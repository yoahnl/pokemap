import '../domain/battle/battle_context.dart';
import '../domain/battle/battle_outcome.dart';
import '../domain/battle/battle_slot.dart';
import '../domain/action/battle_action.dart';
import '../domain/action/battle_action_decision_mapper.dart';
import '../domain/action/battle_item_action_handler.dart';
import '../domain/action/battle_mega_action_handler.dart';
import '../domain/action/battle_action_queue.dart';
import '../domain/decision/battle_decision.dart';
import '../domain/effect/ability/ability_effect.dart';
import '../domain/effect/battle_effect_hooks.dart';
import '../domain/effect/status/status_effect_registry.dart';
import '../domain/handler/battle_end_turn_handler.dart';
import '../domain/handler/battle_handler_context.dart';
import '../domain/handler/battle_handler_result.dart';
import '../domain/handler/battle_status_change_handler.dart';
import '../domain/handler/battle_switch_handler.dart';
import '../domain/move/battle_move_behavior.dart';
import '../domain/move/battle_move_data.dart';
import '../domain/move/battle_move_history_recorder.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/timeline/battle_timeline.dart';
import '../domain/timeline/battle_timeline_builder.dart';
import '../domain/timeline/battle_timeline_event.dart';
import '../psdk/application/psdk_battle_move_behavior.dart';
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
  static const BattleMoveHistoryRecorder _moveHistoryRecorder =
      BattleMoveHistoryRecorder();

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

    const actionMapper = PsdkBattleActionDecisionMapper();
    final actions = PsdkBattleActionQueue(
      actions: <PsdkBattleAction>[
        actionMapper.map(
          state: _context.state,
          user: psdkPlayerSlot,
          decision: playerDecision,
        ),
        actionMapper.map(
          state: _context.state,
          user: psdkOpponentSlot,
          decision: const BattleDecision.fight(moveSlot: 0),
        ),
      ],
    ).ordered(rng: _context.rng);

    _context.beginTurn();
    final timeline = BattleTimelineBuilder()
      ..add(BattleTurnStartedTimelineEvent(turn: _context.turnNumber));

    try {
      for (var actionIndex = 0; actionIndex < actions.length; actionIndex++) {
        final action = actions[actionIndex];
        if (action is PsdkBattleItemAction) {
          final item = _resolveItemAction(action);
          _context.applyStateAndRng(
            nextState: item.state,
            nextRng: item.rng,
          );
          timeline.addPsdkAll(item.events);
          continue;
        }
        if (action is PsdkBattleMegaAction) {
          final mega = _resolveMegaAction(action);
          _context.applyStateAndRng(
            nextState: mega.state,
            nextRng: mega.rng,
          );
          timeline.addPsdkAll(mega.events);
          continue;
        }
        if (action is PsdkBattleSwitchAction) {
          final switched = _resolveSwitchAction(action);
          _context.applyStateAndRng(
            nextState: switched.state,
            nextRng: switched.rng,
          );
          timeline.addPsdkAll(switched.events);
          final outcome = _context.resolveOutcome();
          if (outcome != null) {
            _context.finish(outcome);
            timeline.add(BattleEndedTimelineEvent(outcome: outcome));
            break;
          }
          continue;
        }
        if (action is! PsdkBattleFightAction) {
          throw UnsupportedError(
            'PSDK ${action.kind.name} actions need item/shift/flee topology '
            'before they can execute.',
          );
        }
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
        final statusPrevention = _resolveStatusUserPrevention(
          action: action,
          move: cleanMoveBeforePp,
        );
        if (statusPrevention != null) {
          _context.applyStateAndRng(
            nextState: statusPrevention.state,
            nextRng: statusPrevention.rng,
          );
          timeline.addPsdkAll(statusPrevention.events);
          if (statusPrevention.prevented) {
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
                reason: statusPrevention.reason.jsonName,
              ),
            );
            _notifyMoveFailure(
              user: action.user,
              target: action.target,
              move: cleanMoveBeforePp,
              reason: statusPrevention.reason,
            );
            continue;
          }
        }
        final abilityPrevention = _resolveAbilityUserPrevention(
          action: action,
          move: cleanMoveBeforePp,
        );
        if (abilityPrevention != null) {
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
              reason: abilityPrevention.jsonName,
            ),
          );
          _notifyMoveFailure(
            user: action.user,
            target: action.target,
            move: cleanMoveBeforePp,
            reason: abilityPrevention,
          );
          continue;
        }
        final effectPrevention = _resolveEffectUserPrevention(
          action: action,
          move: cleanMoveBeforePp,
        );
        if (effectPrevention != null) {
          _context.applyStateAndRng(
            nextState: effectPrevention.state,
            nextRng: effectPrevention.rng,
          );
          timeline.addPsdkAll(effectPrevention.events);
          if (effectPrevention.prevented) {
            if (effectPrevention.recordAttempt) {
              _recordMoveAttempt(
                user: action.user,
                moveId: moveBeforePp.id,
                targets: historyTargets,
              );
            }
            timeline.add(
              BattleMoveFailedTimelineEvent(
                turn: _context.turnNumber,
                user: _fromPsdkSlot(action.user),
                target: _fromPsdkSlot(action.target),
                moveId: moveBeforePp.id,
                reason: effectPrevention.reason.jsonName,
              ),
            );
            _notifyMoveFailure(
              user: action.user,
              target: action.target,
              move: cleanMoveBeforePp,
              reason: effectPrevention.reason,
            );
            continue;
          }
        }
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
                moveSlot: action.moveSlot,
                isLastActionOfTurn: !_hasRunnableActionAfter(
                  actions,
                  actionIndex,
                ),
                moveProcedureHooks: _moveProcedureHooks,
                announcedMoveFor: (battler) => _announcedFightActionAfter(
                  actions,
                  actionIndex,
                  battler,
                ),
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
            moveSlot: action.moveSlot,
            isLastActionOfTurn: !_hasRunnableActionAfter(
              actions,
              actionIndex,
            ),
            moveProcedureHooks: _moveProcedureHooks,
            announcedMoveFor: (battler) => _announcedFightActionAfter(
              actions,
              actionIndex,
              battler,
            ),
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

    final endTurn = _resolveEndTurn();
    timeline.addPsdkAll(endTurn.events);
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

  BattleHandlerResult _resolveEndTurn() {
    final result = const BattleEndTurnHandler().resolveEndTurn(
      BattleHandlerContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: psdkPlayerSlot,
      ),
    );
    if (result.applied) {
      _context.applyStateAndRng(
        nextState: result.state,
        nextRng: result.rng,
      );
    }
    return result;
  }

  BattleHandlerResult _resolveSwitchAction(PsdkBattleSwitchAction action) {
    return const BattleSwitchHandler().switchCombatant(
      context: BattleHandlerContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: action.user,
      ),
      target: action.user,
      partyIndex: action.partyIndex,
    );
  }

  BattleHandlerResult _resolveItemAction(PsdkBattleItemAction action) {
    return const BattleItemActionHandler().useItem(
      context: BattleHandlerContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: action.user,
      ),
      action: action,
    );
  }

  BattleHandlerResult _resolveMegaAction(PsdkBattleMegaAction action) {
    return const BattleMegaActionHandler().megaEvolve(
      context: BattleHandlerContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: action.user,
      ),
      action: action,
    );
  }

  BattleStatusUserPreventionResult? _resolveStatusUserPrevention({
    required PsdkBattleFightAction action,
    required BattleMoveDefinition move,
  }) {
    return const BattleStatusChangeHandler().resolveUserPrevention(
      context: BattleHandlerContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: action.user,
      ),
      user: action.user,
      move: move,
    );
  }

  BattleMoveFailureReason? _resolveAbilityUserPrevention({
    required PsdkBattleFightAction action,
    required BattleMoveDefinition move,
  }) {
    final context = BattleAbilityMoveContext(
      state: _context.state,
      user: action.user,
      target: action.target,
      move: move,
    );
    for (final effect in _context.state.activeAbilityEffects()) {
      final reason = effect.onMovePreventionUser(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  BattleEffectUserMovePreventionResult? _resolveEffectUserPrevention({
    required PsdkBattleFightAction action,
    required BattleMoveDefinition move,
  }) {
    return _context.state.battlerAt(action.user).effects.userMovePrevention(
          BattleEffectUserMovePreventionContext(
            state: _context.state,
            rng: _context.rng,
            turn: _context.turnNumber,
            user: action.user,
            target: action.target,
            move: move,
          ),
          where: (effect) => effect is! BattleMajorStatusEffect,
        );
  }

  bool _hasRunnableActionAfter(
    List<PsdkBattleAction> actions,
    int actionIndex,
  ) {
    for (var index = actionIndex + 1; index < actions.length; index++) {
      final action = actions[index];
      if (action is! PsdkBattleFightAction) {
        continue;
      }
      final user = _context.state.battlerAt(action.user);
      final target = _context.state.battlerAt(action.target);
      if (!user.isFainted && !target.isFainted) {
        return true;
      }
    }
    return false;
  }

  BattleAnnouncedMove? _announcedFightActionAfter(
    List<PsdkBattleAction> actions,
    int actionIndex,
    PsdkBattleSlotRef battler,
  ) {
    for (var index = actionIndex + 1; index < actions.length; index++) {
      final action = actions[index];
      if (action is! PsdkBattleFightAction || action.user != battler) {
        continue;
      }
      final user = _context.state.battlerAt(action.user);
      final target = _context.state.battlerAt(action.target);
      if (user.isFainted || target.isFainted) {
        return null;
      }
      return BattleAnnouncedMove(
        user: action.user,
        target: action.target,
        moveSlot: action.moveSlot,
        move: action.move,
      );
    }
    return null;
  }

  void _recordMoveAttempt({
    required PsdkBattleSlotRef user,
    required String moveId,
    required List<PsdkBattleSlotRef> targets,
  }) {
    _context.applyStateAndRng(
      nextState: _moveHistoryRecorder.recordAttempt(
        state: _context.state,
        user: user,
        moveId: moveId,
        turn: _context.turnNumber,
        targets: targets,
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
      nextState: _moveHistoryRecorder.recordSuccess(
        state: _context.state,
        user: user,
        moveId: moveId,
        turn: _context.turnNumber,
        targets: targets,
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
