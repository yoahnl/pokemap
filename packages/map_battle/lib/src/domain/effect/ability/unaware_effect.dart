import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class UnawareEffect extends BattleAbilityEffect {
  const UnawareEffect({required BattleEffectScope scope})
      : super(abilityId: 'unaware', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return UnawareEffect(scope: scope);
  }

  @override
  bool ignoresOffensiveStatStages(BattleAbilityDamageContext context) {
    if (context.criticalHit) {
      return false;
    }
    final owner = this.owner;
    return owner != null && owner == context.targetSlot;
  }

  @override
  bool ignoresDefensiveStatStages(BattleAbilityDamageContext context) {
    if (context.criticalHit) {
      return false;
    }
    final owner = this.owner;
    return owner != null && owner == context.userSlot;
  }

  @override
  double chanceOfHitMultiplier(BattleAbilityMoveContext context) {
    final owner = this.owner;
    if (owner == null) {
      return 1;
    }
    if (owner == context.target) {
      final user = context.state.battlerAt(context.user);
      return _inverseStageMultiplier(user.statStages.valueOf('accuracy'));
    }
    if (owner == context.user) {
      final target = context.state.battlerAt(context.target);
      return _inverseStageMultiplier(-target.statStages.valueOf('evasion'));
    }
    return 1;
  }
}

double _inverseStageMultiplier(int stage) {
  final multiplier = _accuracyStageMultiplier(stage);
  return multiplier == 0 ? 1 : 1 / multiplier;
}

double _accuracyStageMultiplier(int stage) {
  final clamped = stage.clamp(-6, 6).toInt();
  if (clamped >= 0) {
    return (3 + clamped) / 3;
  }
  return 3 / (3 - clamped);
}

bool battlerHasActiveUnaware(PsdkBattleCombatant battler) {
  return battler.abilityEffects.any((effect) => effect is UnawareEffect);
}
