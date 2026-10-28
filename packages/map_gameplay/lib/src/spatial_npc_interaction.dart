import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'spatial_movement_controller.dart';
import 'spatial_terrain_navigation.dart';
import 'spatial_model_geometry.dart';

MapEntity? findSpatialNpcInteraction({
  required MapSpatialScene scene,
  required Iterable<MapEntity> entities,
  required double x,
  required double z,
  required EntityFacing facing,
  SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  bool Function(double x, double z, String ignoredEntityId)? isPositionBlocked,
}) =>
    findSpatialEntityInteraction(
      scene: scene,
      entities: entities.where(
          (entity) => entity.kind == MapEntityKind.npc && entity.npc != null),
      x: x,
      z: z,
      facing: facing,
      actorStateProvider: actorStateProvider,
      isPositionBlocked: isPositionBlocked,
    );

MapEntity? findSpatialEntityInteraction({
  required MapSpatialScene scene,
  required Iterable<MapEntity> entities,
  required double x,
  required double z,
  required EntityFacing facing,
  SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
  bool Function(double x, double z, String ignoredEntityId)? isPositionBlocked,
}) {
  MapEntity? result;
  var nearest = double.infinity;
  final candidates = entities.toList();
  final overlapping = candidates.where((entity) {
    if (entity.interactionMode != MapEntityInteractionMode.overlap)
      return false;
    final state = actorStateProvider?.call(entity.id);
    final left = state == null ? entity.pos.x.toDouble() : state.x - .5;
    final top = state == null ? entity.pos.y.toDouble() : state.z - .5;
    return x >= left &&
        x < left + entity.size.width &&
        z >= top &&
        z < top + entity.size.height;
  }).toList();
  if (overlapping.isNotEmpty)
    return overlapping.length == 1 ? overlapping.single : null;
  for (final entity in candidates) {
    if (entity.kind == MapEntityKind.spawn) continue;
    if (entity.interactionMode == MapEntityInteractionMode.overlap) continue;
    final state = actorStateProvider?.call(entity.id);
    final anchorX = state?.x ?? entity.pos.x + .5;
    final anchorZ = state?.z ?? entity.pos.y + .5;
    final targetX = entity.presentation == null
        ? anchorX
        : x.clamp(anchorX, anchorX + entity.size.width - 1);
    final targetZ = entity.presentation == null
        ? anchorZ
        : z.clamp(anchorZ, anchorZ + entity.size.height - 1);
    final dx = targetX - x, dz = targetZ - z;
    final (forward, lateral) = switch (facing) {
      EntityFacing.north => (-dz, dx.abs()),
      EntityFacing.south => (dz, dx.abs()),
      EntityFacing.east => (dx, dz.abs()),
      EntityFacing.west => (-dx, dz.abs()),
    };
    final counter = _canReachAcrossCounter(scene, candidates, entity,
        x: x,
        z: z,
        targetX: targetX,
        targetZ: targetZ,
        facing: facing,
        actorStateProvider: actorStateProvider,
        isPositionBlocked: isPositionBlocked);
    if (forward > 0 &&
        (forward <= 1.25 || counter) &&
        lateral <= .5 &&
        forward < nearest &&
        _hasNavigableTerrainBetween(scene, x, z, x + dx, z + dz,
            ignoreBlockedAt: counter
                ? (px, pz) => _counterCellContains(x, z, facing, px, pz)
                : entity.kind == MapEntityKind.custom ||
                        entity.kind == MapEntityKind.sign
                    ? (px, pz) =>
                        px.floor() == targetX.floor() &&
                        pz.floor() == targetZ.floor()
                    : null)) {
      result = entity;
      nearest = forward;
    }
  }
  return result;
}

bool _counterCellContains(
    double x, double z, EntityFacing facing, double px, double pz) {
  final (dx, dz) = _facingDelta(facing);
  return px.floor() == x.floor() + dx && pz.floor() == z.floor() + dz;
}

(int, int) _facingDelta(EntityFacing facing) => switch (facing) {
      EntityFacing.north => (0, -1),
      EntityFacing.south => (0, 1),
      EntityFacing.east => (1, 0),
      EntityFacing.west => (-1, 0),
    };

