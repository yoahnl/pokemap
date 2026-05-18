import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityFinalDamageCondition {
  superEffectiveIncoming,
  notVeryEffectiveOutgoing,
  superEffectiveOutgoing,
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
      AbilityFinalDamageCondition.superEffectiveOutgoing =>
        context.user.abilityId == abilityId &&
                context.typeEffectivenessMultiplier > 1
            ? multiplier
            : 1,
    };
  }
}

enum AbilityBasePowerCondition {
  lowHpUser,
  fluffyIncoming,
  contactIncoming,
  fireIncoming,
  fireOrIceIncoming,
  sandForceOutgoing,
  specialIncoming,
}

final class AbilityBasePowerModifierEffect extends BattleAbilityEffect {
  const AbilityBasePowerModifierEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.condition,
    required this.multiplier,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityBasePowerCondition condition;
  final double multiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AbilityBasePowerModifierEffect(
      abilityId: abilityId,
      scope: scope,
      condition: condition,
      multiplier: multiplier,
    );
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    return switch (condition) {
      AbilityBasePowerCondition.lowHpUser =>
        context.user.abilityId == abilityId &&
                context.user.currentHp < context.user.maxHp / 2
            ? multiplier
            : 1,
      AbilityBasePowerCondition.sandForceOutgoing =>
        context.user.abilityId == abilityId &&
                !context.weatherEffectsSuppressed &&
                context.field.isWeatherActive(PsdkBattleWeatherId.sandstorm) &&
                (context.moveType == 'steel' ||
                    context.moveType == 'rock' ||
                    context.moveType == 'ground')
            ? multiplier
            : 1,
      _ => 1,
    };
  }

  @override
  double incomingDamageBasePowerMultiplier(
    BattleAbilityDamageContext context,
  ) {
    if (context.target.abilityId != abilityId) {
      return 1;
    }
    return switch (condition) {
      AbilityBasePowerCondition.contactIncoming =>
        context.move.flags.contact ? multiplier : 1,
      AbilityBasePowerCondition.fluffyIncoming => context.move.flags.contact
          ? 0.5
          : context.moveType == 'fire'
              ? 2
              : 1,
      AbilityBasePowerCondition.fireIncoming =>
        context.moveType == 'fire' ? multiplier : 1,
      AbilityBasePowerCondition.fireOrIceIncoming =>
        context.moveType == 'fire' || context.moveType == 'ice'
            ? multiplier
            : 1,
      AbilityBasePowerCondition.specialIncoming =>
        context.move.category == PsdkBattleMoveCategory.special
            ? multiplier
            : 1,
      AbilityBasePowerCondition.lowHpUser ||
      AbilityBasePowerCondition.sandForceOutgoing =>
        1,
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
