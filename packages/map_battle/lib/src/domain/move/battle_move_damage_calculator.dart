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
    final moveType = _effectiveMoveType(context);
    final resolvedPower = _effectivePower(context);
    if (move.category == PsdkBattleMoveCategory.status || resolvedPower <= 0) {
      return BattleMoveDamageResult.zero(
        rng: context.rng,
        stabMultiplier: 1,
        typeEffectivenessMultiplier: 1,
      );
    }

    final stabMultiplier = _typeProcessor.resolveStabMultiplier(
      moveType: moveType,
      userTypes: context.user.types,
      extraUserTypes: _extraTypes(context.user),
    );
    final effectiveness = _typeProcessor.resolveEffectiveness(
      moveType: moveType,
      targetTypes: context.target.types,
      extraTargetTypes: _extraTypes(context.target),
      forceGrounded: context.target.effects.contains('smack_down'),
      foresight: context.target.effects.contains('foresight'),
      miracleEye: context.target.effects.contains('miracle_eye'),
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
      criticalRate: _effectiveCriticalRate(context),
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
    final typeEffectivenessMultiplier = _applyLocalEffectivenessModifiers(
      effectiveness.multiplier,
      context,
      moveType,
    );
    final typedDamage = (stabDamage * typeEffectivenessMultiplier).floor();
    final damage = typedDamage < 1 ? 1 : typedDamage;

    return BattleMoveDamageResult(
      rng: rng,
      damage: damage,
      isCritical: critical.isCritical,
      criticalMultiplier: critical.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
    );
  }
}

int _effectivePower(BattleMoveDamageContext context) {
  var power = context.overrides?.power ?? context.move.power;
  final moveType = _effectiveMoveType(context);
  if (context.user.effects.contains('charge') && moveType == 'electric') {
    power *= 2;
  }
  if (_hasBattleEffect(context, 'mud_sport') && moveType == 'electric') {
    power ~/= 2;
  }
  if (_hasBattleEffect(context, 'water_sport') && moveType == 'fire') {
    power ~/= 2;
  }
  return power;
}

String _effectiveMoveType(BattleMoveDamageContext context) {
  final moveType = context.move.type.toLowerCase();
  if (context.user.effects.contains('electrify')) {
    return 'electric';
  }
  if (_hasBattleEffect(context, 'ion_deluge') && moveType == 'normal') {
    return 'electric';
  }
  return moveType;
}

bool _hasBattleEffect(BattleMoveDamageContext context, String id) {
  return context.user.effects.contains(id) ||
      context.target.effects.contains(id);
}

Iterable<String> _extraTypes(PsdkBattleCombatant battler) {
  return <String>[
    if (battler.type3 != null) battler.type3!,
    ...battler.temporaryTypes,
  ];
}

int _effectiveCriticalRate(BattleMoveDamageContext context) {
  final user = context.user;
  final target = context.target;
  if (target.effects.contains('lucky_chant')) {
    return 0;
  }
  if (user.abilityId == 'merciless' && _hasPoisonStatus(target)) {
    return 4;
  }
  if (user.effects.contains('laser_focus')) {
    return 4;
  }
  if (target.abilityId == 'battle_armor' || target.abilityId == 'shell_armor') {
    return 0;
  }

  var criticalRate = context.move.criticalRate;
  if (user.effects.contains('focus_energy')) {
    criticalRate += 2;
  }
  if (user.effects.contains('dragon_cheer')) {
    criticalRate += user.hasType('dragon') ? 2 : 1;
  }
  if (user.effects.contains('triple_arrows')) {
    criticalRate += 2;
  }
  if (user.abilityId == 'super_luck') {
    criticalRate += 1;
  }
  if (_hasCriticalItem(user)) {
    criticalRate += 1;
  }
  if (user.effects.contains('lansat_berry')) {
    criticalRate += 1;
  }
  return criticalRate;
}

bool _hasPoisonStatus(PsdkBattleCombatant battler) {
  return battler.majorStatus == PsdkBattleMajorStatus.poison ||
      battler.majorStatus == PsdkBattleMajorStatus.toxic;
}

bool _hasCriticalItem(PsdkBattleCombatant battler) {
  return battler.heldItemId == 'razor_claw' ||
      battler.heldItemId == 'scope_lens' ||
      (battler.heldItemId == 'leek' && battler.speciesId == 'farfetch_d') ||
      (battler.heldItemId == 'lucky_punch' && battler.speciesId == 'chansey');
}

double _applyLocalEffectivenessModifiers(
  double multiplier,
  BattleMoveDamageContext context,
  String moveType,
) {
  if (moveType == 'fire' && context.target.effects.contains('tar_shot')) {
    return multiplier * 2;
  }
  if (context.target.effects.contains('glaive_rush')) {
    return multiplier * 2;
  }
  return multiplier;
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
    PsdkBattleMoveCategory.physical => _physicalAttack(context),
    PsdkBattleMoveCategory.special => context.user.stats.specialAttack,
    PsdkBattleMoveCategory.status => context.user.stats.attack,
  };
}

int _physicalAttack(BattleMoveDamageContext context) {
  final attack = context.user.stats.attack;
  if (context.user.majorStatus != PsdkBattleMajorStatus.burn ||
      context.user.abilityId == 'guts' ||
      context.move.battleEngineMethod == 's_facade') {
    return attack;
  }
  final burnedAttack = (attack * 0.5).floor();
  return burnedAttack < 1 ? 1 : burnedAttack;
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
