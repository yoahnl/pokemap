import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder draft creation operations', () {
    test('creates a valid draft actor event with page zero', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Rencontre rival au port',
        position: const EventPosition(layerId: 'events', x: 2, y: 3),
      );

      final event = result.createdEvent;
      final page = event.pages.single;

      expect(result.updatedMap.events, [event]);
      expect(event.id, 'evt_rencontre_rival_au_port');
      expect(event.title, 'Rencontre rival au port');
      expect(event.type, MapEventType.actor);
      expect(
          event.position, const EventPosition(layerId: 'events', x: 2, y: 3));
      expect(page.pageNumber, 0);
      expect(result.createdContract.source.eventId, event.id);
    });

    test('generates a stable slug id from a human title', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: '  Rencontre rival au port  ',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      expect(result.createdEvent.id, 'evt_rencontre_rival_au_port');
      expect(result.createdEvent.title, 'Rencontre rival au port');
    });

    test('suffixes the generated id when the base id already exists', () {
      final map = _map(
        events: [
          _event('evt_rencontre_rival_au_port'),
          _event('evt_rencontre_rival_au_port_2'),
        ],
      );

      final result = createEventBuilderDraftEventOnMap(
        map,
        title: 'Rencontre rival au port',
        position: const EventPosition(layerId: 'events', x: 3, y: 4),
      );

      expect(result.createdEvent.id, 'evt_rencontre_rival_au_port_3');
      expect(result.updatedMap.events.map((event) => event.id), [
        'evt_rencontre_rival_au_port',
        'evt_rencontre_rival_au_port_2',
        'evt_rencontre_rival_au_port_3',
      ]);
    });

    test('falls back to a readable title and stable id for blank title', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: '   ',
        position: const EventPosition(layerId: 'events', x: 1, y: 2),
      );

      expect(result.createdEvent.title, 'Nouvel événement');
      expect(result.createdEvent.id, 'evt_nouvel_evenement');
    });

    test('normalizes accented title characters before id generation', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Événement du phare',
        position: const EventPosition(layerId: 'events', x: 1, y: 2),
      );

      expect(result.createdEvent.id, 'evt_evenement_du_phare');
    });

    test('respects the caller supplied position without defaults', () {
      const position = EventPosition(layerId: 'events', x: 5, y: 6);

      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Coffre abandonné',
        position: position,
      );

      expect(result.createdEvent.position, position);
    });

    test('propagates map event validation when position is out of bounds', () {
      expect(
        () => createEventBuilderDraftEventOnMap(
          _map(),
          title: 'Sortie carte',
          position: const EventPosition(layerId: 'events', x: 99, y: 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('stores one-shot Event Builder metadata by default', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Rival au port',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      final metadata = result.createdEvent.pages.single.metadata;

      expect(
        metadata[EventBuilderMetadataKeys.schemaVersion],
        EventBuilderMetadataKeys.currentSchemaVersion,
      );
      expect(
        metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );
      expect(
        result.createdContract.behavior.reusePolicy,
        EventBuilderReusePolicy.oneShot,
      );
    });

    test('stores reusable Event Builder metadata when requested', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Rumeur au comptoir',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
        reusePolicy: EventBuilderReusePolicy.reusable,
      );

      final metadata = result.createdEvent.pages.single.metadata;

      expect(
        metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.reusable.name,
      );
      expect(
        result.createdContract.behavior.reusePolicy,
        EventBuilderReusePolicy.reusable,
      );
    });

    test('does not create scene target, script, message or condition', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Garde somnolent',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      final page = result.createdEvent.pages.single;

      expect(page.sceneTarget, isNull);
      expect(page.script, isNull);
      expect(page.message, isNull);
      expect(page.condition, isNull);
    });

    test('is visible in the read model as draft with missing scene action', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Pêcheur en détresse',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      final readModel = buildEventBuilderReadModel(
        events: [result.createdEvent],
      );
      final summary = readModel.events.single;

      expect(summary.status, EventBuilderEventStatus.draft);
      expect(summary.statusLabel, 'Brouillon');
      expect(summary.sceneAction.isMissing, isTrue);
      expect(summary.diagnostics.single.kind,
          EventBuilderDiagnosticReadModelKind.missingSceneAction);
    });

    test('preserves existing events unchanged', () {
      final existing = _event(
        'evt_existing',
        title: 'Déjà là',
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
        ),
      );
      final map = _map(events: [existing]);

      final result = createEventBuilderDraftEventOnMap(
        map,
        title: 'Nouveau draft',
        position: const EventPosition(layerId: 'events', x: 2, y: 2),
      );

      expect(result.updatedMap.events.first, existing);
      expect(result.updatedMap.events, hasLength(2));
    });
  });
}

MapData _map({List<MapEventDefinition> events = const []}) {
  return MapData(
    id: 'map_selbrume',
    name: 'Selbrume',
    size: const GridSize(width: 8, height: 8),
    layers: const [
      MapLayer.tile(id: 'events', name: 'Events', tiles: []),
    ],
    events: events,
  );
}

MapEventDefinition _event(
  String id, {
  String title = 'Existing',
  MapEventPage page = const MapEventPage(pageNumber: 0),
}) {
  return MapEventDefinition(
    id: id,
    title: title,
    position: const EventPosition(layerId: 'events', x: 0, y: 0),
    pages: [page],
  );
}
