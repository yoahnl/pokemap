import 'dart:math' as math;
import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'collision/pixel_movement_resolver.dart';
import 'spatial_terrain_navigation.dart';
import 'spatial_model_geometry.dart';
import 'direction.dart';
import 'player_spawn_resolver.dart';

({PlayerSpatialPosition position, EntityFacing facing})
    resolveSpatialPlayerSpawn({
  required MapData map,
  String? preferredSpawnId,
}) {
  final scene = map.spatialScene;
  if (scene == null ||
      scene.width != map.size.width ||
      scene.depth != map.size.height) {
    throw StateError('La carte ne possède pas de scène 3D cohérente.');
  }
  late final PlayerSpatialPosition position;
  var facing = EntityFacing.south;
  if ((preferredSpawnId?.trim().isNotEmpty ?? false) ||
      (map.mapMetadata.defaultSpawnId?.trim().isNotEmpty ?? false) ||
      map.entities.any((entity) =>
          entity.kind == MapEntityKind.spawn &&
          entity.spawn?.role == EntitySpawnRole.playerStart)) {
    final resolved = resolveInitialPlayerSpawn(
      map,
      preferredSpawnId: preferredSpawnId,
    );
    position = PlayerSpatialPosition(
      x: resolved.pos.x + .5,
      z: resolved.pos.y + .5,
    );
    facing = resolved.facing.asFacing;
  } else {
    position = PlayerSpatialPosition(
      x: scene.navigation.spawn.x,
      z: scene.navigation.spawn.z,
    );
  }
  _validateSpatialArrival(position, scene);
  return (position: position, facing: facing);
}

void _validateSpatialArrival(
  PlayerSpatialPosition position,
  MapSpatialScene scene,
) {
  if (position.x >= scene.width || position.z >= scene.depth) {
    throw StateError('Le point d’arrivée 3D est hors de la carte.');
  }
  final x = position.x * SpatialMovementController.pixelsPerCell;
  final z = position.z * SpatialMovementController.pixelsPerCell;
  if (x != x.roundToDouble() || z != z.roundToDouble()) {
    throw StateError(
        'Le point d’arrivée 3D ne respecte pas la précision du déplacement.');
  }
}

final class SpatialMovementNeighbor {
  SpatialMovementNeighbor({
    required this.controller,
    required this.offsetX,
    required this.offsetZ,
  }) {
    if (!offsetX.isFinite ||
        !offsetZ.isFinite ||
        offsetX != offsetX.roundToDouble() ||
        offsetZ != offsetZ.roundToDouble()) {
      throw ArgumentError('Une connexion doit être alignée sur les cases.');
    }
  }

  final SpatialMovementController controller;
  final double offsetX;
  final double offsetZ;
}

final class SpatialMovementController {
  SpatialMovementController({
    required MapSpatialScene scene,
    required Iterable<ProjectModel3dEntry> models,
    Iterable<MapEntity> entities = const [],
    bool Function(MapEntity entity)? entityPresencePredicate,
    MapEntity? Function(MapEntity entity)? entityProjection,
    SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider,
    SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  }) : this._(
          scene: scene,
          models: models,
          entities: entities,
          entityPresencePredicate: entityPresencePredicate,
          entityProjection: entityProjection,
          modelStateProvider: modelStateProvider,
          actorStateProvider: actorStateProvider,
          spawn: scene.navigation.spawn,
          spawnFacing: EntityFacing.south,
          blockedCells: const {},
        );

  factory SpatialMovementController.fromMap({
    required MapData map,
    required Iterable<ProjectModel3dEntry> models,
    GridPos? arrival,
    PlayerSpatialPosition? spatialArrival,
    EntityFacing? facing,
    String? preferredSpawnId,
    bool validateSpawn = true,
    bool Function(MapEntity entity)? entityPresencePredicate,
    MapEntity? Function(MapEntity entity)? entityProjection,
    SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider,
    SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  }) {
    final scene = map.spatialScene;
    if (scene == null ||
        scene.width != map.size.width ||
        scene.depth != map.size.height) {
      throw StateError('La carte ne possède pas de scène 3D cohérente.');
    }
    if (arrival != null && spatialArrival != null) {
      throw ArgumentError('Une seule position d’arrivée 3D peut être fournie.');
    }
    late final PlayerSpatialPosition position;
    var spawnFacing = EntityFacing.south;
    if (spatialArrival != null) {
      position = spatialArrival;
    } else if (arrival != null) {
      if (arrival.x < 0 ||
          arrival.y < 0 ||
          arrival.x >= scene.width ||
          arrival.y >= scene.depth) {
        throw StateError('Le point d’arrivée 3D est hors de la carte.');
      }
      position = PlayerSpatialPosition(x: arrival.x + .5, z: arrival.y + .5);
    } else {
      final resolved = resolveSpatialPlayerSpawn(
        map: map,
        preferredSpawnId: preferredSpawnId,
      );
      position = resolved.position;
      spawnFacing = resolved.facing;
    }
    _validateSpatialArrival(position, scene);
    return SpatialMovementController._(
      scene: scene,
      models: models,
      entities:
          map.entities.where((entity) => entity.kind != MapEntityKind.spawn),
      entityPresencePredicate: entityPresencePredicate,
      entityProjection: entityProjection,
      modelStateProvider: modelStateProvider,
      actorStateProvider: actorStateProvider,
      spawn: SpatialSpawn(x: position.x, z: position.z),
      spawnFacing: facing ?? spawnFacing,
      blockedCells: {
        for (final layer in map.layers.whereType<CollisionLayer>())
          for (var i = 0;
              i < layer.collisions.length && i < scene.width * scene.depth;
              i++)
            if (layer.collisions[i]) i,
      },
      validateSpawn: validateSpawn,
    );
  }

