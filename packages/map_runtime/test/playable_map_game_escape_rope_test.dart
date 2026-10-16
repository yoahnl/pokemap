import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart'
    show MemorySave, tickUntil, warp, press;

const rope = ProjectItemDefinition(
  id: 'rope',
  displayName: 'Corde Sortie',
  pocketId: 'items',
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.world,
      consumption: ProjectItemConsumptionPolicy.onApplied,
      effect: ProjectItemEffectDefinition.escapeRope(),
    ),
  ],
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final failure in <String?>[
    null,
    'load',
    'mount',
    'activation',
    'checkpoint',
    'npc',
    'wall',
    'water',
    'hiddenNpc',
    'rewards',
  ]) {
    testWidgets('rope transfer and durable checkpoint are atomic: $failure', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final saves = <GameState>[];
        final mounted = await mountRope(
          tester,
          failure: failure,
          checkpoint: (state) async {
            if (failure == 'checkpoint') throw StateError('disk full');
            saves.add(state);
          },
        );
        final game = mounted.game;
        final before = game.playerServiceGameStateSnapshot;
        game.pauseEngine();
        var done = false;
        final use = mounted.controller
            .useBagItemOutsideBattle(
              const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
            )
            .whenComplete(() => done = true);
        final duplicate = await mounted.controller.useBagItemOutsideBattle(
          const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
        );
        expect(duplicate.status, RuntimePlayerPauseCommandStatus.unavailable);
        await tickUntil(game, () => done);
        final result = await use;
        if (failure == null || failure == 'hiddenNpc' || failure == 'rewards') {
          expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
          expect(game.gameStateSnapshot.currentMapId, 'outside');
          expect(
            game.gameStateSnapshot.playerPosition,
            const GridPos(x: 3, y: 2),
          );
          expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
          expect(
            game.gameStateSnapshot.bag.entries.single.quantity,
            failure == 'rewards' ? 4 : 1,
          );
          if (failure == 'rewards') {
            expect(
              game
                  .gameStateSnapshot
                  .narrativeFactRuntimeState
                  .overridesByFactId['arrived'],
              isTrue,
            );
          }
          expect(game.gameStateSnapshot.escapeReturnPoint, isNull);
          expect(saves, hasLength(1));
          expect(
            saveDataFromGameState(
              gameStateFromSaveData(
                SaveData.fromJson(saveDataFromGameState(saves.single).toJson()),
              ),
            ),
            saveDataFromGameState(saves.single),
          );
        } else {
          expect(
            result.status,
            isNot(RuntimePlayerPauseCommandStatus.accepted),
          );
          expect(game.playerServiceGameStateSnapshot, before);
          expect(game.debugIsMapLoaded('cave'), isTrue);
          expect(saves, isEmpty);
        }
      });
    });
  }
  for (final sameDungeon in [false, true]) {
    testWidgets(
      'real input and MapEnter chain preserve dungeon identity: $sameDungeon',
      (tester) async {
        await tester.runAsync(() async {
          final saves = <GameState>[];
          final mounted = await mountRope(
            tester,
            failure: sameDungeon ? 'chainSame' : 'chainOther',
            checkpoint: (state) async => saves.add(state),
          );
          final game = mounted.game;
          expect(game.gameStateSnapshot.currentMapId, 'outside');
          await press(game, RuntimeInputControl.right);
          await tickUntil(
            game,
            () =>
                game.gameStateSnapshot.currentMapId == 'second' &&
                !game.debugIsMapActivationDispatchInFlight &&
                game.inputAuthoritySnapshot.acceptsOverworldInput,
          );
          final anchor = game.gameStateSnapshot.escapeReturnPoint;
          expect(game.gameStateSnapshot.trainerProfile.money, 50);
          if (sameDungeon) {
            expect(anchor?.dungeonId, 'dungeon');
            expect(anchor?.mapId, 'outside');
            expect(anchor?.position, const GridPos(x: 3, y: 2));
            expect(anchor?.facing, EntityFacing.east);
          } else {
            expect(anchor, isNull);
          }
          var done = false;
          final used = mounted.controller
              .useBagItemOutsideBattle(
                const RuntimePlayerPauseCommand.useBagItem(
                  itemTargetId: 'rope',
                ),
              )
              .whenComplete(() => done = true);
          await tickUntil(game, () => done);
          final result = await used;
          expect(
            result.status == RuntimePlayerPauseCommandStatus.accepted,
            sameDungeon,
          );
          expect(
            game.gameStateSnapshot.currentMapId,
            sameDungeon ? 'outside' : 'second',
          );
          expect(
            game.gameStateSnapshot.bag.entries.single.quantity,
            sameDungeon ? 1 : 2,
          );
          expect(game.gameStateSnapshot.trainerProfile.money, 50);
          expect(saves.length, sameDungeon ? 1 : 0);
          if (sameDungeon) {
            expect(saves.single.currentMapId, 'outside');
            expect(saves.single.trainerProfile.money, 50);
          }
        });
      },
    );
  }
  for (final failure in ['entryLoad', 'entryMount']) {
    testWidgets(
      'failed external dungeon transfer does not publish an anchor: $failure',
      (tester) async {
        await tester.runAsync(() async {
          final mounted = await mountRope(
            tester,
            failure: failure,
            checkpoint: (_) async => fail('failed entry must not save'),
          );
          final game = mounted.game;
          expect(game.gameStateSnapshot.escapeReturnPoint, isNull);
          expect(await warp(game, 'cave', 'door'), 'blocked');
          expect(game.gameStateSnapshot.currentMapId, 'outside');
          expect(game.gameStateSnapshot.escapeReturnPoint, isNull);
          expect(game.gameStateSnapshot.bag.entries.single.quantity, 2);
        });
      },
    );
  }
  testWidgets(
    'warp entry records anchor and rope arrival does not retrigger entrance',
    (tester) async {
      await tester.runAsync(() async {
        final mounted = await mountRope(
          tester,
          failure: 'entrywarp',
          checkpoint: (_) async {},
        );
        final game = mounted.game;
        expect(game.gameStateSnapshot.escapeReturnPoint, isNull);
        expect(await warp(game, 'cave', 'door'), 'completed');
        expect(game.gameStateSnapshot.currentMapId, 'cave');
        expect(game.gameStateSnapshot.escapeReturnPoint?.mapId, 'outside');
        expect(
          game.gameStateSnapshot.escapeReturnPoint?.position,
          const GridPos(x: 3, y: 2),
        );
        var done = false;
        final used = mounted.controller
            .useBagItemOutsideBattle(
              const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
            )
            .whenComplete(() => done = true);
        await tickUntil(game, () => done);
        expect((await used).status, RuntimePlayerPauseCommandStatus.accepted);
        for (var frame = 0; frame < 10; frame++) {
          game.update(.016);
          await Future<void>.delayed(Duration.zero);
        }
        expect(game.gameStateSnapshot.currentMapId, 'outside');
        await press(game, RuntimeInputControl.left);
        await press(game, RuntimeInputControl.right);
        await tickUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId == 'cave' &&
              game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(
          game.gameStateSnapshot.escapeReturnPoint?.position,
          const GridPos(x: 3, y: 2),
        );
      });
    },
  );
  testWidgets(
    'native map connection captures external entry and rope returns exactly',
    (tester) async {
      await tester.runAsync(() async {
        final mounted = await mountRope(
          tester,
          failure: 'connection',
          checkpoint: (_) async {},
        );
        final game = mounted.game;
        await press(game, RuntimeInputControl.right);
        await tickUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId == 'cave' &&
              game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(
          game.gameStateSnapshot.escapeReturnPoint?.position,
          const GridPos(x: 7, y: 2),
        );
        var done = false;
        final used = mounted.controller
            .useBagItemOutsideBattle(
              const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
            )
            .whenComplete(() => done = true);
        await tickUntil(game, () => done);
        expect((await used).status, RuntimePlayerPauseCommandStatus.accepted);
        expect(game.gameStateSnapshot.currentMapId, 'outside');
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 7, y: 2),
        );
      });
    },
  );
  testWidgets(
    'state change while mounting refuses and restores newer source visuals',
    (tester) async {
      await tester.runAsync(() async {
        final entered = Completer<void>(), release = Completer<void>();
        final mounted = await mountRope(
          tester,
          checkpoint: (_) async => fail('stale transfer must not save'),
          mountGate: release,
          mountEntered: entered,
        );
        final game = mounted.game;
        var done = false;
        final used = mounted.controller
            .useBagItemOutsideBattle(
              const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
            )
            .whenComplete(() => done = true);
        await tickUntil(game, () => entered.isCompleted);
        game.setPlayerMovementMode(MovementMode.walk);
        final newer = game.playerServiceGameStateSnapshot;
        release.complete();
        await tickUntil(game, () => done);
        expect(
          (await used).status,
          isNot(RuntimePlayerPauseCommandStatus.accepted),
        );
        expect(game.playerServiceGameStateSnapshot, newer);
        expect(game.debugIsMapLoaded('cave'), isTrue);
      });
    },
  );
  testWidgets(
    'Scene entry preserves consequences already accumulated before its warp',
    (tester) async {
      await tester.runAsync(() async {
        final mounted = await mountRope(
          tester,
          failure: 'sceneEntry',
          checkpoint: (_) async {},
        );
        final game = mounted.game;
        expect(game.gameStateSnapshot.currentMapId, 'cave');
        expect(game.gameStateSnapshot.trainerProfile.money, 250);
        expect(game.gameStateSnapshot.escapeReturnPoint?.mapId, 'outside');
      });
    },
  );
  testWidgets('failed durable checkpoint preserves newer concurrent state', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final entered = Completer<void>(), release = Completer<void>();
      final mounted = await mountRope(
        tester,
        checkpoint: (_) async {
          entered.complete();
          await release.future;
          throw StateError('disk full');
        },
      );
      final game = mounted.game;
      var done = false;
      final use = mounted.controller
          .useBagItemOutsideBattle(
            const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
          )
          .whenComplete(() => done = true);
      await tickUntil(game, () => entered.isCompleted);
      game.setPlayerMovementMode(MovementMode.surf);
      final newer = game.playerServiceGameStateSnapshot;
      release.complete();
      await tickUntil(game, () => done);
      expect(
        (await use).status,
        isNot(RuntimePlayerPauseCommandStatus.accepted),
      );
      expect(
        game.playerServiceGameStateSnapshot,
        newer.copyWith(
          bag: const Bag(entries: [BagEntry(itemId: 'rope', quantity: 2)]),
        ),
      );
      expect(game.gameStateSnapshot.currentMapId, 'outside');
    });
  });
}

