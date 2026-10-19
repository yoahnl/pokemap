part of 'playable_map_game.dart';

final class _RuntimeFieldObstacleMovement {
  _RuntimeFieldObstacleMovement({
    required this.mapId,
    required this.activationId,
    required this.entityId,
    required this.slide,
    required this.durationSeconds,
    required this.playerFrom,
    required this.firstMovement,
    required this.repelActiveForStep,
  }) : suppressMovement = slide != null,
       remainingSeconds = durationSeconds;

  final String mapId;
  final String? activationId;
  final String entityId;
  FieldObstacleSlide? slide;
  final double durationSeconds;
  final GridPos playerFrom;
  final GameplayStepResult firstMovement;
  final bool repelActiveForStep;
  final bool suppressMovement;
  double remainingSeconds;
}

extension _PlayableMapFieldObstacleSlide on PlayableMapGame {
  void _startFieldObstacleMovement({
    required StrengthPushApplied decision,
    required GridPos playerFrom,
    required GridPos obstacleFrom,
    required Direction direction,
    required double durationSeconds,
  }) {
    final movement = _RuntimeFieldObstacleMovement(
      mapId: _activeMapId,
      activationId: _currentMapActivationId,
      entityId: decision.entityId,
      slide: decision.slide,
      durationSeconds: durationSeconds,
      playerFrom: playerFrom,
      firstMovement: decision.movement,
      repelActiveForStep: _gameState.repelState.isActive,
    );
    _fieldObstacleMovement = movement;
    _animateFieldObstacleMovementStep(
      movement,
      obstacleFrom,
      GridPos(
        x: obstacleFrom.x + direction.dx,
        y: obstacleFrom.y + direction.dy,
      ),
    );
    if (!movement.suppressMovement) {
      _handleGameplayMovementResult(
        decision.movement,
        previousPlayerPos: playerFrom,
      );
      return;
    }
    _slideSuppressedMovementControls.addAll(_pressedMovementControls);
    _clearPressedMovementControls();
    _sprintPressed = false;
    _publishCommittedMovement(
      CommittedMovement(
        kind: CommittedMovementKind.walk,
        fromCell: playerFrom,
        toCell: _world.player.pos,
      ),
    );
    if (!identical(_fieldObstacleMovement, movement)) return;
    _player.startStep(
      _world.player,
      durationSeconds: durationSeconds,
      animationState: _playerStepAnimation,
    );
    _publishInputAuthoritySnapshot();
  }

  void _animateFieldObstacleMovementStep(
    _RuntimeFieldObstacleMovement movement,
    GridPos from,
    GridPos to,
  ) {
    movement.remainingSeconds = movement.durationSeconds;
    _reserveScriptedNpcStepOccupiedCells(
      entityId: movement.entityId,
      fromAnchorPos: from,
      toAnchorPos: to,
    );
    final loaded = _loadedMapsById[movement.mapId];
    for (final layers in [loaded?.backgroundLayers, loaded?.foregroundLayers]) {
      layers?.animateFieldObstaclePush(
        entityId: movement.entityId,
        from: from,
        to: to,
        durationSeconds: movement.durationSeconds,
      );
    }
  }

  void _advanceFieldObstacleMovement(double dt) {
    final movement = _fieldObstacleMovement;
    if (movement == null) return;
    if (_isRemoved ||
        movement.mapId != _activeMapId ||
        movement.activationId != _currentMapActivationId) {
      _cancelFieldObstacleMovement();
      return;
    }
    if (!dt.isFinite || dt < 0) return;
    movement.remainingSeconds = math.max(0, movement.remainingSeconds - dt);
    if (movement.remainingSeconds > .0000001 ||
        _player.isStepping ||
        _externalInputLocks.isNotEmpty ||
        !_inputLocks.snapshot.acceptsOverworldInput) {
      return;
    }
    final slide = movement.slide;
    if (slide != null) {
      final result = stepFieldObstacleSlide(
        slide: slide,
        world: _world,
        gameState: _captureGameStateFromWorld(),
        authoringMap: (_runtimeBundleByMapId[_activeMapId] ?? _bundle).map,
        project: _bundle.manifest,
        characterReservations: _scriptedNpcReservedOccupiedCellsByEntity.entries
            .where((entry) => entry.key != movement.entityId)
            .map((entry) => entry.value.contactRect)
            .whereType<PixelRect>(),
      );
      if (result is FieldObstacleSlideMoved) {
        movement.slide = result.slide;
        _world = result.world;
        _applyIntrinsicFieldObstacleState(result.gameState);
        _animateFieldObstacleMovementStep(movement, result.from, result.to);
        return;
      }
      if (result is FieldObstacleSlideRefused) {
        _cancelFieldObstacleMovement();
        _publishOverworldInteractions();
        return;
      }
    }
    _cancelFieldObstacleMovement(clearInputs: movement.suppressMovement);
    if (movement.suppressMovement) {
      _handleGameplayMovementResult(
        movement.firstMovement,
        previousPlayerPos: movement.playerFrom,
        animatePlayer: false,
        publishMovement: false,
        repelActiveForStepOverride: movement.repelActiveForStep,
      );
    } else {
      _checkTrainerLineOfSight();
    }
    _publishOverworldInteractions();
  }

  void _cancelFieldObstacleMovement({bool clearInputs = true}) {
    final movement = _fieldObstacleMovement;
    if (movement == null) return;
    _fieldObstacleMovement = null;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(movement.entityId);
    final loaded = _loadedMapsById[movement.mapId];
    loaded?.backgroundLayers.cancelFieldObstaclePush(movement.entityId);
    loaded?.foregroundLayers.cancelFieldObstaclePush(movement.entityId);
    if (isLoaded && _activeMapId == movement.mapId) {
      _player.syncState(_world.player, snapToGrid: true);
    }
    if (clearInputs) {
      _slideSuppressedMovementControls.addAll(_pressedMovementControls);
      _clearPressedMovementControls();
      _sprintPressed = false;
    }
  }
}
