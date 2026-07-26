import 'package:map_core/map_core.dart';

import 'narrative_event_dispatch_planner.dart';
import 'narrative_event_state_transactions.dart';

enum NarrativeEventActivity {
  idle,
  dispatching,
  sceneActive,
  sceneSuspended,
  outboxProcessing,
}

abstract interface class NarrativeEventActivityPort {
  Future<T> runWithActivity<T>(
    NarrativeEventActivity activity,
    Future<T> Function() action,
  );
}

final class NoopNarrativeEventActivityPort
    implements NarrativeEventActivityPort {
  @override
  Future<T> runWithActivity<T>(
    NarrativeEventActivity activity,
    Future<T> Function() action,
  ) {
    return action();
  }
}

final class NarrativeSceneExecutionRequest {
  const NarrativeSceneExecutionRequest({
    required this.eventId,
    required this.sceneId,
    required this.executionId,
    required this.gameState,
  });

  final String eventId;
  final String sceneId;
  final String executionId;
  final GameState gameState;
}

typedef NarrativeSceneExecutionCallback = Future<NarrativeSceneExecutionResult>
    Function(NarrativeSceneExecutionRequest request);

sealed class NarrativeSceneExecutionResult {
  const NarrativeSceneExecutionResult();

  factory NarrativeSceneExecutionResult.completed({
    required GameState updatedGameState,
    required List<NarrativeOutcomeRef> qualifiedOutcomes,
    SceneFinishGameConsequence? gameCompletion,
  }) {
    return NarrativeSceneExecutionCompleted(
      updatedGameState: updatedGameState,
      qualifiedOutcomes: qualifiedOutcomes,
      gameCompletion: gameCompletion,
    );
  }

  factory NarrativeSceneExecutionResult.failed(Object failure) {
    return NarrativeSceneExecutionFailed(failure);
  }

  factory NarrativeSceneExecutionResult.cancelled([Object? reason]) {
    return NarrativeSceneExecutionCancelled(reason);
  }
}

final class NarrativeSceneExecutionCompleted
    extends NarrativeSceneExecutionResult {
  NarrativeSceneExecutionCompleted({
    required this.updatedGameState,
    required List<NarrativeOutcomeRef> qualifiedOutcomes,
    this.gameCompletion,
  }) : qualifiedOutcomes = List.unmodifiable(qualifiedOutcomes);

  final GameState updatedGameState;
  final List<NarrativeOutcomeRef> qualifiedOutcomes;
  final SceneFinishGameConsequence? gameCompletion;
}

final class NarrativeSceneExecutionFailed
    extends NarrativeSceneExecutionResult {
  const NarrativeSceneExecutionFailed(this.failure);

  final Object failure;
}

final class NarrativeSceneExecutionCancelled
    extends NarrativeSceneExecutionResult {
  const NarrativeSceneExecutionCancelled(this.reason);

  final Object? reason;
}

enum NarrativeEventExecutionFailureKind {
  sceneFailure,
  sceneCallbackException,
  orchestrationException,
}

final class NarrativeEventExecutionFailure {
  const NarrativeEventExecutionFailure({
    required this.kind,
    required this.cause,
    this.stackTrace,
  });

  final NarrativeEventExecutionFailureKind kind;
  final Object cause;
  final StackTrace? stackTrace;
}

sealed class NarrativeEventExecutionResult {
  const NarrativeEventExecutionResult();
}

final class NarrativeEventExecutionNoMatch
    extends NarrativeEventExecutionResult {
  const NarrativeEventExecutionNoMatch(this.decision);

  final NarrativeEventDispatchNoMatch decision;

  bool get legacyFallbackAllowed => decision.legacyFallbackAllowed;
}

final class NarrativeEventExecutionClaimedButIneligible
    extends NarrativeEventExecutionResult {
  const NarrativeEventExecutionClaimedButIneligible(this.decision);

  final NarrativeEventDispatchClaimedButIneligible decision;
}

final class NarrativeEventExecutionSucceeded
    extends NarrativeEventExecutionResult {
  const NarrativeEventExecutionSucceeded({
    required this.eventId,
    required this.executionId,
    required this.rootCorrelationId,
    required this.updatedGameState,
  });

  final String eventId;
  final String executionId;
  final String rootCorrelationId;
  final GameState updatedGameState;
}

final class NarrativeEventExecutionFailed
    extends NarrativeEventExecutionResult {
  const NarrativeEventExecutionFailed(this.failure);

  final NarrativeEventExecutionFailure failure;
}

final class NarrativeEventExecutionCancelled
    extends NarrativeEventExecutionResult {
  const NarrativeEventExecutionCancelled(this.reason);

  final Object? reason;
}

typedef NarrativeExecutionIdFactory = String Function();
typedef NarrativeCorrelationIdFactory = String Function();
typedef NarrativeDeliveryIdFactory = String Function();
typedef NarrativeEventPrePlanStateTransform = GameState Function(
  GameState gameState,
);

final class NarrativeEventExecutionCoordinator {
  NarrativeEventExecutionCoordinator({
    required NarrativeEventStateTransactions stateTransactions,
    required NarrativeEventDispatchPlanner planner,
    required NarrativeSceneExecutionCallback executeScene,
    required NarrativeEventActivityPort activityPort,
    required NarrativeExecutionIdFactory executionIdFactory,
    required NarrativeCorrelationIdFactory correlationIdFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
    NarrativeEventPrePlanStateTransform? beforePlan,
  })  : _stateTransactions = stateTransactions,
        _planner = planner,
        _executeScene = executeScene,
        _activityPort = activityPort,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory,
        _beforePlan = beforePlan;

