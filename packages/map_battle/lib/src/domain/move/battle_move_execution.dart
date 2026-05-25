import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../battle/battle_slot.dart';
import '../timeline/battle_timeline_builder.dart';
import 'battle_move_behavior.dart';
import 'battle_move_data.dart';

final class BattleMoveProcedureExecution {
  BattleMoveProcedureExecution({
    required this.context,
    required this.timeline,
    required this.user,
    required this.move,
    required this.requestedTarget,
  })  : actualUser = user,
        actualState = context.state;

  final BattleMoveBehaviorContext context;
  final BattleTimelineBuilder timeline;
  final BattlePositionRef user;
  final BattleMoveDefinition move;
  final BattlePositionRef? requestedTarget;

  /// Effective user after the PSDK remap stage.
  ///
  /// Most moves keep the original user. Effects such as Snatch can steal a
  /// move after accuracy, so FIGHT-11 keeps this mutable execution-local value
  /// beside [actualTargets] instead of rewriting the selected action.
  BattlePositionRef actualUser;

  PsdkBattleState actualState;

  List<BattlePositionRef> actualTargets = <BattlePositionRef>[];

  int get turn => context.turn;

  PsdkBattleSlotRef get psdkUser {
    return PsdkBattleSlotRef(bank: user.bank, position: user.position);
  }

  PsdkBattleSlotRef get psdkActualUser {
    return PsdkBattleSlotRef(
      bank: actualUser.bank,
      position: actualUser.position,
    );
  }
}
