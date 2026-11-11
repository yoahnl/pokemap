import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final definition = PeriodicEncounterDefinition(
    rewardId: 'weekly-creature',
    label: 'Créature hebdomadaire',
    consumeOnOutcomes: PeriodicEncounterOutcome.values.toSet(),
  );

  test('periodic encounter definition is strict and round trips', () {
    expect(PeriodicEncounterDefinition.fromJson(definition.toJson()), definition);
    expect(definition.toJson(), {
      'schemaVersion': 1,
      'rewardId': 'weekly-creature',
      'label': 'Créature hebdomadaire',
      'consumeOnOutcomes': ['victory', 'captured', 'fled'],
    });
    for (final patch in <Map<String, dynamic>>[
      {'schemaVersion': 2},
      {'schemaVersion': 1.0},
      {'rewardId': ' '},
      {'label': ''},
      {'consumeOnOutcomes': []},
      {'consumeOnOutcomes': ['defeat']},
      {'consumeOnOutcomes': ['captured', 'captured']},
      {'consumeOnOutcomes': ['captured', 1]},
      {'extra': true},
    ]) {
      expect(() => PeriodicEncounterDefinition.fromJson({...definition.toJson(), ...patch}), throwsFormatException);
    }
    expect(() => definition.consumeOnOutcomes.clear(), throwsUnsupportedError);
  });

  test('availability locator resolves a periodic battle without an item command', () {
    final scene = SceneAsset(id: 'encounter', name: 'Encounter', graph: SceneGraph(
      startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'battle', kind: SceneNodeKind.battle, payload: SceneBattlePayload(
          battleKind: 'wild', battleTemplateId: 'creature', periodicEncounter: definition)),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'battle', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'end', fromNodeId: 'battle', fromPortId: 'victory', toNodeId: 'end', kind: SceneEdgeKind.battleVictory),
      ]));
    final reference = PeriodicRewardReference(sceneId: scene.id, nodeId: 'battle', rewardId: definition.rewardId);
    final resolved = resolvePeriodicRewardReference(reference: reference, lookupScenes: (_) => [scene]);
    expect(resolved.isResolved, isTrue);
    final state = GameState(saveId: 'availability', gameplayCalendarState: GameplayCalendarState(observedLocalDay: '2026-11-06', dayRevision: 0));
    expect(evaluatePeriodicRewardCondition(reference: reference, expectedValue: true, gameState: state, lookupScenes: (_) => [scene]).passed, isTrue);
    final consumed = state.copyWith(periodicRewardState: PeriodicRewardState(claimsById: {
      definition.rewardId: PeriodicRewardClaim(revision: 1, lastClaimDayRevision: 0, lastClaimLocalDay: '2026-11-06'),
    }));
    expect(evaluatePeriodicRewardCondition(reference: reference, expectedValue: false, gameState: consumed, lookupScenes: (_) => [scene]).passed, isTrue);
    for (final expected in [true, false]) {
      final unavailable = evaluatePeriodicRewardCondition(reference: reference, expectedValue: expected, gameState: consumed, lookupScenes: (_) => []);
      expect(unavailable.unavailable, isTrue);
      expect(unavailable.passed, isFalse);
    }
  });
}
