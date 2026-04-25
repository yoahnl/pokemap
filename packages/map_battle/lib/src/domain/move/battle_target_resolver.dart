import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_slot.dart';
import 'battle_move_execution.dart';

final class BattleTargetResolver {
  const BattleTargetResolver();

  List<BattlePositionRef> resolve(BattleMoveProcedureExecution execution) {
    final requested = execution.requestedTarget;
    final targets = switch (execution.move.target) {
      PsdkBattleMoveTarget.user => <BattlePositionRef>[execution.user],
      PsdkBattleMoveTarget.adjacentFoe => <BattlePositionRef>[
          requested ?? _foeOf(execution.user),
        ],
    };

    return targets.where((target) {
      final battler = execution.context.state.combatants[PsdkBattleSlotRef(
        bank: target.bank,
        position: target.position,
      )];
      return battler != null && !battler.isFainted;
    }).toList(growable: false);
  }
}

BattlePositionRef _foeOf(BattlePositionRef user) {
  return BattlePositionRef(
    bank: user.bank == 0 ? 1 : 0,
    position: user.position,
  );
}
