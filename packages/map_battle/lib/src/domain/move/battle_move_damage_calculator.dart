import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_critical_resolver.dart';
import 'battle_move_data.dart';
import 'battle_move_type_processor.dart';

final class BattleMoveDamageCalculator {
  const BattleMoveDamageCalculator({
    BattleMoveTypeProcessor typeProcessor = const BattleMoveTypeProcessor(),
    BattleMoveCriticalResolver criticalResolver =
        const BattleMoveCriticalResolver(),
  })  : _typeProcessor = typeProcessor,
        _criticalResolver = criticalResolver;

  final BattleMoveTypeProcessor _typeProcessor;
  final BattleMoveCriticalResolver _criticalResolver;

  BattleMoveDamageResult calculate(BattleMoveDamageContext context) {
    final move = context.move;
    final resolvedPower = context.overrides?.power ?? move.power;
    if (move.category == PsdkBattleMoveCategory.status || resolvedPower <= 0) {
      return BattleMoveDamageResult.zero(
        rng: context.rng,
        stabMultiplier: 1,
        typeEffectivenessMultiplier: 1,
      );
    }

    final stabMultiplier = _typeProcessor.resolveStabMultiplier(
      moveType: move.type,
      userTypes: context.user.types,
    );
    final effectiveness = _typeProcessor.resolveEffectiveness(
      moveType: move.type,
      targetTypes: context.target.types,
    );
    if (effectiveness.isImmune) {
      return BattleMoveDamageResult.zero(
        rng: context.rng,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: effectiveness.multiplier,
      );
    }

    final critical = _criticalResolver.resolve(
      move: move,
      rng: context.rng,
    );
    final damageRoll = critical.rng.moveDamage.nextDamagePercent();
    final rng = critical.rng.copyWith(moveDamage: damageRoll.next);

    // PSDK move subclasses often override only one formula input, for example
    // Brine's base power or Body Press' offensive stat source. These overrides
    // are deliberately scoped to one calculation so catalog definitions remain
    // immutable import data instead of becoming per-hit scratch objects.
    final offensiveStat = _positiveStat(
      context.overrides?.offensiveStatFor(critical.isCritical) ??
          _offensiveStat(context),
    );
    final defensiveStat = _positiveStat(
      context.overrides?.defensiveStatFor(critical.isCritical) ??
          _defensiveStat(context),
    );
    final levelFactor = ((2 * context.user.level) ~/ 5) + 2;
    final baseDamage =
        (((levelFactor * resolvedPower * offensiveStat) ~/ defensiveStat) ~/
                50) +
            2;
    final criticalDamage = (baseDamage * critical.multiplier).floor();
    final randomDamage = ((criticalDamage * damageRoll.value) / 100).floor();
    final stabDamage = (randomDamage * stabMultiplier).floor();
    final typedDamage = (stabDamage * effectiveness.multiplier).floor();
    final damage = typedDamage < 1 ? 1 : typedDamage;

    return BattleMoveDamageResult(
      rng: rng,
      damage: damage,
      isCritical: critical.isCritical,
      criticalMultiplier: critical.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: effectiveness.multiplier,
    );
  }
}

final class BattleMoveDamageContext {
  const BattleMoveDamageContext({
    required this.user,
    required this.target,
    required this.move,
    required this.rng,
    this.overrides,
  });

  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final BattleMoveDefinition move;
  final BattleRngStreams rng;
  final BattleMoveDamageOverrides? overrides;
}

typedef BattleMoveStatResolver = int Function(bool isCritical);

/// Per-hit formula inputs resolved by PSDK move behaviors.
///
/// This object is intentionally narrow: it changes the values consumed by the
/// damage formula without changing move identity, PP, flags, targeting or any
/// other catalog fields.
final class BattleMoveDamageOverrides {
  const BattleMoveDamageOverrides({
    this.power,
    this.offensiveStat,
    this.defensiveStat,
    this.offensiveStatResolver,
    this.defensiveStatResolver,
  })  : assert(power == null || power >= 0),
        assert(offensiveStat == null || offensiveStat >= 1),
        assert(defensiveStat == null || defensiveStat >= 1),
        assert(offensiveStat == null || offensiveStatResolver == null),
        assert(defensiveStat == null || defensiveStatResolver == null);

  final int? power;
  final int? offensiveStat;
  final int? defensiveStat;
  final BattleMoveStatResolver? offensiveStatResolver;
  final BattleMoveStatResolver? defensiveStatResolver;

  int? offensiveStatFor(bool isCritical) {
    return offensiveStatResolver?.call(isCritical) ?? offensiveStat;
  }

  int? defensiveStatFor(bool isCritical) {
    return defensiveStatResolver?.call(isCritical) ?? defensiveStat;
  }
}

final class BattleMoveDamageResult {
  const BattleMoveDamageResult({
    required this.rng,
    required this.damage,
    required this.isCritical,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
  });

  factory BattleMoveDamageResult.zero({
    required BattleRngStreams rng,
    required double stabMultiplier,
    required double typeEffectivenessMultiplier,
  }) {
    return BattleMoveDamageResult(
      rng: rng,
      damage: 0,
      isCritical: false,
      criticalMultiplier: 1,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
    );
  }

  final BattleRngStreams rng;
  final int damage;
  final bool isCritical;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;

  bool get isImmune => typeEffectivenessMultiplier == 0.0;
}

int _offensiveStat(BattleMoveDamageContext context) {
  return switch (context.move.category) {
    PsdkBattleMoveCategory.physical => context.user.stats.attack,
    PsdkBattleMoveCategory.special => context.user.stats.specialAttack,
    PsdkBattleMoveCategory.status => context.user.stats.attack,
  };
}

int _defensiveStat(BattleMoveDamageContext context) {
  final value = switch (context.move.category) {
    PsdkBattleMoveCategory.physical => context.target.stats.defense,
    PsdkBattleMoveCategory.special => context.target.stats.specialDefense,
    PsdkBattleMoveCategory.status => context.target.stats.defense,
  };
  return value < 1 ? 1 : value;
}

int _positiveStat(int value) {
  return value < 1 ? 1 : value;
}
