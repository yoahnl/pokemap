import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NS-EVENT-35 trigger variants and lifecycle semantics', () {
    test('NS-EVENT-35 runtime consumes object scene target interaction',
        () async {
      final loaded = await _loadRuntimeCase(
        suffix: 'object_interaction',
        type: MapEventType.object,
        reusePolicy: EventBuilderReusePolicy.oneShot,
        includeSetFact: true,
        includeMarkEventConsumed: false,
      );

      expect(loaded.event.type, MapEventType.object);
      expect(loaded.event.pages.single.sceneTarget?.sceneId, loaded.sceneId);

      expect(
        loaded.game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      await _pumpUntil(
        loaded.game,
        () => loaded.game.gameStateSnapshot.storyFlags.activeFlags
            .contains(loaded.factId),
      );

      expect(
        loaded.game.gameStateSnapshot.storyFlags.activeFlags,
        contains(loaded.factId),
      );
      expect(
        loaded.game.gameStateSnapshot.consumedEventIds,
        isNot(contains(loaded.eventId)),
      );
    });

    test(
        'NS-EVENT-35 trigger zone handoff is partial because entering the tile does not run the scene',
        () async {
      final loaded = await _loadRuntimeCase(
        suffix: 'trigger_zone_entry',
        type: MapEventType.triggerZone,
        reusePolicy: EventBuilderReusePolicy.oneShot,
        includeSetFact: true,
        includeMarkEventConsumed: true,
      );

      expect(loaded.event.type, MapEventType.triggerZone);
      expect(loaded.game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      await _runSingleMove(loaded.game, RuntimeInputControl.right);

      // This is the NS-EVENT-35 boundary: MapEventType.triggerZone is authorable,
      // but PlayableMapGame has no map-event enter-zone hook yet. Moving onto the
      // event tile must therefore stay a documented PARTIAL rather than a false
      // PASS.
      expect(loaded.game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(
        loaded.game.gameStateSnapshot.storyFlags.activeFlags,
        isNot(contains(loaded.factId)),
      );
      expect(
        loaded.game.gameStateSnapshot.consumedEventIds,
        isNot(contains(loaded.eventId)),
      );
      expect(loaded.game.debugFlowPhaseName, 'overworld');
    });

    test('NS-EVENT-35 oneShot metadata alone does not consume event', () async {
      final loaded = await _loadRuntimeCase(
        suffix: 'oneshot_without_mark',
        type: MapEventType.actor,
        reusePolicy: EventBuilderReusePolicy.oneShot,
        includeSetFact: true,
        includeMarkEventConsumed: false,
      );

      expect(
        loaded
            .event.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );

      expect(
        loaded.game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      await _pumpUntil(
        loaded.game,
        () => loaded.game.gameStateSnapshot.storyFlags.activeFlags
            .contains(loaded.factId),
      );

      expect(
        loaded.game.gameStateSnapshot.storyFlags.activeFlags,
        contains(loaded.factId),
      );
      expect(
        loaded.game.gameStateSnapshot.consumedEventIds,
        isNot(contains(loaded.eventId)),
      );
    });

    test(
        'NS-EVENT-35 explicit markEventConsumed remains canonical runtime consumption',
        () async {
      final loaded = await _loadRuntimeCase(
        suffix: 'reusable_explicit_mark',
        type: MapEventType.object,
        reusePolicy: EventBuilderReusePolicy.reusable,
        includeSetFact: false,
        includeMarkEventConsumed: true,
      );

      expect(
        loaded
            .event.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.reusable.name,
      );

      expect(
        loaded.game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      await _pumpUntil(
        loaded.game,
        () => loaded.game.gameStateSnapshot.consumedEventIds
            .contains(loaded.eventId),
      );

      expect(
        loaded.game.gameStateSnapshot.consumedEventIds,
        contains(loaded.eventId),
      );
    });
  });
}

Future<_LoadedRuntimeCase> _loadRuntimeCase({
  required String suffix,
  required MapEventType type,
  required EventBuilderReusePolicy reusePolicy,
  required bool includeSetFact,
  required bool includeMarkEventConsumed,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'ns_event_35_${suffix}_',
  );
  addTearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  final mapId = 'map_ns_event_35_$suffix';
  final eventId = 'evt_ns_event_35_$suffix';
  final sceneId = 'scene_ns_event_35_$suffix';
  final factId = 'fact_ns_event_35_$suffix';
  final fixture = _runtimeFixture(
    mapId: mapId,
    eventId: eventId,
    sceneId: sceneId,
    factId: factId,
    type: type,
    reusePolicy: reusePolicy,
    includeSetFact: includeSetFact,
    includeMarkEventConsumed: includeMarkEventConsumed,
  );
  final projectFilePath = await _writeRuntimeProject(
    root,
    mapId: mapId,
    project: fixture.project,
    map: fixture.map,
  );
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: mapId,
  );
  final loadedEvent = bundle.map.events.singleWhere(
    (candidate) => candidate.id == eventId,
  );
  final game = _TestPlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFilePath,
  );

  game.onGameResize(_testViewportSize);
  await game.onLoad();

  return _LoadedRuntimeCase(
    game: game,
    event: loadedEvent,
    eventId: eventId,
    sceneId: sceneId,
    factId: factId,
  );
}

