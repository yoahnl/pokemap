import '../domain/battle/battle_context.dart';
import '../domain/battle/battle_outcome.dart';
import '../domain/battle/battle_slot.dart';
import '../domain/decision/battle_decision.dart';
import '../domain/move/battle_move_data.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/timeline/battle_timeline.dart';
import '../domain/timeline/battle_timeline_builder.dart';
import '../domain/timeline/battle_timeline_event.dart';
import '../psdk/application/psdk_battle_move_behavior.dart';
import '../psdk/domain/psdk_battle_move.dart';
import '../psdk/domain/psdk_battle_slots.dart';

/// Result of submitting one decision to [BattleTurnRunner].
final class BattleEngineTurnResult {
  const BattleEngineTurnResult({
    required this.state,
    required this.timeline,
    required this.outcome,
    required this.nextRequest,
  });

  final BattlePublicState state;
  final BattleTimeline timeline;
  final BattleEngineOutcome? outcome;
  final BattleEngineDecisionRequest? nextRequest;
}

/// Executes exactly one PSDK-style singles turn against a mutable context.
///
/// Lot 4 intentionally keeps this runner small and explicit. It is the seam
/// where later PSDK actions, handlers and effects will replace the temporary
/// action construction below without changing the public [BattleEngine] API.
final class BattleTurnRunner {
  BattleTurnRunner(
    this._context, {
    required PsdkBattleMoveBehaviorRegistry moveBehaviorRegistry,
    BattleMoveProcedureHooks moveProcedureHooks = BattleMoveProcedureHooks.none,
  })  : _moveBehaviorRegistry = moveBehaviorRegistry,
        _moveProcedureHooks = moveProcedureHooks;

  final BattleContext _context;
  final PsdkBattleMoveBehaviorRegistry _moveBehaviorRegistry;
  final BattleMoveProcedureHooks _moveProcedureHooks;