Future<({PlayableMapGame game, PlayerServiceRuntimeController controller})>
mountRope(
  WidgetTester tester, {
  String? failure,
  required Future<void> Function(GameState) checkpoint,
  Completer<void>? mountGate,
  Completer<void>? mountEntered,
}) async {
  final root = await Directory.systemTemp.createTemp('native-rope-');
  addTearDown(() => root.delete(recursive: true));
  final source =
      const MapData(
        id: 'cave',
        name: 'Cave',
        size: GridSize(width: 8, height: 6),
        mapMetadata: MapMetadata(escapeRopeDungeonId: 'dungeon'),
      ).copyWith(
        warps: [
          const MapWarp(
            id: 'door',
            pos: GridPos(x: 2, y: 2),
            targetMapId: 'outside',
            targetPos: GridPos(x: 3, y: 2),
          ),
        ],
      );
  final outside = MapData(
    id: 'outside',
    name: 'Outside',
    size: const GridSize(width: 8, height: 6),
    warps: [
      if (failure == 'entrywarp' ||
          failure == 'chainSame' ||
          failure == 'chainOther')
        const MapWarp(
          id: 'entrance',
          pos: GridPos(x: 3, y: 2),
          targetMapId: 'cave',
          targetPos: GridPos(x: 2, y: 2),
        ),
    ],
    connections: [
      if (failure == 'connection')
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'cave',
        ),
    ],
    layers: [
      if (failure == 'wall')
        MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: List.generate(48, (i) => i == 19),
        ),
    ],
    gameplayZones: [
      if (failure == 'water')
        const MapGameplayZone(
          id: 'water',
          kind: GameplayZoneKind.movement,
          area: MapRect(
            pos: GridPos(x: 3, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
          movement: MovementZonePayload(requiredMode: MovementMode.surf),
        ),
    ],
    entities: [
      if (failure == 'npc' || failure == 'hiddenNpc')
        const MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 2),
          npc: MapEntityNpcData(),
        ),
    ],
  );
  var state = const GameState(
    saveId: 'rope',
    currentMapId: 'cave',
    playerPosition: GridPos(x: 2, y: 2),
    bag: Bag(entries: [BagEntry(itemId: 'rope', quantity: 2)]),
    escapeReturnPoint: EscapeReturnPoint(
      dungeonId: 'dungeon',
      mapId: 'outside',
      position: GridPos(x: 3, y: 2),
      facing: EntityFacing.west,
    ),
  );
  if (failure == 'entrywarp' ||
      failure == 'connection' ||
      failure == 'sceneEntry') {
    state = state.copyWith(
      currentMapId: 'outside',
      playerPosition: GridPos(x: failure == 'connection' ? 7 : 3, y: 2),
      playerFacing: EntityFacing.west,
      escapeReturnPoint: null,
    );
  }
  if (failure == 'hiddenNpc') {
    state = state.copyWith(
      metadata: {'pokemap.npcPresence.outside.npc': 'hidden'},
    );
  }
  final manifest = ProjectManifest(
    name: 'Rope',
    tilesets: [],
    maps: [
      ProjectMapEntry(id: 'cave', name: 'Cave', relativePath: 'maps/cave.json'),
      ProjectMapEntry(
        id: 'outside',
        name: 'Outside',
        relativePath: 'maps/outside.json',
      ),
    ],
  );
  await File('${root.path}/items.json').writeAsString(
    jsonEncode(
      const ProjectItemCatalog(schemaVersion: 1, entries: [rope]).toJson(),
    ),
  );
  var readyManifest = failure != 'rewards'
      ? manifest
      : manifest.copyWith(
          pokemon: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'items.json'},
          ),
          facts: [NarrativeFactDefinition(id: 'arrived', label: 'Arrived')],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_019abcde-3000-7000-8000-000000000003',
                  name: 'Arrival reward',
                  source: NarrativeEventSourceRef.mapEnter('outside'),
                  sceneId: 'arrival_rewards',
                  conditions: [],
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
            legacyClaims: [],
          ),
          scenes: [
            SceneAsset(
              id: 'arrival_rewards',
              name: 'Arrival rewards',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'fact',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.consequence(
                      SceneConsequence.setFact(factId: 'arrived', value: true),
                    ),
                  ),
                  SceneNode(
                    id: 'item',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.consequence(
                      SceneConsequence.giveItem(itemId: 'rope', quantity: 3),
                    ),
                  ),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'a',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'fact',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                  SceneEdge(
                    id: 'b',
                    fromNodeId: 'fact',
                    fromPortId: 'completed',
                    toNodeId: 'item',
                    kind: SceneEdgeKind.actionCompleted,
                  ),
                  SceneEdge(
                    id: 'c',
                    fromNodeId: 'item',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.actionCompleted,
                  ),
                ],
              ),
            ),
          ],
        );
  if (failure == 'sceneEntry') {
    readyManifest = manifest.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: 'evt_019abcde-3000-7000-8000-000000000004',
              name: 'Entry',
              source: NarrativeEventSourceRef.mapEnter('outside'),
              sceneId: 'entry-scene',
              conditions: [],
              reusePolicy: NarrativeEventReusePolicy.reusable,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: [],
      ),
      scenes: [
        SceneAsset(
          id: 'entry-scene',
          name: 'Entry scene',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'money',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.giveMoney(amount: 250),
                ),
              ),
              SceneNode(
                id: 'warp',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.warp(
                    destinationMapId: 'cave',
                    warpId: 'door',
                    transition: SceneWarpTransition.none,
                  ),
                ),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'a',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'money',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'b',
                fromNodeId: 'money',
                fromPortId: 'completed',
                toNodeId: 'warp',
                kind: SceneEdgeKind.actionCompleted,
              ),
              SceneEdge(
                id: 'c',
                fromNodeId: 'warp',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
        ),
      ],
    );
  }
  final second = source.copyWith(
    id: 'second',
    name: 'Second',
    mapMetadata: MapMetadata(
      escapeRopeDungeonId: failure == 'chainSame' ? 'dungeon' : 'other-dungeon',
    ),
  );
  if (failure == 'entryLoad' || failure == 'entryMount') {
    state = state.copyWith(currentMapId: 'outside', escapeReturnPoint: null);
  }
  if (failure == 'chainSame' || failure == 'chainOther') {
    state = state.copyWith(
      currentMapId: 'outside',
      playerPosition: const GridPos(x: 2, y: 2),
      playerFacing: EntityFacing.east,
      escapeReturnPoint: null,
    );
    readyManifest = manifest.copyWith(
      maps: [
        ...manifest.maps,
        const ProjectMapEntry(
          id: 'second',
          name: 'Second',
          relativePath: 'maps/second.json',
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: 'evt_019abcde-3000-7000-8000-000000000005',
              name: 'MapEnter chain',
              source: NarrativeEventSourceRef.mapEnter('cave'),
              sceneId: 'map-enter-chain',
              conditions: [],
              reusePolicy: NarrativeEventReusePolicy.reusable,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: [],
      ),
      scenes: [
        SceneAsset(
          id: 'map-enter-chain',
          name: 'MapEnter chain',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'money',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.giveMoney(amount: 50),
                ),
              ),
              SceneNode(
                id: 'warp',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.warp(
                    destinationMapId: 'second',
                    warpId: 'door',
                    transition: SceneWarpTransition.none,
                  ),
                ),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'a',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'money',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'b',
                fromNodeId: 'money',
                fromPortId: 'completed',
                toNodeId: 'warp',
                kind: SceneEdgeKind.actionCompleted,
              ),
              SceneEdge(
                id: 'c',
                fromNodeId: 'warp',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
        ),
      ],
    );
  }
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: {},
    manifest: readyManifest,
    map: state.currentMapId == 'outside' ? outside : source,
  );
  var loaded = false;
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: MapActivationReason.saveRestore,
    saveRepository: MemorySave(),
    overworldCheckpointWriter: checkpoint,
    runtimeTilesetImageLoader: (
      paths, {
      transparentColorByTilesetId = const {},
    }) async => {},
    runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
      if ((mapId == 'outside' && failure == 'load') ||
          (mapId == 'cave' && failure == 'entryLoad')) {
        throw StateError('load failed');
      }
      return bundle.copyWith(
        map: mapId == 'outside'
            ? outside
            : mapId == 'second'
            ? second
            : source,
      );
    },
    beforeMapMount: (mapId) async {
      if (loaded && mapId == 'cave' && failure == 'entryMount') {
        throw StateError('mount failed');
      }
      if (loaded && mapId == 'outside') {
        if (mountEntered != null && !mountEntered.isCompleted) {
          mountEntered.complete();
        }
        await mountGate?.future;
        if (failure == 'mount') throw StateError('mount failed');
      }
    },
    beforeNarrativeAuthorityPreparation: (occurrence) async {
      if (loaded &&
          occurrence.source.toJson()['mapId'] == 'outside' &&
          failure == 'activation') {
        throw StateError('activation failed');
      }
    },
  );
  final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => game.playerServiceGameStateSnapshot,
    commitAndSave: game.commitAndSavePlayerServiceState,
    setInputLocked: (locked) => game.setExternalInputLock(
      RuntimeExternalInputLock.playerService,
      locked: locked,
    ),
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    itemCatalog: ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(schemaVersion: 1, entries: [rope]),
    ),
  );
  game.setPlayerServiceRuntimeController(controller);
  addTearDown(controller.dispose);
  addTearDown(game.onRemove);
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
  await tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  loaded = true;
  return (game: game, controller: controller);
}
