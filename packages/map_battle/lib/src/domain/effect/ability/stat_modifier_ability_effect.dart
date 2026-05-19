import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

typedef AbilityStatCondition = bool Function(BattleAbilityStatContext context);

final class StatModifierAbilityEffect extends BattleAbilityEffect {
  const StatModifierAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.statMultipliers,
    AbilityStatCondition? condition,
  })  : _condition = condition,
        super(abilityId: abilityId, scope: scope);

  final Map<String, double> statMultipliers;
  final AbilityStatCondition? _condition;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatModifierAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      statMultipliers: statMultipliers,
      condition: _condition,
    );
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    if (context.battler.abilityId != abilityId ||
        !(_condition?.call(context) ?? true)) {
      return 1;
    }
    return statMultipliers[context.stat] ?? 1;
  }
}

final class PlusMinusAbilityEffect extends BattleAbilityEffect {
  const PlusMinusAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  static const Set<String> _partnerAbilities = <String>{'plus', 'minus'};

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PlusMinusAbilityEffect(abilityId: abilityId, scope: scope);
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    final state = context.state;
    if (context.stat != 'specialAttack' ||
        ownerSlot == null ||
        context.battlerSlot != ownerSlot ||
        state == null ||
        context.battler.abilityId != abilityId) {
      return 1;
    }
    for (final allySlot in state.alliesOf(ownerSlot)) {
      final ally = state.battlerAt(allySlot);
      if (ally.effects.contains('ability_suppressed')) {
        continue;
      }
      final allyAbilityId = ally.abilityId;
      if (allyAbilityId != null && _partnerAbilities.contains(allyAbilityId)) {
        return 1.5;
      }
    }
    return 1;
  }
}

final class FlowerGiftStatAbilityEffect extends BattleAbilityEffect {
  const FlowerGiftStatAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'flower_gift', scope: scope);

  @override
  bool get affectsGlobalStats => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FlowerGiftStatAbilityEffect(scope: scope);
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    final battlerSlot = context.battlerSlot;
    if (ownerSlot == null ||
        battlerSlot == null ||
        ownerSlot.bank != battlerSlot.bank ||
        !hasSunnyWeather(context)) {
      return 1;
    }
    return switch (context.stat) {
      'attack' || 'specialDefense' => 1.5,
      _ => 1,
    };
  }
}

final class RuinStatAbilityEffect extends BattleAbilityEffect {
  const RuinStatAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.stat,
  }) : super(abilityId: abilityId, scope: scope);

  final String stat;

  @override
  bool get affectsGlobalStats => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RuinStatAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      stat: stat,
    );
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    final battlerSlot = context.battlerSlot;
    if (ownerSlot == null ||
        battlerSlot == null ||
        battlerSlot == ownerSlot ||
        context.stat != stat ||
        context.battler.abilityId == abilityId) {
      return 1;
    }
    return 0.75;
  }
}

bool hasMajorStatus(BattleAbilityStatContext context) {
  return context.battler.majorStatus != null;
}

bool hasBurnStatus(BattleAbilityStatContext context) {
  return context.battler.majorStatus == PsdkBattleMajorStatus.burn;
}

bool hasPoisonStatus(BattleAbilityStatContext context) {
  return context.battler.majorStatus == PsdkBattleMajorStatus.poison ||
      context.battler.majorStatus == PsdkBattleMajorStatus.toxic;
}

bool hasGrassyTerrain(BattleAbilityStatContext context) {
  return context.field.isTerrainActive(PsdkBattleTerrainId.grassyTerrain);
}

bool hasElectricTerrain(BattleAbilityStatContext context) {
  return context.field.isTerrainActive(PsdkBattleTerrainId.electricTerrain);
}

bool hasSunnyWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      context.field.isWeatherActive(PsdkBattleWeatherId.sunny);
}

bool hasRainWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      (context.field.isWeatherActive(PsdkBattleWeatherId.rain) ||
          context.field.isWeatherActive(PsdkBattleWeatherId.hardrain));
}

bool hasSandstormWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      context.field.isWeatherActive(PsdkBattleWeatherId.sandstorm);
}

bool hasSnowingWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      (context.field.isWeatherActive(PsdkBattleWeatherId.hail) ||
          context.field.isWeatherActive(PsdkBattleWeatherId.snow));
}
