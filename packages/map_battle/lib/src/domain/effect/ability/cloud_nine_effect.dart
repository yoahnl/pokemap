import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class CloudNineEffect extends BattleAbilityEffect {
  const CloudNineEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'cloud_nine', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CloudNineEffect(scope: scope);
  }

  @override
  bool get suppressesWeatherEffects => true;
}
