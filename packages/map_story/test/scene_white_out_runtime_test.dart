import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

SceneAsset whiteOutScene() => SceneAsset(
  id: 'white_out',
  name: 'Défaite scénarisée',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'recovery',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.fromJson({'kind': 'whiteOut'}),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'recovery',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'return',
        fromNodeId: 'recovery',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

void main() {

  test('whiteOut builds an autonomous runtime command', () {
    final scene = whiteOutScene();
    final result = buildSceneRuntimePlan(scene);
    expect(result.canBuild, isTrue);
    final intent = result.plan!.nodes
        .singleWhere((node) => node.id == 'recovery')
        .intent;
    expect(intent.kind, SceneRuntimePlanIntentKind.executeInteractiveCommand);
    expect(intent.interactiveCommand!.toJson(), {'kind': 'whiteOut'});
    expect(SceneAsset.fromJson(scene.toJson()).graph.edges, scene.graph.edges);
  });

}
