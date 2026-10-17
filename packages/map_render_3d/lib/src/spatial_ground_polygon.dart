part of 'spatial_terrain_geometry.dart';

double _groundPolygonArea(List<BorderGroundPoint> points) {
  var sum = 0.0;
  for (var index = 0; index < points.length; index++) {
    final a = points[index], b = points[(index + 1) % points.length];
    sum += a.x * b.z - b.x * a.z;
  }
  return sum / 2;
}

List<BorderGroundPoint> _clipGroundHalfPlane(
  List<BorderGroundPoint> polygon,
  BorderGroundPoint a,
  BorderGroundPoint b,
  double sign,
) {
  if (polygon.isEmpty) return const [];
  double distance(BorderGroundPoint p) =>
      sign * ((b.x - a.x) * (p.z - a.z) - (b.z - a.z) * (p.x - a.x));
  final result = <BorderGroundPoint>[];
  var previous = polygon.last, old = distance(polygon.last);
  for (final point in polygon) {
    final next = distance(point);
    if ((old >= 0) != (next >= 0)) {
      final t = old / (old - next);
      result.add(
        BorderGroundPoint(
          x: previous.x + (point.x - previous.x) * t,
          z: previous.z + (point.z - previous.z) * t,
        ),
      );
    }
    if (next >= 0) result.add(point);
    previous = point;
    old = next;
  }
  return result;
}

({List<BorderGroundPoint> inside, List<List<BorderGroundPoint>> outside})
_splitGroundPolygon(
  List<BorderGroundPoint> subject,
  List<BorderGroundPoint> clip,
) {
  var inside = subject;
  final outside = <List<BorderGroundPoint>>[];
  final sign = _groundPolygonArea(clip).sign;
  for (var index = 0; index < clip.length && inside.isNotEmpty; index++) {
    final a = clip[index], b = clip[(index + 1) % clip.length];
    final piece = _clipGroundHalfPlane(inside, a, b, -sign);
    if (piece.length >= 3 && _groundPolygonArea(piece).abs() > 1e-12)
      outside.add(piece);
    inside = _clipGroundHalfPlane(inside, a, b, sign);
  }
  if (inside.length < 3 || _groundPolygonArea(inside).abs() <= 1e-12)
    inside = const [];
  return (inside: inside, outside: outside);
}

Iterable<SpatialSurfacePatch> _preciseGroundPatches(
  SpatialSurfacePatch patch,
  List<SpatialBorderGroundReplacement> replacements,
) sync* {
  var pieces = [
    (
      points: [
        BorderGroundPoint(x: patch.left, z: patch.top),
        BorderGroundPoint(x: patch.right, z: patch.top),
        BorderGroundPoint(x: patch.right, z: patch.bottom),
        BorderGroundPoint(x: patch.left, z: patch.bottom),
      ],
      height: patch.scene.heightAt(patch.cell.$1, patch.cell.$2),
    ),
  ];
  for (var pass = 0; pass < replacements.length; pass++) {
    var changed = false;
    for (final replacement in replacements) {
      final contours = replacement.footprints.isEmpty
          ? [
              [
                BorderGroundPoint(x: replacement.left, z: replacement.top),
                BorderGroundPoint(x: replacement.right, z: replacement.top),
                BorderGroundPoint(x: replacement.right, z: replacement.bottom),
                BorderGroundPoint(x: replacement.left, z: replacement.bottom),
              ],
            ]
          : [for (final footprint in replacement.footprints) footprint.points];
      final next = <({List<BorderGroundPoint> points, double height})>[];
      for (final piece in pieces) {
        if (piece.height <= replacement.lowerHeight + .000001 ||
            piece.height > replacement.upperHeight + .000001) {
          next.add(piece);
          continue;
        }
        var remainder = [piece.points];
        for (final contour in contours) {
          final outside = <List<BorderGroundPoint>>[];
          for (final polygon in remainder) {
            final split = _splitGroundPolygon(polygon, contour);
            outside.addAll(split.outside);
            if (split.inside.isNotEmpty) {
              next.add((points: split.inside, height: replacement.lowerHeight));
              changed = true;
            }
          }
          remainder = outside;
        }
        next.addAll([
          for (final polygon in remainder)
            (points: polygon, height: piece.height),
        ]);
      }
      pieces = next;
    }
    if (!changed) break;
  }
  for (final piece in pieces) {
    final points = <BorderGroundPoint>[];
    for (final point in piece.points) {
      if (points.isEmpty || points.last != point) points.add(point);
    }
    if (points.length > 1 && points.first == points.last) points.removeLast();
    if (points.length < 3 || _groundPolygonArea(points).abs() <= 1e-12)
      continue;
    final ordered = _groundPolygonArea(points) < 0
        ? points
        : points.reversed.toList();
    final polygons = ordered.length <= 4
        ? [ordered]
        : [
            for (var index = 1; index < ordered.length - 1; index++)
              [ordered.first, ordered[index], ordered[index + 1]],
          ];
    for (final polygon in polygons) {
      if (_groundPolygonArea(polygon).abs() <= 1e-12) continue;
      final quad = polygon.length == 3 ? [...polygon, polygon.last] : polygon;
      yield SpatialSurfacePatch(
        scene: patch.scene,
        cell: patch.cell,
        left: polygon.map((point) => point.x).reduce(math.min),
        top: polygon.map((point) => point.z).reduce(math.min),
        right: polygon.map((point) => point.x).reduce(math.max),
        bottom: polygon.map((point) => point.z).reduce(math.max),
        ramp: null,
        groundHeight: piece.height,
        footprint: quad,
      );
    }
  }
}

