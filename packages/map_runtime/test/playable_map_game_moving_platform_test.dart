import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

import '../../map_gameplay/test/support/moving_platform_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (motion, blocked) in [
    (MovingPlatformMotion.forward, false),
    (MovingPlatformMotion.rotateClockwise, false),
    (MovingPlatformMotion.forward, true),
  ]) {
    testWidgets('walking activates ${motion.name}, blocked=$blocked, without carry or reload loops', (tester) async {
      await tester.runAsync(() async {
        final fixture = MovingPlatformFixture();
        final definition = MovingPlatformDefinition.fromJson({
          ...fixture.definition.toJson(),
          'controls': [{'id': 'button', 'cell': {'x': 0, 'y': 0}, 'motion': motion.name}],
        });
        final map = fixture.map.copyWith(
          movingPlatforms: [definition],
          layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
          entities: [
            if (blocked) const MapEntity(id: 'wall', kind: MapEntityKind.npc,
              pos: GridPos(x: 3, y: 2), npc: MapEntityNpcData()),
          ],
        );
        final repository = _MemorySave(null);
        final bundle = _bundle(fixture, _scene()).copyWith(map: map);
        final game = await _game(tester, bundle, GameState(saveId: 'automatic',
          currentMapId: 'gym', playerPosition: const GridPos(x: 1, y: 2),
          movingPlatformWorldState: fixture.state), repository: repository);
        expect(game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.right)), isTrue);
        game.update(0);
        expect(game.debugIsPlayerStepping, isTrue);
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(game.gameStateSnapshot.movingPlatformWorldState, fixture.state);
        game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.right));
        game.update(1);
        expect(await game.saveGame(), isFalse);
        for (var tick = 0; tick < 1000 && !game.inputAuthoritySnapshot.acceptsOverworldInput; tick++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
        final pose = game.gameStateSnapshot.movingPlatformWorldState.platform('gym', 'bridge')!;
        expect(pose.leftPx, !blocked && motion == MovingPlatformMotion.forward ? 96 : 64);
        expect(pose.quarterTurns, motion == MovingPlatformMotion.rotateClockwise ? 1 : 0);
        expect(await game.saveGame(), isTrue);
        final saved = repository.state!;
        game.update(1);
        expect(game.gameStateSnapshot.movingPlatformWorldState, saved.movingPlatformWorldState);
        expect(await game.loadGame(), isTrue);
        game.update(1);
        expect(game.gameStateSnapshot.movingPlatformWorldState, saved.movingPlatformWorldState);
        expect(game.gameStateSnapshot.playerPixelPosition, saved.playerPixelPosition);
        final restored = await _game(tester, bundle,
          gameStateFromStrictSaveJson(strictGameStateSaveJson(saved)));
        restored.update(1);
        expect(restored.gameStateSnapshot.movingPlatformWorldState, saved.movingPlatformWorldState);
        expect(restored.gameStateSnapshot.playerPixelPosition, saved.playerPixelPosition);
      });
    });
  }

  testWidgets(
    'save restore composes moved boulders before validating moved platforms',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = MovingPlatformFixture();
        final authored = fixture.map.copyWith(
          layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
          entities: const [
            MapEntity(
              id: 'rock',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 4, y: 2),
              fieldObstacle: MapEntityFieldObstacleData(
                kind: FieldObstacleKind.strengthBoulder,
              ),
            ),
          ],
        );
        final platforms = fixture.state.withPlatform(
          mapId: 'gym',
          platformId: 'bridge',
          pose: MovingPlatformPose(leftPx: 128, topPx: 64, quarterTurns: 0),
        );
        final instances = MapInstanceWorldState(
          instancesByMapId: {
            'gym': MapInstanceRuntimeState(
              instanceId: 'gym-1',
              strengthActive: true,
              fieldObstaclePositions: const {'rock': GridPos(x: 3, y: 2)},
            ),
          },
        );
        final state = GameState(
          saveId: 'composed',
          currentMapId: 'gym',
          playerPosition: const GridPos(x: 5, y: 2),
          movingPlatformWorldState: platforms,
          mapInstanceWorldState: instances,
        );
        final repository = _MemorySave(GameState.fromJson(state.toJson()));
        final game = await _game(
          tester,
          _bundle(fixture, _scene()).copyWith(map: authored),
          state,
          repository: repository,
        );
        expect(game.debugMapEntityPosition('rock'), const GridPos(x: 3, y: 2));
        expect(game.gameStateSnapshot.movingPlatformWorldState, platforms);
        expect(await game.saveGame(), isTrue);
        expect(await game.loadGame(), isTrue);
        expect(game.debugMapEntityPosition('rock'), const GridPos(x: 3, y: 2));
        expect(game.gameStateSnapshot.movingPlatformWorldState, platforms);
        final fresh = await _game(
          tester,
          _bundle(fixture, _scene()).copyWith(map: authored),
          GameState.fromJson(repository.state!.toJson()),
        );
        expect(fresh.debugMapEntityPosition('rock'), const GridPos(x: 3, y: 2));
        expect(authored.entities.single.pos, const GridPos(x: 4, y: 2));
      });
    },
  );

  for (final (smartTerrain, preciseTerrain) in [(false, false), (true, false), (true, true)]) {
  testWidgets(
    '${preciseTerrain ? 'Precise terrain' : smartTerrain ? 'Smart Tile' : 'Tile'} mounted Player carries the rider, rotates and restores exact saved pixels',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = MovingPlatformFixture(smartTerrain: smartTerrain, preciseTerrain: preciseTerrain);
        final bundle = _bundle(fixture, _scene());
        final diagnostics = diagnoseSceneAgainstProject(
          bundle.manifest.scenes.first,
          bundle.manifest,
          mapsById: {'gym': bundle.map},
        );
        expect(
          diagnostics.hasErrors,
          isFalse,
          reason: diagnostics.diagnostics
              .map((d) => '${d.code}: ${d.message}')
              .join('\n'),
        );
        final state = GameState(
          saveId: 'moving',
          currentMapId: 'gym',
          playerPosition: const GridPos(x: 2, y: 2),
          movingPlatformWorldState: fixture.state,
        );
        final game = await _game(tester, bundle, state);
        final start = game.debugPlayerWorldTopLeft;
        final player = fixture.world().player;
        expect(
          game.gameStateSnapshot.playerPixelPosition,
          PixelOffset(
            x: player.playerPositionPx.leftPx,
            y: player.playerPositionPx.topPx,
          ),
        );

        final result = await game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'platform-event',
            sceneId: 'move',
            executionId: 'run',
            gameState: game.gameStateSnapshot,
          ),
        );
        expect(
          result,
          isA<NarrativeSceneExecutionCompleted>(),
          reason: result is NarrativeSceneExecutionFailed
              ? result.failure.toString()
              : null,
        );
        final saved =
            (result as NarrativeSceneExecutionCompleted).updatedGameState;
        expect(
          saved.movingPlatformWorldState.platform('gym', 'bridge')!.leftPx,
          96,
        );
        expect(saved.playerPosition, const GridPos(x: 3, y: 2));
        expect(
          game.debugPlayerWorldTopLeft.x,
          start.x + 32 * bundle.manifest.settings.displayScale,
        );
        final restored = await _game(
          tester,
          bundle,
          gameStateFromStrictSaveJson(strictGameStateSaveJson(saved)),
        );
        expect(restored.debugPlayerWorldTopLeft, game.debugPlayerWorldTopLeft);
        expect(
          restored.gameStateSnapshot.movingPlatformWorldState,
          saved.movingPlatformWorldState,
        );
        final rotation = await restored.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'rotate-event',
            sceneId: 'rotate',
            executionId: 'rotate-run',
            gameState: restored.gameStateSnapshot,
          ),
        );
        expect(
          rotation,
          isA<NarrativeSceneExecutionCompleted>(),
          reason: rotation is NarrativeSceneExecutionFailed
              ? rotation.failure.toString()
              : null,
        );
        expect(
          (rotation as NarrativeSceneExecutionCompleted)
              .updatedGameState
              .movingPlatformWorldState
              .platform('gym', 'bridge')!
              .quarterTurns,
          1,
        );
        expect(restored.debugPlayerWorldTopLeft, game.debugPlayerWorldTopLeft);
      });
    },
  );

  }

  testWidgets(
    'a later Scene failure rolls platform visuals and rider back together',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = MovingPlatformFixture();
        final bundle = _bundle(fixture, _scene(failAfterMove: true));
        final game = await _game(
          tester,
          bundle,
          GameState(
            saveId: 'rollback',
            currentMapId: 'gym',
            playerPosition: const GridPos(x: 2, y: 2),
            movingPlatformWorldState: fixture.state,
          ),
        );
        final before = game.gameStateSnapshot;
        final position = game.debugPlayerWorldTopLeft;
        final result = await game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'platform-event',
            sceneId: 'move',
            executionId: 'rollback-run',
            gameState: before,
          ),
        );
        expect(result, isA<NarrativeSceneExecutionFailed>());
        expect(
          (result as NarrativeSceneExecutionFailed).failure.toString(),
          contains('takeItem'),
        );
        expect(
          game.gameStateSnapshot.movingPlatformWorldState,
          before.movingPlatformWorldState,
        );
        expect(game.debugPlayerWorldTopLeft, position);
      });
    },
  );

  testWidgets(
    'invalid restored platform preserves the mounted session and save',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = MovingPlatformFixture();
        final bundle = _bundle(fixture, _scene());
        final state = GameState(
          saveId: 'valid',
          currentMapId: 'gym',
          playerPosition: const GridPos(x: 2, y: 2),
          movingPlatformWorldState: fixture.state,
        );
        final invalid = state.copyWith(
          movingPlatformWorldState: fixture.state.withPlatform(
            mapId: 'gym',
            platformId: 'bridge',
            pose: MovingPlatformPose(
              leftPx: 10000,
              topPx: 10000,
              quarterTurns: 0,
            ),
          ),
        );
        final repository = _MemorySave(invalid);
        final game = await _game(tester, bundle, state, repository: repository);
        final before = game.gameStateSnapshot;
        final position = game.debugPlayerWorldTopLeft;
        expect(await game.loadGame(), isFalse);
        expect(repository.loadCount, 1);
        expect(game.gameStateSnapshot, before);
        expect(game.debugPlayerWorldTopLeft, position);
        expect(repository.state, invalid);
      });
    },
  );

  test(
    'saved inconsistent pixel position is rejected before playability',
    () async {
      final fixture = MovingPlatformFixture();
      final bundle = _bundle(fixture, _scene());
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: '/tmp/platform-test/project.json',
        initialGameState: GameState(
          saveId: 'invalid',
          currentMapId: 'gym',
          playerPosition: const GridPos(x: 2, y: 2),
          playerPixelPosition: const PixelOffset(x: 200, y: 200),
          movingPlatformWorldState: fixture.state,
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        runtimeTilesetImageLoader: _images,
      );
      game.onGameResize(Vector2(320, 240));
      addTearDown(game.onRemove);
      await expectLater(game.onLoad(), throwsStateError);
    },
  );
}

