import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'narrative_value.dart';

part 'script_conditions.freezed.dart';
part 'script_conditions.g.dart';

/// Condition de script.
///
/// Une condition retourne true/false lors de l'évaluation.
/// Peut être combinée avec allOf/anyOf/not.
@freezed
class ScriptCondition with _$ScriptCondition {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptCondition({
    required ScriptConditionType type,

    /// Paramètres de la condition (dépend du type).
    @Default({}) Map<String, String> params,

    /// Sous-conditions pour allOf/anyOf/not.
    @Default([]) List<ScriptCondition> children,
  }) = _ScriptCondition;

  factory ScriptCondition.fromJson(Map<String, dynamic> json) =>
      _$ScriptConditionFromJson(json);
}

/// Types de conditions.
enum ScriptConditionType {
  /// true si tous les enfants sont true.
  @JsonValue('allOf')
  allOf,

  /// true si au moins un enfant est true.
  @JsonValue('anyOf')
  anyOf,

  /// true si l'enfant unique est false.
  @JsonValue('not')
  not,

  /// true si le flag spécifié est actif.
  @JsonValue('flagIsSet')
  flagIsSet,

  /// true si le flag spécifié est inactif.
  @JsonValue('flagIsUnset')
  flagIsUnset,

  /// true si le Fact typé égale la valeur attendue.
  @JsonValue('factEquals')
  factEquals,

  /// true si la Story Step spécifiée est terminée.
  @JsonValue('stepCompleted')
  stepCompleted,

  /// true si le badge spécifié est possédé.
  @JsonValue('badgeOwned')
  badgeOwned,

  /// true si le sac contient au moins la quantité demandée.
  @JsonValue('itemQuantityAtLeast')
  itemQuantityAtLeast,

  /// true si le joueur possède au moins le montant demandé.
  @JsonValue('moneyAtLeast')
  moneyAtLeast,

  /// true si la variable égale la valeur.
  @JsonValue('variableEquals')
  variableEquals,

  /// true si la variable > valeur.
  @JsonValue('variableGreaterThan')
  variableGreaterThan,

  /// true si la variable < valeur.
  @JsonValue('variableLessThan')
  variableLessThan,

  /// true si la field ability est débloquée.
  @JsonValue('fieldAbilityUnlocked')
  fieldAbilityUnlocked,

  /// true si l'équipe a un Pokémon avec le move spécifié.
  @JsonValue('partyHasMove')
  partyHasMove,

  /// true si l'équipe a un Pokémon utilisable (non-KO) avec le move.
  @JsonValue('partyHasUsableMove')
  partyHasUsableMove,

  /// true si l'événement spécifié a été consommé.
  @JsonValue('eventIsConsumed')
  eventIsConsumed,

  /// true si le joueur est sur la map spécifiée.
  @JsonValue('playerOnMap')
  playerOnMap,
}

/// Clés de paramètres pour les conditions.
class ScriptConditionParams {
  /// Nom du flag pour flagIsSet/flagIsUnset.
  static const String flagName = 'flagName';

  /// Identifiant du Fact pour factEquals.
  static const String factId = 'factId';

  /// Wire name de NarrativeValueKind pour factEquals.
  static const String valueType = 'valueType';

  /// Identifiant de Story Step pour stepCompleted.
  static const String stepId = 'stepId';

  /// Identifiant de badge pour badgeOwned.
  static const String badgeId = 'badgeId';

  /// Identifiant d'objet pour itemQuantityAtLeast.
  static const String itemId = 'itemId';

  /// Quantité minimale pour itemQuantityAtLeast.
  static const String quantity = 'quantity';

  /// Montant minimum pour moneyAtLeast.
  static const String amount = 'amount';

  /// Nom de la variable pour variableEquals/variableGreaterThan/variableLessThan.
  static const String variableName = 'variableName';

  /// Valeur à comparer (string ou int selon le contexte).
  static const String value = 'value';

  /// Field ability pour fieldAbilityUnlocked.
  static const String ability = 'ability';

  /// Move ID pour partyHasMove/partyHasUsableMove.
  static const String moveId = 'moveId';

  /// Event ID pour eventIsConsumed.
  static const String eventId = 'eventId';

  /// Map ID pour playerOnMap.
  static const String mapId = 'mapId';
}

/// Extension utilitaire pour créer des conditions typées.
extension ScriptConditionFactory on ScriptCondition {
  /// Crée une condition allOf.
  static ScriptCondition allOf(List<ScriptCondition> children) {
    return ScriptCondition(
      type: ScriptConditionType.allOf,
      children: children,
    );
  }

  /// Crée une condition anyOf.
  static ScriptCondition anyOf(List<ScriptCondition> children) {
    return ScriptCondition(
      type: ScriptConditionType.anyOf,
      children: children,
    );
  }

  /// Crée une condition not.
  static ScriptCondition not(ScriptCondition child) {
    return ScriptCondition(
      type: ScriptConditionType.not,
      children: [child],
    );
  }

  /// Crée une condition flagIsSet.
  static ScriptCondition flagIsSet(String flagName) {
    return ScriptCondition(
      type: ScriptConditionType.flagIsSet,
      params: {ScriptConditionParams.flagName: flagName},
    );
  }

