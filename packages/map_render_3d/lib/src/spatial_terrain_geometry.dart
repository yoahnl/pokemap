import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

part 'spatial_ground_polygon.dart';

final class SpatialSurfacePatch {
  const SpatialSurfacePatch({
    required this.scene,
    required this.cell,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.ramp,
    this.groundHeight,
    this.groundGradientX = 0,
    this.groundGradientZ = 0,
    this.footprint,
  });

  final MapSpatialScene scene;
  final (int, int) cell;
  final double left, top, right, bottom;
  final SpatialRamp? ramp;
  final double? groundHeight;
  final double groundGradientX;
  final double groundGradientZ;
  final List<BorderGroundPoint>? footprint;

  double heightAt(double x, double z) => ramp == null
      ? (groundHeight ?? scene.heightAt(cell.$1, cell.$2)) +
            groundGradientX * x +
            groundGradientZ * z
      : ramp!.levelAt(x, z) * scene.levelHeight;

  List<Vector3> get corners => footprint != null
      ? [
          for (final point in footprint!)
            Vector3(point.x, heightAt(point.x, point.z), point.z),
        ]
      : [
          Vector3(left, heightAt(left, top), top),
          Vector3(left, heightAt(left, bottom), bottom),
          Vector3(right, heightAt(right, bottom), bottom),
          Vector3(right, heightAt(right, top), top),
        ];
}

final class SpatialFlatGroundSurface {
  SpatialFlatGroundSurface({
    required this.height,
    this.gradientX = 0,
    this.gradientZ = 0,
    required List<BorderGroundFootprint> footprints,
  }) : footprints = List.unmodifiable(footprints) {
    if (!height.isFinite ||
        !gradientX.isFinite ||
        !gradientZ.isFinite ||
        footprints.isEmpty) {
      throw ArgumentError(
        'Flat surfaces require a finite height and footprints',
      );
    }
  }

  final double height;
  final double gradientX;
  final double gradientZ;
  final List<BorderGroundFootprint> footprints;

  double heightAt(double x, double z) => height + gradientX * x + gradientZ * z;
}

Iterable<SpatialSurfacePatch> spatialFlatGroundPatches(
  MapSpatialScene scene, {
  required SpatialFlatGroundSurface surface,
  double left = 0,
  double top = 0,
  double? right,
  double? bottom,
}) sync* {
  final a = math.max(0.0, left), b = math.max(0.0, top);
  final c = math.min(scene.width.toDouble(), right ?? scene.width.toDouble());
  final d = math.min(scene.depth.toDouble(), bottom ?? scene.depth.toDouble());
  if (a >= c || b >= d) return;
  for (var z = b.floor(); z < d; z++) {
    for (var x = a.floor(); x < c; x++) {
      final l = math.max(a, x.toDouble()), t = math.max(b, z.toDouble());
      final r = math.min(c, x + 1.0), end = math.min(d, z + 1.0);
      var remaining = [
        [
          BorderGroundPoint(x: l, z: t),
          BorderGroundPoint(x: r, z: t),
          BorderGroundPoint(x: r, z: end),
          BorderGroundPoint(x: l, z: end),
        ],
      ];
      for (final footprint in surface.footprints) {
        final outside = <List<BorderGroundPoint>>[];
        for (final polygon in remaining) {
          final split = _splitGroundPolygon(polygon, footprint.points);
          outside.addAll(split.outside);
          if (split.inside.isEmpty) continue;
          final ordered = _groundPolygonArea(split.inside) < 0
              ? split.inside
              : split.inside.reversed.toList();
          final pieces = ordered.length <= 4
              ? [ordered]
              : [
                  for (var i = 1; i < ordered.length - 1; i++)
                    [ordered.first, ordered[i], ordered[i + 1]],
                ];
          for (final piece in pieces) {
            if (_groundPolygonArea(piece).abs() <= 1e-12) continue;
            yield SpatialSurfacePatch(
              scene: scene,
              cell: (x, z),
              left: l,
              top: t,
              right: r,
              bottom: end,
              ramp: null,
              groundHeight: surface.height,
              groundGradientX: surface.gradientX,
              groundGradientZ: surface.gradientZ,
              footprint: piece.length == 3 ? [...piece, piece.last] : piece,
            );
          }
        }
        remaining = outside;
        if (remaining.isEmpty) break;
      }
    }
  }
}

