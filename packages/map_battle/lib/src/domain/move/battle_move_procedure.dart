import '../battle/battle_slot.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';
import 'battle_accuracy_resolver.dart';
import 'battle_move_execution.dart';
import 'battle_move_prevention.dart';
import 'battle_target_resolver.dart';

final class BattleMoveProcedure {
  const BattleMoveProcedure({
    BattleTargetResolver targetResolver = const BattleTargetResolver(),
    BattleAccuracyResolver accuracyResolver = const BattleAccuracyResolver(),
    BattleMoveTargetPrecheck? targetPrecheck,
    BattleMoveProcedureHooks hooks = BattleMoveProcedureHooks.none,
  })  : _targetResolver = targetResolver,
        _accuracyResolver = accuracyResolver,
        _targetPrecheck = targetPrecheck,
        _hooks = hooks;

  final BattleTargetResolver _targetResolver;
  final BattleAccuracyResolver _accuracyResolver;
  final BattleMoveTargetPrecheck? _targetPrecheck;
  final BattleMoveProcedureHooks _hooks;

  BattleMoveProcedureResult prepare(BattleMoveProcedureExecution execution) {
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

    final targets = _targetResolver.resolve(execution);
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

    if (targets.isEmpty) {
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

    final accuracy = _accuracyResolver.resolve(
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
    _hooks.notifyPostAccuracy(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: accuracy.rng,
        turn: execution.turn,
        user: execution.user,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: actualTargets,
      ),
    );
    _hooks.notifyPostAccuracyMove(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: accuracy.rng,
        turn: execution.turn,
        user: execution.user,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: actualTargets,
      ),
    );
    execution.timeline.add(
      BattleAnimationCueTimelineEvent(
        turn: execution.turn,
        user: execution.user,
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
        user: execution.user,
        target: execution.requestedTarget,
        move: execution.move,
        reason: reason,
        targets: targets,
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
