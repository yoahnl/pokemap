import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

sealed class PledgeFieldEffect extends BattleEffect {
  const PledgeFieldEffect({
    required String id,
    required BattleEffectScope scope,
    required int remainingTurns,
  }) : super(id: id, scope: scope, remainingTurns: remainingTurns);

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextRemainingTurns = turns - 1;
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

final class RainbowPledgeEffect extends PledgeFieldEffect {
  const RainbowPledgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'pledge_rainbow',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RainbowPledgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}

final class SeaOfFirePledgeEffect extends PledgeFieldEffect {
  const SeaOfFirePledgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'pledge_sea_of_fire',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SeaOfFirePledgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}

final class SwampPledgeEffect extends PledgeFieldEffect {
  const SwampPledgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'pledge_swamp',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwampPledgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
