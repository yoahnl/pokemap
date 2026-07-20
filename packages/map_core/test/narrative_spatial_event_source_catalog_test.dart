import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase D D1 spatial source catalog', () {
    test('indexes canonical map, entity, and trigger sources truthfully', () {
      final map = _map(
        entities: [
          _entity('npc_lysa', 'Lysa', MapEntityKind.npc, 1, 2),
          _entity('sign_quay', 'Panneau du quai', MapEntityKind.sign, 2, 2),
          _entity('item_key', 'Clé rouillée', MapEntityKind.item, 3, 2),
          _entity(
            'custom_bell',
            'Cloche',
            MapEntityKind.custom,
            4,
            2,
            width: 2,
          ),
          _entity('spawn_player', 'Départ', MapEntityKind.spawn, 0, 0),
          _entity(
            'custom_metadata_disabled',
            'Levier',
            MapEntityKind.custom,
            5,
            2,
            properties: const {'enabled': 'false'},
          ),
        ],
        triggers: [
          _trigger('zone_quay', 'Quai nord', TriggerType.event, 1, 5),
          _trigger(
            'zone_custom',
            'Passage secret',
            TriggerType.custom,
            3,
            5,
            width: 2,
          ),
          for (final type in const [
            TriggerType.warp,
            TriggerType.message,
            TriggerType.interaction,
            TriggerType.spawn,
            TriggerType.camera,
          ])
            _trigger('system_${type.name}', type.name, type, 0, 7),
          _trigger(
            'invalid_area',
            'Zone invalide',
            TriggerType.event,
            8,
            8,
            width: 0,
          ),
        ],
        placedElements: [
          const MapPlacedElement(
            id: 'placed_decor',
            layerId: 'objects',
            elementId: 'crate',
            pos: GridPos(x: 2, y: 8),
          ),
          MapPlacedElement(
            id: 'placed_interactive',
            layerId: 'objects',
            elementId: 'switch',
            pos: const GridPos(x: 3, y: 8),
            behaviors: [
              MapPlacedElementBehavior(
                effect: const MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'Bonjour',
                ),
              ),
            ],
          ),
        ],
      );
      final project = _project([
        _mapEntry('map_port', 'Port des Brisants'),
      ]);

      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: [map],
      );

      expect(
        catalog.selectableOptions.map((option) => option.source),
        containsAll([
          NarrativeEventSourceRef.mapEnter('map_port'),
          NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
          NarrativeEventSourceRef.entityInteract('map_port', 'sign_quay'),
          NarrativeEventSourceRef.entityInteract('map_port', 'item_key'),
          NarrativeEventSourceRef.entityInteract('map_port', 'custom_bell'),
          NarrativeEventSourceRef.entityInteract(
            'map_port',
            'custom_metadata_disabled',
          ),
          NarrativeEventSourceRef.triggerEnter('map_port', 'zone_quay'),
          NarrativeEventSourceRef.triggerEnter('map_port', 'zone_custom'),
        ]),
      );
      expect(
        catalog.options.where(
          (option) =>
              option.ownerKind ==
              NarrativeSpatialEventSourceOwnerKind.placedElement,
        ),
        hasLength(1),
      );
      expect(
        catalog.options.any(
          (option) =>
              option.source ==
              NarrativeEventSourceRef.entityInteract(
                'map_port',
                'placed_interactive',
              ),
        ),
        isFalse,
      );
      expect(
        catalog.options
            .firstWhere(
              (option) => option.ownerId == 'spawn_player',
            )
            .availability,
        NarrativeSpatialEventSourceAvailability.visibleButUnavailable,
      );
      expect(
        catalog.options
            .firstWhere(
              (option) => option.ownerId == 'system_warp',
            )
            .unavailableReason,
        contains('système'),
      );
      expect(
        catalog.options
            .firstWhere(
              (option) => option.ownerId == 'invalid_area',
            )
            .availability,
        NarrativeSpatialEventSourceAvailability.incompatible,
      );

      final lysa = catalog.resolve(
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
      );
      expect(lysa.status, NarrativeSpatialEventSourceResolutionStatus.found);
      expect(lysa.option!.humanLabel, 'Lysa — PNJ');
      expect(
        lysa.option!.humanDescription,
        'Interaction avec Lysa, au Port des Brisants.',
      );
      expect(lysa.option!.debugTechnicalLabel, contains('npc_lysa'));
      expect(
        lysa.option!.geometry.bounds,
        const MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );
      expect(
        catalog
            .resolve(NarrativeEventSourceRef.mapEnter('map_port'))
            .option!
            .geometry
            .kind,
        NarrativeSpatialSourceGeometryKind.mapWide,
      );
    });

    test('groups real sources by map, presentation kind and reference state',
        () {
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project([
          _mapEntry('map_forest', 'Forêt', sortOrder: 1),
          _mapEntry('map_port', 'Port', sortOrder: 0),
        ]),
        maps: [
          _map(
            entities: [
              _entity('npc_lysa', 'Lysa', MapEntityKind.npc, 1, 2),
              _entity('item_key', 'Clé', MapEntityKind.item, 3, 2),
              _entity('sign_quay', 'Panneau', MapEntityKind.sign, 4, 2),
            ],
            triggers: [
              _trigger('zone_quay', 'Quai', TriggerType.event, 1, 5),
            ],
            placedElements: [
              MapPlacedElement(
                id: 'placed_switch',
                layerId: 'objects',
                elementId: 'switch',
                pos: const GridPos(x: 3, y: 8),
                behaviors: [
                  MapPlacedElementBehavior(
                    effect: const MapPlacedElementEffect(
                      type: MapPlacedElementEffectType.showMessage,
                      message: 'Bonjour',
                    ),
                  ),
                ],
              ),
            ],
          ),
          _map(id: 'map_forest', name: 'Forêt'),
        ],
      );

      expect(
        catalog.mapGroups.map((group) => group.mapId),
        ['map_forest', 'map_port'],
      );
      final port = catalog.mapGroups.singleWhere(
        (group) => group.mapId == 'map_port',
      );
      expect(port.mapEntrySources, hasLength(1));
      expect(port.zoneSources, hasLength(1));
      expect(port.npcSources.map((option) => option.ownerId), ['npc_lysa']);
      expect(
        port.objectSources.map((option) => option.ownerId),
        ['item_key', 'sign_quay'],
      );
      expect(port.unavailableSources, hasLength(1));
      expect(
        port.unavailableSources.single.presentationKind,
        NarrativeSpatialEventSourcePresentationKind.placedElement,
      );
      expect(
        port.unavailableSources.single.referenceState,
        NarrativeSpatialEventSourceReferenceState.notAttachable,
      );
      expect(
        port.selectableSources.every(
          (option) =>
              option.referenceState ==
              NarrativeSpatialEventSourceReferenceState.ready,
        ),
        isTrue,
      );
    });

    test('filters only compatible concrete trigger and source kinds', () {
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(
            entities: [
              _entity('npc_lysa', 'Lysa', MapEntityKind.npc, 1, 2),
            ],
            triggers: [
              _trigger('zone_quay', 'Quai', TriggerType.event, 1, 5),
            ],
          ),
        ],
      );

      expect(
        catalog
            .selectableOptionsCompatibleWith(
              NarrativeEventSourceKind.entityInteract,
            )
            .map((option) => option.ownerId),
        ['npc_lysa'],
      );
      expect(
        catalog
            .selectableOptionsCompatibleWith(
              NarrativeEventSourceKind.triggerEnter,
            )
            .map((option) => option.ownerId),
        ['zone_quay'],
      );
      expect(
        catalog.selectableOptionsCompatibleWith(
          NarrativeEventSourceKind.outcomeReceived,
        ),
        isEmpty,
      );
    });

    test('rebuild refreshes moved geometry without changing source identity',
        () {
      final project = _project([_mapEntry('map_port', 'Port')]);
      final initial = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: [
          _map(
            entities: [
              _entity('npc_lysa', 'Lysa', MapEntityKind.npc, 1, 2),
            ],
          ),
        ],
      );
      final moved = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: [
          _map(
            entities: [
              _entity('npc_lysa', 'Lysa', MapEntityKind.npc, 6, 7),
            ],
          ),
        ],
      );
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );

      expect(initial.resolve(source).option!.source, source);
      expect(moved.resolve(source).option!.source, source);
      expect(
        initial.resolve(source).option!.geometry.bounds!.pos,
        const GridPos(x: 1, y: 2),
      );
      expect(
        moved.resolve(source).option!.geometry.bounds!.pos,
        const GridPos(x: 6, y: 7),
      );
    });

    test('keeps missing and ambiguous owners visible but unselectable', () {
      final duplicateEntityMap = _map(
        entities: [
          _entity('npc_same', 'Lysa', MapEntityKind.npc, 1, 1),
          _entity('npc_same', 'Copie', MapEntityKind.npc, 2, 1),
        ],
      );
      final project = _project([
        _mapEntry('map_port', 'Port'),
        _mapEntry('map_missing', 'Forêt absente'),
      ]);

      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: [duplicateEntityMap],
      );

      expect(
        catalog
            .resolve(
              NarrativeEventSourceRef.entityInteract('map_port', 'npc_same'),
            )
            .status,
        NarrativeSpatialEventSourceResolutionStatus.ambiguous,
      );
      expect(
        catalog.resolve(NarrativeEventSourceRef.mapEnter('map_missing')).status,
        NarrativeSpatialEventSourceResolutionStatus.unavailable,
      );
      expect(
        catalog.options
            .firstWhere((option) => option.mapId == 'map_missing')
            .availability,
        NarrativeSpatialEventSourceAvailability.missing,
      );
      expect(
        catalog.options
            .firstWhere((option) => option.mapId == 'map_missing')
            .referenceState,
        NarrativeSpatialEventSourceReferenceState.needsMapRepair,
      );
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(['duplicateEntityId', 'missingMapData']),
      );
    });

    test('decorates confirmed legacy sources and keeps assisted ones separate',
        () {
      final confirmed = _legacyProjection(
        legacyEventId: 'legacy_confirmed',
        candidateSource:
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
        confirmed: true,
      );
      final assisted = _legacyProjection(
        legacyEventId: 'legacy_assisted',
        candidateSource:
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
        confirmed: false,
      );

      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(
            entities: [
              _entity('npc_lysa', 'Lysa', MapEntityKind.npc, 1, 2),
            ],
            events: [
              _legacyEvent('legacy_confirmed', 'Rencontre Lysa', 1, 2),
              _legacyEvent('legacy_assisted', 'Ancien événement', 4, 4),
            ],
          ),
        ],
        legacyProjections: [assisted, confirmed],
      );

      final lysa = catalog
          .resolve(
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
          )
          .option!;
      expect(lysa.legacyProvenances, [confirmed.provenance]);
      final legacy = catalog.options.singleWhere(
        (option) => option.legacyProvenances.contains(assisted.provenance),
      );
      expect(
        legacy.availability,
        NarrativeSpatialEventSourceAvailability.legacyCompatibility,
      );
      expect(
        legacy.referenceState,
        NarrativeSpatialEventSourceReferenceState.legacyCompatibility,
      );
      expect(legacy.source, isNull);
      expect(legacy.humanLabel, contains('Ancien événement'));
      expect(legacy.geometry.bounds!.pos, const GridPos(x: 4, y: 4));
    });

    test('is deterministic and immutable on informative scale fixtures', () {
      final maps = [
        _map(id: 'map_b', name: 'B'),
        _map(id: 'map_a', name: 'A'),
      ];
      final project = _project([
        _mapEntry('map_b', 'B', sortOrder: 1),
        _mapEntry('map_a', 'A', sortOrder: 0),
      ]);
      final before = jsonEncode([
        for (final map in maps) map.toJson(),
      ]);

      final first = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: maps.reversed.toList(),
      );
      final second = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: maps,
      );

      expect(first.toDebugJson(), second.toDebugJson());
      expect(jsonEncode([for (final map in maps) map.toJson()]), before);
      expect(
          () => first.options.add(first.options.first), throwsUnsupportedError);
      final indexedMap = first.optionsForSource(
        NarrativeEventSourceRef.mapEnter('map_a'),
      );
      expect(indexedMap, hasLength(1));
      expect(() => indexedMap.clear(), throwsUnsupportedError);

      for (final count in const [10, 100, 500]) {
        final entries = [
          for (var index = 0; index < count; index++)
            _mapEntry('map_$index', 'Map $index', sortOrder: index),
        ];
        final fixtureMaps = [
          for (var index = 0; index < count; index++)
            _map(id: 'map_$index', name: 'Map $index'),
        ];
        final stopwatch = Stopwatch()..start();
        final catalog = buildNarrativeSpatialEventSourceCatalog(
          project: _project(entries),
          maps: fixtureMaps,
        );
        stopwatch.stop();
        expect(catalog.selectableOptions, hasLength(count));
        // Informative only: no timing threshold belongs in a functional test.
        expect(stopwatch.elapsedMicroseconds, greaterThanOrEqualTo(0));
      }
    });

    test('blocks duplicate manifest maps and preserves malformed identities',
        () {
      final duplicateManifest = buildNarrativeSpatialEventSourceCatalog(
        project: _project([
          _mapEntry('map_port', 'Port A'),
          _mapEntry('map_port', 'Port B'),
        ]),
        maps: [_map()],
      );

      expect(duplicateManifest.selectableOptions, isEmpty);
      expect(
        duplicateManifest
            .resolve(
              NarrativeEventSourceRef.mapEnter('map_port'),
            )
            .status,
        NarrativeSpatialEventSourceResolutionStatus.ambiguous,
      );
      expect(
        duplicateManifest.diagnostics.map((diagnostic) => diagnostic.code),
        contains('duplicateManifestMapId'),
      );

      final malformed = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry(' map_port ', 'Map invalide')]),
        maps: [
          _map(
            id: ' map_port ',
            entities: [
              _entity(' npc ', 'Nom', MapEntityKind.npc, 1, 1),
            ],
          ),
        ],
      );
      expect(
        malformed.options.every(
          (option) =>
              option.availability ==
              NarrativeSpatialEventSourceAvailability.incompatible,
        ),
        isTrue,
      );
      expect(malformed.options.first.mapId, ' map_port ');
      expect(
        malformed.options
            .firstWhere((option) => option.ownerId != null)
            .ownerId,
        ' npc ',
      );
      expect(
        malformed.options.any(
          (option) => option.debugTechnicalLabel.contains(' map_port '),
        ),
        isTrue,
      );
    });

    test('totally orders duplicate owners independently of input order', () {
      final firstEntity =
          _entity('npc_same', 'Même nom', MapEntityKind.npc, 1, 1);
      final secondEntity =
          _entity('npc_same', 'Même nom', MapEntityKind.npc, 2, 1);
      final project = _project([_mapEntry('map_port', 'Port')]);

      final first = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: [
          _map(entities: [firstEntity, secondEntity])
        ],
      );
      final second = buildNarrativeSpatialEventSourceCatalog(
        project: project,
        maps: [
          _map(entities: [secondEntity, firstEntity])
        ],
      );

      expect(first.toDebugJson(), second.toDebugJson());
    });

    test('deduplicates legacy provenance and preserves missing source hints',
        () {
      final confirmed = _legacyProjection(
        legacyEventId: 'legacy_confirmed',
        candidateSource: NarrativeEventSourceRef.entityInteract(
          'map_port',
          'npc_missing',
        ),
        confirmed: true,
      );

      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(
            events: [
              _legacyEvent('legacy_confirmed', 'Ancienne rencontre', 1, 1),
            ],
          ),
        ],
        legacyProjections: [confirmed],
      );

      final legacy = catalog.options.singleWhere(
        (option) => option.legacyProvenances.contains(confirmed.provenance),
      );
      expect(legacy.source, isNull);
      expect(legacy.sourceHint, confirmed.confirmedSource);
      expect(
        legacy.availability,
        NarrativeSpatialEventSourceAvailability.missing,
      );
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains('confirmedLegacySourceMissing'),
      );

      final duplicateConfirmed = _legacyProjection(
        legacyEventId: 'legacy_confirmed',
        candidateSource: NarrativeEventSourceRef.entityInteract(
          'map_port',
          'npc_lysa',
        ),
        confirmed: true,
      );
      final duplicate = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(
            entities: [
              const MapEntity(
                id: 'npc_lysa',
                name: 'Lysa',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2, y: 2),
              ),
            ],
            events: [
              _legacyEvent('legacy_confirmed', 'Ancienne rencontre', 1, 1),
            ],
          ),
        ],
        legacyProjections: [duplicateConfirmed, duplicateConfirmed],
      );
      final duplicateCodes =
          duplicate.diagnostics.map((diagnostic) => diagnostic.code);
      expect(
        duplicateCodes,
        contains('duplicateLegacyProjection'),
      );
      expect(duplicateCodes, isNot(contains('confirmedLegacySourceAmbiguous')));
      expect(duplicateCodes, isNot(contains('confirmedLegacySourceMissing')));
    });

    test('uses payload-backed human labels and rejects contradictory options',
        () {
      final entity = MapEntity(
        id: 'npc_lysa',
        name: '',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
        npc: const MapEntityNpcData(displayName: 'Capitaine Lysa'),
      );
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(entities: [entity])
        ],
      );
      expect(
        catalog.options
            .firstWhere((option) => option.ownerId == 'npc_lysa')
            .humanLabel,
        'Capitaine Lysa — PNJ',
      );

      expect(
        () => NarrativeSpatialEventSourceOption(
          source: NarrativeEventSourceRef.entityInteract(
            'map_port',
            'npc_lysa',
          ),
          humanLabel: 'Contradictoire',
          humanDescription: 'Contrat contradictoire.',
          mapId: 'map_port',
          mapLabel: 'Port',
          sourceTypeLabel: 'Map',
          availability: NarrativeSpatialEventSourceAvailability.selectable,
          origin: NarrativeSpatialEventSourceOrigin.canonical,
          debugTechnicalLabel: 'contradictory',
          geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
          ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeSpatialEventSourceOption(
          source: null,
          humanLabel: 'Map impossible',
          humanDescription: 'Une map ne possède pas de propriétaire local.',
          mapId: 'map_port',
          mapLabel: 'Port',
          sourceTypeLabel: 'Map',
          availability:
              NarrativeSpatialEventSourceAvailability.visibleButUnavailable,
          unavailableReason: 'Option de test invalide.',
          origin: NarrativeSpatialEventSourceOrigin.canonical,
          debugTechnicalLabel: 'map:map_port',
          geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
          ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
          ownerId: 'unexpected',
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeSpatialEventSourceOption(
          source: null,
          humanLabel: 'Entité impossible',
          humanDescription: 'Une entité doit conserver son identité locale.',
          mapId: 'map_port',
          mapLabel: 'Port',
          sourceTypeLabel: 'PNJ',
          availability:
              NarrativeSpatialEventSourceAvailability.visibleButUnavailable,
          unavailableReason: 'Option de test invalide.',
          origin: NarrativeSpatialEventSourceOrigin.canonical,
          debugTechnicalLabel: 'entity:map_port:missing',
          geometry: const NarrativeSpatialSourceGeometrySummary.unavailable(),
          ownerKind: NarrativeSpatialEventSourceOwnerKind.entity,
        ),
        throwsArgumentError,
      );
    });

    test('sorts opaque non-I-JSON identities without throwing', () {
      const opaqueId = 'npc_\uFDD0';
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(
            entities: const [
              MapEntity(
                id: opaqueId,
                name: 'Identité opaque',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 1, y: 1),
              ),
            ],
          ),
        ],
      );

      final option = catalog.options.singleWhere(
        (candidate) => candidate.ownerId == opaqueId,
      );
      expect(option.selectable, isTrue);
      expect(option.source, isNotNull);

      final projection = _legacyProjection(
        legacyEventId: 'legacy_opaque',
        candidateSource: NarrativeEventSourceRef.entityInteract(
          'map_port',
          opaqueId,
        ),
        confirmed: true,
      );
      final duplicate = buildNarrativeSpatialEventSourceCatalog(
        project: _project([_mapEntry('map_port', 'Port')]),
        maps: [
          _map(
            entities: const [
              MapEntity(
                id: opaqueId,
                name: 'Identité opaque',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 1, y: 1),
              ),
            ],
            events: [_legacyEvent('legacy_opaque', 'Legacy opaque', 1, 1)],
          ),
        ],
        legacyProjections: [projection, projection],
      );
      expect(
        duplicate.diagnostics.map((diagnostic) => diagnostic.code),
        contains('duplicateLegacyProjection'),
      );
    });
  });
}

