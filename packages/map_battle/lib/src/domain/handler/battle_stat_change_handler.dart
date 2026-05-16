import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_scope.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleStatChangeHandler {
  const BattleStatChangeHandler();

  BattleHandlerResult applyStatChange({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String stat,
    required int stages,
  }) {
    if (stages == 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_stat_change',
      );
    }

    final battler = context.state.battlerAt(target);
    if (stages < 0 &&
        context.user.bank != target.bank &&
        _bankHasEffect(context.state, target.bank, 'mist')) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'mist',
      );
    }

    final statStages = battler.statStages.apply(stat: stat, stages: stages);
    final previousStage = battler.statStages.valueOf(stat);
    final currentStage = statStages.valueOf(stat);
    if (currentStage == previousStage) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: stages > 0 ? 'stat_stage_max' : 'stat_stage_min',
      );
    }

    final nextBattler =
        battler.copyWith(statStages: statStages).recordStatChange(
              turn: context.turn,
              stat: stat,
              delta: stages,
              currentStage: currentStage,
            );

    return BattleHandlerResult(
      state: context.state.replaceBattler(target, nextBattler),
      rng: context.rng,
      amount: stages,
      events: <PsdkBattleEvent>[
        PsdkBattleStatStageEvent(
          target: target,
          stat: stat,
          amount: stages,
          currentStage: currentStage,
        ),
      ],
    );
  }
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
