import '../domain/battle/battle_context.dart';
import '../domain/battle/battle_setup.dart';
import '../domain/ai/psdk_battle_ai.dart';
import '../domain/action/battle_action.dart';
import '../domain/action/battle_item_action_handler.dart';
import '../domain/decision/battle_decision.dart';
import '../domain/handler/battle_handler_context.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/timeline/battle_timeline_event.dart';
import '../domain/timeline/battle_timeline.dart';
import '../psdk/domain/psdk_battle_slots.dart';
import '../psdk/application/psdk_battle_move_behavior.dart';
import '../psdk/domain/psdk_battle_setup.dart';
import 'battle_turn_runner.dart';

/// Public clean-architecture entry point for the PSDK battle migration.
///
/// This engine owns a mutable [BattleContext] internally and exposes immutable
/// snapshots/results externally. That mirrors the Ruby PSDK style closely
/// enough for future handler/effect ports while avoiding a breaking rewrite of
/// the legacy immutable `BattleSession` API in this lot.
final class BattleEngine {
  BattleEngine({
    required BattleEngineSetup setup,
    PsdkBattleMoveBehaviorRegistry? moveBehaviorRegistry,
    BattleMoveProcedureHooks moveProcedureHooks = BattleMoveProcedureHooks.none,
    PsdkBattleAi? opponentAi,
  })  : _context = BattleContext.fromSetup(setup),
        _moveProcedureHooks = moveProcedureHooks,
        _opponentAi = opponentAi,
        _opponentItemQuantities = {
          for (final option
              in opponentAi?.itemOptions ?? const <PsdkBattleAiItemOption>[])
            option.itemId: option.quantity,
        },
        _moveBehaviorRegistry =
            moveBehaviorRegistry ?? PsdkBattleMoveBehaviorRegistry.defaults();

  BattleEngine.fromPsdk({
    required PsdkBattleSetup setup,
    PsdkBattleMoveBehaviorRegistry? moveBehaviorRegistry,
    BattleMoveProcedureHooks moveProcedureHooks = BattleMoveProcedureHooks.none,
    PsdkBattleAi? opponentAi,
  }) : this(
          setup: BattleEngineSetup.fromPsdk(setup),
          moveBehaviorRegistry: moveBehaviorRegistry,
          moveProcedureHooks: moveProcedureHooks,
          opponentAi: opponentAi,
        );

  final BattleContext _context;
  final PsdkBattleMoveBehaviorRegistry _moveBehaviorRegistry;
  final BattleMoveProcedureHooks _moveProcedureHooks;
  final PsdkBattleAi? _opponentAi;
  final Map<String, int> _opponentItemQuantities;
  final Map<PsdkBattleSlotRef, BattleDecision> _pendingChoices = {};
  BattleEngineDecisionRequest? _request;
  int _requestRevision = 0;

  BattleEngineDecisionRequest get currentRequest {
    return _request ??= _createRequest();
  }

  BattleEngineDecisionRequest _createRequest() {
    final slots = _context.state.combatants.keys
        .where((slot) => slot.bank == 0)
        .toList()
      ..sort((left, right) => left.position.compareTo(right.position));
    final reserved = {
      for (final choice in _pendingChoices.values)
        if (choice is BattleSwitchDecision) choice.partyIndex,
    };
    BattleEngineDecisionRequest at(PsdkBattleSlotRef actor) =>
        BattleEngineDecisionRequest.fromContext(
          _context,
          actor: actor,
          requestRevision: _requestRevision,
          reservedPartyIndexes: reserved,
        );
    for (final slot in slots) {
      if (_context.state.battlerAt(slot).isFainted) {
        final request = at(slot);
        if (request.kind == BattleEngineDecisionRequestKind.forcedReplacement) {
          return request;
        }
      }
    }
    return at(slots
            .where((slot) =>
                !_context.state.battlerAt(slot).isFainted &&
                !_pendingChoices.containsKey(slot))
            .firstOrNull ??
        slots.first);
  }

  BattleEngineTurnResult submit(
    BattleDecision decision, {
    BattleEngineDecisionRequest? request,
  }) {
    final current = currentRequest;
    if (!_context.setup.isSingles &&
        (!identical(request, current) || !current.allows(decision))) {
      throw BattleDecisionRejectedError(
          requestKind: current.kind, decision: decision);
    }
    if (decision is BattleFightDecision &&
        decision.isStruggle &&
        !current.canStruggle) {
      throw BattleDecisionRejectedError(
        requestKind: current.kind,
        decision: decision,
      );
    }
    if (!_context.setup.isSingles && decision is BattleItemDecision) {
      final item = const BattleItemActionHandler().useItem(
        context: BattleHandlerContext(
          state: _context.state,
          rng: _context.rng,
          turn: _context.turnNumber,
          user: current.actor,
        ),
        action: PsdkBattleItemAction(
          user: current.actor,
          itemId: decision.itemId,
          target: decision.target,
          targetPartyIndex: decision.targetPartyIndex,
          effect: decision.effect,
          consumeItem: decision.consumeItem,
          highPriority: decision.highPriority,
        ),
      );
      if (!item.applied) {
        throw BattleDecisionRejectedError(
          requestKind: current.kind,
          decision: decision,
        );
      }
    }
    final runner = BattleTurnRunner(
      _context,
      moveBehaviorRegistry: _moveBehaviorRegistry,
      moveProcedureHooks: _moveProcedureHooks,
      opponentAi: _opponentAi,
      opponentItemQuantities: _opponentItemQuantities,
    );
    BattleEngineTurnResult result;
    if (current.kind == BattleEngineDecisionRequestKind.forcedReplacement &&
        decision is BattleSwitchDecision) {
      result = runner.replaceFaintedPlayer(
        decision,
        actor: current.actor,
      );
    } else if (_context.setup.isSingles) {
      result = runner.run(decision);
    } else {
      _pendingChoices[current.actor] = decision;
      final remaining = _context.state.aliveSlots().where(
          (slot) => slot.bank == 0 && !_pendingChoices.containsKey(slot));
      if (remaining.isNotEmpty) {
        _requestRevision++;
        _request = null;
        return BattleEngineTurnResult(
          state: snapshot(),
          timeline: BattleTimeline.empty(),
          outcome: snapshot().outcome,
          nextRequest: currentRequest,
        );
      }
      try {
        result = runner.runChoices(Map.unmodifiable(_pendingChoices));
      } catch (_) {
        _pendingChoices.remove(current.actor);
        rethrow;
      }
      _pendingChoices.clear();
    }
    for (final event
        in result.timeline.events.whereType<BattleItemTimelineEvent>()) {
      if (event.kind != 'item_consumed' || event.user.bank != 1) {
        continue;
      }
      final quantity = _opponentItemQuantities[event.itemId] ?? 0;
      if (quantity > 0) {
        _opponentItemQuantities[event.itemId] = quantity - 1;
      }
    }
    _requestRevision++;
    _request = null;
    return BattleEngineTurnResult(
      state: result.state,
      timeline: result.timeline,
      outcome: result.outcome,
      nextRequest: result.state.isFinished ? null : currentRequest,
    );
  }

  BattlePublicState snapshot() => BattlePublicState.fromContext(_context);
}
