import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

sealed class NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchResult(
    this.occurrenceId,
    this.occurrence,
  );

  final String occurrenceId;
  final NarrativeEventOccurrence occurrence;
}

final class NarrativeSpatialProductionDispatchLegacyFallback
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchLegacyFallback(
    super.occurrenceId,
    super.occurrence,
  );
}

final class NarrativeSpatialProductionDispatchDuplicate
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchDuplicate(
    super.occurrenceId,
    super.occurrence,
  );
}

final class NarrativeSpatialProductionDispatchNoFallback
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchNoFallback(
    super.occurrenceId,
    super.occurrence, [
    this.reason,
  ]);

  final Object? reason;
}

final class NarrativeSpatialProductionDispatchV2Handled
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchV2Handled(
    super.occurrenceId,
    super.occurrence,
    this.execution,
  );

  final NarrativeEventExecutionSucceeded execution;
}

final class NarrativeSpatialProductionDispatchClaimedIneligible
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchClaimedIneligible(
    super.occurrenceId,
    super.occurrence,
    this.execution,
  );

  final NarrativeEventExecutionClaimedButIneligible execution;
}

final class NarrativeSpatialProductionDispatchStale
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchStale(
    super.occurrenceId,
    super.occurrence,
  );
}

final class NarrativeSpatialProductionDispatchAuthorityBlocked
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchAuthorityBlocked(
    super.occurrenceId,
    super.occurrence,
    this.authority,
  );

  final NarrativeEventDispatchAuthorityBlocked authority;
}

final class NarrativeSpatialProductionDispatchFailed
    extends NarrativeSpatialProductionDispatchResult {
  const NarrativeSpatialProductionDispatchFailed(
    super.occurrenceId,
    super.occurrence,
    this.failure, [
    this.stackTrace,
  ]);

  final Object failure;
  final StackTrace? stackTrace;
}

typedef NarrativeSpatialAuthorityPreparation
    = Future<NarrativeEventDispatchAuthorityPreparation> Function(
  String occurrenceId,
  NarrativeEventOccurrence occurrence,
);

typedef NarrativeSpatialLegacyFallback = Future<void> Function(
  String occurrenceId,
  NarrativeEventOccurrence occurrence,
  GameState gameState,
);

/// Production boundary shared by entity-interaction and trigger-entry hooks.
///
/// One stable [occurrenceId] is claimed before the first asynchronous boundary.
/// Event V2 owns every claimed or attempted candidate; legacy fallback is
/// reachable only for an authority-approved no-match decision.
final class NarrativeSpatialProductionDispatchBridge {
  NarrativeSpatialProductionDispatchBridge({
    required NarrativeEventStateTransactions stateTransactions,
    required GameState Function() currentGameState,
    required void Function(GameState gameState) onGameStateCommitted,
    required NarrativeSpatialAuthorityPreparation prepareAuthority,
    required NarrativeSceneExecutionCallback executeScene,
    required NarrativeSpatialLegacyFallback legacyFallback,
    required NarrativeEventActivityPort activityPort,
    required bool Function(String occurrenceId) isCurrentOccurrence,
    required NarrativeExecutionIdFactory executionIdFactory,
    required NarrativeCorrelationIdFactory correlationIdFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
  })  : _stateTransactions = stateTransactions,
        _currentGameState = currentGameState,
        _onGameStateCommitted = onGameStateCommitted,
        _prepareAuthority = prepareAuthority,
        _executeScene = executeScene,
        _legacyFallback = legacyFallback,
        _activityPort = activityPort,
        _isCurrentOccurrence = isCurrentOccurrence,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final GameState Function() _currentGameState;
  final void Function(GameState gameState) _onGameStateCommitted;
  final NarrativeSpatialAuthorityPreparation _prepareAuthority;
  final NarrativeSceneExecutionCallback _executeScene;
  final NarrativeSpatialLegacyFallback _legacyFallback;
  final NarrativeEventActivityPort _activityPort;
  final bool Function(String occurrenceId) _isCurrentOccurrence;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;

  final Set<String> _claimedOccurrenceIds = <String>{};

