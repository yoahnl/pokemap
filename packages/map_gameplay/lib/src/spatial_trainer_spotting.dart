import 'package:map_core/map_core.dart';

final class SpatialTrainerSpot {
  const SpatialTrainerSpot(
      {required this.entity,
      required this.origin,
      required this.targetX,
      required this.targetZ,
      required this.playerFacing});
  final MapEntity entity;
  final SpatialActorRuntimeState origin;
  final double targetX, targetZ;
  final EntityFacing playerFacing;
}

SpatialTrainerSpot? findSpatialTrainerSpot({
  required Iterable<MapEntity> entities,
  required double playerX,
  required double playerZ,
  required bool Function(MapEntity) eligible,
  required bool Function(MapEntity, double, double, double, double) canTraverse,
  SpatialActorRuntimeState? Function(MapEntity)? actorState,
}) {
  if (!playerX.isFinite || !playerZ.isFinite) return null;
  SpatialTrainerSpot? result;
  var nearest = double.infinity;
  for (final entity in entities) {
    final npc = entity.npc;
    if (npc == null || npc.trainerId == null || npc.lineOfSightRange <= 0) {
      continue;
    }
    final origin = actorState?.call(entity) ??
        SpatialActorRuntimeState(
            x: entity.pos.x + .5, z: entity.pos.y + .5, facing: npc.facing);
    final (dx, dz) = switch (origin.facing) {
      EntityFacing.north => (0.0, -1.0),
      EntityFacing.south => (0.0, 1.0),
      EntityFacing.east => (1.0, 0.0),
      EntityFacing.west => (-1.0, 0.0),
    };
    final forward = (playerX - origin.x) * dx + (playerZ - origin.z) * dz;
    final lateral =
        ((playerX - origin.x) * dz - (playerZ - origin.z) * dx).abs();
    if (forward < .95 ||
        forward > npc.lineOfSightRange + .05 ||
        lateral > .5 ||
        forward >= nearest ||
        !eligible(entity)) {
      continue;
    }
    final targetX = playerX - dx, targetZ = playerZ - dz;
    if (!canTraverse(entity, origin.x, origin.z, targetX, targetZ)) continue;
    nearest = forward;
    result = SpatialTrainerSpot(
        entity: entity,
        origin: origin,
        targetX: targetX,
        targetZ: targetZ,
        playerFacing: switch (origin.facing) {
          EntityFacing.north => EntityFacing.south,
          EntityFacing.south => EntityFacing.north,
          EntityFacing.east => EntityFacing.west,
          EntityFacing.west => EntityFacing.east,
        });
  }
  return result;
}
