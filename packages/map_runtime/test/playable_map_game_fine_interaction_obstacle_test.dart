import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final eventV2 in [false, true]) {
    testWidgets(
      'a fine barrier blocks the public ${eventV2 ? 'EventV2' : 'native'} sign interaction through reload',
      (tester) async {
        await tester.runAsync(() async {
          final open = await _mount(tester, eventV2: eventV2);
          final allowed =
              open.overworldInteractionSnapshot.primaryAction!.request;
          expect(allowed.targetId, 'sign');
          final blocked = await _mount(tester, eventV2: eventV2, barrier: true);
          _expectFinePose(blocked);
          expect(blocked.overworldInteractionSnapshot.primaryAction, isNull);
          expect(
            blocked.dispatchOverworldInteraction(
              _currentRequest(blocked, allowed),
            ),
            isFalse,
          );
          expect(
            blocked
                .gameStateSnapshot
                .narrativeFactRuntimeState
                .overridesByFactId['read'],
            isNot(true),
          );
          expect(await blocked.saveGame(), isTrue);
          final cold = await _mount(
            tester,
            eventV2: eventV2,
            barrier: true,
            restored: gameStateFromStrictSaveJson(
              strictGameStateSaveJson(blocked.gameStateSnapshot),
            ),
          );
          _expectFinePose(cold);
          expect(cold.overworldInteractionSnapshot.primaryAction, isNull);
          expect(
            cold.dispatchOverworldInteraction(_currentRequest(cold, allowed)),
            isFalse,
          );

          final clear = await _mount(tester, eventV2: eventV2);
          _expectFinePose(clear);
          final request =
              clear.overworldInteractionSnapshot.primaryAction!.request;
          expect(clear.dispatchOverworldInteraction(request), isTrue);
          await helpers.tickUntil(
            clear,
            () => eventV2
                ? clear
                          .gameStateSnapshot
                          .narrativeFactRuntimeState
                          .overridesByFactId['read'] ==
                      true
                : clear.debugNotificationText != null,
          );
          await helpers.tickUntil(
            clear,
            () => clear.inputAuthoritySnapshot.acceptsOverworldInput,
          );
          expect(await clear.saveGame(), isTrue);
          final reopened = await _mount(
            tester,
            eventV2: eventV2,
            restored: gameStateFromStrictSaveJson(
              strictGameStateSaveJson(clear.gameStateSnapshot),
            ),
          );
          _expectFinePose(reopened);
          expect(
            reopened.overworldInteractionSnapshot.primaryAction,
            isNotNull,
          );
          if (eventV2) {
            expect(
              reopened
                  .gameStateSnapshot
                  .narrativeFactRuntimeState
                  .overridesByFactId['read'],
              isTrue,
            );
          }
        });
      },
    );
  }

  for (final dispatch in [false, true]) {
    testWidgets(
      'a fine barrier ${dispatch ? 'refuses dispatch to' : 'withdraws'} the real front map event',
      (tester) async {
        await tester.runAsync(() async {
          final clear = await _mount(tester, mapEvent: true);
          final template =
              clear.overworldInteractionSnapshot.primaryAction!.request;
          expect(
            template.targetKind,
            RuntimeOverworldInteractionTargetKind.mapEvent,
          );
          final blocked = await _mount(tester, mapEvent: true, barrier: true);
          _expectFinePose(blocked);
          if (dispatch) {
            expect(
              blocked.dispatchOverworldInteraction(
                _currentRequest(blocked, template),
              ),
              isFalse,
            );
            await _frames(blocked);
            expect(
              blocked
                  .gameStateSnapshot
                  .narrativeFactRuntimeState
                  .overridesByFactId['read'],
              isNot(true),
            );
          } else {
            expect(blocked.overworldInteractionSnapshot.primaryAction, isNull);
          }
        });
      },
    );
  }

  testWidgets(
    'the real front map event executes after removing the barrier and remains available after reload',
    (tester) async {
      await tester.runAsync(() async {
        final clear = await _mount(tester, mapEvent: true);
        _expectFinePose(clear);
        expect(
          clear.dispatchOverworldInteraction(
            clear.overworldInteractionSnapshot.primaryAction!.request,
          ),
          isTrue,
        );
        await helpers.tickUntil(
          clear,
          () =>
              clear
                      .gameStateSnapshot
                      .narrativeFactRuntimeState
                      .overridesByFactId['read'] ==
                  true &&
              clear.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(await clear.saveGame(), isTrue);
        final cold = await _mount(
          tester,
          mapEvent: true,
          restored: gameStateFromStrictSaveJson(
            strictGameStateSaveJson(clear.gameStateSnapshot),
          ),
        );
        _expectFinePose(cold);
        expect(
          cold
              .gameStateSnapshot
              .narrativeFactRuntimeState
              .overridesByFactId['read'],
          isTrue,
        );
        expect(
          cold.overworldInteractionSnapshot.primaryAction!.request.targetId,
          'tile-event',
        );
      });
    },
  );
}

