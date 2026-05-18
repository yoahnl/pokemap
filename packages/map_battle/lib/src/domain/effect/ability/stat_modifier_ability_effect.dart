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
