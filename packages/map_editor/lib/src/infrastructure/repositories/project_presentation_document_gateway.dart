import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/services/narrative_document_session.dart';

/// Project-manifest document gateway dedicated to presentation-only sessions.
///
/// PST-011 uses the read boundary to establish a trustworthy saved baseline.
/// The compare-and-swap save implementation is activated by PST-012.
final class ProjectPresentationDocumentGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  ProjectPresentationDocumentGateway({required String projectPath})
      : projectPath = _requiredPath(projectPath);

  final String projectPath;

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
    return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
      code: 'personalizationSaveUnavailable',
      message: 'Personalization saving is not available in this Studio lot.',
    );
  }
}

String _requiredPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    throw ArgumentError.value(value, 'projectPath', 'must not be empty');
  }
  return path;
}
