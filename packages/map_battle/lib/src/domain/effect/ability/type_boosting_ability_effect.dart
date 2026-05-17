import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class TypeBoostingAbilityEffect extends BattleAbilityEffect {
  const TypeBoostingAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.boostedType,
    this.multiplier = 1.5,
    this.requiresLowHp = false,
  }) : super(abilityId: abilityId, scope: scope);

  final String boostedType;
  final double multiplier;
  final bool requiresLowHp;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TypeBoostingAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      boostedType: boostedType,
      multiplier: multiplier,
      requiresLowHp: requiresLowHp,
    );
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    if (context.moveType != boostedType) {
      return 1;
    }
    if (requiresLowHp &&
        !_isLowHp(context.user.currentHp, context.user.maxHp)) {
      return 1;
    }
    return multiplier;
  }
}

bool _isLowHp(int currentHp, int maxHp) {
  if (maxHp <= 0) {
    return false;
  }
  return currentHp / maxHp <= 1 / 3;
}
