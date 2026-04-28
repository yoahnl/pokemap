import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class SmackDownEffect extends BattleEffect {
  const SmackDownEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'smack_down',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SmackDownEffect(scope: scope);
  }
}
