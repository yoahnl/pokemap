import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class SkillLinkEffect extends BattleAbilityEffect {
  const SkillLinkEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'skill_link', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SkillLinkEffect(scope: scope);
  }

  @override
  int? forcedHitCount(BattleAbilityMoveContext context) {
    if (!isOwnedBy(context.user)) {
      return null;
    }
    return switch (context.move.battleEngineMethod) {
      's_multi_hit' || 's_water_shuriken' => 5,
      _ => null,
    };
  }

  @override
  bool bypassesMultiHitAccuracyRecheck(BattleAbilityMoveContext context) {
    if (!isOwnedBy(context.user)) {
      return false;
    }
    return switch (context.move.battleEngineMethod) {
      's_triple_kick' || 's_population_bomb' => true,
      _ => false,
    };
  }
}