  SpatialMovementController._({
    required this.scene,
    required Iterable<ProjectModel3dEntry> models,
    required Iterable<MapEntity> entities,
    required bool Function(MapEntity entity)? entityPresencePredicate,
    required this.entityProjection,
    required this.modelStateProvider,
    required this.actorStateProvider,
    required SpatialSpawn spawn,
    required EntityFacing spawnFacing,
    required Set<int> blockedCells,
    bool validateSpawn = true,
  })  : entities = List.unmodifiable(entities),
        models = {for (final model in models) model.id: model},
        _spawn = spawn,
        _spawnFacing = spawnFacing,
        _blockedCells = Set.unmodifiable(blockedCells),
        _entityPresencePredicate = entityPresencePredicate,
        allowDiagonalMovement = scene.navigation.allowDiagonalMovement {
    for (final entity in this.entities) {
      _entitiesById.putIfAbsent(entity.id, () => entity);
    }
    for (final instance in scene.instances) {
      _instancesById.putIfAbsent(instance.id, () => instance);
    }
    _reset(validateSpawn: validateSpawn);
  }
  final SpatialSpawn _spawn;
  final EntityFacing _spawnFacing;
  final Set<int> _blockedCells;
  bool Function(MapEntity entity)? _entityPresencePredicate;
  GridPos? bumpedCell;
  MapConnectionDirection? edgeExitDirection;
  PlayerSpatialPosition? connectionArrival;
  Map<MapConnectionDirection, SpatialMovementNeighbor> _connectedNeighbors = {};
  bool _connectedTraversalEnabled = false;
  late final SpatialMovementNeighbor _localMap =
      SpatialMovementNeighbor(controller: this, offsetX: 0, offsetZ: 0);
  final MapSpatialScene scene;
  final List<MapEntity> entities;
  final Map<String, MapEntity> _entitiesById = {};
  final Map<String, SpatialModelInstance> _instancesById = {};
  final Map<String, ProjectModel3dEntry> models;
  SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider;
  SpatialActorRuntimeState? Function(String entityId)? actorStateProvider;
  static const pixelsPerCell = 16;
  late PixelPosition _position;
  _SpatialLedgeJump? _ledgeJump;
  bool get isJumping => _ledgeJump != null;
  double get jumpSpeed => _ledgeJump == null
      ? 5
      : _ledgeJump!.ledge.distance * 1000 / _ledgeJump!.ledge.durationMs;
  PlayerSpatialPosition? get reservedLanding => _ledgeJump == null
      ? null
      : PlayerSpatialPosition(
          x: _ledgeJump!.ledge.landingX + .5,
          z: _ledgeJump!.ledge.landingZ + .5);
  double get jumpLift => _ledgeJump == null
      ? 0
      : math.sin(math.pi * _ledgeJump!.progress) * _ledgeJump!.ledge.height;
  double get groundY => _ledgeJump == null
      ? scene.worldHeightAt(x, z)
      : _ledgeJump!.sourceY +
          (_ledgeJump!.landingY - _ledgeJump!.sourceY) * _ledgeJump!.progress;
  double _remainderX = 0, _remainderZ = 0;
  int _inputX = 0, _inputZ = 0;
  ({int x, int z}) get inputDirection => (x: _inputX, z: _inputZ);
  bool _run = false, paused = false, moving = false;
  bool allowDiagonalMovement;
  int inputEpoch = 0;
  EntityFacing facing = EntityFacing.south;
  double animationSeconds = 0;
  bool get running => moving && _run;
  double get x => (_position.leftPx + 16) / pixelsPerCell;
  double get z => (_position.topPx + 31) / pixelsPerCell;
  PlayerSpatialPosition get spatialPosition =>
      PlayerSpatialPosition(x: x, z: z);
  double get y => groundY + jumpLift;
  bool get isPositionTraversable =>
      !isJumping &&
      x >= 0 &&
      z >= 0 &&
      x < scene.width &&
      z < scene.depth &&
      !_connectedCollides(_hitbox(_position));
  PlayerSpatialPosition? findNpcOverlapRecovery() {
    final origin = spatialPosition;
    final footprint = _hitbox(_position);
    final overlaps = <String>{};
    final overlappingEntities = <MapEntity>[];
    for (final source in entities) {
      final entity = entityProjection == null ? source : entityProjection!(source);
      if (entity != null && entity.kind == MapEntityKind.npc && entity.blocksMovement &&
          (_entityPresencePredicate?.call(entity) ?? true) && _entityCollides(footprint, entity)) {
        overlaps.add(entity.id);
        overlappingEntities.add(entity);
      }
    }
    if (overlaps.isEmpty || _collides(footprint, ignoredEntityIds: overlaps)) return null;
    final pending = Queue<({int dx, int dz})>()..add((dx: 0, dz: 0));
    final visited = <({int dx, int dz})>{(dx: 0, dz: 0)};
    while (pending.isNotEmpty) {
      final current = pending.removeFirst();
      final fromX = origin.x + current.dx / pixelsPerCell;
      final fromZ = origin.z + current.dz / pixelsPerCell;
      for (final delta in [(dx: 0, dz: -1), (dx: -1, dz: 0), (dx: 1, dz: 0), (dx: 0, dz: 1)]) {
        final next = (dx: current.dx + delta.dx, dz: current.dz + delta.dz);
        if (visited.contains(next)) continue;
        final toX = origin.x + next.dx / pixelsPerCell;
        final toZ = origin.z + next.dz / pixelsPerCell;
        final candidate = _actorFootprint(toX, toZ);
        final expanded = PixelRect(leftPx: candidate.rect.leftPx - 1,
            topPx: candidate.rect.topPx - 1, widthPx: candidate.rect.widthPx + 2,
            heightPx: candidate.rect.heightPx + 2);
        if (!overlappingEntities.any((entity) => _entityCollides(expanded, entity,
            offsetX: candidate.offsetX, offsetZ: candidate.offsetZ))) {
          continue;
        }
        if (!canTraverseActor(fromX, fromZ, toX, toZ, ignoredEntityIds: overlaps)) continue;
        visited.add(next);
        if (canTraverseActor(toX, toZ, toX, toZ)) {
          return PlayerSpatialPosition(x: toX, z: toZ);
        }
        if (overlappingEntities.any((entity) => _entityCollides(candidate.rect, entity,
            offsetX: candidate.offsetX, offsetZ: candidate.offsetZ))) {
          pending.add(next);
        }
      }
    }
    return null;
  }