  /// Crée une condition flagIsUnset.
  static ScriptCondition flagIsUnset(String flagName) {
    return ScriptCondition(
      type: ScriptConditionType.flagIsUnset,
      params: {ScriptConditionParams.flagName: flagName},
    );
  }

  /// Crée une condition d'égalité sur un Fact typé.
  static ScriptCondition factEquals(String factId, NarrativeValue value) {
    return ScriptCondition(
      type: ScriptConditionType.factEquals,
      params: {
        ScriptConditionParams.factId: _requiredConditionId(factId, 'factId'),
        ScriptConditionParams.valueType: value.kind.wireName,
        ScriptConditionParams.value: _narrativeValueWireValue(value),
      },
    );
  }

  /// Crée une condition de Story Step terminée.
  static ScriptCondition stepCompleted(String stepId) {
    return ScriptCondition(
      type: ScriptConditionType.stepCompleted,
      params: {
        ScriptConditionParams.stepId: _requiredConditionId(stepId, 'stepId'),
      },
    );
  }

  /// Crée une condition de badge possédé.
  static ScriptCondition badgeOwned(String badgeId) {
    return ScriptCondition(
      type: ScriptConditionType.badgeOwned,
      params: {
        ScriptConditionParams.badgeId: _requiredConditionId(badgeId, 'badgeId'),
      },
    );
  }

  /// Crée une condition de quantité minimale d'objet.
  static ScriptCondition itemQuantityAtLeast(String itemId, int quantity) {
    return ScriptCondition(
      type: ScriptConditionType.itemQuantityAtLeast,
      params: {
        ScriptConditionParams.itemId: _requiredConditionId(itemId, 'itemId'),
        ScriptConditionParams.quantity:
            _nonNegativeConditionInteger(quantity, 'quantity').toString(),
      },
    );
  }

  /// Crée une condition de montant minimum.
  static ScriptCondition moneyAtLeast(int amount) {
    return ScriptCondition(
      type: ScriptConditionType.moneyAtLeast,
      params: {
        ScriptConditionParams.amount:
            _nonNegativeConditionInteger(amount, 'amount').toString(),
      },
    );
  }

  /// Crée une condition variableEquals (int).
  static ScriptCondition variableEqualsInt(String variableName, int value) {
    return ScriptCondition(
      type: ScriptConditionType.variableEquals,
      params: {
        ScriptConditionParams.variableName: variableName,
        ScriptConditionParams.value: value.toString(),
      },
    );
  }

  /// Crée une condition variableEquals (string).
  static ScriptCondition variableEqualsString(
      String variableName, String value) {
    return ScriptCondition(
      type: ScriptConditionType.variableEquals,
      params: {
        ScriptConditionParams.variableName: variableName,
        ScriptConditionParams.value: value,
      },
    );
  }

  /// Crée une condition variableGreaterThan.
  static ScriptCondition variableGreaterThan(String variableName, int value) {
    return ScriptCondition(
      type: ScriptConditionType.variableGreaterThan,
      params: {
        ScriptConditionParams.variableName: variableName,
        ScriptConditionParams.value: value.toString(),
      },
    );
  }

  /// Crée une condition variableLessThan.
  static ScriptCondition variableLessThan(String variableName, int value) {
    return ScriptCondition(
      type: ScriptConditionType.variableLessThan,
      params: {
        ScriptConditionParams.variableName: variableName,
        ScriptConditionParams.value: value.toString(),
      },
    );
  }

  /// Crée une condition fieldAbilityUnlocked.
  static ScriptCondition fieldAbilityUnlocked(FieldAbility ability) {
    return ScriptCondition(
      type: ScriptConditionType.fieldAbilityUnlocked,
      params: {ScriptConditionParams.ability: ability.name},
    );
  }

  /// Crée une condition partyHasUsableMove.
  static ScriptCondition partyHasUsableMove(String moveId) {
    return ScriptCondition(
      type: ScriptConditionType.partyHasUsableMove,
      params: {ScriptConditionParams.moveId: moveId},
    );
  }

  /// Crée une condition eventIsConsumed.
  static ScriptCondition eventIsConsumed(String eventId) {
    return ScriptCondition(
      type: ScriptConditionType.eventIsConsumed,
      params: {ScriptConditionParams.eventId: eventId},
    );
  }

  /// Crée une condition playerOnMap.
  static ScriptCondition playerOnMap(String mapId) {
    return ScriptCondition(
      type: ScriptConditionType.playerOnMap,
      params: {ScriptConditionParams.mapId: mapId},
    );
  }
}

String _requiredConditionId(String value, String parameterName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      parameterName,
      'must not be empty',
    );
  }
  return normalized;
}

int _nonNegativeConditionInteger(int value, String parameterName) {
  if (value < 0) {
    throw ArgumentError.value(
      value,
      parameterName,
      'must be non-negative',
    );
  }
  return value;
}

String _narrativeValueWireValue(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => value.boolValue.toString(),
      NarrativeValueKind.integer => value.intValue.toString(),
      NarrativeValueKind.string => value.stringValue,
    };