Future<PlayableMapGame> _game(
  WidgetTester tester,
  RuntimeMapBundle bundle,
  GameState state, {
  GameSaveRepository? repository,
}) async {
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/platform-test/project.json',
    initialGameState: state,
    saveRepository: repository,
    initialMapActivationReason: MapActivationReason.saveRestore,
    runtimeTilesetImageLoader: _images,
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle,
  );
  game.onGameResize(Vector2(320, 240));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  addTearDown(game.onRemove);
  await game.loaded;
  await tester.pump();
  for (var i = 0; i < 1000 && game.debugIsMapActivationDispatchInFlight; i++) {
    game.update(0);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  expect(game.debugIsMapActivationDispatchInFlight, isFalse);
  return game;
}

Future<Map<String, RuntimeTilesetImage>> _images(
  Map<String, String> paths, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
}) async {
  final picture = ui.PictureRecorder();
  ui.Canvas(picture).drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xff8ac98a),
  );
  final image = await picture.endRecording().toImage(32, 64);
  return {
    'tiles': RuntimeTilesetImage(
      images: [image],
      chunks: [const RuntimeTilesetChunk(top: 0, height: 64, width: 32)],
      width: 32,
      height: 64,
    ),
  };
}

RuntimeMapBundle _bundle(MovingPlatformFixture fixture, SceneAsset scene) =>
    RuntimeMapBundle(
      projectRootDirectory: '/tmp/platform-test',
      tilesetAbsolutePathsById: const {'tiles': '/tmp/platform-test/tiles.png'},
      map: fixture.map,
      manifest: fixture.project.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: const [],
          legacyClaims: const [],
        ),
        maps: const [
          ProjectMapEntry(
            id: 'gym',
            name: 'Gym',
            relativePath: 'maps/gym.json',
          ),
        ],
        scenes: [
          scene,
          _scene(id: 'rotate', motion: MovingPlatformMotion.rotateClockwise),
        ],
      ),
    );

