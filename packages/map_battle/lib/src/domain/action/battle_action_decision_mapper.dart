import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../battler/battle_grounding_resolver.dart';
import '../decision/battle_decision.dart';
import '../effect/move/two_turn_charge_effect.dart';
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
    final twoTurnCharge = _twoTurnCharge(battler);
    final chargedMoveSlot =
        _chargedMoveSlot(battler: battler, charge: twoTurnCharge);
    final effectiveMoveSlot = chargedMoveSlot ?? moveSlot;
    if (effectiveMoveSlot < 0 || effectiveMoveSlot >= battler.moves.length) {
      throw RangeError.range(
        effectiveMoveSlot,
        0,
        battler.moves.length - 1,
        'moveSlot',
      );
    }
    final move = _effectiveActionMove(
      state: state,
      battler: battler,
      move: battler.moves[effectiveMoveSlot],
    );
    return PsdkBattleFightAction(
      user: user,
      target: chargedMoveSlot != null
          ? twoTurnCharge!.chargedTarget
          : requestedTarget ?? _targetFor(user: user, move: move),
      moveSlot: effectiveMoveSlot,
      move: move,
      speed: _actionSpeed(battler),
    );
  }
}

TwoTurnChargeEffect? _twoTurnCharge(PsdkBattleCombatant battler) {
  for (final effect in battler.effects.effects) {
    if (effect is TwoTurnChargeEffect) {
      return effect;
    }
  }
  return null;
}

int? _chargedMoveSlot({
  required PsdkBattleCombatant battler,
  required TwoTurnChargeEffect? charge,
}) {
  final chargedMoveId = charge?.chargedMoveId;
  if (chargedMoveId == null) {
    return null;
  }
  for (var index = 0; index < battler.moves.length; index++) {
    if (battler.moves[index].id == chargedMoveId) {
      return index;
    }
  }
  return null;
}

PsdkBattleMoveData _effectiveActionMove({
  required PsdkBattleState state,
  required PsdkBattleCombatant battler,
  required PsdkBattleMoveData move,
}) {
  if (move.battleEngineMethod != 's_grassy_glide' ||
      !state.field.isTerrainActive(PsdkBattleTerrainId.grassyTerrain) ||
      !const BattleGroundingResolver().isGrounded(battler) ||
      move.priority >= 14) {
    return move;
  }
  return _copyMoveWithPriority(move, move.priority + 1);
}

PsdkBattleMoveData _copyMoveWithPriority(
  PsdkBattleMoveData move,
  int priority,
) {
  return PsdkBattleMoveData(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: move.power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    protectable: move.protectable,
    statuses: move.statuses,
    stageMods: move.stageMods,
  );
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
    PsdkBattleMoveTarget.anyFoe ||
    PsdkBattleMoveTarget.allAdjacentFoes ||
    PsdkBattleMoveTarget.allFoes ||
    PsdkBattleMoveTarget.randomFoe =>
      psdkSinglesFoeOf(user),
    PsdkBattleMoveTarget.bank ||
    PsdkBattleMoveTarget.userSide ||
    PsdkBattleMoveTarget.foeSide ||
    PsdkBattleMoveTarget.allAllies ||
    PsdkBattleMoveTarget.allBattlers ||
    PsdkBattleMoveTarget.none =>
      user,
    PsdkBattleMoveTarget.adjacentAlly ||
    PsdkBattleMoveTarget.adjacentAllyOrSelf ||
    PsdkBattleMoveTarget.allAdjacent =>
      throw UnsupportedError(
        'PSDK target ${move.target.name} needs multi-target action support.',
      ),
  };
}
