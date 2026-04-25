import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class RecklessEffect extends BattleAbilityEffect {
  const RecklessEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'reckless', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RecklessEffect(scope: scope);
  }

  @override
  double basePowerMultiplier(BattleAbilityMoveContext context) {
    if (!isOwnedBy(context.user)) {
      return 1;
    }
    return context.move.battleEngineMethod == 's_recoil' ? 1.2 : 1;
  }
}