ProjectManifest _project(List<ProjectMapEntry> maps) {
  return ProjectManifest(
    name: 'Selbrume',
    maps: maps,
    tilesets: const [],
  );
}

ProjectMapEntry _mapEntry(
  String id,
  String name, {
  int sortOrder = 0,
}) {
  return ProjectMapEntry(
    id: id,
    name: name,
    relativePath: 'maps/$id.json',
    sortOrder: sortOrder,
  );
}

MapData _map({
  String id = 'map_port',
  String name = 'Port des Brisants',
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
  List<MapPlacedElement> placedElements = const [],
  List<MapEventDefinition> events = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 10, height: 10),
    entities: entities,
    triggers: triggers,
    placedElements: placedElements,
    events: events,
  );
}

MapEntity _entity(
  String id,
  String name,
  MapEntityKind kind,
  int x,
  int y, {
  int width = 1,
  Map<String, String> properties = const {},
}) {
  return MapEntity(
    id: id,
    name: name,
    kind: kind,
    pos: GridPos(x: x, y: y),
    size: GridSize(width: width, height: 1),
    properties: properties,
  );
}

MapTrigger _trigger(
  String id,
  String name,
  TriggerType type,
  int x,
  int y, {
  int width = 1,
}) {
  return MapTrigger(
    id: id,
    name: name,
    type: type,
    area: MapRect(
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: 1),
    ),
  );
}

