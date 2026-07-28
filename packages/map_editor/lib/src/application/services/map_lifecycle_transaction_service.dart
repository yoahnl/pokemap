import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/map_document_persistence.dart';
import '../errors/application_errors.dart';

/// Lifecycle mutations covered by the DS-05 durable intent protocol.
///
/// These names describe product operations. They deliberately do not contain
/// the word "atomic": each individual file is replaced atomically, while the
/// journal makes the multi-file lifecycle recoverable rather than atomic.
enum MapLifecycleOperation { create, duplicate, rename, delete }

/// Last durable evidence written to the lifecycle journal.
///
/// Recovery never trusts this phase alone. It always re-reads project and map
/// bytes because a process can stop between a file commit and the next phase
/// rewrite.
enum MapLifecycleTransactionStatus {
  prepared,
  targetWritten,
  projectWritten,
  sourceRemoved,
  committed,
}

enum MapLifecycleRecoveryStatus { clear, recovered }

enum MapLifecycleTransactionCheckpoint {
  afterJournalPrepared,
  afterTargetWritten,
  afterProjectWritten,
  afterSourceRemoved,
  beforeJournalCleared,
}

typedef MapLifecycleTransactionFaultInjector = FutureOr<void> Function(
  MapLifecycleTransactionCheckpoint checkpoint,
  MapLifecycleTransactionRecord record,
);

/// Fault-injection sentinel that represents process termination.
///
/// Production exceptions are reported as recovery-required or blocked. This
/// sentinel is intentionally rethrown unchanged so restart tests can prove that
/// durable journal evidence, rather than in-memory compensation, performs the
/// recovery.
final class MapLifecycleSimulatedCrash implements Exception {
  const MapLifecycleSimulatedCrash();
}

final class MapLifecycleProjectSnapshot {
  MapLifecycleProjectSnapshot({
    required this.project,
    required String revision,
  }) : revision = requireMapDocumentRevision(revision);

  final ProjectManifest project;
  final String revision;
}

final class MapLifecycleTransactionRequest {
  const MapLifecycleTransactionRequest._({
    required this.operation,
    required this.projectPath,
    required this.beforeProject,
    required this.afterProject,
    this.sourcePath,
    this.sourceRevision,
    this.targetPath,
    this.targetMap,
  });

