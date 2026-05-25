import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../move/battle_move_prevention.dart';
import '../../rng/battle_seeded_rng.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class SpeedBoostEffect extends BattleAbilityEffect {
  const SpeedBoostEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'speed_boost', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SpeedBoostEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    if (!isOwnedBy(owner)) {
      return null;
    }
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.switching) {
      return null;
    }

    final result = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      stat: 'speed',
      stages: 1,
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class MoodyEffect extends BattleAbilityEffect {
  const MoodyEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'moody', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MoodyEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted) {
      return null;
    }

    var rng = context.rng;
    final upCandidates = _moodyStats
        .where((stat) => battler.statStages.valueOf(stat) < 6)
        .toList(growable: false);
    final upStat = _sampleStat(upCandidates, rng.generic);
    if (upStat != null) {
      rng = rng.copyWith(generic: upStat.next);
    }

    final downCandidates = _moodyStats
        .where(
          (stat) =>
              stat != upStat?.stat && battler.statStages.valueOf(stat) > -6,
        )
        .toList(growable: false);
    final downStat = _sampleStat(downCandidates, rng.generic);
    if (downStat != null) {
      rng = rng.copyWith(generic: downStat.next);
    }

    if (upStat == null && downStat == null) {
      return null;
    }

    var nextState = context.state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;
    for (final change in <({String stat, int stages})>[
      if (upStat != null) (stat: upStat.stat, stages: 2),
      if (downStat != null) (stat: downStat.stat, stages: -1),
    ]) {
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: context.owner,
        stat: change.stat,
        stages: change.stages,
        sourceAbilityId: abilityId,
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      applied = applied || result.applied || result.events.isNotEmpty;
    }

    if (!applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

final class HealerEffect extends BattleAbilityEffect {
  const HealerEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'healer', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HealerEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final owner = context.state.battlerAt(context.owner);
    if (owner.isFainted) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;
    for (final ally in context.state.adjacentAlliesOf(context.owner)) {
      if (nextState.battlerAt(ally).majorStatus == null) {
        continue;
      }
      final chance =
          nextRng.generic.nextChance(numerator: 30, denominator: 100);
      nextRng = nextRng.copyWith(generic: chance.next);
      if (!chance.didOccur) {
        continue;
      }
      final result = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: ally,
        moveId: 'ability:healer',
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      applied = applied || result.applied || result.events.isNotEmpty;
    }

    if (!applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

final class RainDishEffect extends BattleAbilityEffect {
  const RainDishEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'rain_dish', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RainDishEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner) || !_rainIsActive(context.state)) {
      return null;
    }
    return _healOwnerFraction(
      context: context,
      denominator: 16,
      moveId: 'ability:rain_dish',
    );
  }
}

final class HydrationEffect extends BattleAbilityEffect {
  const HydrationEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'hydration', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HydrationEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner) || !_rainIsActive(context.state)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted || battler.majorStatus == null) {
      return null;
    }

    final result = const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      moveId: 'ability:hydration',
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class IceBodyEffect extends BattleAbilityEffect {
  const IceBodyEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'ice_body', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return IceBodyEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner) || !_snowIsActive(context.state)) {
      return null;
    }
    return _healOwnerFraction(
      context: context,
      denominator: 16,
      moveId: 'ability:ice_body',
    );
  }
}

final class DrySkinEffect extends BattleAbilityEffect {
  const DrySkinEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'dry_skin', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DrySkinEffect(scope: scope);
  }

  @override
  double incomingDamageBasePowerMultiplier(
    BattleAbilityDamageContext context,
  ) {
    return context.moveType == 'fire' ? 1.25 : 1;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!isOwnedBy(context.target) ||
        context.user == context.target ||
        context.move.type.toLowerCase() != 'water') {
      return null;
    }

    final healed = _heal(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.target,
      amount: context.state.battlerAt(context.target).maxHp ~/ 4,
      moveId: 'ability:dry_skin',
    );
    return BattleEffectDamagePreventionResult(
      state: healed.state,
      rng: healed.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      events: healed.events,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    if (_rainIsActive(context.state)) {
      return _healOwnerFraction(
        context: context,
        denominator: 8,
        moveId: 'ability:dry_skin',
      );
    }
    if (_sunIsActive(context.state)) {
      return _damageOwnerFraction(
        context: context,
        denominator: 8,
        moveId: 'ability:dry_skin',
      );
    }
    return null;
  }
}

final class SolarPowerEffect extends BattleAbilityEffect {
  const SolarPowerEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'solar_power', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SolarPowerEffect(scope: scope);
  }

  @override
  double offensiveStatMultiplier(BattleAbilityDamageContext context) {
    if (context.user.abilityId != abilityId ||
        context.move.category != PsdkBattleMoveCategory.special ||
        context.weatherEffectsSuppressed ||
        !_sunIsActiveInField(context.field)) {
      return 1;
    }
    return 1.5;
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner) || !_sunIsActive(context.state)) {
      return null;
    }
    return _damageOwnerFraction(
      context: context,
      denominator: 8,
      moveId: 'ability:solar_power',
    );
  }
}

