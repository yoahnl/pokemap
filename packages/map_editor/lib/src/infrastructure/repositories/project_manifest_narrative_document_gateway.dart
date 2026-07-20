import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/ports/narrative_authoring_persistence_gateway.dart';
import '../../application/services/narrative_document_session.dart';

/// Compare-and-swap adapter for the first document-session pilot.
///
/// NSC-13 deliberately allows only one existing Cinematic to change per save.
/// Creation, deletion, reordering, multi-asset changes and every other manifest
/// field remain on their existing transactional authoring paths.
final class ProjectManifestNarrativeDocumentGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  ProjectManifestNarrativeDocumentGateway({
    required String projectPath,
    required NarrativeAuthoringPersistenceGateway persistence,
  })  : projectPath = _requiredText(projectPath, 'projectPath'),
        _persistence = persistence;

  final String projectPath;
  final NarrativeAuthoringPersistenceGateway _persistence;

  @override
  Future<NarrativeDocumentVersion<ProjectManifest>> read() async {
    final bytes = await File(projectPath).readAsBytes();
    return NarrativeDocumentVersion<ProjectManifest>(
      revision: narrativeEventBytesFingerprint(bytes),
      document: decodeValidatedNarrativeEventAuthoringProject(bytes).manifest,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectManifest>> save({
    required String expectedRevision,
    required ProjectManifest before,
    required ProjectManifest after,
    required String operationId,
  }) async {
    final current = await _readOrFailure();
    if (current case NarrativeDocumentSaveFailed<ProjectManifest>()) {
      return current;
    }
    final live = current as NarrativeDocumentVersion<ProjectManifest>;
    if (live.revision != expectedRevision || live.document != before) {
      return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
        code: 'staleProjectRevision',
        message: 'The project changed since this document session started.',
        external: live,
      );
    }

    final mutation = _singleCinematicUpdate(before, after);
    if (mutation == null) {
      return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'unsupportedDocumentMutation',
        message: 'This document session can persist exactly one existing '
            'Cinematic update and no other project change.',
      );
    }

    late final NarrativeAuthoringPersistenceResult persistenceResult;
    try {
      persistenceResult = await _persistence.persist(
        NarrativeAuthoringTransaction.fromMutation(
          projectPath: projectPath,
          operationId: operationId,
          mutation: mutation,
        ),
      );
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'projectManifestWriteFailed',
        message: 'The project manifest could not be persisted: $error',
      );
    }

    if (persistenceResult.status ==
        NarrativeAuthoringPersistenceStatus.committed) {
      final durable = await _readOrFailure();
      if (durable case NarrativeDocumentSaveFailed<ProjectManifest>()) {
        return durable;
      }
      final version = durable as NarrativeDocumentVersion<ProjectManifest>;
      if (version.document != after) {
        return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
          code: 'durableDocumentMismatch',
          message: 'Persistence completed but the durable document does not '
              'match the requested Cinematic update.',
        );
      }
      return NarrativeDocumentSaveResult<ProjectManifest>.saved(version);
    }

    if (_isConflictCode(persistenceResult.code)) {
      final external = await _readOrFailure();
      if (external case NarrativeDocumentSaveFailed<ProjectManifest>()) {
        return external;
      }
      return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
        code: persistenceResult.code,
        message: persistenceResult.message,
        external: external as NarrativeDocumentVersion<ProjectManifest>,
      );
    }
    return NarrativeDocumentSaveResult<ProjectManifest>.failed(
      code: persistenceResult.code,
      message: persistenceResult.message,
    );
  }

  Future<Object> _readOrFailure() async {
    try {
      return await read();
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'projectManifestReadFailed',
        message: 'The project manifest cannot be read safely: $error',
      );
    }
  }
}

NarrativeAssetUpdated? _singleCinematicUpdate(
  ProjectManifest before,
  ProjectManifest after,
) {
  if (before.copyWith(cinematics: after.cinematics) != after ||
      before.cinematics.length != after.cinematics.length) {
    return null;
  }
  final beforeIds = [for (final asset in before.cinematics) asset.id];
  final afterIds = [for (final asset in after.cinematics) asset.id];
  if (!_sameStrings(beforeIds, afterIds)) {
    return null;
  }
  final changedIndexes = <int>[];
  for (var index = 0; index < before.cinematics.length; index++) {
    if (before.cinematics[index] != after.cinematics[index]) {
      changedIndexes.add(index);
    }
  }
  if (changedIndexes.length != 1) {
    return null;
  }
  final index = changedIndexes.single;
  return NarrativeAssetUpdated(
    before: before,
    after: after,
    previousAsset: before.cinematics[index],
    asset: after.cinematics[index],
  );
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isConflictCode(String code) {
  return code == 'staleProjectRevision' || code == 'projectChangedBeforeCommit';
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}