  factory MapLifecycleTransactionRequest.create({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String targetPath,
    required MapData targetMap,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.create,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }

  factory MapLifecycleTransactionRequest.duplicate({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String sourcePath,
    required String sourceRevision,
    required String targetPath,
    required MapData targetMap,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.duplicate,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: requireMapDocumentRevision(sourceRevision),
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }

  factory MapLifecycleTransactionRequest.rename({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String sourcePath,
    required String sourceRevision,
    required String targetPath,
    required MapData targetMap,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.rename,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: requireMapDocumentRevision(sourceRevision),
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }

  factory MapLifecycleTransactionRequest.delete({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String sourcePath,
    required String sourceRevision,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.delete,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: requireMapDocumentRevision(sourceRevision),
    );
  }

  final MapLifecycleOperation operation;
  final String projectPath;
  final ProjectManifest beforeProject;
  final ProjectManifest afterProject;
  final String? sourcePath;
  final String? sourceRevision;
  final String? targetPath;
  final MapData? targetMap;
}

/// Durable write-ahead evidence for one map lifecycle mutation.
///
/// The full validated target map is temporary recovery data, not a second
/// source of truth. Keeping it in the journal lets a prepared transaction roll
/// forward even when the process stopped before creating its target document.
final class MapLifecycleTransactionRecord {
  static const schemaVersion = 1;

  MapLifecycleTransactionRecord._({
    required this.transactionId,
    required this.operation,
    required this.status,
    required this.projectPath,
    required String projectBeforeRevision,
    required this.beforeProject,
    required this.afterProject,
    this.sourcePath,
    String? sourceRevision,
    this.targetPath,
    this.targetMap,
    String? targetRevision,
  })  : projectBeforeRevision =
            requireMapDocumentRevision(projectBeforeRevision),
        sourceRevision = sourceRevision == null
            ? null
            : requireMapDocumentRevision(sourceRevision),
        targetRevision = targetRevision == null
            ? null
            : requireMapDocumentRevision(targetRevision) {
    _validateShape();
  }

  factory MapLifecycleTransactionRecord.fromRequest({
    required MapLifecycleTransactionRequest request,
    required String canonicalProjectPath,
    required String projectBeforeRevision,
  }) {
    final targetRevision = request.targetMap == null
        ? null
        : mapDocumentRevisionFor(request.targetMap!);
    final identityPayload = <String, Object?>{
      'operation': request.operation.name,
      'projectPath': canonicalProjectPath,
      'projectBeforeRevision': projectBeforeRevision,
      'beforeProject': request.beforeProject.toJson(),
      'afterProject': request.afterProject.toJson(),
      'sourcePath': request.sourcePath,
      'sourceRevision': request.sourceRevision,
      'targetPath': request.targetPath,
      'targetRevision': targetRevision,
    };
    final fingerprint = narrativeEventBytesFingerprint(
      utf8.encode(jsonEncode(identityPayload)),
    ).substring('sha256:'.length);
    return MapLifecycleTransactionRecord._(
      transactionId: 'map_lifecycle_${fingerprint.substring(0, 24)}',
      operation: request.operation,
      status: MapLifecycleTransactionStatus.prepared,
      projectPath: canonicalProjectPath,
      projectBeforeRevision: projectBeforeRevision,
      beforeProject: request.beforeProject,
      afterProject: request.afterProject,
      sourcePath: request.sourcePath,
      sourceRevision: request.sourceRevision,
      targetPath: request.targetPath,
      targetMap: request.targetMap,
      targetRevision: targetRevision,
    );
  }

  factory MapLifecycleTransactionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException(
        'Unsupported map lifecycle journal schema.',
      );
    }
    final operation = _enumByName(
      MapLifecycleOperation.values,
      json['operation'],
      'operation',
    );
    final status = _enumByName(
      MapLifecycleTransactionStatus.values,
      json['status'],
      'status',
    );
    final beforeProject = ProjectManifest.fromJson(
      _jsonObject(json['beforeProject'], 'beforeProject'),
    );
    final afterProject = ProjectManifest.fromJson(
      _jsonObject(json['afterProject'], 'afterProject'),
    );
    final targetMapJson = json['targetMap'];
    final targetMap = targetMapJson == null
        ? null
        : MapData.fromJson(_jsonObject(targetMapJson, 'targetMap'));
    ProjectValidator.validate(beforeProject);
    ProjectValidator.validate(afterProject);
    if (targetMap != null) MapValidator.validate(targetMap);
    return MapLifecycleTransactionRecord._(
      transactionId: _requiredString(json['transactionId'], 'transactionId'),
      operation: operation,
      status: status,
      projectPath: _requiredString(json['projectPath'], 'projectPath'),
      projectBeforeRevision: _requiredString(
        json['projectBeforeRevision'],
        'projectBeforeRevision',
      ),
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: _optionalString(json['sourcePath'], 'sourcePath'),
      sourceRevision: _optionalString(json['sourceRevision'], 'sourceRevision'),
      targetPath: _optionalString(json['targetPath'], 'targetPath'),
      targetMap: targetMap,
      targetRevision: _optionalString(json['targetRevision'], 'targetRevision'),
    );
  }

  final String transactionId;
  final MapLifecycleOperation operation;
  final MapLifecycleTransactionStatus status;
  final String projectPath;
  final String projectBeforeRevision;
  final ProjectManifest beforeProject;
  final ProjectManifest afterProject;
  final String? sourcePath;
  final String? sourceRevision;
  final String? targetPath;
  final MapData? targetMap;
  final String? targetRevision;

  bool get hasTarget => targetPath != null;

  bool get removesSource =>
      operation == MapLifecycleOperation.rename ||
      operation == MapLifecycleOperation.delete;

  MapLifecycleTransactionRecord copyWith({
    required MapLifecycleTransactionStatus status,
  }) {
    return MapLifecycleTransactionRecord._(
      transactionId: transactionId,
      operation: operation,
      status: status,
      projectPath: projectPath,
      projectBeforeRevision: projectBeforeRevision,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
      targetPath: targetPath,
      targetMap: targetMap,
      targetRevision: targetRevision,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'transactionId': transactionId,
        'operation': operation.name,
        'status': status.name,
        'projectPath': projectPath,
        'projectBeforeRevision': projectBeforeRevision,
        'beforeProject': beforeProject.toJson(),
        'afterProject': afterProject.toJson(),
        'sourcePath': sourcePath,
        'sourceRevision': sourceRevision,
        'targetPath': targetPath,
        'targetMap': targetMap?.toJson(),
        'targetRevision': targetRevision,
      };

  void _validateShape() {
    if (transactionId.trim().isEmpty ||
        projectPath.trim().isEmpty ||
        beforeProject == afterProject) {
      throw const FormatException(
        'Map lifecycle journal identity or project transition is invalid.',
      );
    }
    final hasSource = sourcePath != null && sourceRevision != null;
    final hasCompleteTarget =
        targetPath != null && targetMap != null && targetRevision != null;
    if ((sourcePath == null) != (sourceRevision == null) ||
        (targetPath == null) != (targetMap == null) ||
        (targetPath == null) != (targetRevision == null)) {
      throw const FormatException(
        'Map lifecycle journal contains a partial map precondition.',
      );
    }
    switch (operation) {
      case MapLifecycleOperation.create:
        if (hasSource || !hasCompleteTarget) {
          throw const FormatException(
            'Create requires one complete target and no source.',
          );
        }
      case MapLifecycleOperation.duplicate:
      case MapLifecycleOperation.rename:
        if (!hasSource || !hasCompleteTarget || sourcePath == targetPath) {
          throw const FormatException(
            'Duplicate/rename requires distinct complete source and target.',
          );
        }
      case MapLifecycleOperation.delete:
        if (!hasSource || hasCompleteTarget) {
          throw const FormatException(
            'Delete requires one complete source and no target.',
          );
        }
    }
    if (targetMap != null &&
        mapDocumentRevisionFor(targetMap!) != targetRevision) {
      throw const FormatException(
        'Map lifecycle target payload does not match its revision.',
      );
    }
    _validateLifecycleDelta(
      operation: operation,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }
}

final class MapLifecycleTransactionResult {
  const MapLifecycleTransactionResult({
    required this.project,
    this.targetMap,
    this.targetRevision,
  });

  final ProjectManifest project;
  final MapData? targetMap;
  final String? targetRevision;
}

final class MapLifecycleRecoveryResult {
  const MapLifecycleRecoveryResult(this.status);

  final MapLifecycleRecoveryStatus status;
}

/// Infrastructure boundary used by the deterministic application coordinator.
///
/// File implementations must make each journal rewrite and document mutation
/// individually durable. The application coordinator owns ordering and never
/// infers a successful multi-file commit from a phase flag alone.
abstract interface class MapLifecycleTransactionGateway {
  Future<T> synchronized<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  );

  String journalPath(String canonicalProjectPath);

  Future<MapLifecycleTransactionRecord?> readJournal(
    String canonicalProjectPath,
  );

  Future<void> writeJournal(
    String canonicalProjectPath,
    MapLifecycleTransactionRecord record,
  );

  Future<void> clearJournal(String canonicalProjectPath);

  Future<MapLifecycleProjectSnapshot> readProject(
    String canonicalProjectPath,
  );

  Future<MapLifecycleProjectSnapshot> writeProject(
    String canonicalProjectPath, {
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    required String expectedRevision,
  });

  Future<RevisionedMapDocument?> readMap(String path);

  Future<RevisionedMapDocument> writeMap(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
  });

  Future<void> deleteMap(
    String path, {
    required String expectedRevision,
  });
}

/// Durable lifecycle orchestration for create, duplicate, rename and delete.
///
/// Once the prepared journal is durable, recovery rolls the stated intent
/// forward. It never guesses across independently changed project/map bytes:
/// such divergence keeps the journal and raises a product-visible block.
final class MapLifecycleTransactionCoordinator {
  const MapLifecycleTransactionCoordinator(
    this.gateway, {
    this.faultInjector,
  });