  void setConnectedNeighbors(
      Map<MapConnectionDirection, SpatialMovementNeighbor> neighbors,
      {bool waitForReady = false}) {
    for (final entry in neighbors.entries) {
      final neighbor = entry.value;
      final aligned = switch (entry.key) {
        MapConnectionDirection.east => neighbor.offsetX == scene.width,
        MapConnectionDirection.west =>
          neighbor.offsetX == -neighbor.controller.scene.width,
        MapConnectionDirection.south => neighbor.offsetZ == scene.depth,
        MapConnectionDirection.north =>
          neighbor.offsetZ == -neighbor.controller.scene.depth,
      };
      if (!aligned || identical(neighbor.controller, this)) {
        throw ArgumentError('La carte voisine ne rejoint pas ce bord.');
      }
    }
    _connectedNeighbors = Map.unmodifiable(neighbors);
    _connectedTraversalEnabled = waitForReady || neighbors.isNotEmpty;
  }

  void adoptConnectionMotion(SpatialMovementController source) {
    final direction = source.edgeExitDirection;
    final neighbor = source._connectedNeighbors[direction];
    final arrival = source.connectionArrival;
    if (neighbor == null ||
        !identical(neighbor.controller, this) ||
        arrival == null) {
      throw StateError('Aucun raccord préparé ne mène à cette carte.');
    }
    _validateSpatialArrival(arrival, scene);
    final candidate = PixelPosition(
      leftPx: (arrival.x * pixelsPerCell).round() - 16,
      topPx: (arrival.z * pixelsPerCell).round() - 31,
    );
    final opposite = switch (direction!) {
      MapConnectionDirection.north => MapConnectionDirection.south,
      MapConnectionDirection.south => MapConnectionDirection.north,
      MapConnectionDirection.east => MapConnectionDirection.west,
      MapConnectionDirection.west => MapConnectionDirection.east,
    };
    final neighbors = {
      ..._connectedNeighbors,
      opposite: SpatialMovementNeighbor(
          controller: source,
          offsetX: -neighbor.offsetX,
          offsetZ: -neighbor.offsetZ)
    };
    final previousNeighbors = _connectedNeighbors;
    _connectedNeighbors = neighbors;
    if (_connectedCollides(_hitbox(candidate))) {
      _connectedNeighbors = previousNeighbors;
      throw StateError('Le raccord 3D est bloqué.');
    }
    _position = candidate;
    _connectedTraversalEnabled = true;
    _remainderX = source._remainderX;
    _remainderZ = source._remainderZ;
    _inputX = source._inputX;
    _inputZ = source._inputZ;
    _run = source._run;
    paused = source.paused;
    moving = source.moving;
    allowDiagonalMovement = source.allowDiagonalMovement;
    facing = source.facing;
    animationSeconds = source.animationSeconds;
    inputEpoch = source.inputEpoch;
    bumpedCell = null;
    edgeExitDirection = null;
    connectionArrival = null;
  }

  void setEntityPresencePredicate(bool Function(MapEntity entity)? predicate) {
    _entityPresencePredicate = predicate;
  }

  MapEntity? Function(MapEntity entity)? entityProjection;

  bool canTraverseActor(double fromX, double fromZ, double toX, double toZ,
      {String? ignoredEntityId,
      Set<String> ignoredEntityIds = const {},
      bool collideWithPlayer = false,
      bool allowConnectedMaps = false,
      Iterable<SpatialMovementNeighbor>? connectedMaps,
      PlayerSpatialPosition? playerPosition,
      SpatialActorRuntimeState? Function(String entityId)?
          actorStateProvider}) {
    bool inside(double x, double z) =>
        x.isFinite &&
        z.isFinite &&
        x >= 0 &&
        z >= 0 &&
        x < scene.width &&
        z < scene.depth;
    if (!fromX.isFinite || !fromZ.isFinite || !toX.isFinite || !toZ.isFinite) {
      return false;
    }
    final neighbors = connectedMaps ?? _connectedNeighbors.values;
    if (allowConnectedMaps) {
      if (_connectedMapAt(fromX, fromZ, neighbors: neighbors) == null ||
          _connectedMapAt(toX, toZ, neighbors: neighbors) == null) {
        return false;
      }
    } else if (!inside(fromX, fromZ) || !inside(toX, toZ)) {
      return false;
    }
    final count = math.max(
        1,
        (math.sqrt(math.pow(toX - fromX, 2) + math.pow(toZ - fromZ, 2)) *
                pixelsPerCell)
            .ceil());
    var previousX = fromX, previousZ = fromZ;
    for (var i = 0; i <= count; i++) {
      final x = fromX + (toX - fromX) * i / count;
      final z = fromZ + (toZ - fromZ) * i / count;
      final footprint = _actorFootprint(x, z);
      if ((allowConnectedMaps
              ? _connectedActorCollides(footprint.rect,
                  neighbors: neighbors,
                  offsetX: footprint.offsetX,
                  offsetZ: footprint.offsetZ,
                  ignoredEntityId: ignoredEntityId,
                  ignoredEntityIds: ignoredEntityIds,
                  actorStateProvider: actorStateProvider)
              : _collides(footprint.rect,
                  offsetX: footprint.offsetX,
                  offsetZ: footprint.offsetZ,
                  ignoredEntityId: ignoredEntityId,
                  ignoredEntityIds: ignoredEntityIds,
                  actorStateProvider: actorStateProvider)) ||
          collideWithPlayer &&
              _overlapsPlayer(footprint.rect,
                  offsetX: footprint.offsetX,
                  offsetZ: footprint.offsetZ,
                  playerPosition: playerPosition) ||
          !(allowConnectedMaps
              ? _canTraverseConnectedTerrain(previousX, previousZ, x, z, neighbors: neighbors)
              : canTraverseSpatialTerrainStep(scene, previousX, previousZ, x, z))) {
        return false;
      }
      previousX = x;
      previousZ = z;
    }
    return true;
  }

