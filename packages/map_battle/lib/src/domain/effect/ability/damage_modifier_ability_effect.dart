import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityFinalDamageCondition {
  superEffectiveIncoming,
  notVeryEffectiveOutgoing,
}

final class AbilityFinalDamageModifierEffect extends BattleAbilityEffect {
  const AbilityFinalDamageModifierEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.condition,
    required this.multiplier,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityFinalDamageCondition condition;
  final double multiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AbilityFinalDamageModifierEffect(
      abilityId: abilityId,
      scope: scope,
      condition: condition,
      multiplier: multiplier,
    );
  }

  @override
  double finalDamageMultiplier(BattleAbilityDamageContext context) {
    return switch (condition) {
      AbilityFinalDamageCondition.superEffectiveIncoming =>
        context.target.abilityId == abilityId &&
                context.typeEffectivenessMultiplier > 1
            ? multiplier
            : 1,
      AbilityFinalDamageCondition.notVeryEffectiveOutgoing =>
        context.user.abilityId == abilityId &&
                context.typeEffectivenessMultiplier < 1
            ? multiplier
            : 1,
    };
  }
}

final class FullHpIncomingPowerReductionEffect extends BattleAbilityEffect {
  const FullHpIncomingPowerReductionEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.multiplier,
  }) : super(abilityId: abilityId, scope: scope);

  final double multiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FullHpIncomingPowerReductionEffect(
      abilityId: abilityId,
      scope: scope,
      multiplier: multiplier,
    );
  }

  @override
  double incomingDamageBasePowerMultiplier(BattleAbilityDamageContext context) {
    if (context.target.abilityId != abilityId) {
      return 1;
    }
    if (context.target.currentHp != context.target.maxHp) {
      return 1;
    }
    return multiplier;
  }
}
