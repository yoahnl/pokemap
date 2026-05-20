import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
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
  stakeoutOutgoing,
  analyticOutgoing,
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
      AbilityBasePowerCondition.stakeoutOutgoing =>
        context.user.abilityId == abilityId &&
                context.user.battleTurnCount >= 1 &&
                context.target.switching
            ? multiplier
            : 1,
      AbilityBasePowerCondition.analyticOutgoing =>
        context.user.abilityId == abilityId && context.isLastActionOfTurn
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
      AbilityBasePowerCondition.sandForceOutgoing ||
      AbilityBasePowerCondition.stakeoutOutgoing ||
      AbilityBasePowerCondition.analyticOutgoing =>
        1,
    };
  }
}

final class RivalryEffect extends BattleAbilityEffect {
  const RivalryEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'rivalry', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RivalryEffect(scope: scope);
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    if (context.user.abilityId != abilityId) {
      return 1;
    }
    final userGender = context.user.gender;
    final targetGender = context.target.gender;
    if (userGender == PsdkBattleGender.unknown ||
        targetGender == PsdkBattleGender.unknown) {
      return 1;
    }
    return userGender == targetGender ? 1.25 : 0.75;
  }
}

final class AuraPowerAbilityEffect extends BattleAbilityEffect {
  const AuraPowerAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AuraPowerAbilityEffect(abilityId: abilityId, scope: scope);
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    if (context.user.abilityId != abilityId) {
      return 1;
    }
    return _auraMultiplier(context);
  }

  @override
  double incomingDamageBasePowerMultiplier(
    BattleAbilityDamageContext context,
  ) {
    if (context.user.abilityId == abilityId ||
        context.target.abilityId != abilityId) {
      return 1;
    }
    return _auraMultiplier(context);
  }

  double _auraMultiplier(BattleAbilityDamageContext context) {
    final auraAbility = switch (context.moveType) {
      'dark' => 'dark_aura',
      'fairy' => 'fairy_aura',
      _ => null,
    };
    if (auraAbility == null ||
        abilityId != auraAbility ||
        !context.activeAbilityIds.contains(auraAbility)) {
      return 1;
    }
    return context.activeAbilityIds.contains('aura_break') ? 0.75 : 1.33;
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

enum AllyDamageModifierKind {
  batterySpecialAttack,
  friendGuard,
  powerSpot,
  steelySpirit,
}

final class AllyDamageModifierAbilityEffect extends BattleAbilityEffect {
  const AllyDamageModifierAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.kind,
    required this.multiplier,
  }) : super(abilityId: abilityId, scope: scope);

  final AllyDamageModifierKind kind;
  final double multiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AllyDamageModifierAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      kind: kind,
      multiplier: multiplier,
    );
  }

  @override
  double offensiveStatMultiplier(BattleAbilityDamageContext context) {
    if (kind != AllyDamageModifierKind.batterySpecialAttack ||
        context.move.category != PsdkBattleMoveCategory.special ||
        !_sameBankDifferentSlot(owner, context.userSlot)) {
      return 1;
    }
    return multiplier;
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    return switch (kind) {
      AllyDamageModifierKind.friendGuard =>
        _sameBankDifferentSlot(owner, context.targetSlot) ? multiplier : 1,
      AllyDamageModifierKind.powerSpot =>
        _sameBankDifferentSlot(owner, context.userSlot) ? multiplier : 1,
      AllyDamageModifierKind.steelySpirit =>
        _sameBankDifferentSlot(owner, context.userSlot) &&
                context.moveType == 'steel'
            ? multiplier
            : 1,
      AllyDamageModifierKind.batterySpecialAttack => 1,
    };
  }
}

bool _sameBank(PsdkBattleSlotRef? left, PsdkBattleSlotRef? right) {
  return left != null && right != null && left.bank == right.bank;
}

bool _sameBankDifferentSlot(PsdkBattleSlotRef? left, PsdkBattleSlotRef? right) {
  return _sameBank(left, right) && left != right;
}
