import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'spatial_surf_water.dart';

GridPos? spatialFishingTarget(MapData map, GameState state) {
  final scene = map.spatialScene, position = state.playerSpatialPosition;
  if (scene == null ||
      position == null ||
      scene.width != map.size.width ||
      scene.depth != map.size.height ||
      position.x < 0 ||
      position.z < 0 ||
      position.x >= scene.width ||
      position.z >= scene.depth ||
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
    if ((scene.worldHeightAt(x, z) - height).abs() > .25 + 1e-6 ||
        scene.navigation.ledges.any((ledge) => ledge.containsBarrier(x, z))) {
      return null;
    }
  }
  return GridPos(x: targetX.floor(), y: targetZ.floor());
}
