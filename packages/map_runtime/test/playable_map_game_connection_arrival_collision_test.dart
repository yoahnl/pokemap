import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'package:map_runtime/src/presentation/flame/warp_transition_overlay_component.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'connection rejects feet collision when the cell centre is free',
    () async {
      final fixture = await _fixture(maskPixel: (16, 24));
      final target = fixture.targetWorld;
      expect(
        target.isCellCenterBlockedLegacyForGridIndexedSystems(0, 1),
        isFalse,
      );
      expect(target.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectRejected(fixture.game, 'Connection blocked');
    },
  );

  test(
    'connection accepts free feet when the cell centre touches a mask',
    () async {
      final fixture = await _fixture(maskPixel: (16, 16));
      final target = fixture.targetWorld;
      expect(
        target.isCellCenterBlockedLegacyForGridIndexedSystems(0, 1),
        isTrue,
      );
      expect(target.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
    },
  );

  test(
    'connection rejects a present blocking entity at canonical contact',
    () async {
      final fixture = await _fixture(blockingEntity: true);
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );

      await _move(fixture.game, RuntimeInputControl.right);

      _expectRejected(fixture.game, 'Connection blocked');
    },
  );

  test('connection accepts a through entity at the arrival', () async {
    final fixture = await _fixture(blockingEntity: false);
    expect(
      fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
      isFalse,
    );

    await _move(fixture.game, RuntimeInputControl.right);

    _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
  });

  test(
    'connection preserves the walking restriction on an authored water cell',
    () async {
      final fixture = await _fixture(water: true);
      await _move(fixture.game, RuntimeInputControl.right);
      _expectRejected(fixture.game, 'Connection blocked');
    },
  );

  test('connection accepts an authored water cell while surfing', () async {
    final fixture = await _fixture(water: true);
    fixture.game.setPlayerMovementMode(MovementMode.surf);
    await _move(fixture.game, RuntimeInputControl.right);
    _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
    expect(
      fixture.game.gameStateSnapshot.playerMovementMode,
      MovementMode.surf,
    );
  });

  test(
    'connection keeps the authored offset and accepts its in-bounds arrival',
    () async {
      final fixture = await _fixture(offset: 1);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectArrived(fixture.game, const GridPos(x: 0, y: 0));
    },
  );

  test(
    'connection refuses an out-of-bounds offset before changing the map',
    () async {
      final fixture = await _fixture(offset: 4);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectRejected(fixture.game, 'Connection invalid');
    },
  );

  test(
    'free reciprocal connection returns through the actual input path',
    () async {
      final fixture = await _fixture();

      await _move(fixture.game, RuntimeInputControl.right);
      _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
      await _move(fixture.game, RuntimeInputControl.left);

      expect(fixture.game.gameStateSnapshot.currentMapId, 'source');
      expect(
        fixture.game.gameStateSnapshot.playerPosition,
        const GridPos(x: 1, y: 1),
      );
      expect(fixture.game.gameStateSnapshot.playerFacing, EntityFacing.west);
      expect(
        fixture.game.debugRenderedPlayerFootCell,
        const GridPos(x: 1, y: 1),
      );
      expect(fixture.game.debugCompletedMapActivationDispatchCount, 3);
      expect(
        fixture.game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection,
      );
      expect(fixture.game.debugLastCompletedMapActivation?.mapId, 'source');
      expect(fixture.game.debugFlowPhaseName, 'overworld');
      expect(fixture.game.debugHasPendingMapTransition, isFalse);
      expect(fixture.game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );

  for (final facing in EntityFacing.values) {
    test(
      'scene warp applies the authored ${facing.name} arrival facing',
      () async {
        final fixture = await _fixture(
          warpArrival: true,
          sourceFacing: facing == EntityFacing.east
              ? EntityFacing.west
              : EntityFacing.east,
        );

        final result = await _warp(
          fixture.game,
          SceneInteractiveCommand.warp(
            destinationMapId: 'target',
            warpId: 'arrival',
            arrivalFacing: facing,
            transition: SceneWarpTransition.none,
          ),
        );

        expect(result.port, 'completed');
        _expectArrived(
          fixture.game,
          const GridPos(x: 0, y: 1),
          facing: facing,
          reason: MapActivationReason.warp,
        );
      },
    );
  }

  test('scene warp preserves facing when arrival facing is omitted', () async {
    final fixture = await _fixture(
      warpArrival: true,
      sourceFacing: EntityFacing.west,
    );

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      facing: EntityFacing.west,
      reason: MapActivationReason.warp,
    );
  });

  test('scene warp none never mounts a visual transition overlay', () async {
    final fixture = await _fixture(warpArrival: true);

    final result = await _warp(
      fixture.game,
      _arrivalCommand(transition: SceneWarpTransition.none),
    );

    expect(result.port, 'completed');
    expect(result.sawTransitionOverlay, isFalse);
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
  });

  test('a rejected same-map warp cannot report completed from unchanged state', () async {
    final fixture = await _fixture(warpArrival: true, sameMapArrival: true);
    final game = fixture.game;
    var finished = false;
    final active = game.debugExecuteSceneInteractiveCommand(_arrivalCommand())
        .whenComplete(() => finished = true);
    for (var tick = 0; tick < 40 && game.debugFlowPhaseName != 'mapTransition'; tick++) {
      game.update(0);
      await Future<void>.delayed(Duration.zero);
    }
    expect(game.debugFlowPhaseName, 'mapTransition');
    expect(game.gameStateSnapshot.currentMapId, 'source');
    final rejected = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.warp(destinationMapId: 'source', warpId: 'same',
        transition: SceneWarpTransition.none),
    );
    for (var tick = 0; tick < 300 && !finished; tick++) {
      game.update(.016);
      await Future<void>.delayed(Duration.zero);
    }
    expect(await active, 'completed');
    expect(rejected, 'blocked');
  });

  test('scene warp map default mounts its indoor fade overlay', () async {
    final fixture = await _fixture(warpArrival: true);

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    expect(result.sawTransitionOverlay, isTrue);
    expect(
      fixture.game.camera.viewport.children
          .whereType<WarpTransitionOverlayComponent>(),
      isEmpty,
    );
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
  });

  test(
    'scene warp rejects feet collision when the cell centre is free',
    () async {
      final fixture = await _fixture(warpArrival: true, maskPixel: (16, 24));
      expect(
        fixture.targetWorld.isCellCenterBlockedLegacyForGridIndexedSystems(
          0,
          1,
        ),
        isFalse,
      );
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );
      final before = fixture.game.gameStateSnapshot;

      final result = await _warp(
        fixture.game,
        _arrivalCommand(arrivalFacing: EntityFacing.north),
      );

      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test(
    'scene warp accepts free feet when the cell centre touches a mask',
    () async {
      final fixture = await _fixture(warpArrival: true, maskPixel: (16, 16));
      expect(
        fixture.targetWorld.isCellCenterBlockedLegacyForGridIndexedSystems(
          0,
          1,
        ),
        isTrue,
      );
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isFalse,
      );

      final result = await _warp(fixture.game, _arrivalCommand());

      expect(result.port, 'completed');
      _expectArrived(
        fixture.game,
        const GridPos(x: 0, y: 1),
        reason: MapActivationReason.warp,
      );
    },
  );

  test(
    'scene warp rolls back an active blocking entity without changing facing',
    () async {
      final fixture = await _fixture(warpArrival: true, blockingEntity: true);
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );
      final before = fixture.game.gameStateSnapshot;

      final result = await _warp(
        fixture.game,
        _arrivalCommand(arrivalFacing: EntityFacing.west),
      );

      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test('scene warp accepts a through entity at the arrival', () async {
    final fixture = await _fixture(warpArrival: true, blockingEntity: false);
    expect(
      fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
      isFalse,
    );

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
  });

  test(
    'scene warp preserves the walking restriction on an authored water cell',
    () async {
      final fixture = await _fixture(warpArrival: true, water: true);
      final before = fixture.game.gameStateSnapshot;

      final result = await _warp(
        fixture.game,
        _arrivalCommand(arrivalFacing: EntityFacing.south),
      );

      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test('scene warp accepts an authored water cell while surfing', () async {
    final fixture = await _fixture(warpArrival: true, water: true);
    fixture.game.setPlayerMovementMode(MovementMode.surf);

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
    expect(
      fixture.game.gameStateSnapshot.playerMovementMode,
      MovementMode.surf,
    );
  });

  test(
    'scene warp arrival and facing survive a serialized save and reload',
    () async {
      final repository = _MemorySaveRepository();
      final fixture = await _fixture(
        warpArrival: true,
        saveRepository: repository,
      );
      final game = fixture.game;
      game.setPlayerMovementMode(MovementMode.surf);

      final result = await _warp(
        game,
        _arrivalCommand(
          arrivalFacing: EntityFacing.north,
          transition: SceneWarpTransition.none,
        ),
      );
      expect(result.port, 'completed');
      expect(await game.saveGame(), isTrue);
      await _move(game, RuntimeInputControl.right);
      game.setPlayerMovementMode(MovementMode.walk);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);

      expect(await game.loadGame(), isTrue);

      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
      expect(game.gameStateSnapshot.playerMovementMode, MovementMode.surf);
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 1));
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugExpectedPlayerWorldTopLeft,
      );
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );
}

