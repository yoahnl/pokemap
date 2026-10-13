import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
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

void _expectArrived(PlayableMapGame game, GridPos arrival) {
  expect(game.gameStateSnapshot.currentMapId, 'target');
  expect(game.gameStateSnapshot.playerPosition, arrival);
  expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);
  expect(game.debugRenderedPlayerFootCell, arrival);
  expect(game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
  expect(game.debugCompletedMapActivationDispatchCount, 2);
  expect(
    game.debugLastCompletedMapActivation?.reason,
    MapActivationReason.connection,
  );
  expect(game.debugLastCompletedMapActivation?.mapId, 'target');
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.debugHasPendingMapTransition, isFalse);
  expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
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
    entities: const [
      MapEntity(
        id: 'start',
        name: 'Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
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
    mapMetadata: const MapMetadata(defaultSpawnId: 'target_start'),
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
  final game = _ConnectionGame(bundle: bundle, projectFilePath: projectPath);
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
  _ConnectionGame({required super.bundle, required super.projectFilePath});

  @override
  bool get isLoaded => true;
}
