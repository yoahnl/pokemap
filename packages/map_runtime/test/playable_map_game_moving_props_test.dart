import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import '../../map_gameplay/test/support/moving_platform_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (blocksAfterFact, failAfterMove) in [
    (false, false),
    (true, false),
    (false, true),
  ]) {
    testWidgets(
      'a pending Scene fact refreshes prop path collision to blocking=$blocksAfterFact, rollback=$failAfterMove',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = _Fixture();
          final condition = NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('changed', true),
          );
          final base = fixture.bundle();
          final map = base.map.copyWith(
            entities: [
              MapEntity(
                id: 'conditional-wall',
                kind: MapEntityKind.custom,
                pos: const GridPos(x: 3, y: 2),
                presentation: MapEntityPresentation(
                  variants: [
                    MapEntityPresentationVariant(
                      id: 'changed',
                      condition: condition,
                      blocksMovement: blocksAfterFact,
                    ),
                    MapEntityPresentationVariant(
                      id: 'initial',
                      condition: NarrativeEventConditionExpression.not(
                        condition,
                      ),
                      blocksMovement: !blocksAfterFact,
                    ),
                  ],
                ),
              ),
            ],
          );
          final scene = _scene(failAfterMove: failAfterMove);
          final graph = scene.graph;
          final changedScene = SceneAsset(
            id: scene.id,
            name: scene.name,
            graph: SceneGraph(
              startNodeId: graph.startNodeId,
              nodes: [
                ...graph.nodes,
                SceneNode(
                  id: 'change',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.consequence(
                    SceneConsequence.setFact(factId: 'changed', value: true),
                  ),
                ),
              ],
              edges: [
                for (final edge in graph.edges)
                  if (edge.id != 'start') edge,
                SceneEdge(
                  id: 'start-change',
                  kind: SceneEdgeKind.defaultFlow,
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'change',
                ),
                SceneEdge(
                  id: 'change-move',
                  kind: SceneEdgeKind.defaultFlow,
                  fromNodeId: 'change',
                  fromPortId: 'completed',
                  toNodeId: 'props',
                ),
              ],
            ),
          );
          final bundle = base.copyWith(
            map: map,
            manifest: base.manifest.copyWith(
              facts: [NarrativeFactDefinition(id: 'changed', label: 'Changed')],
              scenes: [changedScene],
            ),
          );
          final game = await _game(tester, bundle, fixture.state);
          final result = await _execute(game);
          if (failAfterMove) {
            expect(result, isA<NarrativeSceneExecutionFailed>());
            expect(
              game.debugMovingPropPosition('gate-a'),
              const PixelOffset(x: 64, y: 64),
            );
            expect(
              game.gameStateSnapshot.movingPropWorldState,
              fixture.state.movingPropWorldState,
            );
            expect(
              game.debugMovingPropsCollide(
                const PixelRect(
                  leftPx: 96,
                  topPx: 64,
                  widthPx: 32,
                  heightPx: 32,
                ),
              ),
              isTrue,
            );
            return;
          }
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          expect(
            game.debugMovingPropPosition('gate-a'),
            PixelOffset(x: blocksAfterFact ? 64 : 128, y: 64),
          );
          final settled =
              (result as NarrativeSceneExecutionCompleted).updatedGameState;
          expect(
            settled.movingPropWorldState.prop('gym', 'gate-a'),
            blocksAfterFact ? MovingPropState.closed : MovingPropState.open,
          );
        });
      },
    );
  }

  testWidgets(
    'autonomous props move together without carrying the player and survive reload',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = _Fixture();
        final repository = _MemorySave();
        final game = await _game(
          tester,
          fixture.bundle(productionEvent: true),
          fixture.state,
          repository: repository,
        );
        final player = game.debugPlayerWorldTopLeft;
        final execution = _executeProduction(game);
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(
          game.gameStateSnapshot.movingPropWorldState,
          fixture.state.movingPropWorldState,
        );
        final first = game.debugMovingPropPosition('gate-a')!;
        final second = game.debugMovingPropPosition('gate-b')!;
        expect(first.x, greaterThan(64));
        expect(first.x, lessThan(128));
        expect(first.x, second.x);
        expect(game.debugPlayerWorldTopLeft, player);
        final committed = await execution;
        expect(
          committed.movingPropWorldState.prop('gym', 'gate-a'),
          MovingPropState.open,
        );
        expect(
          game.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 128, y: 64),
        );
        expect(
          game.debugMovingPropPosition('gate-b'),
          const PixelOffset(x: 128, y: 128),
        );
        expect(
          game.debugMovingPropsCollide(
            const PixelRect(leftPx: 64, topPx: 64, widthPx: 32, heightPx: 32),
          ),
          isFalse,
        );
        expect(
          game.debugMovingPropsCollide(
            const PixelRect(leftPx: 128, topPx: 64, widthPx: 32, heightPx: 32),
          ),
          isTrue,
        );
        expect(await game.saveGame(), isTrue);
        final saved = gameStateFromStrictSaveJson(
          strictGameStateSaveJson(repository.state!),
        );
        expect(await game.loadGame(), isTrue);
        expect(
          game.gameStateSnapshot.movingPropWorldState,
          saved.movingPropWorldState,
        );
        expect(
          game.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 128, y: 64),
        );
        final fresh = await _game(tester, fixture.bundle(), saved);
        expect(
          fresh.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 128, y: 64),
        );
        expect(
          fresh.debugMovingPropsCollide(
            const PixelRect(leftPx: 128, topPx: 64, widthPx: 32, heightPx: 32),
          ),
          isTrue,
        );
      });
    },
  );

  testWidgets(
    'a blocked group returns every prop and leaves the durable state unchanged',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = _Fixture(blocked: true);
        final game = await _game(tester, fixture.bundle(), fixture.state);
        expect(await _execute(game), isA<NarrativeSceneExecutionCompleted>());
        expect(
          game.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 64, y: 64),
        );
        expect(
          game.debugMovingPropPosition('gate-b'),
          const PixelOffset(x: 64, y: 128),
        );
        expect(
          game.gameStateSnapshot.movingPropWorldState,
          fixture.state.movingPropWorldState,
        );
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      });
    },
  );

  testWidgets(
    'a later Scene failure rolls prop visuals and collision back atomically',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = _Fixture();
        final game = await _game(
          tester,
          fixture.bundle(failAfterMove: true),
          fixture.state,
        );
        expect(await _execute(game), isA<NarrativeSceneExecutionFailed>());
        expect(
          game.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 64, y: 64),
        );
        expect(
          game.debugMovingPropsCollide(
            const PixelRect(leftPx: 64, topPx: 64, widthPx: 32, heightPx: 32),
          ),
          isTrue,
        );
        expect(
          game.debugMovingPropsCollide(
            const PixelRect(leftPx: 128, topPx: 64, widthPx: 32, heightPx: 32),
          ),
          isFalse,
        );
        expect(
          game.gameStateSnapshot.movingPropWorldState,
          fixture.state.movingPropWorldState,
        );
      });
    },
  );

  testWidgets(
    'runtime removal interrupts the movement without committing a pose',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = _Fixture();
        final game = await _game(tester, fixture.bundle(), fixture.state);
        final execution = _execute(game);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        game.onRemove();
        expect(await execution, isA<NarrativeSceneExecutionFailed>());
        expect(
          game.gameStateSnapshot.movingPropWorldState,
          fixture.state.movingPropWorldState,
        );
      });
    },
  );

  testWidgets(
    'an invalid restored prop preserves the current session and save',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = _Fixture();
        final bundle = fixture.bundle().copyWith(
          map: fixture.map.copyWith(
            entities: const [
              MapEntity(
                id: 'wall',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 4, y: 2),
                npc: MapEntityNpcData(),
              ),
            ],
          ),
        );
        final invalid = fixture.state.copyWith(
          movingPropWorldState: fixture.state.movingPropWorldState.withProp(
            mapId: 'gym',
            propId: 'gate-a',
            state: MovingPropState.open,
          ),
        );
        final repository = _MemorySave()..state = invalid;
        final game = await _game(
          tester,
          bundle,
          fixture.state,
          repository: repository,
        );
        final before = game.gameStateSnapshot;
        expect(await game.loadGame(), isFalse);
        expect(game.gameStateSnapshot, before);
        expect(
          game.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 64, y: 64),
        );
        expect(repository.state, invalid);
      });
    },
  );

  testWidgets(
    'moving a rider platform preserves open prop visuals and collision',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = _Fixture(withPlatform: true);
        final game = await _game(
          tester,
          fixture.bundle(),
          fixture.state.copyWith(playerPosition: const GridPos(x: 4, y: 6)),
        );
        final props = await _execute(game) as NarrativeSceneExecutionCompleted;
        final platform = await game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'platform-event',
            sceneId: 'platform',
            executionId: 'platform-run',
            gameState: props.updatedGameState,
          ),
        );
        expect(platform, isA<NarrativeSceneExecutionCompleted>());
        final saved =
            (platform as NarrativeSceneExecutionCompleted).updatedGameState;
        expect(
          saved.movingPlatformWorldState.platform('gym', 'bridge')!.leftPx,
          160,
        );
        expect(
          saved.movingPropWorldState.prop('gym', 'gate-a'),
          MovingPropState.open,
        );
        expect(
          game.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 128, y: 64),
        );
        expect(
          game.debugMovingPropsCollide(
            const PixelRect(leftPx: 128, topPx: 64, widthPx: 32, heightPx: 32),
          ),
          isTrue,
        );
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.scale(1 / fixture.project.settings.displayScale);
        for (final layer
            in game.world.children.whereType<MapLayersComponent>()) {
          layer.setVisibleLocalRect(null);
          layer.render(canvas);
        }
        final image = await recorder.endRecording().toImage(320, 320);
        final pixels = await image.toByteData();
        expect(pixels!.getUint8((68 * 320 + 132) * 4 + 3), greaterThan(0));
        image.dispose();
        final fresh = await _game(
          tester,
          fixture.bundle(),
          gameStateFromStrictSaveJson(strictGameStateSaveJson(saved)),
        );
        expect(
          fresh.debugMovingPropPosition('gate-a'),
          const PixelOffset(x: 128, y: 64),
        );
        expect(
          fresh.gameStateSnapshot.movingPlatformWorldState,
          saved.movingPlatformWorldState,
        );
      });
    },
  );
}