void _expectRejected(PlayableMapGame game, String notification) {
  expect(game.gameStateSnapshot.currentMapId, 'source');
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
  expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);
  expect(game.debugNotificationText, notification);
  expect(game.debugCompletedMapActivationDispatchCount, 1);
  expect(
    game.debugLastCompletedMapActivation?.reason,
    MapActivationReason.initialBoot,
  );
  expect(game.debugLastCompletedMapActivation?.mapId, 'source');
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.debugHasPendingMapTransition, isFalse);
  expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
}

void _expectArrived(
  PlayableMapGame game,
  GridPos arrival, {
  EntityFacing facing = EntityFacing.east,
  MapActivationReason reason = MapActivationReason.connection,
}) {
  expect(game.gameStateSnapshot.currentMapId, 'target');
  expect(game.gameStateSnapshot.playerPosition, arrival);
  expect(game.gameStateSnapshot.playerFacing, facing);
  expect(_components(game).whereType<PlayerComponent>().single.cinematicFacing, facing);
  expect(game.debugRenderedPlayerFootCell, arrival);
  expect(game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
  expect(game.debugCompletedMapActivationDispatchCount, 2);
  expect(game.debugLastCompletedMapActivation?.reason, reason);
  expect(game.debugLastCompletedMapActivation?.mapId, 'target');
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.debugHasPendingMapTransition, isFalse);
  expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
}