  final MapLifecycleTransactionGateway gateway;
  final MapLifecycleTransactionFaultInjector? faultInjector;

  Future<MapLifecycleTransactionResult> execute(
    MapLifecycleTransactionRequest request,
  ) {
    return gateway.synchronized(request.projectPath, (canonicalProjectPath) {
      return _executeLocked(request, canonicalProjectPath);
    });
  }

  Future<MapLifecycleRecoveryResult> recover(String projectPath) {
    return gateway.synchronized(projectPath, _recoverLocked);
  }

  /// Holds the lifecycle lock while normal project I/O runs.
  ///
  /// `FileProjectRepository` uses this barrier so opening or generically saving
  /// `project.json` cannot observe a half-finished World Map lifecycle.
  Future<T> runAfterRecovery<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  ) {
    return gateway.synchronized(projectPath, (canonicalProjectPath) async {
      await _recoverLocked(canonicalProjectPath);
      return action(canonicalProjectPath);
    });
  }

  Future<MapLifecycleTransactionResult> _executeLocked(
    MapLifecycleTransactionRequest request,
    String canonicalProjectPath,
  ) async {
    await _recoverLocked(canonicalProjectPath);
    _requireProjectMapPaths(
      canonicalProjectPath,
      request.sourcePath,
      request.targetPath,
    );
    final current = await gateway.readProject(canonicalProjectPath);
    if (current.project != request.beforeProject) {
      throw const EditorConflictException(
        'Le projet a changé avant le début de la transaction de carte.',
      );
    }
    await _requireSourceRevision(
      sourcePath: request.sourcePath,
      sourceRevision: request.sourceRevision,
      canonicalProjectPath: canonicalProjectPath,
      journalIsDurable: false,
    );
    late final MapLifecycleTransactionRecord record;
    try {
      record = MapLifecycleTransactionRecord.fromRequest(
        request: request,
        canonicalProjectPath: canonicalProjectPath,
        projectBeforeRevision: current.revision,
      );
    } on FormatException catch (error) {
      throw EditorValidationException(
        'La transaction lifecycle demandée est invalide: $error',
      );
    }
    var journalIsDurable = false;
    try {
      await gateway.writeJournal(canonicalProjectPath, record);
      journalIsDurable = true;
      await _checkpoint(
        MapLifecycleTransactionCheckpoint.afterJournalPrepared,
        record,
      );
      return await _rollForwardLocked(record);
    } on MapLifecycleSimulatedCrash {
      rethrow;
    } on ProjectRecoveryBlockedException {
      rethrow;
    } on ProjectRecoveryRequiredException {
      rethrow;
    } on Object catch (error) {
      if (!journalIsDurable) rethrow;
      throw ProjectRecoveryRequiredException(
        'La transaction de carte a été interrompue et sera reprise avant '
        'tout nouvel accès au projet. Cause: $error',
        code: 'mapLifecycleRecoveryRequired',
        path: gateway.journalPath(canonicalProjectPath),
      );
    }
  }

