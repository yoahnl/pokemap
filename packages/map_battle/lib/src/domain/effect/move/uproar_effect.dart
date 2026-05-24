import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class UproarEffect extends BattleEffect {
  const UproarEffect({
    required BattleEffectScope scope,
    int remainingTurns = 3,
  }) : super(
          id: 'uproar',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return UproarEffect(scope: scope, remainingTurns: remainingTurns);
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (context.status != PsdkBattleMajorStatus.sleep ||
        context.state.battlerAt(context.owner).isFainted) {
      return null;
    }
    return 'uproar_prevents_sleep';
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    final nextRemainingTurns = turns == null ? 0 : turns - 1;
    final nextEffects = nextRemainingTurns <= 0
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(nextRemainingTurns));

    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        if (nextRemainingTurns <= 0)
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: 0,
            reason: 'expired',
          )
        else
          PsdkBattleEffectEvent.ticked(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: nextRemainingTurns,
            reason: 'duration_tick',
          ),
      ],
    );
  }
}
