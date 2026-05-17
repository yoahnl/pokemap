import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../move/battle_move_prevention.dart';
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
