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
}
