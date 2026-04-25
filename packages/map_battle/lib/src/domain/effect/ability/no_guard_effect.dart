import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class NoGuardEffect extends BattleAbilityEffect {
  const NoGuardEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'no_guard', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return NoGuardEffect(scope: scope);
  }

  @override
  bool bypassesAccuracy(BattleAbilityMoveContext context) {
    return isOwnedBy(context.user) || isOwnedBy(context.target);
  }
}
