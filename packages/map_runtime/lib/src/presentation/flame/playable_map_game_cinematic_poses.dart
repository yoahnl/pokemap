part of 'playable_map_game.dart';

extension _PlayableMapCinematicPoses on PlayableMapGame {
  CinematicActorPoseCommit _prepareCinematicActorPoses(
    Map<CinematicActorBinding, FlameCinematicActorPose> poses,
  ) {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null || _world.map.id != _activeMapId) {
      throw StateError('The cinematic map is unavailable.');
    }
    final manifest = loaded.bundle.manifest;
    final transactionState = _battleRuntimeGameState;
    final presentationState = _scenePresentationGameState;
    var instances = transactionState.mapInstanceWorldState;
    if (instances.instanceRef(_activeMapId) == null) {
      instances = retainMapInstance(
        state: instances,
        mapId: _activeMapId,
        allocateId: _allocateMapInstanceId,
      );
    }
    instances = _captureInstanceNpcPositions(instances, _activeMapId);
    final origin = _originPixelsOf(loaded);
    final npcPoses = <String, MapInstanceNpcPose>{};
    GameplayPlayerState? player;
    for (final entry in poses.entries) {
      final binding = entry.key;
      final pose = entry.value;
      if (!pose.focusX.isFinite || !pose.focusY.isFinite) {
        throw StateError('The cinematic actor pose must be finite.');
      }
      if (binding.kind == CinematicActorBindingKind.player) {
        final offset = _player.cinematicVisualFocusPoint - _player.position;
        final px = PixelPosition(
          leftPx: _cinematicPixel((pose.focusX - offset.x - origin.x) *
              manifest.settings.tileWidth / loaded.bundle.cellWidth),
          topPx: _cinematicPixel((pose.focusY - offset.y - origin.y) *
              manifest.settings.tileHeight / loaded.bundle.cellHeight),
        );
        final candidate = _world.player.copyWith(
          playerPositionPx: px,
          facing: _directionFromEntityFacing(pose.facing),
        );
        player = candidate.copyWith(
          pos: PlayerCollisionConventionsV1.projectFeetAnchorToCell(
            playerCollisionRectPx: candidate.playerCollisionRectPx,
            tileWidthPx: _world.tileWidthPx,
            tileHeightPx: _world.tileHeightPx,
            mapWidthCells: _world.map.size.width,
            mapHeightCells: _world.map.size.height,
          ),
        );
      } else {
        final id = binding.mapEntityId;
        final entity = _world.map.entities
            .where((entity) => entity.id == id).singleOrNull;
        final actor = loaded.npcActorByEntityId[id];
        if (entity?.npc == null || actor == null || !actor.isGameplayPresent) {
          throw StateError('The cinematic NPC is unavailable.');
        }
        final position = cinematicEntityGridPositionForFocus(
          entity: entity!,
          project: manifest,
          focusX: (pose.focusX - origin.x) / loaded.bundle.cellWidth,
          focusY: (pose.focusY - origin.y) / loaded.bundle.cellHeight,
        );
        if (position == null) {
          throw StateError('The cinematic final NPC pose must align to its grid.');
        }
        npcPoses[id!] = MapInstanceNpcPose(
          position: position,
          facing: pose.facing,
        );
      }
    }
    return prepareCinematicActorPoseCommit(
      world: _world,
      authoringMap: (_runtimeBundleByMapId[_activeMapId] ?? _bundle).map,
      instances: instances,
      instance: instances.instanceRef(_activeMapId)!,
      project: manifest,
      gameState: transactionState,
      lookupRewardScenes: _lookupRewardScenes,
      periodicRewardState: (_) => presentationState,
      player: player,
      npcPoses: npcPoses,
    );
  }

  int _cinematicPixel(double value) {
    if (!value.isFinite || (value - value.round()).abs() > 0.0000001) {
      throw StateError('The cinematic final player pose requires whole pixels.');
    }
    return value.round();
  }

  void _commitCinematicActorPoses(
    Map<CinematicActorBinding, FlameCinematicActorPose> poses,
  ) {
    if (poses.isEmpty) return;
    final prepared = _prepareCinematicActorPoses(poses);
    final previousWorld = _world;
    final previousGameState = _gameState;
    final session = _activeNarrativeSceneWorkingSession;
    final previousSessionState = session?.gameState;
    final activation = _currentMapActivationId;
    final mapId = _activeMapId;
    void restore() {
      if (_isRemoved || _activeMapId != mapId ||
          _currentMapActivationId != activation) {
        return;
      }
      _world = previousWorld;
      _gameState = previousGameState;
      if (session != null && previousSessionState != null) {
        session.gameState = previousSessionState;
      }
      _syncCinematicActorComponents(poses.keys);
    }

    try {
      _world = prepared.world;
      _replaceLogicalMapInstances(prepared.instances);
      _syncCinematicActorComponents(poses.keys);
      _syncSceneActorPlayerState(session);
    } catch (_) {
      restore();
      rethrow;
    }
    session?.registerCompensation(() async => restore());
  }

  void _syncCinematicActorComponents(Iterable<CinematicActorBinding> bindings) {
    final loaded = _loadedMapsById[_activeMapId]!;
    for (final binding in bindings) {
      if (binding.kind == CinematicActorBindingKind.player) {
        _player.syncState(_world.player, snapToGrid: true);
        _runtimeNpcPositions['player'] = _world.player.pos;
        _scriptedEntityMovementController?.syncTrackedEntityPosition(
            'player', _world.player.pos);
      } else {
        final entity = _world.map.entities
            .singleWhere((entity) => entity.id == binding.mapEntityId);
        final actor = loaded.npcActorByEntityId[entity.id]!;
        actor.configureGridPlacement(
          pos: entity.pos,
          footprint: entity.size,
          mapOrigin: _originPixelsOf(loaded),
        );
        actor.setMotion(entity.npc!.facing, CharacterAnimationState.idle);
        _runtimeNpcPositions[entity.id] = entity.pos;
        _scriptedEntityMovementController?.syncTrackedEntityPosition(
            entity.id, entity.pos);
      }
    }
  }
}
