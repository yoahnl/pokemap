part of 'spatial_terrain_geometry.dart';

Iterable<((double, double), (double, double), (double, double))>
_closedFlankEdges(
  SpatialSurfacePatch patch,
  SpatialBorderGroundReplacementIndex replacements,
) sync* {
  final surface = patch.terrainSurface;
  if (surface == null || !surface.closedFlanks) return;
  final alongX = surface.gradientX != 0;
  if (alongX == (surface.gradientZ != 0)) return;
  for (final edge in _groundPatchEdges(patch, replacements)) {
    final normal = edge.$3;
    if ((alongX ? normal.$1 : normal.$2).abs() > 1e-9) continue;
    final x = (edge.$1.$1 + edge.$2.$1) / 2 + normal.$1 * .000001;
    final z = (edge.$1.$2 + edge.$2.$2) / 2 + normal.$2 * .000001;
    if (!surface.contains(x, z)) yield edge;
  }
}
