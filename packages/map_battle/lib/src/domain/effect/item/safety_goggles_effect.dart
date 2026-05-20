import '../../battle/battle_slot.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class SafetyGogglesEffect extends BattleItemEffect {
  const SafetyGogglesEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'safety_goggles', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SafetyGogglesEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!_isOwner(context.target) || !context.move.flags.powder) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  bool _isOwner(BattlePositionRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope ||
        (scope.slot.bank == target.bank &&
            scope.slot.position == target.position);
  }
}
