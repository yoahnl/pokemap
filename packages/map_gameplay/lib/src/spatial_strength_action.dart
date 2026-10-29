import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'field_action.dart';
import 'field_obstacle_action.dart';
import 'spatial_field_obstacle_action.dart';
import 'spatial_field_obstacle_pose.dart';
import 'spatial_model_geometry.dart';
import 'spatial_movement_controller.dart';
import 'spatial_surf_water.dart';

typedef _Point = ({double x, double z});
typedef _Volume = ({List<_Point> polygon, double minY, double maxY});

final class SpatialStrengthPushTicket {
  const SpatialStrengthPushTicket._(
      {required this.entityId,
      required this.instanceId,
      required this.instance,
      required this.from,
      required this.to,
      required this.playerFrom,
      required this.playerTo,
      required this.facing,
      required this.issuedAtStateRevision,
      required MapEntity entity,
      required SpatialModelInstance modelInstance,
      required ProjectModel3dEntry model,
      required GridPos playerGrid,
      required PixelOffset? playerPixel,
      required PlayerSpatialPosition? playerSpatial,
      required SpatialModelRuntimeState? modelState,
      required double groundY})
      : _entity = entity,
        _modelInstance = modelInstance,
        _model = model,
        _playerGrid = playerGrid,
        _playerPixel = playerPixel,
        _playerSpatial = playerSpatial,
        _modelState = modelState,
        _groundY = groundY;

  final String entityId, instanceId;
  final MapInstanceRef instance;
  final GridPos from, to;
  final PlayerSpatialPosition playerFrom, playerTo;
  final EntityFacing facing;
  final int issuedAtStateRevision;
  final MapEntity _entity;
  final SpatialModelInstance _modelInstance;
  final ProjectModel3dEntry _model;
  final GridPos _playerGrid;
  final PixelOffset? _playerPixel;
  final PlayerSpatialPosition? _playerSpatial;
  final SpatialModelRuntimeState? _modelState;
  final double _groundY;
}

SpatialStrengthPushTicket? issueSpatialStrengthPushTicket(
    {required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required String entityId,
    required double x,
    required double z,
    required EntityFacing facing,
    required int stateRevision,
    ProjectSettings? projectSettings,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider}) {
  final resources = models.toList();
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (stateRevision < 0 ||
      instance == null ||
      !gameState.mapInstanceWorldState.isStrengthActive(instance) ||
      evaluateSpatialFieldObstacleAttempt(
          map: map,
          gameState: gameState,
          models: resources,
          entityId: entityId,
          x: x,
          z: z,
          facing: facing,
          projectSettings: projectSettings,
          entityIsPresent: entityIsPresent,
          actorStateProvider: actorStateProvider) is! CanUseFieldObstacle) {
    return null;
  }
  try {
    final entity = map.entities.singleWhere((entity) => entity.id == entityId);
    if (entity.fieldObstacle?.kind != FieldObstacleKind.strengthBoulder ||
        gameState.playerMovementMode != MovementMode.walk) {
      return null;
    }
    final binding = _strengthBinding(map, gameState, resources, entity);
    final from = gameState.mapInstanceWorldState
            .fieldObstaclePositionForMap(map.id, entityId) ??
        entity.pos;
    final (dx, dz) = _direction(facing);
    final to = GridPos(x: from.x + dx, y: from.y + dz);
    if (x + dx < 0 || z + dz < 0) {
      return null;
    }
    final playerFrom = PlayerSpatialPosition(x: x, z: z);
    playerFrom.validateGridPosition(gameState.playerPosition);
    final playerTo = PlayerSpatialPosition(x: x + dx, z: z + dz);
    final source = _obstacleVolume(
        map, gameState, entity, binding.instance, binding.model);
    final sweep = _sweep(source, dx.toDouble(), dz.toDouble());
    final ground = map.spatialScene!.worldHeightAt(x, z);
    if ((source.minY - ground).abs() > 1e-6 ||
        !_volumeClear(map, gameState, resources, entity, sweep,
            entityIsPresent: entityIsPresent,
            actorStateProvider: actorStateProvider) ||
        !_flatTerrain(map, sweep.polygon, ground) ||
        !_heroPathClear(map, gameState, resources, entity, source, playerFrom,
            playerTo, ground,
            entityIsPresent: entityIsPresent,
            actorStateProvider: actorStateProvider)) {
      return null;
    }
    return SpatialStrengthPushTicket._(
        entityId: entityId,
        instanceId: binding.instance.id,
        instance: instance,
        from: from,
        to: to,
        playerFrom: playerFrom,
        playerTo: playerTo,
        facing: facing,
        issuedAtStateRevision: stateRevision,
        entity: entity,
        modelInstance: binding.instance,
        model: binding.model,
        playerGrid: gameState.playerPosition,
        playerPixel: gameState.playerPixelPosition,
        playerSpatial: gameState.playerSpatialPosition,
        modelState:
            gameState.spatialWorldState.modelState(map.id, binding.instance.id),
        groundY: ground);
  } on Object {
    return null;
  }
}

