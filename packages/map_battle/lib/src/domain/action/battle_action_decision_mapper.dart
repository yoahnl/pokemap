import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';
import '../decision/battle_decision.dart';
import 'battle_action.dart';

final class PsdkBattleActionDecisionMapper {
  const PsdkBattleActionDecisionMapper();

  PsdkBattleAction map({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required BattleDecision decision,
  }) {
    return switch (decision) {
      BattleFightDecision(:final moveSlot, :final target) => _fight(
          state: state,
          user: user,
          moveSlot: moveSlot,
          requestedTarget: target,
        ),
      BattleSwitchDecision(:final partyIndex) => PsdkBattleSwitchAction(
          user: user,
          partyIndex: partyIndex,
        ),
    };
  }

  PsdkBattleFightAction _fight({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required int moveSlot,
    required PsdkBattleSlotRef? requestedTarget,
  }) {
    final battler = state.battlerAt(user);
    if (moveSlot < 0 || moveSlot >= battler.moves.length) {
      throw RangeError.range(
        moveSlot,
        0,
        battler.moves.length - 1,
        'moveSlot',
      );
    }
    final move = battler.moves[moveSlot];
    return PsdkBattleFightAction(
      user: user,
      target: requestedTarget ?? _targetFor(user: user, move: move),
      moveSlot: moveSlot,
      move: move,
      speed: _actionSpeed(battler),
    );
  }
}

int _actionSpeed(PsdkBattleCombatant battler) {
  final speed = battler.stats.speed < 1 ? 1 : battler.stats.speed;
  if (battler.majorStatus != PsdkBattleMajorStatus.paralysis ||
      battler.abilityId == 'quick_feet') {
    return speed;
  }
  final paralyzedSpeed = (speed * 0.25).floor();
  return paralyzedSpeed < 1 ? 1 : paralyzedSpeed;
}

PsdkBattleSlotRef _targetFor({
  required PsdkBattleSlotRef user,
  required PsdkBattleMoveData move,
}) {
  return switch (move.target) {
    PsdkBattleMoveTarget.user || PsdkBattleMoveTarget.self => user,
    PsdkBattleMoveTarget.adjacentFoe ||
    PsdkBattleMoveTarget.anyFoe =>
      psdkSinglesFoeOf(user),
    PsdkBattleMoveTarget.bank ||
    PsdkBattleMoveTarget.userSide ||
    PsdkBattleMoveTarget.foeSide ||
    PsdkBattleMoveTarget.none =>
      user,
    PsdkBattleMoveTarget.adjacentAlly ||
    PsdkBattleMoveTarget.adjacentAllyOrSelf ||
    PsdkBattleMoveTarget.allAdjacent ||
    PsdkBattleMoveTarget.allAdjacentFoes ||
    PsdkBattleMoveTarget.allBattlers ||
    PsdkBattleMoveTarget.allFoes ||
    PsdkBattleMoveTarget.allAllies ||
    PsdkBattleMoveTarget.randomFoe =>
      throw UnsupportedError(
        'PSDK target ${move.target.name} needs multi-target action support.',
      ),
  };
}
