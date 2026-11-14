import 'package:avelune_studio/features/scenes/application/steps/scene_step_list.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_projection.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_rebuild.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

SceneStepList listOf(SceneGraph graph) {
  final projection = projectSceneSteps(graph);
  expect(projection, isA<SceneStepList>());
  final list = projection as SceneStepList;
  expect(rebuildSceneStepGraph(list), graph);
  return list;
}

List<String> ids(SceneStepSequence sequence) => [
  for (final step in sequence.steps) step.nodeId,
];

SceneBlockStep blockAt(SceneStepSequence sequence, int index) =>
    sequence.steps[index] as SceneBlockStep;
