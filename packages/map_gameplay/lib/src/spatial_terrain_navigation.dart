import 'dart:math' as math;

import 'package:map_core/map_core.dart';

bool canTraverseSpatialTerrainStep(
        MapSpatialScene scene, double ax, double az, double bx, double bz) =>
    (scene.worldHeightAt(bx, bz) - scene.worldHeightAt(ax, az)).abs() <= .25 ||
    _rampAllowsTransition(scene, ax, az, bx, bz);

bool _rampAllowsTransition(
    MapSpatialScene scene, double ax, double az, double bx, double bz) {
  for (final ramp in scene.navigation.ramps) {
    final vertical = ramp.direction == SpatialRampDirection.north ||
        ramp.direction == SpatialRampDirection.south;
    final aligned = vertical
        ? ax >= ramp.x &&
            ax <= ramp.x + ramp.width &&
            bx >= ramp.x &&
            bx <= ramp.x + ramp.width
        : az >= ramp.z &&
            az <= ramp.z + ramp.depth &&
            bz >= ramp.z &&
            bz <= ramp.z + ramp.depth;
    final intersects = vertical
        ? math.max(az, bz) >= ramp.z && math.min(az, bz) <= ramp.z + ramp.depth
        : math.max(ax, bx) >= ramp.x && math.min(ax, bx) <= ramp.x + ramp.width;
    if (aligned &&
        intersects &&
        (scene.worldHeightAt(ax, az) - ramp.levelAt(ax, az) * scene.levelHeight)
                .abs() <
            .0001 &&
        (scene.worldHeightAt(bx, bz) - ramp.levelAt(bx, bz) * scene.levelHeight)
                .abs() <
            .0001) {
      return true;
    }
  }
  return false;
}
