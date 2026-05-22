import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/ability/mental_immunity_ability_effect.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/move/confusion_effect.dart';
import '../effect/move/flinch_effect.dart';
import '../handler/battle_handler_context.dart';
import '../handler/battle_stat_change_handler.dart';
import '../handler/battle_status_change_handler.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_data.dart';

final class BattleMoveSecondaryEffectResolver {
  const BattleMoveSecondaryEffectResolver();

  BattleMoveSecondaryEffectResult resolve({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required int turn,
  }) {
    if (move.statuses.isEmpty && move.stageMods.isEmpty) {
      return BattleMoveSecondaryEffectResult(
        state: state,
        rng: rng,
        events: const <PsdkBattleEvent>[],
      );
    }

    var nextState = state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[];
    final secondaryContext = BattleAbilitySecondaryEffectContext(
      state: nextState,
      user: user,
      target: target,
      move: move,
    );
    if (_secondaryEffectsPrevented(secondaryContext)) {
      return BattleMoveSecondaryEffectResult(
        state: nextState,
        rng: nextRng,
        events: events,
      );
    }

    final globalChance = _modifiedChance(
      move.effectChance,
      secondaryContext,
    );
    if (globalChance != null && globalChance < 100) {
      final roll = nextRng.generic.nextPercent();
      nextRng = nextRng.copyWith(generic: roll.next);
      if (roll.value > globalChance) {
        return BattleMoveSecondaryEffectResult(
          state: nextState,
          rng: nextRng,
          events: events,
        );
      }
    }

    for (final status in move.statuses) {
      final statusChance = _modifiedChance(status.chance, secondaryContext);
      if (globalChance == null && statusChance != null && statusChance < 100) {
        final roll = nextRng.generic.nextPercent();
        nextRng = nextRng.copyWith(generic: roll.next);
        if (roll.value > statusChance) {
          continue;
        }
      }

      final majorStatus = status.majorStatus;
      if (majorStatus != null) {
        final result = const BattleStatusChangeHandler().applyMajorStatus(
          context: BattleHandlerContext(
            state: nextState,
            rng: nextRng,
            turn: turn,
            user: user,
          ),
          target: target,
          moveId: move.id,
          status: majorStatus,
          move: move,
        );
        nextState = result.state;
        nextRng = result.rng;
        if (result.applied) {
          events.addAll(result.events);
        }
        continue;
      }

      if (status.volatileStatus == PsdkBattleVolatileStatus.confusion &&
          !_safeguardPreventsVolatileStatus(
            state: nextState,
            user: user,
            target: target,
          ) &&
          !battleMentalAbilityBlocksEffect(
            state: nextState,
            user: user,
            target: target,
            effectId: PsdkBattleEffectIds.confusion,
          ) &&
          !nextState
              .battlerAt(target)
              .effects
              .contains(PsdkBattleEffectIds.confusion)) {
        final durationRoll = nextRng.generic.nextIntInclusive(min: 1, max: 4);
        nextRng = nextRng.copyWith(generic: durationRoll.next);
        nextState = nextState.updateBattler(
          target,
          (battler) => battler.copyWith(
            effects: battler.effects.addEffect(
              ConfusionEffect(
                scope: BattlerBattleEffectScope(target),
                remainingConfusionTurns: durationRoll.value + 1,
              ),
            ),
          ),
        );
        final postVolatile = nextState
            .battlerAt(target)
            .effects
            .dispatchPostVolatileStatusChange(
              BattleEffectVolatileStatusChangeContext(
                state: nextState,
                rng: nextRng,
                turn: turn,
                owner: target,
                user: user,
                target: target,
                effectId: PsdkBattleEffectIds.confusion,
                cured: false,
                moveId: move.id,
                move: move,
              ),
            );
        nextState = postVolatile.state;
        nextRng = postVolatile.rng;
        events.addAll(postVolatile.events);
      }

      if (status.volatileStatus == PsdkBattleVolatileStatus.flinch &&
          !battleMentalAbilityBlocksEffect(
            state: nextState,
            user: user,
            target: target,
            effectId: PsdkBattleEffectIds.flinch,
          ) &&
          !nextState
              .battlerAt(target)
              .effects
              .contains(PsdkBattleEffectIds.flinch)) {
        final result = applyFlinchEffect(
          state: nextState,
          rng: nextRng,
          turn: turn,
          target: target,
          reason: move.id,
          move: move,
        );
        nextState = result.state;
        nextRng = result.rng;
        events.addAll(result.events);
      }
    }

    for (final mod in move.stageMods) {
      if (mod.stages == 0) {
        continue;
      }
      final modChance = _modifiedChance(mod.chance, secondaryContext);
      if (globalChance == null && modChance != null && modChance < 100) {
        final roll = nextRng.generic.nextPercent();
        nextRng = nextRng.copyWith(generic: roll.next);
        if (roll.value > modChance) {
          continue;
        }
      }

      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: turn,
          user: user,
        ),
        target: target,
        stat: mod.stat,
        stages: mod.stages,
        move: move,
      );
      nextState = result.state;
      nextRng = result.rng;
      if (result.applied) {
        events.addAll(result.events);
      }
    }

    return BattleMoveSecondaryEffectResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