FieldObstacleCommit commitSpatialStrengthPush(
    {required SpatialStrengthPushTicket ticket,
    required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    required int currentStateRevision,
    ProjectSettings? projectSettings,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider}) {
  if (currentStateRevision != ticket.issuedAtStateRevision) {
    return const FieldObstacleRefused(FieldActionRefusal.staleStateRevision);
  }
  if (gameState.playerPosition != ticket._playerGrid ||
      gameState.playerPixelPosition != ticket._playerPixel ||
      gameState.playerSpatialPosition != ticket._playerSpatial ||
      gameState.playerFacing != ticket.facing ||
      map.id != ticket.instance.mapId ||
      gameState.mapInstanceWorldState.instanceRef(map.id) != ticket.instance) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  final fresh = issueSpatialStrengthPushTicket(
      map: map,
      gameState: gameState,
      models: models,
      entityId: ticket.entityId,
      x: ticket.playerFrom.x,
      z: ticket.playerFrom.z,
      facing: ticket.facing,
      stateRevision: currentStateRevision,
      projectSettings: projectSettings,
      entityIsPresent: entityIsPresent,
      actorStateProvider: actorStateProvider);
  if (fresh == null) {
    return const FieldObstacleRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: FieldObstacleUnavailable(
            FieldObstacleBlockReason.blockedDestination));
  }
  if (fresh.from != ticket.from ||
      fresh.to != ticket.to ||
      fresh._entity != ticket._entity ||
      fresh._modelInstance != ticket._modelInstance ||
      fresh._model != ticket._model ||
      fresh._modelState != ticket._modelState ||
      fresh._groundY != ticket._groundY) {
    return const FieldObstacleRefused(FieldActionRefusal.targetChanged);
  }
  final dx = ticket.to.x - ticket.from.x, dz = ticket.to.y - ticket.from.y;
  return FieldObstacleApplied(
      gameState.copyWith(
          playerPosition: GridPos(
              x: ticket._playerGrid.x + dx, y: ticket._playerGrid.y + dz),
          playerSpatialPosition: ticket.playerTo,
          playerPixelPosition: ticket._playerPixel == null
              ? null
              : PixelOffset(
                  x: ticket._playerPixel!.x +
                      dx * (projectSettings?.tileWidth ?? 16),
                  y: ticket._playerPixel!.y +
                      dz * (projectSettings?.tileHeight ?? 16)),
          mapInstanceWorldState: gameState.mapInstanceWorldState
              .moveFieldObstacle(ticket.instance, ticket.entityId, ticket.to,
                  resetPolicy: ticket._entity.fieldObstacle!.resetPolicy)),
      ticket.entityId);
}

void validateSpatialStrengthSavedPositions(
    {required MapData map,
    required GameState gameState,
    required Iterable<ProjectModel3dEntry> models,
    bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider}) {
  final world = gameState.mapInstanceWorldState;
  final ids = {
    ...?world.instancesByMapId[map.id]?.fieldObstaclePositions.keys,
    ...?world.persistentFieldObstaclePositions[map.id]?.keys
  };
  if (ids.isEmpty) return;
  final resources = models.toList();
  if (map.id != gameState.currentMapId ||
      world.instanceRef(map.id) == null ||
      map.spatialScene == null) {
    throw StateError(
        'Saved Strength positions require the current spatial map instance.');
  }
  for (final id in ids) {
    final matches = map.entities.where((entity) => entity.id == id).toList();
    if (matches.length != 1) {
      throw StateError('Saved Strength entity is missing or ambiguous: $id');
    }
    final entity = matches.single;
    if (entity.fieldObstacle?.kind != FieldObstacleKind.strengthBoulder ||
        world.isFieldObstacleCleared(world.instanceRef(map.id)!, id) ||
        (world.persistentFieldObstaclePositions[map.id]?.containsKey(id) ??
                false) !=
            (entity.fieldObstacle!.resetPolicy ==
                FieldObstacleResetPolicy.persistent)) {
      throw StateError(
          'Saved Strength position does not match its authored obstacle: $id');
    }
    final binding = _strengthBinding(map, gameState, resources, entity);
    final volume = _obstacleVolume(
        map, gameState, entity, binding.instance, binding.model);
    if (!_volumeClear(map, gameState, resources, entity, volume,
            entityIsPresent: entityIsPresent,
            actorStateProvider: actorStateProvider) ||
        !_flatTerrain(map, volume.polygon, volume.minY)) {
      throw StateError(
          'Saved Strength endpoint is blocked or unsupported: $id');
    }
  }
}

