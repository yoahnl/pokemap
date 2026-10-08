import 'dart:math' as math;

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

final class SpatialMovementController {
  SpatialMovementController({
    required MapSpatialScene scene,
    required Iterable<ProjectModel3dEntry> models,
    Iterable<MapEntity> entities = const [],
    bool Function(MapEntity entity)? entityPresencePredicate,
    SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider,
    SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  }) : this._(
          scene: scene,
          models: models,
          entities: entities,
          entityPresencePredicate: entityPresencePredicate,
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
    bool Function(MapEntity entity)? entityPresencePredicate,
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
    );
  }

  SpatialMovementController._({
    required this.scene,
    required Iterable<ProjectModel3dEntry> models,
    required Iterable<MapEntity> entities,
    required bool Function(MapEntity entity)? entityPresencePredicate,
    required this.modelStateProvider,
    required this.actorStateProvider,
    required SpatialSpawn spawn,
    required EntityFacing spawnFacing,
    required Set<int> blockedCells,
  })  : entities = List.unmodifiable(entities),
        models = {for (final model in models) model.id: model},
        _spawn = spawn,
        _spawnFacing = spawnFacing,
        _blockedCells = Set.unmodifiable(blockedCells),
        _entityPresencePredicate = entityPresencePredicate,
        allowDiagonalMovement = scene.navigation.allowDiagonalMovement {
    reset();
  }
  final SpatialSpawn _spawn;
  final EntityFacing _spawnFacing;
  final Set<int> _blockedCells;
  bool Function(MapEntity entity)? _entityPresencePredicate;
  GridPos? bumpedCell;
  MapConnectionDirection? edgeExitDirection;
  final MapSpatialScene scene;
  final List<MapEntity> entities;
  final Map<String, ProjectModel3dEntry> models;
  SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider;
  SpatialActorRuntimeState? Function(String entityId)? actorStateProvider;
  static const pixelsPerCell = 16;
  late PixelPosition _position;
  double _remainderX = 0, _remainderZ = 0;
  int _inputX = 0, _inputZ = 0;
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
  double get y => scene.worldHeightAt(x, z);
  void setEntityPresencePredicate(bool Function(MapEntity entity)? predicate) {
    _entityPresencePredicate = predicate;
  }

  bool canTraverseActor(double fromX, double fromZ, double toX, double toZ,
      {String? ignoredEntityId,
      bool collideWithPlayer = false,
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
    if (!inside(fromX, fromZ) || !inside(toX, toZ)) return false;
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
      if (_collides(footprint.rect,
              offsetX: footprint.offsetX,
              offsetZ: footprint.offsetZ,
              ignoredEntityId: ignoredEntityId,
              actorStateProvider: actorStateProvider) ||
          collideWithPlayer &&
              _overlapsPlayer(footprint.rect,
                  offsetX: footprint.offsetX,
                  offsetZ: footprint.offsetZ,
                  playerPosition: playerPosition) ||
          !canTraverseSpatialTerrainStep(scene, previousX, previousZ, x, z)) {
        return false;
      }
      previousX = x;
      previousZ = z;
    }
    return true;
  }

  bool wouldModelBlockActor(String instanceId, double x, double z) {
    final instance = scene.instances
        .where((instance) => instance.id == instanceId)
        .firstOrNull;
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
    inputEpoch++;
    _inputX = _inputZ = 0;
    _run = false;
    moving = false;
    _remainderX = _remainderZ = 0;
    animationSeconds = 0;
  }

  void setPaused(bool value) {
    paused = value;
    releaseInput();
  }

  void setDiagonalMovement(bool value) {
    allowDiagonalMovement = value;
    releaseInput();
  }

  void reset() {
    final candidate = PixelPosition(
      leftPx: (_spawn.x * pixelsPerCell).round() - 16,
      topPx: (_spawn.z * pixelsPerCell).round() - 31,
    );
    if (_collides(_hitbox(candidate))) {
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
    if (!dt.isFinite || dt <= 0 || paused) return;
    final elapsed = dt.clamp(0.0, .05);
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
  }

  bool _collides(PixelRect rect,
      {bool ignoreBounds = false,
      double offsetX = 0,
      double offsetZ = 0,
      String? ignoredEntityId,
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
    for (final entity in entities.where((entity) => entity.blocksMovement)) {
      if (entity.id == ignoredEntityId) continue;
      if (!(_entityPresencePredicate?.call(entity) ?? true)) continue;
      final footprint = resolveEntityCollisionRectPx(entity,
          tileWidthPx: pixelsPerCell, tileHeightPx: pixelsPerCell);
      final state = actorStateProvider?.call(entity.id) ??
          this.actorStateProvider?.call(entity.id);
      final entityOffsetX = state == null ? 0 : state.x - entity.pos.x - .5;
      final entityOffsetZ = state == null ? 0 : state.z - entity.pos.y - .5;
      final npcLeft = footprint.leftPx / pixelsPerCell + entityOffsetX,
          npcTop = footprint.topPx / pixelsPerCell - .5 + entityOffsetZ,
          npcRight = (footprint.leftPx + footprint.widthPx) / pixelsPerCell +
              entityOffsetX,
          npcBottom = (footprint.topPx + footprint.heightPx) / pixelsPerCell -
              .5 +
              entityOffsetZ;
      if (left < npcRight &&
          right > npcLeft &&
          top < npcBottom &&
          bottom > npcTop) {
        return true;
      }
    }
    for (final instance in scene.instances) {
      final blocks = modelStateProvider?.call(instance.id)?.blocksMovement ??
          instance.blocksMovement;
      if (!blocks) continue;
      if (_modelCollides(rect, instance, offsetX: offsetX, offsetZ: offsetZ)) {
        return true;
      }
    }
    return false;
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
    final geometry = spatialModelWorldGeometry(instance, model);
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
