import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'spatial_movement_controller.dart';
import 'spatial_terrain_navigation.dart';

MapEntity? findSpatialNpcInteraction({
  required MapSpatialScene scene,
  required Iterable<MapEntity> entities,
  required double x,
  required double z,
  required EntityFacing facing,
}) {
  MapEntity? result;
  var nearest = double.infinity;
  for (final entity in entities) {
    if (entity.kind != MapEntityKind.npc || entity.npc == null) continue;
    final dx = entity.pos.x + .5 - x, dz = entity.pos.y + .5 - z;
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

EntityFacing spatialNpcFacingPlayer(MapEntity entity,
    {required double x, required double z}) {
  final dx = x - entity.pos.x - .5, dz = z - entity.pos.y - .5;
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