bool _canReachAcrossCounter(
    MapSpatialScene scene, List<MapEntity> candidates, MapEntity entity,
    {required double x,
    required double z,
    required double targetX,
    required double targetZ,
    required EntityFacing facing,
    SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
    bool Function(double x, double z, String ignoredEntityId)?
        isPositionBlocked}) {
  final side = switch (facing) {
    EntityFacing.north => EntityFacing.south,
    EntityFacing.south => EntityFacing.north,
    EntityFacing.east => EntityFacing.west,
    EntityFacing.west => EntityFacing.east,
  };
  if (entity.size.width != 1 ||
      entity.size.height != 1 ||
      !entity.counterInteractionSides.contains(side) &&
          entity.npc?.counterInteractionSides.contains(side) != true) {
    return false;
  }
  final (dx, dz) = _facingDelta(facing);
  if (targetX.floor() != x.floor() + 2 * dx ||
      targetZ.floor() != z.floor() + 2 * dz) {
    return false;
  }
  final frontX = x.floor() + dx + .5, frontZ = z.floor() + dz + .5;
  if (!scene.navigation.blockedAreas
          .any((area) => area.contains(frontX, frontZ)) &&
      isPositionBlocked?.call(frontX, frontZ, entity.id) != true) {
    return false;
  }
  if (isPositionBlocked?.call(targetX, targetZ, entity.id) == true) {
    return false;
  }
  if ((scene.worldHeightAt(x, z) - scene.worldHeightAt(targetX, targetZ))
          .abs() >
      .000001) {
    return false;
  }
  return !candidates.any((candidate) {
    if (candidate.id == entity.id) return false;
    final pose = actorStateProvider?.call(candidate.id);
    final left = pose == null ? candidate.pos.x : pose.x.floor();
    final top = pose == null ? candidate.pos.y : pose.z.floor();
    return frontX >= left &&
        frontX < left + candidate.size.width &&
        frontZ >= top &&
        frontZ < top + candidate.size.height;
  });
}

SpatialModelInstance? findSpatialModelInteraction({
  required MapSpatialScene scene,
  required Iterable<ProjectModel3dEntry> models,
  required Iterable<SpatialModelInstance> instances,
  required double x,
  required double z,
  required EntityFacing facing,
  SpatialModelRuntimeState? Function(String instanceId)? modelStateProvider,
  bool Function(double x, double z)? additionalPositionBlocked,
}) {
  if (!x.isFinite ||
      !z.isFinite ||
      x < 0 ||
      z < 0 ||
      x >= scene.width ||
      z >= scene.depth) {
    return null;
  }
  final resources = {for (final model in models) model.id: model};
  final forwardAxis = switch (facing) {
    EntityFacing.north => (x: 0.0, z: -1.0),
    EntityFacing.south => (x: 0.0, z: 1.0),
    EntityFacing.east => (x: 1.0, z: 0.0),
    EntityFacing.west => (x: -1.0, z: 0.0),
  };
  SpatialModelInstance? result;
  var nearest = double.infinity;
  final actorHeight = scene.worldHeightAt(x, z);
  for (final instance in instances) {
    final model = resources[instance.modelId];
    if (model == null) {
      throw StateError('Modèle d’interaction absent : ${instance.modelId}');
    }
    final geometry = spatialModelWorldGeometry(instance, model, runtimeState: modelStateProvider?.call(instance.id));
    if (actorHeight >= geometry.maxY || actorHeight + 1.92 <= geometry.minY) {
      continue;
    }
    var polygon = <_InteractionProjection>[
      for (final point in geometry.polygon)
        (
          forward:
              (point.x - x) * forwardAxis.x + (point.z - z) * forwardAxis.z,
          lateral:
              -(point.x - x) * forwardAxis.z + (point.z - z) * forwardAxis.x,
        ),
    ];
    if (!polygon.any((point) => point.forward > 0)) continue;
    polygon = _clipInteractionPolygon(polygon, (point) => point.lateral + .5);
    polygon = _clipInteractionPolygon(polygon, (point) => .5 - point.lateral);
    polygon = _clipInteractionPolygon(polygon, (point) => point.forward);
    polygon = _clipInteractionPolygon(polygon, (point) => 1.25 - point.forward);
    if (polygon.isEmpty) continue;
    final distance = polygon.map((point) => point.forward).reduce(math.min);
    if (distance > nearest + .000000001 ||
        (distance - nearest).abs() <= .000000001 &&
            result != null &&
            instance.id.compareTo(result.id) >= 0) {
      continue;
    }
    final leading = polygon
        .where((point) => (point.forward - distance).abs() <= .000000001);
    final minLateral = leading.map((point) => point.lateral).reduce(math.min);
    final maxLateral = leading.map((point) => point.lateral).reduce(math.max);
    final lateral = 0.0.clamp(minLateral, maxLateral);
    if (!_hasNavigableTerrainBetween(
        scene,
        x,
        z,
        x + forwardAxis.x * distance - forwardAxis.z * lateral,
        z + forwardAxis.z * distance + forwardAxis.x * lateral,
        additionalPositionBlocked: additionalPositionBlocked,
        ignoreBlockedAt: (px, pz) =>
            _polygonOverlapsCell(geometry.polygon, px.floor(), pz.floor()))) {
      continue;
    }
    if (_modelOccludesInteraction(scene, resources, instance.id,
        x: x,
        z: z,
        actorHeight: actorHeight,
        forwardX: forwardAxis.x,
        forwardZ: forwardAxis.z,
        distance: distance,
        lateral: lateral,
        modelStateProvider: modelStateProvider)) {
      continue;
    }
    result = instance;
    nearest = distance;
  }
  return result;
}

typedef _InteractionProjection = ({double forward, double lateral});

