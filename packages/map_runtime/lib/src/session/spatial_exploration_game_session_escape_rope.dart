part of 'spatial_exploration_game_session_runtime.dart';

extension _SpatialEscapeRope on SpatialExplorationGameSessionRuntime {
  EscapeReturnPoint? _escapeAnchorAfterTransfer(
    MapData target,
    GameState state,
  ) {
    final source = _escapeTransferSource;
    if (source == null || source.map.id == target.id)
      return state.escapeReturnPoint;
    _escapeTransferSource = null;
    return escapeReturnPointAfterTransfer(
      sourceMap: source.map,
      targetMap: target,
      sourceState: source.state,
    );
  }

  Future<bool> _useSpatialEscapeRope(
    ProjectItemDefinition item,
    GameState expected,
  ) async {
    final session = _session;
    final writer = _commitCheckpoint;
    if (_disposed ||
        _stopped ||
        session == null ||
        writer == null ||
        !descriptor.grantedCapabilities.contains(
          OverworldItemCapabilities.spatialEscapeRopeCapabilityId,
        ) ||
        _escapeRopeInFlight ||
        _materializingState ||
        _gameplayOperations != 0 ||
        _sceneStateReader != null ||
        gameStateSnapshot != expected)
      return false;
    final source = _gameState!;
    final sourceMap = session.bundle.map;
    final target = _mapsById[source.escapeReturnPoint?.mapId];
    final evaluation = evaluateEscapeRopeAttempt(
      sourceMap: sourceMap,
      targetMap: target,
      gameState: expected,
      item: item,
      project: session.bundle.manifest,
      validateArrival: false,
    );
    if (evaluation is! CanUseEscapeRope || target == null) return false;
    final revision = session.mapRevision.value;
    final applied = commitEscapeRopeAction(
      ticket: EscapeRopeActionTicket(
        evaluation: evaluation,
        gameState: expected,
        sourceMap: sourceMap,
        targetMap: target,
        item: item,
        issuedAtStateRevision: revision,
      ),
      sourceMap: sourceMap,
      targetMap: target,
      gameState: source,
      item: item,
      currentStateRevision: revision,
      project: session.bundle.manifest,
      validateArrival: false,
    );
    if (applied == null) return false;
    var projected = applied.copyWith(
      mapInstanceWorldState: !_usesFieldObstacleInstances
          ? applied.mapInstanceWorldState
          : setupDifferentMapInstance(
              state: applied.mapInstanceWorldState,
              targetMapId: target.id,
              allocateId: (_) =>
                  _runtimeIds.generate(existingRecords: const []),
            ),
    );
    _escapeRopeInFlight = true;
    _materializingState = true;
    _escapeTransferSource = null;
    try {
      await _withSceneState(
        () => projected,
        (state) => projected = state,
        () async {
          await session.restoreGameState(
            projected,
            compensatePendingScene: true,
            restorePlayerAvatar: false,
          );
          _ensureGameplayActive();
          if (!identical(session, _session) ||
              _gameState != source ||
              session.bundle.map.id != target.id ||
              session.mapRevision.value != revision + 1 ||
              session.movement.spatialPosition !=
                  evaluation.arrival.spatialPosition ||
              session.movement.facing != evaluation.arrival.facing ||
              !session.movement.isPositionTraversable) {
            throw StateError(
              'The spatial Escape Rope arrival is stale or obstructed.',
            );
          }
          ensureRuntimeBagCapacity(
            state: projected,
            capacity: session.bundle.manifest.bagCapacity,
            itemCatalog: _bagItemCatalog,
          );
          await _activityGate.runCheckpoint(
            NarrativeRuntimeCheckpointOperation.save,
            () => writer(
              GameSessionCheckpointCommit(
                descriptor: descriptor.publicContext,
                checkpoint: _checkpointFromState(
                  projected,
                  captureEnvironment: false,
                ),
                status: SaveStatus.active,
                trigger: GameSessionCheckpointTrigger.pauseMutation,
              ),
            ),
          );
        },
      );
      if (_disposed ||
          _stopped ||
          !identical(session, _session) ||
          _gameState != source)
        return false;
      _gameState = projected;
      _lastCell = projected.playerPosition;
      _pendingEscapeActivation = MapActivation(
        activationId: _mapActivationId,
        mapId: target.id,
        reason: MapActivationReason.warp,
      );
      return true;
    } on Object {
      if (!_disposed && !_stopped && identical(session, _session)) {
        final restored = _gameState ?? source;
        try {
          _story?.synchronize(restored.spatialWorldState);
          await session.restoreGameState(
            restored,
            compensatePendingScene: true,
            restorePlayerAvatar: false,
          );
          _lastCell = restored.playerPosition;
        } on Object catch (restoreError) {
          _stopped = true;
          session.interactionError.value = StateError(
            'The Escape Rope failed and its source could not be restored: $restoreError',
          );
        }
      }
      return false;
    } finally {
      _escapeRopeInFlight = false;
      _materializingState = false;
      _escapeTransferSource = null;
      if (!_disposed) _syncMovement();
    }
  }

  void _startPendingEscapeActivation() {
    final activation = _pendingEscapeActivation;
    if (activation == null ||
        _disposed ||
        _stopped ||
        _paused ||
        _locks.isNotEmpty)
      return;
    _pendingEscapeActivation = null;
    unawaited(
      _runGameplay(() async {
        if (_gameState?.currentMapId != activation.mapId) return;
        await _gameplay?.activateMap(activation);
      }),
    );
  }
}
