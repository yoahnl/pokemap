import 'package:map_authoring/map_authoring.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/narrative_index_port.dart';

Future<T> readNarrativeIndex<T>(
  ProjectSession session,
  ProjectFileReader reader,
  Future<T> Function(AuthoringReadApi reads, ProjectHandle handle) body,
) async {
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [session.directoryPath],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    catalogMetadataFields: const {},
    workshopScope: true,
  );
  final opened = await opener.openProject(session.directoryPath);
  try {
    return await body(
      AuthoringReadApi(
        openService: opener,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
      ),
      opened.projectHandle,
    );
  } on AuthoringQueryException catch (failure) {
    throw switch (failure.code) {
      'query.narrative_titles_preparation_required' =>
        const NarrativeIndexPreparationRequired('narrativeTitles'),
      'query.narrative_usages_preparation_required' =>
        const NarrativeIndexPreparationRequired('narrativeUsages'),
      'query.narrative_events_preparation_required' =>
        const NarrativeIndexPreparationRequired('narrativeEvents'),
      'query.map_directory_preparation_required' =>
        const NarrativeIndexPreparationRequired('mapDirectory'),
      'query.narrative_titles_catalog_required' ||
      'query.narrative_usages_catalog_required' ||
      'query.storyline_read_catalog_required' ||
      'query.map_directory_catalog_required' ||
      'query.scene_document_catalog_required' =>
        const NarrativeIndexUnavailable(),
      _ => failure,
    };
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
}
