import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_patch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_step_fixtures.dart';

SceneAsset baseScene() => sceneOf(
  [
    startNode(),
    waitNode('a'),
    conditionNode('if'),
    pcNode('b'),
    waitNode('c'),
    waitNode('after'),
    endNode('end'),
    endNode('early'),
  ],
  [
    link('start', 'a'),
    link('a', 'if'),
    link('if', 'b', port: 'true'),
    link('if', 'early', port: 'false'),
    link('b', 'c'),
    link('b', 'c', port: 'cancelled'),
    link('c', 'after'),
    link('after', 'end'),
  ],
);

ProjectManifest projectWith(SceneAsset scene) => ProjectManifest(
  name: 'Steps',
  maps: const [],
  tilesets: const [],
  scenes: [scene],
);

SceneGraphPatch patchOf(SceneAsset before, SceneAsset after) {
  final result = sceneGraphPatchBetween(
    sceneId: before.id,
    before: before.graph,
    after: after.graph,
  );
  expect(result, isA<SceneGraphPatchReady>());
  return (result as SceneGraphPatchReady).patch;
}

SceneAsset applyThroughAuthoring(SceneAsset before, SceneGraphPatch patch) {
  final parameters = patch.toParameters();
  final applied = const SceneActions().patchGraph(
    projectWith(before),
    maps: const [],
    sceneId: parameters['sceneId']! as String,
    upsertNodes: [
      for (final json in parameters['upsertNodes']! as List)
        SceneNode.fromJson(json as Map<String, dynamic>),
    ],
    removeNodeIds: parameters['removeNodeIds']! as List<String>,
    upsertEdges: [
      for (final json in parameters['upsertEdges']! as List)
        SceneEdge.fromJson(json as Map<String, dynamic>),
    ],
    removeEdgeIds: parameters['removeEdgeIds']! as List<String>,
  );
  return applied.scenes.single;
}

void expectPatchMatchesReplacement(
  SceneAsset before,
  SceneStepEditResult edit,
) {
  expect(edit, isA<SceneStepEdited>());
  final edited = edit as SceneStepEdited;
  final patched = applyThroughAuthoring(before, patchOf(before, edited.scene));
  expect(patched.graph, edited.scene.graph);
  expect(patched.layout.edgeLayouts, edited.scene.layout.edgeLayouts);
  expect(patched.layout.nodeLayouts, [
    for (final layout in edited.scene.layout.nodeLayouts)
      if (!edited.createdNodeIds.contains(layout.nodeId)) layout,
  ]);
}

void main() {
  test('the patch only carries what changed, in the canonical shape', () {
    final before = baseScene();
    final edit = insertSceneStep(
      before,
      at: const SceneStepSlot(index: 1),
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.wait(durationMs: 1),
      ),
      ids: countingIds(),
    ) as SceneStepEdited;
    final patch = patchOf(before, edit.scene);
    expect(patch.upsertNodes.map((node) => node.id), ['new_node_1']);
    expect(patch.removeNodeIds, isEmpty);
    expect(patch.upsertEdges.map((edge) => edge.id), [
      'a.completed',
      'new_edge_1',
    ]);
    expect(patch.removeEdgeIds, isEmpty);
    final descriptor = SceneActions.descriptors.singleWhere(
      (candidate) => candidate.id == sceneGraphPatchActionId,
    );
    expect(
      patch.toParameters().keys.toSet(),
      (descriptor.extensions['parameters']! as List).toSet(),
    );
  });

  test('an untouched list produces an empty patch', () {
    final before = baseScene();
    final patch = patchOf(before, before);
    expect(patch.isEmpty, isTrue);
    expect(applyThroughAuthoring(before, patch).graph, before.graph);
  });

  test('applying each command patch equals replacing the whole scene', () {
    final before = baseScene();
    expectPatchMatchesReplacement(
      before,
      insertSceneStep(
        before,
        at: const SceneStepSlot(blockNodeId: 'if', index: 1),
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.openPc(),
        ),
        ids: countingIds(),
      ),
    );
    expectPatchMatchesReplacement(
      before,
      removeSceneStep(before, nodeId: 'if', ids: countingIds()),
    );
    expectPatchMatchesReplacement(
      before,
      removeSceneStep(before, nodeId: 'b', ids: countingIds()),
    );
    expectPatchMatchesReplacement(
      before,
      moveSceneStep(
        before,
        nodeId: 'a',
        to: const SceneStepSlot(blockNodeId: 'if', index: 2),
        ids: countingIds(),
      ),
    );
    expectPatchMatchesReplacement(
      before,
      wrapSceneStepsInCondition(
        before,
        from: const SceneStepSlot(blockNodeId: 'if', index: 0),
        count: 2,
        condition: weekdayCondition(),
        ids: countingIds(),
      ),
    );
  });

  test('a reordered graph cannot be expressed as a patch', () {
    final before = baseScene();
    final reordered = SceneGraph(
      startNodeId: before.graph.startNodeId,
      nodes: before.graph.nodes.reversed.toList(),
      edges: before.graph.edges,
    );
    final result = sceneGraphPatchBetween(
      sceneId: before.id,
      before: before.graph,
      after: reordered,
    );
    expect(result, isA<SceneGraphPatchUnsupported>());
    expect(
      (result as SceneGraphPatchUnsupported).reason,
      SceneGraphPatchUnsupportedReason.nodeOrderChanged,
    );
  });
}