Future<NarrativeSceneExecutionResult> _execute(PlayableMapGame game) =>
    game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'props-event',
        sceneId: 'props',
        executionId: 'props-run',
        gameState: game.gameStateSnapshot,
      ),
    );

Future<GameState> _executeProduction(PlayableMapGame game) async {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    ),
    isTrue,
  );
  for (
    var tick = 0;
    tick < 1000 && !game.debugIsNarrativeSpatialDispatchInFlight;
    tick++
  ) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
  for (
    var tick = 0;
    tick < 2000 && game.debugIsNarrativeSpatialDispatchInFlight;
    tick++
  ) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
  return game.debugReadNarrativeGameStateForTest();
}

final class _Fixture {
  _Fixture({bool blocked = false, bool withPlatform = false}) {
    final base = MovingPlatformFixture();
    map = base.map.copyWith(
      movingPlatforms: [
        if (withPlatform)
          MovingPlatformDefinition.fromJson({
            ...base.definition.toJson(),
            'initialPose': {'leftPx': 128, 'topPx': 192, 'quarterTurns': 0},
          }),
      ],
      layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
      movingProps: [
        for (final (id, y) in [('gate-a', 64), ('gate-b', 128)])
          MovingPropDefinition(
            id: id,
            placedElementId: '$id-art',
            closedPositionPx: PixelOffset(x: 64, y: y),
            openPositionPx: PixelOffset(x: 128, y: y),
            collisionRect: const PixelRect(
              leftPx: 0,
              topPx: 0,
              widthPx: 32,
              heightPx: 32,
            ),
          ),
      ],
      placedElements: [
        if (withPlatform)
          base.map.placedElements.single.copyWith(
            pos: const GridPos(x: 4, y: 6),
          ),
        for (final (id, y) in [('gate-a', 2), ('gate-b', 4)])
          MapPlacedElement(
            id: '$id-art',
            layerId: 'magma',
            elementId: 'platform-0',
            pos: GridPos(x: 2, y: y),
            applyCollision: false,
            properties: const {
              pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
            },
          ),
      ],
      entities: [
        if (blocked)
          const MapEntity(
            id: 'wall',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 4),
            npc: MapEntityNpcData(),
          ),
      ],
    );
    project = base.project.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
      maps: const [
        ProjectMapEntry(
          id: 'gym',
          name: 'Props',
          relativePath: 'maps/gym.json',
        ),
      ],
    );
    state = GameState(
      saveId: 'props',
      currentMapId: 'gym',
      playerPosition: const GridPos(x: 1, y: 1),
      movingPropWorldState: initializeMovingPropWorldState(
        map: map,
        worldState: const MovingPropWorldState.empty(),
      ),
      movingPlatformWorldState: initializeMovingPlatformWorldState(
        map: map,
        worldState: const MovingPlatformWorldState.empty(),
      ),
    );
  }

  late final MapData map;
  late final ProjectManifest project;
  late final GameState state;

  RuntimeMapBundle bundle({
    bool failAfterMove = false,
    bool productionEvent = false,
  }) => RuntimeMapBundle(
    projectRootDirectory: '/tmp/props-test',
    tilesetAbsolutePathsById: const {'tiles': '/tmp/props-test/tiles.png'},
    map: productionEvent
        ? map.copyWith(
            entities: [
              ...map.entities,
              const MapEntity(
                id: 'button',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 1, y: 2),
                npc: MapEntityNpcData(),
              ),
            ],
          )
        : map,
    manifest: project.copyWith(
      scenes: [
        _scene(failAfterMove: failAfterMove),
        if (map.movingPlatforms.isNotEmpty) _platformScene(),
      ],
      eventRegistry: productionEvent
          ? NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: [
                NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                    id: 'evt_019abcde-1000-7000-8000-000000000125',
                    name: 'Open props',
                    source: NarrativeEventSourceRef.entityInteract(
                      'gym',
                      'button',
                    ),
                    conditions: const [],
                    sceneId: 'props',
                    reusePolicy: NarrativeEventReusePolicy.reusable,
                    priority: 0,
                    order: 0,
                  ),
                  enabled: true,
                ),
              ],
              legacyClaims: const [],
            )
          : project.eventRegistry,
    ),
  );
}

