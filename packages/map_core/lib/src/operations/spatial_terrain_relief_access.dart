import '../models/geometry.dart';
import '../models/map_data.dart';

bool terrainReliefUnreachable(
  MapData map,
  Set<GridPos> painted,
  double height,
) {
  final scene = map.spatialScene!;
  final heights = <GridPos, double>{};
  double heightAt(GridPos cell) =>
      heights[cell] ??= scene.worldHeightAt(cell.x + .5, cell.y + .5);
  bool inside(GridPos cell) =>
      cell.x >= 0 &&
      cell.y >= 0 &&
      cell.x < scene.width &&
      cell.y < scene.depth;
  bool rampAt(GridPos cell) =>
      scene.navigation.ramps.any(
        (ramp) => ramp.contains(cell.x + .5, cell.y + .5),
      ) ||
      scene.terrainSurfaces
          .candidatesAtCell(cell.x, cell.y)
          .any(
            (surface) =>
                (surface.gradientX != 0 || surface.gradientZ != 0) &&
                surface.contains(cell.x + .5, cell.y + .5),
          );
  final half = scene.width * scene.depth / 2;
  final warps = {for (final warp in map.warps) warp.pos};
  final visited = <GridPos>{};
  for (final seed in painted) {
    if (visited.contains(seed) || (heightAt(seed) - height).abs() > 1e-6) {
      continue;
    }
    final component = <GridPos>{seed};
    final pending = [seed];
    var reachable = false;
    while (pending.isNotEmpty && !reachable) {
      final cell = pending.removeLast();
      if (warps.contains(cell) || component.length > half) reachable = true;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final next = GridPos(x: cell.x + dx, y: cell.y + dy);
        if (!inside(next) || component.contains(next)) continue;
        if (rampAt(next)) {
          reachable = true;
        } else if ((heightAt(next) - height).abs() <= 1e-6) {
          component.add(next);
          pending.add(next);
        }
      }
    }
    if (!reachable) return true;
    visited.addAll(component);
  }
  return false;
}