  bool wouldModelBlockActor(String instanceId, double x, double z) {
    final instance = _instancesById[instanceId];
    if (instance == null) {
      throw StateError('Modèle de collision absent : $instanceId');
    }
    final footprint = _actorFootprint(x, z);
    return _modelCollides(footprint.rect, instance,
        offsetX: footprint.offsetX, offsetZ: footprint.offsetZ);
  }

  void setRuntimeStateProviders({
    SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider,
    SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  }) {
    this.modelStateProvider = modelStateProvider;
    this.actorStateProvider = actorStateProvider;
  }

  void setInput({required int x, required int z, bool run = false}) {
    if (isJumping) return;
    if (_run != run) {
      animationSeconds = 0;
    }
    _inputX = x.sign;
    _inputZ = z.sign;
    _run = run;
  }

  void releaseInput() {
    bumpedCell = null;
    edgeExitDirection = null;
    connectionArrival = null;
    inputEpoch++;
    _inputX = _inputZ = 0;
    _run = false;
    moving = false;
    _remainderX = _remainderZ = 0;
    animationSeconds = 0;
  }

  void setPaused(bool value, {bool preserveInput = false}) {
    if (paused == value) {
      if (value &&
          !preserveInput &&
          (_inputX != 0 || _inputZ != 0 || _run || moving)) {
        releaseInput();
      }
      return;
    }
    paused = value;
    if (!preserveInput) releaseInput();
  }

  void setNativeTraversalPose(
      {required double x,
      required double z,
      required EntityFacing facing,
      required bool moving,
      required double animationSeconds}) {
    if (!paused ||
        !x.isFinite ||
        !z.isFinite ||
        !animationSeconds.isFinite ||
        animationSeconds < 0) {
      throw StateError('Une traversée native doit posséder le déplacement.');
    }
    final targetX = (x * pixelsPerCell).round() / pixelsPerCell;
    final targetZ = (z * pixelsPerCell).round() / pixelsPerCell;
    if ((this.x != targetX || this.z != targetZ) &&
        !canTraverseActor(this.x, this.z, targetX, targetZ)) {
      throw StateError('La sortie de la porte est bloquée.');
    }
    _position = PixelPosition(
        leftPx: (targetX * pixelsPerCell).round() - 16,
        topPx: (targetZ * pixelsPerCell).round() - 31);
    this.facing = facing;
    this.moving = moving;
    this.animationSeconds = animationSeconds;
  }

  void Function() captureNativeTraversalRollback() {
    if (!paused) {
      throw StateError('Une traversée native doit posséder le déplacement.');
    }
    final position = _position;
    final originalFacing = facing;
    final originalAnimationSeconds = animationSeconds;
    return () {
      if (!paused) {
        throw StateError('Une traversée native doit posséder le déplacement.');
      }
      releaseInput();
      _position = position;
      facing = originalFacing;
      animationSeconds = originalAnimationSeconds;
    };
  }

  void setDiagonalMovement(bool value) {
    allowDiagonalMovement = value;
    releaseInput();
  }

  void reset() => _reset(validateSpawn: true);

  void _reset({required bool validateSpawn}) {
    _ledgeJump = null;
    final candidate = PixelPosition(
      leftPx: (_spawn.x * pixelsPerCell).round() - 16,
      topPx: (_spawn.z * pixelsPerCell).round() - 31,
    );
    if (validateSpawn && _collides(_hitbox(candidate))) {
      throw StateError('Le point de départ 3D est bloqué.');
    }
    _position = candidate;
    paused = false;
    facing = _spawnFacing;
    releaseInput();
  }

