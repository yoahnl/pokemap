import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/services/narrative_document_session.dart';
import '../../features/personalization/application/project_presentation_asset_lifecycle.dart';
import 'atomic_project_manifest_persistence.dart';

typedef ProjectPresentationCanonicalSave =
    Future<void> Function({
      required ProjectPresentationProfile profile,
      required String expectedProjectRevision,
      required String operationId,
    });

/// Project-manifest document gateway dedicated to presentation-only sessions.
///
final class ProjectPresentationDocumentGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  ProjectPresentationDocumentGateway({
    required String projectPath,
    AtomicProjectManifestPersistence? persistence,
    ProjectPresentationAssetCleaner? assetCleaner,
    ProjectPresentationCanonicalSave? canonicalSave,
  }) : projectPath = _requiredPath(projectPath),
       _persistence = persistence ?? const AtomicProjectManifestPersistence(),
       _assetCleaner =
           assetCleaner ?? const ProjectPresentationAssetLifecycle(),
       _canonicalSave = canonicalSave;

  final String projectPath;
  final AtomicProjectManifestPersistence _persistence;
  final ProjectPresentationAssetCleaner _assetCleaner;
  final ProjectPresentationCanonicalSave? _canonicalSave;

  ProjectPresentationAssetCleanupResult? lastAssetCleanupResult;

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
    if (before.copyWith(presentation: after.presentation) != after) {
      return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'unsupportedDocumentMutation',
        message: 'This document session can persist presentation changes only.',
      );
    }

    final current = await _readOrFailure();
    if (current case NarrativeDocumentSaveFailed<ProjectManifest>()) {
      return current;
    }
    final live = current as NarrativeDocumentVersion<ProjectManifest>;
    if (live.revision != expectedRevision || live.document != before) {
      return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
        code: 'staleProjectRevision',
        message: 'The project changed since the Personalization Studio opened.',
        external: live,
      );
    }

    if (_canonicalSave case final canonicalSave?) {
      try {
        await canonicalSave(
          profile: after.effectivePresentation,
          expectedProjectRevision: expectedRevision,
          operationId: operationId,
        );
      } on Object catch (error) {
        final external = await _readOrFailure();
        if (external case NarrativeDocumentVersion<ProjectManifest>()) {
          if (external.revision != expectedRevision ||
              external.document != before) {
            return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
              code: 'staleProjectRevision',
              message: 'The project changed while the presentation was saved.',
              external: external,
            );
          }
        }
        return NarrativeDocumentSaveResult<ProjectManifest>.failed(
          code: 'canonicalPresentationUpdateFailed',
          message: 'The canonical presentation update failed: $error',
        );
      }
      return _finishCommittedSave(before: before, after: after);
    }

    late final NarrativeAuthoringPersistenceResult persistenceResult;
    try {
      persistenceResult = await _persistence.persistProjectDocument(
        projectPath: projectPath,
        operationId: operationId,
        before: before,
        after: after,
      );
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'projectManifestWriteFailed',
        message: 'The project manifest could not be persisted: $error',
      );
    }

    if (persistenceResult.status ==
        NarrativeAuthoringPersistenceStatus.committed) {
      return _finishCommittedSave(before: before, after: after);
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

  Future<NarrativeDocumentSaveResult<ProjectManifest>> _finishCommittedSave({
    required ProjectManifest before,
    required ProjectManifest after,
  }) async {
    final durable = await _readOrFailure();
    if (durable case NarrativeDocumentSaveFailed<ProjectManifest>()) {
      return durable;
    }
    final version = durable as NarrativeDocumentVersion<ProjectManifest>;
    if (version.document != after) {
      return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'durableDocumentMismatch',
        message:
            'Persistence completed but the durable document does not '
            'match the requested presentation update.',
      );
    }
    try {
      lastAssetCleanupResult = await _assetCleaner.cleanStaleAssets(
        projectRoot: File(projectPath).parent,
        previousProfile: before.effectivePresentation,
        currentProfile: after.effectivePresentation,
      );
    } on Object catch (error) {
      lastAssetCleanupResult = ProjectPresentationAssetCleanupResult.failed(
        error,
      );
    }
    return NarrativeDocumentSaveResult<ProjectManifest>.saved(version);
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

bool _isConflictCode(String code) {
  return code == 'staleProjectRevision' || code == 'projectChangedBeforeCommit';
}

String _requiredPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    throw ArgumentError.value(value, 'projectPath', 'must not be empty');
  }
  return path;
}