SceneInteractiveCommand _arrivalCommand({
  EntityFacing? arrivalFacing,
  SceneWarpTransition transition = SceneWarpTransition.mapDefault,
}) => SceneInteractiveCommand.warp(
  destinationMapId: 'target',
  warpId: 'arrival',
  arrivalFacing: arrivalFacing,
  transition: transition,
);

Iterable<Component> _components(Component parent) sync* {
  yield parent;
  for (final child in parent.children) {
    yield* _components(child);
  }
}

Future<({String port, bool sawTransitionOverlay})> _warp(
  PlayableMapGame game,
  SceneInteractiveCommand command,
) async {
  var completed = false;
  var sawTransitionOverlay = false;
  final execution = game
      .debugExecuteSceneInteractiveCommand(command)
      .whenComplete(() => completed = true);
  for (var tick = 0; tick < 240; tick++) {
    game.update(.016);
    sawTransitionOverlay |= game.camera.viewport.children
        .whereType<WarpTransitionOverlayComponent>()
        .isNotEmpty;
    await Future<void>.delayed(Duration.zero);
    if (completed &&
        !game.debugHasPendingMapTransition &&
        !game.debugIsMapActivationDispatchInFlight &&
        game.debugFlowPhaseName == 'overworld') {
      game.update(0);
      return (
        port: await execution,
        sawTransitionOverlay: sawTransitionOverlay,
      );
    }
  }
  fail('Scene warp command did not settle.');
}

