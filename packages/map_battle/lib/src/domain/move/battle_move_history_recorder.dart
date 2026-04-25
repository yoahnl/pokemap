import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';

/// Centralizes the PSDK move-history mutations used by the turn runner.
///
/// Pokemon SDK records both "attempted" and "successful" move histories at the
/// end of the move procedure. Dart still executes the body through move
/// behaviors, so this small recorder keeps the state mutation explicit while
/// avoiding duplicated history writes in every early-failure branch.
final class BattleMoveHistoryRecorder {
  const BattleMoveHistoryRecorder();

  PsdkBattleState recordAttempt({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required String moveId,
    required int turn,
    required List<PsdkBattleSlotRef> targets,
  }) {
    return state.updateBattler(
      user,
      (battler) => battler.recordMoveAttempt(
        moveId: moveId,
        turn: turn,
        targets: targets,
      ),
    );
  }

  PsdkBattleState recordSuccess({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required String moveId,
    required int turn,
    required List<PsdkBattleSlotRef> targets,
  }) {
    return state.updateBattler(
      user,
      (battler) => battler.recordMoveSuccess(
        moveId: moveId,
        turn: turn,
        targets: targets,
      ),
    );
  }
}
