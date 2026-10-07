import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import 'spatial_terrain_geometry.dart';

final class SpatialSurfaceHit {
  const SpatialSurfaceHit({required this.cell, required this.position});

  final (int, int) cell;
  final Model3dVector3 position;
}

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
) => pickSpatialSurface(scene, origin, direction)?.cell;

SpatialSurfaceHit? pickSpatialSurface(
  MapSpatialScene scene,
  Vector3 origin,
  Vector3 direction,
) {
  var nearest = double.infinity;
  SpatialSurfaceHit? selected;
  var maximumLevel = scene.heightLevels.reduce(math.max);
  for (final ramp in scene.navigation.ramps) {
    maximumLevel = math.max(maximumLevel, ramp.highLevel);
  }
  final maximumHeight = maximumLevel * scene.levelHeight;
  for (var z = 0; z < scene.depth; z++) {
    for (var x = 0; x < scene.width; x++) {
      var enter = 0.0, leave = nearest;
      final minimum = [x.toDouble(), -.15, z.toDouble()];
      final maximum = [x + 1.0, maximumHeight, z + 1.0];
      for (var axis = 0; axis < 3; axis++) {
        if (direction[axis].abs() < .000000001) {
          if (origin[axis] < minimum[axis] || origin[axis] > maximum[axis]) {
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
      if (leave < enter) continue;
      for (final face in spatialTerrainFaces(
        scene,
        left: x.toDouble(),
        top: z.toDouble(),
        right: x + 1.0,
        bottom: z + 1.0,
        repeatWalls: false,
      )) {
        for (var i = 1; i < face.positions.length - 1; i++) {
          final distance = _rayTriangle(
            origin,
            direction,
            face.positions[0],
            face.positions[i],
            face.positions[i + 1],
          );
          if (distance != null && distance < nearest) {
            nearest = distance;
            final point = origin + direction * distance;
            final cell = (point.x.floor(), point.z.floor());
            final selectedCell =
                face.isTop &&
                    cell.$1 >= 0 &&
                    cell.$2 >= 0 &&
                    cell.$1 < scene.width &&
                    cell.$2 < scene.depth &&
                    (scene.worldHeightAt(point.x, point.z) - point.y).abs() <
                        .000001
                ? cell
                : face.cell;
            selected = SpatialSurfaceHit(
              cell: selectedCell,
              position: Model3dVector3(x: point.x, y: point.y, z: point.z),
            );
          }
        }
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

double? _rayTriangle(
  Vector3 origin,
  Vector3 direction,
  Vector3 a,
  Vector3 b,
  Vector3 c,
) {
  final edge1 = b - a, edge2 = c - a;
  final p = direction.cross(edge2);
  final determinant = edge1.dot(p);
  if (determinant.abs() < .000000001) return null;
  final inverse = 1 / determinant;
  final t = origin - a;
  final u = t.dot(p) * inverse;
  if (u < 0 || u > 1) return null;
  final q = t.cross(edge1);
  final v = direction.dot(q) * inverse;
  if (v < 0 || u + v > 1) return null;
  final distance = edge2.dot(q) * inverse;
  return distance >= 0 ? distance : null;
}