Future<void> _move(PlayableMapGame game, RuntimeInputControl control) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  for (var tick = 0; tick < 240; tick++) {
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping &&
        !game.debugHasPendingMapTransition &&
        !game.debugIsMapActivationDispatchInFlight &&
        game.debugFlowPhaseName == 'overworld') {
      return;
    }
  }
  fail('Connection input did not settle.');
}

Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({
  (int, int)? maskPixel,
  bool? blockingEntity,
  int offset = 0,
  bool water = false,
  bool warpArrival = false,
  bool sameMapArrival = false,
  EntityFacing sourceFacing = EntityFacing.east,
  GameSaveRepository? saveRepository,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'runtime_connection_canonical_arrival_',
  );
  addTearDown(() => root.delete(recursive: true));
  final source = MapData(
    id: 'source',
    name: 'Source',
    size: const GridSize(width: 2, height: 3),
    layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
      MapEntity(
        id: 'start',
        name: 'Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: sourceFacing,
        ),
      ),
    ],
    connections: [
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'target',
        offset: offset,
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'start'),
    warps: [
      if (sameMapArrival)
        const MapWarp(id: 'same', pos: GridPos(x: 1, y: 1),
          targetMapId: 'source', targetPos: GridPos(x: 1, y: 1),
          triggerMode: MapWarpTriggerMode.onBump),
    ],
  );
  final target = MapData(
    id: 'target',
    name: 'Target',
    size: const GridSize(width: 3, height: 3),
    layers: [
      TileLayer(id: 'objects', name: 'Objects', cells: List<int>.filled(9, 0)),
    ],
    entities: [
      const MapEntity(
        id: 'target_start',
        name: 'Target start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      if (blockingEntity != null)
        MapEntity(
          id: 'arrival_entity',
          name: 'Arrival entity',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 0, y: 1),
          blocksMovement: blockingEntity,
          properties: const {
            mapEntityCollisionWidthProperty: '1',
            mapEntityCollisionHeightProperty: '1',
          },
        ),
    ],
    placedElements: [
      if (maskPixel != null)
        const MapPlacedElement(
          id: 'mask',
          elementId: 'original_mask',
          layerId: 'objects',
          pos: GridPos(x: 0, y: 1),
          applyCollision: true,
        ),
    ],
    connections: [
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'source',
        offset: -offset,
      ),
    ],
    gameplayZones: [
      if (water)
        const MapGameplayZone(
          id: 'water',
          name: 'Water',
          kind: GameplayZoneKind.movement,
          area: MapRect(
            pos: GridPos(x: 0, y: 1),
            size: GridSize(width: 1, height: 1),
          ),
          movement: MovementZonePayload(requiredMode: MovementMode.surf),
        ),
    ],
    warps: [
      if (warpArrival)
        const MapWarp(
          id: 'arrival',
          pos: GridPos(x: 0, y: 1),
          targetMapId: 'source',
          targetPos: GridPos(x: 1, y: 1),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'target_start',
      isIndoor: warpArrival,
    ),
  );
  final pixels = List<bool>.filled(32 * 32, false);
  if (maskPixel != null) pixels[maskPixel.$2 * 32 + maskPixel.$1] = true;
  final manifest = ProjectManifest(
    name: 'Canonical connection arrival fixture',
    maps: [
      for (final map in [source, target])
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'original',
        name: 'Original',
        relativePath: 'assets/original.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'original', name: 'Original'),
    ],
    elements: [
      ProjectElementEntry(
        id: 'original_mask',
        name: 'Original mask',
        tilesetId: 'original',
        categoryId: 'original',
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
        collisionProfile: ElementCollisionProfile(
          collisionMask: ElementCollisionPixelMask(
            widthPx: 32,
            heightPx: 32,
            dataBase64: ElementCollisionMaskCodec.encodePackedBits(
              widthPx: 32,
              heightPx: 32,
              solidPixels: pixels,
            ),
          ),
        ),
      ),
    ],
  );
  ProjectValidator.validate(manifest, maps: [source, target]);
  for (final map in [source, target]) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  await Directory(p.join(root.path, 'maps')).create();
  await Directory(p.join(root.path, 'assets')).create();
  for (final map in [source, target]) {
    await File(p.join(root.path, 'maps', '${map.id}.json'))
        .writeAsString(jsonEncode(map.toJson()));
  }
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 32);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(p.join(root.path, 'assets', 'original.png'))
      .writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  final projectPath = p.join(root.path, 'project.json');
  await File(projectPath).writeAsString(jsonEncode(manifest.toJson()));
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectPath,
    mapId: 'source',
  );
  final game = _ConnectionGame(
    bundle: bundle,
    projectFilePath: projectPath,
    saveRepository: saveRepository,
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  for (var tick = 0; tick < 240; tick++) {
    if (!game.debugIsMapActivationDispatchInFlight) break;
    await Future<void>.delayed(Duration.zero);
  }
  expect(game.debugIsMapActivationDispatchInFlight, isFalse);
  expect(game.gameStateSnapshot.currentMapId, 'source');
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
  return (
    game: game,
    targetWorld: GameplayWorldState.initial(
      map: target,
      project: manifest,
      playerPos: const GridPos(x: 0, y: 1),
      tileWidth: 32,
      tileHeight: 32,
    ),
  );
}

final class _ConnectionGame extends PlayableMapGame {
  _ConnectionGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

final class _MemorySaveRepository implements GameSaveRepository {
  Map<String, dynamic>? _savedJson;

  @override
  Future<void> save(GameState state) async => _savedJson = state.toJson();

  @override
  Future<GameState?> load() async =>
      _savedJson == null ? null : GameState.fromJson(_savedJson!);

  @override
  Future<bool> exists() async => _savedJson != null;

  @override
  Future<void> delete() async => _savedJson = null;
}
