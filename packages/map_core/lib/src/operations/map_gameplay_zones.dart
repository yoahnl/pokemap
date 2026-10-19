import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_gameplay_zone_payloads.dart';
import '../models/smart_tile_gameplay_zone_provenance.dart';

// ---------------------------------------------------------------------------
// Lookup
// ---------------------------------------------------------------------------

MapGameplayZone? findGameplayZoneById(MapData map, String zoneId) {
  final normalized = zoneId.trim();
  if (normalized.isEmpty) return null;
  for (final zone in map.gameplayZones) {
    if (zone.id == normalized) return zone;
  }
  return null;
}

/// Retourne la zone de priorité la plus haute à la position donnée (dernière posée si égalité).
MapGameplayZone? findGameplayZoneAtPos(MapData map, GridPos pos) {
  MapGameplayZone? best;
  for (final zone in map.gameplayZones) {
    if (gameplayZoneContainsPosition(zone, pos)) {
      if (best == null || zone.priority >= best.priority) {
        best = zone;
      }
    }
  }
  return best;
}

/// Retourne toutes les zones couvrant [pos], triées par priorité décroissante.
List<MapGameplayZone> findAllGameplayZonesAtPos(MapData map, GridPos pos) {
  final result = map.gameplayZones
      .where((z) => gameplayZoneContainsPosition(z, pos))
      .toList(growable: false);
  result.sort((a, b) => b.priority.compareTo(a.priority));
  return result;
}

// ---------------------------------------------------------------------------
// Mutations
// ---------------------------------------------------------------------------

MapData addGameplayZoneToMap(MapData map, {required MapGameplayZone zone}) {
  final normalized = _normalizeZone(zone);
  _validateZone(
    map,
    normalized,
    duplicateIdLabel: 'Gameplay zone ID already exists',
  );
  return map.copyWith(gameplayZones: [...map.gameplayZones, normalized]);
}

MapData updateGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  String? id,
  String? name,
  GameplayZoneKind? kind,
  MapRect? area,
  int? priority,
  Object? cellMask = _kUnset,

  /// Passer `null` pour effacer le payload, `_kUnset` (défaut) pour conserver.
  Object? encounter = _kUnset,
  Object? movement = _kUnset,
  Object? movementEffect = _kUnset,
  Object? hazard = _kUnset,
  Object? fieldAction = _kUnset,
  Object? special = _kUnset,
  Object? smartTileProvenance = _kUnset,
}) {
  final index = map.gameplayZones.indexWhere((z) => z.id == zoneId);
  if (index < 0) throw ValidationException('Gameplay zone not found: $zoneId');

  final current = map.gameplayZones[index];
  if (current.fieldAction?.dive?.link != null &&
      ((kind != null && kind != current.kind) ||
          (id != null && id != current.id) ||
          (!identical(fieldAction, _kUnset) &&
              (fieldAction as FieldActionZonePayload?)?.dive?.role !=
                  current.fieldAction!.dive!.role))) {
    throw const ValidationException(
      'Unlink the Dive pair before changing its endpoint type or role.',
    );
  }
  var draft = current.copyWith(
    id: id?.trim() ?? current.id,
    name: name?.trim() ?? current.name,
    kind: kind ?? current.kind,
    area: area ?? current.area,
    priority: priority ?? current.priority,
  );
  if (!identical(encounter, _kUnset)) {
    draft = draft.copyWith(encounter: encounter as EncounterZonePayload?);
  }
  if (!identical(cellMask, _kUnset)) {
    draft = draft.copyWith(cellMask: cellMask as List<GridPos>?);
  }
  if (!identical(movement, _kUnset)) {
    draft = draft.copyWith(movement: movement as MovementZonePayload?);
  }
  if (!identical(movementEffect, _kUnset)) {
    draft = draft.copyWith(
      movementEffect: movementEffect as MovementEffectZonePayload?,
    );
  }
  if (!identical(fieldAction, _kUnset)) {
    draft = draft.copyWith(fieldAction: fieldAction as FieldActionZonePayload?);
  }
  if (!identical(hazard, _kUnset)) {
    draft = draft.copyWith(hazard: hazard as HazardZonePayload?);
  }
  if (!identical(special, _kUnset)) {
    draft = draft.copyWith(special: special as SpecialZonePayload?);
  }
  if (!identical(smartTileProvenance, _kUnset)) {
    draft = draft.copyWith(
      smartTileProvenance:
          smartTileProvenance as SmartTileGameplayZoneProvenance?,
    );
  }

  final next = _normalizeZone(draft);
  _validateZone(
    map,
    next,
    excludedZoneId: current.id,
    duplicateIdLabel: 'Gameplay zone ID already exists',
  );
  final updated = List<MapGameplayZone>.from(
    map.gameplayZones,
    growable: false,
  );
  updated[index] = next;
  return map.copyWith(gameplayZones: updated);
}

