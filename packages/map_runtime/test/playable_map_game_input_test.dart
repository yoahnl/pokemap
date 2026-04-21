import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui show Image, KeyEventDeviceType;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame runtime input seam', () {
    test('public runtime input API is safe before onLoad', () {
      final game = PlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      expect(
        () => game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        returnsNormally,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isFalse,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.up),
        ),
        isFalse,
      );
    });

    test('onKeyEvent forwards keyboard events to the runtime input seam', () {
      final game = _RecordingPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      final result = game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        const <LogicalKeyboardKey>{},
      );

      expect(result, KeyEventResult.handled);
      expect(
        game.recordedEvents,
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        ],
      );
    });

    test('onKeyEvent forwards gamepad buttons to the runtime input seam', () {
      final game = _RecordingPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      final downResult = game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );
      final upResult = game.onKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );

      expect(downResult, KeyEventResult.handled);
      expect(upResult, KeyEventResult.handled);
      expect(
        game.recordedEvents,
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
          RuntimeInputEvent.release(RuntimeInputControl.primary),
        ],
      );
    });

    test('one cardinal step lands on the expected cell without a visual offset',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_step_regression_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _singleStepMap(),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'step_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);

      expect(game.gameStateSnapshot.currentMapId, 'step_map');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 0));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test(
        'warp transition keeps the player visually aligned to the logical target',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_regression_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMap(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'warp_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping &&
            !game.debugHasPendingMapTransition,
      );

      expect(game.gameStateSnapshot.currentMapId, 'warp_target');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 1));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test(
        'connection transition keeps the player visually aligned to the logical target',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_regression_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping &&
            !game.debugHasPendingMapTransition,
      );

      expect(game.gameStateSnapshot.currentMapId, 'connection_target');
      expect(
        game.gameStateSnapshot.playerPosition,
        const GridPos(x: 0, y: 0),
      );
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 0));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test(
        'connection transition animates one entry step in target map coordinates',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_trajectory_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final firstTopLeftAfterSwap = await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'connection_target',
      );

      expect(firstTopLeftAfterSwap, isNotNull);
      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(game.debugIsPlayerStepping, isTrue);
      expect(
        firstTopLeftAfterSwap,
        game.debugWorldTopLeftForSpawnCell(const GridPos(x: -1, y: 0)),
      );

      final samples = <double>[firstTopLeftAfterSwap!.x];
      for (var i = 0; i < 3; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
        samples.add(game.debugPlayerWorldTopLeft.x);
      }
      expect(samples[1], greaterThan(samples[0]));
      expect(samples[2], greaterThan(samples[1]));
      expect(samples[3], greaterThan(samples[2]));

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugWorldTopLeftForSpawnCell(const GridPos(x: 0, y: 0)),
      );
    });

    test(
        'warp transition snaps cleanly after fade and does not interpolate across maps',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_trajectory_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMap(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final firstTopLeftAfterSwap = await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'warp_target',
      );

      expect(firstTopLeftAfterSwap, isNotNull);
      expect(game.debugIsPlayerStepping, isFalse);

      for (var i = 0; i < 5; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
        expect(game.debugPlayerWorldTopLeft.x, firstTopLeftAfterSwap!.x);
        expect(game.debugPlayerWorldTopLeft.y, firstTopLeftAfterSwap.y);
      }
    });

    test(
        'connection transition west and east use target-space entry start cells',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_directional_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
          _connectionTargetWestMap(),
          _connectionWestSourceMap(),
        ],
      );

      final eastBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final eastGame = _TestPlayableMapGame(
        bundle: eastBundle,
        projectFilePath: projectFilePath,
      );
      eastGame.onGameResize(_testViewportSize);
      await eastGame.onLoad();
      expect(
        eastGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      eastGame.update(0.016);
      expect(
        eastGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );
      final eastFirstTopLeft = await _captureFirstTopLeftOnMap(
        eastGame,
        targetMapId: 'connection_target',
      );
      expect(
        eastFirstTopLeft,
        eastGame.debugWorldTopLeftForSpawnCell(const GridPos(x: -1, y: 0)),
      );

      final westBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source_west',
      );
      final westGame = _TestPlayableMapGame(
        bundle: westBundle,
        projectFilePath: projectFilePath,
      );
      westGame.onGameResize(_testViewportSize);
      await westGame.onLoad();
      expect(
        westGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.left),
        ),
        isTrue,
      );
      westGame.update(0.016);
      expect(
        westGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.left),
        ),
        isTrue,
      );
      final westFirstTopLeft = await _captureFirstTopLeftOnMap(
        westGame,
        targetMapId: 'connection_target_west',
      );
      expect(
        westFirstTopLeft,
        westGame.debugWorldTopLeftForSpawnCell(const GridPos(x: 3, y: 0)),
      );
    });

    test(
        'connection transition keeps input locked until visual entry step completes',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_input_lock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'connection_target',
      );

      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(game.debugIsPlayerStepping, isTrue);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.left),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.left),
        ),
        isTrue,
      );

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );
      expect(
        game.gameStateSnapshot.playerPosition,
        const GridPos(x: 0, y: 0),
      );
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 0));
    });

    test('warp to already loaded map reuses cached map visuals', () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_cache_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMapWithConnectionToTarget(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundleLoadCounts = <String, int>{};
      final tilesetLoadCounts = <String, int>{};
      Future<RuntimeMapBundle> bundleLoader({
        required String projectFilePath,
        required String mapId,
      }) async {
        bundleLoadCounts[mapId] = (bundleLoadCounts[mapId] ?? 0) + 1;
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
        );
        return RuntimeMapBundle(
          manifest: bundle.manifest,
          map: bundle.map,
          projectRootDirectory: bundle.projectRootDirectory,
          tilesetAbsolutePathsById: const <String, String>{
            'shared': '/tmp/shared_tileset.png',
          },
        );
      }
      Future<Map<String, RuntimeTilesetImage>> tilesetLoader(
        Map<String, String> absolutePathByTilesetId,
      ) async {
        for (final path in absolutePathByTilesetId.values) {
          tilesetLoadCounts[path] = (tilesetLoadCounts[path] ?? 0) + 1;
        }
        return <String, RuntimeTilesetImage>{
          for (final entry in absolutePathByTilesetId.entries)
            entry.key: RuntimeTilesetImage(
              images: const <ui.Image>[],
              chunks: const <RuntimeTilesetChunk>[],
              width: 0,
              height: 0,
            ),
        };
      }
      final initialBundle = await bundleLoader(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: initialBundle,
        projectFilePath: projectFilePath,
        runtimeMapBundleLoader: bundleLoader,
        runtimeTilesetImageLoader: tilesetLoader,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();
      await _pumpUntil(game, () => game.debugIsMapLoaded('warp_target'));

      final bundleLoadsBeforeWarp = Map<String, int>.from(bundleLoadCounts);
      final tilesetLoadsBeforeWarp = Map<String, int>.from(tilesetLoadCounts);

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'warp_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );

      expect(bundleLoadCounts, equals(bundleLoadsBeforeWarp));
      expect(tilesetLoadCounts, equals(tilesetLoadsBeforeWarp));
    });

    test(
        'connection transition rebases a preloaded target map before the entry step',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_rebase_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionHubMap(),
          _connectionSouthSourceMap(),
          _targetMap(id: 'shared_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_hub',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();
      await _pumpUntil(
        game,
        () =>
            game.debugIsMapLoaded('shared_target') &&
            game.debugIsMapLoaded('connection_source_south'),
      );

      await _runSingleMove(game, RuntimeInputControl.down);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_source_south' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final firstTopLeftAfterSwap = await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'shared_target',
      );

      expect(firstTopLeftAfterSwap, isNotNull);
      expect(
        firstTopLeftAfterSwap,
        game.debugWorldTopLeftForSpawnCell(const GridPos(x: -1, y: 0)),
      );
    });
  });
}