RuntimeOverworldInteractionRequest _currentRequest(
  PlayableMapGame game,
  RuntimeOverworldInteractionRequest template,
) {
  final snapshot = game.overworldInteractionSnapshot;
  return RuntimeOverworldInteractionRequest(
    sessionId: snapshot.sessionId,
    mapActivationId: snapshot.mapActivationId,
    mapId: snapshot.mapId,
    targetKind: template.targetKind,
    targetId: template.targetId,
    actionId: template.actionId,
  );
}

void _expectFinePose(PlayableMapGame game) {
  final state = game.gameStateSnapshot;
  expect(state.playerPosition, const GridPos(x: 5, y: 6));
  expect(state.playerPixelPosition, const PixelOffset(x: 159, y: 192));
  expect(state.playerFacing, EntityFacing.east);
  final rect =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
        spriteTopLeftPx: const PixelPosition(leftPx: 159, topPx: 192),
        spriteWidthPx: PlayerCollisionConventionsV1.defaultSpriteWidthPx,
        spriteHeightPx: PlayerCollisionConventionsV1.defaultSpriteHeightPx,
      );
  expect(
    [rect.leftPx, rect.topPx, rect.widthPx, rect.heightPx],
    [169, 216, 12, 8],
  );
}

Future<void> _frames(PlayableMapGame game) async {
  for (var i = 0; i < 12; i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<PlayableMapGame> _mount(
  WidgetTester tester, {
  bool barrier = false,
  bool eventV2 = false,
  bool mapEvent = false,
  GameState? restored,
}) async {
  final root = await Directory.systemTemp.createTemp('fine-interaction-');
  addTearDown(() => root.delete(recursive: true));
  final map = MapData(
    id: 'room',
    name: 'Room',
    size: const GridSize(width: 16, height: 16),
    layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
      if (!mapEvent)
        const MapEntity(
          id: 'sign',
          kind: MapEntityKind.sign,
          pos: GridPos(x: 6, y: 6),
          sign: MapEntitySignData(plainText: 'Panneau'),
        ),
    ],
    placedElements: [
      if (barrier)
        const MapPlacedElement(
          id: 'separate-barrier',
          layerId: 'objects',
          elementId: 'barrier',
          pos: GridPos(x: 5, y: 6),
          pixelOffset: PixelOffset(x: 25, y: 0),
          pixelSize: PixelSize(width: 2, height: 32),
          properties: {
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
          },
        ),
    ],
    events: [
      if (mapEvent)
        const MapEventDefinition(
          id: 'tile-event',
          position: EventPosition(layerId: 'objects', x: 6, y: 6),
          pages: [
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'read-scene'),
            ),
          ],
        ),
    ],
  );
  final project = ProjectManifest(
    name: 'Fine interaction',
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
    maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
      ),
    ],
    facts: [NarrativeFactDefinition(id: 'read', label: 'Read')],
    scenes: [_scene()],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: eventV2 ? EventSystemMode.v2Only : EventSystemMode.legacyOnly,
      records: [
        if (eventV2)
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: 'evt_019abcde-2800-7000-8000-000000000001',
              name: 'Read',
              source: NarrativeEventSourceRef.entityInteract('room', 'sign'),
              conditions: const [],
              sceneId: 'read-scene',
              reusePolicy: NarrativeEventReusePolicy.reusable,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
      ],
      legacyClaims: const [],
    ),
    elements: [
      ProjectElementEntry(
        id: 'barrier',
        name: 'Barrier',
        tilesetId: 'tiles',
        categoryId: 'objects',
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
              solidPixels: List.filled(1024, true),
            ),
          ),
        ),
      ),
    ],
  );
  final bundle = RuntimeMapBundle(
    manifest: project,
    map: MapData.fromJson(
      jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
    ),
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(
      restored ??
          const GameState(
            saveId: '00000000-0000-4000-8000-000000000028',
            currentMapId: 'room',
            playerPosition: GridPos(x: 5, y: 6),
            playerPixelPosition: PixelOffset(x: 159, y: 192),
            playerFacing: EntityFacing.east,
          ),
    ),
    initialMapActivationReason: MapActivationReason.saveRestore,
    runtimeTilesetImageLoader: (
      paths, {
      transparentColorByTilesetId = const {},
    }) async => {},
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle,
    saveRepository: helpers.MemorySave(),
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(
        game: game,
        errorBuilder: (_, _) => const SizedBox.shrink(),
      ),
    ),
  );
  await tester
      .state<GameWidgetState<PlayableMapGame>>(
        find.byType(GameWidget<PlayableMapGame>),
      )
      .loaderFuture;
  await tester.pump();
  await helpers.tickUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
  await _frames(game);
  return game;
}

SceneAsset _scene() => SceneAsset(
  id: 'read-scene',
  name: 'Read',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'set',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'read', value: true),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-set',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'set',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'set-end',
        fromNodeId: 'set',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);
