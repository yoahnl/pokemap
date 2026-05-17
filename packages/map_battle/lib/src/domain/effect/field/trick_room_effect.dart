import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class TrickRoomEffect extends BattleEffect {
  const TrickRoomEffect({
    int remainingTurns = 5,
  }) : super(
          id: 'trick_room',
          scope: const FieldBattleEffectScope(),
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TrickRoomEffect(remainingTurns: remainingTurns);
  }

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
