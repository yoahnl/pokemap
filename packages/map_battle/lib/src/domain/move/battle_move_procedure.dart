import '../battle/battle_slot.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import 'battle_accuracy_resolver.dart';
import 'battle_move_execution.dart';
import 'battle_move_prevention.dart';
import 'battle_move_remapper.dart';
import 'battle_target_resolver.dart';

final class BattleMoveProcedure {
  const BattleMoveProcedure({
    BattleTargetResolver targetResolver = const BattleTargetResolver(),
    BattleAccuracyResolver accuracyResolver = const BattleAccuracyResolver(),
    BattleMoveRemapper remapper = const NoopBattleMoveRemapper(),
    BattleMoveTargetPrecheck? targetPrecheck,
    BattleMoveProcedureHooks hooks = BattleMoveProcedureHooks.none,
    bool traceStages = false,
    bool forceAccuracyBypass = false,
  })  : _targetResolver = targetResolver,
        _accuracyResolver = accuracyResolver,
        _remapper = remapper,
        _targetPrecheck = targetPrecheck,
        _hooks = hooks,
        _traceStages = traceStages,
        _forceAccuracyBypass = forceAccuracyBypass;

  final BattleTargetResolver _targetResolver;
  final BattleAccuracyResolver _accuracyResolver;
  final BattleMoveRemapper _remapper;
  final BattleMoveTargetPrecheck? _targetPrecheck;
  final BattleMoveProcedureHooks _hooks;
  final bool _traceStages;
  final bool _forceAccuracyBypass;

  BattleMoveProcedureResult prepare(BattleMoveProcedureExecution execution) {
    _trace(execution, BattleMoveProcedureStage.userAlive);
    final user = execution.context.state.battlerAt(execution.context.user);
    if (user.isFainted) {
      _notifyFailure(
        execution: execution,
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.userFainted,
      );
      return BattleMoveProcedureResult.failed(
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.userFainted,
      );
    }

    _trace(execution, BattleMoveProcedureStage.resolveTargets);
    final targets = _targetResolver.resolve(execution);

    // In PSDK this stage also runs effect user-prevention and PP decrement.
    // Dart currently performs those in BattleTurnRunner before dispatching the
    // behavior. Keeping the stage visible here prevents later ports from
    // accidentally moving declaration/pre-accuracy ahead of usability.
    _trace(execution, BattleMoveProcedureStage.usableByUser);

    _trace(execution, BattleMoveProcedureStage.usage);
    execution.timeline.add(
      BattleMoveDeclaredTimelineEvent(
        turn: execution.turn,
        user: execution.user,
        targets: targets,
        moveId: execution.move.id,
        moveName: execution.move.name,
        moveDbSymbol: execution.move.dbSymbol,
      ),
    );

    _trace(execution, BattleMoveProcedureStage.preAccuracy);
    _hooks.notifyPreAccuracy(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: execution.context.rng,
        turn: execution.turn,
        user: execution.user,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: targets,
      ),
    );

