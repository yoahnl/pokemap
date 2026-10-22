part of 'playable_map_game.dart';

extension _PlayableMapMovingProps on PlayableMapGame {
  void _applyMovingPropFrame(
    MovingPropWorldState state,
    Map<String, PixelOffset> positions,
  ) {
    _world = _world.withMovingPropState(
      project: _bundle.manifest,
      worldState: state,
      positions: positions,
    );
    _applyMovingPlatformFrame(_world);
  }

  Future<String> _executeSceneSetPropStateCommand(
    SceneInteractiveCommand command, {
    required GameState Function() currentGameState,
  }) async {
    if (command is! SceneSetPropStateInteractiveCommand ||
        !isLoaded ||
        _isRemoved ||
        command.mapId != _activeMapId ||
        _world.map.spatialScene != null ||
        _world.map.version == ProjectVersion.v9 ||
        _movingPropsRunning ||
        _fieldObstacleMovement != null ||
        _player.isStepping ||
        _player.isJumping ||
        _sceneActorRouteTargets.isNotEmpty ||
        _sceneForcedRouteBarrierCount > 0 ||
        (_scriptedEntityMovementController?.hasActiveForcedMoves ?? false)) {
      return 'blocked';
    }
    final session = _activeNarrativeSceneWorkingSession;
    if (session == null) {
      throw StateError('Prop movement requires a Scene transaction.');
    }
    _refreshWorldNpcPresence();
    if (_loadedMapsById[_activeMapId]?.npcActorByEntityId.values.any(
          (actor) => actor.isStepping,
        ) ??
        false) {
      return 'blocked';
    }
    final activationId = _currentMapActivationId;
    final originalWorld = _world;
    final originalState = session.gameState;
    bool current() =>
        !_isRemoved &&
        _activeMapId == command.mapId &&
        _currentMapActivationId == activationId &&
        identical(_activeNarrativeSceneWorkingSession, session);
    final result = moveGameplayProps(
      world: _world,
      project: _bundle.manifest,
      worldState: currentGameState().movingPropWorldState,
      propIds: command.propIds,
      state: command.state,
    );
    final token = _inputLocks.acquire(
      owner: RuntimeInputLockOwner.scriptedMovement,
      surface: RuntimeInputSurface.cinematic,
    );
    _movingPropsRunning = true;
    _clearPressedMovementControls();
    _publishInputAuthoritySnapshot();
    session.registerCompensation(() async {
      session.gameState = originalState;
      if (current()) _applyMovingPlatformFrame(originalWorld);
    });
    var completed = false;
    try {
      final startedAtMs = _runtimeClockMs;
      for (var index = 0; index < result.frames.length; index++) {
        if (!current()) throw StateError('Prop movement was interrupted.');
        final frame = result.frames[index];
        _applyMovingPropFrame(
          originalState.movingPropWorldState,
          frame.positions,
        );
        final due =
            command.durationMs * (index + 1) / result.frames.length;
        final remaining = due - (_runtimeClockMs - startedAtMs);
        if (remaining > 0) {
          await _waitForSceneActorRoute(
            isCurrent: current,
            durationMs: remaining.ceil(),
          );
        }
      }
      if (!current()) throw StateError('Prop movement was interrupted.');
      _applyMovingPropFrame(result.finalWorldState, const {});
      session.gameState = session.gameState.copyWith(
        movingPropWorldState: result.finalWorldState,
      );
      completed = true;
      return result.outcome.name;
    } finally {
      if (!completed && current()) _applyMovingPlatformFrame(originalWorld);
      _movingPropsRunning = false;
      _inputLocks.release(
        owner: RuntimeInputLockOwner.scriptedMovement,
        token: token,
      );
      _clearPressedMovementControls();
      _publishInputAuthoritySnapshot();
    }
  }
}
