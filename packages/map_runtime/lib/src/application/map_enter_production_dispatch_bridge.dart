import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'map_activation.dart';

sealed class MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchResult(this.activation);

  final MapActivation activation;
}

final class MapEnterProductionDispatchLegacyFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchLegacyFallback(super.activation);
}

final class MapEnterProductionDispatchDuplicate
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchDuplicate(super.activation);
}

final class MapEnterProductionDispatchNoFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchNoFallback(
    super.activation, [
    this.reason,
  ]);

  final Object? reason;
}

final class MapEnterProductionDispatchV2Handled
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchV2Handled(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionSucceeded execution;
}

final class MapEnterProductionDispatchClaimedIneligible
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchClaimedIneligible(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionClaimedButIneligible execution;
}

final class MapEnterProductionDispatchStale
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchStale(super.activation);
}

final class MapEnterProductionDispatchAuthorityBlocked
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchAuthorityBlocked(
    super.activation,
    this.authority,
  );

  final NarrativeEventDispatchAuthorityBlocked authority;
}

final class MapEnterProductionDispatchFailed
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchFailed(
    super.activation,
    this.failure, [
    this.stackTrace,
  ]);

  final Object failure;
  final StackTrace? stackTrace;
}

/// Application boundary between completed map activations and Event V2.
///
/// V2-19 owns map-enter dispatch and runtime activation deduplication. Outcome
/// reentrancy stays in V2-22, while save/load orchestration remains FG-014; the
/// save-restore callback here is only the ordering seam between those lots.
final class MapEnterProductionDispatchBridge {
  MapEnterProductionDispatchBridge({
    required NarrativeEventStateTransactions stateTransactions,
    required GameState Function() currentGameState,
    required void Function(GameState gameState) onGameStateCommitted,
    required Future<NarrativeEventDispatchAuthorityPreparation> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
    ) prepareAuthority,
    required NarrativeSceneExecutionCallback executeScene,
    required Future<void> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
      GameState gameState,
    ) legacyFallback,
    required NarrativeEventActivityPort activityPort,
    required Future<void> Function(MapActivation activation)
        beforeSaveRestoreDispatch,
    required bool Function(String activationId) isCurrentActivation,
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
        _beforeSaveRestoreDispatch = beforeSaveRestoreDispatch,
        _isCurrentActivation = isCurrentActivation,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final GameState Function() _currentGameState;
  final void Function(GameState gameState) _onGameStateCommitted;
  final Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) _prepareAuthority;
  final NarrativeSceneExecutionCallback _executeScene;
  final Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) _legacyFallback;
  final NarrativeEventActivityPort _activityPort;
  final Future<void> Function(MapActivation activation)
      _beforeSaveRestoreDispatch;
  final bool Function(String activationId) _isCurrentActivation;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;

  // add() happens before the first await, so concurrent callers in the same
  // isolate cannot both claim the same completed activation.
  final Set<String> _claimedActivationIds = <String>{};

  Future<MapEnterProductionDispatchResult> dispatchCompletedActivation(
    MapActivation activation,
  ) async {
    late final String activationId;
    late final NarrativeEventOccurrence occurrence;
    try {
      activationId = activation.activationId;
      occurrence = activation.occurrence;

      // Only the current activation needs to stay claimed. This keeps the set
      // bounded across map transitions while retaining the current ID so a
      // concurrent or repeated dispatch remains a duplicate.
      _claimedActivationIds.removeWhere(
        (claimedId) => !_isCurrentActivation(claimedId),
      );
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (!_claimedActivationIds.add(activationId)) {
        return MapEnterProductionDispatchDuplicate(activation);
      }

      // The runtime GameState is authoritative at activation completion. Put
      // that exact snapshot behind the serialized F1 transaction boundary
      // before planning or executing Event V2.
      await _stateTransactions.transact<GameState>((_) {
        final current = _currentGameState();
        return NarrativeEventStateTransaction.commit(current, current);
      });
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (activation.reason == MapActivationReason.saveRestore) {
        await _beforeSaveRestoreDispatch(activation);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        final latestGameState = await _stateTransactions.read();
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        _onGameStateCommitted(latestGameState);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
      }

      final preparation = await _prepareAuthority(activation, occurrence);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (preparation is NarrativeEventDispatchAuthorityBlocked) {
        return MapEnterProductionDispatchAuthorityBlocked(
          activation,
          preparation,
        );
      }
      final authority = preparation as NarrativeEventDispatchAuthorityReady;
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: _stateTransactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale before Scene execution.',
            );
          }
          final result = await _executeScene(request);
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale during Scene execution.',
            );
          }
          return result;
        },
        activityPort: _activityPort,
        executionIdFactory: _executionIdFactory,
        correlationIdFactory: _correlationIdFactory,
        deliveryIdFactory: _deliveryIdFactory,
        beforePlan: (gameState) => authority.applyMapActivationReset(
          gameState: gameState,
          activationId: activationId,
          mapId: activation.mapId,
          resetEligible: activation.reason == MapActivationReason.warp ||
              activation.reason == MapActivationReason.connection,
        ),
      );
      final execution = await coordinator.execute(authority: authority);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (execution is NarrativeEventExecutionSucceeded) {
        _onGameStateCommitted(execution.updatedGameState);
        return MapEnterProductionDispatchV2Handled(activation, execution);
      }
      if (execution is NarrativeEventExecutionClaimedButIneligible) {
        _onGameStateCommitted(await _stateTransactions.read());
        return MapEnterProductionDispatchClaimedIneligible(
          activation,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionFailed) {
        return MapEnterProductionDispatchFailed(
          activation,
          execution.failure,
          execution.failure.stackTrace,
        );
      }
      if (execution is NarrativeEventExecutionCancelled) {
        return MapEnterProductionDispatchNoFallback(activation, execution);
      }

      final noMatch = execution as NarrativeEventExecutionNoMatch;
      final gameState = await _stateTransactions.read();
      _onGameStateCommitted(gameState);
      if (!noMatch.legacyFallbackAllowed) {
        return MapEnterProductionDispatchNoFallback(activation, noMatch);
      }
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      await _legacyFallback(activation, occurrence, gameState);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      return MapEnterProductionDispatchLegacyFallback(activation);
    } catch (error, stackTrace) {
      // Preparation, pre-hooks, callbacks and legacy failures all stay closed:
      // no secondary dispatch path is attempted after an infrastructure error.
      return MapEnterProductionDispatchFailed(activation, error, stackTrace);
    }
  }

  MapEnterProductionDispatchStale _stale(
    MapActivation activation,
    String activationId,
  ) {
    _claimedActivationIds.remove(activationId);
    return MapEnterProductionDispatchStale(activation);
  }
}
