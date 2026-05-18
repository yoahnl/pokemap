import '../../psdk/domain/psdk_battle_combatant.dart';
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
      PsdkBattleMoveTarget.adjacentFoe => _redirectedOrOriginal(
          execution: execution,
          user: user,
          candidates: state.adjacentFoesOf(user),
          targets: _requestedOrFirst(
            requested: requestedSlot,
            candidates: state.adjacentFoesOf(user),
            fallback: psdkSinglesFoeOf(user),
          ),
        ),
      PsdkBattleMoveTarget.anyFoe => _redirectedOrOriginal(
          execution: execution,
          user: user,
          candidates: state.foesOf(user),
          targets: _requestedOrFirst(
            requested: requestedSlot,
            candidates: state.foesOf(user),
          ),
        ),
      PsdkBattleMoveTarget.adjacentAlly => _requestedOrFirst(
          requested: requestedSlot,
          candidates: state.alliesOf(user),
        ),
      PsdkBattleMoveTarget.adjacentAllyOrSelf => _requestedOrFirst(
          requested: requestedSlot,
          candidates: <PsdkBattleSlotRef>[
            user,
            ...state.adjacentAlliesOf(user),
          ],
          fallback: user,
        ),
      PsdkBattleMoveTarget.allAdjacent => state.adjacentSlotsOf(user),
      PsdkBattleMoveTarget.allAdjacentFoes => state.adjacentFoesOf(user),
      PsdkBattleMoveTarget.allFoes => state.foesOf(user),
      PsdkBattleMoveTarget.allBattlers => state.aliveSlots(),
      PsdkBattleMoveTarget.allAllies => state.alliesOf(user),
      PsdkBattleMoveTarget.bank ||
      PsdkBattleMoveTarget.userSide ||
      PsdkBattleMoveTarget.foeSide ||
      PsdkBattleMoveTarget.none =>
        const <PsdkBattleSlotRef>[],
      PsdkBattleMoveTarget.randomFoe => _redirectedOrOriginal(
          execution: execution,
          user: user,
          candidates: state.foesOf(user),
          targets: _randomOne(
            execution: execution,
            candidates: state.foesOf(user),
            fallback: psdkSinglesFoeOf(user),
          ),
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

List<PsdkBattleSlotRef> _redirectedOrOriginal({
  required BattleMoveProcedureExecution execution,
  required PsdkBattleSlotRef user,
  required List<PsdkBattleSlotRef> candidates,
  required List<PsdkBattleSlotRef> targets,
}) {
  if (targets.isEmpty || !_canRedirect(execution)) {
    return targets;
  }
  for (final candidate in candidates) {
    final battler = execution.context.state.combatants[candidate];
    if (battler == null || battler.isFainted) {
      continue;
    }
    if (candidate.bank == user.bank ||
        !battler.effects.contains(PsdkBattleEffectIds.centerOfAttention) ||
        battler.effects.contains(PsdkBattleEffectIds.preventTargetsMove)) {
      continue;
    }
    return <PsdkBattleSlotRef>[candidate];
  }
  return targets;
}

bool _canRedirect(BattleMoveProcedureExecution execution) {
  final move = execution.move;
  if (move.id == 'snipe_shot' || move.dbSymbol == 'snipe_shot') {
    return false;
  }
  final user = execution.context.state.battlerAt(
    PsdkBattleSlotRef(
      bank: execution.user.bank,
      position: execution.user.position,
    ),
  );
  return user.abilityId != 'stalwart' && user.abilityId != 'propeller_tail';
}

List<PsdkBattleSlotRef> _randomOne({
  required BattleMoveProcedureExecution execution,
  required List<PsdkBattleSlotRef> candidates,
  PsdkBattleSlotRef? fallback,
}) {
  final resolvedCandidates = candidates.isEmpty && fallback != null
      ? <PsdkBattleSlotRef>[fallback]
      : candidates;
  if (resolvedCandidates.isEmpty) {
    return const <PsdkBattleSlotRef>[];
  }
  final roll = execution.context.rng.generic.nextIntInclusive(
    min: 0,
    max: resolvedCandidates.length - 1,
  );
  return <PsdkBattleSlotRef>[resolvedCandidates[roll.value]];
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
