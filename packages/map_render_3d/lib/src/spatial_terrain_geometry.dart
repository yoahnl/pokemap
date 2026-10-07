import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

final class SpatialSurfacePatch {
  const SpatialSurfacePatch({
    required this.scene,
    required this.cell,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.ramp,
  });

  final MapSpatialScene scene;
  final (int, int) cell;
  final double left, top, right, bottom;
  final SpatialRamp? ramp;

  double heightAt(double x, double z) => ramp == null
      ? scene.heightAt(cell.$1, cell.$2)
      : ramp!.levelAt(x, z) * scene.levelHeight;

  List<Vector3> get corners => [
    Vector3(left, heightAt(left, top), top),
    Vector3(left, heightAt(left, bottom), bottom),
    Vector3(right, heightAt(right, bottom), bottom),
    Vector3(right, heightAt(right, top), top),
  ];
}

Iterable<SpatialSurfacePatch> spatialSurfacePatches(
  MapSpatialScene scene, {
  double left = 0,
  double top = 0,
  double? right,
  double? bottom,
}) sync* {
  final a = math.max(0.0, left), b = math.max(0.0, top);
  final c = math.min(scene.width.toDouble(), right ?? scene.width.toDouble());
  final d = math.min(scene.depth.toDouble(), bottom ?? scene.depth.toDouble());
  if (a >= c || b >= d) return;
  for (var cellZ = b.floor(); cellZ < d; cellZ++) {
    for (var cellX = a.floor(); cellX < c; cellX++) {
      final cellLeft = math.max(a, cellX.toDouble());
      final cellTop = math.max(b, cellZ.toDouble());
      final cellRight = math.min(c, cellX + 1.0);
      final cellBottom = math.min(d, cellZ + 1.0);
      final ramps = scene.navigation.ramps
          .where(
            (ramp) =>
                ramp.x <= cellRight &&
                ramp.x + ramp.width >= cellLeft &&
                ramp.z <= cellBottom &&
                ramp.z + ramp.depth >= cellTop,
          )
          .toList();
      final xs = <double>{cellLeft, cellRight};
      final zs = <double>{cellTop, cellBottom};
      for (final ramp in ramps) {
        for (final x in [ramp.x, ramp.x + ramp.width]) {
          if (x > cellLeft && x < cellRight) xs.add(x);
        }
        for (final z in [ramp.z, ramp.z + ramp.depth]) {
          if (z > cellTop && z < cellBottom) zs.add(z);
        }
      }
      final columns = xs.toList()..sort(), rows = zs.toList()..sort();
      for (var z = 0; z < rows.length - 1; z++) {
        for (var x = 0; x < columns.length - 1; x++) {
          final px = (columns[x] + columns[x + 1]) / 2;
          final pz = (rows[z] + rows[z + 1]) / 2;
          yield SpatialSurfacePatch(
            scene: scene,
            cell: (cellX, cellZ),
            left: columns[x],
            top: rows[z],
            right: columns[x + 1],
            bottom: rows[z + 1],
            ramp: ramps.where((r) => r.contains(px, pz)).firstOrNull,
          );
        }
      }
    }
  }
}

typedef SpatialTerrainFace = ({
  (int, int) cell,
  bool isTop,
  List<Vector3> positions,
  List<Vector2> uvs,
});

