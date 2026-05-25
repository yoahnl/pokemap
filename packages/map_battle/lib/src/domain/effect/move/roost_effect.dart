import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class RoostEffect extends BattleEffect {
  const RoostEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'roost',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RoostEffect(scope: scope, remainingTurns: remainingTurns);
  }
}
