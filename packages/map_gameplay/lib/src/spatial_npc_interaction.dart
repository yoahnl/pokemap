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
}) =>
    findSpatialEntityInteraction(
      scene: scene,
      entities: entities.where(
          (entity) => entity.kind == MapEntityKind.npc && entity.npc != null),
      x: x,
      z: z,
      facing: facing,
      actorStateProvider: actorStateProvider,
    );

MapEntity? findSpatialEntityInteraction({
  required MapSpatialScene scene,
  required Iterable<MapEntity> entities,
  required double x,
  required double z,
  required EntityFacing facing,
  SpatialActorRuntimeState? Function(String entityId)? actorStateProvider,
}) {
  MapEntity? result;
  var nearest = double.infinity;
  for (final entity in entities) {
    if (entity.kind == MapEntityKind.spawn) continue;
    final state = actorStateProvider?.call(entity.id);
    final dx = (state?.x ?? entity.pos.x + .5) - x,
        dz = (state?.z ?? entity.pos.y + .5) - z;
    final (forward, lateral) = switch (facing) {
      EntityFacing.north => (-dz, dx.abs()),
      EntityFacing.south => (dz, dx.abs()),
      EntityFacing.east => (dx, dz.abs()),
      EntityFacing.west => (-dx, dz.abs()),
    };
    if (forward > 0 &&
        forward <= 1.25 &&
        lateral <= .5 &&
        forward < nearest &&
        _hasNavigableTerrainBetween(scene, x, z, x + dx, z + dz)) {
      result = entity;
      nearest = forward;
    }
  }
  return result;
}

SpatialModelInstance? findSpatialModelInteraction({
  required MapSpatialScene scene,
  required Iterable<ProjectModel3dEntry> models,
  required Iterable<SpatialModelInstance> instances,
  required double x,
  required double z,
  required EntityFacing facing,
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
    final geometry = spatialModelWorldGeometry(instance, model);
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
        z + forwardAxis.z * distance + forwardAxis.x * lateral)) {
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

bool _hasNavigableTerrainBetween(
    MapSpatialScene scene, double ax, double az, double bx, double bz) {
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
        scene.navigation.blockedAreas.any((area) =>
            x >= area.x &&
            x < area.x + area.width &&
            z >= area.z &&
            z < area.z + area.depth) ||
        !canTraverseSpatialTerrainStep(scene, previousX, previousZ, x, z)) {
      return false;
    }
    previousX = x;
    previousZ = z;
  }
  return true;
}
