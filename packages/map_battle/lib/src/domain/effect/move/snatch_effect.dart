import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class SnatchEffect extends BattleEffect {
  const SnatchEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'snatch',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SnatchEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}

final class SnatchedEffect extends BattleEffect {
  const SnatchedEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'snatched',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SnatchedEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