  Future<MapLifecycleRecoveryResult> _recoverLocked(
    String canonicalProjectPath,
  ) async {
    late final MapLifecycleTransactionRecord? record;
    try {
      record = await gateway.readJournal(canonicalProjectPath);
    } on ProjectRecoveryBlockedException {
      rethrow;
    } on Object catch (error) {
      throw ProjectRecoveryBlockedException(
        'Le journal lifecycle World Map est illisible ou invalide: $error',
        code: 'mapLifecycleJournalInvalid',
        path: gateway.journalPath(canonicalProjectPath),
      );
    }
    if (record == null) {
      return const MapLifecycleRecoveryResult(
        MapLifecycleRecoveryStatus.clear,
      );
    }
    if (p.normalize(record.projectPath) != p.normalize(canonicalProjectPath)) {
      _blocked(
        canonicalProjectPath,
        'Le journal appartient à un autre manifeste de projet.',
      );
    }
    _requireProjectMapPaths(
      canonicalProjectPath,
      record.sourcePath,
      record.targetPath,
    );
    try {
      await _rollForwardLocked(record);
      return const MapLifecycleRecoveryResult(
        MapLifecycleRecoveryStatus.recovered,
      );
    } on MapLifecycleSimulatedCrash {
      rethrow;
    } on ProjectRecoveryBlockedException {
      rethrow;
    } on ProjectRecoveryRequiredException {
      rethrow;
    } on Object catch (error) {
      throw ProjectRecoveryRequiredException(
        'La reprise de la transaction World Map doit être retentée. '
        'Cause: $error',
        code: 'mapLifecycleRecoveryRequired',
        path: gateway.journalPath(canonicalProjectPath),
      );
    }
  }

