import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../compatibility/legacy_map_event_projection.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import 'narrative_event_canonical_json.dart';

/// Builds the read-only spatial source catalog used by Event V2 authoring.
///
/// The catalog never infers canonical identities from metadata or position.
/// Legacy projections may decorate an exact canonical source, but assisted
/// projections remain separate compatibility entries.
NarrativeSpatialEventSourceCatalog buildNarrativeSpatialEventSourceCatalog({
  required ProjectManifest project,
  required List<MapData> maps,
  List<LegacyMapEventProjection> legacyProjections = const [],
}) {
  final options = <NarrativeSpatialEventSourceOption>[];
  final diagnostics = <NarrativeSpatialEventSourceDiagnostic>[];
  final mapsById = <String, List<MapData>>{};
  for (final map in maps) {
    mapsById.putIfAbsent(map.id, () => []).add(map);
  }

  final entries = List<ProjectMapEntry>.of(project.maps)
    ..sort(_compareMapEntries);
  final manifestMapIds = <String>{};
  final manifestEntryCounts = <String, int>{};
  for (final entry in entries) {
    manifestEntryCounts.update(entry.id, (count) => count + 1,
        ifAbsent: () => 1);
  }
  final diagnosedDuplicateManifestIds = <String>{};
  for (final entry in entries) {
    manifestMapIds.add(entry.id);
    final duplicateManifestId = manifestEntryCounts[entry.id]! > 1;
    if (duplicateManifestId && diagnosedDuplicateManifestIds.add(entry.id)) {
      diagnostics.add(
        NarrativeSpatialEventSourceDiagnostic(
          code: 'duplicateManifestMapId',
          message:
              'Plusieurs entrées du projet utilisent le même identifiant de map.',
          mapId: entry.id,
        ),
      );
    }
    final matchingMaps = mapsById[entry.id] ?? const <MapData>[];
    _appendMapOptions(
      entry: entry,
      matchingMaps: matchingMaps,
      manifestIdentityUnique: !duplicateManifestId,
      options: options,
      diagnostics: diagnostics,
    );
  }

  for (final map in maps) {
    if (manifestMapIds.contains(map.id)) continue;
    diagnostics.add(
      NarrativeSpatialEventSourceDiagnostic(
        code: 'orphanMapData',
        message:
            'La map ${_display(map.name, map.id)} n’est pas déclarée dans le projet.',
        mapId: map.id,
      ),
    );
  }

  _applyLegacyCompatibility(
    entries: entries,
    mapsById: mapsById,
    projections: legacyProjections,
    options: options,
    diagnostics: diagnostics,
  );

  options.sort(_compareOptions);
  diagnostics.sort(_compareDiagnostics);
  return NarrativeSpatialEventSourceCatalog(
    options: options,
    diagnostics: diagnostics,
  );
}

