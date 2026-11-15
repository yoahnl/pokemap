import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_layout.dart';
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
    nodeLayouts: [
      for (final json in parameters['nodeLayouts']! as List)
        SceneNodeLayout.fromJson(json as Map<String, dynamic>),
    ],
  );
  return applied.scenes.single;
}

void expectPatchMatchesReplacement(
  SceneAsset before,
  SceneGraphEditResult edit,
) {
  expect(edit, isA<SceneGraphEdited>());
  final edited = edit as SceneGraphEdited;
  final graphOnly = applyThroughAuthoring(
    before,
    patchOf(before, edited.scene),
  );
  expect(graphOnly.graph, edited.scene.graph);
  expect(graphOnly.layout.edgeLayouts, edited.scene.layout.edgeLayouts);
  expect(graphOnly.layout.nodeLayouts, [
    for (final layout in edited.scene.layout.nodeLayouts)
      if (!edited.createdNodeIds.contains(layout.nodeId)) layout,
  ]);
  final result = sceneGraphPatchForScenes(base: before, current: edited.scene);
  expect(result, isA<SceneGraphPatchReady>());
  final patch = (result as SceneGraphPatchReady).patch;
  expect(
    patch.nodeLayouts.map((layout) => layout.nodeId).toSet(),
    edited.createdNodeIds,
  );
  expect(applyThroughAuthoring(before, patch), edited.scene);
}

void main() {
  test('the patch only carries what changed, in the canonical shape', () {
    final before = baseScene();
    final edit = addSceneGraphStep(
      before,
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.wait(durationMs: 1),
      ),
      at: const SceneGraphPoint(900, 300),
      from: (nodeId: 'a', portId: 'completed'),
      ids: countingIds(),
    ) as SceneGraphEdited;
    final patch = patchOf(before, edit.scene);
    expect(patch.upsertNodes.map((node) => node.id), ['new_node_1']);
    expect(patch.removeNodeIds, isEmpty);
    expect(patch.upsertEdges.map((edge) => edge.id), ['new_edge_1']);
    expect(patch.removeEdgeIds, ['a.completed']);
    final descriptor = SceneActions.descriptors.singleWhere(
      (candidate) => candidate.id == sceneGraphPatchActionId,
    );
    expect(
      patch.toParameters().keys.toSet(),
      (descriptor.extensions['parameters']! as List).toSet(),
    );
  });

  test('an untouched scene produces an empty patch', () {
    final before = baseScene();
    final patch = patchOf(before, before);
    expect(patch.isEmpty, isTrue);
    expect(applyThroughAuthoring(before, patch).graph, before.graph);
  });

  test('applying each graph edit as a patch equals replacing the whole '
      'scene', () {
    final before = baseScene();
    expectPatchMatchesReplacement(
      before,
      addSceneGraphStep(
        before,
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.openPc(),
        ),
        at: const SceneGraphPoint(400, 400),
        from: (nodeId: 'if', portId: 'false'),
        ids: countingIds(),
      ),
    );
    expectPatchMatchesReplacement(
      before,
      removeSceneGraphItems(before, nodeIds: {'b'}),
    );
    expectPatchMatchesReplacement(
      before,
      removeSceneGraphItems(before, edgeIds: {'c.completed'}),
    );
    expectPatchMatchesReplacement(
      before,
      connectSceneGraphExit(
        before,
        from: (nodeId: 'if', portId: 'false'),
        toNodeId: 'end',
        ids: countingIds(),
      ),
    );
    expectPatchMatchesReplacement(
      before,
      editSceneGraphStep(
        before,
        SceneNode(
          id: 'if',
          kind: SceneNodeKind.condition,
          title: 'Lundi',
          payload: weekdayCondition(),
        ),
      ),
    );
  });

  test('a scene whose other fields or kept layouts changed is not a patch', () {
    final before = baseScene();
    final renamed = SceneAsset.fromJson({
      ...before.toJson(),
      'name': 'Renamed',
    });
    final moved = SceneAsset.fromJson({
      ...before.toJson(),
      'layout': SceneGraphLayout(
        nodeLayouts: [
          for (final layout in before.layout.nodeLayouts)
            layout.nodeId == 'a'
                ? SceneNodeLayout(nodeId: 'a', x: 999, y: 999)
                : layout,
        ],
        edgeLayouts: before.layout.edgeLayouts,
      ).toJson(),
    });
    for (final (current, reason) in [
      (renamed, SceneGraphPatchUnsupportedReason.sceneChanged),
      (moved, SceneGraphPatchUnsupportedReason.layoutChanged),
    ]) {
      final result = sceneGraphPatchForScenes(base: before, current: current);
      expect(result, isA<SceneGraphPatchUnsupported>());
      expect((result as SceneGraphPatchUnsupported).reason, reason);
    }
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