  PixelRect _hitbox(PixelPosition position) =>
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: position, spriteWidthPx: 32, spriteHeightPx: 32);

  ({PixelRect rect, double offsetX, double offsetZ}) _actorFootprint(
      double x, double z) {
    final rect = _hitbox(PixelPosition(
        leftPx: (x * pixelsPerCell).round() - 16,
        topPx: (z * pixelsPerCell).round() - 31));
    return (
      rect: rect,
      offsetX: x - rect.bottomCenterPx.xPx / pixelsPerCell,
      offsetZ: z - rect.bottomCenterPx.yPx / pixelsPerCell
    );
  }

  void update(double dt) {
    bumpedCell = null;
    edgeExitDirection = null;
    connectionArrival = null;
    if (!dt.isFinite || dt <= 0 || paused) return;
    final elapsed = dt.clamp(0.0, .05);
    if (_ledgeJump != null) {
      _updateLedgeJump(elapsed);
      return;
    }
    var dx = _inputX, dz = _inputZ;
    if (!allowDiagonalMovement && dx != 0 && dz != 0) dx = 0;
    if (dx == 0 && dz == 0) {
      moving = false;
      animationSeconds = 0;
      return;
    }
    final nextFacing = dz < 0
        ? EntityFacing.north
        : dz > 0
            ? EntityFacing.south
            : dx < 0
                ? EntityFacing.west
                : EntityFacing.east;
    if (nextFacing != facing) animationSeconds = 0;
    facing = nextFacing;
    if ((dx == 0 || dz == 0) && _beginLedgeJump(dx, dz)) return;
    final speed = (_run ? 6.0 : 3.0) *
        pixelsPerCell *
        elapsed /
        (dx != 0 && dz != 0 ? math.sqrt2 : 1);
    _remainderX += dx * speed;
    _remainderZ += dz * speed;
    final stepX = _remainderX.truncate(), stepZ = _remainderZ.truncate();
    _remainderX -= stepX;
    _remainderZ -= stepZ;
    final before = _position;
    final originX = x, originZ = z;
    var collided = false;
    _position = PixelMovementResolverV1.resolveSeparateAxis(
        spriteTopLeftPx: before,
        deltaXPx: stepX,
        deltaYPx: stepZ,
        spriteWidthPx: 32,
        spriteHeightPx: 32,
        worldStaticObstaclesCollidePixelRect: (rect) {
          if (_connectedTraversalEnabled) {
            final blocked = _connectedCollides(rect) ||
                !_canTraverseConnectedTerrain(
                    rect.bottomCenterPx.xPx / pixelsPerCell +
                        (originX - rect.bottomCenterPx.xPx / pixelsPerCell)
                                .sign /
                            pixelsPerCell,
                    rect.bottomCenterPx.yPx / pixelsPerCell +
                        (originZ - rect.bottomCenterPx.yPx / pixelsPerCell)
                                .sign /
                            pixelsPerCell,
                    rect.bottomCenterPx.xPx / pixelsPerCell,
                    rect.bottomCenterPx.yPx / pixelsPerCell);
            if (blocked) collided = true;
            return blocked;
          }
          if (_collides(rect)) {
            collided = true;
            if ((dx == 0 || dz == 0) && !_collides(rect, ignoreBounds: true)) {
              edgeExitDirection = switch (facing) {
                EntityFacing.north when rect.topPx < 0 =>
                  MapConnectionDirection.north,
                EntityFacing.south
                    when rect.topPx + rect.heightPx >
                        scene.depth * pixelsPerCell =>
                  MapConnectionDirection.south,
                EntityFacing.west when rect.leftPx < 0 =>
                  MapConnectionDirection.west,
                EntityFacing.east
                    when rect.leftPx + rect.widthPx >
                        scene.width * pixelsPerCell =>
                  MapConnectionDirection.east,
                _ => null,
              };
            }
            return true;
          }
          final px = rect.bottomCenterPx.xPx / pixelsPerCell,
              pz = rect.bottomCenterPx.yPx / pixelsPerCell;
          final previousX = px + (originX - px).sign / pixelsPerCell;
          final previousZ = pz + (originZ - pz).sign / pixelsPerCell;
          final blocked = !canTraverseSpatialTerrainStep(
              scene, previousX, previousZ, px, pz);
          if (blocked) {
            collided = true;
          }
          return blocked;
        });
    final facingBlocked = switch (facing) {
      EntityFacing.north ||
      EntityFacing.south =>
        stepZ != 0 && _position.topPx == before.topPx,
      EntityFacing.east ||
      EntityFacing.west =>
        stepX != 0 && _position.leftPx == before.leftPx,
    };
    if (collided && facingBlocked) {
      bumpedCell = GridPos(
        x: originX.floor() + facing.asDirection.dx,
        y: originZ.floor() + facing.asDirection.dy,
      );
    }
    if (stepX != 0 || stepZ != 0) {
      moving =
          _position.leftPx != before.leftPx || _position.topPx != before.topPx;
    }
    if (moving) {
      animationSeconds += elapsed;
    } else if (stepX != 0 || stepZ != 0) {
      animationSeconds = 0;
    }
    if (_connectedTraversalEnabled &&
        (x < 0 || z < 0 || x >= scene.width || z >= scene.depth)) {
      final direction = x < 0
          ? MapConnectionDirection.west
          : x >= scene.width
              ? MapConnectionDirection.east
              : z < 0
                  ? MapConnectionDirection.north
                  : MapConnectionDirection.south;
      final neighbor = _connectedNeighbors[direction];
      if (neighbor != null) {
        connectionArrival = PlayerSpatialPosition(
            x: x - neighbor.offsetX, z: z - neighbor.offsetZ);
        edgeExitDirection = direction;
      }
      _position = before;
    }
  }

  bool _beginLedgeJump(int dx, int dz) {
    for (final ledge in scene.navigation.ledges) {
      if (ledge.dx != dx ||
          ledge.dz != dz ||
          (x - ledge.x - .5).abs() > .1875 ||
          (z - ledge.z - .5).abs() > .1875) {
        continue;
      }
      final sourceX = ledge.x + .5, sourceZ = ledge.z + .5;
      if (!canTraverseActor(x, z, sourceX, sourceZ) ||
          !_ledgeLandingFree(ledge)) {
        return false;
      }
      final source = PixelPosition(
          leftPx: (sourceX * pixelsPerCell).round() - 16,
          topPx: (sourceZ * pixelsPerCell).round() - 31);
      releaseInput();
      _position = source;
      _ledgeJump = _SpatialLedgeJump(
          ledge,
          source,
          scene.worldHeightAt(sourceX, sourceZ),
          scene.worldHeightAt(ledge.landingX + .5, ledge.landingZ + .5));
      moving = true;
      return true;
    }
    return false;
  }

  bool _ledgeLandingFree(SpatialLedge ledge) {
    final target = _actorFootprint(ledge.landingX + .5, ledge.landingZ + .5);
    return !_collides(target.rect,
        offsetX: target.offsetX, offsetZ: target.offsetZ);
  }

  void _updateLedgeJump(double elapsed) {
    final jump = _ledgeJump!;
    jump.elapsed = math.min(
        jump.elapsed + elapsed * 1000, jump.ledge.durationMs.toDouble());
    final t = jump.progress;
    _position = PixelPosition(
        leftPx: ((jump.ledge.x + .5 + jump.ledge.dx * jump.ledge.distance * t) *
                    pixelsPerCell)
                .round() -
            16,
        topPx: ((jump.ledge.z + .5 + jump.ledge.dz * jump.ledge.distance * t) *
                    pixelsPerCell)
                .round() -
            31);
    moving = true;
    if (t >= 1) {
      if (!_ledgeLandingFree(jump.ledge)) _position = jump.source;
      _ledgeJump = null;
      moving = false;
    }
  }

  SpatialMovementNeighbor? _connectedMapAt(double x, double z,
      {Iterable<SpatialMovementNeighbor>? neighbors}) {
    if (x >= 0 && z >= 0 && x < scene.width && z < scene.depth) {
      return _localMap;
    }
    for (final neighbor in neighbors ?? _connectedNeighbors.values) {
      final localX = x - neighbor.offsetX, localZ = z - neighbor.offsetZ;
      if (localX >= 0 &&
          localZ >= 0 &&
          localX < neighbor.controller.scene.width &&
          localZ < neighbor.controller.scene.depth) {
        return neighbor;
      }
    }
    return null;
  }

  bool _canTraverseConnectedTerrain(
      double ax, double az, double bx, double bz,
      {Iterable<SpatialMovementNeighbor>? neighbors}) {
    final a = _connectedMapAt(ax, az, neighbors: neighbors),
        b = _connectedMapAt(bx, bz, neighbors: neighbors);
    if (a == null || b == null) return false;
    if (identical(a.controller, b.controller)) {
      return canTraverseSpatialTerrainStep(a.controller.scene, ax - a.offsetX,
          az - a.offsetZ, bx - b.offsetX, bz - b.offsetZ);
    }
    return (a.controller.scene.worldHeightAt(ax - a.offsetX, az - a.offsetZ) -
                b.controller.scene
                    .worldHeightAt(bx - b.offsetX, bz - b.offsetZ))
            .abs() <=
        .25;
  }

  bool _connectedFootprintCovered(PixelRect rect, {
    required Iterable<SpatialMovementNeighbor> neighbors,
    required double offsetX,
    required double offsetZ,
  }) {
    var uncovered = [(left: rect.leftPx / pixelsPerCell + offsetX,
      top: rect.topPx / pixelsPerCell + offsetZ,
      right: (rect.leftPx + rect.widthPx) / pixelsPerCell + offsetX,
      bottom: (rect.topPx + rect.heightPx) / pixelsPerCell + offsetZ)];
    for (final owner in [_localMap, ...neighbors]) {
      final remaining = <({double left, double top, double right, double bottom})>[];
      for (final area in uncovered) {
        final left = math.max(area.left, owner.offsetX);
        final top = math.max(area.top, owner.offsetZ);
        final right = math.min(area.right, owner.offsetX + owner.controller.scene.width);
        final bottom = math.min(area.bottom, owner.offsetZ + owner.controller.scene.depth);
        if (left >= right || top >= bottom) {
          remaining.add(area);
          continue;
        }
        if (area.left < left) {
          remaining.add((left: area.left, top: area.top, right: left, bottom: area.bottom));
        }
        if (right < area.right) {
          remaining.add((left: right, top: area.top, right: area.right, bottom: area.bottom));
        }
        if (area.top < top) {
          remaining.add((left: left, top: area.top, right: right, bottom: top));
        }
        if (bottom < area.bottom) {
          remaining.add((left: left, top: bottom, right: right, bottom: area.bottom));
        }
      }
      if (remaining.isEmpty) {
        return true;
      }
      uncovered = remaining;
    }
    return false;
  }

  bool _connectedActorCollides(
    PixelRect rect, {
    required Iterable<SpatialMovementNeighbor> neighbors,
    required double offsetX,
    required double offsetZ,
    String? ignoredEntityId,
    Set<String> ignoredEntityIds = const {},
    SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  }) {
    if (!_connectedFootprintCovered(rect, neighbors: neighbors,
        offsetX: offsetX, offsetZ: offsetZ)) {
      return true;
    }
    final right = rect.leftPx + rect.widthPx;
    final bottom = rect.topPx + rect.heightPx;
    for (var pz = rect.topPx; pz < bottom; pz++) {
      for (var px = rect.leftPx; px < right; px++) {
        final x = px / pixelsPerCell + offsetX;
        final z = pz / pixelsPerCell + offsetZ;
        if (_connectedMapAt(x, z, neighbors: neighbors) == null ||
            px + 1 < right &&
                !_canTraverseConnectedTerrain(x, z, x + 1 / pixelsPerCell, z, neighbors: neighbors) ||
            pz + 1 < bottom &&
                !_canTraverseConnectedTerrain(x, z, x, z + 1 / pixelsPerCell, neighbors: neighbors)) {
          return true;
        }
      }
    }
    for (final neighbor in [_localMap, ...neighbors]) {
      final ox = (neighbor.offsetX * pixelsPerCell).round();
      final oz = (neighbor.offsetZ * pixelsPerCell).round();
      final localLeft =
          math.max((-offsetX * pixelsPerCell).ceil(), rect.leftPx - ox);
      final localTop =
          math.max((-offsetZ * pixelsPerCell).ceil(), rect.topPx - oz);
      final localRight = math.min(
          (neighbor.controller.scene.width * pixelsPerCell -
                  offsetX * pixelsPerCell)
              .ceil(),
          right - ox);
      final localBottom = math.min(
          (neighbor.controller.scene.depth * pixelsPerCell -
                  offsetZ * pixelsPerCell)
              .ceil(),
          bottom - oz);
      if (localLeft >= localRight || localTop >= localBottom) continue;
      final local = identical(neighbor.controller, this);
      if (neighbor.controller._collides(
          PixelRect(
              leftPx: localLeft,
              topPx: localTop,
              widthPx: localRight - localLeft,
              heightPx: localBottom - localTop),
          ignoreBounds: true,
          offsetX: offsetX,
          offsetZ: offsetZ,
          ignoredEntityId: local ? ignoredEntityId : null,
          ignoredEntityIds: local ? ignoredEntityIds : const {},
          actorStateProvider: local ? actorStateProvider : null)) {
        return true;
      }
    }
    for (final source in entities) {
      final entity =
          entityProjection == null ? source : entityProjection!(source);
      if (entity == null ||
          !entity.blocksMovement ||
          entity.id == ignoredEntityId ||
          ignoredEntityIds.contains(entity.id) ||
          !(_entityPresencePredicate?.call(entity) ?? true)) {
        continue;
      }
      if (_entityCollides(rect, entity,
          offsetX: offsetX,
          offsetZ: offsetZ,
          actorStateProvider: actorStateProvider)) {
        return true;
      }
    }
    return false;
  }

  bool _connectedCollides(PixelRect rect) {
    final left = rect.leftPx, top = rect.topPx;
    final right = left + rect.widthPx, bottom = top + rect.heightPx;
    if (left >= 0 &&
        top >= 0 &&
        right <= scene.width * pixelsPerCell &&
        bottom <= scene.depth * pixelsPerCell) {
      return _collides(rect);
    }
    for (var pz = top; pz < bottom; pz++) {
      for (var px = left; px < right; px++) {
        if (_connectedMapAt(px / pixelsPerCell, pz / pixelsPerCell) == null) {
          return true;
        }
        if (px + 1 < right &&
            !_canTraverseConnectedTerrain(
                px / pixelsPerCell,
                pz / pixelsPerCell,
                (px + 1) / pixelsPerCell,
                pz / pixelsPerCell)) {
          return true;
        }
        if (pz + 1 < bottom &&
            !_canTraverseConnectedTerrain(
                px / pixelsPerCell,
                pz / pixelsPerCell,
                px / pixelsPerCell,
                (pz + 1) / pixelsPerCell)) {
          return true;
        }
      }
    }
    for (final neighbor in [_localMap, ..._connectedNeighbors.values]) {
      final ox = (neighbor.offsetX * pixelsPerCell).round();
      final oz = (neighbor.offsetZ * pixelsPerCell).round();
      final localLeft = math.max(0, left - ox);
      final localTop = math.max(0, top - oz);
      final localRight =
          math.min(neighbor.controller.scene.width * pixelsPerCell, right - ox);
      final localBottom = math.min(
          neighbor.controller.scene.depth * pixelsPerCell, bottom - oz);
      if (localLeft >= localRight || localTop >= localBottom) continue;
      if (neighbor.controller._collides(PixelRect(
          leftPx: localLeft,
          topPx: localTop,
          widthPx: localRight - localLeft,
          heightPx: localBottom - localTop))) {
        return true;
      }
    }
    return false;
  }

  bool _collides(PixelRect rect,
      {bool ignoreBounds = false,
      double offsetX = 0,
      double offsetZ = 0,
      String? ignoredEntityId,
      Set<String> ignoredEntityIds = const {},
      SpatialActorRuntimeState? Function(String entityId)?
          actorStateProvider}) {
    final left = rect.leftPx / pixelsPerCell + offsetX,
        top = rect.topPx / pixelsPerCell + offsetZ,
        right = (rect.leftPx + rect.widthPx) / pixelsPerCell + offsetX,
        bottom = (rect.topPx + rect.heightPx) / pixelsPerCell + offsetZ;
    if (!ignoreBounds &&
        (left < 0 || top < 0 || right > scene.width || bottom > scene.depth)) {
      return true;
    }
    if (_terrainCollides(rect, offsetX: offsetX, offsetZ: offsetZ)) return true;
    for (var z = top.floor(); z < bottom.ceil(); z++) {
      for (var x = left.floor(); x < right.ceil(); x++) {
        if (x >= 0 &&
            x < scene.width &&
            z >= 0 &&
            z < scene.depth &&
            _blockedCells.contains(z * scene.width + x)) {
          return true;
        }
      }
    }
    for (final area in scene.navigation.blockedAreas) {
      if (left < area.x + area.width &&
          right > area.x &&
          top < area.z + area.depth &&
          bottom > area.z) {
        return true;
      }
    }
    for (final sourceEntity in entities) {
      final entity = entityProjection == null
          ? sourceEntity
          : entityProjection!(sourceEntity);
      if (entity == null || !entity.blocksMovement) continue;
      if (entity.id == ignoredEntityId || ignoredEntityIds.contains(entity.id)) continue;
      if (!(_entityPresencePredicate?.call(entity) ?? true)) continue;
      if (_entityCollides(rect, entity,
          offsetX: offsetX, offsetZ: offsetZ, actorStateProvider: actorStateProvider)) {
        return true;
      }
    }
    for (final instance in scene.instances) {
      if (instance.entityId case final entityId?) {
        final entity = _entitiesById[entityId];
        if (entity == null) {
          throw StateError('The bound 3D entity does not exist.');
        }
        if (!(_entityPresencePredicate?.call(entity) ?? true)) continue;
      }
      final blocks = modelStateProvider?.call(instance.id)?.blocksMovement ??
          instance.blocksMovement;
      if (!blocks) continue;
      if (_modelCollides(rect, instance, offsetX: offsetX, offsetZ: offsetZ)) {
        return true;
      }
    }
    return false;
  }

  bool _entityCollides(PixelRect rect, MapEntity entity,
      {double offsetX = 0, double offsetZ = 0,
      SpatialActorRuntimeState? Function(String entityId)? actorStateProvider}) {
    final left = rect.leftPx / pixelsPerCell + offsetX,
        top = rect.topPx / pixelsPerCell + offsetZ,
        right = (rect.leftPx + rect.widthPx) / pixelsPerCell + offsetX,
        bottom = (rect.topPx + rect.heightPx) / pixelsPerCell + offsetZ;
    final footprint = resolveEntityCollisionRectPx(entity,
        tileWidthPx: pixelsPerCell, tileHeightPx: pixelsPerCell);
    final state = actorStateProvider?.call(entity.id) ??
        this.actorStateProvider?.call(entity.id);
    final entityOffsetX = state == null ? 0 : state.x - entity.pos.x - .5;
    final entityOffsetZ = state == null ? 0 : state.z - entity.pos.y - .5;
    final hasExplicitCollision = entity.properties.keys.any(const {
      mapEntityCollisionWidthProperty,
      mapEntityCollisionHeightProperty,
      mapEntityCollisionOffsetXProperty,
      mapEntityCollisionOffsetYProperty,
      'collisionWidth',
      'collisionHeight',
      'collisionOffsetX',
      'collisionOffsetY',
    }.contains);
    final verticalAnchorOffset =
        entity.kind == MapEntityKind.npc && !hasExplicitCollision
          ? .5 - 1 / pixelsPerCell
          : 0;
    final npcLeft = footprint.leftPx / pixelsPerCell + entityOffsetX,
        npcTop = footprint.topPx / pixelsPerCell - verticalAnchorOffset + entityOffsetZ,
        npcRight = (footprint.leftPx + footprint.widthPx) / pixelsPerCell +
          entityOffsetX,
        npcBottom = (footprint.topPx + footprint.heightPx) / pixelsPerCell -
          verticalAnchorOffset +
          entityOffsetZ;
    return left < npcRight && right > npcLeft && top < npcBottom && bottom > npcTop;
  }

  bool _modelCollides(PixelRect rect, SpatialModelInstance instance,
      {double offsetX = 0, double offsetZ = 0}) {
    final left = rect.leftPx / pixelsPerCell + offsetX,
        top = rect.topPx / pixelsPerCell + offsetZ,
        right = (rect.leftPx + rect.widthPx) / pixelsPerCell + offsetX,
        bottom = (rect.topPx + rect.heightPx) / pixelsPerCell + offsetZ;
    final model = models[instance.modelId];
    if (model == null) {
      throw StateError('Modèle de collision absent : ${instance.modelId}');
    }
    final geometry =
        spatialModelWorldGeometry(instance, model, useCollisionBounds: true);
    final actorHeight = scene.worldHeightAt(
        rect.bottomCenterPx.xPx / pixelsPerCell + offsetX,
        rect.bottomCenterPx.yPx / pixelsPerCell + offsetZ);
    if (actorHeight >= geometry.maxY || actorHeight + 1.92 <= geometry.minY) {
      return false;
    }
    final player = [
      (x: left, z: top),
      (x: right, z: top),
      (x: right, z: bottom),
      (x: left, z: bottom)
    ];
    var separated = false;
    for (final axis in [
      (x: 1.0, z: 0.0),
      (x: 0.0, z: 1.0),
      (x: geometry.cos, z: -geometry.sin),
      (x: geometry.sin, z: geometry.cos)
    ]) {
      final a = geometry.polygon.map((p) => p.x * axis.x + p.z * axis.z),
          b = player.map((p) => p.x * axis.x + p.z * axis.z);
      if (a.reduce(math.max) <= b.reduce(math.min) ||
          b.reduce(math.max) <= a.reduce(math.min)) {
        separated = true;
        break;
      }
    }
    return !separated;
  }

  bool _overlapsPlayer(PixelRect rect,
      {required double offsetX,
      required double offsetZ,
      PlayerSpatialPosition? playerPosition}) {
    final landing = reservedLanding;
    if (landing != null) {
      final reserved = _actorFootprint(landing.x, landing.z);
      if (rect.leftPx / pixelsPerCell + offsetX <
              (reserved.rect.leftPx + reserved.rect.widthPx) / pixelsPerCell +
                  reserved.offsetX &&
          (rect.leftPx + rect.widthPx) / pixelsPerCell + offsetX >
              reserved.rect.leftPx / pixelsPerCell + reserved.offsetX &&
          rect.topPx / pixelsPerCell + offsetZ <
              (reserved.rect.topPx + reserved.rect.heightPx) / pixelsPerCell +
                  reserved.offsetZ &&
          (rect.topPx + rect.heightPx) / pixelsPerCell + offsetZ >
              reserved.rect.topPx / pixelsPerCell + reserved.offsetZ) {
        return true;
      }
    }
    final playerFootprint = playerPosition == null
        ? (rect: _hitbox(_position), offsetX: 0.0, offsetZ: 0.0)
        : _actorFootprint(playerPosition.x, playerPosition.z);
    final player = playerFootprint.rect;
    return rect.leftPx / pixelsPerCell + offsetX <
            (player.leftPx + player.widthPx) / pixelsPerCell +
                playerFootprint.offsetX &&
        (rect.leftPx + rect.widthPx) / pixelsPerCell + offsetX >
            player.leftPx / pixelsPerCell + playerFootprint.offsetX &&
        rect.topPx / pixelsPerCell + offsetZ <
            (player.topPx + player.heightPx) / pixelsPerCell +
                playerFootprint.offsetZ &&
        (rect.topPx + rect.heightPx) / pixelsPerCell + offsetZ >
            player.topPx / pixelsPerCell + playerFootprint.offsetZ;
  }

  bool _terrainCollides(PixelRect rect,
      {double offsetX = 0, double offsetZ = 0}) {
    final left = rect.leftPx,
        top = rect.topPx,
        right = left + rect.widthPx - 1,
        bottom = top + rect.heightPx - 1;
    bool traversable(int ax, int az, int bx, int bz) =>
        canTraverseSpatialTerrainStep(
            scene,
            ax / pixelsPerCell + offsetX,
            az / pixelsPerCell + offsetZ,
            bx / pixelsPerCell + offsetX,
            bz / pixelsPerCell + offsetZ);
    for (var x = left; x < right; x++) {
      if (!traversable(x, top, x + 1, top) ||
          !traversable(x, bottom, x + 1, bottom)) {
        return true;
      }
    }
    for (var z = top; z < bottom; z++) {
      if (!traversable(left, z, left, z + 1) ||
          !traversable(right, z, right, z + 1)) {
        return true;
      }
    }
    return false;
  }
}

final class _SpatialLedgeJump {
  _SpatialLedgeJump(this.ledge, this.source, this.sourceY, this.landingY);
  final SpatialLedge ledge;
  final PixelPosition source;
  final double sourceY, landingY;
  double elapsed = 0;
  double get progress => (elapsed / ledge.durationMs).clamp(0.0, 1.0);
}
