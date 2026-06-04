import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CinematicStageMapSourceCatalog', () {
    test('builds cinematic stage map source catalog from real map data', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(
          entities: const [
            MapEntity(
              id: 'entity_professor',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 6),
              npc: MapEntityNpcData(displayName: 'Professor Willow'),
            ),
            MapEntity(
              id: 'entity_notice',
              name: 'Notice board',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 7, y: 2),
              sign: MapEntitySignData(title: 'Daily notice'),
            ),
          ],
          events: const [
            MapEventDefinition(
              id: 'event_arrival',
              title: 'Arrival trigger',
              position: EventPosition(layerId: 'ground', x: 9, y: 3),
              pages: [MapEventPage(pageNumber: 0)],
              type: MapEventType.triggerZone,
            ),
          ],
        ),
      );

      expect(catalog.status, CinematicStageMapSourceCatalogStatus.available);
      expect(catalog.stageMapId, 'map_lab');
      expect(catalog.stageMapLabel, 'Research Lab');
      expect(catalog.entities, hasLength(2));
      expect(catalog.events, hasLength(1));

      final npc = catalog.entityById('entity_professor');
      expect(npc, isNotNull);
      expect(npc!.label, 'Professor Willow');
      expect(npc.secondaryLabel, 'map_lab:entity_professor');
      expect(npc.kindLabel, 'PNJ');
      expect(npc.canBindActor, isTrue);
      expect(npc.canBeMovementTarget, isTrue);
      expect(npc.positionSummary, 'Tuile 4, 6');
      expect(npc.diagnostics, isEmpty);

      final sign = catalog.entityById('entity_notice');
      expect(sign, isNotNull);
      expect(sign!.label, 'Daily notice');
      expect(sign.secondaryLabel, 'map_lab:entity_notice');
      expect(sign.kindLabel, 'Panneau');
      expect(sign.canBindActor, isFalse);
      expect(sign.canBeMovementTarget, isTrue);

      final event = catalog.eventById('event_arrival');
      expect(event, isNotNull);
      expect(event!.label, 'Arrival trigger');
      expect(event.secondaryLabel, 'map_lab:event_arrival');
      expect(event.kindLabel, 'Zone trigger');
      expect(event.canBindActor, isFalse);
      expect(event.canBeMovementTarget, isTrue);
      expect(event.positionSummary, 'Tuile 9, 3');
    });

    test('returns missing stage map status without stage map', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: null,
        mapData: _mapData(),
      );

      expect(
        catalog.status,
        CinematicStageMapSourceCatalogStatus.missingStageMap,
      );
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapMissing,
      ]);
    });

    test('returns unavailable status without map data', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: null,
      );

      expect(
        catalog.status,
        CinematicStageMapSourceCatalogStatus.mapDataUnavailable,
      );
      expect(catalog.stageMapId, 'map_lab');
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapDataUnavailable,
      ]);
    });

    test(
        'returns map id mismatch status when map data does not match stage map',
        () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(id: 'map_other'),
      );

      expect(
        catalog.status,
        CinematicStageMapSourceCatalogStatus.mapIdMismatch,
      );
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapDataIdMismatch,
      ]);
    });

    test('uses entity id as fallback label only when no better label exists',
        () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(
          entities: const [
            MapEntity(
              id: 'entity_custom_fallback',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
      );

      final entity = catalog.entityById('entity_custom_fallback');
      expect(entity, isNotNull);
      expect(entity!.label, 'entity_custom_fallback');
      expect(entity.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.entityMissingLabelFallbackToId,
      ]);
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicStageMapSourceDiagnosticCode.stageMapHasNoEvents),
      );
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicStageMapSourceDiagnosticCode.entityMissingLabelFallbackToId,
        ),
      );
    });

    test('uses event id as fallback label only when title is empty', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(
          events: const [
            MapEventDefinition(
              id: 'event_without_title',
              position: EventPosition(layerId: 'ground', x: 3, y: 5),
              pages: [MapEventPage(pageNumber: 0)],
            ),
          ],
        ),
      );

      final event = catalog.eventById('event_without_title');
      expect(event, isNotNull);
      expect(event!.label, 'event_without_title');
      expect(event.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.eventMissingTitleFallbackToId,
      ]);
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicStageMapSourceDiagnosticCode.stageMapHasNoEntities),
      );
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicStageMapSourceDiagnosticCode.eventMissingTitleFallbackToId,
        ),
      );
    });

    test('handles empty entity and event lists', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(catalog.status, CinematicStageMapSourceCatalogStatus.available);
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapHasNoEntities,
        CinematicStageMapSourceDiagnosticCode.stageMapHasNoEvents,
      ]);
    });
  });
}

ProjectMapEntry _stageMap() {
  return const ProjectMapEntry(
    id: 'map_lab',
    name: 'Research Lab',
    relativePath: 'maps/research_lab.json',
  );
}

MapData _mapData({
  String id = 'map_lab',
  List<MapEntity> entities = const [],
  List<MapEventDefinition> events = const [],
}) {
  return MapData(
    id: id,
    name: 'Research Lab',
    size: const GridSize(width: 12, height: 10),
    entities: entities,
    events: events,
  );
}
