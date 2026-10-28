part of 'playable_map_game.dart';

extension _PlayableMapFieldTraversal on PlayableMapGame {
  Future<bool> _traverseFieldTerrain(FieldTraversalActionTicket ticket) async {
    if (!isLoaded ||
        _isRemoved ||
        _cancelFieldTerrainTraversal != null ||
        _activeNarrativeSceneWorkingSession != null ||
        !_canResolveOverworldInteraction() ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        _player.isStepping ||
        _player.isJumping ||
        validateFieldTraversalTicket(
              projectSettings: _bundle.manifest.settings,
              ticket: ticket,
              ability: ticket.fieldAction.ability,
              map: _world.map,
              gameState: gameStateSnapshot,
              currentStateRevision: _gameStateRevision,
            ) !=
            null) {
      return false;
    }
    final evaluation = evaluateFieldTraversalAttempt(
      ability: ticket.fieldAction.ability,
      kind: ticket.zone.fieldAction!.actionKind,
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
    if (evaluation.reason != null) return false;
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
    var finished = false;
    bool scopeCurrent() =>
        !_isRemoved &&
        _currentMapActivationId == activation &&
        identical(_player, actor);
    bool current() =>
        !finished &&
        scopeCurrent() &&
        _gameStateRevision == revision &&
        findGameplayZoneById(_world.map, ticket.zone.id) == ticket.zone &&
        _gameState.mapInstanceWorldState.instanceRef(_activeMapId) ==
            ticket.instance &&
        (!fieldTraversalRequiresSurf(ticket.zone) ||
            _world.player.movementMode == MovementMode.surf);
    late final void Function() cancel;
    void finish() {
      if (finished) return;
      finished = true;
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
      if (scopeCurrent()) {
        _scriptedNpcReservedOccupiedCellsByEntity.remove('player');
      }
      _sceneActorRouteTargets.remove(target);
      if (identical(_cancelFieldTerrainTraversal, cancel)) {
        _cancelFieldTerrainTraversal = null;
      }
      _inputLocks.release(
        owner: RuntimeInputLockOwner.scriptedMovement,
        token: token,
      );
      _publishInputAuthoritySnapshot();
      _publishOverworldInteractions();
    }

    cancel = () {
      finish();
      _processSceneActorRouteWaits();
    };
    _cancelFieldTerrainTraversal = cancel;
    _sceneActorRouteTargets.add(target);
    _clearPressedMovementControls();
    _publishInputAuthoritySnapshot();
    try {
      for (final cell in evaluation.cells) {
        if (!current()) return false;
        final plan = planActorRouteMove(
          world: _world,
          target: target,
          direction: fieldTraversalFacing(ticket.zone),
          through: false,
          fieldTraversalZone: ticket.zone,
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
        _reserveScriptedNpcStepOccupiedCells(
          entityId: 'player',
          fromAnchorPos: plan.from,
          toAnchorPos: plan.to,
        );
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
            direction: fieldTraversalFacing(ticket.zone),
            through: false,
            fieldTraversalZone: ticket.zone,
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
          if (!finished && scopeCurrent()) {
            _scriptedNpcReservedOccupiedCellsByEntity.remove('player');
          }
          if (!finished && physicalCompletionAcquired && scopeCurrent()) {
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
            final committedRevision = _publishCommittedMovement(
              CommittedMovement(
                kind: CommittedMovementKind.forced,
                fromCell: plan.from,
                toCell: plan.to,
              ),
            );
            if (continuationValidated && committedRevision != null) {
              revision = committedRevision;
            }
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
        direction: fieldTraversalFacing(ticket.zone).asDirection,
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
      debugPrint('[field-traversal] traversal interrupted: $error');
      return false;
    } finally {
      finish();
    }
  }
}
