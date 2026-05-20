import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class MoldBreakerFamilyEffect extends BattleAbilityEffect {
  const MoldBreakerFamilyEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MoldBreakerFamilyEffect(abilityId: abilityId, scope: scope);
  }
}