  Future<MapLifecycleTransactionResult> _rollForwardLocked(
    MapLifecycleTransactionRecord initialRecord,
  ) async {
    var record = initialRecord;
    var currentProject = await gateway.readProject(record.projectPath);
    final projectIsBefore = currentProject.project == record.beforeProject;
    final projectIsAfter = currentProject.project == record.afterProject;
    if (!projectIsBefore && !projectIsAfter) {
      _blocked(
        record.projectPath,
        'project.json diverge des deux états attestés par le journal.',
      );
    }

    if (projectIsBefore) {
      if (currentProject.revision != record.projectBeforeRevision) {
        _blocked(
          record.projectPath,
          'La révision exacte de project.json a changé depuis la préparation.',
        );
      }
      await _requireSourceRevision(
        sourcePath: record.sourcePath,
        sourceRevision: record.sourceRevision,
        canonicalProjectPath: record.projectPath,
      );
      if (record.hasTarget) {
        await _ensureTarget(record);
        record = await _advance(
          record,
          MapLifecycleTransactionStatus.targetWritten,
        );
        await _checkpoint(
          MapLifecycleTransactionCheckpoint.afterTargetWritten,
          record,
        );
      }
      currentProject = await gateway.writeProject(
        record.projectPath,
        operationId: record.transactionId,
        before: record.beforeProject,
        after: record.afterProject,
        expectedRevision: record.projectBeforeRevision,
      );
      if (currentProject.project != record.afterProject) {
        _blocked(
          record.projectPath,
          'Le manifeste durable ne correspond pas à la transaction préparée.',
        );
      }
      record = await _advance(
        record,
        MapLifecycleTransactionStatus.projectWritten,
      );
      await _checkpoint(
        MapLifecycleTransactionCheckpoint.afterProjectWritten,
        record,
      );
    } else if (record.hasTarget) {
      // A committed manifest must never be left pointing at a missing target.
      // The journal contains the validated payload needed for an idempotent
      // absence-only repair after a crash or external file removal.
      await _ensureTarget(record);
    }

    if (record.removesSource) {
      await _removeSource(record);
      record = await _advance(
        record,
        MapLifecycleTransactionStatus.sourceRemoved,
      );
      await _checkpoint(
        MapLifecycleTransactionCheckpoint.afterSourceRemoved,
        record,
      );
    }

    record = await _advance(
      record,
      MapLifecycleTransactionStatus.committed,
    );
    await _checkpoint(
      MapLifecycleTransactionCheckpoint.beforeJournalCleared,
      record,
    );
    await gateway.clearJournal(record.projectPath);
    return MapLifecycleTransactionResult(
      project: record.afterProject,
      targetMap: record.targetMap,
      targetRevision: record.targetRevision,
    );
  }

  Future<MapLifecycleTransactionRecord> _advance(
    MapLifecycleTransactionRecord record,
    MapLifecycleTransactionStatus requested,
  ) async {
    final next = requested.index > record.status.index
        ? record.copyWith(status: requested)
        : record;
    if (next.status != record.status) {
      await gateway.writeJournal(record.projectPath, next);
    }
    return next;
  }

  Future<void> _ensureTarget(MapLifecycleTransactionRecord record) async {
    final targetPath = record.targetPath!;
    final expectedRevision = record.targetRevision!;
    final targetMap = record.targetMap!;
    final current = await gateway.readMap(targetPath);
    if (current != null) {
      if (current.revision != expectedRevision || current.map != targetMap) {
        _blocked(
          record.projectPath,
          'La cible "$targetPath" existe avec un contenu indépendant.',
        );
      }
      return;
    }
    final saved = await gateway.writeMap(
      targetMap,
      targetPath,
      precondition: const MapDocumentWritePrecondition.absent(),
    );
    if (saved.revision != expectedRevision || saved.map != targetMap) {
      _blocked(
        record.projectPath,
        'La cible durable ne correspond pas au payload du journal.',
      );
    }
  }

