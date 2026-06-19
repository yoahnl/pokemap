import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _mapId = 'map_ns_event_34_port';
const _eventId = 'evt_runtime_handoff';
const _sceneId = 'scene_ns_event_34_handoff';
const _factId = 'fact_ns_event_34_scene_started';
const _factRuleId = 'rule_ns_event_34_fact_projection';
const _consumedRuleId = 'rule_ns_event_34_consumed_projection';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NS-EVENT-34 runtime handoff smoke', () {
    test('runtime consumes editor-authored scene target event', () async {
      final root = await Directory.systemTemp.createTemp(
        'ns_event_34_scene_target_handoff_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final fixture = _editorAuthoredFixture();
      final projectFilePath = await _writeRuntimeProject(
        root,
        project: fixture.project,
        map: fixture.map,
      );

      final persistedProject = jsonDecode(
        await File(projectFilePath).readAsString(),
      ) as Map<String, dynamic>;
      final persistedMap = jsonDecode(
        await File(p.join(root.path, 'maps', '$_mapId.json')).readAsString(),
      ) as Map<String, dynamic>;

      expect((persistedProject['scenes'] as List<Object?>), hasLength(1));
      expect(
        (((persistedMap['events'] as List<Object?>).single
                as Map<String, dynamic>)['pages'] as List<Object?>)
            .single as Map<String, dynamic>,
        containsPair(
          'sceneTarget',
          containsPair('sceneId', _sceneId),
        ),
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _mapId,
      );
      final loadedEvent = bundle.map.events.single;
      expect(loadedEvent.id, _eventId);
      expect(loadedEvent.pages.single.sceneTarget?.sceneId, _sceneId);
      expect(loadedEvent.pages.single.script, isNull);
      expect(loadedEvent.pages.single.message, isNull);
      expect(
        loadedEvent.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );

      final saveRepository = _TempFileGameSaveRepository(root);
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: saveRepository,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.storyFlags.activeFlags.contains(_factId) &&
            game.gameStateSnapshot.consumedEventIds.contains(_eventId),
      );

      final updatedState = game.gameStateSnapshot;
      expect(updatedState.storyFlags.activeFlags, contains(_factId));
      expect(updatedState.consumedEventIds, contains(_eventId));
      expect(updatedState.currentMapId, _mapId);

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: bundle.manifest,
        gameState: updatedState,
        map: bundle.map,
      );
      expect(projection.enabledEventIds, contains(_eventId));

      expect(
        await SaveGameUseCase(saveRepository).execute(updatedState),
        isTrue,
      );
      final reloaded = await LoadGameUseCase(saveRepository).execute();
      expect(reloaded, isNotNull);
      final normalizedReloaded = normalizeLoadedGameState(reloaded!);
      expect(normalizedReloaded.storyFlags.activeFlags, contains(_factId));
      expect(normalizedReloaded.consumedEventIds, contains(_eventId));
    });
  });
}

_RuntimeHandoffFixture _editorAuthoredFixture() {
  const baseMap = MapData(
    id: _mapId,
    name: 'NS-EVENT-34 Port',
    size: GridSize(width: 3, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_ns_event_34',
        name: 'Spawn NS-EVENT-34',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_ns_event_34'),
  );

  final draft = createEventBuilderDraftEventOnMap(
    baseMap,
    title: 'Runtime handoff',
    position: const EventPosition(layerId: 'objects', x: 1, y: 0),
    type: MapEventType.actor,
    reusePolicy: EventBuilderReusePolicy.oneShot,
  );
  var map = setMapEventPageSceneTarget(
    draft.updatedMap,
    eventId: draft.createdEvent.id,
    pageNumber: 0,
    sceneId: _sceneId,
  );
  map = updateMapEventOnMap(
    map,
    eventId: draft.createdEvent.id,
    id: _eventId,
  );
  final event = map.events.singleWhere((candidate) => candidate.id == _eventId);

  final project = ProjectManifest(
    name: 'NS-EVENT-34 Runtime Handoff',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'NS-EVENT-34 Port',
        relativePath: 'maps/$_mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Scene runtime handoff started',
      ),
    ],
    worldRules: <WorldRuleDefinition>[
      WorldRuleDefinition(
        id: _factRuleId,
        label: 'Fact projects world impact',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: _factId,
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: _mapId,
          eventId: _eventId,
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
        priority: 0,
      ),
      WorldRuleDefinition(
        id: _consumedRuleId,
        label: 'Consumed event projects world impact',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: _eventId,
          predicate: WorldRuleSourcePredicate.consumed,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: _mapId,
          eventId: _eventId,
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
        priority: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _handoffScene(),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );

  return _RuntimeHandoffFixture(
    project: project,
    map: map,
    event: event,
  );
}

SceneAsset _handoffScene() {
  return SceneAsset(
    id: _sceneId,
    name: 'NS-EVENT-34 handoff scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: <SceneNode>[
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(
          id: 'node_mark_event_consumed',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: _mapId,
              eventId: _eventId,
            ),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'edge_start_set_fact',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_set_fact_mark_event',
          fromNodeId: 'node_set_fact',
          fromPortId: 'completed',
          toNodeId: 'node_mark_event_consumed',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_mark_event_end',
          fromNodeId: 'node_mark_event_consumed',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

Future<String> _writeRuntimeProject(
  Directory root, {
  required ProjectManifest project,
  required MapData map,
}) async {
  final mapsDir = Directory(p.join(root.path, 'maps'));
  await mapsDir.create(recursive: true);
  await File(p.join(mapsDir.path, '$_mapId.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
  );
  return projectFile.path;
}

final _testViewportSize = Vector2(640, 480);

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
  fail('Timed out waiting for the NS-EVENT-34 runtime smoke to settle.');
}

final class _RuntimeHandoffFixture {
  const _RuntimeHandoffFixture({
    required this.project,
    required this.map,
    required this.event,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition event;
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory(p.join(_testDirectory.path, 'pokemonProject'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return p.join(saveDir.path, 'game_save.json');
  }
}