({SpatialModelInstance instance, ProjectModel3dEntry model}) _strengthBinding(
    MapData map,
    GameState state,
    List<ProjectModel3dEntry> models,
    MapEntity entity) {
  if (!isValidSpatialFieldObstacle(map, entity)) {
    throw StateError('Invalid Strength binding.');
  }
  final instance = map.spatialScene!.instances
      .singleWhere((instance) => instance.entityId == entity.id);
  final model = models.singleWhere((model) => model.id == instance.modelId);
  final live = state.spatialWorldState.modelState(map.id, instance.id);
  if (model.rampProfile != null ||
      live != null &&
          (live.modelId != model.id ||
              !live.blocksMovement ||
              live.animationIndex != null ||
              live.normalizedTime != 0 ||
              live.translationX != 0 ||
              live.translationY != 0 ||
              live.translationZ != 0)) {
    throw StateError('Strength requires a static blocking model.');
  }
  return (instance: instance, model: model);
}

_Volume _obstacleVolume(MapData map, GameState state, MapEntity entity,
    SpatialModelInstance instance, ProjectModel3dEntry model,
    {bool authored = false}) {
  final geometry = spatialModelWorldGeometry(instance, model,
      useCollisionBounds: true,
      runtimeState: authored
          ? null
          : spatialFieldObstacleModelPose(
              mapId: map.id,
              entity: entity,
              instance: instance,
              world: state.mapInstanceWorldState,
              baseState:
                  state.spatialWorldState.modelState(map.id, instance.id)));
  if (geometry.maxY <= geometry.minY || _area(geometry.polygon).abs() < 1e-9) {
    throw StateError('Strength collision bounds require volume.');
  }
  return (polygon: geometry.polygon, minY: geometry.minY, maxY: geometry.maxY);
}

bool _volumeClear(MapData map, GameState state,
    List<ProjectModel3dEntry> models, MapEntity moving, _Volume volume,
    {bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider}) {
  final scene = map.spatialScene!;
  final world = state.mapInstanceWorldState;
  final instance = world.instanceRef(map.id)!;
  bool present(MapEntity entity) =>
      entity.kind != MapEntityKind.spawn &&
      !world.isFieldObstacleCleared(instance, entity.id) &&
      (entityIsPresent?.call(entity.id) ?? true);
  for (final other in scene.instances) {
    if (other.entityId == moving.id) {
      continue;
    }
    final entity =
        map.entities.where((entity) => entity.id == other.entityId).firstOrNull;
    if (other.entityId != null && (entity == null || !present(entity))) {
      continue;
    }
    final live = spatialFieldObstacleModelPose(
        mapId: map.id,
        entity: entity,
        instance: other,
        world: world,
        baseState: state.spatialWorldState.modelState(map.id, other.id));
    if (!(live?.blocksMovement ?? other.blocksMovement)) {
      continue;
    }
    final model = models.singleWhere((model) => model.id == other.modelId);
    final geometry = spatialModelWorldGeometry(other, model,
        useCollisionBounds: true, runtimeState: live);
    if (_volumesOverlap(volume, (
      polygon: geometry.polygon,
      minY: geometry.minY,
      maxY: geometry.maxY
    ))) {
      return false;
    }
  }
  for (final entity in map.entities) {
    if (entity.id == moving.id ||
        !entity.blocksMovement ||
        !present(entity) ||
        (entity.kind != MapEntityKind.npc &&
            scene.instances.any((model) => model.entityId == entity.id))) {
      continue;
    }
    final actor = actorStateProvider?.call(entity.id) ??
        state.spatialWorldState.actorState(map.id, entity.id);
    if (_volumesOverlap(volume, _entityVolume(map, entity, actor))) {
      return false;
    }
  }
  if (moving.fieldObstacle!.resetPolicy ==
      FieldObstacleResetPolicy.persistent) {
    for (final entity in persistentFieldObstacleResetBlockers(
        authoringMap: map, movingEntityId: moving.id)) {
      final bindings = scene.instances
          .where((model) => model.entityId == entity.id)
          .toList();
      final authored = bindings.isEmpty
          ? _entityVolume(map, entity, null)
          : _obstacleVolume(
              map,
              state,
              entity,
              bindings.single,
              models
                  .singleWhere((model) => model.id == bindings.single.modelId),
              authored: true);
      if (_volumesOverlap(volume, authored)) {
        return false;
      }
    }
  }
  return true;
}

