import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'spatial_surf_water.dart';
import 'spatial_movement_controller.dart';
import 'gameplay_world_state.dart';

GridPos? spatialFishingTarget(GameplayWorldState world, GameState state,
    {required Iterable<ProjectModel3dEntry> models,
    SpatialMovementController? movement}) {
  final map = world.map;
  final scene = map.spatialScene, position = state.playerSpatialPosition;
  if (scene == null ||
      position == null ||
      scene.width != map.size.width ||
      scene.depth != map.size.height ||
      position.x < 0 ||
      position.z < 0 ||
      position.x >= scene.width ||
      position.z >= scene.depth ||
      position.x * SpatialMovementController.pixelsPerCell !=
          (position.x * SpatialMovementController.pixelsPerCell).roundToDouble() ||
      position.z * SpatialMovementController.pixelsPerCell !=
          (position.z * SpatialMovementController.pixelsPerCell).roundToDouble() ||
      state.playerPosition !=
          GridPos(x: position.x.floor(), y: position.z.floor())) {
    return null;
  }
  final facing = state.playerFacing.asDirection;
  final targetX = position.x + facing.dx, targetZ = position.z + facing.dy;
  final water = SpatialSurfWater.fromMap(map);
  if (!water.contains(targetX, targetZ)) return null;
  final height = scene.worldHeightAt(position.x, position.z);
  for (var step = 1; step <= 4; step++) {
    final x = position.x + facing.dx * step / 4;
    final z = position.z + facing.dy * step / 4;
    final delta = scene.worldHeightAt(x, z) - height;
    if (delta > .25 + 1e-6 ||
        -delta > scene.navigation.maximumFishingDropWorld + 1e-6 ||
        scene.navigation.ledges.any((ledge) => ledge.containsBarrier(x, z))) {
      return null;
    }
  }
  final collision = movement ??
      SpatialMovementController.fromMap(
        map: map,
        models: models,
        spatialArrival: position,
        validateSpawn: false,
        modelStateProvider: (id) =>
            state.spatialWorldState.modelState(map.id, id),
        actorStateProvider: (id) =>
            state.spatialWorldState.actorState(map.id, id),
        entityPresencePredicate: (entity) =>
            (world.mapEntityPresencePredicate?.call(map.id, entity) ?? true) &&
            (entity.kind != MapEntityKind.npc ||
                (world.npcMapPresencePredicate?.call(map.id, entity) ?? true)),
      );
  if (collision.scene != scene ||
      !collision.canCastFishingLine(position.x, position.z, targetX, targetZ,
          surfWaterPredicate: water.contains)) {
    return null;
  }
  return GridPos(x: targetX.floor(), y: targetZ.floor());
}
