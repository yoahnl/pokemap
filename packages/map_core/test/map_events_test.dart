import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('map event scene targets', () {
    test('reads older page JSON without sceneTarget as null', () {
      final page = MapEventPage.fromJson({'pageNumber': 0});

      expect(page.sceneTarget, isNull);
      expect(page.toJson().containsKey('sceneTarget'), isFalse);
    });

    test('round-trips page JSON with sceneTarget', () {
      final page = MapEventPage.fromJson({
        'pageNumber': 0,
        'sceneTarget': {'sceneId': 'scene_intro'},
      });

      expect(
          page.sceneTarget, const MapEventSceneTarget(sceneId: 'scene_intro'));
      expect(MapEventPage.fromJson(page.toJson()), page);
    });

    test('copyWith preserves sceneTarget', () {
      const page = MapEventPage(
        pageNumber: 0,
        sceneTarget: MapEventSceneTarget(sceneId: 'scene_intro'),
      );

      final updated = page.copyWith(message: 'Hi');

      expect(updated.sceneTarget, page.sceneTarget);
      expect(updated.message, 'Hi');
    });
  });

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

    test('sets and clears a scene target on an existing event page', () {
      final condition = ScriptConditionFactory.flagIsSet('flag_ready');
      final map = _mapWithEvent(
        MapEventPage(
          pageNumber: 2,
          message: 'Legacy message',
          script: const ScriptRef(scriptId: 'script_intro'),
          condition: condition,
          metadata: const {'tone': 'calm'},
        ),
      );

      final updated = setMapEventPageSceneTarget(
        map,
        eventId: 'event_gate',
        pageNumber: 2,
        sceneId: ' scene_intro ',
      );
      final updatedPage = updated.events.single.pages.single;

      expect(map.events.single.pages.single.sceneTarget, isNull);
      expect(updatedPage.sceneTarget,
          const MapEventSceneTarget(sceneId: 'scene_intro'));
      expect(updatedPage.message, 'Legacy message');
      expect(updatedPage.script, const ScriptRef(scriptId: 'script_intro'));
      expect(updatedPage.condition, condition);
      expect(updatedPage.metadata, {'tone': 'calm'});

      final cleared = clearMapEventPageSceneTarget(
        updated,
        eventId: 'event_gate',
        pageNumber: 2,
      );

      expect(cleared.events.single.pages.single.sceneTarget, isNull);
      expect(cleared.events.single.pages.single.message, 'Legacy message');
    });

    test('scene target operations reject invalid references', () {
      final map = _mapWithEvent(const MapEventPage(pageNumber: 0));

      expect(
        () => setMapEventPageSceneTarget(
          map,
          eventId: 'missing_event',
          pageNumber: 0,
          sceneId: 'scene_intro',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => setMapEventPageSceneTarget(
          map,
          eventId: 'event_gate',
          pageNumber: 99,
          sceneId: 'scene_intro',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => setMapEventPageSceneTarget(
          map,
          eventId: 'event_gate',
          pageNumber: 0,
          sceneId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => clearMapEventPageSceneTarget(
          map,
          eventId: 'event_gate',
          pageNumber: 99,
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
      const project = ProjectManifest(
        name: 'P',
        maps: [],
        tilesets: [],
        scripts: [],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
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

    test('validates sceneTarget against ProjectManifest.scenes', () {
      final map = _mapWithEvent(
        const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_intro'),
        ),
      );
      final project = _projectWithScenes([_validScene('scene_intro')]);

      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        returnsNormally,
      );

      final projectWithoutScene = _projectWithScenes([]);
      expect(
        () => MapValidator.validate(
          map,
          projectDialogueContext: projectWithoutScene,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _mapWithEvent(MapEventPage page) {
  return MapData(
    id: 'map_test',
    name: 'Test Map',
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
        id: 'event_gate',
        title: 'Gate',
        position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
        pages: [page],
      ),
    ],
  );
}

ProjectManifest _projectWithScenes(List<SceneAsset> scenes) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _validScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Intro Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
