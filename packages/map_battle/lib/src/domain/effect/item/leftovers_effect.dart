import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class LeftoversEffect extends BattleItemEffect {
  const LeftoversEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'leftovers', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LeftoversEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    if (!isOwnedBy(owner)) {
      return null;
    }

    final battler = context.state.battlerAt(owner);
    if (battler.isFainted ||
        battler.heldItemId != itemId ||
        battler.itemConsumed ||
        battler.itemEffectsSuppressed ||
        battler.currentHp >= battler.maxHp) {
      return null;
    }

    final amount = (battler.maxHp ~/ 16).clamp(1, battler.maxHp).toInt();
    final result = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      amount: amount,
    );
    if (!result.applied) {
      return null;
    }

    final healed = result.state.battlerAt(owner);
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: owner,
          target: owner,
          moveId: 'item:leftovers',
          amount: result.amount,
          remainingHp: healed.currentHp,
        ),
      ],
    );
  }
}
