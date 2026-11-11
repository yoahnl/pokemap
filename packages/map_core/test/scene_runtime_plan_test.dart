import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene runtime plan V0', () {

    test('does not mutate the original SceneAsset', () {
      final scene = _minimalScene(
        declaredOutcomes: [
          SceneOutcome(id: 'scene_done', label: 'Done'),
        ],
      );
      final beforeJson = scene.toJson();

      checkSceneRuntimeCompilation(scene);

      expect(scene.toJson(), beforeJson);
    });
  });
}

SceneAsset _minimalScene({
  SceneGraphLayout? layout,
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Runtime Plan Test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: layout ??
        SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
    declaredOutcomes: declaredOutcomes,
  );
}

