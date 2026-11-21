import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class SpatialTerrainContour {
  SpatialTerrainContour._(
    SpatialTerrainSurface surface,
    BorderGroundFootprint footprint,
  ) : points = List.unmodifiable([
        for (final point in footprint.points)
          BorderGroundPoint(x: surface.x + point.x, z: surface.z + point.z),
      ]);

  final List<BorderGroundPoint> points;
  late final double left = points.map((p) => p.x).reduce(math.min);
  late final double right = points.map((p) => p.x).reduce(math.max);
  late final double top = points.map((p) => p.z).reduce(math.min);
  late final double bottom = points.map((p) => p.z).reduce(math.max);

  static final _cache = Expando<List<SpatialTerrainContour>>();

  static Iterable<SpatialTerrainContour> overlapping(
    SpatialTerrainSurface surface, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final contours = _cache[surface] ??= [
      for (final footprint in surface.footprints)
        SpatialTerrainContour._(surface, footprint),
    ];
    return contours.where(
      (c) =>
          c.right > left && c.left < right && c.bottom > top && c.top < bottom,
    );
  }
}
