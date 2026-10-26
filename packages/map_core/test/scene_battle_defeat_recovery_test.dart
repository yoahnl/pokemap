import 'package:map_core/map_core.dart';
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
  test('scripted battles continue the scene by default', () {
    final payload = SceneBattlePayload.fromJson(battleJson());
    expect(payload.defeatRecovery, SceneBattleDefeatRecovery.continueScene);
  });

  test('default recovery does not rewrite unrelated battle payloads', () {
    final payload = SceneBattlePayload.fromJson(battleJson());
    expect(payload.toJson().containsKey('defeatRecovery'), isFalse);
  });

  test('recovery choice survives serialization', () {
    final payload = SceneBattlePayload.fromJson(
      battleJson('returnToRecoveryPoint'),
    );
    expect(payload.toJson()['defeatRecovery'], 'returnToRecoveryPoint');
    expect(SceneBattlePayload.fromJson(payload.toJson()), payload);
  });

  test('unknown recovery behavior is rejected', () {
    expect(
      () => SceneBattlePayload.fromJson(battleJson('discardProgress')),
      throwsA(isA<FormatException>()),
    );
  });

  test('recovery choice participates in payload identity', () {
    final continuing = SceneBattlePayload.fromJson(battleJson('continueScene'));
    final recovering = SceneBattlePayload.fromJson(
      battleJson('returnToRecoveryPoint'),
    );
    expect(recovering, isNot(continuing));
  });

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

  test('changing a linked trainer retains its recovery choice', () {
    final scene = sceneFor(
      SceneBattlePayload.fromJson(battleJson('returnToRecoveryPoint')),
    );
    final updated = updateSceneBattlePayload(
      scene,
      nodeId: 'battle',
      trainerId: 'other_rival',
    );
    expect(updated.updatedPayload.trainerId, 'other_rival');
    expect(
      updated.updatedPayload.toJson()['defeatRecovery'],
      'returnToRecoveryPoint',
    );
  });

  for (final dimension in ProjectDimension.values) {
    test('recovery availability is explicit for $dimension projects', () {
      final scene = sceneFor(
        SceneBattlePayload.fromJson(battleJson('returnToRecoveryPoint')),
      );
      final report = diagnoseSceneAgainstProject(
        scene,
        ProjectManifest(
          name: 'Recovery',
          maps: const [],
          tilesets: const [],
          settings: ProjectSettings(dimension: dimension),
        ),
      );
      expect(
        report.diagnostics.any(
          (d) => d.code.name == 'battleRecoveryUnsupportedDimension',
        ),
        isFalse,
      );
    });
  }
}
