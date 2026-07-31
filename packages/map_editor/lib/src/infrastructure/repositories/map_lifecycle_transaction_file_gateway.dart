import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/services/map_lifecycle_transaction_service.dart';
import '../../domain/models/map_document_persistence.dart';
import '../../domain/repositories/repositories.dart';
import 'atomic_project_manifest_persistence.dart';

final _lifecycleWriteQueues = <String, Future<void>>{};

/// Filesystem adapter for the DS-05 recoverable lifecycle protocol.
///
/// The journal is a write-ahead intent under `.pokemap/recovery`. Each rewrite
/// is flushed and renamed on one filesystem. Map and project files still commit
/// separately through their own CAS writers; the journal makes that sequence
/// recoverable and intentionally does not advertise multi-file atomicity.
final class MapLifecycleTransactionFileGateway
    implements MapLifecycleTransactionGateway {
  MapLifecycleTransactionFileGateway({
    required RevisionedMapRepository mapRepository,
    AtomicProjectManifestPersistence? projectPersistence,
  })  : _mapRepository = mapRepository,
        _projectPersistence =
            projectPersistence ?? const AtomicProjectManifestPersistence();

  final RevisionedMapRepository _mapRepository;
  final AtomicProjectManifestPersistence _projectPersistence;

  @override
  Future<T> synchronized<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  ) async {
    final requestedPath = p.normalize(p.absolute(projectPath));
    final projectFile = File(requestedPath);
    final lockIdentity = p.normalize(
      await projectFile.exists()
          ? await projectFile.resolveSymbolicLinks()
          : requestedPath,
    );
    final previous =
        _lifecycleWriteQueues[lockIdentity] ?? Future<void>.value();
    final turn = Completer<void>();
    final tail = previous.then((_) => turn.future);
    _lifecycleWriteQueues[lockIdentity] = tail;
    await previous;

    RandomAccessFile? handle;
    var locked = false;
    try {
      final lockPath = _lockPath(requestedPath);
      await _requireRegularOrMissing(
        lockPath,
        label: 'Map lifecycle lock',
      );
      final lockFile = File(lockPath);
      await lockFile.parent.create(recursive: true);
      handle = await lockFile.open(mode: FileMode.append);
      await handle.lock(FileLock.exclusive);
      locked = true;
      return await action(requestedPath);
    } finally {
      if (handle != null) {
        if (locked) await handle.unlock();
        await handle.close();
      }
      turn.complete();
      if (identical(_lifecycleWriteQueues[lockIdentity], tail)) {
        _lifecycleWriteQueues.remove(lockIdentity);
      }
    }
  }

  @override
  String journalPath(String canonicalProjectPath) {
    return p.join(
      p.dirname(p.normalize(p.absolute(canonicalProjectPath))),
      '.pokemap',
      'recovery',
      'world-map-lifecycle.json',
    );
  }

  String journalRewritePath(String canonicalProjectPath) {
    return '${journalPath(canonicalProjectPath)}.rewrite.tmp';
  }

  String _lockPath(String canonicalProjectPath) {
    return p.join(
      p.dirname(p.normalize(p.absolute(canonicalProjectPath))),
      '.pokemap',
      'recovery',
      'world-map-lifecycle.lock',
    );
  }

  @override
  Future<MapLifecycleTransactionRecord?> readJournal(
    String canonicalProjectPath,
  ) async {
    final stablePath = journalPath(canonicalProjectPath);
    final rewritePath = journalRewritePath(canonicalProjectPath);
    await _requireRegularOrMissing(
      stablePath,
      label: 'Map lifecycle journal',
    );
    await _requireRegularOrMissing(
      rewritePath,
      label: 'Map lifecycle journal rewrite',
    );
    final stable = File(stablePath);
    final rewrite = File(rewritePath);
    if (!await stable.exists()) {
      // A rewrite without the renamed stable intent never authorized any map
      // or manifest mutation and is safe to discard deterministically.
      if (await rewrite.exists()) await rewrite.delete();
      return null;
    }
    if (await rewrite.exists()) await rewrite.delete();
    final decoded = jsonDecode(await stable.readAsString());
    if (decoded is! Map) {
      throw const FormatException(
        'Map lifecycle journal root must be a JSON object.',
      );
    }
    return MapLifecycleTransactionRecord.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> writeJournal(
    String canonicalProjectPath,
    MapLifecycleTransactionRecord record,
  ) async {
    final stablePath = journalPath(canonicalProjectPath);
    final rewritePath = journalRewritePath(canonicalProjectPath);
    await _requireRegularOrMissing(
      stablePath,
      label: 'Map lifecycle journal',
    );
    await _requireRegularOrMissing(
      rewritePath,
      label: 'Map lifecycle journal rewrite',
    );
    final stable = File(stablePath);
    final rewrite = File(rewritePath);
    await stable.parent.create(recursive: true);
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(record.toJson()),
    );
    await _writeFlushed(rewrite, bytes);
    final rewriteRevision = narrativeEventBytesFingerprint(
      await rewrite.readAsBytes(),
    );
    final expectedRevision = narrativeEventBytesFingerprint(bytes);
    if (rewriteRevision != expectedRevision) {
      throw const EditorPersistenceException(
        'The flushed map lifecycle journal cannot be verified.',
      );
    }
    await rewrite.rename(stable.path);
    final stableRevision = narrativeEventBytesFingerprint(
      await stable.readAsBytes(),
    );
    if (stableRevision != expectedRevision) {
      throw const EditorPersistenceException(
        'The durable map lifecycle journal cannot be verified.',
      );
    }
  }

  @override
  Future<void> clearJournal(String canonicalProjectPath) async {
    final stablePath = journalPath(canonicalProjectPath);
    final rewritePath = journalRewritePath(canonicalProjectPath);
    await _requireRegularOrMissing(
      stablePath,
      label: 'Map lifecycle journal',
    );
    await _requireRegularOrMissing(
      rewritePath,
      label: 'Map lifecycle journal rewrite',
    );
    final stable = File(stablePath);
    final rewrite = File(rewritePath);
    if (await rewrite.exists()) await rewrite.delete();
    if (await stable.exists()) await stable.delete();
  }

  @override
  Future<MapLifecycleProjectSnapshot> readProject(
    String canonicalProjectPath,
  ) async {
    final file = File(canonicalProjectPath);
    if (!await file.exists()) {
      throw const EditorNotFoundException(
        'The project manifest required by map lifecycle recovery is missing.',
      );
    }
    final bytes = await file.readAsBytes();
    return MapLifecycleProjectSnapshot(
      project: decodeValidatedNarrativeEventAuthoringProject(bytes).manifest,
      revision: narrativeEventBytesFingerprint(bytes),
    );
  }

  @override
  Future<MapLifecycleProjectSnapshot> writeProject(
    String canonicalProjectPath, {
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    required String expectedRevision,
  }) async {
    final result = await _projectPersistence.persistProjectDocument(
      projectPath: canonicalProjectPath,
      operationId: operationId,
      before: before,
      after: after,
      expectedRevision: expectedRevision,
    );
    switch (result.status) {
      case NarrativeAuthoringPersistenceStatus.committed:
        final durable = await readProject(canonicalProjectPath);
        if (durable.project != after) {
          throw const EditorPersistenceException(
            'The durable project does not match the lifecycle transaction.',
          );
        }
        return durable;
      case NarrativeAuthoringPersistenceStatus.persistenceFailed:
        if (_isProjectConflictCode(result.code)) {
          throw EditorConflictException(result.message);
        }
        throw EditorPersistenceException(result.message);
      case NarrativeAuthoringPersistenceStatus.recoveryRequired:
        throw ProjectRecoveryRequiredException(
          result.message,
          code: result.code,
          path: canonicalProjectPath,
        );
    }
  }

  @override
  Future<RevisionedMapDocument?> readMap(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw EditorConflictException(
        'Map lifecycle refuses a non-regular map document: $path',
      );
    }
    final repository = _mapRepository;
    if (repository is DurableMapDocumentRepository) {
      return (repository as DurableMapDocumentRepository)
          .loadDurableMapDocument(path);
    }
    return repository.loadMapDocument(path);
  }

  @override
  Future<RevisionedMapDocument> writeMap(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
  }) {
    return _mapRepository.saveMapDocument(
      map,
      path,
      precondition: precondition,
    );
  }

  @override
  Future<void> deleteMap(
    String path, {
    required String expectedRevision,
  }) {
    return _mapRepository.deleteMapDocument(
      path,
      expectedRevision: expectedRevision,
    );
  }
}

bool _isProjectConflictCode(String code) {
  return code == 'staleProjectRevision' || code == 'projectChangedBeforeCommit';
}

Future<void> _writeFlushed(File file, List<int> bytes) async {
  await file.parent.create(recursive: true);
  final handle = await file.open(mode: FileMode.write);
  try {
    await handle.writeFrom(bytes);
    await handle.flush();
  } finally {
    await handle.close();
  }
}

Future<void> _requireRegularOrMissing(
  String path, {
  required String label,
}) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound ||
      type == FileSystemEntityType.file) {
    return;
  }
  throw EditorConflictException('$label is not a regular file: $path');
}
