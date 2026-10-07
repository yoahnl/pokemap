import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

(int, int)? pickSpatialCell(
  MapSpatialScene scene,
  Vector3 origin,
  Vector3 direction,
) {
  var nearest = double.infinity;
  (int, int)? selected;
  for (var z = 0; z < scene.depth; z++) {
    for (var x = 0; x < scene.width; x++) {
      var enter = 0.0;
      var leave = double.infinity;
      final minimum = [x.toDouble(), -0.15, z.toDouble()];
      final maximum = [x + 1.0, scene.heightAt(x, z), z + 1.0];
      for (var axis = 0; axis < 3; axis++) {
        if (direction[axis].abs() < 0.000001) {
          if (origin[axis] < minimum[axis] || origin[axis] >= maximum[axis]) {
            leave = -1;
            break;
          }
        } else {
          final first = (minimum[axis] - origin[axis]) / direction[axis];
          final last = (maximum[axis] - origin[axis]) / direction[axis];
          enter = math.max(enter, math.min(first, last));
          leave = math.min(leave, math.max(first, last));
        }
      }
      if (leave >= enter && enter < nearest) {
        nearest = enter;
        selected = (x, z);
      }
    }
  }
  return selected;
}