  Future<void> _removeSource(MapLifecycleTransactionRecord record) async {
    final sourcePath = record.sourcePath!;
    final sourceRevision = record.sourceRevision!;
    final current = await gateway.readMap(sourcePath);
    if (current == null) return;
    if (current.revision != sourceRevision) {
      _blocked(
        record.projectPath,
        'La source "$sourcePath" a changé avant sa suppression.',
      );
    }
    await gateway.deleteMap(
      sourcePath,
      expectedRevision: sourceRevision,
    );
    if (await gateway.readMap(sourcePath) != null) {
      _blocked(
        record.projectPath,
        'La suppression durable de "$sourcePath" ne peut pas être attestée.',
      );
    }
  }

  Future<void> _requireSourceRevision({
    required String? sourcePath,
    required String? sourceRevision,
    required String canonicalProjectPath,
    bool journalIsDurable = true,
  }) async {
    if (sourcePath == null) return;
    final current = await gateway.readMap(sourcePath);
    if (current == null || current.revision != sourceRevision) {
      if (!journalIsDurable) {
        throw const EditorConflictException(
          'The source map changed before lifecycle preparation.',
        );
      }
      _blocked(
        canonicalProjectPath,
        'La source "$sourcePath" ne possède plus la révision préparée.',
      );
    }
  }

  Future<void> _checkpoint(
    MapLifecycleTransactionCheckpoint checkpoint,
    MapLifecycleTransactionRecord record,
  ) async {
    await faultInjector?.call(checkpoint, record);
  }

  Never _blocked(String projectPath, String reason) {
    throw ProjectRecoveryBlockedException(
      'La reprise lifecycle World Map refuse de deviner: $reason',
      code: 'mapLifecycleRecoveryBlocked',
      path: gateway.journalPath(projectPath),
    );
  }
}

void _validateLifecycleDelta({
  required MapLifecycleOperation operation,
  required String projectPath,
  required ProjectManifest beforeProject,
  required ProjectManifest afterProject,
  required String? sourcePath,
  required String? targetPath,
  required MapData? targetMap,
}) {
  // Map lifecycle must never become a generic project writer. This equality
  // proves every non-map field is byte-model-equivalent before inspecting the
  // operation-specific maps-list delta.
  if (beforeProject.copyWith(maps: afterProject.maps) != afterProject) {
    throw const FormatException(
      'Map lifecycle may change the manifest maps list only.',
    );
  }
  final sourceRelativePath = sourcePath == null
      ? null
      : _projectRelativeMapPath(projectPath, sourcePath);
  final targetRelativePath = targetPath == null
      ? null
      : _projectRelativeMapPath(projectPath, targetPath);

  switch (operation) {
    case MapLifecycleOperation.create:
    case MapLifecycleOperation.duplicate:
      if (afterProject.maps.length != beforeProject.maps.length + 1 ||
          !_sameEntries(
            beforeProject.maps,
            afterProject.maps.take(beforeProject.maps.length).toList(),
          )) {
        throw const FormatException(
          'Create/duplicate must append exactly one map entry.',
        );
      }
      _requireTargetEntry(
        afterProject.maps.last,
        targetMap: targetMap!,
        targetRelativePath: targetRelativePath!,
      );
      if (operation == MapLifecycleOperation.duplicate) {
        _requireUniqueSourceEntry(
          beforeProject.maps,
          sourceRelativePath!,
        );
      }
      break;
    case MapLifecycleOperation.rename:
      if (afterProject.maps.length != beforeProject.maps.length) {
        throw const FormatException(
          'Rename must preserve the number of map entries.',
        );
      }
      final sourceIndex = _requireUniqueSourceEntry(
        beforeProject.maps,
        sourceRelativePath!,
      );
      for (var index = 0; index < beforeProject.maps.length; index += 1) {
        if (index == sourceIndex) continue;
        if (beforeProject.maps[index] != afterProject.maps[index]) {
          throw const FormatException(
            'Rename changed an unrelated map entry.',
          );
        }
      }
      final expectedRenamedEntry = beforeProject.maps[sourceIndex].copyWith(
        id: targetMap!.id,
        name: targetMap.name,
        relativePath: targetRelativePath!,
      );
      if (afterProject.maps[sourceIndex] != expectedRenamedEntry) {
        throw const FormatException(
          'Rename target entry does not match the journaled map.',
        );
      }
      break;
    case MapLifecycleOperation.delete:
      final sourceIndex = _requireUniqueSourceEntry(
        beforeProject.maps,
        sourceRelativePath!,
      );
      final expectedMaps = <ProjectMapEntry>[
        ...beforeProject.maps.take(sourceIndex),
        ...beforeProject.maps.skip(sourceIndex + 1),
      ];
      if (!_sameEntries(afterProject.maps, expectedMaps)) {
        throw const FormatException(
          'Delete must remove exactly its journaled source entry.',
        );
      }
      break;
  }
}