void _appendMapOptions({
  required ProjectMapEntry entry,
  required List<MapData> matchingMaps,
  required bool manifestIdentityUnique,
  required List<NarrativeSpatialEventSourceOption> options,
  required List<NarrativeSpatialEventSourceDiagnostic> diagnostics,
}) {
  final mapLabel = _display(entry.name, entry.id);
  final source = _mapSource(entry.id);
  if (matchingMaps.isEmpty) {
    const reason = 'Les données de cette map sont introuvables.';
    options.add(
      _mapOption(
        entry: entry,
        source: source,
        availability: NarrativeSpatialEventSourceAvailability.missing,
        reason: reason,
      ),
    );
    diagnostics.add(
      NarrativeSpatialEventSourceDiagnostic(
        code: 'missingMapData',
        message: '$reason Map : $mapLabel.',
        mapId: entry.id,
      ),
    );
    return;
  }

  if (matchingMaps.length > 1) {
    const reason = 'Plusieurs fichiers décrivent cette même map.';
    options.add(
      _mapOption(
        entry: entry,
        source: source,
        availability:
            NarrativeSpatialEventSourceAvailability.visibleButUnavailable,
        reason: reason,
      ),
    );
    diagnostics.add(
      NarrativeSpatialEventSourceDiagnostic(
        code: 'duplicateMapData',
        message: '$reason Map : $mapLabel.',
        mapId: entry.id,
      ),
    );
    return;
  }

  final map = matchingMaps.single;
  final mapSizeValid = _validSize(map.size);
  final mapSelectable =
      mapSizeValid && source != null && manifestIdentityUnique;
  options.add(
    _mapOption(
      entry: entry,
      source: source,
      availability: mapSelectable
          ? NarrativeSpatialEventSourceAvailability.selectable
          : mapSizeValid && source != null
              ? NarrativeSpatialEventSourceAvailability.visibleButUnavailable
              : NarrativeSpatialEventSourceAvailability.incompatible,
      reason: mapSelectable
          ? null
          : !manifestIdentityUnique
              ? 'L’identifiant de cette map est dupliqué dans le projet.'
              : 'La taille ou l’identifiant de la map est invalide.',
    ),
  );
  if (!mapSizeValid || source == null) {
    diagnostics.add(
      NarrativeSpatialEventSourceDiagnostic(
        code: 'invalidMapIdentityOrSize',
        message: 'La map $mapLabel ne peut pas fournir de source spatiale.',
        mapId: entry.id,
      ),
    );
  }

  _appendEntityOptions(
    entry: entry,
    map: map,
    mapUsable: mapSizeValid,
    mapIdentityUnique: manifestIdentityUnique,
    options: options,
    diagnostics: diagnostics,
  );
  _appendTriggerOptions(
    entry: entry,
    map: map,
    mapUsable: mapSizeValid,
    mapIdentityUnique: manifestIdentityUnique,
    options: options,
    diagnostics: diagnostics,
  );
  _appendPlacedElementOptions(
    entry: entry,
    map: map,
    mapUsable: mapSizeValid,
    options: options,
  );
}

NarrativeSpatialEventSourceOption _mapOption({
  required ProjectMapEntry entry,
  required NarrativeEventSourceRef? source,
  required NarrativeSpatialEventSourceAvailability availability,
  required String? reason,
}) {
  final mapLabel = _display(entry.name, entry.id);
  return NarrativeSpatialEventSourceOption(
    source: source,
    humanLabel: 'Entrée sur $mapLabel',
    humanDescription: 'Déclenchement à l’entrée de la map $mapLabel.',
    mapId: entry.id,
    mapLabel: mapLabel,
    sourceTypeLabel: 'Entrée de map',
    availability: availability,
    unavailableReason: reason,
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: 'map:${entry.id}',
    geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
    ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
  );
}

void _appendEntityOptions({
  required ProjectMapEntry entry,
  required MapData map,
  required bool mapUsable,
  required bool mapIdentityUnique,
  required List<NarrativeSpatialEventSourceOption> options,
  required List<NarrativeSpatialEventSourceDiagnostic> diagnostics,
}) {
  final groups = <String, List<MapEntity>>{};
  for (final entity in map.entities) {
    groups.putIfAbsent(entity.id, () => []).add(entity);
  }
  final ids = groups.keys.toList()..sort(compareNarrativeEventUtf16);
  for (final id in ids) {
    final entities = groups[id]!;
    final duplicate = entities.length > 1;
    if (duplicate) {
      diagnostics.add(
        NarrativeSpatialEventSourceDiagnostic(
          code: 'duplicateEntityId',
          message: 'Plusieurs éléments de la map utilisent l’identifiant $id.',
          mapId: entry.id,
          ownerId: id,
        ),
      );
    }
    for (final entity in entities) {
      options.add(
        _entityOption(
          entry: entry,
          map: map,
          entity: entity,
          mapUsable: mapUsable,
          mapIdentityUnique: mapIdentityUnique,
          duplicate: duplicate,
        ),
      );
    }
  }
}

