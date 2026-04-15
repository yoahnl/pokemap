/// Snapshot minimal des stats résolues d'un combattant pour `map_battle`.
///
/// BE2 introduit ce type pour sortir d'un modèle où :
/// - `physical` et `special` n'étaient différenciés que par les stages ;
/// - le moteur n'avait aucune vraie base offensive/défensive à opposer ;
/// - `speed` n'était même pas transportée jusqu'à l'état battle.
///
/// Frontière volontairement stricte :
/// - ce snapshot transporte uniquement les stats non-HP déjà utiles au moteur ;
/// - `maxHp` / `currentHp` restent sur le combattant pour éviter toute
///   duplication mensongère ;
/// - on n'ouvre pas accuracy / evasion dans ce lot ;
/// - on n'utilise pas encore `speed` pour l'ordre d'action.
class BattleStatsSnapshot {
  const BattleStatsSnapshot({
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  /// Stat physique offensive résolue avant le combat.
  final int attack;

  /// Stat physique défensive résolue avant le combat.
  final int defense;

  /// Stat spéciale offensive résolue avant le combat.
  final int specialAttack;

  /// Stat spéciale défensive résolue avant le combat.
  final int specialDefense;

  /// Vitesse résolue avant le combat.
  ///
  /// BE2 la transporte déjà pour arrêter sa perte silencieuse au handoff,
  /// mais l'ordre d'action reste explicitement hors scope.
  final int speed;
}
