import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_prevention.dart';

/// Direct PSDK move execution request.
///
/// This is the clean seam future runtime adapters can use once they know the
/// PSDK `battleEngineMethod` and have Studio move metadata, without first
/// flattening everything into legacy `BattleMoveData`.
final class PsdkBattleMoveRequest {
  const PsdkBattleMoveRequest({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    required this.target,
    required this.moveId,
    required this.battleEngineMethod,
    required this.studioMove,
    this.canFlee = false,
    this.moveSlot,
    this.isLastActionOfTurn = false,
    this.moveProcedureHooks = BattleMoveProcedureHooks.none,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;
  final String battleEngineMethod;
  final PsdkBattleMoveData studioMove;
  final bool canFlee;
  final int? moveSlot;
  final bool isLastActionOfTurn;
  final BattleMoveProcedureHooks moveProcedureHooks;

  PsdkBattleMoveData get resolvedStudioMove {
    return studioMove.copyWith(
      id: moveId,
      battleEngineMethod: battleEngineMethod,
    );
  }
}
