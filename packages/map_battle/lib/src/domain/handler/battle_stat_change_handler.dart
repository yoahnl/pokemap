import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/battle_effect_scope.dart';
import '../move/battle_move_data.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleStatChangeHandler {
  const BattleStatChangeHandler();

  BattleHandlerResult applyStatChange({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String stat,
    required int stages,
    BattleMoveDefinition? move,
    String? sourceAbilityId,
  }) {
    if (stages == 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_stat_change',
      );
    }

    var effectiveStages = stages;
    final hookPrevention = _statPreventionReason(
      context: context,
      target: target,
      stat: stat,
      stages: effectiveStages,
      move: move,
      sourceAbilityId: sourceAbilityId,
    );
    if (hookPrevention != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: hookPrevention,
      );
    }

    final fieldPrevention = _fieldStatPreventionReason(
      context: context,
      target: target,
      stages: effectiveStages,
    );
    if (fieldPrevention != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: fieldPrevention,
      );
    }

    final redirect = _dispatchStatChangeRedirect(
      context: context,
      target: target,
      stat: stat,
      stages: effectiveStages,
      move: move,
      sourceAbilityId: sourceAbilityId,
    );
    if (redirect != null) {
      return BattleHandlerResult(
        state: redirect.state,
        rng: redirect.rng,
        events: redirect.events,
        applied: redirect.applied,
        reason: 'stat_change_redirected',
      );
    }

    effectiveStages = _resolveStatChangeHooks(
      context: context,
      target: target,
      stat: stat,
      stages: effectiveStages,
      move: move,
      sourceAbilityId: sourceAbilityId,
    );
    if (effectiveStages == 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_stat_change',
      );
    }

    final battler = context.state.battlerAt(target);
    final statStages =
        battler.statStages.apply(stat: stat, stages: effectiveStages);
    final previousStage = battler.statStages.valueOf(stat);
    final currentStage = statStages.valueOf(stat);
    if (currentStage == previousStage) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: effectiveStages > 0 ? 'stat_stage_max' : 'stat_stage_min',
      );
    }

    final nextBattler =
        battler.copyWith(statStages: statStages).recordStatChange(
              turn: context.turn,
              stat: stat,
              delta: effectiveStages,
              currentStage: currentStage,
            );

    final baseState = context.state.replaceBattler(target, nextBattler);
    final post = _dispatchStatChangePost(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: target,
      stat: stat,
      stages: effectiveStages,
      sourceAbilityId: sourceAbilityId,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      amount: effectiveStages,
      events: <PsdkBattleEvent>[
        PsdkBattleStatStageEvent(
          target: target,
          stat: stat,
          amount: effectiveStages,
          currentStage: currentStage,
        ),
        ...post.events,
      ],
    );
  }
}

String? _statPreventionReason({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required String stat,
  required int stages,
  required BattleMoveDefinition? move,
  required String? sourceAbilityId,
}) {
  for (final owner in _orderedSlots(context.state)) {
    final reason =
        context.state.battlerAt(owner).effects.statChangePreventionReason(
              BattleEffectStatChangePreventionContext(
                state: context.state,
                rng: context.rng,
                turn: context.turn,
                owner: owner,
                user: context.user,
                target: target,
                stat: stat,
                stages: stages,
                move: move,
                sourceAbilityId: sourceAbilityId,
              ),
            );
    if (reason != null) {
      return reason;
    }
  }
  return null;
}

String? _fieldStatPreventionReason({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required int stages,
}) {
  if (stages < 0 &&
      context.user.bank != target.bank &&
      _bankHasEffect(context.state, target.bank, 'mist')) {
    return 'mist';
  }
  return null;
}

BattleEffectStatChangeRedirectResult? _dispatchStatChangeRedirect({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required String stat,
  required int stages,
  required BattleMoveDefinition? move,
  required String? sourceAbilityId,
}) {
  for (final owner in _orderedSlots(context.state)) {
    final result = context.state.battlerAt(owner).effects.statChangeRedirect(
          BattleEffectStatChangeContext(
            state: context.state,
            rng: context.rng,
            turn: context.turn,
            owner: owner,
            user: context.user,
            target: target,
            stat: stat,
            stages: stages,
            move: move,
            sourceAbilityId: sourceAbilityId,
          ),
        );
    if (result != null) {
      return result;
    }
  }
  return null;
}

int _resolveStatChangeHooks({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required String stat,
  required int stages,
  required BattleMoveDefinition? move,
  required String? sourceAbilityId,
}) {
  var effectiveStages = stages;
  for (final owner in _orderedSlots(context.state)) {
    effectiveStages = context.state.battlerAt(owner).effects.resolveStatChange(
          BattleEffectStatChangeContext(
            state: context.state,
            rng: context.rng,
            turn: context.turn,
            owner: owner,
            user: context.user,
            target: target,
            stat: stat,
            stages: effectiveStages,
            move: move,
            sourceAbilityId: sourceAbilityId,
          ),
        );
  }
  return effectiveStages;
}

BattleEffectStatChangePostResult _dispatchStatChangePost({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required String stat,
  required int stages,
  required String? sourceAbilityId,
}) {
  var nextState = context.state;
  var nextRng = context.rng;
  final events = <PsdkBattleEvent>[];
  var changed = false;
  for (final owner in _orderedSlots(nextState)) {
    final result = nextState.battlerAt(owner).effects.dispatchStatChangePost(
          BattleEffectStatChangeContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            owner: owner,
            user: context.user,
            target: target,
            stat: stat,
            stages: stages,
            sourceAbilityId: sourceAbilityId,
          ),
        );
    nextState = result.state;
    nextRng = result.rng;
    events.addAll(result.events);
    changed = changed || result.applied || result.events.isNotEmpty;
  }
  return BattleEffectStatChangePostResult(
    state: nextState,
    rng: nextRng,
    events: events,
    applied: changed,
  );
}

List<PsdkBattleSlotRef> _orderedSlots(PsdkBattleState state) {
  final slots = state.combatants.keys.toList();
  slots.sort(_compareSlots);
  return slots;
}

int _compareSlots(PsdkBattleSlotRef a, PsdkBattleSlotRef b) {
  final bank = a.bank.compareTo(b.bank);
  return bank != 0 ? bank : a.position.compareTo(b.position);
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
