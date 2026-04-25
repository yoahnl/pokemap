import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_slot.dart';
import 'battle_move_execution.dart';

final class BattleTargetResolver {
  const BattleTargetResolver();

  List<BattlePositionRef> resolve(BattleMoveProcedureExecution execution) {
    final requested = execution.requestedTarget;
    final user = PsdkBattleSlotRef(
      bank: execution.user.bank,
      position: execution.user.position,
    );
    final requestedSlot = requested == null
        ? null
        : PsdkBattleSlotRef(
            bank: requested.bank,
            position: requested.position,
          );
    final state = execution.context.state;
    final targets = switch (execution.move.target) {
      PsdkBattleMoveTarget.self ||
      PsdkBattleMoveTarget.user =>
        <PsdkBattleSlotRef>[user],
      PsdkBattleMoveTarget.adjacentFoe => _requestedOrFirst(
          requested: requestedSlot,
          candidates: state.foesOf(user),
          fallback: psdkSinglesFoeOf(user),
        ),
      PsdkBattleMoveTarget.anyFoe => _requestedOrFirst(
          requested: requestedSlot,
          candidates: state.foesOf(user),
        ),
      PsdkBattleMoveTarget.adjacentAlly => _requestedOrFirst(
          requested: requestedSlot,
          candidates: state.alliesOf(user),
        ),
      PsdkBattleMoveTarget.adjacentAllyOrSelf => _requestedOrFirst(
          requested: requestedSlot,
          candidates: <PsdkBattleSlotRef>[user, ...state.alliesOf(user)],
          fallback: user,
        ),
      PsdkBattleMoveTarget.allAdjacent => state
          .aliveSlots()
          .where((slot) => slot != user)
          .toList(growable: false),
      PsdkBattleMoveTarget.allAdjacentFoes ||
      PsdkBattleMoveTarget.allFoes =>
        state.foesOf(user),
      PsdkBattleMoveTarget.allBattlers => state.aliveSlots(),
      PsdkBattleMoveTarget.allAllies => state.alliesOf(user),
      PsdkBattleMoveTarget.bank ||
      PsdkBattleMoveTarget.userSide ||
      PsdkBattleMoveTarget.foeSide ||
      PsdkBattleMoveTarget.none =>
        const <PsdkBattleSlotRef>[],
      PsdkBattleMoveTarget.randomFoe => throw UnsupportedError(
          'randomFoe targeting needs RNG-threaded target resolution.',
        ),
    };

    return targets
        .where((target) {
          final battler = state.combatants[target];
          return battler != null && !battler.isFainted;
        })
        .map((slot) =>
            BattlePositionRef(bank: slot.bank, position: slot.position))
        .toList(growable: false);
  }
}

List<PsdkBattleSlotRef> _requestedOrFirst({
  required PsdkBattleSlotRef? requested,
  required List<PsdkBattleSlotRef> candidates,
  PsdkBattleSlotRef? fallback,
}) {
  if (requested != null) {
    return candidates.contains(requested)
        ? <PsdkBattleSlotRef>[requested]
        : const <PsdkBattleSlotRef>[];
  }
  if (candidates.isNotEmpty) {
    return <PsdkBattleSlotRef>[candidates.first];
  }
  return fallback == null
      ? const <PsdkBattleSlotRef>[]
      : <PsdkBattleSlotRef>[fallback];
}