  BattleEngineTurnResult run(BattleDecision playerDecision) {
    if (!_context.canBattleContinue) {
      return BattleEngineTurnResult(
        state: BattlePublicState.fromContext(_context),
        timeline: BattleTimeline.empty(),
        outcome: BattlePublicState.fromContext(_context).outcome,
        nextRequest: null,
      );
    }

    final previousState = _context.state;
    final previousRng = _context.rng;
    final previousTurnNumber = _context.turnNumber;

    final playerAction = _buildAction(
      user: psdkPlayerSlot,
      decision: playerDecision,
    );
    final opponentAction = _buildAction(
      user: psdkOpponentSlot,
      decision: const BattleDecision.fight(moveSlot: 0),
    );
    final actions = <_BattleResolvedAction>[playerAction, opponentAction]
      ..sort(_compareActions);

    _context.beginTurn();
    final timeline = BattleTimelineBuilder()
      ..add(BattleTurnStartedTimelineEvent(turn: _context.turnNumber));

    try {
      for (var actionIndex = 0; actionIndex < actions.length; actionIndex++) {
        final action = actions[actionIndex];
        if (!_context.canBattleContinue) {
          break;
        }

        final user = _context.state.battlerAt(action.user);
        final target = _context.state.battlerAt(action.target);
        if (user.isFainted || target.isFainted) {
          continue;
        }

        final moveBeforePp = user.moves[action.moveSlot];
        final historyTargets = <PsdkBattleSlotRef>[action.target];
        final cleanMoveBeforePp = BattleMoveDefinition.fromPsdk(moveBeforePp);
        final userPrevention = _moveProcedureHooks.preventUser(
              BattleMoveUserPreventionContext(
                state: _context.state,
                rng: _context.rng,
                turn: _context.turnNumber,
                user: _fromPsdkSlot(action.user),
                target: _fromPsdkSlot(action.target),
                move: cleanMoveBeforePp,
              ),
            ) ??
            _moveBehaviorRegistry.preventUser(
              method: moveBeforePp.battleEngineMethod,
              context: PsdkBattleMoveContext(
                state: _context.state,
                rng: _context.rng,
                turn: _context.turnNumber,
                user: action.user,
                target: action.target,
                move: moveBeforePp,
                isLastActionOfTurn: !_hasRunnableActionAfter(
                  actions,
                  actionIndex,
                ),
                moveProcedureHooks: _moveProcedureHooks,
              ),
            );
        if (userPrevention != null) {
          _recordMoveAttempt(
            user: action.user,
            moveId: moveBeforePp.id,
            targets: historyTargets,
          );
          timeline.add(
            BattleMoveFailedTimelineEvent(
              turn: _context.turnNumber,
              user: _fromPsdkSlot(action.user),
              target: _fromPsdkSlot(action.target),
              moveId: moveBeforePp.id,
              reason: userPrevention.reason.jsonName,
            ),
          );
          _notifyMoveFailure(
            user: action.user,
            target: action.target,
            move: cleanMoveBeforePp,
            reason: userPrevention.reason,
          );
          continue;
        }

        if (!moveBeforePp.hasUsablePp) {
          _recordMoveAttempt(
            user: action.user,
            moveId: moveBeforePp.id,
            targets: historyTargets,
          );
          timeline.add(
            BattleMoveFailedTimelineEvent(
              turn: _context.turnNumber,
              user: _fromPsdkSlot(action.user),
              target: _fromPsdkSlot(action.target),
              moveId: moveBeforePp.id,
              reason: BattleMoveFailureReason.pp.jsonName,
            ),
          );
          _notifyMoveFailure(
            user: action.user,
            target: action.target,
            move: cleanMoveBeforePp,
            reason: BattleMoveFailureReason.pp,
          );
          continue;
        }

        final moveAfterPp = moveBeforePp.spendPp();
        _context.applyStateAndRng(
          nextState: _context.state.updateBattler(
            action.user,
            (battler) => battler.replaceMoveAt(action.moveSlot, moveAfterPp),
          ),
          nextRng: _context.rng,
        );
        timeline.add(
          BattleMovePpSpentTimelineEvent(
            turn: _context.turnNumber,
            user: _fromPsdkSlot(action.user),
            moveId: moveAfterPp.id,
            spent: moveBeforePp.currentPp - moveAfterPp.currentPp,
            remainingPp: moveAfterPp.currentPp,
          ),
        );

        final resolution = _moveBehaviorRegistry.resolve(
          method: moveAfterPp.battleEngineMethod,
          context: PsdkBattleMoveContext(
            state: _context.state,
            rng: _context.rng,
            turn: _context.turnNumber,
            user: action.user,
            target: action.target,
            move: moveAfterPp,
            isLastActionOfTurn: !_hasRunnableActionAfter(
              actions,
              actionIndex,
            ),
            moveProcedureHooks: _moveProcedureHooks,
          ),
        );
        _context.applyStateAndRng(
          nextState: resolution.state,
          nextRng: resolution.rng,
        );
        timeline.addPsdkAll(resolution.events);
        _recordMoveAttempt(
          user: action.user,
          moveId: moveAfterPp.id,
          targets: historyTargets,
        );
        if (resolution.successful) {
          _recordMoveSuccess(
            user: action.user,
            moveId: moveAfterPp.id,
            targets: historyTargets,
          );
        }

        final outcome = _context.resolveOutcome();
        if (outcome != null) {
          _context.finish(outcome);
          timeline.add(BattleEndedTimelineEvent(outcome: outcome));
          break;
        }
      }
    } catch (_) {
      // Lot 4 keeps turn submission atomic from the public engine boundary.
      // Unknown PSDK handlers must fail loudly, but they must not leave behind
      // a half-advanced turn number, RNG stream, or partially mutated state.
      _context.restore(
        state: previousState,
        rng: previousRng,
        turnNumber: previousTurnNumber,
      );
      rethrow;
    }

    _clearTurnScopedEffects();
    final publicState = BattlePublicState.fromContext(_context);
    return BattleEngineTurnResult(
      state: publicState,
      timeline: timeline.build(),
      outcome: publicState.outcome,
      nextRequest: publicState.isFinished
          ? null
          : BattleEngineDecisionRequest.fromContext(_context),
    );
  }

