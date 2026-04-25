import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class AquaRingEffect extends BattleEffect {
  const AquaRingEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'aqua_ring',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AquaRingEffect(scope: scope);
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return AquaRingEffect(scope: BattlerBattleEffectScope(context.target));
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.currentHp >= battler.maxHp) {
      return null;
    }

    var healAmount = battler.maxHp ~/ 16;
    if (healAmount < 1) {
      healAmount = 1;
    }
    if (battler.heldItemId == 'big_root') {
      healAmount += (healAmount * 30) ~/ 100;
    }

    final result = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      amount: healAmount,
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
          moveId: 'effect:aqua_ring',
          amount: result.amount,
          remainingHp: healed.currentHp,
        ),
      ],
    );
  }
}
