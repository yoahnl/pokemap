import 'package:map_core/map_core_domain.dart';

typedef EventSceneChoices = ({
  String? selectedId,
  SceneAsset? linked,
  Map<String, String> contexts,
  List<SceneAsset> visible,
});

EventSceneChoices eventSceneChoices({
  required List<SceneAsset> scenes,
  List<StorylineAsset> storylines = const [],
  String? selectedId,
  String query = '',
}) {
  final linked = scenes.where((scene) => scene.id == selectedId).firstOrNull;
  final contexts = _sceneContexts(scenes, storylines);
  final needle = query.trim().toLowerCase();
  return (
    selectedId: selectedId,
    linked: linked,
    contexts: contexts,
    visible: [
      if (linked != null && _matches(linked, contexts[linked.id], needle))
        linked,
      for (final scene in scenes)
        if (scene.id != selectedId &&
            _matches(scene, contexts[scene.id], needle))
          scene,
    ],
  );
}

Map<String, String> _sceneContexts(
  List<SceneAsset> scenes,
  List<StorylineAsset> stories,
) {
  final storylines = {for (final storyline in stories) storyline.id: storyline};
  return {
    for (final scene in scenes)
      scene.id: [
        if (storylines[scene.storylineId] case final storyline?) ...[
          storyline.title,
          if (storyline.chapters
                  .where((chapter) => chapter.id == scene.chapterId)
                  .firstOrNull
              case final chapter?)
            chapter.title,
        ],
        if (scene.description?.trim() case final description?
            when description.isNotEmpty)
          description,
        ...scene.tags,
      ].join(' · '),
  };
}

bool _matches(SceneAsset scene, String? context, String needle) =>
    needle.isEmpty ||
    scene.name.toLowerCase().contains(needle) ||
    scene.id.toLowerCase().contains(needle) ||
    (context?.toLowerCase().contains(needle) ?? false);

String eventSceneCountLabel({
  required int visible,
  required int total,
  required String query,
}) => query.trim().isEmpty
    ? '$total ${total > 1 ? 'scènes' : 'scène'}'
    : '$visible ${visible > 1 ? 'scènes' : 'scène'} sur $total';

String eventSceneEmptyLabel(String query) => query.trim().isEmpty
    ? 'Aucune scène dans ce projet.'
    : 'Aucune scène ne correspond à « ${query.trim()} ».';

String eventSceneRowStatus(
  SceneAsset scene, {
  required bool dirty,
  required bool linked,
}) =>
    '${scene.graph.nodes.length} blocs · ${dirty ? 'Modifiée localement' : 'Enregistrée'}${linked ? ' · Scène liée' : ''}';

String eventSceneDialogueLabel(
  ProjectManifest project,
  SceneYarnDialoguePayload dialogue,
) {
  final name =
      project.dialogues
          .where((item) => item.id == dialogue.dialogueId)
          .firstOrNull
          ?.name ??
      'Dialogue introuvable : ${dialogue.dialogueId}';
  final node = dialogue.yarnNodeName?.trim();
  return node == null || node.isEmpty
      ? 'Ouvrir le dialogue $name'
      : 'Ouvrir le dialogue $name · $node';
}
