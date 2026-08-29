import 'package:map_core/map_core.dart';

import 'rail_journey_runtime_coordinator.dart';

typedef RailJourneyDoorAnimation = Future<bool> Function(
  String placedElementId,
);
typedef RailJourneySpatialTransition = Future<bool> Function(
  RailJourneyRuntimeTransition transition,
);
typedef RailJourneyProgressCommit = Future<void> Function(
  RailJourneyProgress progress,
);
typedef RailJourneyRuntimeRollback = Future<void> Function();

enum RailJourneyRuntimeTransactionBlockReason {
  runtimeBlocked,
  replayTransition,
  doorAnimationFailed,
  spatialTransitionFailed,
}

sealed class RailJourneyRuntimeTransactionResult {
  const RailJourneyRuntimeTransactionResult();

  String get outputPortId;
}

final class RailJourneyRuntimeTransactionCompleted
    extends RailJourneyRuntimeTransactionResult {
  const RailJourneyRuntimeTransactionCompleted({
    required this.alreadyApplied,
    this.transition,
  });

  final bool alreadyApplied;
  final RailJourneyRuntimeTransition? transition;

  @override
  String get outputPortId => 'completed';
}

final class RailJourneyRuntimeTransactionBlocked
    extends RailJourneyRuntimeTransactionResult {
  const RailJourneyRuntimeTransactionBlocked({
    required this.reason,
    this.runtimeResult,
  });

  final RailJourneyRuntimeTransactionBlockReason reason;
  final RailJourneyRuntimeBlocked? runtimeResult;

  @override
  String get outputPortId => 'blocked';
}

final class RailJourneyRuntimeTransaction {
  const RailJourneyRuntimeTransaction({
    this.coordinator = const RailJourneyRuntimeCoordinator(),
  });

  final RailJourneyRuntimeCoordinator coordinator;

  Future<RailJourneyRuntimeTransactionResult> execute({
    required SceneRailJourneyInteractiveCommand command,
    required String operationInstanceId,
    required RailJourneyCatalog catalog,
    required GameState gameState,
    required RailJourneyDoorAnimation animateDoor,
    required RailJourneySpatialTransition performTransition,
    required RailJourneyProgressCommit commitProgress,
    required RailJourneyRuntimeRollback rollback,
  }) async {
    final runtimeResult = coordinator.execute(
      command: command,
      operationInstanceId: operationInstanceId,
      catalog: catalog,
      gameState: gameState,
    );
    if (runtimeResult is RailJourneyRuntimeBlocked) {
      return RailJourneyRuntimeTransactionBlocked(
        reason: RailJourneyRuntimeTransactionBlockReason.runtimeBlocked,
        runtimeResult: runtimeResult,
      );
    }

    final completed = runtimeResult as RailJourneyRuntimeCompleted;
    final transition = completed.transition;
    if (completed.alreadyApplied) {
      if (transition != null) {
        return const RailJourneyRuntimeTransactionBlocked(
          reason: RailJourneyRuntimeTransactionBlockReason.replayTransition,
        );
      }
      return const RailJourneyRuntimeTransactionCompleted(
        alreadyApplied: true,
      );
    }

    var mutationStarted = false;
    try {
      if (transition != null) {
        final animated = await animateDoor(
          transition.sourceDoorPlacedElementId,
        );
        if (!animated) {
          return const RailJourneyRuntimeTransactionBlocked(
            reason:
                RailJourneyRuntimeTransactionBlockReason.doorAnimationFailed,
          );
        }
        mutationStarted = true;
        final transitioned = await performTransition(transition);
        if (!transitioned) {
          await rollback();
          mutationStarted = false;
          return const RailJourneyRuntimeTransactionBlocked(
            reason: RailJourneyRuntimeTransactionBlockReason
                .spatialTransitionFailed,
          );
        }
      }

      mutationStarted = true;
      await commitProgress(completed.gameState.railJourneyProgress);
      mutationStarted = false;
      return RailJourneyRuntimeTransactionCompleted(
        alreadyApplied: false,
        transition: transition,
      );
    } catch (error, stackTrace) {
      if (mutationStarted) {
        await rollback();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
