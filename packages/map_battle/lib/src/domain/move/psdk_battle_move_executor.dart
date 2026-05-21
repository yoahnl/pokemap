import '../../data/static_basic_move_registry.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import 'battle_move_behavior.dart';
import 'battle_move_data.dart';
import 'battle_move_registry.dart';
import 'psdk_battle_move_request.dart';

/// Executes imported PSDK move metadata directly through the clean registry.
///
/// The executor deliberately owns no turn policy, PP spending, AI decision, or
/// party write-back. It only resolves `battleEngineMethod` and delegates to the
/// same behavior objects used by the PSDK battle lane.
final class PsdkBattleMoveExecutor {
  const PsdkBattleMoveExecutor() : _registry = null;

  const PsdkBattleMoveExecutor.withRegistry(BattleMoveRegistry registry)
      : _registry = registry;

  final BattleMoveRegistry? _registry;

  BattleMoveBehaviorResolution execute(PsdkBattleMoveRequest request) {
    final move = BattleMoveDefinition.fromPsdk(request.resolvedStudioMove);
    final behavior = (_registry ?? createStaticBasicMoveRegistry()).resolve(
      request.battleEngineMethod,
    );

    final result = behavior.resolve(
      BattleMoveBehaviorContext(
        state: request.state,
        rng: request.rng,
        turn: request.turn,
        user: request.user,
        target: request.target,
        move: move,
        moveSlot: request.moveSlot,
        isLastActionOfTurn: request.isLastActionOfTurn,
        moveProcedureHooks: request.moveProcedureHooks,
      ),
    );
    if (!result.successful) {
      return result;
    }
    var nextState = result.state;
    var nextRng = result.rng;
    final postActionEvents = <PsdkBattleEvent>[];
    var applied = false;

    for (final owner in result.state.aliveSlots()) {
      final postAction = nextState.battlerAt(owner).effects.dispatchPostAction(
            BattleEffectPostActionContext(
              state: nextState,
              rng: nextRng,
              turn: request.turn,
              owner: owner,
              user: request.user,
              move: move,
              successful: result.successful,
            ),
          );
      nextState = postAction.state;
      nextRng = postAction.rng;
      postActionEvents.addAll(postAction.events);
      applied = applied || postAction.applied || postAction.events.isNotEmpty;
    }

    if (!applied && postActionEvents.isEmpty) {
      return result;
    }
    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: nextRng,
      events: <PsdkBattleEvent>[
        ...result.events,
        ...postActionEvents,
      ],
      successful: result.successful,
    );
  }
}
