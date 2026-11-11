import 'package:avelune_studio/features/narrative/application/scene_node_references.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final scene = SceneAsset(
    id: 'lab',
    name: 'Laboratoire',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'first',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
  SceneNodeReference reference(String nodeId) =>
      SceneNodeReference(scene, scene.graph.nodes.firstWhere((n) => n.id == nodeId));

  test('a single reference is chosen without asking', () {
    final only = reference('start');
    expect(soleSceneNodeReference([only]), same(only));
  });

  test('no reference or several references still need a choice', () {
    expect(soleSceneNodeReference(const []), isNull);
    expect(soleSceneNodeReference([reference('start'), reference('end')]), isNull);
  });

  test('a reference reads as the scene name and the node name', () {
    final label = sceneNodeReferenceLabel(reference('start'));
    expect(label, startsWith('Laboratoire · '));
    expect(label.length, greaterThan('Laboratoire · '.length));
  });
}
