import 'package:map_core/map_core.dart';

class WarpEditingCoordinator {
  const WarpEditingCoordinator();

  MapWarp? findWarpAtPos(MapData map, GridPos pos) {
    for (final warp in map.warps) {
      if (warp.pos == pos) {
        return warp;
      }
    }
    return null;
  }

  MapWarp? findWarpById(MapData map, String warpId) {
    for (final warp in map.warps) {
      if (warp.id == warpId) {
        return warp;
      }
    }
    return null;
  }

  String generateUniqueWarpId(MapData map) {
    final ids = map.warps.map((warp) => warp.id).toSet();
    if (!ids.contains('warp')) return 'warp';
    var index = 1;
    while (ids.contains('warp_$index')) {
      index++;
    }
    return 'warp_$index';
  }

  MapWarp createDefaultWarp(
    MapData map,
    GridPos pos,
  ) {
    return MapWarp(
      id: generateUniqueWarpId(map),
      pos: pos,
      targetMapId: map.id,
      targetPos: pos,
    );
  }
}
