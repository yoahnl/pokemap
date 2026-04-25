import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class AirLockEffect extends BattleAbilityEffect {
  const AirLockEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'air_lock', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AirLockEffect(scope: scope);
  }

  @override
  bool get suppressesWeatherEffects => true;
}
