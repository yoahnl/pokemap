part of 'playable_map_game.dart';

extension _PlayableMapDive on PlayableMapGame {
  Future<void> _openDiveInteraction(String zoneId) async {
    if (!_diveActionAvailable) {
      return;
    }
    final source = _world.map;
    final state = gameStateSnapshot;
    final revision = _gameStateRevision;
    final link = findGameplayZoneById(source, zoneId)?.fieldAction?.dive?.link;
    RuntimeMapBundle? target;
    try {
      if (link != null &&
          _bundle.manifest.maps.where((map) => map.id == link.mapId).length ==
              1) {
        target = await _loadRuntimeMapBundleCached(link.mapId);
      }
    } on Object {
      target = null;
    }
    if (!_diveActionAvailable ||
        revision != _gameStateRevision ||
        source != _world.map ||
        state != gameStateSnapshot) {
      return;
    }
    final projected = target == null
        ? null
        : _projectMovingPlatformBundle(target, state);
    final prepared = prepareDiveInteraction(
      sourceMap: source,
      targetMap: projected?.map,
      gameState: state,
      stateRevision: revision,
      zoneId: zoneId,
      project: _bundle.manifest,
      world: _world,
    );
    _openDialogue(
      prepared.session,
      onDialogueFinished: (outcome) {
        if (outcome != 'dive-confirmed' || prepared.ticket == null) {
          return;
        }
        unawaited(
          _transferDive(prepared.ticket!).then((completed) {
            if (!completed && !_isRemoved) {
              _showNotification('Le passage de Plongée n’est plus disponible.');
            }
          }),
        );
      },
    );
  }

  bool get _diveActionAvailable =>
      isLoaded &&
      !_isRemoved &&
      !_diveTransferInFlight &&
      _activeNarrativeSceneWorkingSession == null &&
      _canResolveOverworldInteraction() &&
      !_hasCheckpointUnsafeRuntimeWorkForSave &&
      !_player.isStepping &&
      !_player.isJumping;

  Future<bool> _transferDive(DiveActionTicket ticket) async {
    if (!_diveActionAvailable) {
      return false;
    }
    var mountedDestination = false;
    late _RuntimeSpatialSnapshot source;
    bool current(MapInstanceWorldState? instances) {
      if (instances != null) mountedDestination = true;
      if (_isRemoved || _activeMapId != ticket.sourceMap.id) {
        return false;
      }
      final state = gameStateSnapshot;
      final checked = instances == null
          ? state
          : state.copyWith(
              mapInstanceWorldState: ticket.gameState.mapInstanceWorldState,
            );
      final targetBundle = _runtimeBundleByMapId[ticket.targetMap.id];
      final target = targetBundle == null
          ? null
          : _projectMovingPlatformBundle(targetBundle, checked).map;
      if (instances != null) {
        source = _RuntimeSpatialSnapshot(
          gameState: checked,
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
      return validateDiveTicket(
            ticket: ticket,
            sourceMap: _world.map,
            targetMap: target,
            gameState: checked,
            currentStateRevision: _gameStateRevision,
            project: _bundle.manifest,
            sourceWorld: _world,
          ) ==
          null;
    }

    if (!current(null)) {
      return false;
    }
    source = _RuntimeSpatialSnapshot(
      gameState: gameStateSnapshot,
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
    GameState? destinationState;
    MapData? destinationMap;
    int? destinationRevision;
    String? destinationActivationId;
    bool destinationCurrent() =>
        destinationState != null &&
        !_isRemoved &&
        _activeMapId == ticket.targetMap.id &&
        (_currentMapActivationId == source.currentMapActivationId ||
            _currentMapActivationId == destinationActivationId) &&
        _gameStateRevision == destinationRevision &&
        _world.map == destinationMap &&
        gameStateSnapshot == destinationState;

    bool ownsDestination(MapActivation activation) {
      destinationState ??= gameStateSnapshot;
      destinationMap ??= _world.map;
      destinationRevision ??= _gameStateRevision;
      destinationActivationId ??= activation.activationId;
      return destinationCurrent();
    }

    final wasPaused = isPaused;
    _diveTransferInFlight = true;
    if (wasPaused) resumeEngine();
    var completed = false;
    try {
      completed = await _handleWarp(
        TriggeredWarp(
          triggerMode: MapWarpTriggerMode.onBump,
          warpId: 'dive.${ticket.evaluation.sourceZoneId}',
          targetMapId: ticket.evaluation.targetMapId,
          targetPos: ticket.evaluation.position,
        ),
        arrivalFacing: ticket.evaluation.facing,
        arrivalMovementMode: ticket.evaluation.arrivalMovementMode,
        transferGuard: current,
        destinationTransferGuard: ownsDestination,
      );
      if (completed) {
        final reverse = evaluateDiveAttempt(
          sourceMap: _world.map,
          targetMap: source.world.map,
          gameState: gameStateSnapshot,
          zoneId: ticket.evaluation.targetZoneId,
          project: _bundle.manifest,
          sourceWorld: _world,
        );
        completed =
            reverse is CanUseDive && reverse.targetMapId == source.activeMapId;
      }
      return completed;
    } on Object {
      return false;
    } finally {
      try {
        if (!completed &&
            !_isRemoved &&
            (destinationState == null || destinationCurrent()) &&
            (mountedDestination ||
                _activeMapId != source.activeMapId ||
                !_loadedMapsById.containsKey(source.activeMapId))) {
          if (!await _restoreRuntimeSpatialSnapshot(
            source,
            commitNarrativeState: true,
          )) {
            throw StateError('The Dive source could not be restored.');
          }
        }
      } finally {
        if (!completed && wasPaused && !_isRemoved) pauseEngine();
        _diveTransferInFlight = false;
        _publishInputAuthoritySnapshot();
        _publishOverworldInteractions();
      }
    }
  }
}
