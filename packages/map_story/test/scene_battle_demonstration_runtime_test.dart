import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

Map<String, dynamic> _demonstration() => {
  'playerTrainerId': 'guide',
  'bagItems': [
    {'itemId': 'poke-ball', 'quantity': 20},
  ],
  'choices': [
    {'kind': 'fight', 'moveIndex': 0},
    {'kind': 'capture', 'itemId': 'poke-ball'},
  ],
  'captureAlwaysSucceeds': true,
  'stepDelayMs': 500,
};

void main() {
  test(
    'battle demonstration survives strict payload serialization and planning',
    () {
      final payload = SceneBattlePayload.fromJson({
        'battleKind': 'wild',
        'battleTemplateId': 'capture-target',
        'demonstration': _demonstration(),
      });
      expect(payload.toJson()['demonstration'], _demonstration());
      expect(SceneBattlePayload.fromJson(payload.toJson()), payload);
      final plan = buildSceneRuntimePlan(_scene(payload)).plan!;
      expect(plan.nodes[1].intent.battleDemonstration, payload.demonstration);
      final updated = updateSceneBattlePayload(
        _scene(payload),
        nodeId: 'battle',
        battleKind: 'wild',
        battleTemplateId: 'other',
      );
      expect(updated.updatedPayload.demonstration, payload.demonstration);
    },
  );

}

SceneAsset _scene(SceneBattlePayload payload) => SceneAsset(
  id: 'demo',
  name: 'Demo',
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
