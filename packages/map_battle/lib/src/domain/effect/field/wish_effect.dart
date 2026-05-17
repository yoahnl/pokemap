import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class WishEffect extends BattleEffect {
  const WishEffect({
    required BattleEffectScope scope,
    required this.healAmount,
    required int remainingTurns,
  }) : super(id: 'wish', scope: scope, remainingTurns: remainingTurns);

  final int healAmount;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WishEffect(
      scope: scope,
      healAmount: healAmount,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }

    if (turns > 1) {
      final nextEffects = context.state
          .battlerAt(context.owner)
          .effects
          .addEffect(copyWithRemainingTurns(turns - 1));
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          context.owner,
          (battler) => battler.copyWith(effects: nextEffects),
        ),
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleEffectEvent.ticked(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: turns - 1,
            reason: 'duration_tick',
          ),
        ],
      );
    }

    final clearedState = context.state.updateBattler(
      context.owner,
      (battler) => battler.copyWith(effects: battler.effects.remove(id)),
    );
    final healed = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: clearedState,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      amount: healAmount,
    );
    final events = <PsdkBattleEvent>[
      PsdkBattleEffectEvent.removed(
        turn: context.turn,
        target: context.owner,
        effectId: id,
        remainingTurns: 0,
        reason: 'resolved',
      ),
      if (healed.applied)
        PsdkBattleHealEvent(
          user: context.owner,
          target: context.owner,
          moveId: id,
          amount: healed.amount,
          remainingHp: healed.state.battlerAt(context.owner).currentHp,
        ),
    ];
    return BattleEffectEndTurnResult(
      state: healed.state,
      rng: healed.rng,
      events: events,
    );
  }
}
