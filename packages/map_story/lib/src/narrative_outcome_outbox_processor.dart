import 'package:map_core/map_core.dart';

import 'narrative_event_execution_coordinator.dart';
import 'narrative_event_state_transactions.dart';

abstract interface class NarrativeOutcomeOutboxSnapshot {
  GameState get gameState;
  Set<String> get consumedNarrativeEventIds;
  List<NarrativeOutcomeDelivery> get pendingDeliveries;
  Set<String> get deliveredDeliveryIds;
  GameState replaceProgress(NarrativeEventProgress progress);
}

final class GameStateNarrativeOutcomeOutboxSnapshot
    implements NarrativeOutcomeOutboxSnapshot {
  const GameStateNarrativeOutcomeOutboxSnapshot(this.gameState);

  @override
  final GameState gameState;

  @override
  Set<String> get consumedNarrativeEventIds =>
      gameState.narrativeEventProgress.consumedNarrativeEventIds;

  @override
  List<NarrativeOutcomeDelivery> get pendingDeliveries =>
      gameState.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;

  @override
  Set<String> get deliveredDeliveryIds =>
      gameState.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds;

  @override
  GameState replaceProgress(NarrativeEventProgress progress) {
    return gameState.copyWith(narrativeEventProgress: progress);
  }
}

typedef NarrativeOutcomeOutboxSnapshotFactory = NarrativeOutcomeOutboxSnapshot
    Function(GameState gameState);

final class NarrativeOutcomeDispatchRequest {
  const NarrativeOutcomeDispatchRequest({
    required this.delivery,
    required this.occurrence,
    required this.gameState,
  });

  final NarrativeOutcomeDelivery delivery;
  final NarrativeEventOccurrence occurrence;
  final GameState gameState;
}

typedef NarrativeOutcomeDispatcher = Future<NarrativeOutcomeDispatchResult>
    Function(NarrativeOutcomeDispatchRequest request);

sealed class NarrativeOutcomeDispatchResult {
  const NarrativeOutcomeDispatchResult();

  factory NarrativeOutcomeDispatchResult.delivered({
    required GameState updatedGameState,
    List<NarrativeOutcomeRef> qualifiedChildOutcomes = const [],
    String? causationExecutionId,
  }) {
    return NarrativeOutcomeDispatchDelivered(
      updatedGameState: updatedGameState,
      qualifiedChildOutcomes: qualifiedChildOutcomes,
      causationExecutionId: causationExecutionId,
    );
  }

  factory NarrativeOutcomeDispatchResult.infrastructureFailureBeforePlanning(
    Object failure,
  ) {
    return NarrativeOutcomeDispatchInfrastructureFailureBeforePlanning(failure);
  }

  factory NarrativeOutcomeDispatchResult.terminalFailure(Object failure) {
    return NarrativeOutcomeDispatchTerminalFailure(failure);
  }
}

final class NarrativeOutcomeDispatchDelivered
    extends NarrativeOutcomeDispatchResult {
  NarrativeOutcomeDispatchDelivered({
    required this.updatedGameState,
    required List<NarrativeOutcomeRef> qualifiedChildOutcomes,
    required this.causationExecutionId,
  }) : qualifiedChildOutcomes = List.unmodifiable(qualifiedChildOutcomes);

  final GameState updatedGameState;
  final List<NarrativeOutcomeRef> qualifiedChildOutcomes;
  final String? causationExecutionId;
}

final class NarrativeOutcomeDispatchInfrastructureFailureBeforePlanning
    extends NarrativeOutcomeDispatchResult {
  const NarrativeOutcomeDispatchInfrastructureFailureBeforePlanning(
    this.failure,
  );

  final Object failure;
}

final class NarrativeOutcomeDispatchTerminalFailure
    extends NarrativeOutcomeDispatchResult {
  const NarrativeOutcomeDispatchTerminalFailure(this.failure);

  final Object failure;
}

enum NarrativeOutcomeTerminalReason {
  depthExceeded,
  retryLimitReached,
  dispatcherTerminalFailure,
  dispatcherException,
}

