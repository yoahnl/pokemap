import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class TormentEffect extends BattleEffect {
  const TormentEffect({
    required BattleEffectScope scope,
    int remainingTurns = 3,
  }) : super(
          id: 'torment',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TormentEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_prevents(
      state: context.state,
      user: context.user,
      moveId: context.move.id,
    )) {
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
    if (!_prevents(
      state: context.state,
      user: context.user,
      moveId: context.move.id,
    )) {
      return null;
    }

    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _prevents({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required String moveId,
  }) {
    if (!_appliesTo(user) || moveId == 'struggle') {
      return false;
    }
    final lastSuccessful =
        state.battlerAt(user).moveHistory.lastSuccessfulMoveId;
    return lastSuccessful == moveId;
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
