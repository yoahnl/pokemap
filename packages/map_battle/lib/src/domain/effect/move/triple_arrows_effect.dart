import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `TripleArrows` critical-rate marker.
final class TripleArrowsEffect extends BattleEffect {
  const TripleArrowsEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'triple_arrows',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TripleArrowsEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return TripleArrowsEffect(
      scope: BattlerBattleEffectScope(context.target),
      remainingTurns: remainingTurns ?? 4,
    );
  }
}
