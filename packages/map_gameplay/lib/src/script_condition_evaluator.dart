import 'package:map_core/map_core.dart';

/// Évaluateur pur de conditions de script.
///
/// Prend un [GameState] et un contexte optionnel,
/// retourne true/false pour une condition donnée.
///
/// Ne contient aucun effet de bord.
/// Totalement testable et déterministe.
class ScriptConditionEvaluator {
  const ScriptConditionEvaluator();

  /// Évalue une condition contre un état de partie.
  bool evaluate(
    ScriptCondition condition,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    switch (condition.type) {
      case ScriptConditionType.allOf:
        return _evaluateAllOf(condition.children, state, context: context);
      case ScriptConditionType.anyOf:
        return _evaluateAnyOf(condition.children, state, context: context);
      case ScriptConditionType.not:
        return _evaluateNot(condition.children, state, context: context);
      case ScriptConditionType.flagIsSet:
        return _evaluateFlagIsSet(condition.params, state);
      case ScriptConditionType.flagIsUnset:
        return _evaluateFlagIsUnset(condition.params, state);
      case ScriptConditionType.variableEquals:
        return _evaluateVariableEquals(condition.params, state);
      case ScriptConditionType.variableGreaterThan:
        return _evaluateVariableGreaterThan(condition.params, state);
      case ScriptConditionType.variableLessThan:
        return _evaluateVariableLessThan(condition.params, state);
      case ScriptConditionType.fieldAbilityUnlocked:
        return _evaluateFieldAbilityUnlocked(condition.params, state);
      case ScriptConditionType.partyHasMove:
        return _evaluatePartyHasMove(condition.params, state, requireUsable: false);
      case ScriptConditionType.partyHasUsableMove:
        return _evaluatePartyHasMove(condition.params, state, requireUsable: true);
      case ScriptConditionType.eventIsConsumed:
        return _evaluateEventIsConsumed(condition.params, state);
      case ScriptConditionType.playerOnMap:
        return _evaluatePlayerOnMap(condition.params, state);
    }
  }

  bool _evaluateAllOf(
    List<ScriptCondition> children,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    if (children.isEmpty) return true;
    for (final child in children) {
      if (!evaluate(child, state, context: context)) {
        return false;
      }
    }
    return true;
  }

  bool _evaluateAnyOf(
    List<ScriptCondition> children,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    if (children.isEmpty) return false;
    for (final child in children) {
      if (evaluate(child, state, context: context)) {
        return true;
      }
    }
    return false;
  }

  bool _evaluateNot(
    List<ScriptCondition> children,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    if (children.isEmpty) return true;
    return !evaluate(children.first, state, context: context);
  }

  bool _evaluateFlagIsSet(Map<String, String> params, GameState state) {
    final flagName = params[ScriptConditionParams.flagName];
    if (flagName == null || flagName.isEmpty) return false;
    return state.storyFlags.activeFlags.contains(flagName);
  }

  bool _evaluateFlagIsUnset(Map<String, String> params, GameState state) {
    final flagName = params[ScriptConditionParams.flagName];
    if (flagName == null || flagName.isEmpty) return true;
    return !state.storyFlags.activeFlags.contains(flagName);
  }

  bool _evaluateVariableEquals(Map<String, String> params, GameState state) {
    final variableName = params[ScriptConditionParams.variableName];
    final valueStr = params[ScriptConditionParams.value];
    if (variableName == null || valueStr == null) return false;

    final actualValue = state.scriptVariables.values[variableName];
    if (actualValue == null) return false;

    return actualValue.map(
      bool: (b) => valueStr == b.value.toString(),
      int: (i) => valueStr == i.value.toString(),
      string: (s) => valueStr == s.value,
    );
  }

  bool _evaluateVariableGreaterThan(
    Map<String, String> params,
    GameState state,
  ) {
    final variableName = params[ScriptConditionParams.variableName];
    final valueStr = params[ScriptConditionParams.value];
    if (variableName == null || valueStr == null) return false;

    final actualValue = state.scriptVariables.values[variableName];
    if (actualValue == null) return false;

    return actualValue.map(
      bool: (_) => false,
      int: (i) => i.value > int.parse(valueStr),
      string: (_) => false,
    );
  }

  bool _evaluateVariableLessThan(Map<String, String> params, GameState state) {
    final variableName = params[ScriptConditionParams.variableName];
    final valueStr = params[ScriptConditionParams.value];
    if (variableName == null || valueStr == null) return false;

    final actualValue = state.scriptVariables.values[variableName];
    if (actualValue == null) return false;

    return actualValue.map(
      bool: (_) => false,
      int: (i) => i.value < int.parse(valueStr),
      string: (_) => false,
    );
  }

  bool _evaluateFieldAbilityUnlocked(
    Map<String, String> params,
    GameState state,
  ) {
    final abilityName = params[ScriptConditionParams.ability];
    if (abilityName == null) return false;

    final ability = FieldAbility.values.firstWhere(
      (a) => a.name == abilityName,
      orElse: () => throw FormatException('Unknown field ability: $abilityName'),
    );

    return state.progression.unlockedFieldAbilities.contains(ability);
  }

  bool _evaluatePartyHasMove(
    Map<String, String> params,
    GameState state, {
    bool requireUsable = false,
  }) {
    final moveId = params[ScriptConditionParams.moveId];
    if (moveId == null || moveId.isEmpty) return false;

    final party = state.party.members;
    if (party.isEmpty) return false;

    for (final pokemon in party) {
      if (requireUsable && pokemon.isFainted) continue;
      if (pokemon.knownMoveIds.contains(moveId)) {
        return true;
      }
    }
    return false;
  }

  bool _evaluateEventIsConsumed(Map<String, String> params, GameState state) {
    final eventId = params[ScriptConditionParams.eventId];
    if (eventId == null || eventId.isEmpty) return false;
    return state.consumedEventIds.contains(eventId);
  }

  bool _evaluatePlayerOnMap(Map<String, String> params, GameState state) {
    final mapId = params[ScriptConditionParams.mapId];
    if (mapId == null || mapId.isEmpty) return false;
    return state.currentMapId == mapId;
  }
}

/// Contexte optionnel pour l'évaluation de conditions.
///
/// Peut contenir des données temporaires non persistées dans le GameState.
/// Exemple : état temporaire d'un dialogue, position immédiate, etc.
class ScriptEvaluationContext {
  const ScriptEvaluationContext({
    this.transientFlags = const {},
    this.transientVariables = const {},
  });

  /// Flags temporaires (non persistés).
  final Set<String> transientFlags;

  /// Variables temporaires (non persistées).
  final Map<String, ScriptVariableValue> transientVariables;
}