sealed class NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxProcessResult();
}

final class NarrativeOutcomeOutboxEmpty
    extends NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxEmpty();
}

final class NarrativeOutcomeOutboxBusy
    extends NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxBusy();
}

final class NarrativeOutcomeOutboxDelivered
    extends NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxDelivered({
    required this.delivery,
    required this.updatedGameState,
  });

  final NarrativeOutcomeDelivery delivery;
  final GameState updatedGameState;
}

final class NarrativeOutcomeOutboxRetryScheduled
    extends NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxRetryScheduled({
    required this.delivery,
    required this.failure,
    required this.updatedGameState,
  });

  final NarrativeOutcomeDelivery delivery;
  final Object failure;
  final GameState updatedGameState;
}

final class NarrativeOutcomeOutboxTerminalized
    extends NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxTerminalized({
    required this.delivery,
    required this.reason,
    required this.failure,
    required this.updatedGameState,
  });

  final NarrativeOutcomeDelivery delivery;
  final NarrativeOutcomeTerminalReason reason;
  final Object? failure;
  final GameState updatedGameState;
}

final class NarrativeOutcomeOutboxDataInconsistency
    extends NarrativeOutcomeOutboxProcessResult {
  const NarrativeOutcomeOutboxDataInconsistency({
    required this.delivery,
    required this.updatedGameState,
  });

  final NarrativeOutcomeDelivery delivery;
  final GameState updatedGameState;
  String get diagnosticCode => 'dataInconsistency';
}

final class NarrativeOutcomeOutboxProcessor {
  NarrativeOutcomeOutboxProcessor({
    required NarrativeEventStateTransactions stateTransactions,
    required NarrativeOutcomeDispatcher dispatcher,
    required NarrativeEventActivityPort activityPort,
    NarrativeOutcomeOutboxSnapshotFactory? snapshotFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
  })  : _stateTransactions = stateTransactions,
        _dispatcher = dispatcher,
        _activityPort = activityPort,
        _snapshotFactory = snapshotFactory ??
            ((gameState) => GameStateNarrativeOutcomeOutboxSnapshot(gameState)),
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final NarrativeOutcomeDispatcher _dispatcher;
  final NarrativeEventActivityPort _activityPort;
  final NarrativeOutcomeOutboxSnapshotFactory _snapshotFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;
  bool _processing = false;

  Future<NarrativeOutcomeOutboxProcessResult> processNext() {
    if (_processing) {
      return Future.value(const NarrativeOutcomeOutboxBusy());
    }
    _processing = true;
    return _processNext().whenComplete(() {
      _processing = false;
    });
  }

  Future<NarrativeOutcomeOutboxProcessResult> _processNext() {
    return _activityPort.runWithActivity(
      NarrativeEventActivity.outboxProcessing,
      () => _stateTransactions.serializeOutbox(_processExclusive),
    );
  }