  final NarrativeEventStateTransactions _stateTransactions;
  final NarrativeEventDispatchPlanner _planner;
  final NarrativeSceneExecutionCallback _executeScene;
  final NarrativeEventActivityPort _activityPort;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;
  final NarrativeEventPrePlanStateTransform? _beforePlan;

  Future<NarrativeEventExecutionResult> execute({
    required NarrativeEventDispatchAuthorityReady authority,
    Set<String> inFlightNarrativeEventIds = const <String>{},
  }) async {
    try {
      return await _activityPort.runWithActivity(
        NarrativeEventActivity.dispatching,
        () => _stateTransactions.transact(
          (gameState) => _executeTransaction(
            authority,
            gameState,
            inFlightNarrativeEventIds,
          ),
        ),
      );
    } catch (error, stackTrace) {
      return NarrativeEventExecutionFailed(
        NarrativeEventExecutionFailure(
          kind: NarrativeEventExecutionFailureKind.orchestrationException,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<NarrativeEventStateTransactionDecision<NarrativeEventExecutionResult>>
      _executeTransaction(
    NarrativeEventDispatchAuthorityReady authority,
    GameState gameState,
    Set<String> inFlightNarrativeEventIds,
  ) async {
    final planningState = _beforePlan?.call(gameState) ?? gameState;
    final decision = _planner.plan(
      authority: authority,
      gameState: planningState,
      inFlightNarrativeEventIds: inFlightNarrativeEventIds,
    );
    if (decision is NarrativeEventDispatchNoMatch) {
      final result = NarrativeEventExecutionNoMatch(decision);
      return planningState == gameState
          ? NarrativeEventStateTransaction.rollback(result)
          : NarrativeEventStateTransaction.commit(planningState, result);
    }
    if (decision is NarrativeEventDispatchClaimedButIneligible) {
      final result = NarrativeEventExecutionClaimedButIneligible(decision);
      return planningState == gameState
          ? NarrativeEventStateTransaction.rollback(result)
          : NarrativeEventStateTransaction.commit(planningState, result);
    }
    final handled = decision as NarrativeEventDispatchHandled;
    final executionId = _executionIdFactory();
    final rootCorrelationId =
        authority.occurrence.rootCorrelationId ?? _correlationIdFactory();
    NarrativeSceneExecutionResult sceneResult;
    try {
      sceneResult = await _activityPort.runWithActivity(
        NarrativeEventActivity.sceneActive,
        () => _executeScene(
          NarrativeSceneExecutionRequest(
            eventId: handled.eventId,
            sceneId: handled.sceneId,
            executionId: executionId,
            gameState: planningState,
          ),
        ),
      );
    } catch (error, stackTrace) {
      return NarrativeEventStateTransaction.rollback(
        NarrativeEventExecutionFailed(
          NarrativeEventExecutionFailure(
            kind: NarrativeEventExecutionFailureKind.sceneCallbackException,
            cause: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
    if (sceneResult is NarrativeSceneExecutionFailed) {
      return NarrativeEventStateTransaction.rollback(
        NarrativeEventExecutionFailed(
          NarrativeEventExecutionFailure(
            kind: NarrativeEventExecutionFailureKind.sceneFailure,
            cause: sceneResult.failure,
          ),
        ),
      );
    }
    if (sceneResult is NarrativeSceneExecutionCancelled) {
      return NarrativeEventStateTransaction.rollback(
        NarrativeEventExecutionCancelled(sceneResult.reason),
      );
    }
    final completed = sceneResult as NarrativeSceneExecutionCompleted;
    final updatedState = _completeSuccessfulExecution(
      authority: authority,
      handled: handled,
      completed: completed,
      executionId: executionId,
      rootCorrelationId: rootCorrelationId,
    );
    return NarrativeEventStateTransaction.commit(
      updatedState,
      NarrativeEventExecutionSucceeded(
        eventId: handled.eventId,
        executionId: executionId,
        rootCorrelationId: rootCorrelationId,
        updatedGameState: updatedState,
      ),
    );
  }

  GameState _completeSuccessfulExecution({
    required NarrativeEventDispatchAuthorityReady authority,
    required NarrativeEventDispatchHandled handled,
    required NarrativeSceneExecutionCompleted completed,
    required String executionId,
    required String rootCorrelationId,
  }) {
    final progress = completed.updatedGameState.narrativeEventProgress;
    final consumed = {...progress.consumedNarrativeEventIds};
    if (handled.reusePolicy == NarrativeEventReusePolicy.oneShot) {
      consumed.add(handled.eventId);
    }
    final depth = authority.occurrence.depth == null
        ? 0
        : authority.occurrence.depth! + 1;
    final pending = [
      ...progress.pendingNarrativeOutcomeDeliveries,
      for (final outcome in completed.qualifiedOutcomes)
        NarrativeOutcomeDelivery(
          deliveryId: _deliveryIdFactory(),
          outcome: outcome,
          causationExecutionId: executionId,
          rootCorrelationId: rootCorrelationId,
          depth: depth,
          attemptCount: 0,
        ),
    ];
    return completed.updatedGameState.copyWith(
      narrativeEventProgress: progress.copyWith(
        consumedNarrativeEventIds: consumed,
        pendingNarrativeOutcomeDeliveries: pending,
      ),
    );
  }
}
