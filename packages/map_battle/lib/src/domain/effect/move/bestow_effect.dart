import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK Bestow field marker.
///
/// Pokemon SDK returns the bestowed item at battle end in trainer-style battles.
/// Wild battles keep the transfer when the receiver is an opponent.
final class BestowEffect extends BattleEffect {
  const BestowEffect({
    required BattleEffectScope scope,
    required this.giver,
    required this.receiver,
    required this.itemId,
  }) : super(id: 'bestow', scope: scope);

  final PsdkBattleSlotRef giver;
  final PsdkBattleSlotRef receiver;
  final String itemId;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BestowEffect(
      scope: scope,
      giver: giver,
      receiver: receiver,
      itemId: itemId,
    );
  }

  @override
  BattleEffectBattleEndResult? onBattleEnd(
    BattleEffectBattleEndContext context,
  ) {
    if (context.owner != giver) {
      return null;
    }

    var state = context.state;
    var rng = context.rng;
    if (receiver.bank == 0 || !context.canFlee) {
      final receiverBattler = state.battlerAt(receiver);
      if (receiverBattler.heldItemId == itemId) {
        final restored = const BattleItemChangeHandler().changeHeldItem(
          context: BattleHandlerContext(
            state: state,
            rng: rng,
            turn: context.turn,
            user: giver,
          ),
          target: giver,
          heldItemId: itemId,
        );
        final cleared = const BattleItemChangeHandler().changeHeldItem(
          context: BattleHandlerContext(
            state: restored.state,
            rng: restored.rng,
            turn: context.turn,
            user: giver,
          ),
          target: receiver,
          heldItemId: null,
        );
        state = cleared.state;
        rng = cleared.rng;
      }
    }

    return BattleEffectBattleEndResult(
      state: state.updateBattler(
        giver,
        (battler) => battler.copyWith(
          effects: battler.effects.remove(id),
        ),
      ),
      rng: rng,
    );
  }
}
