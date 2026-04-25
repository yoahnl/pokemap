import '../../psdk/domain/psdk_battle_outcome.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleBattleEndHandler {
  const BattleBattleEndHandler();

  BattleHandlerResult finish({
    required BattleHandlerContext context,
    required PsdkBattleOutcome outcome,
  }) {
    return BattleHandlerResult(
      state: context.state.copyWith(outcome: outcome),
      rng: context.rng,
    );
  }
}
