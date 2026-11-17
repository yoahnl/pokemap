import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/narrative_index_port.dart';

Future<T> readNarrativeIndex<T>(
  ProjectSession session,
  ProjectFileReader reader,
  Future<T> Function(AuthoringReadApi reads, ProjectHandle handle) body, {
  bool initializeSceneOwners = true,
}) => _withNarrativeProject(
  session,
  reader,
  (opener, handles, handle) => body(
    AuthoringReadApi(
      openService: opener,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    ),
    handle,
  ),
  initializeSceneOwners: initializeSceneOwners,
);

Future<T> readNarrativeCatalog<T>(
  ProjectSession session,
  ProjectFileReader reader,
  Future<T> Function(PortableProjectCatalog catalog) body,
) => _withNarrativeProject(session, reader, (opener, _, handle) async {
  final catalog = await opener.catalogProject(handle);
  if (catalog == null) throw const NarrativeIndexUnavailable();
  return catalog.read(body);
});

Future<T> _withNarrativeProject<T>(
  ProjectSession session,
  ProjectFileReader reader,
  Future<T> Function(
    ProjectOpenService opener,
    WorkspaceHandleStore handles,
    ProjectHandle handle,
  )
  body, {
  bool initializeSceneOwners = true,
}) async {
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [session.directoryPath],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    initializeSceneOwners: initializeSceneOwners,
    catalogMetadataFields: const {},
    workshopScope: true,
  );
  final opened = await opener.openProject(session.directoryPath);
  try {
    return await body(opener, handles, opened.projectHandle);
  } on AuthoringQueryException catch (failure) {
    throw switch (failure.code) {
      'query.narrative_titles_preparation_required' =>
        const NarrativeIndexPreparationRequired('narrativeTitles'),
      'query.narrative_usages_preparation_required' =>
        const NarrativeIndexPreparationRequired('narrativeUsages'),
      'query.narrative_events_preparation_required' =>
        const NarrativeIndexPreparationRequired('narrativeEvents'),
      'query.dialogue_document_preparation_required' =>
        const NarrativeIndexPreparationRequired('default'),
      'query.map_directory_preparation_required' =>
        const NarrativeIndexPreparationRequired('mapDirectory'),
      'query.narrative_titles_catalog_required' ||
      'query.narrative_usages_catalog_required' ||
      'query.storyline_read_catalog_required' ||
      'query.map_directory_catalog_required' ||
      'query.scene_document_catalog_required' =>
        const NarrativeIndexUnavailable(),
      'query.dialogue_document_catalog_required' =>
        const NarrativeIndexUnavailable(),
      _ => failure,
    };
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
}
