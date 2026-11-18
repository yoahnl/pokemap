part of 'catalog_workshop_selection.dart';

Future<
    ({
      CatalogMetadataDocumentSelection selection,
      Map<String, Set<String>> ids,
    })> _targetStorylineDocuments(
  CatalogSnapshot snapshot,
  ProjectManifest manifest,
  String actionId,
  Map<String, Object?> parameters,
) async {
  final ids = actionId == 'storyline.chapter.rename'
      ? {
          'storylines': {narrativeStringParameter(parameters, 'storylineId')}
        }
      : _incomingStorylineDocumentIds(parameters);
  final selected = await CatalogMetadataDocuments.readDocuments(
      snapshot: snapshot, project: manifest, ids: ids);
  return (selection: selected, ids: ids);
}

Map<String, Set<String>> _incomingStorylineDocumentIds(
  Map<String, Object?> parameters,
) {
  final incoming = parameters['storyline'];
  final id = incoming is Map ? incoming['id'] : null;
  if (incoming is! Map || id is! String || id.isEmpty || id.trim() != id) {
    throw NarrativeAuthoringException(
      'storyline.invalid',
      'The Storyline payload needs a valid identity.',
    );
  }
  final factIds = CatalogWorkshopSelection._referenceIds(
      incoming, const {ScriptConditionParams.flagName});
  return {
    'storylines': {
      id,
      ...CatalogWorkshopSelection._referenceIds(incoming['relationships'],
          const {'sourceStorylineId', 'targetStorylineId'}),
    },
    if (factIds.isNotEmpty) 'facts': factIds,
  };
}

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

Future<CatalogMetadataDocumentSelection?> _storylineTrameDocuments(
    CatalogSnapshot snapshot,
    ProjectManifest manifest,
    String actionId,
    Map<String, Object?> parameters) async {
  if (!StorylineTrameActions.ids.contains(actionId)) return null;
  final renamed = actionId == 'storyline.milestone.rename'
      ? manifest.storylines
          .where((storyline) => storyline.id == parameters['storylineId'])
          .expand((storyline) => storyline.chapters)
          .expand((chapter) => chapter.steps)
          .where((step) => step.id == parameters['stepId'])
          .map(storylineMilestoneCompletionFactId)
          .whereType<String>()
          .toSet()
      : const <String>{};
  return CatalogMetadataDocuments.readDocuments(
      snapshot: snapshot,
      project: manifest,
      ids: {
        'storylines': {
          for (final storyline in manifest.storylines) storyline.id
        },
        if (StorylineTrameActions.factWritingActions.contains(actionId))
          'facts': renamed,
      });
}
