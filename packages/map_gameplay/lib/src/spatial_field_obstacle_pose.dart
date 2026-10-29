import 'package:map_core/map_core.dart';

SpatialModelRuntimeState? spatialFieldObstacleModelPose({
  required String mapId,
  required MapEntity? entity,
  required SpatialModelInstance instance,
  required MapInstanceWorldState world,
  SpatialModelRuntimeState? baseState,
}) {
  if (entity?.fieldObstacle?.kind != FieldObstacleKind.strengthBoulder ||
      instance.entityId != entity!.id) {
    return baseState;
  }
  final position = world.fieldObstaclePositionForMap(mapId, entity.id);
  if (position == null) return baseState;
  final dx = position.x - entity.pos.x;
  final dz = position.y - entity.pos.y;
  if (dx == 0 && dz == 0) return baseState;
  final base = baseState ?? SpatialModelRuntimeState(modelId: instance.modelId,
      animationIndex: instance.animationIndex, normalizedTime: 0, blocksMovement: instance.blocksMovement);
  return base.copyWith(translationX: base.translationX + dx, translationZ: base.translationZ + dz);
}
