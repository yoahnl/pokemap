import '../../psdk/domain/psdk_battle_slots.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleHealHandler {
  const BattleHealHandler();

  BattleHandlerResult heal({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required int amount,
  }) {
    final battler = context.state.battlerAt(target);
    final healed = amount.clamp(0, battler.maxHp - battler.currentHp).toInt();
    if (healed <= 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_heal',
      );
    }
    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (current) => current.copyWith(currentHp: current.currentHp + healed),
      ),
      rng: context.rng,
      amount: healed,
    );
  }
}
