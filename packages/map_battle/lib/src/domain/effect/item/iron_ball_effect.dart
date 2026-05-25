import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class IronBallEffect extends BattleItemEffect {
  const IronBallEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'iron_ball', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return IronBallEffect(scope: scope);
  }

  @override
  bool? groundedOverride(PsdkBattleCombatant battler) {
    return _canApplyTo(battler) ? true : null;
  }

  @override
  double statMultiplier(PsdkBattleCombatant battler, String stat) {
    return _canApplyTo(battler) && stat == 'speed' ? 0.5 : 1;
  }

  bool _canApplyTo(PsdkBattleCombatant battler) {
    return battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed;
  }
}
