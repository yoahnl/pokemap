import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/ports/narrative_authoring_persistence_gateway.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

enum AtomicProjectManifestWriteCheckpoint {
  afterInitialRead,
  afterTempFlushed,
  beforeSecondCompareAndSwap,
  afterProjectRenamed,
  beforeCommitVerification,
}

final class AtomicProjectManifestWriteContext {
  const AtomicProjectManifestWriteContext({
    required this.projectPath,
    required this.tempPath,
    required this.beforeRevision,
    required this.expectedAfterRevision,
  });

  final String projectPath;
  final String tempPath;
  final String beforeRevision;
  final String expectedAfterRevision;
}

typedef AtomicProjectManifestFaultInjector = FutureOr<void> Function(
  AtomicProjectManifestWriteCheckpoint checkpoint,
  AtomicProjectManifestWriteContext context,
);

/// Atomically replaces one project manifest after two compare-and-swap checks.
///
/// The writer intentionally preserves root members unknown to the current
/// model and the exact decoded `eventRegistry` value already present on disk.
/// Narrative Event authoring owns changes to that registry through its own
/// journalled writer.
final class AtomicProjectManifestPersistence
    implements NarrativeAuthoringPersistenceGateway {
  const AtomicProjectManifestPersistence({
    this.faultInjector,
    this.eventRegistryPersistence,
  });

  final AtomicProjectManifestFaultInjector? faultInjector;
  final NarrativeEventRegistryPersistence? eventRegistryPersistence;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) async {
    if (!transaction.isApplicable) {
      return _failed(
        'transactionNotApplicable',
        'Only an applicable narrative mutation can be persisted.',
      );
    }
    return persistProjectDocument(
      projectPath: transaction.projectPath,
      operationId: transaction.operationId,
      before: transaction.before,
      after: transaction.after,
    );
  }

  /// Persists an exact project snapshot through the same validated, atomic
  /// compare-and-swap boundary used by Narrative Studio.
  ///
  /// Feature-specific gateways must validate their allowed mutation before
  /// calling this method.
  Future<NarrativeAuthoringPersistenceResult> persistProjectDocument({
    required String projectPath,
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
  }) async {
    try {
      ProjectValidator.validate(after);
    } on Object catch (error) {
      return _failed(
        'invalidTargetProject',
        'The projected manifest is invalid: $error',
      );
    }

    late final String canonicalProjectPath;
    try {
      final requestedProject = File(projectPath);
      if (!await requestedProject.exists()) {
        return _failed(
          'projectManifestMissing',
          'The project manifest does not exist.',
        );
      }
      // Resolve once before locking and use that same target for every later
      // read, temp and rename. Otherwise renaming onto a symlink path would
      // replace the link itself and fork the project away from its real file.
      canonicalProjectPath = p.normalize(
        await requestedProject.resolveSymbolicLinks(),
      );
    } on Object catch (error) {
      return _failed(
        'projectManifestPathResolutionFailed',
        'The project manifest path cannot be resolved safely: $error',
      );
    }

    try {
      return await withProjectManifestWriteLock(
        canonicalProjectPath,
        () => _persistLocked(
          canonicalProjectPath: canonicalProjectPath,
          operationId: operationId,
          before: before,
          after: after,
        ),
      );
    } on Object catch (error) {
      return _failed(
        'projectManifestWriteFailed',
        'The project manifest could not be persisted: $error',
      );
    }
  }

  Future<NarrativeAuthoringPersistenceResult> _persistLocked({
    required String canonicalProjectPath,
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
  }) async {
    final recoveryInspection =
        await (eventRegistryPersistence ?? NarrativeEventRegistryPersistence())
            .inspectProjectAlreadyLocked(canonicalProjectPath);
    switch (recoveryInspection.status) {
      case NarrativeEventRegistryRecoveryGateStatus.recoveryRequired:
        return _recoveryRequired(
          'eventRegistryRecoveryRequired',
          _eventRecoveryMessage(
            'An interrupted Event write must be recovered first.',
            recoveryInspection,
          ),
        );
      case NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked:
        return _recoveryRequired(
          'eventRegistryRecoveryBlocked',
          _eventRecoveryMessage(
            'Event recovery is blocked and must be inspected first.',
            recoveryInspection,
          ),
        );
      case NarrativeEventRegistryRecoveryGateStatus.clear:
        break;
    }
    final projectFile = File(canonicalProjectPath);
    if (!await projectFile.exists()) {
      return _failed(
        'projectManifestMissing',
        'The project manifest does not exist.',
      );
    }

    late final List<int> beforeBytes;
    late final String beforeRevision;
    late final ValidatedNarrativeEventAuthoringProject current;
    late final Map<String, Object?> currentRoot;
    try {
      beforeBytes = await projectFile.readAsBytes();
      beforeRevision = narrativeEventBytesFingerprint(beforeBytes);
      current = decodeValidatedNarrativeEventAuthoringProject(beforeBytes);
      currentRoot = _strictObject(
        decodeNarrativeEventJsonStrict(utf8.decode(beforeBytes)),
      );
    } on Object catch (error) {
      return _failed(
        'invalidCurrentProject',
        'The current project manifest cannot be updated safely: $error',
      );
    }

    final tempPath = _tempPath(canonicalProjectPath, operationId);
    final placeholderContext = AtomicProjectManifestWriteContext(
      projectPath: projectFile.path,
      tempPath: tempPath,
      beforeRevision: beforeRevision,
      expectedAfterRevision: beforeRevision,
    );
    await _checkpoint(
      AtomicProjectManifestWriteCheckpoint.afterInitialRead,
      placeholderContext,
    );
    if (current.manifest != before) {
      return _failed(
        'staleProjectRevision',
        'The project changed since this narrative edit started.',
      );
    }
    if (!_sameRegistry(
      current.registryState.registryOrNull,
      after.eventRegistry,
    )) {
      return _failed(
        'eventRegistryMismatch',
        'Generic narrative persistence cannot change the Event registry.',
      );
    }

    late final List<int> afterBytes;
    try {
      final serializedAfter = _strictObject(
        jsonDecode(jsonEncode(after.toJson())),
      );
      final nextRoot = Map<String, Object?>.from(currentRoot)
        ..addAll(serializedAfter);
      if (currentRoot.containsKey('eventRegistry')) {
        nextRoot['eventRegistry'] = currentRoot['eventRegistry'];
      } else {
        nextRoot.remove('eventRegistry');
      }
      canonicalizeNarrativeEventJson(nextRoot);
      afterBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(nextRoot),
      );
      final projected = decodeValidatedNarrativeEventAuthoringProject(
        afterBytes,
      );
      if (projected.manifest != after) {
        return _failed(
          'projectedManifestMismatch',
          'The persisted projection does not match the validated mutation.',
        );
      }
    } on Object catch (error) {
      return _failed(
        'invalidTargetProject',
        'The projected manifest cannot be encoded safely: $error',
      );
    }

    final expectedAfterRevision = narrativeEventBytesFingerprint(afterBytes);
    final context = AtomicProjectManifestWriteContext(
      projectPath: projectFile.path,
      tempPath: tempPath,
      beforeRevision: beforeRevision,
      expectedAfterRevision: expectedAfterRevision,
    );
    final tempFile = File(tempPath);
    var renameVisible = false;
    try {
      await tempFile.parent.create(recursive: true);
      final handle = await tempFile.open(mode: FileMode.write);
      try {
        await handle.writeFrom(afterBytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.afterTempFlushed,
        context,
      );
      final tempRevision = narrativeEventBytesFingerprint(
        await tempFile.readAsBytes(),
      );
      if (tempRevision != expectedAfterRevision) {
        await _deleteTemp(tempFile);
        return _failed(
          'projectManifestTempVerificationFailed',
          'The flushed temporary manifest does not match its source bytes.',
        );
      }

      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.beforeSecondCompareAndSwap,
        context,
      );
      final liveRevision = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      if (liveRevision != beforeRevision) {
        await _deleteTemp(tempFile);
        return _failed(
          'projectChangedBeforeCommit',
          'The project changed while the narrative edit was being saved.',
        );
      }

      await tempFile.rename(projectFile.path);
      renameVisible = true;
      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.afterProjectRenamed,
        context,
      );
      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.beforeCommitVerification,
        context,
      );
      final committedRevision = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      if (committedRevision != expectedAfterRevision) {
        return _recoveryRequired(
          'projectManifestVerificationFailed',
          'The renamed project manifest could not be verified.',
        );
      }
      return const NarrativeAuthoringPersistenceResult.committed(
        code: 'projectManifestCommitted',
        message: 'The narrative mutation was persisted atomically.',
      );
    } on Object catch (error) {
      if (!renameVisible) {
        await _deleteTemp(tempFile);
        return _failed(
          'projectManifestWriteFailed',
          'The project manifest was not replaced: $error',
        );
      }
      // A callback or final read can fail after the atomic rename even though
      // the exact requested bytes are already durable and readable. Verify
      // once more before declaring ambiguity so the UI never reports a known
      // committed document as "not saved".
      try {
        final committedRevision = narrativeEventBytesFingerprint(
          await projectFile.readAsBytes(),
        );
        if (committedRevision == expectedAfterRevision) {
          return const NarrativeAuthoringPersistenceResult.committed(
            code: 'projectManifestCommittedAfterInterruptedVerification',
            message: 'The narrative mutation was persisted and verified '
                'after an interrupted commit callback.',
          );
        }
      } on Object {
        // The state really is indeterminate; keep the recovery interlock.
      }
      return _recoveryRequired(
        'projectManifestCommitAmbiguous',
        'The project was replaced but final verification was interrupted: '
            '$error',
      );
    }
  }

  Future<void> _checkpoint(
    AtomicProjectManifestWriteCheckpoint checkpoint,
    AtomicProjectManifestWriteContext context,
  ) async {
    await faultInjector?.call(checkpoint, context);
  }
}