final class ShedSkinEffect extends BattleAbilityEffect {
  const ShedSkinEffect({required BattleEffectScope scope})
      : super(abilityId: 'shed_skin', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ShedSkinEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    if (battler.isFainted || battler.majorStatus == null) {
      return null;
    }

    final roll = context.rng.generic.nextChance(numerator: 1, denominator: 3);
    final rng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur) {
      return BattleEffectEndTurnResult(
        state: context.state,
        rng: rng,
        applied: false,
      );
    }

    final result = const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      moveId: 'ability:shed_skin',
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class BadDreamsEffect extends BattleAbilityEffect {
  const BadDreamsEffect({required BattleEffectScope scope})
      : super(abilityId: 'bad_dreams', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BadDreamsEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final owner = context.state.battlerAt(context.owner);
    if (owner.isFainted) {
      return null;
    }

    var state = context.state;
    var rng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;
    for (final target in context.state.aliveSlots()) {
      if (target.bank == context.owner.bank) {
        continue;
      }
      final battler = state.battlerAt(target);
      if (battler.majorStatus != PsdkBattleMajorStatus.sleep &&
          battler.abilityId != 'comatose') {
        continue;
      }
      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.owner,
        ),
        target: target,
        moveId: 'ability:bad_dreams',
        rawDamage: _fraction(battler.maxHp, 8),
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
      applied = applied || result.applied;
    }
    if (!applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: state,
      rng: rng,
      events: events,
    );
  }
}

const _moodyStats = <String>[
  'attack',
  'defense',
  'speed',
  'specialDefense',
  'specialAttack',
  'evasion',
  'accuracy',
];

({String stat, BattleRngStream next})? _sampleStat(
  List<String> stats,
  BattleRngStream rng,
) {
  if (stats.isEmpty) {
    return null;
  }
  final roll = rng.nextIntInclusive(min: 0, max: stats.length - 1);
  return (stat: stats[roll.value], next: roll.next);
}

BattleEffectEndTurnResult? _healOwnerFraction({
  required BattleEffectEndTurnContext context,
  required int denominator,
  required String moveId,
}) {
  final battler = context.state.battlerAt(context.owner);
  if (battler.isFainted || battler.currentHp >= battler.maxHp) {
    return null;
  }

  final result = _heal(
    state: context.state,
    rng: context.rng,
    turn: context.turn,
    owner: context.owner,
    amount: battler.maxHp ~/ denominator,
    moveId: moveId,
  );
  if (!result.applied) {
    return null;
  }
  return BattleEffectEndTurnResult(
    state: result.state,
    rng: result.rng,
    events: result.events,
  );
}

BattleEffectEndTurnResult? _damageOwnerFraction({
  required BattleEffectEndTurnContext context,
  required int denominator,
  required String moveId,
}) {
  final battler = context.state.battlerAt(context.owner);
  if (battler.isFainted || battler.abilityId == 'magic_guard') {
    return null;
  }

  final damage = _fraction(battler.maxHp, denominator).clamp(
    1,
    battler.currentHp,
  );
  final result = const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      user: context.owner,
    ),
    target: context.owner,
    moveId: moveId,
    rawDamage: damage,
  );
  if (!result.applied) {
    return null;
  }
  return BattleEffectEndTurnResult(
    state: result.state,
    rng: result.rng,
    events: result.events,
  );
}

_HealResult _heal({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef owner,
  required int amount,
  required String moveId,
}) {
  final result = const BattleHealHandler().heal(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: owner,
    ),
    target: owner,
    amount: _fraction(amount, 1),
  );
  if (!result.applied) {
    return _HealResult(state: state, rng: rng, events: const []);
  }

  final healed = result.state.battlerAt(owner);
  return _HealResult(
    state: result.state,
    rng: result.rng,
    events: <PsdkBattleEvent>[
      PsdkBattleHealEvent(
        user: owner,
        target: owner,
        moveId: moveId,
        amount: result.amount,
        remainingHp: healed.currentHp,
      ),
    ],
    applied: true,
  );
}

bool _rainIsActive(PsdkBattleState state) {
  return state.isWeatherEffectActive(PsdkBattleWeatherId.rain) ||
      state.isWeatherEffectActive(PsdkBattleWeatherId.hardrain);
}

bool _sunIsActive(PsdkBattleState state) {
  return state.isWeatherEffectActive(PsdkBattleWeatherId.sunny) ||
      state.isWeatherEffectActive(PsdkBattleWeatherId.hardsun);
}

bool _sunIsActiveInField(PsdkBattleFieldState field) {
  return field.isWeatherActive(PsdkBattleWeatherId.sunny) ||
      field.isWeatherActive(PsdkBattleWeatherId.hardsun);
}

bool _snowIsActive(PsdkBattleState state) {
  return state.isWeatherEffectActive(PsdkBattleWeatherId.hail) ||
      state.isWeatherEffectActive(PsdkBattleWeatherId.snow);
}

int _fraction(int maxHp, int denominator) {
  return (maxHp ~/ denominator).clamp(1, maxHp).toInt();
}

final class _HealResult {
  const _HealResult({
    required this.state,
    required this.rng,
    required this.events,
    this.applied = false,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}
