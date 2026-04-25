import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
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
    final statStages = battler.statStages.apply(stat: stat, stages: stages);
    final currentStage = statStages.valueOf(stat);
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