NarrativeSpatialEventSourceOption _entityOption({
  required ProjectMapEntry entry,
  required MapData map,
  required MapEntity entity,
  required bool mapUsable,
  required bool mapIdentityUnique,
  required bool duplicate,
}) {
  final mapLabel = _display(entry.name, entry.id);
  final label = _display(entity.inspectorHeadline, entity.id);
  final kindLabel = _entityKindLabel(entity.kind);
  final geometryValid = mapUsable && _rectWithinMap(_entityBounds(entity), map);
  final source = _entitySource(entry.id, entity.id);
  final reason = switch ((
    duplicate,
    mapIdentityUnique,
    entity.kind,
    geometryValid,
    source
  )) {
    (true, _, _, _, _) =>
      'Cet identifiant est utilisé plusieurs fois sur la map.',
    (_, false, _, _, _) =>
      'L’identifiant de la map est dupliqué dans le projet.',
    (_, _, MapEntityKind.spawn, _, _) =>
      'Les points d’apparition sont gérés par le système de map.',
    (_, _, _, false, _) => 'La position de cet élément est invalide.',
    (_, _, _, _, null) => 'L’identifiant de cet élément est invalide.',
    _ => null,
  };
  final availability = reason == null
      ? NarrativeSpatialEventSourceAvailability.selectable
      : geometryValid && source != null
          ? NarrativeSpatialEventSourceAvailability.visibleButUnavailable
          : NarrativeSpatialEventSourceAvailability.incompatible;
  return NarrativeSpatialEventSourceOption(
    source: source,
    humanLabel: '$label — $kindLabel',
    humanDescription: 'Interaction avec $label, au $mapLabel.',
    mapId: entry.id,
    mapLabel: mapLabel,
    sourceTypeLabel: kindLabel,
    availability: availability,
    unavailableReason: reason,
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: 'entity:${entry.id}:${entity.id}',
    geometry: geometryValid
        ? NarrativeSpatialSourceGeometrySummary.bounds(_entityBounds(entity))
        : const NarrativeSpatialSourceGeometrySummary.unavailable(),
    ownerKind: NarrativeSpatialEventSourceOwnerKind.entity,
    presentationKind: entity.kind == MapEntityKind.npc
        ? NarrativeSpatialEventSourcePresentationKind.npc
        : NarrativeSpatialEventSourcePresentationKind.object,
    ownerId: entity.id,
  );
}

void _appendTriggerOptions({
  required ProjectMapEntry entry,
  required MapData map,
  required bool mapUsable,
  required bool mapIdentityUnique,
  required List<NarrativeSpatialEventSourceOption> options,
  required List<NarrativeSpatialEventSourceDiagnostic> diagnostics,
}) {
  final groups = <String, List<MapTrigger>>{};
  for (final trigger in map.triggers) {
    groups.putIfAbsent(trigger.id, () => []).add(trigger);
  }
  final ids = groups.keys.toList()..sort(compareNarrativeEventUtf16);
  for (final id in ids) {
    final triggers = groups[id]!;
    final duplicate = triggers.length > 1;
    if (duplicate) {
      diagnostics.add(
        NarrativeSpatialEventSourceDiagnostic(
          code: 'duplicateTriggerId',
          message: 'Plusieurs zones de la map utilisent l’identifiant $id.',
          mapId: entry.id,
          ownerId: id,
        ),
      );
    }
    for (final trigger in triggers) {
      options.add(
        _triggerOption(
          entry: entry,
          map: map,
          trigger: trigger,
          mapUsable: mapUsable,
          mapIdentityUnique: mapIdentityUnique,
          duplicate: duplicate,
        ),
      );
    }
  }
}

