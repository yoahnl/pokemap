import 'package:map_core/map_core_domain.dart';

import '../../scenes/application/scene_labels.dart';

final class SceneNodeReference {
  const SceneNodeReference(this.scene, this.node);
  final SceneAsset scene;
  final SceneNode node;
}

List<SceneNodeReference> sceneNodesWhere(
  Iterable<SceneAsset> scenes,
  bool Function(SceneNode node) matches,
) => [
  for (final scene in scenes)
    for (final node in scene.graph.nodes)
      if (matches(node)) SceneNodeReference(scene, node),
];

List<SceneNodeReference> sceneNodesPlayingCinematic(
  Iterable<SceneAsset> scenes,
  String cinematicId,
) => sceneNodesWhere(
  scenes,
  (node) => switch (node.payload) {
    SceneCinematicPayload(cinematicId: final id) => id == cinematicId,
    _ => false,
  },
);

List<SceneNodeReference> sceneNodesStartingTrainerBattle(
  Iterable<SceneAsset> scenes,
  String trainerId,
) => sceneNodesWhere(
  scenes,
  (node) => switch (node.payload) {
    SceneBattlePayload(trainerId: final id) => id == trainerId,
    _ => false,
  },
);

List<SceneYarnDialoguePayload> sceneDialogues(SceneAsset scene) {
  final seen = <String>{};
  return [
    for (final node in scene.graph.nodes)
      if (node.payload case final SceneYarnDialoguePayload payload
          when seen.add('${payload.dialogueId}\u0000${payload.yarnNodeName}'))
        payload,
  ];
}

String sceneNodeReferenceLabel(SceneNodeReference reference) =>
    '${reference.scene.name} · ${sceneNodeName(reference.scene.graph, reference.node.id)}';

SceneNodeReference? soleSceneNodeReference(
  List<SceneNodeReference> references,
) => references.length == 1 ? references.single : null;