    _trace(execution, BattleMoveProcedureStage.noTarget);
    if (targets.isEmpty && execution.move.target.requiresBattlerTarget) {
      execution.timeline.add(
        BattleMoveFailedTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          moveId: execution.move.id,
          reason: BattleMoveFailureReason.noTarget.jsonName,
        ),
      );
      _notifyFailure(
        execution: execution,
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.noTarget,
      );
      return BattleMoveProcedureResult.failed(
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.noTarget,
      );
    }

    if (targets.isEmpty) {
      execution.actualTargets = targets;
      _trace(execution, BattleMoveProcedureStage.postAccuracy);
      _hooks.notifyPostAccuracy(
        BattleMoveAccuracyHookContext(
          state: execution.context.state,
          rng: execution.context.rng,
          turn: execution.turn,
          user: execution.user,
          requestedTarget: execution.requestedTarget,
          move: execution.move,
          targets: targets,
        ),
      );
      _trace(execution, BattleMoveProcedureStage.postAccuracyMove);
      _hooks.notifyPostAccuracyMove(
        BattleMoveAccuracyHookContext(
          state: execution.context.state,
          rng: execution.context.rng,
          turn: execution.turn,
          user: execution.user,
          requestedTarget: execution.requestedTarget,
          move: execution.move,
          targets: targets,
        ),
      );
      _trace(execution, BattleMoveProcedureStage.animation);
      execution.timeline.add(
        BattleAnimationCueTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          targets: targets,
          moveId: execution.move.id,
          animationId: execution.move.dbSymbol,
        ),
      );
      return BattleMoveProcedureResult.ready(
        rng: execution.context.rng,
        targets: targets,
      );
    }

    _trace(execution, BattleMoveProcedureStage.accuracy);
    final accuracy = _forceAccuracyBypass
        ? BattleAccuracyResult(
            rng: execution.context.rng,
            hitTargets: targets,
            missedTargets: const <BattlePositionRef>[],
            bypassed: true,
          )
        : _accuracyResolver.resolve(
            execution: execution,
            targets: targets,
          );
    for (final missedTarget in accuracy.missedTargets) {
      execution.timeline.add(
        BattleMoveMissedTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          target: missedTarget,
          moveId: execution.move.id,
        ),
      );
    }
    var actualTargets = accuracy.hitTargets;
    if (actualTargets.isEmpty) {
      _notifyFailure(
        execution: execution,
        rng: accuracy.rng,
        reason: BattleMoveFailureReason.accuracy,
        targets: targets,
      );
      return BattleMoveProcedureResult.failed(
        rng: accuracy.rng,
        reason: BattleMoveFailureReason.accuracy,
      );
    }

    _trace(execution, BattleMoveProcedureStage.remap);
    final remapped = _remapper.remap(
      BattleMoveRemapContext(
        state: execution.context.state,
        turn: execution.turn,
        user: execution.user,
        targets: actualTargets,
        move: execution.move,
      ),
    );
    execution.actualUser = remapped.user;
    actualTargets = remapped.targets;

    _trace(execution, BattleMoveProcedureStage.immunity);
    final targetPrecheck = _targetPrecheck;
    if (targetPrecheck != null) {
      final precheck = targetPrecheck(execution, actualTargets);
      actualTargets = precheck.targets;
      if (actualTargets.isEmpty) {
        _notifyFailure(
          execution: execution,
          rng: accuracy.rng,
          reason: precheck.reason,
          targets: accuracy.hitTargets,
        );
        return BattleMoveProcedureResult.failed(
          rng: accuracy.rng,
          reason: precheck.reason,
        );
      }
    }

    execution.actualTargets = actualTargets;
    _trace(execution, BattleMoveProcedureStage.postAccuracy);
    _hooks.notifyPostAccuracy(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: accuracy.rng,
        turn: execution.turn,
        user: execution.actualUser,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: actualTargets,
      ),
    );
    _trace(execution, BattleMoveProcedureStage.postAccuracyMove);
    _hooks.notifyPostAccuracyMove(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: accuracy.rng,
        turn: execution.turn,
        user: execution.actualUser,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: actualTargets,
      ),
    );
    _trace(execution, BattleMoveProcedureStage.animation);
    execution.timeline.add(
      BattleAnimationCueTimelineEvent(
        turn: execution.turn,
        user: execution.actualUser,
        targets: actualTargets,
        moveId: execution.move.id,
        animationId: execution.move.dbSymbol,
      ),
    );

    return BattleMoveProcedureResult.ready(
      rng: accuracy.rng,
      targets: actualTargets,
    );
  }

  void _notifyFailure({
    required BattleMoveProcedureExecution execution,
    required BattleRngStreams rng,
    required BattleMoveFailureReason reason,
    List<BattlePositionRef> targets = const <BattlePositionRef>[],
  }) {
    _hooks.notifyFailure(
      BattleMoveFailureContext(
        state: execution.context.state,
        rng: rng,
        turn: execution.turn,
        user: execution.actualUser,
        target: execution.requestedTarget,
        move: execution.move,
        reason: reason,
        targets: targets,
      ),
    );
  }

  void _trace(
    BattleMoveProcedureExecution execution,
    BattleMoveProcedureStage stage,
  ) {
    if (!_traceStages) {
      return;
    }
    execution.timeline.add(
      BattleMoveProcedureTraceEvent(
        turn: execution.turn,
        moveId: execution.move.id,
        stage: stage,
      ),
    );
  }
}

typedef BattleMoveTargetPrecheck = BattleMoveTargetPrecheckResult Function(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
);

final class BattleMoveTargetPrecheckResult {
  BattleMoveTargetPrecheckResult({
    required List<BattlePositionRef> targets,
    required this.reason,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final List<BattlePositionRef> targets;
  final BattleMoveFailureReason reason;
}

final class BattleMoveProcedureResult {
  BattleMoveProcedureResult._({
    required this.rng,
    required List<BattlePositionRef> targets,
    required this.reason,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  factory BattleMoveProcedureResult.ready({
    required BattleRngStreams rng,
    required List<BattlePositionRef> targets,
  }) {
    return BattleMoveProcedureResult._(
      rng: rng,
      targets: targets,
      reason: null,
    );
  }

  factory BattleMoveProcedureResult.failed({
    required BattleRngStreams rng,
    required BattleMoveFailureReason reason,
  }) {
    return BattleMoveProcedureResult._(
      rng: rng,
      targets: const <BattlePositionRef>[],
      reason: reason,
    );
  }

  final BattleRngStreams rng;
  final List<BattlePositionRef> targets;
  final BattleMoveFailureReason? reason;

  bool get shouldExecuteBehavior => reason == null;
}