  Future<NarrativeOutcomeOutboxProcessResult> _processExclusive() async {
    final initialState = await _stateTransactions.read();
    final snapshot = _snapshotFactory(initialState);
    if (snapshot.pendingDeliveries.isEmpty) {
      return const NarrativeOutcomeOutboxEmpty();
    }
    final delivery = snapshot.pendingDeliveries.first;
    if (snapshot.deliveredDeliveryIds.contains(delivery.deliveryId)) {
      return _commitDataInconsistency(delivery);
    }
    if (delivery.depth > 8) {
      return _commitTerminal(
        delivery,
        NarrativeOutcomeTerminalReason.depthExceeded,
        null,
      );
    }
    if (delivery.attemptCount >= 3) {
      return _commitTerminal(
        delivery,
        NarrativeOutcomeTerminalReason.retryLimitReached,
        null,
      );
    }
    NarrativeOutcomeDispatchResult dispatchResult;
    try {
      dispatchResult = await _dispatcher(
        NarrativeOutcomeDispatchRequest(
          delivery: delivery,
          occurrence: NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.outcomeReceived(delivery.outcome),
            rootCorrelationId: delivery.rootCorrelationId,
            depth: delivery.depth,
          ),
          gameState: snapshot.gameState,
        ),
      );
    } catch (error) {
      return _commitTerminal(
        delivery,
        NarrativeOutcomeTerminalReason.dispatcherException,
        error,
      );
    }
    if (dispatchResult
        is NarrativeOutcomeDispatchInfrastructureFailureBeforePlanning) {
      final failure = dispatchResult.failure;
      final nextAttemptCount = delivery.attemptCount + 1;
      if (nextAttemptCount >= 3) {
        return _commitTerminal(
          delivery,
          NarrativeOutcomeTerminalReason.retryLimitReached,
          failure,
        );
      }
      final retried = NarrativeOutcomeDelivery(
        deliveryId: delivery.deliveryId,
        outcome: delivery.outcome,
        causationExecutionId: delivery.causationExecutionId,
        rootCorrelationId: delivery.rootCorrelationId,
        depth: delivery.depth,
        attemptCount: nextAttemptCount,
      );
      return await _withCurrentDelivery(
        delivery,
        (currentSnapshot, _) {
          final updatedState = _replaceSnapshotProgress(
            currentSnapshot,
            pending: [
              retried,
              ...currentSnapshot.pendingDeliveries.skip(1),
            ],
            delivered: currentSnapshot.deliveredDeliveryIds,
          );
          return NarrativeEventStateTransaction.commit(
            updatedState,
            NarrativeOutcomeOutboxRetryScheduled(
              delivery: retried,
              failure: failure,
              updatedGameState: updatedState,
            ),
          );
        },
      );
    }
    if (dispatchResult is NarrativeOutcomeDispatchTerminalFailure) {
      return _commitTerminal(
        delivery,
        NarrativeOutcomeTerminalReason.dispatcherTerminalFailure,
        dispatchResult.failure,
      );
    }
    try {
      final delivered = dispatchResult as NarrativeOutcomeDispatchDelivered;
      return await _withCurrentDelivery(
        delivery,
        (currentSnapshot, currentDelivery) {
          final currentState = currentSnapshot.gameState;
          if (currentState != initialState &&
              currentState != delivered.updatedGameState) {
            return _dataInconsistency(currentSnapshot, currentDelivery);
          }
          final baseState = currentState == initialState
              ? delivered.updatedGameState
              : currentState;
          return _completeDelivery(
            currentSnapshot,
            currentDelivery,
            delivered,
            baseState,
          );
        },
      );
    } catch (error) {
      return _commitTerminal(
        delivery,
        NarrativeOutcomeTerminalReason.dispatcherException,
        error,
      );
    }
  }

  Future<NarrativeOutcomeOutboxProcessResult> _withCurrentDelivery(
    NarrativeOutcomeDelivery expected,
    NarrativeEventStateTransactionDecision<NarrativeOutcomeOutboxProcessResult>
        Function(
      NarrativeOutcomeOutboxSnapshot snapshot,
      NarrativeOutcomeDelivery delivery,
    ) callback,
  ) {
    return _stateTransactions.transact((gameState) {
      final snapshot = _snapshotFactory(gameState);
      if (snapshot.pendingDeliveries.isEmpty ||
          snapshot.pendingDeliveries.first.deliveryId != expected.deliveryId) {
        return NarrativeEventStateTransaction.rollback(
          NarrativeOutcomeOutboxDataInconsistency(
            delivery: expected,
            updatedGameState: gameState,
          ),
        );
      }
      return callback(snapshot, snapshot.pendingDeliveries.first);
    });
  }

  Future<NarrativeOutcomeOutboxProcessResult> _commitTerminal(
    NarrativeOutcomeDelivery delivery,
    NarrativeOutcomeTerminalReason reason,
    Object? failure,
  ) {
    return _withCurrentDelivery(
      delivery,
      (snapshot, current) => _terminalize(snapshot, current, reason, failure),
    );
  }

  Future<NarrativeOutcomeOutboxProcessResult> _commitDataInconsistency(
    NarrativeOutcomeDelivery delivery,
  ) {
    return _withCurrentDelivery(
      delivery,
      (snapshot, current) => _dataInconsistency(snapshot, current),
    );
  }

  NarrativeEventStateTransactionDecision<NarrativeOutcomeOutboxProcessResult>
      _dataInconsistency(
    NarrativeOutcomeOutboxSnapshot snapshot,
    NarrativeOutcomeDelivery delivery,
  ) {
    final updatedState = _replaceSnapshotProgress(
      snapshot,
      pending: [
        for (final pending in snapshot.pendingDeliveries)
          if (pending.deliveryId != delivery.deliveryId) pending,
      ],
      delivered: {...snapshot.deliveredDeliveryIds, delivery.deliveryId},
    );
    return NarrativeEventStateTransaction.commit(
      updatedState,
      NarrativeOutcomeOutboxDataInconsistency(
        delivery: delivery,
        updatedGameState: updatedState,
      ),
    );
  }

  NarrativeEventStateTransactionDecision<NarrativeOutcomeOutboxProcessResult>
      _completeDelivery(
    NarrativeOutcomeOutboxSnapshot snapshot,
    NarrativeOutcomeDelivery delivery,
    NarrativeOutcomeDispatchDelivered dispatchResult,
    GameState baseState,
  ) {
    final callbackProgress = baseState.narrativeEventProgress;
    final children = [
      for (final outcome in dispatchResult.qualifiedChildOutcomes)
        NarrativeOutcomeDelivery(
          deliveryId: _deliveryIdFactory(),
          outcome: outcome,
          causationExecutionId: dispatchResult.causationExecutionId,
          rootCorrelationId: delivery.rootCorrelationId,
          depth: delivery.depth + 1,
          attemptCount: 0,
        ),
    ];
    final delivered = {
      ...callbackProgress.deliveredNarrativeOutcomeDeliveryIds,
      ...snapshot.deliveredDeliveryIds,
      delivery.deliveryId,
    };
    final updatedState = baseState.copyWith(
      narrativeEventProgress: callbackProgress.copyWith(
        pendingNarrativeOutcomeDeliveries: [
          for (final pending
              in callbackProgress.pendingNarrativeOutcomeDeliveries)
            if (pending.deliveryId != delivery.deliveryId) pending,
          ...children,
        ],
        deliveredNarrativeOutcomeDeliveryIds: delivered,
      ),
    );
    return NarrativeEventStateTransaction.commit(
      updatedState,
      NarrativeOutcomeOutboxDelivered(
        delivery: delivery,
        updatedGameState: updatedState,
      ),
    );
  }

  NarrativeEventStateTransactionDecision<NarrativeOutcomeOutboxProcessResult>
      _terminalize(
    NarrativeOutcomeOutboxSnapshot snapshot,
    NarrativeOutcomeDelivery delivery,
    NarrativeOutcomeTerminalReason reason,
    Object? failure,
  ) {
    final updatedState = _replaceSnapshotProgress(
      snapshot,
      pending: snapshot.pendingDeliveries.skip(1).toList(growable: false),
      delivered: {...snapshot.deliveredDeliveryIds, delivery.deliveryId},
    );
    return NarrativeEventStateTransaction.commit(
      updatedState,
      NarrativeOutcomeOutboxTerminalized(
        delivery: delivery,
        reason: reason,
        failure: failure,
        updatedGameState: updatedState,
      ),
    );
  }

  GameState _replaceSnapshotProgress(
    NarrativeOutcomeOutboxSnapshot snapshot, {
    required List<NarrativeOutcomeDelivery> pending,
    required Set<String> delivered,
  }) {
    return snapshot.replaceProgress(
      snapshot.gameState.narrativeEventProgress.copyWith(
        consumedNarrativeEventIds: snapshot.consumedNarrativeEventIds,
        pendingNarrativeOutcomeDeliveries: pending,
        deliveredNarrativeOutcomeDeliveryIds: delivered,
      ),
    );
  }
}