class _RecordingPlayableMapGame extends PlayableMapGame {
  _RecordingPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
  });

  final List<RuntimeInputEvent> recordedEvents = <RuntimeInputEvent>[];

  @override
  bool handleRuntimeInputEvent(RuntimeInputEvent event) {
    recordedEvents.add(event);
    return true;
  }
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.runtimeMapBundleLoader,
    super.runtimeTilesetImageLoader,
  });

  @override
  bool get isLoaded => true;
}

RuntimeMapBundle _baseBundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Test Project',
      maps: [
        ProjectMapEntry(
          id: 'test_map',
          name: 'Test Map',
          relativePath: 'maps/test_map.json',
        ),
      ],
      tilesets: [],
    ),
    map: const MapData(
      id: 'test_map',
      name: 'Test Map',
      size: GridSize(width: 8, height: 8),
      layers: [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
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
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
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
  fail('Timed out waiting for the runtime game to settle.');
}

Future<Vector2?> _captureFirstTopLeftOnMap(
  PlayableMapGame game, {
  required String targetMapId,
  int maxTicks = 240,
}) async {
  if (game.gameStateSnapshot.currentMapId == targetMapId) {
    return game.debugPlayerWorldTopLeft.clone();
  }
  for (var i = 0; i < maxTicks; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (game.gameStateSnapshot.currentMapId == targetMapId) {
      return game.debugPlayerWorldTopLeft.clone();
    }
  }
  return null;
}

Future<String> _writeRuntimeProject(
  Directory root, {
  required List<MapData> maps,
}) async {
  final manifest = ProjectManifest(
    name: 'Runtime Movement Regression',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
  );
  final mapsDir = Directory(p.join(root.path, 'maps'));
  await mapsDir.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDir.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

MapData _singleStepMap() {
  return const MapData(
    id: 'step_map',
    name: 'Step Map',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_step',
        name: 'Spawn Step',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_step'),
  );
}

MapData _warpSourceMap() {
  return const MapData(
    id: 'warp_source',
    name: 'Warp Source',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_warp_source',
        name: 'Spawn Warp Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'warp_to_target',
        pos: GridPos(x: 1, y: 0),
        targetMapId: 'warp_target',
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_warp_source'),
  );
}

MapData _connectionSourceMap() {
  return const MapData(
    id: 'connection_source',
    name: 'Connection Source',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_source',
        name: 'Spawn Connection Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'connection_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source'),
  );
}

MapData _connectionWestSourceMap() {
  return const MapData(
    id: 'connection_source_west',
    name: 'Connection Source West',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_source_west',
        name: 'Spawn Connection Source West',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'connection_target_west',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source_west'),
  );
}

MapData _connectionHubMap() {
  return const MapData(
    id: 'connection_hub',
    name: 'Connection Hub',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_hub',
        name: 'Spawn Connection Hub',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'shared_target',
        offset: 0,
      ),
      MapConnection(
        direction: MapConnectionDirection.south,
        targetMapId: 'connection_source_south',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_hub'),
  );
}

MapData _connectionSouthSourceMap() {
  return const MapData(
    id: 'connection_source_south',
    name: 'Connection Source South',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_source_south',
        name: 'Spawn Connection Source South',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'shared_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source_south'),
  );
}

MapData _connectionTargetWestMap() {
  return const MapData(
    id: 'connection_target_west',
    name: 'Connection Target West',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_target_west',
        name: 'Spawn Connection Target West',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_target_west'),
  );
}

MapData _targetMap({
  required String id,
}) {
  return MapData(
    id: id,
    name: 'Target Map',
    size: const GridSize(width: 3, height: 2),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: const <MapEntity>[
      MapEntity(
        id: 'spawn_target',
        name: 'Spawn Target',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_target'),
  );
}

MapData _warpSourceMapWithConnectionToTarget() {
  return const MapData(
    id: 'warp_source',
    name: 'Warp Source',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_warp_source',
        name: 'Spawn Warp Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'warp_to_target',
        pos: GridPos(x: 1, y: 0),
        targetMapId: 'warp_target',
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'warp_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_warp_source'),
  );
}
