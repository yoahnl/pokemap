import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class BigRootEffect extends BattleItemEffect {
  const BigRootEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'big_root', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BigRootEffect(scope: scope);
  }

  @override
  double drainHealMultiplier(BattleItemDrainModifierContext context) {
    return _canApplyTo(context.user, itemId) ? 1.3 : 1;
  }
}

final class BindingBandEffect extends BattleItemEffect {
  const BindingBandEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'binding_band', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BindingBandEffect(scope: scope);
  }

  @override
  int? bindResidualDamageDivisor(BattleItemBindResidualContext context) {
    return _canApplyTo(context.origin, itemId) ? 6 : null;
  }
}

final class GripClawEffect extends BattleItemEffect {
  const GripClawEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'grip_claw', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GripClawEffect(scope: scope);
  }

  @override
  int? bindDuration(BattleItemBindDurationContext context) {
    return _canApplyTo(context.user, itemId) ? 7 : null;
  }
}

bool _canApplyTo(PsdkBattleCombatant battler, String itemId) {
  return battler.heldItemId == itemId &&
      !battler.itemConsumed &&
      !battler.itemEffectsSuppressed;
}
