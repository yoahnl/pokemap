import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

MapWarp createMapWarp(
  MapData map, {
  required String id,
  required GridPos pos,
  MapWarpTriggerMode triggerMode = MapWarpTriggerMode.onEnter,
  String? targetMapId,
  GridPos? targetPos,
  List<EntityFacing> allowedApproachFacings = const [],
  WarpTriggerPadding triggerPadding = const WarpTriggerPadding(),
}) {
  final passive = triggerMode == MapWarpTriggerMode.sceneOnly;
  if (passive) {
    _validateSceneOnlyTarget(map, pos, targetMapId, targetPos);
  } else if (targetMapId == null || targetPos == null) {
    throw const ValidationException(
      'Active warp requires an explicit destination',
    );
  }
  final warp = MapWarp(
    id: id.trim(),
    pos: pos,
    targetMapId: passive ? map.id : targetMapId!.trim(),
    targetPos: passive ? pos : targetPos!,
    triggerMode: triggerMode,
    allowedApproachFacings: allowedApproachFacings,
    triggerPadding: triggerPadding,
  );
  _validateWarp(map, warp, duplicateIdLabel: 'Warp ID already exists');
  return warp;
}

MapData addWarpToMap(
  MapData map, {
  required MapWarp warp,
}) {
  _validateWarp(
    map,
    warp,
    duplicateIdLabel: 'Warp ID already exists',
  );
  return map.copyWith(
    warps: [...map.warps, warp],
  );
}

MapData updateWarpOnMap(
  MapData map, {
  required String warpId,
  String? id,
  GridPos? pos,
  String? targetMapId,
  GridPos? targetPos,
  MapWarpTriggerMode? triggerMode,
  List<EntityFacing>? allowedApproachFacings,
  WarpTriggerPadding? triggerPadding,
}) {
  final index = map.warps.indexWhere((warp) => warp.id == warpId);
  if (index < 0) {
    throw ValidationException('Warp not found: $warpId');
  }
  final current = map.warps[index];
  final nextPos = pos ?? current.pos;
  final nextMode = triggerMode ?? current.triggerMode;
  final passive = nextMode == MapWarpTriggerMode.sceneOnly;
  if (passive) {
    _validateSceneOnlyTarget(map, nextPos, targetMapId, targetPos);
  } else if (current.triggerMode == MapWarpTriggerMode.sceneOnly &&
      (targetMapId == null || targetPos == null)) {
    throw const ValidationException(
      'Activating a scene-only point requires an explicit destination',
    );
  }
  final next = current.copyWith(
    id: id?.trim() ?? current.id,
    pos: nextPos,
    targetMapId: passive ? map.id : targetMapId?.trim() ?? current.targetMapId,
    targetPos: passive ? nextPos : targetPos ?? current.targetPos,
    triggerMode: nextMode,
    allowedApproachFacings:
        allowedApproachFacings ?? current.allowedApproachFacings,
    triggerPadding: triggerPadding ?? current.triggerPadding,
  );
  _validateWarp(
    map,
    next,
    excludedWarpId: current.id,
    duplicateIdLabel: 'Warp ID already exists',
  );
  final updated = List<MapWarp>.from(map.warps, growable: false);
  updated[index] = next;
  return map.copyWith(warps: updated);
}

MapData removeWarpFromMap(
  MapData map, {
  required String warpId,
}) {
  final index = map.warps.indexWhere((warp) => warp.id == warpId);
  if (index < 0) {
    throw ValidationException('Warp not found: $warpId');
  }
  final updated = List<MapWarp>.from(map.warps, growable: true)
    ..removeAt(index);
  return map.copyWith(warps: updated);
}

void _validateWarp(
  MapData map,
  MapWarp warp, {
  String? excludedWarpId,
  required String duplicateIdLabel,
}) {
  final id = warp.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Warp ID cannot be empty');
  }
  if (map.warps.any((entry) => entry.id == id && entry.id != excludedWarpId)) {
    throw ValidationException('$duplicateIdLabel: $id');
  }
  if (!_isInBounds(warp.pos, map.size)) {
    throw ValidationException(
      'Warp $id is out of map bounds at (${warp.pos.x}, ${warp.pos.y})',
    );
  }
  if (warp.targetMapId.trim().isEmpty) {
    throw ValidationException('Warp $id has empty targetMapId');
  }
  if (warp.triggerMode == MapWarpTriggerMode.sceneOnly) {
    _validateSceneOnlyTarget(map, warp.pos, warp.targetMapId, warp.targetPos);
  }
  if (warp.targetPos.x < 0 || warp.targetPos.y < 0) {
    throw ValidationException(
      'Warp $id has invalid target position: (${warp.targetPos.x}, ${warp.targetPos.y})',
    );
  }
  final padding = warp.triggerPadding;
  if (padding.top < 0 ||
      padding.right < 0 ||
      padding.bottom < 0 ||
      padding.left < 0) {
    throw ValidationException('Warp $id has invalid negative trigger padding');
  }
  final seen = <EntityFacing>{};
  for (final facing in warp.allowedApproachFacings) {
    if (!seen.add(facing)) {
      throw ValidationException(
        'Warp $id has duplicate allowed approach facing: ${facing.name}',
      );
    }
  }
}

void _validateSceneOnlyTarget(
  MapData map,
  GridPos pos,
  String? targetMapId,
  GridPos? targetPos,
) {
  if ((targetMapId != null && targetMapId != map.id) ||
      (targetPos != null && targetPos != pos)) {
    throw const ValidationException(
      'Scene-only point must target its own map and position',
    );
  }
}

bool _isInBounds(GridPos pos, GridSize size) {
  return pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;
}
