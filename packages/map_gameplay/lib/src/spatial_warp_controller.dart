import 'package:map_core/map_core.dart';

import 'spatial_movement_controller.dart';

final class SpatialWarpController {
  SpatialWarpController({
    required this.map,
    required double x,
    required double z,
  }) {
    _inside = _warpsAt(x, z).toSet();
    _arrivalSuppressed = Set.of(_inside);
  }

  final MapData map;
  late Set<MapWarp> _inside;
  late Set<MapWarp> _arrivalSuppressed;
  Set<MapWarp> _bumped = {};

  MapWarp? candidateDoorApproach({
    required double x,
    required double z,
    required EntityFacing facing,
    required int inputX,
    required int inputZ,
  }) {
    if (!x.isFinite || !z.isFinite || x < 0 || z < 0 ||
        x >= map.size.width || z >= map.size.height ||
        inputX.abs() + inputZ.abs() != 1) {
      return null;
    }
    final direction = switch (facing) {
      EntityFacing.north => (0, -1),
      EntityFacing.south => (0, 1),
      EntityFacing.east => (1, 0),
      EntityFacing.west => (-1, 0),
    };
    if (direction.$1 != inputX || direction.$2 != inputZ) return null;
    final approach = switch (facing) {
      EntityFacing.north => EntityFacing.south,
      EntityFacing.south => EntityFacing.north,
      EntityFacing.east => EntityFacing.west,
      EntityFacing.west => EntityFacing.east,
    };
    for (final warp in map.warps) {
      final door = warp.door;
      if (door == null || warp.triggerMode == MapWarpTriggerMode.sceneOnly ||
          _arrivalSuppressed.contains(warp) ||
          (warp.allowedApproachFacings.isNotEmpty &&
              !warp.allowedApproachFacings.contains(approach))) {
        continue;
      }
      if (x.floor() == door.exitPos.x && z.floor() == door.exitPos.y &&
          warp.pos.x - door.exitPos.x == inputX &&
          warp.pos.y - door.exitPos.y == inputZ) {
        return warp;
      }
    }
    return null;
  }

  MapWarp? update({
    required double x,
    required double z,
    required EntityFacing facing,
    GridPos? bumpedCell,
  }) {
    if (!x.isFinite || !z.isFinite) return null;
    final inside = _warpsAt(x, z).toSet();
    _arrivalSuppressed.retainAll(inside);
    final approach = switch (facing) {
      EntityFacing.north => EntityFacing.south,
      EntityFacing.south => EntityFacing.north,
      EntityFacing.east => EntityFacing.west,
      EntityFacing.west => EntityFacing.east,
    };
    bool allows(MapWarp warp) =>
        warp.allowedApproachFacings.isEmpty ||
        warp.allowedApproachFacings.contains(approach);
    final bumped = bumpedCell == null
        ? <MapWarp>{}
        : _warpsAt(bumpedCell.x + .5, bumpedCell.y + .5)
            .where((warp) =>
                warp.triggerMode == MapWarpTriggerMode.onBump && allows(warp))
            .toSet();
    MapWarp? candidate;
    for (final warp in map.warps) {
      if (_arrivalSuppressed.contains(warp) || !allows(warp)) continue;
      final triggered = switch (warp.triggerMode) {
        MapWarpTriggerMode.onEnter =>
          inside.contains(warp) && !_inside.contains(warp),
        MapWarpTriggerMode.onBump =>
          bumped.contains(warp) && !_bumped.contains(warp),
        MapWarpTriggerMode.sceneOnly => false,
      };
      if (triggered) {
        candidate = warp;
        break;
      }
    }
    _inside = inside;
    _bumped = bumped;
    return candidate;
  }

  Iterable<MapWarp> _warpsAt(double x, double z) sync* {
    if (!x.isFinite ||
        !z.isFinite ||
        x < 0 ||
        z < 0 ||
        x >= map.size.width ||
        z >= map.size.height) {
      return;
    }
    final cellX = x.floor(), cellZ = z.floor();
    const cell = SpatialMovementController.pixelsPerCell;
    for (final warp in map.warps) {
      final padding = warp.triggerPadding;
      final minX = ((warp.pos.x * cell - padding.left) / cell).floor();
      final maxX =
          (((warp.pos.x + 1) * cell + padding.right - 1) / cell).floor();
      final minZ = ((warp.pos.y * cell - padding.top) / cell).floor();
      final maxZ =
          (((warp.pos.y + 1) * cell + padding.bottom - 1) / cell).floor();
      if (cellX >= minX && cellX <= maxX && cellZ >= minZ && cellZ <= maxZ) {
        yield warp;
      }
    }
  }
}
