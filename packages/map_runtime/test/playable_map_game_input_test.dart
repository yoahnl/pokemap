import 'dart:convert';
import 'dart:io';
import 'dart:ui' show KeyEventDeviceType;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
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
          deviceType: KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );
      final upResult = game.onKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: KeyEventDeviceType.gamepad,
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