Iterable<SpatialSurfacePatch> _terrainSurfacePatches(
  SpatialSurfacePatch patch,
) sync* {
  if (patch.ramp != null || patch.scene.terrainSurfaces.surfaces.isEmpty) {
    yield patch;
    return;
  }
  final candidates = patch.scene.terrainSurfaces.candidatesAtCell(
    patch.cell.$1,
    patch.cell.$2,
  );
  final polygon = <BorderGroundPoint>[];
  for (final point
      in patch.footprint ??
          [
            BorderGroundPoint(x: patch.left, z: patch.top),
            BorderGroundPoint(x: patch.right, z: patch.top),
            BorderGroundPoint(x: patch.right, z: patch.bottom),
            BorderGroundPoint(x: patch.left, z: patch.bottom),
          ]) {
    if (polygon.isEmpty || polygon.last != point) polygon.add(point);
  }
  if (polygon.length > 1 && polygon.first == polygon.last) polygon.removeLast();
  var remaining = [polygon];
  var intersected = false;
  for (final surface in candidates) {
    final bounds = surface.bounds;
    if (bounds.right <= patch.left ||
        bounds.left >= patch.right ||
        bounds.bottom <= patch.top ||
        bounds.top >= patch.bottom)
      continue;
    for (final footprint in surface.footprints) {
      final contour = [
        for (final point in footprint.points)
          BorderGroundPoint(x: surface.x + point.x, z: surface.z + point.z),
      ];
      final inside = _splitGroundPolygon(polygon, contour).inside;
      if (inside.isEmpty) continue;
      intersected = true;
      yield* _terrainPolygonPieces(
        patch,
        inside,
        height:
            surface.height -
            surface.gradientX * surface.x -
            surface.gradientZ * surface.z,
        gradientX: surface.gradientX,
        gradientZ: surface.gradientZ,
      );
      remaining = [
        for (final piece in remaining)
          ..._splitGroundPolygon(piece, contour).outside,
      ];
    }
  }
  if (!intersected) {
    yield patch;
    return;
  }
  for (final piece in remaining) {
    yield* _terrainPolygonPieces(patch, piece);
  }
}

Iterable<SpatialSurfacePatch> _terrainPolygonPieces(
  SpatialSurfacePatch patch,
  List<BorderGroundPoint> polygon, {
  double? height,
  double? gradientX,
  double? gradientZ,
}) sync* {
  if (polygon.length < 3 || _groundPolygonArea(polygon).abs() <= 1e-12) return;
  final ordered = _groundPolygonArea(polygon) < 0
      ? polygon
      : polygon.reversed.toList();
  final pieces = ordered.length <= 4
      ? [ordered]
      : [
          for (var i = 1; i < ordered.length - 1; i++)
            [ordered.first, ordered[i], ordered[i + 1]],
        ];
  for (final piece in pieces) {
    if (_groundPolygonArea(piece).abs() <= 1e-12) continue;
    yield SpatialSurfacePatch(
      scene: patch.scene,
      cell: patch.cell,
      left: piece.map((p) => p.x).reduce(math.min),
      top: piece.map((p) => p.z).reduce(math.min),
      right: piece.map((p) => p.x).reduce(math.max),
      bottom: piece.map((p) => p.z).reduce(math.max),
      ramp: null,
      groundHeight: height ?? patch.groundHeight,
      groundGradientX: gradientX ?? patch.groundGradientX,
      groundGradientZ: gradientZ ?? patch.groundGradientZ,
      footprint: piece.length == 3 ? [...piece, piece.last] : piece,
    );
  }
}

double? _terrainNeighborHeight(
  MapSpatialScene scene,
  double x,
  double z,
  (double, double) point,
) {
  if (scene.terrainSurfaces.surfaces.isEmpty) return null;
  double? highest;
  for (final surface in scene.terrainSurfaces.candidatesAtCell(
    x.floor(),
    z.floor(),
  )) {
    if (!surface.contains(x, z)) continue;
    final height = surface.heightAt(point.$1, point.$2);
    if (highest == null || height > highest) highest = height;
  }
  return highest;
}

