import '../domain/battle/battle_context.dart';
import '../domain/battle/battle_outcome.dart';
import '../domain/battle/battle_slot.dart';
import '../domain/ai/psdk_battle_ai.dart';
import '../domain/action/battle_action.dart';
import '../domain/action/battle_action_decision_mapper.dart';
import '../domain/action/battle_item_action_handler.dart';
import '../domain/action/battle_mega_action_handler.dart';
import '../domain/action/battle_shift_action_handler.dart';
import '../domain/action/battle_action_queue.dart';
import '../domain/decision/battle_decision.dart';
import '../domain/effect/ability/ability_effect.dart';
import '../domain/effect/ability/dancer_effect.dart';
import '../domain/effect/battle_effect.dart';
import '../domain/effect/battle_effect_scope.dart';
import '../domain/effect/battle_effect_hooks.dart';
import '../domain/effect/move/beak_blast_effect.dart';
import '../domain/effect/move/shell_trap_effect.dart';
import '../domain/effect/item/item_effect.dart';
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
import '../psdk/domain/psdk_battle_combatant.dart';
import '../psdk/domain/psdk_battle_move.dart';
import '../psdk/domain/psdk_battle_outcome.dart';
import '../psdk/domain/psdk_battle_slots.dart';
import '../psdk/domain/psdk_battle_state.dart';
import '../psdk/domain/psdk_battle_timeline.dart';

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
    PsdkBattleAi? opponentAi,
  })  : _moveBehaviorRegistry = moveBehaviorRegistry,
        _moveProcedureHooks = moveProcedureHooks,
        _opponentAi = opponentAi;

  final BattleContext _context;
  final PsdkBattleMoveBehaviorRegistry _moveBehaviorRegistry;
  final BattleMoveProcedureHooks _moveProcedureHooks;
  final PsdkBattleAi? _opponentAi;
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
    var actions = PsdkBattleActionQueue(
      actions: <PsdkBattleAction>[
        actionMapper.map(
          state: _context.state,
          user: psdkPlayerSlot,
          decision: playerDecision,
        ),
        actionMapper.map(
          state: _context.state,
          user: psdkOpponentSlot,
          decision: _opponentDecision(),
        ),
      ],
    ).ordered(
      rng: _context.rng,
      trickRoom: _hasActiveFieldEffect(_context.state, 'trick_room'),
    );

    _context.beginTurn();
    final timeline = BattleTimelineBuilder()
      ..add(BattleTurnStartedTimelineEvent(turn: _context.turnNumber));
    try {
      final preAttack = _resolvePreAttackActions(actions);
      if (preAttack.applied) {
        _context.applyStateAndRng(
          nextState: preAttack.state,
          nextRng: preAttack.rng,
        );
        timeline.addPsdkAll(preAttack.events);
      }

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
        if (action is PsdkBattleFleeAction) {
          final fled = _resolveFleeAction(action, timeline);
          if (fled) {
            break;
          }
          continue;
        }
        if (action is PsdkBattleShiftAction) {
          final shifted = _resolveShiftAction(action);
          _context.applyStateAndRng(
            nextState: shifted.state,
            nextRng: shifted.rng,
          );
          timeline.addPsdkAll(shifted.events);
          continue;
        }
        if (action is PsdkBattleNoAction) {
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
        final moveBeforePp = user.moves[action.moveSlot];
        final moveAllowsFaintedOriginalTarget =
            moveBeforePp.battleEngineMethod == 's_dragon_darts';
        if (user.isFainted ||
            user.switching ||
            (target.isFainted && !moveAllowsFaintedOriginalTarget)) {
          continue;
        }

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
              attackOrder: actionIndex,
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
            attackOrder: actionIndex,
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
                attackOrder: actionIndex,
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
                canFlee: _context.setup.canFlee,
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
            attackOrder: actionIndex,
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
            attackOrder: actionIndex,
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

        final ppCost = _ppCostForMove(
          state: _context.state,
          user: action.user,
        );
        final moveAfterPp = moveBeforePp.spendPp(ppCost);
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
        final cleanMoveAfterPp = BattleMoveDefinition.fromPsdk(moveAfterPp);
        final preAccuracy = _resolvePreAccuracy(
          user: action.user,
          target: action.target,
          move: cleanMoveAfterPp,
        );
        if (preAccuracy.applied || preAccuracy.events.isNotEmpty) {
          _context.applyStateAndRng(
            nextState: preAccuracy.state,
            nextRng: preAccuracy.rng,
          );
          timeline.addPsdkAll(preAccuracy.events);
        }

        final stateBeforeResolution = _context.state;
        final resolution = _moveBehaviorRegistry.resolve(
          method: moveAfterPp.battleEngineMethod,
          context: PsdkBattleMoveContext(
            state: _context.state,
            rng: _context.rng,
            turn: _context.turnNumber,
            user: action.user,
            target: action.target,
            move: moveAfterPp,
            canFlee: _context.setup.canFlee,
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
        actions = _deferOpenedShellTrapActions(
          actions: actions,
          currentIndex: actionIndex,
          beforeState: stateBeforeResolution,
          afterState: _context.state,
        );
        timeline.addPsdkAll(resolution.events);
        _recordMoveAttempt(
          user: action.user,
          moveId: moveAfterPp.id,
          targets: historyTargets,
          attackOrder: actionIndex,
        );
        if (resolution.successful) {
          _recordMoveSuccess(
            user: action.user,
            moveId: moveAfterPp.id,
            targets: historyTargets,
            attackOrder: actionIndex,
          );
          final postAction = _resolvePostAction(
            user: action.user,
            move: cleanMoveAfterPp,
            successful: true,
          );
          _context.applyStateAndRng(
            nextState: postAction.state,
            nextRng: postAction.rng,
          );
          timeline.addPsdkAll(postAction.events);
          final dancerReplays = _resolveDancerReplays(
            user: action.user,
            target: action.target,
            move: moveAfterPp,
            actions: actions,
            actionIndex: actionIndex,
          );
          if (dancerReplays.applied || dancerReplays.events.isNotEmpty) {
            _context.applyStateAndRng(
              nextState: dancerReplays.state,
              nextRng: dancerReplays.rng,
            );
            timeline.addPsdkAll(dancerReplays.events);
          }
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

    if (_context.canBattleContinue) {
      final endTurn = _resolveEndTurn();
      timeline.addPsdkAll(endTurn.events);
    }
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

  BattleDecision _opponentDecision() {
    final ai = _opponentAi;
    if (ai == null) {
      return const BattleDecision.fight(moveSlot: 0);
    }
    return ai.chooseDecision(
      state: _context.state,
      user: psdkOpponentSlot,
      target: psdkPlayerSlot,
    );
  }

  BattleHandlerResult _resolvePreAttackActions(List<PsdkBattleAction> actions) {
    var state = _context.state;
    var applied = false;

    for (final action in actions.whereType<PsdkBattleFightAction>()) {
      final effect = _preAttackEffectFor(action);
      if (effect == null) {
        continue;
      }

      final user = state.battlerAt(action.user);
      if (user.isFainted ||
          user.majorStatus == PsdkBattleMajorStatus.sleep ||
          user.majorStatus == PsdkBattleMajorStatus.freeze) {
        continue;
      }

      state = state.updateBattler(
        action.user,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(effect),
        ),
      );
      applied = true;
    }

    return BattleHandlerResult(
      state: state,
      rng: _context.rng,
      applied: applied,
    );
  }

  List<PsdkBattleAction> _deferOpenedShellTrapActions({
    required List<PsdkBattleAction> actions,
    required int currentIndex,
    required PsdkBattleState beforeState,
    required PsdkBattleState afterState,
  }) {
    var next = actions;
    for (final entry in beforeState.combatants.entries) {
      final slot = entry.key;
      if (!entry.value.effects.contains('shell_trap')) {
        continue;
      }
      final after = afterState.combatants[slot];
      if (after == null || after.effects.contains('shell_trap')) {
        continue;
      }
      next = PsdkBattleActionQueue.deferPendingShellTrapActionToEnd(
        actions: next,
        currentIndex: currentIndex,
        user: slot,
      );
    }
    return next;
  }

  BattleEffect? _preAttackEffectFor(PsdkBattleFightAction action) {
    final scope = BattlerBattleEffectScope(action.user);
    return switch (action.move.battleEngineMethod) {
      's_beak_blast' => BeakBlastEffect(scope: scope),
      's_shell_trap' => ShellTrapEffect(scope: scope),
      _ => null,
    };
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

  bool _resolveFleeAction(
    PsdkBattleFleeAction action,
    BattleTimelineBuilder timeline,
  ) {
    final succeeded =
        _context.setup.canFlee || _hasFleePassthrough(action.user);
    timeline.add(
      BattleFleeAttemptTimelineEvent(
        turn: _context.turnNumber,
        actor: _fromPsdkSlot(action.user),
        succeeded: succeeded,
      ),
    );
    if (!succeeded) {
      return false;
    }

    const outcome = PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.fled);
    _context.finish(outcome);
    timeline.add(BattleEndedTimelineEvent(outcome: outcome));
    return true;
  }

  bool _hasFleePassthrough(PsdkBattleSlotRef user) {
    final battler = _context.state.battlerAt(user);
    if (battler.isFainted) {
      return false;
    }
    for (final effect in battler.abilityEffects) {
      if (effect.fleePassthrough(state: _context.state, user: user)) {
        return true;
      }
    }
    for (final effect in _context.state.activeItemEffectsAt(user)) {
      if (effect.fleePassthrough(state: _context.state, user: user)) {
        return true;
      }
    }
    return false;
  }

  BattleHandlerResult _resolveShiftAction(PsdkBattleShiftAction action) {
    return const BattleShiftActionHandler().shift(
      context: BattleHandlerContext(
        state: _context.state,
        rng: _context.rng,
        turn: _context.turnNumber,
        user: action.user,
      ),
      action: action,
    );
  }

  BattleEffectPreAccuracyResult _resolvePreAccuracy({
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
  }) {
    return _context.state.battlerAt(user).effects.dispatchPreAccuracy(
          BattleEffectPreAccuracyContext(
            state: _context.state,
            rng: _context.rng,
            turn: _context.turnNumber,
            owner: user,
            user: user,
            target: target,
            move: move,
          ),
          where: (effect) => effect is! BattleMajorStatusEffect,
        );
  }

  BattleEffectPostActionResult _resolvePostAction({
    required PsdkBattleSlotRef user,
    required BattleMoveDefinition move,
    required bool successful,
  }) {
    var nextState = _context.state;
    var nextRng = _context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;
    for (final owner in _context.state.aliveSlots()) {
      final postAction = nextState.battlerAt(owner).effects.dispatchPostAction(
            BattleEffectPostActionContext(
              state: nextState,
              rng: nextRng,
              turn: _context.turnNumber,
              owner: owner,
              user: user,
              move: move,
              successful: successful,
            ),
          );
      nextState = postAction.state;
      nextRng = postAction.rng;
      events.addAll(postAction.events);
      changed = changed || postAction.applied || postAction.events.isNotEmpty;
    }
    return BattleEffectPostActionResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  BattleHandlerResult _resolveDancerReplays({
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required PsdkBattleMoveData move,
    required List<PsdkBattleAction> actions,
    required int actionIndex,
  }) {
    if (!_isDanceMove(move)) {
      return BattleHandlerResult(
        state: _context.state,
        rng: _context.rng,
        applied: false,
      );
    }
    if (_context.state.battlerAt(user).effects.contains('snatched')) {
      return BattleHandlerResult(
        state: _context.state,
        rng: _context.rng,
        applied: false,
      );
    }

    var nextState = _context.state;
    var nextRng = _context.rng;
    final events = <PsdkBattleEvent>[];
    final dancers = <PsdkBattleSlotRef>[
      for (final slot in nextState.aliveSlots())
        if (slot != user && _hasActiveDancerEffect(nextState, slot)) slot,
    ]..sort((left, right) {
        final speed = nextState
            .battlerAt(left)
            .effectiveStat('speed')
            .compareTo(nextState.battlerAt(right).effectiveStat('speed'));
        return speed == 0 ? _comparePsdkSlots(left, right) : speed;
      });

    for (final dancer in dancers) {
      final battler = nextState.battlerAt(dancer);
      if (battler.isFainted || _dancerReplayIsBlocked(battler)) {
        continue;
      }
      final dancerTarget = _dancerReplayTarget(
        originalUser: user,
        originalTarget: target,
        dancer: dancer,
        move: move,
      );
      if (nextState.battlerAt(dancerTarget).isFainted) {
        continue;
      }
      final replayState = _setDancerReplayActivated(
        state: nextState,
        dancer: dancer,
        activated: true,
      );
      final resolution = _moveBehaviorRegistry.resolve(
        method: move.battleEngineMethod,
        context: PsdkBattleMoveContext(
          state: replayState,
          rng: nextRng,
          turn: _context.turnNumber,
          user: dancer,
          target: dancerTarget,
          move: move,
          canFlee: _context.setup.canFlee,
          isLastActionOfTurn: !_hasRunnableActionAfter(actions, actionIndex),
          moveProcedureHooks: _moveProcedureHooks,
          announcedMoveFor: (battler) => _announcedFightActionAfter(
            actions,
            actionIndex,
            battler,
          ),
        ),
      );
      nextState = _setDancerReplayActivated(
        state: resolution.state,
        dancer: dancer,
        activated: false,
      );
      nextRng = resolution.rng;
      events.addAll(resolution.events);
    }

    return BattleHandlerResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: events.isNotEmpty,
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
    int attackOrder = 0,
  }) {
    _context.applyStateAndRng(
      nextState: _moveHistoryRecorder.recordAttempt(
        state: _context.state,
        user: user,
        moveId: moveId,
        turn: _context.turnNumber,
        targets: targets,
        attackOrder: attackOrder,
      ),
      nextRng: _context.rng,
    );
  }

  void _recordMoveSuccess({
    required PsdkBattleSlotRef user,
    required String moveId,
    required List<PsdkBattleSlotRef> targets,
    int attackOrder = 0,
  }) {
    _context.applyStateAndRng(
      nextState: _moveHistoryRecorder.recordSuccess(
        state: _context.state,
        user: user,
        moveId: moveId,
        turn: _context.turnNumber,
        targets: targets,
        attackOrder: attackOrder,
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

bool _isDanceMove(PsdkBattleMoveData move) {
  return move.dance || _danceMoveIds.contains(_normalizedMoveId(move));
}

bool _hasActiveDancerEffect(PsdkBattleState state, PsdkBattleSlotRef slot) {
  return state.battlerAt(slot).abilityEffects.any(
        (effect) => effect is DancerEffect || effect.abilityId == 'dancer',
      );
}

PsdkBattleState _setDancerReplayActivated({
  required PsdkBattleState state,
  required PsdkBattleSlotRef dancer,
  required bool activated,
}) {
  final battler = state.battlerAt(dancer);
  var changed = false;
  var effects = battler.effects;
  for (final effect in battler.effects.effects) {
    if (effect is DancerEffect) {
      changed = true;
      effects = effects.addEffect(effect.copyWithActivated(activated));
      break;
    }
  }
  effects = activated
      ? effects.addEffect(
          GenericBattleEffect(
            id: _dancerReplayActivatedEffectId,
            scope: BattlerBattleEffectScope(dancer),
          ),
        )
      : effects.remove(_dancerReplayActivatedEffectId);
  if (!changed &&
      battler.effects.contains(_dancerReplayActivatedEffectId) ==
          effects.contains(_dancerReplayActivatedEffectId)) {
    return state;
  }
  return state.updateBattler(
    dancer,
    (current) => current.copyWith(effects: effects),
  );
}

bool _dancerReplayIsBlocked(PsdkBattleCombatant battler) {
  return battler.effects.contains('out_of_reach') ||
      battler.effects.contains('out_of_reach_base') ||
      battler.effects.contains('flinch');
}

PsdkBattleSlotRef _dancerReplayTarget({
  required PsdkBattleSlotRef originalUser,
  required PsdkBattleSlotRef originalTarget,
  required PsdkBattleSlotRef dancer,
  required PsdkBattleMoveData move,
}) {
  final sameBankAsUser = originalUser.bank == dancer.bank;
  final originalUserWasNotTarget = originalUser != originalTarget;
  if (sameBankAsUser && originalUserWasNotTarget) {
    return originalTarget;
  }
  if (!sameBankAsUser &&
      originalUserWasNotTarget &&
      _normalizedMoveId(move) != 'lunar_dance') {
    return originalUser;
  }
  return dancer;
}

int _comparePsdkSlots(PsdkBattleSlotRef left, PsdkBattleSlotRef right) {
  final byBank = left.bank.compareTo(right.bank);
  return byBank == 0 ? left.position.compareTo(right.position) : byBank;
}

String _normalizedMoveId(PsdkBattleMoveData move) {
  final raw = move.dbSymbol.trim().isEmpty ? move.id : move.dbSymbol;
  return raw.trim().toLowerCase().replaceAll('-', '_');
}

const Set<String> _danceMoveIds = <String>{
  'dragon_dance',
  'feather_dance',
  'fiery_dance',
  'lunar_dance',
  'petal_dance',
  'quiver_dance',
  'revelation_dance',
  'swords_dance',
  'teeter_dance',
  'victory_dance',
};

const _dancerReplayActivatedEffectId = 'dancer_replay_activated';

bool _hasActiveFieldEffect(PsdkBattleState state, String effectId) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any((effect) {
      return effect.id == effectId && effect.scope is FieldBattleEffectScope;
    }),
  );
}

int _ppCostForMove({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
}) {
  return _hasAlivePressureFoe(state: state, user: user) ? 2 : 1;
}

bool _hasAlivePressureFoe({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
}) {
  for (final foe in state.foesOf(user)) {
    final battler = state.battlerAt(foe);
    if (battler.isFainted || battler.effects.contains('ability_suppressed')) {
      continue;
    }
    if (_normalizedAbilityId(battler.abilityId) == 'pressure') {
      return true;
    }
  }
  return false;
}

String? _normalizedAbilityId(String? abilityId) {
  return abilityId?.trim().toLowerCase().replaceAll('-', '_');
}

BattlePositionRef _fromPsdkSlot(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}
