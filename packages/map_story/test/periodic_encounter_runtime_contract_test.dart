import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {
  final definition = PeriodicEncounterDefinition(
    rewardId: 'weekly-creature',
    label: 'Créature hebdomadaire',
    consumeOnOutcomes: PeriodicEncounterOutcome.values.toSet(),
  );

  test('wild battle payload preserves policy and old battles have no policy', () {
    final oldJson = {'kind': 'battle', 'battleKind': 'wild', 'battleTemplateId': 'creature', 'declaredOutcomes': ['victory', 'captured', 'runaway', 'defeat']};
    final legacy = SceneBattlePayload.fromJson(oldJson);
    expect(legacy.periodicEncounter, isNull);
    expect(legacy.toJson(), oldJson);
    final payload = SceneBattlePayload.fromJson({...oldJson, 'periodicEncounter': definition.toJson()});
    expect(payload.periodicEncounter, definition);
    expect(SceneBattlePayload.fromJson(payload.toJson()), payload);
    expect(payload, isNot(legacy));
    for (final kind in ['trainer', 'static']) {
      expect(() => SceneBattlePayload(battleKind: kind, periodicEncounter: definition), throwsArgumentError);
    }
    expect(() => SceneBattlePayload.fromJson({...oldJson, 'periodicEncounter': null}), throwsFormatException);
    expect(() => SceneRuntimePlanIntent.startBattle(battleKind: 'trainer', periodicEncounter: definition), throwsArgumentError);
  });

}