Iterable<((double, double), (double, double), (double, double))>
_groundPatchEdges(
  SpatialSurfacePatch patch,
  SpatialBorderGroundReplacementIndex replacements,
) sync* {
  for (final edge in _rawGroundPatchEdges(patch)) {
    final start = edge.$1, end = edge.$2, normal = edge.$3;
    final x = (start.$1 + end.$1) / 2 + normal.$1 * .000001;
    final z = (start.$2 + end.$2) / 2 + normal.$2 * .000001;
    final neighbors = replacements[(x.floor(), z.floor())] ?? const [];
    if (patch.footprint == null &&
        !neighbors.any((value) => value.footprints.isNotEmpty)) {
      yield edge;
      continue;
    }
    final parameters = <double>{0, 1};
    final dx = end.$1 - start.$1, dz = end.$2 - start.$2;
    void intersect(BorderGroundPoint a, BorderGroundPoint b) {
      final ex = b.x - a.x, ez = b.z - a.z;
      final qx = a.x - start.$1, qz = a.z - start.$2;
      final denominator = dx * ez - dz * ex;
      final lengths = math.sqrt((dx * dx + dz * dz) * (ex * ex + ez * ez));
      if (lengths == 0) return;
      if (denominator.abs() <= 1e-12 * lengths) {
        if ((qx * dz - qz * dx).abs() > 1e-12 * (dx * dx + dz * dz)) return;
        for (final point in [a, b]) {
          final t =
              ((point.x - start.$1) * dx + (point.z - start.$2) * dz) /
              (dx * dx + dz * dz);
          if (t > 0 && t < 1) parameters.add(t);
        }
        return;
      }
      final t = (qx * ez - qz * ex) / denominator;
      final u = (qx * dz - qz * dx) / denominator;
      if (t > 0 && t < 1 && u >= -1e-10 && u <= 1 + 1e-10) parameters.add(t);
    }

    void intersectRectangle(
      double left,
      double top,
      double right,
      double bottom,
    ) {
      final points = [
        BorderGroundPoint(x: left, z: top),
        BorderGroundPoint(x: right, z: top),
        BorderGroundPoint(x: right, z: bottom),
        BorderGroundPoint(x: left, z: bottom),
      ];
      for (var index = 0; index < points.length; index++) {
        intersect(points[index], points[(index + 1) % points.length]);
      }
    }

    for (final replacement in neighbors) {
      if (replacement.footprints.isEmpty) {
        intersectRectangle(
          replacement.left,
          replacement.top,
          replacement.right,
          replacement.bottom,
        );
      } else {
        for (final footprint in replacement.footprints) {
          for (var index = 0; index < footprint.points.length; index++) {
            intersect(
              footprint.points[index],
              footprint.points[(index + 1) % footprint.points.length],
            );
          }
        }
      }
    }
    for (final ramp in patch.scene.navigation.ramps) {
      if (ramp.x > patch.right ||
          ramp.x + ramp.width < patch.left ||
          ramp.z > patch.bottom ||
          ramp.z + ramp.depth < patch.top)
        continue;
      intersectRectangle(
        ramp.x,
        ramp.z,
        ramp.x + ramp.width,
        ramp.z + ramp.depth,
      );
    }
    final sorted = parameters.toList()..sort();
    for (var index = 0; index < sorted.length - 1; index++) {
      final from = sorted[index], to = sorted[index + 1];
      if (to - from <= 1e-10) continue;
      yield (
        (start.$1 + dx * from, start.$2 + dz * from),
        (start.$1 + dx * to, start.$2 + dz * to),
        normal,
      );
    }
  }
}

Iterable<((double, double), (double, double), (double, double))>
_rawGroundPatchEdges(SpatialSurfacePatch patch) sync* {
  if (patch.footprint == null) {
    final a = patch.left, b = patch.top, c = patch.right, d = patch.bottom;
    yield* [
      ((a, b), (a, d), (-1.0, 0.0)),
      ((c, d), (c, b), (1.0, 0.0)),
      ((c, b), (a, b), (0.0, -1.0)),
      ((a, d), (c, d), (0.0, 1.0)),
    ];
    return;
  }
  final points = patch.corners;
  for (var index = 0; index < points.length; index++) {
    final a = points[index], b = points[(index + 1) % points.length];
    final dx = b.x - a.x, dz = b.z - a.z;
    final length = math.sqrt(dx * dx + dz * dz);
    if (length <= 1e-10) continue;
    yield ((a.x, a.z), (b.x, b.z), (-dz / length, dx / length));
  }
}
