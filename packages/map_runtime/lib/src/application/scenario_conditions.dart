import 'package:map_core/map_core.dart';

class ScenarioConditions {
  const ScenarioConditions._();

  static ScriptCondition all(List<ScriptCondition> children) {
    return ScriptConditionFactory.allOf(children);
  }

  static ScriptCondition any(List<ScriptCondition> children) {
    return ScriptConditionFactory.anyOf(children);
  }

  static ScriptCondition not(ScriptCondition child) {
    return ScriptConditionFactory.not(child);
  }

  static ScriptCondition flagIsSet(String flagName) {
    return ScriptConditionFactory.flagIsSet(flagName.trim());
  }

  static ScriptCondition flagIsUnset(String flagName) {
    return ScriptConditionFactory.flagIsUnset(flagName.trim());
  }

  static ScriptCondition trainerDefeated(String trainerId) {
    return flagIsSet(_trainerDefeatedFlag(trainerId));
  }

  static ScriptCondition trainerNotDefeated(String trainerId) {
    return flagIsUnset(_trainerDefeatedFlag(trainerId));
  }

  static ScriptCondition fieldAbilityUnlocked(FieldAbility ability) {
    return ScriptConditionFactory.fieldAbilityUnlocked(ability);
  }

  static ScriptCondition partyHasUsableMove(String moveId) {
    return ScriptConditionFactory.partyHasUsableMove(moveId.trim());
  }

  static ScriptCondition eventIsConsumed(String eventId) {
    return ScriptConditionFactory.eventIsConsumed(eventId.trim());
  }

  static ScriptCondition playerOnMap(String mapId) {
    return ScriptConditionFactory.playerOnMap(mapId.trim());
  }

  static ScriptCondition variableEqualsInt(String variableName, int value) {
    return ScriptConditionFactory.variableEqualsInt(variableName.trim(), value);
  }

  static ScriptCondition variableEqualsString(
    String variableName,
    String value,
  ) {
    return ScriptConditionFactory.variableEqualsString(
      variableName.trim(),
      value,
    );
  }

  static ScriptCondition variableGreaterThan(String variableName, int value) {
    return ScriptConditionFactory.variableGreaterThan(
      variableName.trim(),
      value,
    );
  }

  static ScriptCondition variableLessThan(String variableName, int value) {
    return ScriptConditionFactory.variableLessThan(variableName.trim(), value);
  }

  static String _trainerDefeatedFlag(String trainerId) {
    return 'trainer_defeated:${trainerId.trim()}';
  }
}