NarrativeSpatialEventSourceOption _triggerOption({
  required ProjectMapEntry entry,
  required MapData map,
  required MapTrigger trigger,
  required bool mapUsable,
  required bool mapIdentityUnique,
  required bool duplicate,
}) {
  final mapLabel = _display(entry.name, entry.id);
  final label = _display(trigger.name, trigger.id);
  final geometryValid = mapUsable && _rectWithinMap(trigger.area, map);
  final source = _triggerSource(entry.id, trigger.id);
  final authorable =
      trigger.type == TriggerType.event || trigger.type == TriggerType.custom;
  final reason = switch ((
    duplicate,
    mapIdentityUnique,
    authorable,
    geometryValid,
    source
  )) {
    (true, _, _, _, _) =>
      'Cet identifiant est utilisé plusieurs fois sur la map.',
    (_, false, _, _, _) =>
      'L’identifiant de la map est dupliqué dans le projet.',
    (_, _, false, _, _) =>
      'Cette zone système est configurée par les outils dédiés de la map.',
    (_, _, _, false, _) => 'La surface de cette zone est invalide.',
    (_, _, _, _, null) => 'L’identifiant de cette zone est invalide.',
    _ => null,
  };
  final availability = reason == null
      ? NarrativeSpatialEventSourceAvailability.selectable
      : geometryValid && source != null
          ? NarrativeSpatialEventSourceAvailability.visibleButUnavailable
          : NarrativeSpatialEventSourceAvailability.incompatible;
  return NarrativeSpatialEventSourceOption(
    source: source,
    humanLabel: '$label — Zone',
    humanDescription: 'Entrée dans $label, au $mapLabel.',
    mapId: entry.id,
    mapLabel: mapLabel,
    sourceTypeLabel: 'Zone',
    availability: availability,
    unavailableReason: reason,
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: 'trigger:${entry.id}:${trigger.id}',
    geometry: geometryValid
        ? NarrativeSpatialSourceGeometrySummary.bounds(trigger.area)
        : const NarrativeSpatialSourceGeometrySummary.unavailable(),
    ownerKind: NarrativeSpatialEventSourceOwnerKind.trigger,
    ownerId: trigger.id,
  );
}

void _appendPlacedElementOptions({
  required ProjectMapEntry entry,
  required MapData map,
  required bool mapUsable,
  required List<NarrativeSpatialEventSourceOption> options,
}) {
  for (final element in map.placedElements) {
    if (element.behaviors.isEmpty) continue;
    final mapLabel = _display(entry.name, entry.id);
    final label = _display(element.elementId, element.id);
    final bounds = MapRect(
      pos: element.pos,
      size: const GridSize(width: 1, height: 1),
    );
    final geometryValid = mapUsable && _rectWithinMap(bounds, map);
    options.add(
      NarrativeSpatialEventSourceOption(
        source: null,
        humanLabel: '$label — Élément placé',
        humanDescription: 'Élément interactif visible au $mapLabel.',
        mapId: entry.id,
        mapLabel: mapLabel,
        sourceTypeLabel: 'Élément placé',
        availability: geometryValid
            ? NarrativeSpatialEventSourceAvailability.visibleButUnavailable
            : NarrativeSpatialEventSourceAvailability.incompatible,
        unavailableReason:
            'Les éléments placés ne possèdent pas encore de source Event V2.',
        origin: NarrativeSpatialEventSourceOrigin.canonical,
        debugTechnicalLabel: 'placed:${entry.id}:${element.id}',
        geometry: geometryValid
            ? NarrativeSpatialSourceGeometrySummary.bounds(bounds)
            : const NarrativeSpatialSourceGeometrySummary.unavailable(),
        ownerKind: NarrativeSpatialEventSourceOwnerKind.placedElement,
        ownerId: element.id,
      ),
    );
  }
}

