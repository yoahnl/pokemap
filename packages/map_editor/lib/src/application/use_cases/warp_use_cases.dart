part of 'project_use_cases.dart';

class AddWarpToMapUseCase {
  MapData execute(
    MapData map, {
    required MapWarp warp,
  }) {
    final updated = addWarpToMap(
      map,
      warp: warp,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class UpdateWarpOnMapUseCase {
  MapData execute(
    MapData map, {
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
  }) {
    final updated = updateWarpOnMap(
      map,
      warpId: warpId,
      id: id,
      pos: pos,
      targetMapId: targetMapId,
      targetPos: targetPos,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteWarpFromMapUseCase {
  MapData execute(
    MapData map, {
    required String warpId,
  }) {
    final updated = removeWarpFromMap(
      map,
      warpId: warpId,
    );
    MapValidator.validate(updated);
    return updated;
  }
}
