import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_warp_ladder.dart';
import '../models/map_layer.dart';
import '../models/project_model3d.dart';

MapWarp createMapWarp(
  MapData map, {
  required String id,
  required GridPos pos,
  MapWarpTriggerMode triggerMode = MapWarpTriggerMode.onEnter,
  String? targetMapId,
  GridPos? targetPos,
  List<EntityFacing> allowedApproachFacings = const [],
  WarpTriggerPadding triggerPadding = const WarpTriggerPadding(),
  MapWarpDoor? door,
  MapWarpLadder? ladder,
  MapWarpTransition transition = const MapWarpTransition(),
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
    door: door,
    ladder: ladder,
    transition: transition,
  );
  _validateWarp(map, warp, duplicateIdLabel: 'Warp ID already exists');
  return warp;
}

MapData addWarpToMap(
  MapData map, {
  required MapWarp warp}) {
  _validateWarp(
    map,
    warp,
    duplicateIdLabel: 'Warp ID already exists');
  return map.copyWith(
    warps: [...map.warps, warp]);
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
  MapWarpDoor? door,
  bool clearDoor = false,
  MapWarpLadder? ladder,
  bool clearLadder = false,
  MapWarpTransition? transition,
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
  final currentDoor = current.door;
  final nextDoor = clearDoor
      ? null
      : door ??
            (currentDoor == null
                ? null
                : currentDoor.copyWith(
                    exitPos: GridPos(
                      x: currentDoor.exitPos.x + nextPos.x - current.pos.x,
                      y: currentDoor.exitPos.y + nextPos.y - current.pos.y,
                    ),
                  ));
  final next = current.copyWith(
    id: id?.trim() ?? current.id,
    pos: nextPos,
    targetMapId: passive ? map.id : targetMapId?.trim() ?? current.targetMapId,
    targetPos: passive ? nextPos : targetPos ?? current.targetPos,
    triggerMode: nextMode,
    allowedApproachFacings:
        allowedApproachFacings ?? current.allowedApproachFacings,
    triggerPadding: triggerPadding ?? current.triggerPadding,
    door: nextDoor,
    ladder: clearLadder ? null : ladder ?? current.ladder,
    transition: transition ?? current.transition,
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
  required String warpId}) {
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
  validateMapWarpLadder(map, warp);
  validateMapWarpTransition(warp.transition);
  validateMapWarpDoor(
    excludedWarpId == null
        ? map
        : map.copyWith(
            warps: map.warps
                .where((entry) => entry.id != excludedWarpId)
                .toList(),
          ),
    warp,
  );
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

void validateMapWarpTransition(MapWarpTransition transition) {
  if (!transition.durationSeconds.isFinite || transition.durationSeconds <= 0 ||
      transition.durationSeconds > 5) {
    throw const ValidationException('La transition doit durer plus de zéro et au plus cinq secondes.',
        code: 'warp.transition_invalid_duration',
    );
  }
}

void validateMapWarpLadder(MapData map, MapWarp warp) {
  if (warp.ladder == null) return;
  if (map.spatialScene == null ||
      warp.triggerMode == MapWarpTriggerMode.sceneOnly ||
      warp.door != null) {
    throw const ValidationException(
      'Une échelle nécessite un passage 3D actif sans animation de porte.',
      code: 'warp.ladder_invalid_binding',
    );
  }
}

void validateMapWarpDoor(
  MapData map,
  MapWarp warp, {
  Iterable<ProjectModel3dEntry>? models,
}) {
  final door = warp.door;
  if (door == null) return;
  Never invalid(String code, String message) => throw ValidationException(
    message,
    code: code,
    details: {'mapId': map.id, 'warpId': warp.id},
  );
  final scene = map.spatialScene;
  if (scene == null || warp.triggerMode == MapWarpTriggerMode.sceneOnly) {
    invalid(
      'warp.door_requires_active_3d_warp',
      'Une porte native nécessite un passage actif sur une carte 3D.',
    );
  }
  if (door.instanceId.trim().isEmpty ||
      door.instanceId != door.instanceId.trim() ||
      door.openAnimationIndex < 0 ||
      door.closeAnimationIndex < 0) {
    invalid(
      'warp.door_invalid_binding',
      'Choisissez un décor et des animations de porte valides.',
    );
  }
  if (!_isInBounds(door.exitPos, map.size) ||
      (door.exitPos.x - warp.pos.x).abs() +
              (door.exitPos.y - warp.pos.y).abs() !=
          1) {
    invalid(
      'warp.door_invalid_exit',
      'La sortie de porte doit être une case voisine, au nord, au sud, à l’est ou à l’ouest, dans la carte.',
    );
  }
  final exitIndex = door.exitPos.y * map.size.width + door.exitPos.x;
  if (map.layers.whereType<CollisionLayer>().any(
    (layer) =>
        exitIndex < layer.collisions.length && layer.collisions[exitIndex],
  )) {
    invalid(
      'warp.door_blocked_exit',
      'La case de sortie de porte est bloquée.',
    );
  }
  if (scene.navigation.blockedAreas.any(
    (area) => area.contains(door.exitPos.x + .5, door.exitPos.y + .5),
  )) {
    invalid(
      'warp.door_blocked_exit',
      'La case de sortie de porte est bloquée.',
    );
  }
  if (map.warps
      .where((other) => other.pos == warp.pos && other.door != null)
      .where((other) => other.id != warp.id)
      .isNotEmpty) {
    invalid(
      'warp.door_ambiguous',
      'Cette position contient plusieurs portes : conservez un seul passage de porte à cet endroit.',
    );
  }
  final instances = scene.instances
      .where((instance) => instance.id == door.instanceId)
      .toList();
  if (instances.length != 1 || instances.single.clip != null) {
    invalid(
      'warp.door_instance_invalid',
      'Le décor de porte est introuvable, dupliqué ou découpé. Choisissez un décor 3D complet de cette carte.',
    );
  }
  if (instances.single.animationIndex != null) {
    invalid(
      'warp.door_ambient_animation',
      'Désactivez la lecture automatique sur ce décor avant de le lier à une porte.',
    );
  }
  if (models == null) return;
  final matchingModels = models
      .where((model) => model.id == instances.single.modelId)
      .toList();
  if (matchingModels.length != 1) {
    invalid(
      'warp.door_model_missing',
      'Le modèle du décor de porte est introuvable ou dupliqué dans la bibliothèque.',
    );
  }
  for (final index in [door.openAnimationIndex, door.closeAnimationIndex]) {
    final clips = matchingModels.single.inspection.animations
        .where((clip) => clip.index == index)
        .toList();
    if (clips.length != 1 ||
        !clips.single.durationSeconds.isFinite ||
        clips.single.durationSeconds <= 0) {
      invalid(
        'warp.door_clip_invalid',
        'Une animation de porte est absente ou sans durée. Choisissez les animations d’ouverture et de fermeture du modèle.',
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
