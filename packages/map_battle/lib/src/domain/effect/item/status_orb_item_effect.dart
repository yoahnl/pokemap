import '../../../psdk/domain/psdk_battle_move.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class StatusOrbItemEffect extends BattleItemEffect {
  const StatusOrbItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.status,
  }) : super(itemId: itemId, scope: scope);

  final PsdkBattleMajorStatus status;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = this.owner;
    if (owner == null || context.owner != owner) {
      return null;
    }
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted ||
        battler.heldItemId != itemId ||
        battler.itemConsumed ||
        battler.itemEffectsSuppressed ||
        battler.abilityId == 'magic_guard' ||
        battler.majorStatus != null) {
      return null;
    }

    final changed = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'item:$itemId',
      status: status,
    );
    if (!changed.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: changed.state,
      rng: changed.rng,
      events: changed.events,
    );
  }
}
