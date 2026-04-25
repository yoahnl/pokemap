import '../../psdk/domain/psdk_battle_combatant.dart';

/// Battle stats resolved before a PSDK-style fight starts.
///
/// This is intentionally separate from legacy `BattleStatsSnapshot`. The clean
/// migration needs mutable battlers and PSDK bank/position topology, while the
/// legacy session still owns its historical immutable DTOs.
final class BattleComputedStats {
  const BattleComputedStats({
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  factory BattleComputedStats.fromPsdk(PsdkBattleStats stats) {
    return BattleComputedStats(
      attack: stats.attack,
      defense: stats.defense,
      specialAttack: stats.specialAttack,
      specialDefense: stats.specialDefense,
      speed: stats.speed,
    );
  }

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;
}

/// Type pair carried by a clean PSDK battler.
final class BattleTypes {
  const BattleTypes({
    required this.primary,
    this.secondary,
  });

  factory BattleTypes.fromPsdk(PsdkBattleTypes types) {
    return BattleTypes(
      primary: types.primary,
      secondary: types.secondary,
    );
  }

  final String primary;
  final String? secondary;

  List<String> get values => <String>[
        primary,
        if (secondary != null) secondary!,
      ];
}

/// Stats supported by the first clean battler stage container.
enum BattleStat {
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

/// Mutable stat stage set with Pokemon's canonical -6..+6 bounds.
///
/// The legacy engine already has `BattleStatStages`; this clean type is named
/// differently to avoid shadowing while Lot 5 lives beside the old model.
final class BattleStatStageSet {
  BattleStatStageSet._(Map<BattleStat, int> values)
      : _values = Map<BattleStat, int>.from(values);

  factory BattleStatStageSet.neutral() {
    return BattleStatStageSet._(<BattleStat, int>{
      for (final stat in BattleStat.values) stat: 0,
    });
  }

  final Map<BattleStat, int> _values;

  int valueOf(BattleStat stat) => _values[stat] ?? 0;

  void raise(BattleStat stat, int amount) {
    _checkStageAmount(amount);
    _set(stat, valueOf(stat) + amount);
  }

  void lower(BattleStat stat, int amount) {
    _checkStageAmount(amount);
    _set(stat, valueOf(stat) - amount);
  }

  void reset(BattleStat stat) {
    _set(stat, 0);
  }

  Map<BattleStat, int> snapshot() => Map<BattleStat, int>.unmodifiable(_values);

  void _set(BattleStat stat, int value) {
    _values[stat] = value.clamp(-6, 6).toInt();
  }

  void _checkStageAmount(int amount) {
    if (amount < 0) {
      throw RangeError.range(amount, 0, null, 'amount');
    }
  }
}
