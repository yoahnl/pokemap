import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/ability/mental_immunity_ability_effect.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/move/confusion_effect.dart';
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

    final globalChance = move.effectChance;
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
      if (globalChance == null && status.chance < 100) {
        final roll = nextRng.generic.nextPercent();
        nextRng = nextRng.copyWith(generic: roll.next);
        if (roll.value > status.chance) {
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
      }
    }

    for (final mod in move.stageMods) {
      if (mod.stages == 0) {
        continue;
      }
      if (globalChance == null && mod.chance != null && mod.chance! < 100) {
        final roll = nextRng.generic.nextPercent();
        nextRng = nextRng.copyWith(generic: roll.next);
        if (roll.value > mod.chance!) {
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