_Volume _entityVolume(
    MapData map, MapEntity entity, SpatialActorRuntimeState? actor) {
  final rect =
      resolveEntityCollisionRectPx(entity, tileWidthPx: 16, tileHeightPx: 16);
  final dx = actor == null ? 0.0 : actor.x - entity.pos.x - .5;
  final dz = actor == null ? 0.0 : actor.z - entity.pos.y - .5;
  final explicit = entity.properties.keys.any(const {
    'collisionWidth',
    'collisionHeight',
    'collisionOffsetX',
    'collisionOffsetY',
    mapEntityCollisionWidthProperty,
    mapEntityCollisionHeightProperty,
    mapEntityCollisionOffsetXProperty,
    mapEntityCollisionOffsetYProperty
  }.contains);
  final anchor =
      entity.kind == MapEntityKind.npc && !explicit ? .5 - 1 / 16 : 0.0;
  final y = map.spatialScene!.worldHeightAt(
      actor?.x ?? entity.pos.x + .5, actor?.z ?? entity.pos.y + .5);
  return (
    polygon: _rectangle(rect.leftPx / 16 + dx, rect.topPx / 16 + dz - anchor,
        rect.widthPx / 16, rect.heightPx / 16),
    minY: y,
    maxY: y + 1.92
  );
}

bool _heroPathClear(
    MapData map,
    GameState state,
    List<ProjectModel3dEntry> models,
    MapEntity moving,
    _Volume boulder,
    PlayerSpatialPosition from,
    PlayerSpatialPosition to,
    double ground,
    {bool Function(String)? entityIsPresent,
    SpatialActorRuntimeState? Function(String)? actorStateProvider}) {
  final world = state.mapInstanceWorldState,
      instance = state.mapInstanceWorldState.instanceRef(map.id)!;
  final hero =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: PixelPosition(leftPx: 0, topPx: 0),
          spriteWidthPx: 32,
          spriteHeightPx: 32);
  final polygon = _rectangle(from.x + (hero.leftPx - 16) / 16,
      from.z + (hero.topPx - 31) / 16, hero.widthPx / 16, hero.heightPx / 16);
  if (_volumesOverlap(
      (polygon: polygon, minY: ground, maxY: ground + 1.92), boulder)) {
    return false;
  }
  final sweep = _sweep((polygon: polygon, minY: ground, maxY: ground + 1.92),
      to.x - from.x, to.z - from.z);
  if (!_flatTerrain(map, sweep.polygon, ground)) {
    return false;
  }
  final controller = SpatialMovementController.fromMap(
      map: map,
      models: models,
      spatialArrival: from,
      facing: state.playerFacing,
      validateSpawn: false,
      entityPresencePredicate: (entity) =>
          !world.isFieldObstacleCleared(instance, entity.id) &&
          (entityIsPresent?.call(entity.id) ?? true),
      entityProjection: (entity) {
        final position = world.fieldObstaclePositionForMap(map.id, entity.id);
        return position == null ? entity : entity.copyWith(pos: position);
      },
      modelStateProvider: (id) {
        final model = map.spatialScene!.instances
            .singleWhere((instance) => instance.id == id);
        return spatialFieldObstacleModelPose(
            mapId: map.id,
            entity: map.entities
                .where((entity) => entity.id == model.entityId)
                .firstOrNull,
            instance: model,
            world: world,
            baseState: state.spatialWorldState.modelState(map.id, id));
      },
      actorStateProvider: (id) =>
          actorStateProvider?.call(id) ??
          state.spatialWorldState.actorState(map.id, id));
  return controller.canTraverseActor(from.x, from.z, to.x, to.z,
      ignoredEntityId: moving.id);
}

