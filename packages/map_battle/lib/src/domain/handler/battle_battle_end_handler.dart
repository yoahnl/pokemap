import '../../psdk/domain/psdk_battle_outcome.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleBattleEndHandler {
  const BattleBattleEndHandler();

  BattleHandlerResult finish({
    required BattleHandlerContext context,
    required PsdkBattleOutcome outcome,
    bool canFlee = false,
  }) {
    var state = context.state;
    var rng = context.rng;
    final events = <PsdkBattleEvent>[];

    for (final owner in context.state.combatants.keys) {
      final result = state.battlerAt(owner).effects.dispatchBattleEnd(
            BattleEffectBattleEndContext(
              state: state,
              rng: rng,
              turn: context.turn,
              owner: owner,
              canFlee: canFlee,
            ),
          );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }

    return BattleHandlerResult(
      state: state.copyWith(outcome: outcome),
      rng: rng,
      events: events,
    );
  }
}
