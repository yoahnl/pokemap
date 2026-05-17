import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class EmbargoEffect extends BattleEffect {
  const EmbargoEffect({
    required BattleEffectScope scope,
    int remainingTurns = 5,
  }) : super(
          id: 'embargo',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return EmbargoEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return EmbargoEffect(
      scope: BattlerBattleEffectScope(context.target),
      remainingTurns: remainingTurns ?? 5,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextEffects = turns <= 1
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(turns - 1));
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }
}