bool _flatTerrain(MapData map, List<_Point> polygon, double height) {
  final scene = map.spatialScene!, water = SpatialSurfWater.fromMap(map);
  if (polygon.any(
      (p) => p.x < 0 || p.z < 0 || p.x > scene.width || p.z > scene.depth)) {
    return false;
  }
  final minX = polygon.map((p) => p.x).reduce(math.min).floor();
  final maxX = polygon.map((p) => p.x).reduce(math.max).ceil();
  final minZ = polygon.map((p) => p.z).reduce(math.min).floor();
  final maxZ = polygon.map((p) => p.z).reduce(math.max).ceil();
  for (var z = minZ; z < maxZ; z++) {
    for (var x = minX; x < maxX; x++) {
      final cell = _rectangle(x.toDouble(), z.toDouble(), 1, 1);
      if (!_polygonsOverlap(polygon, cell)) {
        continue;
      }
      if (x < 0 ||
          z < 0 ||
          x >= scene.width ||
          z >= scene.depth ||
          water.contains(x + .5, z + .5) ||
          map.layers.whereType<CollisionLayer>().any((layer) =>
              z * map.size.width + x < layer.collisions.length &&
              layer.collisions[z * map.size.width + x])) {
        return false;
      }
      final clipped = _clip(polygon, cell);
      if (!_effectiveFloorFlat(scene, clipped, x, z, height)) {
        return false;
      }
    }
  }
  for (final area in scene.navigation.blockedAreas) {
    if (_polygonsOverlap(
        polygon, _rectangle(area.x, area.z, area.width, area.depth))) {
      return false;
    }
  }
  for (final ramp in scene.navigation.ramps) {
    if (_polygonsOverlap(
        polygon, _rectangle(ramp.x, ramp.z, ramp.width, ramp.depth))) {
      return false;
    }
  }
  for (final ledge in scene.navigation.ledges) {
    if (_polygonsOverlap(
        polygon, _rectangle(ledge.x.toDouble(), ledge.z.toDouble(), 1, 1))) {
      return false;
    }
  }

  return true;
}

bool _effectiveFloorFlat(MapSpatialScene scene, List<_Point> polygon, int cellX,
    int cellZ, double height) {
  final flatSupports = <List<_Point>>[];
  final lowerSupports = <List<_Point>>[];
  for (final surface in scene.terrainSurfaces.candidatesAtCell(cellX, cellZ)) {
    for (final footprint in surface.footprints) {
      final area = [
        for (final point in footprint.points)
          (x: surface.x + point.x, z: surface.z + point.z)
      ];
      if (!_polygonsOverlap(polygon, area)) {
        continue;
      }
      final overlap = _clip(polygon, area);
      if (overlap.any((p) => surface.heightAt(p.x, p.z) > height + 1e-6)) {
        return false;
      }
      if (surface.gradientX.abs() <= 1e-12 &&
          surface.gradientZ.abs() <= 1e-12 &&
          (surface.height - height).abs() <= 1e-6) {
        flatSupports.add(overlap);
      } else {
        lowerSupports.add(overlap);
      }
    }
  }
  final requiredCoverage = (scene.heightAt(cellX, cellZ) - height).abs() > 1e-6
      ? [polygon]
      : lowerSupports;
  for (final area in requiredCoverage) {
    var uncovered = [area];
    for (final support in flatSupports) {
      uncovered = [
        for (final piece in uncovered) ..._subtractPolygon(piece, support)
      ];
      if (uncovered.isEmpty) {
        break;
      }
    }
    if (uncovered.isNotEmpty) {
      return false;
    }
  }
  return true;
}

List<List<_Point>> _subtractPolygon(
    List<_Point> subject, List<_Point> boundary) {
  var remaining = subject;
  final outside = <List<_Point>>[];
  final sign = _area(boundary) >= 0 ? 1.0 : -1.0;
  for (var i = 0; i < boundary.length; i++) {
    if (remaining.isEmpty) {
      break;
    }
    final a = boundary[i], b = boundary[(i + 1) % boundary.length];
    final fragment =
        _clipHalfPlane(remaining, (point) => -_cross(a, b, point) * sign);
    if (_area(fragment).abs() > 1e-9) {
      outside.add(fragment);
    }
    remaining =
        _clipHalfPlane(remaining, (point) => _cross(a, b, point) * sign);
  }
  return outside;
}

