import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_layout.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

SceneAsset _unplaced(List<SceneNode> nodes, List<SceneEdge> edges) =>
    SceneAsset(id: 'scene', name: 'Scene', graph: graphOf(nodes, edges));

SceneAsset _edited(SceneGraphEditResult result) =>
    (result as SceneGraphEdited).scene;

SceneGraphEditRefusal _refused(SceneGraphEditResult result) =>
    (result as SceneGraphEditRefused).reason;

final _branching = _unplaced(
  [startNode(), conditionNode('check'), waitNode('wait'), endNode('end')],
  [
    link('start', 'check'),
    link('check', 'wait', port: 'true'),
    link('wait', 'end'),
  ],
);

void main() {
  test('linking an exit adds a typed link and replaces the previous one', () {
    final linked = _edited(
      connectSceneGraphExit(
        _branching,
        from: (nodeId: 'check', portId: 'false'),
        toNodeId: 'end',
        ids: countingIds(),
      ),
    );
    final added = linked.graph.edges.singleWhere((e) => e.id == 'new_edge_1');
    expect(added.fromPortId, 'false');
    expect(added.toNodeId, 'end');
    expect(added.kind, SceneEdgeKind.conditionFalse);

    final relinked = _edited(
      connectSceneGraphExit(
        linked,
        from: (nodeId: 'check', portId: 'true'),
        toNodeId: 'end',
        ids: SceneStepIds(node: () => 'unused', edge: () => 'relink'),
      ),
    );
    final fromTrue = relinked.graph.edges.where(
      (edge) => edge.fromNodeId == 'check' && edge.fromPortId == 'true',
    );
    expect(fromTrue.map((edge) => edge.toNodeId), ['end']);
    expect(relinked.graph.edges.where((e) => e.id == 'check.true'), isEmpty);
  });

  test('a link that would loop, enter Start, enter itself or use an unknown '
      'exit is refused', () {
    SceneGraphEditRefusal refused(String from, String port, String to) =>
        _refused(
          connectSceneGraphExit(
            _branching,
            from: (nodeId: from, portId: port),
            toNodeId: to,
            ids: countingIds(),
          ),
        );

    expect(
      refused('wait', 'completed', 'check'),
      SceneGraphEditRefusal.wouldLoop,
    );
    expect(
      refused('check', 'false', 'start'),
      SceneGraphEditRefusal.startHasNoInput,
    );
    expect(
      refused('wait', 'completed', 'wait'),
      SceneGraphEditRefusal.intoItself,
    );
    expect(refused('check', 'maybe', 'end'), SceneGraphEditRefusal.unknownExit);
    expect(
      refused('ghost', 'completed', 'end'),
      SceneGraphEditRefusal.unknownStep,
    );
    expect(
      connectSceneGraphExit(
        _branching,
        from: (nodeId: 'wait', portId: 'completed'),
        toNodeId: 'end',
        ids: countingIds(),
      ),
      isA<SceneGraphEdited>(),
      reason: 'relinking an exit to its current target is not a loop',
    );
  });

  test('the first edit of an unplaced scene stores every card where it was '
      'shown, so nothing jumps', () {
    final shown = {
      for (final card in projectSceneGraph(_branching).cards)
        card.id: card.position,
    };

    final moved = _edited(
      moveSceneGraphSteps(_branching, {'wait': const SceneGraphPoint(900, 40)}),
    );

    final stored = {
      for (final layout in moved.layout.nodeLayouts)
        layout.nodeId: SceneGraphPoint(layout.x, layout.y),
    };
    expect(stored['wait'], const SceneGraphPoint(900, 40));
    for (final id in ['start', 'check', 'end']) {
      expect(stored[id], shown[id], reason: id);
    }
    expect(projectSceneGraph(moved).needsLayoutSave, isFalse);
    expect(moved.graph, _branching.graph);
  });

  test(
    'a step added from a dropped link is placed and linked to that exit',
    () {
      final result = addSceneGraphStep(
        _branching,
        kind: SceneNodeKind.end,
        at: const SceneGraphPoint(500, 300),
        from: (nodeId: 'check', portId: 'false'),
        ids: countingIds(),
      );

      final scene = _edited(result);
      expect((result as SceneGraphEdited).createdNodeIds, {'new_node_1'});
      expect(
        scene.layout.nodeLayouts.singleWhere((l) => l.nodeId == 'new_node_1'),
        SceneNodeLayout(nodeId: 'new_node_1', x: 500, y: 300),
      );
      final link = scene.graph.edges.singleWhere(
        (edge) => edge.toNodeId == 'new_node_1',
      );
      expect((link.fromNodeId, link.fromPortId), ('check', 'false'));
    },
  );

  test('removing steps drops their links and their stored places; Start '
      'and steps another one depends on stay', () {
    final placed = sceneOf(
      [startNode(), waitNode('wait'), endNode('end')],
      [link('start', 'wait'), link('wait', 'end')],
    );

    final removed = _edited(removeSceneGraphItems(placed, nodeIds: {'wait'}));
    expect(removed.graph.nodes.map((n) => n.id), ['start', 'end']);
    expect(removed.graph.edges, isEmpty);
    expect(removed.layout.edgeLayouts, isEmpty);
    expect(removed.layout.nodeLayouts.map((l) => l.nodeId), ['start', 'end']);

    final unlinked = _edited(
      removeSceneGraphItems(placed, edgeIds: {'wait.completed'}),
    );
    expect(unlinked.graph.edges.map((e) => e.id), ['start.completed']);
    expect(unlinked.graph.nodes, hasLength(3));

    expect(
      _refused(removeSceneGraphItems(placed, nodeIds: {'start', 'wait'})),
      SceneGraphEditRefusal.startCannotBeRemoved,
    );
    final routed = sceneOf(
      [startNode(), battleNode('fight'), routerNode('route', 'fight')],
      [link('start', 'fight')],
    );
    expect(
      _refused(removeSceneGraphItems(routed, nodeIds: {'fight'})),
      SceneGraphEditRefusal.referencedElsewhere,
    );
  });
}
