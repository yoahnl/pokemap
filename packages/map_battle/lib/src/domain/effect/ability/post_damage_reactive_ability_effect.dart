import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/flinch_effect.dart';
import 'ability_effect.dart';
import 'mental_immunity_ability_effect.dart';

final class InnardsOutEffect extends BattleAbilityEffect {
  const InnardsOutEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'innards_out', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return InnardsOutEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        !context.targetFainted) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted) {
      return null;
    }

    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'effect:innards_out',
      rawDamage: context.damage,
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class CottonDownEffect extends BattleAbilityEffect {
  const CottonDownEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'cotton_down', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CottonDownEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;
    for (final target in context.state.aliveSlots()) {
      if (target == context.owner) {
        continue;
      }
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.owner,
        ),
        target: target,
        stat: 'speed',
        stages: -1,
        move: context.move,
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
    return BattleEffectPostDamageResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

final class ElectromorphosisEffect extends BattleAbilityEffect {
  const ElectromorphosisEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'electromorphosis', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ElectromorphosisEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0) {
      return null;
    }

    final target = context.state.battlerAt(context.target);
    if (target.effects.contains('charge')) {
      return null;
    }

    const chargeEffectId = 'charge';
    const chargeRemainingTurns = 2;
    final charge = GenericBattleEffect(
      id: chargeEffectId,
      scope: BattlerBattleEffectScope(context.target),
      remainingTurns: chargeRemainingTurns,
    );
    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.target,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(charge),
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.target,
          effectId: chargeEffectId,
          remainingTurns: charge.remainingTurns,
          reason: 'ability:electromorphosis',
        ),
      ],
    );
  }
}

final class StenchEffect extends BattleAbilityEffect {
  const StenchEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'stench', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StenchEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.user ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted || _heldItemSuppressesStench(user.heldItemId)) {
      return null;
    }

    final roll = context.rng.generic.nextChance(
      numerator: 1,
      denominator: 10,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur ||
        battleMentalAbilityBlocksEffect(
          state: context.state,
          user: context.user,
          target: context.target,
          effectId: 'flinch',
        )) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }

    final result = applyFlinchEffect(
      state: context.state,
      rng: nextRng,
      turn: context.turn,
      target: context.target,
      reason: 'ability:stench',
      move: context.move,
    );
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  bool _heldItemSuppressesStench(String? itemId) {
    return itemId == 'king_s_rock' || itemId == 'razor_fang';
  }
}
