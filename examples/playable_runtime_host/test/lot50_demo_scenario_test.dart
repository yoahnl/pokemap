import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:playable_runtime_host/lot50_demo_scenario.dart';

void main() {
  group('injectLot50DemoScenario', () {
    test('injects demo event and demo script in runtime bundle', () {
      final bundle = _baseBundle();

      final result = injectLot50DemoScenario(bundle);

      expect(result.setup, isNotNull);
      expect(result.warning, isNull);
      expect(result.setup!.mapId, equals('test_map'));
      expect(
        result.bundle.map.events.any((event) => event.id == lot50DemoEventId),
        isTrue,
      );
      expect(
        result.bundle.manifest.scripts
            .any((script) => script.id == lot50DemoScriptId),
        isTrue,
      );

      final injectedEvent = result.bundle.map.events
          .firstWhere((event) => event.id == lot50DemoEventId);
      expect(injectedEvent.pages.length, equals(2));
      expect(injectedEvent.pages.first.script?.scriptId, lot50DemoScriptId);
      expect(
        injectedEvent.position.x == 0 && injectedEvent.position.y == 0,
        isFalse,
      );

      final injectedScript = result.bundle.manifest.scripts
          .firstWhere((script) => script.id == lot50DemoScriptId);
      final commandTypes =
          injectedScript.asset.nodes.first.commands.map((c) => c.type).toList();
      expect(commandTypes, contains(ScriptCommandType.setFlag));
      expect(commandTypes, contains(ScriptCommandType.incrementVariable));
      expect(commandTypes, contains(ScriptCommandType.markEventConsumed));
    });

    test('replaces legacy event/script with same IDs instead of duplicating',
        () {
      final bundle = _baseBundle(
        map: _baseMap().copyWith(
          events: const [
            MapEventDefinition(
              id: lot50DemoEventId,
              title: 'Old',
              position: EventPosition(layerId: 'objects', x: 0, y: 0),
              pages: [
                MapEventPage(pageNumber: 0, message: 'old'),
              ],
            ),
          ],
        ),
        manifest: _baseManifest().copyWith(
          scripts: const [
            ProjectScriptEntry(
              id: lot50DemoScriptId,
              name: 'Old Script',
              asset: ScriptAsset(id: lot50DemoScriptId, nodes: []),
            ),
          ],
        ),
      );

      final result = injectLot50DemoScenario(bundle);
      final scriptsWithId = result.bundle.manifest.scripts
          .where((script) => script.id == lot50DemoScriptId)
          .toList();
      final eventsWithId = result.bundle.map.events
          .where((event) => event.id == lot50DemoEventId)
          .toList();

      expect(scriptsWithId.length, equals(1));
      expect(eventsWithId.length, equals(1));
      expect(scriptsWithId.first.name, equals('LOT 50 Demo Script'));
      expect(eventsWithId.first.title, equals('LOT 50 Demo Event'));
    });

    test('returns warning and unchanged bundle when no candidate cell exists',
        () {
      const tinyMap = MapData(
        id: 'tiny',
        name: 'Tiny',
        size: GridSize(width: 1, height: 1),
        layers: [
          MapLayer.object(id: 'objects', name: 'Objects'),
        ],
        events: [
          MapEventDefinition(
            id: 'occupied',
            title: 'Occupied',
            position: EventPosition(layerId: 'objects', x: 0, y: 0),
            pages: [MapEventPage(pageNumber: 0, message: 'busy')],
          ),
        ],
      );
      final bundle = _baseBundle(map: tinyMap);

      final result = injectLot50DemoScenario(bundle);

      expect(result.setup, isNull);
      expect(result.warning, isNotNull);
      expect(identical(result.bundle, bundle), isTrue);
    });
  });
}

RuntimeMapBundle _baseBundle({
  MapData? map,
  ProjectManifest? manifest,
}) {
  return RuntimeMapBundle(
    manifest: manifest ?? _baseManifest(),
    map: map ?? _baseMap(),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
}

ProjectManifest _baseManifest() {
  return const ProjectManifest(
    name: 'Test Project',
    maps: [
      ProjectMapEntry(
          id: 'test_map', name: 'Test Map', relativePath: 'maps/test_map.json')
    ],
    tilesets: [],
  );
}

MapData _baseMap() {
  return const MapData(
    id: 'test_map',
    name: 'Test Map',
    size: GridSize(width: 8, height: 8),
    layers: [
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
  );
}