SceneAsset _scene({bool failAfterMove = false}) => SceneAsset(
  id: 'props',
  name: 'Props',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'props',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.setPropState(
            mapId: 'gym',
            propIds: const ['gate-a', 'gate-b'],
            state: MovingPropState.open,
            durationMs: 100,
          ),
        ),
      ),
      if (failAfterMove)
        SceneNode(
          id: 'failure',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.takeItem(itemId: 'missing', quantity: 1),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        kind: SceneEdgeKind.defaultFlow,
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'props',
      ),
      for (final port in ['moved', 'blocked'])
        SceneEdge(
          id: port,
          kind: SceneEdgeKind.defaultFlow,
          fromNodeId: 'props',
          fromPortId: port,
          toNodeId: failAfterMove && port == 'moved' ? 'failure' : 'end',
        ),
      if (failAfterMove)
        SceneEdge(
          id: 'failure',
          kind: SceneEdgeKind.defaultFlow,
          fromNodeId: 'failure',
          fromPortId: 'completed',
          toNodeId: 'end',
        ),
    ],
  ),
);

SceneAsset _platformScene() => SceneAsset(
  id: 'platform',
  name: 'Platform',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'move',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.movePlatform(
            mapId: 'gym',
            platformId: 'bridge',
            motion: MovingPlatformMotion.forward,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        kind: SceneEdgeKind.defaultFlow,
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'move',
      ),
      for (final port in [
        'moved',
        'blocked',
        'notRiding',
        'rotationRequiresPivot',
      ])
        SceneEdge(
          id: port,
          kind: SceneEdgeKind.defaultFlow,
          fromNodeId: 'move',
          fromPortId: port,
          toNodeId: 'end',
        ),
    ],
  ),
);

Future<PlayableMapGame> _game(
  WidgetTester tester,
  RuntimeMapBundle bundle,
  GameState state, {
  GameSaveRepository? repository,
}) async {
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/props-test/project.json',
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
  for (
    var tick = 0;
    tick < 1000 && game.debugIsMapActivationDispatchInFlight;
    tick++
  ) {
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
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xff8ac98a),
  );
  final image = await recorder.endRecording().toImage(32, 64);
  return {
    'tiles': RuntimeTilesetImage(
      images: [image],
      chunks: [const RuntimeTilesetChunk(top: 0, height: 64, width: 32)],
      width: 32,
      height: 64,
    ),
  };
}

final class _MemorySave implements GameSaveRepository {
  GameState? state;
  @override
  Future<void> save(GameState value) async {
    state = value;
  }

  @override
  Future<GameState?> load() async => state;
  @override
  Future<bool> exists() async => state != null;
  @override
  Future<void> delete() async {
    state = null;
  }
}