List<_Point> _clipHalfPlane(
    List<_Point> polygon, double Function(_Point) distanceFromEdge) {
  if (polygon.isEmpty) {
    return polygon;
  }
  final result = <_Point>[];
  var previous = polygon.last,
      previousDistance = distanceFromEdge(polygon.last);
  for (final point in polygon) {
    final distance = distanceFromEdge(point);
    if ((distance >= 0) != (previousDistance >= 0)) {
      final t = previousDistance / (previousDistance - distance);
      result.add((
        x: previous.x + (point.x - previous.x) * t,
        z: previous.z + (point.z - previous.z) * t
      ));
    }
    if (distance >= 0) {
      result.add(point);
    }
    previous = point;
    previousDistance = distance;
  }
  return result;
}

(int, int) _direction(EntityFacing facing) => switch (facing) {
      EntityFacing.north => (0, -1),
      EntityFacing.south => (0, 1),
      EntityFacing.east => (1, 0),
      EntityFacing.west => (-1, 0),
    };

List<_Point> _rectangle(double x, double z, double width, double depth) => [
      (x: x, z: z),
      (x: x + width, z: z),
      (x: x + width, z: z + depth),
      (x: x, z: z + depth)
    ];

_Volume _sweep(_Volume volume, double dx, double dz) => (
      polygon: _hull([
        ...volume.polygon,
        for (final p in volume.polygon) (x: p.x + dx, z: p.z + dz)
      ]),
      minY: volume.minY,
      maxY: volume.maxY
    );

bool _volumesOverlap(_Volume a, _Volume b) =>
    a.minY < b.maxY &&
    b.minY < a.maxY &&
    _polygonsOverlap(a.polygon, b.polygon);

bool _polygonsOverlap(List<_Point> a, List<_Point> b) {
  for (final polygon in [a, b]) {
    for (var i = 0; i < polygon.length; i++) {
      final p = polygon[i], q = polygon[(i + 1) % polygon.length];
      final dx = q.z - p.z, dz = p.x - q.x;
      final ap = a.map((p) => p.x * dx + p.z * dz),
          bp = b.map((p) => p.x * dx + p.z * dz);
      if (ap.reduce(math.max) <= bp.reduce(math.min) + 1e-9 ||
          bp.reduce(math.max) <= ap.reduce(math.min) + 1e-9) {
        return false;
      }
    }
  }
  return true;
}

double _cross(_Point a, _Point b, _Point c) =>
    (b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x);
double _area(List<_Point> polygon) {
  var result = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final p = polygon[i], q = polygon[(i + 1) % polygon.length];
    result += p.x * q.z - q.x * p.z;
  }
  return result / 2;
}

List<_Point> _hull(List<_Point> points) {
  final sorted = points.toSet().toList()
    ..sort((a, b) => a.x == b.x ? a.z.compareTo(b.z) : a.x.compareTo(b.x));
  List<_Point> half(Iterable<_Point> values) {
    final result = <_Point>[];
    for (final point in values) {
      while (result.length >= 2 &&
          _cross(result[result.length - 2], result.last, point) <= 0) {
        result.removeLast();
      }
      result.add(point);
    }
    return result..removeLast();
  }

  return [...half(sorted), ...half(sorted.reversed)];
}

List<_Point> _clip(List<_Point> subject, List<_Point> boundary) {
  var result = subject;
  final sign = _area(boundary) >= 0 ? 1.0 : -1.0;
  for (var i = 0; i < boundary.length; i++) {
    if (result.isEmpty) {
      break;
    }
    final a = boundary[i], b = boundary[(i + 1) % boundary.length];
    final output = <_Point>[];
    var previous = result.last, previousD = _cross(a, b, result.last) * sign;
    for (final point in result) {
      final distance = _cross(a, b, point) * sign;
      if ((distance >= 0) != (previousD >= 0)) {
        final t = previousD / (previousD - distance);
        output.add((
          x: previous.x + (point.x - previous.x) * t,
          z: previous.z + (point.z - previous.z) * t
        ));
      }
      if (distance >= 0) output.add(point);
      previous = point;
      previousD = distance;
    }
    result = output;
  }
  return result;
}
