import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('map events operations', () {
    test('add update and remove map event', () {
      final map = MapData(
        id: 'm1',
        name: 'Map 1',
        size: const GridSize(width: 10, height: 10),
        layers: const [
          MapLayer.tile(id: 'l_base', name: 'Base', tiles: []),
        ],
      );
      final created = addMapEventToMap(
        map,
        event: MapEventDefinition(
          id: 'evt_welcome',
          title: 'Welcome',
          position: const EventPosition(layerId: 'l_base', x: 3, y: 4),
          pages: const [
            MapEventPage(
              pageNumber: 0,
              message: 'Hi',
            ),
          ],
        ),
      );
      expect(created.events, hasLength(1));
      expect(created.events.first.id, 'evt_welcome');

      final updated = updateMapEventOnMap(
        created,
        eventId: 'evt_welcome',
        title: 'Welcome Updated',
        pages: const [
          MapEventPage(pageNumber: 1, message: 'Second'),
          MapEventPage(pageNumber: 0, message: 'First'),
        ],
      );
      expect(updated.events.single.title, 'Welcome Updated');
      expect(updated.events.single.pages.map((e) => e.pageNumber), [0, 1]);

      final removed = removeMapEventFromMap(
        updated,
        eventId: 'evt_welcome',
      );
      expect(removed.events, isEmpty);
    });

    test('rejects invalid event page list', () {
      final map = MapData(
        id: 'm1',
        name: 'Map 1',
        size: const GridSize(width: 8, height: 8),
        layers: [
          MapLayer.tile(
            id: 'l_base',
            name: 'Base',
            tiles: List<int>.filled(64, 0),
          ),
        ],
      );
      expect(
        () => addMapEventToMap(
          map,
          event: const MapEventDefinition(
            id: 'evt',
            title: 'E',
            position: EventPosition(layerId: 'l_base', x: 1, y: 1),
            pages: [
              MapEventPage(pageNumber: 0),
              MapEventPage(pageNumber: 0),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('map validator events', () {
    test('validates script reference against project context', () {
      final map = MapData(
        id: 'm1',
        name: 'Map 1',
        size: const GridSize(width: 8, height: 8),
        layers: [
          MapLayer.tile(
            id: 'l_base',
            name: 'Base',
            tiles: List<int>.filled(64, 0),
          ),
        ],
        events: const [
          MapEventDefinition(
            id: 'evt',
            title: 'Event',
            position: EventPosition(layerId: 'l_base', x: 2, y: 2),
            pages: [
              MapEventPage(
                pageNumber: 0,
                script: ScriptRef(scriptId: 'missing_script'),
              ),
            ],
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'P',
        maps: const [],
        tilesets: const [],
        scripts: const [],
      );
      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts valid event condition', () {
      final map = MapData(
        id: 'm1',
        name: 'Map 1',
        size: const GridSize(width: 8, height: 8),
        layers: [
          MapLayer.tile(
            id: 'l_base',
            name: 'Base',
            tiles: List<int>.filled(64, 0),
          ),
        ],
        events: [
          MapEventDefinition(
            id: 'evt',
            title: 'Event',
            position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('lot51_ready'),
              ),
            ],
          ),
        ],
      );
      expect(() => MapValidator.validate(map), returnsNormally);
    });
  });
}
