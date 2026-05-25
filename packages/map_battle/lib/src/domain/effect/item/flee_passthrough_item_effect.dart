import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class SmokeBallEffect extends BattleItemEffect {
  const SmokeBallEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'smoke_ball', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  bool fleePassthrough({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
  }) {
    return isOwnedBy(user) && !state.battlerAt(user).isFainted;
  }
}