bool _secondaryEffectsPrevented(BattleAbilitySecondaryEffectContext context) {
  if (_sheerForceSuppresses(context)) {
    return true;
  }
  for (final effect in context.state.activeAbilityEffects()) {
    if (effect.preventsSecondaryEffects(context)) {
      return true;
    }
  }
  return false;
}

bool _sheerForceSuppresses(BattleAbilitySecondaryEffectContext context) {
  final user = context.state.battlerAt(context.user);
  if (user.abilityId != 'sheer_force' ||
      user.effects.contains('ability_suppressed') ||
      context.move.category == PsdkBattleMoveCategory.status) {
    return false;
  }
  if (context.move.statuses.any(
        (status) => status.majorStatus != null || status.volatileStatus != null,
      ) ||
      context.move.effectChance != null) {
    return true;
  }
  if (context.move.stageMods.isEmpty) {
    return false;
  }
  final onlyPositive = context.move.stageMods.every((mod) => mod.stages > 0);
  final onlyNegative = context.move.stageMods.every((mod) => mod.stages < 0);
  return switch (context.move.target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => onlyPositive,
    _ => onlyNegative,
  };
}

int? battleModifiedSecondaryEffectChance({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
  required int? chance,
}) {
  return _modifiedChance(
    chance,
    BattleAbilitySecondaryEffectContext(
      state: state,
      user: user,
      target: target,
      move: move,
    ),
  );
}

int? _modifiedChance(
  int? chance,
  BattleAbilitySecondaryEffectContext context,
) {
  if (chance == null) {
    return null;
  }
  var multiplier = 1.0;
  for (final effect in context.state.activeAbilityEffects()) {
    multiplier *= effect.secondaryEffectChanceMultiplier(context);
  }
  final modified = (chance * multiplier).floor();
  return modified > 100 ? 100 : modified;
}

bool _safeguardPreventsVolatileStatus({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
}) {
  if (user == target || state.battlerAt(user).abilityId == 'infiltrator') {
    return false;
  }
  return _bankHasEffect(state, target.bank, 'safeguard');
}

bool _bankHasEffect(PsdkBattleState state, int bank, String effectId) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any((effect) {
      if (effect.id != effectId) {
        return false;
      }
      final scope = effect.scope;
      if (scope is BankBattleEffectScope) {
        return scope.bank == bank;
      }
      if (scope is BattlerBattleEffectScope) {
        return scope.slot.bank == bank;
      }
      return false;
    }),
  );
}

final class BattleMoveSecondaryEffectResult {
  BattleMoveSecondaryEffectResult({
    required this.state,
    required this.rng,
    required List<PsdkBattleEvent> events,
  }) : events = List<PsdkBattleEvent>.unmodifiable(events);

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