MapData moveGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  required GridPos pos,
}) {
  final zone = findGameplayZoneById(map, zoneId);
  if (zone == null) {
    throw ValidationException('Gameplay zone not found: $zoneId');
  }
  return updateGameplayZoneOnMap(
    map,
    zoneId: zoneId,
    area: zone.area.copyWith(pos: pos),
  );
}

MapData resizeGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  required GridSize size,
}) {
  final zone = findGameplayZoneById(map, zoneId);
  if (zone == null) {
    throw ValidationException('Gameplay zone not found: $zoneId');
  }
  return updateGameplayZoneOnMap(
    map,
    zoneId: zoneId,
    area: zone.area.copyWith(size: size),
  );
}

MapData removeGameplayZoneFromMap(MapData map, {required String zoneId}) {
  final index = map.gameplayZones.indexWhere((z) => z.id == zoneId);
  if (index < 0) throw ValidationException('Gameplay zone not found: $zoneId');
  if (map.gameplayZones[index].fieldAction?.dive?.link != null) {
    throw const ValidationException(
      'Unlink the Dive pair before deleting its endpoint.',
    );
  }
  final updated = List<MapGameplayZone>.from(map.gameplayZones, growable: true)
    ..removeAt(index);
  return map.copyWith(gameplayZones: updated);
}

// ---------------------------------------------------------------------------
// Helpers internes
// ---------------------------------------------------------------------------

/// Valeur sentinelle pour les paramètres optionnels (distingue null de "non fourni").
const Object _kUnset = Object();

MapGameplayZone _normalizeZone(MapGameplayZone zone) {
  return zone.copyWith(id: zone.id.trim(), name: zone.name.trim());
}

void _validateZone(
  MapData map,
  MapGameplayZone zone, {
  String? excludedZoneId,
  required String duplicateIdLabel,
}) {
  final id = zone.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Gameplay zone ID cannot be empty');
  }

  if (map.gameplayZones.any((z) => z.id == id && z.id != excludedZoneId)) {
    throw ValidationException('$duplicateIdLabel: $id');
  }

  final area = zone.area;
  if (area.size.width <= 0 || area.size.height <= 0) {
    throw ValidationException(
      'Gameplay zone $id has invalid area size: (${area.size.width}x${area.size.height})',
    );
  }
  if (area.pos.x < 0 ||
      area.pos.y < 0 ||
      area.pos.x + area.size.width > map.size.width ||
      area.pos.y + area.size.height > map.size.height) {
    throw ValidationException(
      'Gameplay zone $id area is out of map bounds at (${area.pos.x}, ${area.pos.y}) '
      'with size (${area.size.width}x${area.size.height})',
    );
  }
  validateFieldActionZone(map, zone);
  validateGameplayZoneCellMask(zone);
  validateDirectedJumpZone(map, zone, excludedZoneId: excludedZoneId);
  final specialProps = zone.special?.properties;
  if (specialProps != null) {
    for (final key in specialProps.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Gameplay zone $id has an empty special property key',
        );
      }
    }
  }
  if (zone.movement?.allowedModes.contains(MovementMode.dive) == true) {
    throw const ValidationException(
      'Dive cannot be an additional allowed movement mode.',
    );
  }
  validateDiveMovementZones(
    map.copyWith(
      gameplayZones: [
        ...map.gameplayZones.where((other) => other.id != zone.id),
        zone,
      ],
    ),
  );
  final movementEffect = zone.movementEffect;
  if (zone.kind == GameplayZoneKind.movementEffect && movementEffect == null) {
    throw ValidationException(
      'Gameplay zone $id requires a movement effect payload',
    );
  }
  if (movementEffect != null && movementEffect.movementCost <= 0) {
    throw ValidationException(
      'Gameplay zone $id movement effect movementCost must be positive',
    );
  }
}

bool _containsPos(MapRect rect, GridPos pos) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}