String _projectRelativeMapPath(String projectPath, String mapPath) {
  final projectRoot = p.dirname(p.normalize(p.absolute(projectPath)));
  final relative = p.relative(
    p.normalize(p.absolute(mapPath)),
    from: projectRoot,
  );
  final posixRelative = p.split(relative).join('/');
  if (posixRelative == '..' || posixRelative.startsWith('../')) {
    throw const FormatException(
      'Map lifecycle path is outside the journaled project.',
    );
  }
  return p.posix.normalize(posixRelative);
}

int _requireUniqueSourceEntry(
  List<ProjectMapEntry> entries,
  String sourceRelativePath,
) {
  final matches = <int>[];
  for (var index = 0; index < entries.length; index += 1) {
    if (p.posix.normalize(entries[index].relativePath) == sourceRelativePath) {
      matches.add(index);
    }
  }
  if (matches.length != 1) {
    throw const FormatException(
      'Lifecycle source path must own exactly one manifest entry.',
    );
  }
  return matches.single;
}

void _requireTargetEntry(
  ProjectMapEntry entry, {
  required MapData targetMap,
  required String targetRelativePath,
}) {
  if (entry.id != targetMap.id ||
      entry.name != targetMap.name ||
      p.posix.normalize(entry.relativePath) != targetRelativePath) {
    throw const FormatException(
      'Lifecycle target entry does not match the journaled map.',
    );
  }
}

bool _sameEntries(
  Iterable<ProjectMapEntry> left,
  Iterable<ProjectMapEntry> right,
) {
  final leftList = left.toList(growable: false);
  final rightList = right.toList(growable: false);
  if (leftList.length != rightList.length) return false;
  for (var index = 0; index < leftList.length; index += 1) {
    if (leftList[index] != rightList[index]) return false;
  }
  return true;
}

void _requireProjectMapPaths(
  String projectPath,
  String? sourcePath,
  String? targetPath,
) {
  final projectRoot = p.normalize(p.dirname(p.absolute(projectPath)));
  final mapsRoot = p.normalize(p.join(projectRoot, 'maps'));
  for (final candidate in <String?>[sourcePath, targetPath]) {
    if (candidate == null) continue;
    final normalized = p.normalize(p.absolute(candidate));
    if (!p.isWithin(mapsRoot, normalized) ||
        p.extension(normalized).toLowerCase() != '.json') {
      throw EditorValidationException(
        'Map lifecycle path must stay inside the project maps directory: '
        '$candidate',
      );
    }
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? source,
  String field,
) {
  if (source is! String) {
    throw FormatException('$field must be a string.');
  }
  for (final value in values) {
    if (value.name == source) return value;
  }
  throw FormatException('Unknown $field "$source".');
}

Map<String, dynamic> _jsonObject(Object? source, String field) {
  if (source is! Map) {
    throw FormatException('$field must be a JSON object.');
  }
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    if (entry.key is! String) {
      throw FormatException('$field contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _requiredString(Object? source, String field) {
  if (source is! String || source.trim().isEmpty || source != source.trim()) {
    throw FormatException('$field must be a non-empty trimmed string.');
  }
  return source;
}

String? _optionalString(Object? source, String field) {
  if (source == null) return null;
  return _requiredString(source, field);
}
