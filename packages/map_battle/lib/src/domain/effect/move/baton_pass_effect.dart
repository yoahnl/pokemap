import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class BatonPassEffect extends BattleEffect {
  const BatonPassEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'baton_pass',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BatonPassEffect(scope: scope);
  }
}