Iterable<SpatialSurfacePatch> spatialSurfacePatches(
  MapSpatialScene scene, {
  double left = 0,
  double top = 0,
  double? right,
  double? bottom,
  SpatialBorderGroundReplacementIndex groundReplacements = const {},
}) sync* {
  final a = math.max(0.0, left), b = math.max(0.0, top);
  final c = math.min(scene.width.toDouble(), right ?? scene.width.toDouble());
  final d = math.min(scene.depth.toDouble(), bottom ?? scene.depth.toDouble());
  if (a >= c || b >= d) return;
  final hasTerrainSurfaces = scene.terrainSurfaces.surfaces.isNotEmpty;
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
      final replacements = groundReplacements[(cellX, cellZ)] ?? const [];
      for (final replacement in replacements) {
        for (final x in [replacement.left, replacement.right]) {
          if (x > cellLeft && x < cellRight) xs.add(x);
        }
        for (final z in [replacement.top, replacement.bottom]) {
          if (z > cellTop && z < cellBottom) zs.add(z);
        }
      }
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
          final ramp = ramps.where((r) => r.contains(px, pz)).firstOrNull;
          final patch = SpatialSurfacePatch(
            scene: scene,
            cell: (cellX, cellZ),
            left: columns[x],
            top: rows[z],
            right: columns[x + 1],
            bottom: rows[z + 1],
            ramp: ramp,
            groundHeight: ramp == null
                ? _borderGroundHeight(
                    scene.heightAt(cellX, cellZ),
                    px,
                    pz,
                    replacements,
                  )
                : null,
          );
          if (ramp == null &&
              replacements.any((value) => value.footprints.isNotEmpty)) {
            if (hasTerrainSurfaces) {
              for (final piece in _preciseGroundPatches(patch, replacements)) {
                yield* _terrainSurfacePatches(piece);
              }
            } else {
              yield* _preciseGroundPatches(patch, replacements);
            }
          } else if (hasTerrainSurfaces) {
            yield* _terrainSurfacePatches(patch);
          } else {
            yield patch;
          }
        }
      }
    }
  }
}

double _borderGroundHeight(
  double height,
  double x,
  double z,
  List<SpatialBorderGroundReplacement> replacements,
) {
  for (var pass = 0; pass < replacements.length; pass++) {
    var lowered = height;
    for (final replacement in replacements) {
      if (replacement.contains(x, z) &&
          height > replacement.lowerHeight + .000001 &&
          height <= replacement.upperHeight + .000001) {
        lowered = math.min(lowered, replacement.lowerHeight);
      }
    }
    if (lowered == height) break;
    height = lowered;
  }
  return height;
}

typedef SpatialTerrainFace = ({
  (int, int) cell,
  bool isTop,
  List<Vector3> positions,
  List<Vector2> uvs,
});

typedef SpatialGroundUnderlay = ({
  List<BorderGroundPoint> footprint,
  double heightOffset,
});

typedef SpatialGroundUnderlayIndex =
    Map<(int, int), List<SpatialGroundUnderlay>>;

List<BorderGroundPoint> _underlayPolygon(Iterable<BorderGroundPoint> points) {
  final result = <BorderGroundPoint>[];
  for (final point in points) {
    if (result.isEmpty || result.last != point) result.add(point);
  }
  if (result.length > 1 && result.first == result.last) result.removeLast();
  return result;
}

