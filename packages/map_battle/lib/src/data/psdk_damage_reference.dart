/// Oracle de la chaîne de dégâts, transcrit depuis la source Ruby de PSDK.
///
/// Source : `scripts/5 Battle/10 Move/101 Damage_Calc.rb`, méthode `damages`,
/// qui déclare suivre la formule de 4e génération.
///
/// Ce fichier vit à côté de [BattleParityTarget] parce qu'il joue le même rôle :
/// une déclaration auditable de ce que le moteur est censé faire, indépendante
/// du code qui le fait. Il est partagé par les vecteurs de référence, le
/// générateur de fixtures golden et tout audit de parité à venir, pour qu'il
/// n'existe qu'une seule transcription à maintenir.
///
/// Ce qui compte ici n'est pas la liste des multiplicateurs mais **la position
/// de chaque troncature** : ce sont elles qui rendent le résultat sensible à
/// l'ordre.
///
///     damage = level * 2 / 5 + 2
///     damage = (damage * base_power).floor
///     damage = (damage * sp_atk).floor / 50
///     damage = (damage / sp_def).floor
///     damage = (damage * mod1).floor + 2      <- brûlure, météo, terrain
///     damage = (damage * ch).floor            <- critique
///     damage = (damage * mod2).floor
///     damage = damage * rand(85..100) / 100
///     damage = (damage * stab).floor
///     damage = (damage * type1).floor         <- une troncature PAR type
///     damage = (damage * type2).floor
///     damage = (damage * mod3).floor          <- objet tenu, talent final
///     damage = damage.clamp(1, target_hp)
///
/// La transcription est écrite depuis le Ruby, jamais depuis
/// `BattleMoveDamageCalculator` : c'est ce qui l'empêche de recopier une erreur
/// d'arithmétique du moteur.
///
/// Un écart d'ordre est assumé et déclaré sur l'axe `damage` de
/// [BattleParityTarget] : le moteur combine les deux multiplicateurs de type
/// puis tronque une fois, là où PSDK tronque après chacun. Les deux conventions
/// sont exprimables ici, par [sequentialTypeMultipliers] pour la première et
/// [combinedTypeMultiplier] pour la seconde.
int psdkReferenceDamage({
  required int roll,
  required int level,
  required int power,
  required int offensiveStat,
  required int defensiveStat,
  double mod1 = 1,
  double criticalMultiplier = 1,
  double mod2 = 1,
  double stab = 1,
  List<double> sequentialTypeMultipliers = const <double>[],
  double combinedTypeMultiplier = 1,
  double mod3 = 1,
}) {
  var damage = (2 * level) ~/ 5 + 2;
  damage = (damage * power).floor();
  damage = (damage * offensiveStat).floor() ~/ 50;
  damage = damage ~/ defensiveStat;
  damage = (damage * mod1).floor() + 2;
  damage = (damage * criticalMultiplier).floor();
  damage = (damage * mod2).floor();
  damage = (damage * roll) ~/ 100;
  damage = (damage * stab).floor();
  for (final multiplier in sequentialTypeMultipliers) {
    damage = (damage * multiplier).floor();
  }
  damage = (damage * combinedTypeMultiplier).floor();
  damage = (damage * mod3).floor();
  return damage < 1 ? 1 : damage;
}

/// Roll de dégâts produit par une graine, transcrit depuis `BattleRngStream`.
///
///     nextPercent       -> (seed.abs() % 100) + 1
///     nextDamagePercent -> 85 + (value % 16)
///
/// Le connaître permet d'affirmer une valeur exacte au lieu d'une bande de seize
/// possibles. Une bande laisse passer une erreur d'ordre entre deux étapes :
/// déplacer le STAB avant le roll, ou changer le diviseur 50 en 49, la
/// traversaient sans être vus.
int psdkDamageRollForSeed(int seed) => 85 + (((seed.abs() % 100) + 1) % 16);

/// Bornes de `R_RANGE` côté PSDK.
const int psdkMinimumDamageRoll = 85;
const int psdkMaximumDamageRoll = 100;
