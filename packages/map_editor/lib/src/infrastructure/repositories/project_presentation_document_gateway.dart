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
    implements NarrativeDocumentGateway<ProjectPresentationProfile> {
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
  ProjectManifest? _currentProject;

  ProjectPresentationAssetCleanupResult? lastAssetCleanupResult;
  ProjectManifest get currentProject => _currentProject!;

  @override
  Future<NarrativeDocumentVersion<ProjectPresentationProfile>> read() async {
    final bytes = await File(projectPath).readAsBytes();
    final project = decodeValidatedNarrativeEventAuthoringProject(
      bytes,
    ).manifest;
    _currentProject = project;
    return NarrativeDocumentVersion<ProjectPresentationProfile>(
      revision: narrativeEventBytesFingerprint(bytes),
      document: project.effectivePresentation,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectPresentationProfile>> save({
    required String expectedRevision,
    required ProjectPresentationProfile before,
    required ProjectPresentationProfile after,
    required String operationId,
  }) async {
    final current = await _readOrFailure();
    if (current
        case NarrativeDocumentSaveFailed<ProjectPresentationProfile>()) {
      return current;
    }
    final live =
        current as NarrativeDocumentVersion<ProjectPresentationProfile>;
    if (live.revision != expectedRevision || live.document != before) {
      return NarrativeDocumentSaveResult<ProjectPresentationProfile>.conflicted(
        code: 'staleProjectRevision',
        message: 'The project changed since the Personalization Studio opened.',
        external: live,
      );
    }

    if (_canonicalSave case final canonicalSave?) {
      try {
        await canonicalSave(
          profile: after,
          expectedProjectRevision: expectedRevision,
          operationId: operationId,
        );
      } on Object catch (error) {
        final external = await _readOrFailure();
        if (external
            case NarrativeDocumentVersion<ProjectPresentationProfile>()) {
          if (external.revision != expectedRevision ||
              external.document != before) {
            return NarrativeDocumentSaveResult<
              ProjectPresentationProfile
            >.conflicted(
              code: 'staleProjectRevision',
              message: 'The project changed while the presentation was saved.',
              external: external,
            );
          }
        }
        return NarrativeDocumentSaveResult<ProjectPresentationProfile>.failed(
          code: 'canonicalPresentationUpdateFailed',
          message: 'The canonical presentation update failed: $error',
        );
      }
      return _finishCommittedSave(before: before, after: after);
    }

    late final NarrativeAuthoringPersistenceResult persistenceResult;
    try {
      final liveProject = _currentProject!;
      persistenceResult = await _persistence.persistProjectDocument(
        projectPath: projectPath,
        operationId: operationId,
        before: liveProject,
        after: liveProject.copyWith(presentation: after),
      );
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectPresentationProfile>.failed(
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
      if (external
          case NarrativeDocumentSaveFailed<ProjectPresentationProfile>()) {
        return external;
      }
      return NarrativeDocumentSaveResult<ProjectPresentationProfile>.conflicted(
        code: persistenceResult.code,
        message: persistenceResult.message,
        external:
            external as NarrativeDocumentVersion<ProjectPresentationProfile>,
      );
    }
    return NarrativeDocumentSaveResult<ProjectPresentationProfile>.failed(
      code: persistenceResult.code,
      message: persistenceResult.message,
    );
  }

  Future<NarrativeDocumentSaveResult<ProjectPresentationProfile>>
  _finishCommittedSave({
    required ProjectPresentationProfile before,
    required ProjectPresentationProfile after,
  }) async {
    final durable = await _readOrFailure();
    if (durable
        case NarrativeDocumentSaveFailed<ProjectPresentationProfile>()) {
      return durable;
    }
    final version =
        durable as NarrativeDocumentVersion<ProjectPresentationProfile>;
    if (version.document != after) {
      return const NarrativeDocumentSaveResult<
        ProjectPresentationProfile
      >.failed(
        code: 'durableDocumentMismatch',
        message:
            'Persistence completed but the durable document does not '
            'match the requested presentation update.',
      );
    }
    try {
      lastAssetCleanupResult = await _assetCleaner.cleanStaleAssets(
        projectRoot: File(projectPath).parent,
        previousProfile: before,
        currentProfile: after,
      );
    } on Object catch (error) {
      lastAssetCleanupResult = ProjectPresentationAssetCleanupResult.failed(
        error,
      );
    }
    return NarrativeDocumentSaveResult<ProjectPresentationProfile>.saved(
      version,
    );
  }

  Future<Object> _readOrFailure() async {
    try {
      return await read();
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectPresentationProfile>.failed(
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
