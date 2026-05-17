import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityMoveTypeChangeMode {
  normalToType,
  anyToNormal,
  soundToWater,
}

final class MoveTypeChangeAbilityEffect extends BattleAbilityEffect {
  const MoveTypeChangeAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.mode,
    this.convertedType,
    this.powerMultiplier = 1,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityMoveTypeChangeMode mode;
  final String? convertedType;
  final double powerMultiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MoveTypeChangeAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      mode: mode,
      convertedType: convertedType,
      powerMultiplier: powerMultiplier,
    );
  }

  @override
  String? moveTypeOverride(BattleAbilityMoveTypeContext context) {
    if (_isWeatherBall(context.move.battleEngineMethod)) {
      return null;
    }
    return switch (mode) {
      AbilityMoveTypeChangeMode.normalToType =>
        context.currentType == 'normal' ? convertedType : null,
      AbilityMoveTypeChangeMode.anyToNormal => 'normal',
      AbilityMoveTypeChangeMode.soundToWater =>
        context.move.flags.sound ? 'water' : null,
    };
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    if (powerMultiplier == 1 ||
        _isWeatherBall(context.move.battleEngineMethod)) {
      return 1;
    }
    return switch (mode) {
      AbilityMoveTypeChangeMode.normalToType
          when context.move.type.toLowerCase() == 'normal' &&
              context.moveType == convertedType =>
        powerMultiplier,
      _ => 1,
    };
  }
}

bool _isWeatherBall(String battleEngineMethod) {
  return battleEngineMethod == 's_weather_ball';
}
