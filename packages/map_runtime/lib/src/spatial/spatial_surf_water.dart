import 'package:map_core/map_core.dart';

final class SpatialSurfWater {
  SpatialSurfWater._(this.width, this.depth, this.cells);

  factory SpatialSurfWater.fromMap(MapData map) {
    final cells = <int>{};
    for (final zone in map.gameplayZones) {
      final movement = zone.movement;
      if (zone.kind != GameplayZoneKind.movement ||
          movement == null ||
          (movement.requiredMode != MovementMode.surf &&
              !movement.allowedModes.contains(MovementMode.surf))) {
        continue;
      }
      final area = zone.area;
      for (
        var z = area.pos.y.clamp(0, map.size.height);
        z < (area.pos.y + area.size.height).clamp(0, map.size.height);
        z++
      ) {
        for (
          var x = area.pos.x.clamp(0, map.size.width);
          x < (area.pos.x + area.size.width).clamp(0, map.size.width);
          x++
        ) {
          if (gameplayZoneContainsPosition(zone, GridPos(x: x, y: z))) {
            cells.add(z * map.size.width + x);
          }
        }
      }
    }
    return SpatialSurfWater._(map.size.width, map.size.height, cells);
  }

  final int width;
  final int depth;
  final Set<int> cells;

  bool contains(double x, double z) =>
      x.isFinite &&
      z.isFinite &&
      x >= 0 &&
      z >= 0 &&
      x < width &&
      z < depth &&
      cells.contains(z.floor() * width + x.floor());

  GridPos? facingWater(double x, double z, EntityFacing facing) {
    final (dx, dz) = switch (facing) {
      EntityFacing.north => (0, -1),
      EntityFacing.south => (0, 1),
      EntityFacing.east => (1, 0),
      EntityFacing.west => (-1, 0),
    };
    final cell = GridPos(x: x.floor() + dx, y: z.floor() + dz);
    return contains(cell.x + .5, cell.y + .5) ? cell : null;
  }
}
