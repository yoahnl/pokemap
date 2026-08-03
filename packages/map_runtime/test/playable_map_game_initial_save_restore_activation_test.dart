import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _sourceMapId = 'initial_bundle_map';
const _restoredMapId = 'restored_boot_map';
const _restoredFlag = 'test.initial_save_restore.map_enter';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit saveRestore boot restores map and pose before one mapEnter',
      () async {
    final project = _project();
    final bundles = <String, RuntimeMapBundle>{
      _sourceMapId: _bundle(project, _sourceMap()),
      _restoredMapId: _bundle(project, _restoredMap()),
    };
    Future<RuntimeMapBundle> loadBundle({
      required String projectFilePath,
      required String mapId,
    }) async {
      return bundles[mapId] ?? (throw StateError('Unknown map $mapId'));
    }

    final game = PlayableMapGame(
      bundle: bundles[_sourceMapId]!,
      projectFilePath: '/tmp/initial_save_restore/project.json',
      saveData: const SaveData(
        saveId: 'versioned-launch-save',
        currentMapId: _restoredMapId,
        playerPosition: GridPos(x: 2, y: 1),
        playerFacing: EntityFacing.west,
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      runtimeMapBundleLoader: loadBundle,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
    expect(
        game.gameStateSnapshot.storyFlags.activeFlags, contains(_restoredFlag));
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _restoredMapId);
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
  fail('Timed out waiting for the saveRestore activation dispatch.');
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Initial save restore integration',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _sourceMapId,
        name: 'Initial Bundle Map',
        relativePath: 'maps/initial.json',
      ),
      ProjectMapEntry(
        id: _restoredMapId,
        name: 'Restored Boot Map',
        relativePath: 'maps/restored.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[_restoredMapEnterScenario],
  );
}

RuntimeMapBundle _bundle(ProjectManifest project, MapData map) {
  return RuntimeMapBundle(
    manifest: project,
    map: map,
    projectRootDirectory: '/tmp/initial_save_restore',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Initial Bundle Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'source_spawn',
          name: 'Source Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'source_spawn'),
    );

MapData _restoredMap() => const MapData(
      id: _restoredMapId,
      name: 'Restored Boot Map',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'restored_spawn',
          name: 'Restored Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'restored_spawn'),
    );

const _restoredMapEnterScenario = ScenarioAsset(
  id: 'restored_boot_map_enter_scenario',
  name: 'Restored boot map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _restoredMapId),
    ),
    ScenarioNode(
      id: 'set_restored_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _restoredFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_restored_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_restored_flag',
      toNodeId: 'end',
    ),
  ],
);
