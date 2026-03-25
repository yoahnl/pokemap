import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_gameplay_zone_payloads.dart';

// ---------------------------------------------------------------------------
// Lookup
// ---------------------------------------------------------------------------

MapGameplayZone? findGameplayZoneById(
  MapData map,
  String zoneId,
) {
  final normalized = zoneId.trim();
  if (normalized.isEmpty) return null;
  for (final zone in map.gameplayZones) {
    if (zone.id == normalized) return zone;
  }
  return null;
}

/// Retourne la zone de priorité la plus haute à la position donnée (dernière posée si égalité).
MapGameplayZone? findGameplayZoneAtPos(
  MapData map,
  GridPos pos,
) {
  MapGameplayZone? best;
  for (final zone in map.gameplayZones) {
    if (_containsPos(zone.area, pos)) {
      if (best == null || zone.priority >= best.priority) {
        best = zone;
      }
    }
  }
  return best;
}

/// Retourne toutes les zones couvrant [pos], triées par priorité décroissante.
List<MapGameplayZone> findAllGameplayZonesAtPos(
  MapData map,
  GridPos pos,
) {
  final result = map.gameplayZones
      .where((z) => _containsPos(z.area, pos))
      .toList(growable: false);
  result.sort((a, b) => b.priority.compareTo(a.priority));
  return result;
}

// ---------------------------------------------------------------------------
// Mutations
// ---------------------------------------------------------------------------

MapData addGameplayZoneToMap(
  MapData map, {
  required MapGameplayZone zone,
}) {
  final normalized = _normalizeZone(zone);
  _validateZone(map, normalized, duplicateIdLabel: 'Gameplay zone ID already exists');
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
  /// Passer `null` pour effacer le payload, `_kUnset` (défaut) pour conserver.
  Object? encounter = _kUnset,
  Object? movement = _kUnset,
  Object? hazard = _kUnset,
  Object? special = _kUnset,
}) {
  final index = map.gameplayZones.indexWhere((z) => z.id == zoneId);
  if (index < 0) throw ValidationException('Gameplay zone not found: $zoneId');

  final current = map.gameplayZones[index];
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
  if (!identical(movement, _kUnset)) {
    draft = draft.copyWith(movement: movement as MovementZonePayload?);
  }
  if (!identical(hazard, _kUnset)) {
    draft = draft.copyWith(hazard: hazard as HazardZonePayload?);
  }
  if (!identical(special, _kUnset)) {
    draft = draft.copyWith(special: special as SpecialZonePayload?);
  }

  final next = _normalizeZone(draft);
  _validateZone(
    map,
    next,
    excludedZoneId: current.id,
    duplicateIdLabel: 'Gameplay zone ID already exists',
  );
  final updated = List<MapGameplayZone>.from(map.gameplayZones, growable: false);
  updated[index] = next;
  return map.copyWith(gameplayZones: updated);
}

MapData moveGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  required GridPos pos,
}) {
  final zone = findGameplayZoneById(map, zoneId);
  if (zone == null) throw ValidationException('Gameplay zone not found: $zoneId');
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
  if (zone == null) throw ValidationException('Gameplay zone not found: $zoneId');
  return updateGameplayZoneOnMap(
    map,
    zoneId: zoneId,
    area: zone.area.copyWith(size: size),
  );
}

MapData removeGameplayZoneFromMap(
  MapData map, {
  required String zoneId,
}) {
  final index = map.gameplayZones.indexWhere((z) => z.id == zoneId);
  if (index < 0) throw ValidationException('Gameplay zone not found: $zoneId');
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
  return zone.copyWith(
    id: zone.id.trim(),
    name: zone.name.trim(),
  );
}

void _validateZone(
  MapData map,
  MapGameplayZone zone, {
  String? excludedZoneId,
  required String duplicateIdLabel,
}) {
  final id = zone.id.trim();
  if (id.isEmpty) throw const ValidationException('Gameplay zone ID cannot be empty');

  if (map.gameplayZones.any(
    (z) => z.id == id && z.id != excludedZoneId,
  )) {
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
  final specialProps = zone.special?.properties;
  if (specialProps != null) {
    for (final key in specialProps.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('Gameplay zone $id has an empty special property key');
      }
    }
  }
}

bool _containsPos(MapRect rect, GridPos pos) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}
