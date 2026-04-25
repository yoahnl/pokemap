import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleItemChangeHandler {
  const BattleItemChangeHandler();

  BattleHandlerResult changeHeldItem({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String? heldItemId,
  }) {
    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (battler) => battler
            .copyWith(
              heldItemId: heldItemId,
              consumedItemId: null,
              itemConsumed: false,
            )
            .withItemEffect(target),
      ),
      rng: context.rng,
    );
  }

  BattleHandlerResult consumeHeldItem({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
  }) {
    final battler = context.state.battlerAt(target);
    final heldItemId = battler.heldItemId;
    if (heldItemId == null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'no_held_item',
      );
    }
    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (current) => current
            .copyWith(
              heldItemId: null,
              consumedItemId: heldItemId,
              itemConsumed: true,
            )
            .withItemEffect(target),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleItemEvent.consumed(
          turn: context.turn,
          user: target,
          itemId: heldItemId,
        ),
      ],
    );
  }
}
