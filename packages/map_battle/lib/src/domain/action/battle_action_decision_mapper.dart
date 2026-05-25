import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../battler/battle_grounding_resolver.dart';
import '../decision/battle_decision.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/item/item_effect.dart';
import '../effect/move/bide_effect.dart';
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
      BattleItemDecision(
        :final itemId,
        :final target,
        :final effect,
        :final highPriority,
      ) =>
        PsdkBattleItemAction(
          user: user,
          itemId: itemId,
          target: target,
          effect: effect,
          highPriority: highPriority,
        ),
      BattleMegaDecision(:final form) => PsdkBattleMegaAction(
          user: user,
          form: form,
        ),
      BattleFleeDecision() => PsdkBattleFleeAction(user: user),
      BattleShiftDecision(:final target) => PsdkBattleShiftAction(
          user: user,
          target: target,
        ),
      BattleNoActionDecision() => PsdkBattleNoAction(user: user),
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
    final bide = _bide(battler);
    final chargedMoveSlot =
        _chargedMoveSlot(battler: battler, charge: twoTurnCharge);
    final bideMoveSlot = _bideMoveSlot(battler: battler, bide: bide);
    final forcedTarget = twoTurnCharge?.chargedTarget ?? bide?.chargedTarget;
    final effectiveMoveSlot = chargedMoveSlot ?? bideMoveSlot ?? moveSlot;
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
      user: user,
      battler: battler,
      move: battler.moves[effectiveMoveSlot],
    );
    return PsdkBattleFightAction(
      user: user,
      target:
          forcedTarget ?? requestedTarget ?? _targetFor(user: user, move: move),
      moveSlot: effectiveMoveSlot,
      move: move,
      speed: _actionSpeed(state: state, user: user, battler: battler),
    );
  }
}

BideEffect? _bide(PsdkBattleCombatant battler) {
  for (final effect in battler.effects.effects) {
    if (effect is BideEffect) {
      return effect;
    }
  }
  return null;
}

TwoTurnChargeEffect? _twoTurnCharge(PsdkBattleCombatant battler) {
  for (final effect in battler.effects.effects) {
    if (effect is TwoTurnChargeEffect) {
      return effect;
    }
  }
  return null;
}

int? _bideMoveSlot({
  required PsdkBattleCombatant battler,
  required BideEffect? bide,
}) {
  final forcedMoveId = bide?.forcedMoveId;
  if (forcedMoveId == null) {
    return null;
  }
  for (var index = 0; index < battler.moves.length; index++) {
    if (battler.moves[index].id == forcedMoveId) {
      return index;
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
  required PsdkBattleSlotRef user,
  required PsdkBattleCombatant battler,
  required PsdkBattleMoveData move,
}) {
  var nextMove = move;
  if (nextMove.battleEngineMethod == 's_grassy_glide' &&
      state.field.isTerrainActive(PsdkBattleTerrainId.grassyTerrain) &&
      const BattleGroundingResolver().isGrounded(battler) &&
      nextMove.priority < 14) {
    nextMove = _copyMoveWithPriority(nextMove, nextMove.priority + 1);
  }
  return _applyAbilityPriority(
    state: state,
    user: user,
    battler: battler,
    move: nextMove,
  );
}

PsdkBattleMoveData _applyAbilityPriority({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleCombatant battler,
  required PsdkBattleMoveData move,
}) {
  var priority = move.priority;
  for (final effect in battler.abilityEffects) {
    priority += effect.movePriorityModifier(
      BattleAbilityMovePriorityContext(
        state: state,
        user: user,
        battler: battler,
        move: move,
        currentPriority: priority,
      ),
    );
  }
  return priority == move.priority
      ? move
      : _copyMoveWithPriority(move, priority);
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
    contact: move.contact,
    protectable: move.protectable,
    sound: move.sound,
    bite: move.bite,
    pulse: move.pulse,
    wind: move.wind,
    ballistics: move.ballistics,
    kingRockUtility: move.kingRockUtility,
    heal: move.heal,
    statuses: move.statuses,
    stageMods: move.stageMods,
  );
}

int _actionSpeed({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleCombatant battler,
}) {
  var speed = _adjustedStat(
    state: state,
    battlerSlot: user,
    battler: battler,
    stat: 'speed',
    value: battler.stats.speed,
  );
  if (_bankHasEffect(state, user.bank, 'tailwind')) {
    speed *= 2;
  }
  if (_bankHasEffect(state, user.bank, 'pledge_swamp')) {
    speed = (speed * 0.25).floor().clamp(1, speed).toInt();
  }
  if (battler.majorStatus != PsdkBattleMajorStatus.paralysis ||
      battler.abilityId == 'quick_feet') {
    return speed;
  }
  final paralyzedSpeed = (speed * 0.25).floor();
  return paralyzedSpeed < 1 ? 1 : paralyzedSpeed;
}

int _adjustedStat({
  required PsdkBattleState state,
  required PsdkBattleSlotRef battlerSlot,
  required PsdkBattleCombatant battler,
  required String stat,
  required int value,
}) {
  var multiplier = 1.0;
  for (final effect in state.activeItemEffectsAt(battlerSlot)) {
    multiplier *= effect.statMultiplier(battler, stat);
  }
  final abilityContext = BattleAbilityStatContext(
    field: state.field,
    battler: battler,
    stat: stat,
    state: state,
    battlerSlot: battlerSlot,
    weatherEffectsSuppressed: state.weatherEffectsSuppressed,
  );
  for (final effect in battler.abilityEffects) {
    multiplier *= effect.statMultiplier(abilityContext);
  }
  for (final effect in state.activeAbilityEffects()) {
    if (effect.affectsGlobalStats && !effect.isOwnedBy(battlerSlot)) {
      multiplier *= effect.statMultiplier(abilityContext);
    }
  }
  final adjusted = (value * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

bool _bankHasEffect(PsdkBattleState state, int bank, String effectId) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any((effect) {
      if (effect.id != effectId) {
        return false;
      }
      final scope = effect.scope;
      if (scope is BankBattleEffectScope) {
        return scope.bank == bank;
      }
      if (scope is BattlerBattleEffectScope) {
        return scope.slot.bank == bank;
      }
      return false;
    }),
  );
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
