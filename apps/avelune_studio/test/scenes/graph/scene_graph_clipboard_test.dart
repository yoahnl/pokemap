import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_layout.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

final _scene = sceneOf(
  [
    startNode(),
    battleNode('fight'),
    routerNode('route', 'fight'),
    waitNode('wait'),
    endNode('end'),
  ],
  [
    link('start', 'fight'),
    SceneEdge(
      id: 'fight.victory',
      fromNodeId: 'fight',
      fromPortId: 'victory',
      toNodeId: 'route',
      kind: SceneEdgeKind.battleVictory,
    ),
    link('wait', 'end'),
  ],
);

void main() {
  test('copying keeps the steps, the links between them and their spacing, '
      'never Start', () {
    final fragment = copySceneGraphSteps(_scene, {'start', 'fight', 'route'})!;

    expect(fragment.nodes.map((n) => n.id), ['fight', 'route']);
    expect(fragment.edges.map((e) => e.id), ['fight.victory']);
    expect(fragment.offsets['fight'], const SceneGraphPoint(0, 0));
    expect(fragment.offsets['route'], const SceneGraphPoint(100, 10));
    expect(copySceneGraphSteps(_scene, {'start'}), isNull);
  });

  test('pasting gives new ids, rewires internal links and step references, '
      'places the copy at the pointer and reports what it created', () {
    final fragment = copySceneGraphSteps(_scene, {'fight', 'route'})!;
    var nodes = 0;
    var edges = 0;

    final result = pasteSceneGraphSteps(
      _scene,
      fragment,
      at: const SceneGraphPoint(800, 400),
      ids: SceneStepIds(
        node: () => 'copy_${nodes++}',
        edge: () => 'copy_link_${edges++}',
      ),
    );

    final pasted = (result as SceneGraphEdited).scene;
    expect(result.createdNodeIds, {'copy_0', 'copy_1'});
    final router = pasted.graph.nodes.singleWhere((n) => n.id == 'copy_1');
    expect(
      (router.payload as SceneBranchByOutcomePayload).sourceNodeId,
      'copy_0',
    );
    final link = pasted.graph.edges.singleWhere((e) => e.id == 'copy_link_0');
    expect(
      (link.fromNodeId, link.fromPortId, link.toNodeId),
      ('copy_0', 'victory', 'copy_1'),
    );
    final layouts = {
      for (final l in pasted.layout.nodeLayouts) l.nodeId: (l.x, l.y),
    };
    expect(layouts['copy_0'], (800, 400));
    expect(layouts['copy_1'], (900, 410));
    expect(pasted.graph.nodes, hasLength(_scene.graph.nodes.length + 2));
    expect(
      pasted.graph.edges.where((e) => e.toNodeId == 'copy_0'),
      isEmpty,
      reason: 'links from outside the copy are not duplicated',
    );
  });
}