void _applyLegacyCompatibility({
  required List<ProjectMapEntry> entries,
  required Map<String, List<MapData>> mapsById,
  required List<LegacyMapEventProjection> projections,
  required List<NarrativeSpatialEventSourceOption> options,
  required List<NarrativeSpatialEventSourceDiagnostic> diagnostics,
}) {
  final grouped = <LegacySourceRef, List<LegacyMapEventProjection>>{};
  for (final projection in projections) {
    grouped.putIfAbsent(projection.provenance, () => []).add(projection);
  }
  final provenances = grouped.keys.toList()..sort(compareLegacySourceRefs);
  for (final provenance in provenances) {
    final group = grouped[provenance]!
      ..sort(
        (left, right) => _safeCanonicalSortKey(left.toJson())
            .compareTo(_safeCanonicalSortKey(right.toJson())),
      );
    final projection = group.first;
    final duplicateProjection = group.length > 1;
    final confirmed = projection.confirmedSource;
    final matchingIndexes = <int>[
      if (confirmed != null)
        for (var index = 0; index < options.length; index++)
          if (options[index].source == confirmed) index,
    ];
    final legacyIdentity = _legacyMapIdentity(provenance);
    if (legacyIdentity == null) continue;
    final mapId = legacyIdentity.$1;
    final eventId = legacyIdentity.$2;
    if (duplicateProjection) {
      diagnostics.add(
        NarrativeSpatialEventSourceDiagnostic(
          code: 'duplicateLegacyProjection',
          message:
              'Cette provenance legacy apparaît plusieurs fois dans le catalogue.',
          mapId: mapId,
          ownerId: eventId,
        ),
      );
    }
    if (!duplicateProjection && matchingIndexes.length == 1) {
      final index = matchingIndexes.single;
      options[index] = options[index].withLegacyProvenance(provenance);
      continue;
    }

    final entry = _entryFor(entries, mapId);
    final mapLabel = entry == null ? mapId : _display(entry.name, entry.id);
    final event = _legacyEventFor(mapsById[mapId], eventId);
    final eventLabel =
        event == null ? eventId : _display(event.title, event.id);
    final geometry = event == null
        ? const NarrativeSpatialSourceGeometrySummary.unavailable()
        : _legacyGeometry(event, mapsById[mapId]);
    final sourceHint =
        confirmed != null && _spatialSourceMapId(confirmed) == mapId
            ? confirmed
            : null;
    final availability = duplicateProjection
        ? NarrativeSpatialEventSourceAvailability.visibleButUnavailable
        : confirmed == null
            ? NarrativeSpatialEventSourceAvailability.legacyCompatibility
            : matchingIndexes.isEmpty
                ? NarrativeSpatialEventSourceAvailability.missing
                : NarrativeSpatialEventSourceAvailability.visibleButUnavailable;
    final reason = duplicateProjection
        ? 'Cette provenance legacy est dupliquée et doit être vérifiée.'
        : confirmed == null
            ? 'Cette source existante doit être confirmée avant utilisation.'
            : matchingIndexes.isEmpty
                ? 'La source canonique confirmée est introuvable.'
                : 'La source canonique confirmée est ambiguë.';
    options.add(
      NarrativeSpatialEventSourceOption(
        source: null,
        sourceHint: sourceHint,
        humanLabel: '$eventLabel — Événement existant',
        humanDescription:
            'Source existante à confirmer avant conversion, au $mapLabel.',
        mapId: mapId,
        mapLabel: mapLabel,
        sourceTypeLabel: 'Compatibilité',
        availability: availability,
        unavailableReason: reason,
        origin: NarrativeSpatialEventSourceOrigin.legacyCompatibility,
        debugTechnicalLabel: 'legacy:$mapId:$eventId',
        geometry: geometry,
        ownerKind: NarrativeSpatialEventSourceOwnerKind.legacyMapEvent,
        ownerId: eventId,
        legacyProvenances: [provenance],
      ),
    );
    if (confirmed != null && matchingIndexes.length != 1) {
      final code = matchingIndexes.isEmpty
          ? 'confirmedLegacySourceMissing'
          : 'confirmedLegacySourceAmbiguous';
      diagnostics.add(
        NarrativeSpatialEventSourceDiagnostic(
          code: code,
          message: matchingIndexes.isEmpty
              ? 'La source confirmée de $eventLabel est introuvable.'
              : 'La source confirmée de $eventLabel n’est pas unique.',
          mapId: mapId,
          ownerId: eventId,
        ),
      );
    }
  }
}

NarrativeSpatialSourceGeometrySummary _legacyGeometry(
  MapEventDefinition event,
  List<MapData>? maps,
) {
  final bounds = MapRect(
    pos: GridPos(x: event.position.x, y: event.position.y),
    size: const GridSize(width: 1, height: 1),
  );
  if (maps == null ||
      maps.length != 1 ||
      !_rectWithinMap(bounds, maps.single)) {
    return const NarrativeSpatialSourceGeometrySummary.unavailable();
  }
  return NarrativeSpatialSourceGeometrySummary.bounds(bounds);
}

(String, String)? _legacyMapIdentity(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => (mapId, eventId),
    scenarioSourceNode: (_, __) => null,
  );
}

ProjectMapEntry? _entryFor(List<ProjectMapEntry> entries, String mapId) {
  for (final entry in entries) {
    if (entry.id == mapId) return entry;
  }
  return null;
}