SceneAsset _scene({
  String id = 'move',
  MovingPlatformMotion motion = MovingPlatformMotion.forward,
  bool failAfterMove = false,
}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'platform',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.movePlatform(
            mapId: 'gym',
            platformId: 'bridge',
            motion: motion,
          ),
        ),
      ),
      if (failAfterMove)
        SceneNode(
          id: 'failure',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.takeItem(itemId: 'absent-item', quantity: 1),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        kind: SceneEdgeKind.defaultFlow,
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'platform',
      ),
      for (final port in const [
        'moved',
        'blocked',
        'notRiding',
        'rotationRequiresPivot',
      ])
        SceneEdge(
          kind: SceneEdgeKind.defaultFlow,
          id: port,
          fromNodeId: 'platform',
          fromPortId: port,
          toNodeId: failAfterMove && port == 'moved' ? 'failure' : 'end',
        ),
      if (failAfterMove)
        for (final port in const ['completed'])
          SceneEdge(
            kind: SceneEdgeKind.defaultFlow,
            id: 'failure-$port',
            fromNodeId: 'failure',
            fromPortId: port,
            toNodeId: 'end',
          ),
    ],
  ),
);

final class _MemorySave implements GameSaveRepository {
  _MemorySave(this.state);
  GameState? state;
  int loadCount = 0;
  @override
  Future<void> save(GameState value) async {
    state = value;
  }

  @override
  Future<GameState?> load() async {
    loadCount++;
    return state;
  }

  @override
  Future<bool> exists() async => state != null;
  @override
  Future<void> delete() async {
    state = null;
  }
}
