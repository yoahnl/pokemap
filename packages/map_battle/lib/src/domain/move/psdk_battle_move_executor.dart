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
    final postAction =
        result.state.battlerAt(request.user).effects.dispatchPostAction(
              BattleEffectPostActionContext(
                state: result.state,
                rng: result.rng,
                turn: request.turn,
                owner: request.user,
                user: request.user,
                move: move,
                successful: result.successful,
              ),
            );
    if (!postAction.applied && postAction.events.isEmpty) {
      return result;
    }
    return BattleMoveBehaviorResolution(
      state: postAction.state,
      rng: postAction.rng,
      events: <PsdkBattleEvent>[
        ...result.events,
        ...postAction.events,
      ],
      successful: result.successful,
    );
  }
}
