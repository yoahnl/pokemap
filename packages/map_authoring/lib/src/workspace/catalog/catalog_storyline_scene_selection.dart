part of 'catalog_workshop_selection.dart';

Future<({ProjectManifest project, Set<String> documents})?>
    _storylineSceneDocuments(CatalogSnapshot snapshot, ProjectManifest manifest,
        String actionId, Map<String, Object?> parameters) async {
  final sceneId = parameters['sceneId'];
  if (!StorylineTrameActions.sceneReadingActions.contains(actionId) ||
      sceneId is! String ||
      sceneId.isEmpty ||
      sceneId.trim() != sceneId) {
    return null;
  }
  final selection = await CatalogMetadataDocuments.readDocuments(
      snapshot: snapshot,
      project: manifest,
      ids: {
        'scenes': {sceneId}
      });
  return (project: selection.project, documents: {sceneId});
}
