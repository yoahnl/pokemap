import '../../psdk/domain/psdk_battle_slots.dart';
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
  });

  final BattleMoveBehaviorContext context;
  final BattleTimelineBuilder timeline;
  final BattlePositionRef user;
  final BattleMoveDefinition move;
  final BattlePositionRef? requestedTarget;
  List<BattlePositionRef> actualTargets = <BattlePositionRef>[];

  int get turn => context.turn;

  PsdkBattleSlotRef get psdkUser {
    return PsdkBattleSlotRef(bank: user.bank, position: user.position);
  }
}