bool gameplayZoneContainsPosition(MapGameplayZone zone, GridPos position) {
  if (!_containsPos(zone.area, position)) return false;
  final mask = zone.cellMask;
  if (mask == null) return true;
  return mask.contains(
    GridPos(x: position.x - zone.area.pos.x, y: position.y - zone.area.pos.y),
  );
}

void validateDirectedJumpZone(
  MapData map,
  MapGameplayZone zone, {
  String? excludedZoneId,
}) {
  final effect = zone.movementEffect;
  final jump = effect?.directedJump;
  if (effect?.effectKind != MovementEffectZoneKind.directedJump) {
    if (jump != null) {
      throw const ValidationException(
        'Directed jump payload has a different effect kind',
      );
    }
    return;
  }
  if (jump == null ||
      zone.kind != GameplayZoneKind.movementEffect ||
      zone.encounter != null ||
      zone.movement != null ||
      zone.hazard != null ||
      zone.special != null ||
      zone.cellMask != null ||
      jump.distanceCells != 2 ||
      jump.durationMs < 1 ||
      jump.durationMs > 60000 ||
      jump.peakHeightPx < 1 ||
      jump.peakHeightPx > 1024) {
    throw ValidationException(
      'Gameplay zone ${zone.id} has an invalid directed jump',
    );
  }
  final dx = switch (jump.direction) {
    MapConnectionDirection.east => 1,
    MapConnectionDirection.west => -1,
    _ => 0,
  };
  final dy = switch (jump.direction) {
    MapConnectionDirection.south => 1,
    MapConnectionDirection.north => -1,
    _ => 0,
  };
  final area = zone.area;
  if (area.pos.x - dx < 0 ||
      area.pos.y - dy < 0 ||
      area.pos.x + dx < 0 ||
      area.pos.y + dy < 0 ||
      area.pos.x - dx + area.size.width > map.size.width ||
      area.pos.y - dy + area.size.height > map.size.height ||
      area.pos.x + dx + area.size.width > map.size.width ||
      area.pos.y + dy + area.size.height > map.size.height) {
    throw ValidationException(
      'Gameplay zone ${zone.id} jump endpoints are outside the map',
    );
  }
  for (final other in map.gameplayZones) {
    if (identical(other, zone) ||
        other.id == excludedZoneId ||
        other.id == zone.id ||
        other.kind != GameplayZoneKind.movementEffect ||
        other.movementEffect?.effectKind !=
            MovementEffectZoneKind.directedJump ||
        other.movementEffect?.directedJump?.direction != jump.direction ||
        other.priority != zone.priority) {
      continue;
    }
    final b = other.area;
    if (area.pos.x < b.pos.x + b.size.width &&
        area.pos.x + area.size.width > b.pos.x &&
        area.pos.y < b.pos.y + b.size.height &&
        area.pos.y + area.size.height > b.pos.y) {
      throw ValidationException(
        'Directed jump zones ${zone.id} and ${other.id} are ambiguous',
        code: 'movement.directed_jump_ambiguous',
      );
    }
  }
}

void validateGameplayZoneCellMask(MapGameplayZone zone) {
  final mask = zone.cellMask;
  if (mask == null) return;
  if (zone.kind != GameplayZoneKind.encounter || mask.isEmpty) {
    throw ValidationException('Gameplay zone ${zone.id} has invalid cell mask');
  }
  if (mask.toSet().length != mask.length ||
      mask.any(
        (cell) =>
            cell.x < 0 ||
            cell.y < 0 ||
            cell.x >= zone.area.size.width ||
            cell.y >= zone.area.size.height,
      )) {
    throw ValidationException('Gameplay zone ${zone.id} has invalid cell mask');
  }
}