Iterable<SpatialTerrainFace> spatialTerrainFaces(
  MapSpatialScene scene, {
  double left = 0,
  double top = 0,
  double? right,
  double? bottom,
  bool repeatWalls = true,
}) sync* {
  for (final patch in spatialSurfacePatches(
    scene,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  )) {
    yield (
      cell: patch.cell,
      isTop: true,
      positions: patch.corners,
      uvs: [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)],
    );
    final a = patch.left, b = patch.top, c = patch.right, d = patch.bottom;
    for (final edge in [
      ((a, b), (a, d), (-1.0, 0.0)),
      ((c, d), (c, b), (1.0, 0.0)),
      ((c, b), (a, b), (0.0, -1.0)),
      ((a, d), (c, d), (0.0, 1.0)),
    ]) {
      final start = edge.$1, end = edge.$2, normal = edge.$3;
      final midpointX = (start.$1 + end.$1) / 2 + normal.$1 * .000001;
      final midpointZ = (start.$2 + end.$2) / 2 + normal.$2 * .000001;
      final outside =
          midpointX < 0 ||
          midpointZ < 0 ||
          midpointX >= scene.width ||
          midpointZ >= scene.depth;
      final neighbor = outside
          ? null
          : scene.navigation.ramps
                .where((r) => r.contains(midpointX, midpointZ))
                .firstOrNull;
      double neighborHeight((double, double) point) => outside
          ? -.15
          : neighbor == null
          ? scene.heightAt(midpointX.floor(), midpointZ.floor())
          : neighbor.levelAt(point.$1, point.$2) * scene.levelHeight;
      final highA = patch.heightAt(start.$1, start.$2);
      final highB = patch.heightAt(end.$1, end.$2);
      final lowA = neighborHeight(start), lowB = neighborHeight(end);
      var from = 0.0, to = 1.0;
      final deltaA = highA - lowA, deltaB = highB - lowB;
      if (deltaA <= .000001 && deltaB <= .000001) continue;
      if (deltaA < 0) from = -deltaA / (deltaB - deltaA);
      if (deltaB < 0) to = deltaA / (deltaA - deltaB);
      final polygon = [
        Vector2(from, lowA + (lowB - lowA) * from),
        Vector2(to, lowA + (lowB - lowA) * to),
        Vector2(to, highA + (highB - highA) * to),
        Vector2(from, highA + (highB - highA) * from),
      ];
      if (!repeatWalls) {
        yield (
          cell: patch.cell,
          isTop: false,
          positions: [
            for (final point in polygon)
              Vector3(
                start.$1 + (end.$1 - start.$1) * point.x,
                point.y,
                start.$2 + (end.$2 - start.$2) * point.x,
              ),
          ],
          uvs: [for (final point in polygon) Vector2(point.x, point.y)],
        );
        continue;
      }
      final minY = polygon.map((p) => p.y).reduce(math.min);
      final maxY = polygon.map((p) => p.y).reduce(math.max);
      for (
        var level = (minY / scene.levelHeight).floor();
        level < (maxY / scene.levelHeight).ceil();
        level++
      ) {
        final low = level * scene.levelHeight, high = low + scene.levelHeight;
        final clipped = _clipHeight(
          _clipHeight(polygon, low, true),
          high,
          false,
        );
        if (clipped.length < 3 || _polygonArea(clipped).abs() < .00000001)
          continue;
        final length = (end.$1 - start.$1).abs() + (end.$2 - start.$2).abs();
        final startU = normal.$1 < 0
            ? start.$2 - patch.cell.$2
            : normal.$1 > 0
            ? patch.cell.$2 + 1 - start.$2
            : normal.$2 < 0
            ? patch.cell.$1 + 1 - start.$1
            : start.$1 - patch.cell.$1;
        yield (
          cell: patch.cell,
          isTop: false,
          positions: [
            for (final point in clipped)
              Vector3(
                start.$1 + (end.$1 - start.$1) * point.x,
                point.y,
                start.$2 + (end.$2 - start.$2) * point.x,
              ),
          ],
          uvs: [
            for (final point in clipped)
              Vector2(
                startU + point.x * length,
                1 - (point.y - low) / scene.levelHeight,
              ),
          ],
        );
      }
    }
  }
}

List<Vector2> _clipHeight(List<Vector2> polygon, double height, bool above) {
  final result = <Vector2>[];
  if (polygon.isEmpty) return result;
  var previous = polygon.last;
  var wasInside = above ? previous.y >= height : previous.y <= height;
  for (final point in polygon) {
    final inside = above ? point.y >= height : point.y <= height;
    if (inside != wasInside) {
      final t = (height - previous.y) / (point.y - previous.y);
      result.add(Vector2(previous.x + (point.x - previous.x) * t, height));
    }
    if (inside) result.add(point);
    previous = point;
    wasInside = inside;
  }
  return result;
}

double _polygonArea(List<Vector2> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i], b = points[(i + 1) % points.length];
    area += a.x * b.y - b.x * a.y;
  }
  return area / 2;
}
