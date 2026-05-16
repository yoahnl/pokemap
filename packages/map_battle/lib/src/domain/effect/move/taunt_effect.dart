import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class TauntEffect extends BattleEffect {
  const TauntEffect({
    required BattleEffectScope scope,
    int remainingTurns = 3,
  }) : super(
          id: 'taunt',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TauntEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_prevents(user: context.user, move: context.move)) {
      return null;
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveSelectionPreventionResult? onMoveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    if (!_prevents(user: context.user, move: context.move)) {
      return null;
    }

    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _prevents({
    required PsdkBattleSlotRef user,
    required BattleMoveDefinition move,
  }) {
    return _appliesTo(user) && move.category == PsdkBattleMoveCategory.status;
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
