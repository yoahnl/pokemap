part of 'playable_map_game.dart';

extension _PlayableMapWaterfall on PlayableMapGame {
  Future<bool> _traverseWaterfall(WaterfallActionTicket ticket) async {
    if (!isLoaded ||
        _isRemoved ||
        _waterfallTraversalActive ||
        _activeNarrativeSceneWorkingSession != null ||
        !_canResolveOverworldInteraction() ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        _player.isStepping ||
        _player.isJumping ||
        validateWaterfallTicket(
              ticket: ticket,
              map: _world.map,
              gameState: gameStateSnapshot,
              currentStateRevision: _gameStateRevision,
            ) !=
            null) {
      return false;
    }
    final evaluation = evaluateWaterfallAttempt(
      map: _world.map,
      gameState: gameStateSnapshot,
      zoneId: ticket.zone.id,
      world: _world,
      project: _bundle.manifest,
      dynamicBlockedCells: _scriptedNpcReservedOccupiedCellsByEntity.entries
          .where((e) => e.key != 'player')
          .expand((e) => e.value.cells),
      characterReservations: _scriptedNpcReservedOccupiedCellsByEntity.entries
          .where((e) => e.key != 'player')
          .map((e) => e.value.contactRect)
          .whereType<PixelRect>(),
    );
    if (evaluation is! CanUseWaterfall) return false;
    final activation = _currentMapActivationId;
    final actor = _player;
    final original = _world.player;
    final target = SceneActorTarget.player(mapId: _activeMapId);
    final token = _inputLocks.acquire(
      owner: RuntimeInputLockOwner.scriptedMovement,
      surface: RuntimeInputSurface.blocked,
    );
    var revision = _gameStateRevision;
    var completed = false;
    bool scopeCurrent() =>
        !_isRemoved &&
        _currentMapActivationId == activation &&
        identical(_player, actor);
    bool current() =>
        scopeCurrent() &&
        _gameStateRevision == revision &&
        findGameplayZoneById(_world.map, ticket.zone.id) == ticket.zone &&
        _gameState.mapInstanceWorldState.instanceRef(_activeMapId) ==
            ticket.instance &&
        (!ticket.zone.fieldAction!.waterfall!.requiresSurf ||
            _world.player.movementMode == MovementMode.surf);
    _waterfallTraversalActive = true;
    _sceneActorRouteTargets.add(target);
    _clearPressedMovementControls();
    _publishInputAuthoritySnapshot();
    try {
      for (final cell in evaluation.cells) {
        if (!current()) return false;
        final plan = planActorRouteMove(
          world: _world,
          target: target,
          direction: waterfallFacing(ticket.zone),
          through: false,
          waterfallZone: ticket.zone,
          dynamicBlockedCells: _scriptedNpcReservedOccupiedCellsByEntity.entries
              .where((e) => e.key != 'player')
              .expand((e) => e.value.cells),
          characterReservations: _scriptedNpcReservedOccupiedCellsByEntity
              .entries
              .where((e) => e.key != 'player')
              .map((e) => e.value.contactRect)
              .whereType<PixelRect>(),
        );
        if (plan == null || plan.to != cell) return false;
        actor.startStep(plan.playerState!, durationSeconds: .25);
        final expectedPosition = Vector2(
          actor.mapOrigin.x +
              plan.toPositionPx.leftPx * _bundle.cellWidth / _world.tileWidthPx,
          actor.mapOrigin.y +
              plan.toPositionPx.topPx *
                  _bundle.cellHeight /
                  _world.tileHeightPx,
        );
        var physicalCompletionAcquired = false;
        var continuationValidated = false;
        bool acquirePhysicalCompletion() {
          if (scopeCurrent() &&
              !actor.isStepping &&
              (actor.position.x - expectedPosition.x).abs() < .000000001 &&
              (actor.position.y - expectedPosition.y).abs() < .000000001) {
            physicalCompletionAcquired = true;
          }
          return physicalCompletionAcquired;
        }

        try {
          await _waitForSceneActorRoute(
            isCurrent: () {
              acquirePhysicalCompletion();
              return current();
            },
            isReady: acquirePhysicalCompletion,
          );
          if (!current()) return false;
          final revalidated = planActorRouteMove(
            world: _world,
            target: target,
            direction: waterfallFacing(ticket.zone),
            through: false,
            waterfallZone: ticket.zone,
            dynamicBlockedCells: _scriptedNpcReservedOccupiedCellsByEntity
                .entries
                .where((e) => e.key != 'player')
                .expand((e) => e.value.cells),
            characterReservations: _scriptedNpcReservedOccupiedCellsByEntity
                .entries
                .where((e) => e.key != 'player')
                .map((e) => e.value.contactRect)
                .whereType<PixelRect>(),
          );
          if (revalidated == null ||
              revalidated.to != plan.to ||
              (revalidated.toPositionPx.leftPx != plan.toPositionPx.leftPx ||
                  revalidated.toPositionPx.topPx != plan.toPositionPx.topPx)) {
            return false;
          }
          continuationValidated = true;
        } finally {
          if (physicalCompletionAcquired && scopeCurrent()) {
            _world = _world.withPlayer(
              _world.player.copyWith(
                pos: plan.to,
                playerPositionPx: plan.toPositionPx,
                facing: plan.playerState!.facing,
              ),
            );
            _runtimeNpcPositions['player'] = plan.to;
            _scriptedEntityMovementController?.syncTrackedEntityPosition(
              'player',
              plan.to,
            );
            _syncGameStateFromWorld();
            if (continuationValidated) revision = _gameStateRevision;
            _publishCommittedMovement(
              CommittedMovement(
                kind: CommittedMovementKind.forced,
                fromCell: plan.from,
                toCell: plan.to,
              ),
            );
          }
        }
      }
      if (!current()) return false;
      _applyFieldActionExitAfterStep();
      final arrival = resolveGameplayArrival(
        _world,
        previousPos: evaluation.cells.length > 1
            ? evaluation.cells[evaluation.cells.length - 2]
            : original.pos,
        direction: waterfallFacing(ticket.zone).asDirection,
      );
      _world = arrival.world;
      _syncGameStateFromWorld();
      _handleGameplayMovementResult(
        arrival,
        previousPlayerPos: original.pos,
        animatePlayer: false,
        publishMovement: false,
      );
      completed = true;
      return true;
    } on Object catch (error) {
      debugPrint('[waterfall] traversal interrupted: $error');
      return false;
    } finally {
      if (!completed && scopeCurrent()) {
        _world = _world.withPlayer(
          _world.player.copyWith(
            pos: original.pos,
            playerPositionPx: original.playerPositionPx,
            facing: original.facing,
            movementMode: original.movementMode,
          ),
        );
        actor.syncState(_world.player, snapToGrid: true);
        _runtimeNpcPositions['player'] = original.pos;
        _scriptedEntityMovementController?.syncTrackedEntityPosition(
          'player',
          original.pos,
        );
        _syncGameStateFromWorld();
        _synchronizeTriggerEnterOccupancy();
      }
      _sceneActorRouteTargets.remove(target);
      _waterfallTraversalActive = false;
      _inputLocks.release(
        owner: RuntimeInputLockOwner.scriptedMovement,
        token: token,
      );
      _publishInputAuthoritySnapshot();
      _publishOverworldInteractions();
    }
  }
}