  void _clearTurnScopedEffects() {
    var nextState = _context.state;
    var changed = false;
    for (final entry in _context.state.combatants.entries) {
      final battler = entry.value;
      final clearedEffects = battler.effects.clearTurnScopedEffects();
      if (identical(clearedEffects, battler.effects)) {
        continue;
      }
      // Protect is intentionally the only turn-scoped PSDK effect in Lot 14.
      // Clearing it here mirrors the legacy BE8 end-of-turn cleanup while still
      // letting slower actions in this same turn observe the effect.
      nextState = nextState.replaceBattler(
        entry.key,
        battler.copyWith(effects: clearedEffects),
      );
      changed = true;
    }
    if (changed) {
      _context.applyStateAndRng(
        nextState: nextState,
        nextRng: _context.rng,
      );
    }
  }

  bool _hasRunnableActionAfter(
    List<_BattleResolvedAction> actions,
    int actionIndex,
  ) {
    for (var index = actionIndex + 1; index < actions.length; index++) {
      final action = actions[index];
      final user = _context.state.battlerAt(action.user);
      final target = _context.state.battlerAt(action.target);
      if (!user.isFainted && !target.isFainted) {
        return true;
      }
    }
    return false;
  }

  _BattleResolvedAction _buildAction({
    required PsdkBattleSlotRef user,
    required BattleDecision decision,
  }) {
    return switch (decision) {
      BattleFightDecision(:final moveSlot) => _buildFightAction(
          user: user,
          moveSlot: moveSlot,
        ),
    };
  }

  _BattleResolvedAction _buildFightAction({
    required PsdkBattleSlotRef user,
    required int moveSlot,
  }) {
    final battler = _context.state.battlerAt(user);
    if (moveSlot < 0 || moveSlot >= battler.moves.length) {
      throw RangeError.range(
        moveSlot,
        0,
        battler.moves.length - 1,
        'moveSlot',
      );
    }
    final move = battler.moves[moveSlot];
    return _BattleResolvedAction(
      moveSlot: moveSlot,
      user: user,
      target: _targetFor(user: user, move: move),
      move: move,
      speed: battler.stats.speed,
    );
  }

  void _recordMoveAttempt({
    required PsdkBattleSlotRef user,
    required String moveId,
    required List<PsdkBattleSlotRef> targets,
  }) {
    _context.applyStateAndRng(
      nextState: _context.state.updateBattler(
        user,
        (battler) => battler.recordMoveAttempt(
          moveId: moveId,
          turn: _context.turnNumber,
          targets: targets,
        ),
      ),
      nextRng: _context.rng,
    );
  }

  void _recordMoveSuccess({
    required PsdkBattleSlotRef user,
    required String moveId,
    required List<PsdkBattleSlotRef> targets,
  }) {
    _context.applyStateAndRng(
      nextState: _context.state.updateBattler(
        user,
        (battler) => battler.recordMoveSuccess(
          moveId: moveId,
          turn: _context.turnNumber,
          targets: targets,
        ),
      ),
      nextRng: _context.rng,
    );
  }

  void _notifyMoveFailure({
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required BattleMoveFailureReason reason,
  }) {
    _moveProcedureHooks.notifyFailure(
      BattleMoveFailureContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: _fromPsdkSlot(user),
        target: _fromPsdkSlot(target),
        move: move,
        reason: reason,
        targets: <BattlePositionRef>[_fromPsdkSlot(target)],
      ),
    );
  }
}

BattlePositionRef _fromPsdkSlot(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}

PsdkBattleSlotRef _targetFor({
  required PsdkBattleSlotRef user,
  required PsdkBattleMoveData move,
}) {
  return switch (move.target) {
    PsdkBattleMoveTarget.user => user,
    PsdkBattleMoveTarget.adjacentFoe => psdkSinglesFoeOf(user),
  };
}

int _compareActions(_BattleResolvedAction left, _BattleResolvedAction right) {
  final priority = right.move.priority.compareTo(left.move.priority);
  if (priority != 0) {
    return priority;
  }
  final speed = right.speed.compareTo(left.speed);
  if (speed != 0) {
    return speed;
  }
  return left.user.bank.compareTo(right.user.bank);
}

final class _BattleResolvedAction {
  const _BattleResolvedAction({
    required this.moveSlot,
    required this.user,
    required this.target,
    required this.move,
    required this.speed,
  });

  final int moveSlot;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final PsdkBattleMoveData move;
  final int speed;
}
