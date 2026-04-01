import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('ScenarioConditions', () {
    test('trainerDefeated builds flagIsSet with trainer convention', () {
      final condition = ScenarioConditions.trainerDefeated('leader_1');

      expect(condition.type, equals(ScriptConditionType.flagIsSet));
      expect(
        condition.params[ScriptConditionParams.flagName],
        equals('trainer_defeated:leader_1'),
      );
    });

    test('trainerNotDefeated builds flagIsUnset with trainer convention', () {
      final condition = ScenarioConditions.trainerNotDefeated('leader_1');

      expect(condition.type, equals(ScriptConditionType.flagIsUnset));
      expect(
        condition.params[ScriptConditionParams.flagName],
        equals('trainer_defeated:leader_1'),
      );
    });

    test('composed conditions evaluate correctly with ScriptConditionEvaluator',
        () {
      const evaluator = ScriptConditionEvaluator();
      final condition = ScenarioConditions.all([
        ScenarioConditions.flagIsSet('met_professor'),
        ScenarioConditions.fieldAbilityUnlocked(FieldAbility.surf),
        ScenarioConditions.not(
          ScenarioConditions.trainerDefeated('leader_1'),
        ),
      ]);

      const state = GameState(
        saveId: 'save',
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
        storyFlags: StoryFlags(activeFlags: {'met_professor'}),
      );

      expect(evaluator.evaluate(condition, state), isTrue);
    });

    test('variable helpers keep numeric comparators usable', () {
      const evaluator = ScriptConditionEvaluator();
      final condition = ScenarioConditions.all([
        ScenarioConditions.variableEqualsInt('wins', 3),
        ScenarioConditions.variableGreaterThan('wins', 2),
        ScenarioConditions.variableLessThan('wins', 4),
      ]);

      const state = GameState(
        saveId: 'save',
        scriptVariables: ScriptVariables(
          values: {'wins': ScriptVariableValue.int(3)},
        ),
      );

      expect(evaluator.evaluate(condition, state), isTrue);
    });
  });
}
