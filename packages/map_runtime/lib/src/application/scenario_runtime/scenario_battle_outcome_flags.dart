/// Helpers purs pour les flags d'outcome de combat scénario.
///
/// Convention de nommage :
/// ```text
/// battle:<battleId>:victory
/// battle:<battleId>:defeat
/// battle:<battleId>:flee
/// battle:<battleId>:captured
/// ```
///
/// Voir SEL-A2 §4.5 et SEL-B2 pour la spécification.
library scenario_battle_outcome_flags;

/// Préfixe commun à tous les flags d'outcome de combat scénario.
const String kBattleOutcomeFlagPrefix = 'battle:';

/// Suffixes d'outcome canoniques.
const String kBattleOutcomeSuffixVictory = 'victory';
const String kBattleOutcomeSuffixDefeat = 'defeat';
const String kBattleOutcomeSuffixFlee = 'flee';
const String kBattleOutcomeSuffixCaptured = 'captured';

/// Construit le nom de flag d'outcome pour un combat scénario.
///
/// Exemples :
/// ```dart
/// scenarioBattleOutcomeFlagName('battle_rival_port', 'victory')
///   // → 'battle:battle_rival_port:victory'
///
/// scenarioBattleOutcomeFlagName('battle_rival_port', 'defeat')
///   // → 'battle:battle_rival_port:defeat'
/// ```
///
/// [battleId] identifiant stable du combat (authoring).
/// [outcomeSuffix] un des `kBattleOutcomeSuffix*`.
String scenarioBattleOutcomeFlagName(String battleId, String outcomeSuffix) {
  final normalizedBattleId = battleId.trim();
  final normalizedSuffix = outcomeSuffix.trim();
  assert(normalizedBattleId.isNotEmpty, 'battleId ne peut pas être vide');
  assert(normalizedSuffix.isNotEmpty, 'outcomeSuffix ne peut pas être vide');
  return '$kBattleOutcomeFlagPrefix$normalizedBattleId:$normalizedSuffix';
}
