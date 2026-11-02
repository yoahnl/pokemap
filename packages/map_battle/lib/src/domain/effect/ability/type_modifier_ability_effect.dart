import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class AdaptabilityEffect extends BattleAbilityEffect {
  const AdaptabilityEffect({required BattleEffectScope scope})
      : super(abilityId: 'adaptability', scope: scope);

  @override
  double get sameTypeAttackMultiplier => 2;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) =>
      AdaptabilityEffect(scope: scope);
}

final class ScrappyEffect extends BattleAbilityEffect {
  const ScrappyEffect({required BattleEffectScope scope})
      : super(abilityId: 'scrappy', scope: scope);

  @override
  bool get ignoresGhostTypeImmunity => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) =>
      ScrappyEffect(scope: scope);
}

final class EarlyBirdEffect extends BattleAbilityEffect {
  const EarlyBirdEffect({required BattleEffectScope scope})
      : super(abilityId: 'early_bird', scope: scope);

  @override
  int get sleepTurnProgress => 2;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) =>
      EarlyBirdEffect(scope: scope);
}
