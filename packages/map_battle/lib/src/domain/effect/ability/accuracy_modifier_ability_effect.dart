import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityAccuracyCondition {
  user,
  userPhysicalMove,
  targetSandstorm,
  targetSnowing,
  targetStatusMove,
  targetConfused,
  allyBank,
}

final class AccuracyModifierAbilityEffect extends BattleAbilityEffect {
  const AccuracyModifierAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.condition,
    required this.multiplier,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityAccuracyCondition condition;
  final double multiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AccuracyModifierAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      condition: condition,
      multiplier: multiplier,
    );
  }

  @override
  double chanceOfHitMultiplier(BattleAbilityMoveContext context) {
    final owner = this.owner;
    if (owner == null) {
      return 1;
    }
    return switch (condition) {
      AbilityAccuracyCondition.user => owner == context.user ? multiplier : 1,
      AbilityAccuracyCondition.userPhysicalMove => owner == context.user &&
              context.move.category == PsdkBattleMoveCategory.physical
          ? multiplier
          : 1,
      AbilityAccuracyCondition.targetSandstorm => owner == context.target &&
              !_weatherEffectsSuppressed(context) &&
              context.state.field.isWeatherActive(
                PsdkBattleWeatherId.sandstorm,
              )
          ? multiplier
          : 1,
      AbilityAccuracyCondition.targetSnowing => owner == context.target &&
              !_weatherEffectsSuppressed(context) &&
              (context.state.field.isWeatherActive(PsdkBattleWeatherId.hail) ||
                  context.state.field.isWeatherActive(PsdkBattleWeatherId.snow))
          ? multiplier
          : 1,
      AbilityAccuracyCondition.targetStatusMove => owner == context.target &&
              context.move.category == PsdkBattleMoveCategory.status
          ? multiplier
          : 1,
      AbilityAccuracyCondition.targetConfused => owner == context.target &&
              context.state
                  .battlerAt(context.target)
                  .effects
                  .contains(PsdkBattleEffectIds.confusion)
          ? multiplier
          : 1,
      AbilityAccuracyCondition.allyBank =>
        owner.bank == context.user.bank ? multiplier : 1,
    };
  }

  bool _weatherEffectsSuppressed(BattleAbilityMoveContext context) {
    return context.state.activeAbilityEffects().any(
          (effect) => effect.suppressesWeatherEffects,
        );
  }
}

final class HustleAbilityEffect extends BattleAbilityEffect {
  const HustleAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'hustle', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return HustleAbilityEffect(scope: scope);
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    return context.battler.abilityId == abilityId && context.stat == 'attack'
        ? 1.5
        : 1;
  }

  @override
  double chanceOfHitMultiplier(BattleAbilityMoveContext context) {
    return owner == context.user &&
            context.move.category == PsdkBattleMoveCategory.physical
        ? 0.8
        : 1;
  }
}
