import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_step_fixtures.dart';

SceneAsset linearScene() => sceneOf(
  [startNode(), waitNode('a'), pcNode('b'), waitNode('c'), endNode('end')],
  [
    link('start', 'a'),
    link('a', 'b'),
    link('b', 'c'),
    link('b', 'c', port: 'cancelled'),
    link('c', 'end'),
  ],
);

SceneAsset branchingScene() => sceneOf(
  [
    startNode(),
    conditionNode('if'),
    waitNode('a'),
    waitNode('after'),
    endNode('end'),
    endNode('early'),
    conditionNode('guard'),
  ],
  [
    link('start', 'if'),
    link('if', 'a', port: 'true'),
    link('if', 'guard', port: 'false'),
    link('guard', 'early', port: 'true'),
    link('guard', 'after', port: 'false'),
    link('a', 'after'),
    link('after', 'end'),
  ],
);

SceneStepEdited edited(SceneStepEditResult result) {
  expect(result, isA<SceneStepEdited>());
  return result as SceneStepEdited;
}

SceneStepEditRefusal refused(SceneStepEditResult result) {
  expect(result, isA<SceneStepEditRefused>());
  return (result as SceneStepEditRefused).reason;
}

List<String> rootIds(SceneStepEdited result) => [
  for (final step in result.steps.root.steps) step.nodeId,
];

SceneEdge edgeFrom(SceneAsset scene, String nodeId, String port) =>
    scene.graph.edges.singleWhere(
      (edge) => edge.fromNodeId == nodeId && edge.fromPortId == port,
    );

SceneNodeLayout layoutOf(SceneAsset scene, String nodeId) =>
    scene.layout.nodeLayouts.singleWhere((layout) => layout.nodeId == nodeId);
