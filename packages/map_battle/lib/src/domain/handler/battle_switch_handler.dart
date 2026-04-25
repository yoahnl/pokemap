import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleSwitchHandler {
  const BattleSwitchHandler();

  BattleHandlerResult markSwitching({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required bool switching,
  }) {
    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (battler) => battler.copyWith(switching: switching),
      ),
      rng: context.rng,
    );
  }

  BattleHandlerResult batonPassTransfer({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef source,
    required PsdkBattleSlotRef replacement,
  }) {
    final sourceBattler = context.state.battlerAt(source);
    if (!sourceBattler.effects.contains('baton_pass')) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'no_baton_pass_effect',
      );
    }

    final replacementBattler = context.state.battlerAt(replacement);
    final transferred = sourceBattler.effects.batonPassTransferEffects(
      source: source,
      target: replacement,
    );
    final sourceEffects = sourceBattler.effects
        .withoutBatonPassTransferableEffects(
          source: source,
          target: replacement,
        )
        .remove('baton_pass');
    final replacementEffects = replacementBattler.effects.addEffects(
      transferred.effects,
    );

    return BattleHandlerResult(
      state: context.state
          .updateBattler(
            source,
            (battler) => battler.copyWith(
              statStages: PsdkBattleStatStages.neutral(),
              effects: sourceEffects,
              switching: false,
            ),
          )
          .updateBattler(
            replacement,
            (battler) => battler.copyWith(
              statStages: sourceBattler.statStages,
              effects: replacementEffects,
            ),
          ),
      rng: context.rng,
    );
  }
}
