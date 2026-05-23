import '../../data/static_basic_move_registry.dart';
import '../../domain/move/battle_move_behavior.dart';
import '../../domain/move/battle_move_data.dart';
import '../../domain/move/battle_move_prevention.dart';
import '../../domain/move/battle_move_registry.dart';
import '../../domain/rng/battle_rng_streams.dart';
import '../domain/psdk_battle_move.dart';
import '../domain/psdk_battle_slots.dart';
import '../domain/psdk_battle_state.dart';
import '../domain/psdk_battle_timeline.dart';

class PsdkBattleMoveContext {
  const PsdkBattleMoveContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    required this.target,
    required this.move,
    this.canFlee = false,
    this.moveSlot,
    this.isLastActionOfTurn = false,
    this.moveProcedureHooks = BattleMoveProcedureHooks.none,
    this.announcedMoveFor,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final PsdkBattleMoveData move;
  final bool canFlee;
  final int? moveSlot;
  final bool isLastActionOfTurn;
  final BattleMoveProcedureHooks moveProcedureHooks;
  final BattleAnnouncedMove? Function(PsdkBattleSlotRef battler)?
      announcedMoveFor;
}

class PsdkBattleMoveResolution {
  const PsdkBattleMoveResolution({
    required this.state,
    required this.rng,
    required this.events,
    this.successful = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool successful;
}

typedef PsdkBattleMoveBehavior = PsdkBattleMoveResolution Function(
  PsdkBattleMoveContext context,
);

class PsdkBattleMoveBehaviorRegistry {
  PsdkBattleMoveBehaviorRegistry(Map<String, PsdkBattleMoveBehavior> behaviors)
      : _registry = BattleMoveRegistry(
          behaviors.entries.map(
            (entry) => _PsdkCallbackMoveBehavior(
              battleEngineMethod: entry.key,
              resolve: entry.value,
            ),
          ),
        );

  const PsdkBattleMoveBehaviorRegistry.fromClean(BattleMoveRegistry registry)
      : _registry = registry;

  factory PsdkBattleMoveBehaviorRegistry.defaults() {
    return PsdkBattleMoveBehaviorRegistry.fromClean(
      createStaticBasicMoveRegistry(),
    );
  }

  final BattleMoveRegistry _registry;

  PsdkBattleMoveResolution resolve({
    required String method,
    required PsdkBattleMoveContext context,
  }) {
    final behavior = _resolveBehavior(method);
    final result = behavior.resolve(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: BattleMoveDefinition.fromPsdk(context.move),
        canFlee: context.canFlee,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
        announcedMoveFor: context.announcedMoveFor,
      ),
    );
    return PsdkBattleMoveResolution(
      state: result.state,
      rng: result.rng,
      events: result.events,
      successful: result.successful,
    );
  }

  BattleMoveUserPreventionResult? preventUser({
    required String method,
    required PsdkBattleMoveContext context,
  }) {
    final behavior = _resolveBehavior(method);
    if (behavior is! BattleMoveUserPreventionBehavior) {
      return null;
    }
    return behavior.preventUser(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: BattleMoveDefinition.fromPsdk(context.move),
        canFlee: context.canFlee,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
        announcedMoveFor: context.announcedMoveFor,
      ),
    );
  }

  BattleMoveBehavior _resolveBehavior(String method) {
    try {
      return _registry.resolve(method);
    } on UnsupportedBattleMoveBehavior {
      throw UnsupportedPsdkBattleMoveBehavior(method);
    }
  }
}

class UnsupportedPsdkBattleMoveBehavior implements Exception {
  const UnsupportedPsdkBattleMoveBehavior(this.method);

  final String method;

  @override
  String toString() {
    return 'Unsupported PSDK battleEngineMethod "$method".';
  }
}

final class _PsdkCallbackMoveBehavior implements BattleMoveBehavior {
  const _PsdkCallbackMoveBehavior({
    required this.battleEngineMethod,
    required PsdkBattleMoveBehavior resolve,
  }) : _resolve = resolve;

  @override
  final String battleEngineMethod;
  final PsdkBattleMoveBehavior _resolve;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final result = _resolve(
      PsdkBattleMoveContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move.psdkMove,
        canFlee: context.canFlee,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
        announcedMoveFor: context.announcedMoveFor,
      ),
    );
    return BattleMoveBehaviorResolution(
      state: result.state,
      rng: result.rng,
      events: result.events,
      successful: result.successful,
    );
  }
}