MapEventDefinition? _legacyEventFor(List<MapData>? maps, String eventId) {
  if (maps == null || maps.length != 1) return null;
  final matches = maps.single.events
      .where((event) => event.id == eventId)
      .toList(growable: false);
  return matches.length == 1 ? matches.single : null;
}

NarrativeEventSourceRef? _mapSource(String mapId) {
  if (!_validIdentity(mapId)) return null;
  return NarrativeEventSourceRef.mapEnter(mapId);
}

NarrativeEventSourceRef? _entitySource(String mapId, String entityId) {
  if (!_validIdentity(mapId) || !_validIdentity(entityId)) return null;
  return NarrativeEventSourceRef.entityInteract(mapId, entityId);
}

NarrativeEventSourceRef? _triggerSource(String mapId, String triggerId) {
  if (!_validIdentity(mapId) || !_validIdentity(triggerId)) return null;
  return NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
}

MapRect _entityBounds(MapEntity entity) =>
    MapRect(pos: entity.pos, size: entity.size);

bool _rectWithinMap(MapRect bounds, MapData map) {
  return _validSize(bounds.size) &&
      _validSize(map.size) &&
      bounds.pos.x >= 0 &&
      bounds.pos.y >= 0 &&
      bounds.pos.x + bounds.size.width <= map.size.width &&
      bounds.pos.y + bounds.size.height <= map.size.height;
}

bool _validSize(GridSize size) => size.width > 0 && size.height > 0;

bool _validIdentity(String value) => value.isNotEmpty && value.trim() == value;

String _display(String preferred, String fallback) {
  final trimmed = preferred.trim();
  if (trimmed.isNotEmpty) return trimmed;
  final fallbackTrimmed = fallback.trim();
  return fallbackTrimmed.isEmpty ? 'Sans nom' : fallbackTrimmed;
}

String? _spatialSourceMapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => null,
  );
}

String _entityKindLabel(MapEntityKind kind) => switch (kind) {
      MapEntityKind.npc => 'PNJ',
      MapEntityKind.sign => 'Panneau',
      MapEntityKind.item => 'Objet',
      MapEntityKind.spawn => 'Point d’apparition',
      MapEntityKind.custom => 'Élément',
    };

int _compareMapEntries(ProjectMapEntry left, ProjectMapEntry right) {
  final order = left.sortOrder.compareTo(right.sortOrder);
  if (order != 0) return order;
  final name = compareNarrativeEventUtf16(left.name, right.name);
  if (name != 0) return name;
  return compareNarrativeEventUtf16(left.id, right.id);
}

int _compareOptions(
  NarrativeSpatialEventSourceOption left,
  NarrativeSpatialEventSourceOption right,
) {
  for (final comparison in [
    compareNarrativeEventUtf16(left.mapLabel, right.mapLabel),
    compareNarrativeEventUtf16(left.mapId, right.mapId),
    left.ownerKind.index.compareTo(right.ownerKind.index),
    left.availability.index.compareTo(right.availability.index),
    compareNarrativeEventUtf16(left.humanLabel, right.humanLabel),
    compareNarrativeEventUtf16(
      left.debugTechnicalLabel,
      right.debugTechnicalLabel,
    ),
    compareNarrativeEventUtf16(
      _safeOptionSortKey(left),
      _safeOptionSortKey(right),
    ),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

String _safeOptionSortKey(NarrativeSpatialEventSourceOption option) {
  return _safeCanonicalSortKey(option.toDebugJson());
}

String _safeCanonicalSortKey(Object? value) {
  try {
    return canonicalizeNarrativeEventJson(value);
  } on FormatException {
    // Source identities are opaque and predate the stricter I-JSON boundary.
    // Their insertion-ordered debug shape remains a deterministic fallback.
    return value.toString();
  }
}

int _compareDiagnostics(
  NarrativeSpatialEventSourceDiagnostic left,
  NarrativeSpatialEventSourceDiagnostic right,
) {
  for (final comparison in [
    compareNarrativeEventUtf16(left.mapId, right.mapId),
    compareNarrativeEventUtf16(left.ownerId ?? '', right.ownerId ?? ''),
    compareNarrativeEventUtf16(left.code, right.code),
    compareNarrativeEventUtf16(left.message, right.message),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}
