import 'package:map_core/map_core_domain.dart';

import 'scene_step_commands.dart';
import 'scene_step_list.dart';
import 'scene_step_projection.dart';

SceneStepEditResult editSceneStepNode(
  SceneAsset scene, {
  required SceneNode node,
}) {
  final list = projectSceneSteps(scene.graph);
  if (list is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notAList);
  }
  final previous = list.step(node.id) == null ? null : list.node(node.id);
  if (previous == null) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unknownStep);
  }
  if (previous.kind != node.kind) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unsupportedNodeKind);
  }
  if (previous == node) return SceneStepEdited(scene: scene, steps: list);
  final before = sceneStepPortOrder(previous, scene.graph);
  final after = sceneStepPortOrder(node, scene.graph);
  var samePorts = before.length == after.length;
  for (var index = 0; samePorts && index < before.length; index++) {
    samePorts = before[index] == after[index];
  }
  if (!samePorts) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  }
  final SceneAsset edited;
  try {
    edited = SceneAsset(
      id: scene.id,
      name: scene.name,
      executionProfile: scene.executionProfile,
      description: scene.description,
      storylineId: scene.storylineId,
      chapterId: scene.chapterId,
      tags: scene.tags,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: [
          for (final candidate in scene.graph.nodes)
            candidate.id == node.id ? node : candidate,
        ],
        edges: scene.graph.edges,
      ),
      layout: scene.layout,
      declaredOutcomes: scene.declaredOutcomes,
      metadata: scene.metadata,
    );
  } on ValidationException {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  } on ArgumentError {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  }
  final projected = projectSceneSteps(edited.graph);
  if (projected is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  }
  return SceneStepEdited(scene: edited, steps: projected);
}
