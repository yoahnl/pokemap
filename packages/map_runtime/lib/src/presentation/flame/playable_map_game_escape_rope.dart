part of 'playable_map_game.dart';

extension _PlayableMapEscapeRope on PlayableMapGame {
  void _recordEscapeReturnPointAfterTransfer(
    MapData sourceMap,
    GameState sourceState,
  ) {
    final anchor = escapeReturnPointAfterTransfer(
      sourceMap: sourceMap,
      targetMap: _bundle.map,
      sourceState: sourceState,
    );
    if (_gameState.escapeReturnPoint == anchor) return;
    _gameState = _gameState.copyWith(escapeReturnPoint: anchor);
    final workingSession = _activeNarrativeSceneWorkingSession;
    if (workingSession != null) {
      workingSession.gameState = workingSession.gameState.copyWith(
        escapeReturnPoint: anchor,
      );
    }
  }

  Future<bool> _usePlayerEscapeRope(
    ProjectItemDefinition item,
    GameState expectedState,
  ) async {
    if (_escapeRopeTransferInFlight ||
        _isRemoved ||
        !isLoaded ||
        _activeNarrativeSceneWorkingSession != null ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        _gameState.playerMovementMode != MovementMode.walk ||
        playerServiceGameStateSnapshot != expectedState) {
      return false;
    }
    final anchor = expectedState.escapeReturnPoint;
    if (anchor == null) return false;
    final issuedRevision = _gameStateRevision;
    final sourceMap = _bundle.map;
    late final RuntimeMapBundle target;
    _escapeRopeTransferInFlight = true;
    final wasPaused = isPaused;
    var mountedDestination = false;
    var completed = false;
    int? ownedRevision;
    GameState? ownedState;
    Bag? bagBeforeConsumption;
    var source = _RuntimeSpatialSnapshot(
      gameState: expectedState,
      bundle: _bundle,
      authoredBundle: _runtimeBundleByMapId[_activeMapId] ?? _bundle,
      world: _world,
      activeMapId: _activeMapId,
      previousMapId: _previousMapId,
      flowPhase: _flowPhase,
      currentMapActivationId: _currentMapActivationId,
      completedMapActivationDispatchCount: _completedMapActivationDispatchCount,
      lastCompletedMapActivation: _lastCompletedMapActivation,
    );
    try {
      target = await _loadRuntimeMapBundleCached(anchor.mapId);
      if (_isRemoved ||
          _gameStateRevision != issuedRevision ||
          playerServiceGameStateSnapshot != expectedState) {
        return false;
      }
      final evaluation = evaluateEscapeRopeAttempt(
        sourceMap: sourceMap,
        targetMap: target.map,
        gameState: expectedState,
        item: item,
        project: _bundle.manifest,
        validateArrival: false,
      );
      if (evaluation is! CanUseEscapeRope) return false;
      final ticket = EscapeRopeActionTicket(
        evaluation: evaluation,
        gameState: expectedState,
        sourceMap: sourceMap,
        targetMap: target.map,
        item: item,
        issuedAtStateRevision: issuedRevision,
      );
      final applied = commitEscapeRopeAction(
        ticket: ticket,
        sourceMap: sourceMap,
        targetMap: target.map,
        gameState: expectedState,
        item: item,
        currentStateRevision: _gameStateRevision,
        project: _bundle.manifest,
        validateArrival: false,
      );
      if (applied == null) return false;
      bool current(MapInstanceWorldState? instances) {
        if (instances != null) mountedDestination = true;
        if (_isRemoved || _activeMapId != sourceMap.id) return false;
        final state = playerServiceGameStateSnapshot;
        if (instances != null) {
          source = _RuntimeSpatialSnapshot(
            gameState: state.copyWith(
              mapInstanceWorldState: source.gameState.mapInstanceWorldState,
            ),
            bundle: source.bundle,
            authoredBundle: source.authoredBundle,
            world: _world,
            activeMapId: source.activeMapId,
            previousMapId: source.previousMapId,
            flowPhase: source.flowPhase,
            currentMapActivationId: source.currentMapActivationId,
            completedMapActivationDispatchCount:
                source.completedMapActivationDispatchCount,
            lastCompletedMapActivation: source.lastCompletedMapActivation,
          );
        }
        final checked = instances == null
            ? state
            : state.copyWith(
                mapInstanceWorldState: expectedState.mapInstanceWorldState,
              );
        return commitEscapeRopeAction(
              ticket: ticket,
              sourceMap: _bundle.map,
              targetMap: _runtimeBundleByMapId[target.map.id]?.map,
              gameState: checked,
              item: item,
              currentStateRevision: _gameStateRevision,
              project: _bundle.manifest,
              validateArrival: false,
            ) !=
            null;
      }

      bool destinationCurrent(MapActivation activation) {
        if (_isRemoved || _activeMapId != target.map.id) return false;
        if (ownedRevision == null) {
          ownedRevision = _gameStateRevision;
          ownedState = _gameState;
        }
        if (_gameStateRevision != ownedRevision) return false;
        ownedState = _gameState;
        return true;
      }

      if (wasPaused) resumeEngine();
      final transferred = await _handleWarp(
        TriggeredWarp(
          triggerMode: MapWarpTriggerMode.onBump,
          warpId: 'escape_rope.${item.id}',
          targetMapId: anchor.mapId,
          targetPos: anchor.position,
        ),
        arrivalFacing: anchor.facing,
        arrivalMovementMode: MovementMode.walk,
        revalidateArrivalAfterMount: true,
        transferGuard: current,
        destinationTransferGuard: destinationCurrent,
      );
      if (!transferred || _isRemoved) return false;
      if (!isSceneWarpArrivalAllowed(
        world: _world,
        project: _bundle.manifest,
      )) {
        throw StateError('The Escape Rope arrival is obstructed.');
      }
      ownedRevision = _gameStateRevision;
      ownedState = _gameState;
      final committed = await _narrativeStateTransactions.transact<GameState>((
        currentState,
      ) {
        if (_isRemoved ||
            _gameStateRevision != ownedRevision ||
            _gameState != ownedState) {
          throw StateError('The Escape Rope transfer is stale.');
        }
        bagBeforeConsumption = currentState.bag;
        final consumption = const BagOperations().consume(
          BagConsumeRequest(
            bag: currentState.bag,
            itemId: item.id,
            quantity: 1,
            itemTags: item.tags,
            reason: ItemConsumptionReason.appliedEffect,
          ),
        );
        if (!consumption.isSuccess) {
          throw StateError('The Escape Rope inventory changed.');
        }
        final next = _captureGameStateFromWorld(baseState: currentState)
            .copyWith(bag: consumption.bag, escapeReturnPoint: null);
        return NarrativeEventStateTransaction.commit(next, next);
      });
      _applyNarrativeGameState(committed);
      _syncGameStateFromWorld();
      ownedRevision = _gameStateRevision;
      ownedState = _gameState;
      if (_hasCheckpointUnsafeRuntimeWork) {
        throw StateError('The Escape Rope destination is not checkpoint-safe.');
      }
      final writer = overworldCheckpointWriter;
      if (writer != null) {
        await writer(_gameState);
      } else if (!await _saveGameUseCase.execute(_gameState)) {
        throw StateError('The Escape Rope checkpoint failed.');
      }
      completed = true;
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('[escape_rope] failed: $error\n$stackTrace');
      return false;
    } finally {
      try {
        final ownsState = ownedRevision == null
            ? _gameStateRevision == issuedRevision ||
                  (mountedDestination && _activeMapId == source.activeMapId)
            : _gameStateRevision == ownedRevision && _gameState == ownedState;
        if (!completed &&
            !_isRemoved &&
            !ownsState &&
            bagBeforeConsumption != null &&
            ownedState != null &&
            _gameState.bag == ownedState!.bag) {
          final newer = _gameState;
          final newerRevision = _gameStateRevision;
          final refunded = await _narrativeStateTransactions
              .transact<GameState?>((current) {
                if (_isRemoved ||
                    _gameStateRevision != newerRevision ||
                    _gameState != newer ||
                    current.bag != ownedState!.bag) {
                  return NarrativeEventStateTransaction.rollback(null);
                }
                final next = _captureGameStateFromWorld(baseState: newer)
                    .copyWith(bag: bagBeforeConsumption!);
                return NarrativeEventStateTransaction.commit(next, next);
              });
          if (refunded != null) {
            _applyNarrativeGameState(refunded);
            _syncGameStateFromWorld();
          }
        }
        if (!completed &&
            !_isRemoved &&
            ownsState &&
            (mountedDestination ||
                _activeMapId != source.activeMapId ||
                !_loadedMapsById.containsKey(source.activeMapId))) {
          final restoreRevision = _gameStateRevision;
          final restoreState = _gameState;
          bool ownsRestore() =>
              _gameStateRevision == restoreRevision &&
              (_gameState == restoreState || _gameState == source.gameState);
          if (!await _restoreRuntimeSpatialSnapshot(
            source,
            commitNarrativeState: true,
            restorationGuard: ownsRestore,
          )) {
            throw StateError('The Escape Rope source could not be restored.');
          }
        }
      } finally {
        if (wasPaused && !_isRemoved) pauseEngine();
        _escapeRopeTransferInFlight = false;
      }
    }
  }
}
