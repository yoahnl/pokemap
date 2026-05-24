import '../../../psdk/domain/psdk_battle_move.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class SereneGraceEffect extends BattleAbilityEffect {
  const SereneGraceEffect({required BattleEffectScope scope})
      : super(abilityId: 'serene_grace', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SereneGraceEffect(scope: scope);
  }

  @override
  double secondaryEffectChanceMultiplier(
    BattleAbilitySecondaryEffectContext context,
  ) {
    return isOwnedBy(context.user) ? 2 : 1;
  }
}

final class ShieldDustEffect extends BattleAbilityEffect {
  const ShieldDustEffect({required BattleEffectScope scope})
      : super(abilityId: 'shield_dust', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ShieldDustEffect(scope: scope);
  }

  @override
  bool preventsSecondaryEffects(
    BattleAbilitySecondaryEffectContext context,
  ) {
    return isOwnedBy(context.target) &&
        context.user != context.target &&
        context.move.category != PsdkBattleMoveCategory.status;
  }
}

final class SheerForceEffect extends BattleAbilityEffect {
  const SheerForceEffect({required BattleEffectScope scope})
      : super(abilityId: 'sheer_force', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SheerForceEffect(scope: scope);
  }

  @override
  bool preventsSecondaryEffects(
    BattleAbilitySecondaryEffectContext context,
  ) {
    return isOwnedBy(context.user) && _canBoost(context.move);
  }
}

bool _canBoost(BattleMoveDefinition move) {
  if (move.category == PsdkBattleMoveCategory.status) {
    return false;
  }

  if (move.statuses.any(
    (status) => status.majorStatus != null || status.volatileStatus != null,
  )) {
    return true;
  }

  if (move.effectChance != null) {
    return true;
  }

  if (move.stageMods.isEmpty) {
    return false;
  }

  final onlyPositive = move.stageMods.every((mod) => mod.stages > 0);
  final onlyNegative = move.stageMods.every((mod) => mod.stages < 0);
  return switch (move.target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => onlyPositive,
    _ => onlyNegative,
  };
}
