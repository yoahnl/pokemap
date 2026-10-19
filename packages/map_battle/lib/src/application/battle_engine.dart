import '../domain/battle/battle_context.dart';
import '../domain/battle/battle_setup.dart';
import '../domain/ai/psdk_battle_ai.dart';
import '../domain/decision/battle_decision.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/timeline/battle_timeline_event.dart';
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
          for (final option in opponentAi?.itemOptions ??
              const <PsdkBattleAiItemOption>[])
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

  BattleEngineDecisionRequest get currentRequest {
    return BattleEngineDecisionRequest.fromContext(_context);
  }

  BattleEngineTurnResult submit(BattleDecision decision) {
    final request = currentRequest;
    if (decision is BattleFightDecision &&
        decision.isStruggle &&
        !request.canStruggle) {
      throw BattleDecisionRejectedError(
        requestKind: request.kind,
        decision: decision,
      );
    }
    final runner = BattleTurnRunner(
      _context,
      moveBehaviorRegistry: _moveBehaviorRegistry,
      moveProcedureHooks: _moveProcedureHooks,
      opponentAi: _opponentAi,
      opponentItemQuantities: _opponentItemQuantities,
    );
    if (request.kind == BattleEngineDecisionRequestKind.forcedReplacement &&
        decision is BattleSwitchDecision) {
      return runner.replaceFaintedPlayer(
        decision,
      );
    }
    final result = runner.run(decision);
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
    return result;
  }

  BattlePublicState snapshot() => BattlePublicState.fromContext(_context);
}
