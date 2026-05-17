import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class HealingWishEffect extends BattleEffect {
  const HealingWishEffect({
    required BattleEffectScope scope,
    required this.restorePp,
  }) : super(
          id: restorePp ? 'lunar_dance' : 'healing_wish',
          scope: scope,
        );

  final bool restorePp;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HealingWishEffect(scope: scope, restorePp: restorePp);
  }
}
