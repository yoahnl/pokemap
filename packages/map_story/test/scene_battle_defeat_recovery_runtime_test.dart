import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

Map<String, dynamic> battleJson([String? recovery]) => {
  'kind': 'battle',
  'battleKind': 'trainer',
  'trainerId': 'rival',
  if (recovery != null) 'defeatRecovery': recovery,
};

SceneAsset sceneFor(SceneBattlePayload payload) => SceneAsset(
  id: 'rival_scene',
  name: 'Rival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'battle', kind: SceneNodeKind.battle, payload: payload),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'battle',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'win',
        fromNodeId: 'battle',
        fromPortId: 'victory',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleVictory,
      ),
      SceneEdge(
        id: 'lose',
        fromNodeId: 'battle',
        fromPortId: 'defeat',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  ),
);

void main() {

  test('runtime planning preserves distinct recovery behavior', () {
    final continuing = buildSceneRuntimePlan(
      sceneFor(SceneBattlePayload.fromJson(battleJson('continueScene'))),
    );
    final recovering = buildSceneRuntimePlan(
      sceneFor(
        SceneBattlePayload.fromJson(battleJson('returnToRecoveryPoint')),
      ),
    );
    expect(continuing.plan, isNotNull);
    expect(recovering.plan, isNotNull);
    expect(
      recovering.plan!.nodes[1].intent,
      isNot(continuing.plan!.nodes[1].intent),
    );
  });

}
