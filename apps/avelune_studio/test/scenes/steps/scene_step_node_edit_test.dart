import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_node_edit.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_patch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_step_fixtures.dart';

SceneAsset linear() => sceneOf(
  [startNode(), factNode('fact'), conditionNode('if'), endNode('end')],
  [
    link('start', 'fact'),
    link('fact', 'if'),
    link('if', 'end', port: 'true'),
    link('if', 'end', port: 'false'),
  ],
);

void main() {
  test('editing a step payload changes exactly that node', () {
    final before = linear();
    final next = SceneNode(
      id: 'fact',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.setFact(factId: 'other', value: false),
      ),
    );
    final edit = editSceneStepNode(before, node: next);
    expect(edit, isA<SceneStepEdited>());
    final scene = (edit as SceneStepEdited).scene;
    expect(scene.graph.edges, before.graph.edges);
    expect(scene.layout, before.layout);
    final patch = (sceneGraphPatchForScenes(
      base: before,
      current: scene,
    ) as SceneGraphPatchReady).patch;
    expect(patch.upsertNodes, [next]);
    expect(patch.upsertEdges, isEmpty);
    expect(patch.removeNodeIds, isEmpty);
  });

  test('an unchanged node returns the same scene', () {
    final before = linear();
    final edit = editSceneStepNode(before, node: before.graph.nodes[1]);
    expect((edit as SceneStepEdited).scene, same(before));
  });

  test('refuses unknown steps, kind changes and port changes', () {
    final before = linear();
    SceneStepEditRefusal refusal(SceneNode node) =>
        (editSceneStepNode(before, node: node) as SceneStepEditRefused).reason;
    expect(
      refusal(SceneNode(id: 'end', kind: SceneNodeKind.end)),
      SceneStepEditRefusal.unknownStep,
    );
    expect(
      refusal(SceneNode(id: 'ghost', kind: SceneNodeKind.end)),
      SceneStepEditRefusal.unknownStep,
    );
    expect(
      refusal(dialogueNode('fact')),
      SceneStepEditRefusal.unsupportedNodeKind,
    );
    expect(
      refusal(
        SceneNode(
          id: 'fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.giveItem(itemId: 'potion', quantity: 1),
          ),
        ),
      ),
      SceneStepEditRefusal.notRepresentable,
    );
  });
}
