import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

double? spatialContentDragHeight(
  Vector3 origin,
  Vector3 direction,
  (int, int) anchor,
) {
  final horizontalLength =
      direction.x * direction.x + direction.z * direction.z;
  if (horizontalLength < .000001) return null;
  final distance =
      ((anchor.$1 - origin.x) * direction.x +
          (anchor.$2 - origin.z) * direction.z) /
      horizontalLength;
  if (!distance.isFinite || distance < 0) return null;
  return origin.y + direction.y * distance;
}

(int, int)? pickSpatialPlaneCell(
  Vector3 origin,
  Vector3 direction,
  double height,
) {
  if (direction.y.abs() < .000001) return null;
  final distance = (height - origin.y) / direction.y;
  if (!distance.isFinite || distance < 0) return null;
  final point = origin + direction * distance;
  return (point.x.floor(), point.z.floor());
}

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

final class SpatialContentDrag {
  const SpatialContentDrag({required this.anchor, required this.pointerOrigin});
  final (int, int) anchor, pointerOrigin;
  (int, int) cellAt((int, int) pointer) => (
    anchor.$1 + pointer.$1 - pointerOrigin.$1,
    anchor.$2 + pointer.$2 - pointerOrigin.$2,
  );
}
