import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleItemChangeHandler {
  const BattleItemChangeHandler();

  BattleHandlerResult changeHeldItem({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String? heldItemId,
  }) {
    final previousItemId = context.state.battlerAt(target).heldItemId;
    final nextState = context.state.updateBattler(
      target,
      (battler) => battler
          .copyWith(
            heldItemId: heldItemId,
            consumedItemId: null,
            itemConsumed: false,
          )
          .withItemEffect(target),
    );
    return _dispatchPostItemChange(
      context: context,
      state: nextState,
      rng: context.rng,
      target: target,
      previousItemId: previousItemId,
      nextItemId: heldItemId,
      consumedItemId: null,
      reason: 'changed',
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
    final itemEvents = <PsdkBattleEvent>[
      PsdkBattleItemEvent.consumed(
        turn: context.turn,
        user: target,
        itemId: heldItemId,
      ),
    ];
    final nextState = context.state.updateBattler(
      target,
      (current) => current
          .copyWith(
            heldItemId: null,
            consumedItemId: heldItemId,
            itemConsumed: true,
          )
          .withItemEffect(target),
    );
    return _dispatchPostItemChange(
      context: context,
      state: nextState,
      rng: context.rng,
      target: target,
      previousItemId: heldItemId,
      nextItemId: null,
      consumedItemId: heldItemId,
      reason: 'consumed',
      initialEvents: itemEvents,
    );
  }

  BattleHandlerResult _dispatchPostItemChange({
    required BattleHandlerContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef target,
    required String? previousItemId,
    required String? nextItemId,
    required String? consumedItemId,
    required String reason,
    List<PsdkBattleEvent> initialEvents = const <PsdkBattleEvent>[],
  }) {
    var nextState = state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[...initialEvents];
    var changed = true;

    for (final owner in state.aliveSlots()) {
      final result = nextState.battlerAt(owner).effects.dispatchPostItemChange(
            BattleEffectItemChangeContext(
              state: nextState,
              rng: nextRng,
              turn: context.turn,
              owner: owner,
              target: target,
              previousItemId: previousItemId,
              nextItemId: nextItemId,
              consumedItemId: consumedItemId,
              reason: reason,
            ),
          );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleHandlerResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }
}