String _tempPath(String projectPath, String operationId) {
  final identity = narrativeEventBytesFingerprint(
    utf8.encode(
      '${p.normalize(projectPath)}\u0000$operationId',
    ),
  ).substring(7, 23);
  return p.join(
    p.dirname(projectPath),
    '.pokemap-project-$identity.tmp',
  );
}

Map<String, Object?> _strictObject(Object? value) {
  if (value is! Map) {
    throw const FormatException('Project root must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Project keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

bool _sameRegistry(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

Future<void> _deleteTemp(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // A same-directory temp is not user-visible state. A later attempt with
    // the same operation id truncates and verifies it before commit.
  }
}

NarrativeAuthoringPersistenceResult _failed(String code, String message) {
  return NarrativeAuthoringPersistenceResult(
    status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
    code: code,
    message: message,
  );
}

NarrativeAuthoringPersistenceResult _recoveryRequired(
  String code,
  String message,
) {
  return NarrativeAuthoringPersistenceResult(
    status: NarrativeAuthoringPersistenceStatus.recoveryRequired,
    code: code,
    message: message,
  );
}

String _eventRecoveryMessage(
  String summary,
  NarrativeEventRegistryRecoveryInspection inspection,
) {
  if (inspection.issues.isEmpty) return summary;
  final issue = inspection.issues.first;
  final path = issue.path == null ? '' : ' File: ${issue.path}.';
  return '$summary Cause: ${issue.code}. ${issue.message}$path';
}