  Future<NarrativeSpatialProductionDispatchResult> dispatch({
    required String occurrenceId,
    required NarrativeEventOccurrence occurrence,
  }) async {
    try {
      _validateOccurrence(occurrenceId, occurrence);

      // Claiming happens before the first await, so concurrent callers cannot
      // execute or fall back twice for the same production occurrence.
      _claimedOccurrenceIds.removeWhere(
        (claimedId) => !_isCurrentOccurrence(claimedId),
      );
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      if (!_claimedOccurrenceIds.add(occurrenceId)) {
        return NarrativeSpatialProductionDispatchDuplicate(
          occurrenceId,
          occurrence,
        );
      }

      // The runtime snapshot is authoritative when the spatial occurrence is
      // captured. Install it transactionally before authority planning.
      await _stateTransactions.transact<GameState>((_) {
        final current = _currentGameState();
        return NarrativeEventStateTransaction.commit(current, current);
      });
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }

      final preparation = await _prepareAuthority(occurrenceId, occurrence);
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      if (preparation is NarrativeEventDispatchAuthorityBlocked) {
        return NarrativeSpatialProductionDispatchAuthorityBlocked(
          occurrenceId,
          occurrence,
          preparation,
        );
      }
      final authority = preparation as NarrativeEventDispatchAuthorityReady;
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: _stateTransactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          if (!_isCurrentOccurrence(occurrenceId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Spatial occurrence became stale before Scene execution.',
            );
          }
          final result = await _executeScene(request);
          if (!_isCurrentOccurrence(occurrenceId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Spatial occurrence became stale during Scene execution.',
            );
          }
          return result;
        },
        activityPort: _activityPort,
        executionIdFactory: _executionIdFactory,
        correlationIdFactory: _correlationIdFactory,
        deliveryIdFactory: _deliveryIdFactory,
      );
      final execution = await coordinator.execute(authority: authority);
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }

      if (execution is NarrativeEventExecutionSucceeded) {
        _onGameStateCommitted(execution.updatedGameState);
        if (!_isCurrentOccurrence(occurrenceId)) {
          return _stale(occurrenceId, occurrence);
        }
        return NarrativeSpatialProductionDispatchV2Handled(
          occurrenceId,
          occurrence,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionClaimedButIneligible) {
        return NarrativeSpatialProductionDispatchClaimedIneligible(
          occurrenceId,
          occurrence,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionFailed) {
        return NarrativeSpatialProductionDispatchFailed(
          occurrenceId,
          occurrence,
          execution.failure,
          execution.failure.stackTrace,
        );
      }
      if (execution is NarrativeEventExecutionCancelled) {
        return NarrativeSpatialProductionDispatchNoFallback(
          occurrenceId,
          occurrence,
          execution,
        );
      }

      final noMatch = execution as NarrativeEventExecutionNoMatch;
      if (!noMatch.legacyFallbackAllowed) {
        return NarrativeSpatialProductionDispatchNoFallback(
          occurrenceId,
          occurrence,
          noMatch,
        );
      }

      final gameState = await _stateTransactions.read();
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      await _legacyFallback(occurrenceId, occurrence, gameState);
      if (!_isCurrentOccurrence(occurrenceId)) {
        return _stale(occurrenceId, occurrence);
      }
      return NarrativeSpatialProductionDispatchLegacyFallback(
        occurrenceId,
        occurrence,
      );
    } catch (error, stackTrace) {
      // Infrastructure and host callback failures stay fail-closed: a second
      // dispatch path must never be attempted after partial execution.
      return NarrativeSpatialProductionDispatchFailed(
        occurrenceId,
        occurrence,
        error,
        stackTrace,
      );
    }
  }

  void _validateOccurrence(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
  ) {
    if (occurrenceId.trim().isEmpty) {
      throw ArgumentError.value(
        occurrenceId,
        'occurrenceId',
        'must be non-empty',
      );
    }
    if (occurrence.source.kind != NarrativeEventSourceKind.entityInteract &&
        occurrence.source.kind != NarrativeEventSourceKind.triggerEnter) {
      throw ArgumentError.value(
        occurrence.source.kind,
        'occurrence.source.kind',
        'must be entityInteract or triggerEnter',
      );
    }
  }

  NarrativeSpatialProductionDispatchStale _stale(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
  ) {
    _claimedOccurrenceIds.remove(occurrenceId);
    return NarrativeSpatialProductionDispatchStale(occurrenceId, occurrence);
  }
}
