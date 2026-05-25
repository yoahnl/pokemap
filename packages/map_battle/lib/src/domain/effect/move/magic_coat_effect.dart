import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class MagicCoatEffect extends BattleEffect {
  const MagicCoatEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'magic_coat',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MagicCoatEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