_RuntimeFixture _runtimeFixture({
  required String mapId,
  required String eventId,
  required String sceneId,
  required String factId,
  required MapEventType type,
  required EventBuilderReusePolicy reusePolicy,
  required bool includeSetFact,
  required bool includeMarkEventConsumed,
}) {
  final baseMap = MapData(
    id: mapId,
    name: 'NS-EVENT-35 $mapId',
    size: const GridSize(width: 4, height: 3),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: const <MapEntity>[
      MapEntity(
        id: 'spawn_ns_event_35',
        name: 'Spawn NS-EVENT-35',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_ns_event_35'),
  );

  final draft = createEventBuilderDraftEventOnMap(
    baseMap,
    title: 'NS-EVENT-35 $eventId',
    position: const EventPosition(layerId: 'objects', x: 1, y: 0),
    type: type,
    reusePolicy: reusePolicy,
  );
  var map = setMapEventPageSceneTarget(
    draft.updatedMap,
    eventId: draft.createdEvent.id,
    pageNumber: 0,
    sceneId: sceneId,
  );
  map = updateMapEventOnMap(
    map,
    eventId: draft.createdEvent.id,
    id: eventId,
  );

  final project = ProjectManifest(
    name: 'NS-EVENT-35 Runtime Gate',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: mapId,
        name: 'NS-EVENT-35 Map',
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: factId,
        label: 'NS-EVENT-35 $factId',
      ),
    ],
    scenes: <SceneAsset>[
      _scene(
        sceneId: sceneId,
        mapId: mapId,
        eventId: eventId,
        factId: factId,
        includeSetFact: includeSetFact,
        includeMarkEventConsumed: includeMarkEventConsumed,
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );

  return _RuntimeFixture(project: project, map: map);
}

SceneAsset _scene({
  required String sceneId,
  required String mapId,
  required String eventId,
  required String factId,
  required bool includeSetFact,
  required bool includeMarkEventConsumed,
}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start),
  ];
  final edges = <SceneEdge>[];
  var previousNodeId = 'node_start';
  var edgeIndex = 0;

  void addConsequenceNode(String nodeId, SceneConsequence consequence) {
    nodes.add(
      SceneNode(
        id: nodeId,
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(consequence),
      ),
    );
    edges.add(
      SceneEdge(
        id: 'edge_${edgeIndex++}_$nodeId',
        fromNodeId: previousNodeId,
        fromPortId: 'completed',
        toNodeId: nodeId,
        kind: previousNodeId == 'node_start'
            ? SceneEdgeKind.defaultFlow
            : SceneEdgeKind.actionCompleted,
      ),
    );
    previousNodeId = nodeId;
  }

  if (includeSetFact) {
    addConsequenceNode(
      'node_set_fact',
      SceneConsequence.setFact(factId: factId, value: true),
    );
  }
  if (includeMarkEventConsumed) {
    addConsequenceNode(
      'node_mark_event_consumed',
      SceneConsequence.markEventConsumed(mapId: mapId, eventId: eventId),
    );
  }

  nodes.add(SceneNode(id: 'node_end', kind: SceneNodeKind.end));
  edges.add(
    SceneEdge(
      id: 'edge_${edgeIndex}_end',
      fromNodeId: previousNodeId,
      fromPortId: 'completed',
      toNodeId: 'node_end',
      kind: previousNodeId == 'node_start'
          ? SceneEdgeKind.defaultFlow
          : SceneEdgeKind.actionCompleted,
    ),
  );

  return SceneAsset(
    id: sceneId,
    name: 'NS-EVENT-35 $sceneId',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: nodes,
      edges: edges,
    ),
  );
}

Future<String> _writeRuntimeProject(
  Directory root, {
  required String mapId,
  required ProjectManifest project,
  required MapData map,
}) async {
  final mapsDir = Directory(p.join(root.path, 'maps'));
  await mapsDir.create(recursive: true);
  await File(p.join(mapsDir.path, '$mapId.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
  );
  return projectFile.path;
}

final _testViewportSize = Vector2(640, 480);

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );

  for (var i = 0; i < 120; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping) {
      return;
    }
  }
  fail('Timed out waiting for the NS-EVENT-35 movement step to settle.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the NS-EVENT-35 runtime smoke to settle.');
}

final class _RuntimeFixture {
  const _RuntimeFixture({required this.project, required this.map});

  final ProjectManifest project;
  final MapData map;
}

final class _LoadedRuntimeCase {
  const _LoadedRuntimeCase({
    required this.game,
    required this.event,
    required this.eventId,
    required this.sceneId,
    required this.factId,
  });

  final PlayableMapGame game;
  final MapEventDefinition event;
  final String eventId;
  final String sceneId;
  final String factId;
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
  });

  @override
  bool get isLoaded => true;
}