Iterable<SpatialTerrainFace> spatialTerrainUnderlayFaces(
  SpatialTerrainFace face,
  SpatialGroundUnderlayIndex supports,
) sync* {
  final underlays = supports[face.cell];
  if (!face.isTop) {
    yield face;
    return;
  }
  if (underlays == null || underlays.isEmpty) return;
  final points = _underlayPolygon([
    for (final position in face.positions)
      BorderGroundPoint(x: position.x, z: position.z),
  ]);
  if (points.length < 3 || _groundPolygonArea(points).abs() <= 1e-12) return;
  var pieces = [(points: points, offset: 0.0, covered: false)];
  var changed = false;
  for (final underlay in underlays) {
    final next =
        <({List<BorderGroundPoint> points, double offset, bool covered})>[];
    for (final piece in pieces) {
      if (piece.covered && underlay.heightOffset >= piece.offset) {
        next.add(piece);
        continue;
      }
      final split = _splitGroundPolygon(piece.points, underlay.footprint);
      if (split.inside.isEmpty) {
        next.add(piece);
        continue;
      }
      changed = true;
      next.add((
        points: split.inside,
        offset: underlay.heightOffset,
        covered: true,
      ));
      next.addAll([
        for (final outside in split.outside)
          (points: outside, offset: piece.offset, covered: piece.covered),
      ]);
    }
    pieces = next;
  }
  if (!changed) {
    return;
  }
  final origin = face.positions[0];
  var u = Vector3.zero();
  for (final point in face.positions.skip(1)) {
    final candidate = point - origin;
    if (candidate.x * candidate.x + candidate.z * candidate.z >
        u.x * u.x + u.z * u.z) {
      u = candidate;
    }
  }
  final v = face.positions
      .skip(1)
      .map((point) => point - origin)
      .where((point) => (u.x * point.z - u.z * point.x).abs() > 1e-12)
      .firstOrNull;
  if (v == null) return;
  final determinant = u.x * v.z - u.z * v.x;
  double heightAt(BorderGroundPoint point) {
    final x = point.x - origin.x, z = point.z - origin.z;
    final a = (x * v.z - z * v.x) / determinant;
    final b = (u.x * z - u.z * x) / determinant;
    return origin.y + a * u.y + b * v.y;
  }

  for (final piece in pieces) {
    if (!piece.covered) continue;
    final polygon = _underlayPolygon(piece.points);
    if (polygon.length < 3 || _groundPolygonArea(polygon).abs() <= 1e-12)
      continue;
    yield (
      cell: face.cell,
      isTop: true,
      positions: [
        for (final point in polygon)
          Vector3(point.x, heightAt(point) + piece.offset, point.z),
      ],
      uvs: [
        for (final point in polygon)
          Vector2(point.x - face.cell.$1, point.z - face.cell.$2),
      ],
    );
  }
}

Iterable<SpatialTerrainFace> spatialTerrainFaces(
  MapSpatialScene scene, {
  double left = 0,
  double top = 0,
  double? right,
  double? bottom,
  bool repeatWalls = true,
  bool includeModelledRampSurfaces = false,
  SpatialBorderGroundReplacementIndex groundReplacements = const {},
}) sync* {
  for (final patch in spatialSurfacePatches(
    scene,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    groundReplacements: groundReplacements,
  )) {
    if (patch.ramp?.surfaceInstanceId == null || includeModelledRampSurfaces) {
      yield (
        cell: patch.cell,
        isTop: true,
        positions: patch.corners,
        uvs: patch.footprint == null
            ? [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
            : [
                for (final point in patch.corners)
                  Vector2(point.x - patch.cell.$1, point.z - patch.cell.$2),
              ],
      );
    }
    if (!scene.generateCliffs) continue;
    for (final edge in _groundPatchEdges(patch, groundReplacements)) {
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
          ? _terrainNeighborHeight(scene, midpointX, midpointZ, point) ??
                _borderGroundHeight(
                  scene.heightAt(midpointX.floor(), midpointZ.floor()),
                  midpointX,
                  midpointZ,
                  groundReplacements[(midpointX.floor(), midpointZ.floor())] ??
                      const [],
                )
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
        final dx = end.$1 - start.$1, dz = end.$2 - start.$2;
        final length = dx == 0 || dz == 0
            ? dx.abs() + dz.abs()
            : math.sqrt(dx * dx + dz * dz);
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
