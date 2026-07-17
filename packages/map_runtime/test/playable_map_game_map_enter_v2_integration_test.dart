import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'test_map_enter_load';
const _mapEnterFlag = 'test.map_enter.after_load';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadGame dispatches legacy mapEnter after restoring the same map',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'restored-save',
        currentMapId: _mapId,
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'The fixture must prove that the legacy mapEnter Scenario runs.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);

    expect(await game.loadGame(), isTrue);
    expect(game.gameStateSnapshot.saveId, 'restored-save');
    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'A successful load must dispatch mapEnter after state restore.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 2);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });

  test('missing save target never creates a completed map activation',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'missing-map-save',
        currentMapId: 'missing_save_target',
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    var loaderCalls = 0;
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
      runtimeMapBundleLoader: ({
        required String projectFilePath,
        required String mapId,
      }) async {
        loaderCalls++;
        throw StateError('Map $mapId is unavailable');
      },
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(await game.loadGame(), isFalse);
    expect(loaderCalls, 1);
    expect(game.gameStateSnapshot.currentMapId, _mapId);
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the initial map activation dispatch.');
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Map Enter Load Integration Test',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: _mapId,
          name: 'Map Enter Load',
          relativePath: 'maps/test_map_enter_load.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      scenarios: const <ScenarioAsset>[_mapEnterScenario],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: _mapId,
      name: 'Map Enter Load',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/test_map_enter_load',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const _mapEnterScenario = ScenarioAsset(
  id: 'test_map_enter_load_scenario',
  name: 'Set flag on map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _mapEnterFlag),
    ),
    ScenarioNode(
      id: 'end',
      type: ScenarioNodeType.end,
    ),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_map_enter_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_map_enter_flag',
      toNodeId: 'end',
    ),
  ],
);

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}