List<_InteractionProjection> _clipInteractionPolygon(
    List<_InteractionProjection> points,
    double Function(_InteractionProjection) signedDistance) {
  if (points.isEmpty) return points;
  final clipped = <_InteractionProjection>[];
  var previous = points.last;
  var previousDistance = signedDistance(previous);
  for (final point in points) {
    final distance = signedDistance(point);
    if ((distance >= 0) != (previousDistance >= 0)) {
      final fraction = previousDistance / (previousDistance - distance);
      clipped.add((
        forward:
            previous.forward + (point.forward - previous.forward) * fraction,
        lateral:
            previous.lateral + (point.lateral - previous.lateral) * fraction,
      ));
    }
    if (distance >= 0) clipped.add(point);
    previous = point;
    previousDistance = distance;
  }
  return clipped;
}

EntityFacing spatialNpcFacingPlayer(MapEntity entity,
    {required double x,
    required double z,
    SpatialActorRuntimeState? actorState}) {
  final dx = x - (actorState?.x ?? entity.pos.x + .5),
      dz = z - (actorState?.z ?? entity.pos.y + .5);
  return dx.abs() > dz.abs()
      ? (dx < 0 ? EntityFacing.west : EntityFacing.east)
      : (dz < 0 ? EntityFacing.north : EntityFacing.south);
}

bool _polygonOverlapsCell(List<({double x, double z})> points, int x, int z) {
  var polygon = <_InteractionProjection>[
    for (final point in points) (forward: point.x, lateral: point.z),
  ];
  polygon = _clipInteractionPolygon(polygon, (p) => p.forward - x);
  polygon = _clipInteractionPolygon(polygon, (p) => x + 1 - p.forward);
  polygon = _clipInteractionPolygon(polygon, (p) => p.lateral - z);
  polygon = _clipInteractionPolygon(polygon, (p) => z + 1 - p.lateral);
  var area = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final next = polygon[(i + 1) % polygon.length];
    area +=
        polygon[i].forward * next.lateral - next.forward * polygon[i].lateral;
  }
  return area.abs() > .000000001;
}

bool _modelOccludesInteraction(MapSpatialScene scene,
    Map<String, ProjectModel3dEntry> models, String targetId,
    {required double x,
    required double z,
    required double actorHeight,
    required double forwardX,
    required double forwardZ,
    required double distance,
    required double lateral,
    SpatialModelRuntimeState? Function(String instanceId)?
        modelStateProvider}) {
  for (final obstacle in scene.instances) {
    final runtimeState = modelStateProvider?.call(obstacle.id);
    final blocks = runtimeState?.blocksMovement ?? obstacle.blocksMovement;
    if (obstacle.id == targetId || !blocks) continue;
    final model = models[obstacle.modelId];
    if (model == null) {
      throw StateError('Modèle d’interaction absent : ${obstacle.modelId}');
    }
    final geometry =
        spatialModelWorldGeometry(obstacle, model, useCollisionBounds: true, runtimeState: runtimeState);
    if (actorHeight >= geometry.maxY || actorHeight + 1.92 <= geometry.minY) {
      continue;
    }
    var polygon = <_InteractionProjection>[
      for (final point in geometry.polygon)
        (
          forward: (point.x - x) * forwardX + (point.z - z) * forwardZ,
          lateral: -(point.x - x) * forwardZ + (point.z - z) * forwardX
        ),
    ];
    polygon = _clipInteractionPolygon(polygon, (p) => p.forward - .000000001);
    polygon = _clipInteractionPolygon(
        polygon, (p) => distance - .000000001 - p.forward);
    polygon = _clipInteractionPolygon(
        polygon, (p) => p.lateral - lateral + .000000001);
    polygon = _clipInteractionPolygon(
        polygon, (p) => lateral + .000000001 - p.lateral);
    if (polygon.isNotEmpty) return true;
  }
  return false;
}

bool _hasNavigableTerrainBetween(
    MapSpatialScene scene, double ax, double az, double bx, double bz,
    {bool Function(double x, double z)? ignoreBlockedAt,
    bool Function(double x, double z)? additionalPositionBlocked}) {
  final steps = (math.max((bx - ax).abs(), (bz - az).abs()) *
          SpatialMovementController.pixelsPerCell)
      .ceil();
  var previousX = ax, previousZ = az;
  for (var step = 1; step <= steps; step++) {
    final x = ax + (bx - ax) * step / steps;
    final z = az + (bz - az) * step / steps;
    if (x < 0 ||
        x >= scene.width ||
        z < 0 ||
        z >= scene.depth ||
        additionalPositionBlocked?.call(x, z) == true ||
        (ignoreBlockedAt?.call(x, z) != true &&
            scene.navigation.blockedAreas.any((area) =>
                x >= area.x &&
                x < area.x + area.width &&
                z >= area.z &&
                z < area.z + area.depth)) ||
        !canTraverseSpatialTerrainStep(scene, previousX, previousZ, x, z)) {
      return false;
    }
    previousX = x;
    previousZ = z;
  }
  return true;
}
