part of 'map_builder_story_binding.dart';

extension MapStorySceneEditing on MapBuilderStoryBinding {
  String? detachScene(String eventId, String name) {
    final project = maps.project;
    final record = project == null
        ? null
        : behaviours
              .registry(project)
              ?.records
              .where((record) => record.id == eventId)
              .firstOrNull;
    final sceneId = record?.sceneId;
    final scene = sceneId == null ? null : sceneOf(sceneId);
    if (record == null || scene == null) return null;
    final id = _lineIds().sceneId;
    final copy = SceneAsset.fromJson({
      ...scene.toJson(),
      'id': id,
      'name': name,
    });
    final detached = _operate(
      [record],
      [
        (c) => setNarrativeEventScene(
          context: c,
          expectedRevision: c.revision,
          eventId: record.id,
          sceneId: id,
        ),
      ],
      stage: (draft) {
        draft.load(StoryDraftKind.scene, id, null);
        draft.put(StoryDraftKind.scene, copy);
      },
    );
    return detached ? id : null;
  }
}