MapEventDefinition _legacyEvent(
  String id,
  String title,
  int x,
  int y,
) {
  return MapEventDefinition(
    id: id,
    title: title,
    pages: const [],
    position: EventPosition(layerId: 'objects', x: x, y: y),
  );
}

LegacyMapEventProjection _legacyProjection({
  required String legacyEventId,
  required NarrativeEventSourceRef candidateSource,
  required bool confirmed,
}) {
  final provenance = LegacySourceRef.mapEvent('map_port', legacyEventId);
  return LegacyMapEventProjection(
    provenance: provenance,
    classification: confirmed
        ? LegacyMigrationClassification.autoSafe
        : LegacyMigrationClassification.assisted,
    claimStatus: LegacyProjectionClaimStatus.absent,
    existingClaim: null,
    sourceFingerprint: 'sha256:${'a' * 64}',
    sourceCandidates: [
      LegacyMapEventSourceCandidate(
        source: candidateSource,
        evidence: confirmed
            ? LegacyMapEventSourceEvidenceKind.explicitMetadata
            : LegacyMapEventSourceEvidenceKind.exactUniqueFootprint,
        confirmed: confirmed,
        reason: confirmed ? 'Métadonnée explicite.' : 'Empreinte unique.',
      ),
    ],
    pages: const [],
    preservedEventJson: const {},
    unconvertibleDataPaths: const [],
    linkedReferences: const [],
    diagnostics: const [],
    manualActions: const [],
  );
}