void validateFieldActionZone(MapData map, MapGameplayZone zone) {
  final payload = zone.fieldAction;
  if (zone.kind != GameplayZoneKind.fieldAction && payload == null) return;
  if (zone.kind != GameplayZoneKind.fieldAction ||
      payload == null ||
      zone.encounter != null ||
      zone.movement != null ||
      zone.movementEffect != null ||
      zone.hazard != null ||
      zone.special != null ||
      zone.cellMask != null ||
      zone.smartTileProvenance != null) {
    throw const ValidationException(
      'Field-action zones require their exclusive typed payload.',
    );
  }
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    throw const ValidationException(
      'Field-action zones are supported on 2D maps only.',
    );
  }
  if (payload.actionKind == FieldActionZoneKind.dive) {
    final dive = payload.dive;
    if (dive == null ||
        payload.darkness != null ||
        payload.waterfall != null ||
        payload.whirlpool != null ||
        zone.area.size != const GridSize(width: 1, height: 1)) {
      throw const ValidationException('Dive requires an exclusive 1x1 point.');
    }
    DiveZonePayload.fromJson(dive.toJson());
    final spawnId = dive.arrivalSpawnId;
    if (dive.link != null && spawnId == null) {
      throw const ValidationException(
        'A linked Dive point requires an arrival spawn.',
      );
    }
    if (spawnId != null) {
      final entities = map.entities
          .where((entity) => entity.id == spawnId)
          .toList();
      if (entities.length != 1 ||
          entities.single.kind != MapEntityKind.spawn ||
          entities.single.spawn == null ||
          entities.single.pos != zone.area.pos) {
        throw const ValidationException(
          'Dive arrival must be one exact local spawn ID on its point.',
        );
      }
    }
    return;
  }
  if (payload.actionKind == FieldActionZoneKind.waterfall ||
      payload.actionKind == FieldActionZoneKind.whirlpool) {
    final waterfall = payload.waterfall;
    final whirlpool = payload.whirlpool;
    final isWhirlpool = payload.actionKind == FieldActionZoneKind.whirlpool;
    final entry = isWhirlpool ? whirlpool?.entry : waterfall?.entry;
    final path = isWhirlpool ? whirlpool?.path : waterfall?.path;
    final exit = isWhirlpool ? whirlpool?.exit : waterfall?.exit;
    final direction = isWhirlpool ? whirlpool?.direction : waterfall?.direction;
    if (entry == null || path == null || exit == null || direction == null ||
        (isWhirlpool ? waterfall != null : whirlpool != null) ||
        payload.darkness != null ||
        payload.dive != null ||
        path.isEmpty ||
        path.length > 256) {
      throw const ValidationException(
        'Field traversal requires its exclusive bounded cardinal route.',
      );
    }
    final cells = [entry, ...path, exit];
    final (dx, dy) = switch (direction) {
      MapConnectionDirection.north => (0, -1),
      MapConnectionDirection.south => (0, 1),
      MapConnectionDirection.east => (1, 0),
      MapConnectionDirection.west => (-1, 0),
    };
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      if (cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= zone.area.size.width ||
          cell.y >= zone.area.size.height ||
          (i > 0 &&
              (cell.x != cells[i - 1].x + dx ||
                  cell.y != cells[i - 1].y + dy))) {
        throw const ValidationException(
          'Field traversal entry, path and exit must be contiguous, follow their direction and stay inside the zone.',
        );
      }
    }
    return;
  }
  if (payload.darkness == null ||
      payload.waterfall != null ||
      payload.whirlpool != null ||
      payload.dive != null) {
    throw const ValidationException(
      'Darkness requires its exclusive typed payload.',
    );
  }
  final opacity = payload.darkness!.opacity;
  if (!opacity.isFinite || opacity < .35 || opacity > .95) {
    throw const ValidationException(
      'Darkness opacity must be between 0.35 and 0.95.',
    );
  }
}

void validateDiveMovementZones(MapData map) {
  final movements = map.gameplayZones
      .where(
        (zone) =>
            zone.kind == GameplayZoneKind.movement && zone.movement != null,
      )
      .toList();
  for (final zone in movements) {
    final payload = zone.movement!;
    if (payload.allowedModes.contains(MovementMode.dive)) {
      throw const ValidationException(
        'Dive cannot be an additional allowed movement mode.',
      );
    }
    if (payload.requiredMode != MovementMode.dive) continue;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      throw const ValidationException(
        'Dive movement terrain is supported on 2D maps only.',
      );
    }
    for (final other in movements) {
      if (other.movement!.requiredMode != MovementMode.surf &&
          !other.movement!.allowedModes.contains(MovementMode.surf))
        continue;
      final a = zone.area, b = other.area;
      if (a.pos.x < b.pos.x + b.size.width &&
          a.pos.x + a.size.width > b.pos.x &&
          a.pos.y < b.pos.y + b.size.height &&
          a.pos.y + a.size.height > b.pos.y) {
        throw const ValidationException(
          'Surf and Dive terrains cannot overlap.',
        );
      }
    }
  }
}
