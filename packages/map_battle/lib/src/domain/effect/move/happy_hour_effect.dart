import '../battle_effect.dart';
import '../battle_effect_scope.dart';

/// Passive PSDK `HappyHour` effect marker.
final class HappyHourEffect extends BattleEffect {
  const HappyHourEffect({
    required BattleEffectScope scope,
    int? remainingTurns,
  }) : super(
          id: 'happy_hour',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HappyHourEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
