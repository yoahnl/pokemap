import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a fresh Cut tree allocates an instance and offers an interaction',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester);
        final game = fixture.game;
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          isNotNull,
        );
        expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
      });
    },
  );

  testWidgets(
    'save restore projects a cleared tree before collision validation',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester, restoredCleared: true);
        final game = fixture.game;
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(fixture.sfx.cuts, 0);
      });
    },
  );

  testWidgets('V2 without a declared owner admits intrinsic Cut', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final fixture = await _mount(tester, v2Only: true);
      await _cut(fixture.game);
      expect(fixture.sfx.cuts, 1);
    });
  });

  testWidgets('a disabled declared V2 owner still prevents intrinsic Cut', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final fixture = await _mount(tester, v2Only: true, declaredOwner: true);
      expect(fixture.game.overworldInteractionSnapshot.primaryAction, isNull);
      await _press(fixture.game, RuntimeInputControl.primary);
      expect(
        fixture.game.debugMapEntityPosition('tree'),
        const GridPos(x: 2, y: 1),
      );
      expect(fixture.sfx.cuts, 0);
    });
  });

  for (final answer in ['yes', 'no', 'cancel', 'stale']) {
    testWidgets('native Cut $answer resolves through the Player dialogue', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester);
        final game = fixture.game;
        final request =
            game.overworldInteractionSnapshot.primaryAction?.request;
        expect(request, isNotNull);
        expect(game.dispatchOverworldInteraction(request!), isTrue);
        expect(
          game.inputAuthoritySnapshot.context,
          RuntimeInputContext.dialogue,
        );
        final position = game.debugPlayerGridPosition;
        await _press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, position);
        final revision = game.debugGameStateRevision;
        game.gameStateSnapshot;
        game.saveLoadInfo;
        expect(game.debugGameStateRevision, revision);
        await _press(game, RuntimeInputControl.primary);
        if (answer == 'no') await _press(game, RuntimeInputControl.down);
        if (answer == 'stale') game.setPlayerMovementMode(MovementMode.surf);
        await _press(
          game,
          answer == 'cancel'
              ? RuntimeInputControl.secondary
              : RuntimeInputControl.primary,
        );
        await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
        final success = answer == 'yes';
        final state = game.gameStateSnapshot;
        final instance = state.mapInstanceWorldState.instanceRef('route')!;
        expect(
          state.mapInstanceWorldState.isFieldObstacleCleared(instance, 'tree'),
          success,
        );
        expect(
          game.debugMapEntityPosition('tree'),
          success ? isNull : const GridPos(x: 2, y: 1),
        );
        expect(fixture.sfx.cuts, success ? 1 : 0);
        final authored = await game.debugLoadRuntimeMapBundleCachedForTest(
          'route',
        );
        expect(
          authored.map.entities.any((entity) => entity.id == 'tree'),
          isTrue,
        );
        if (success) {
          await _press(game, RuntimeInputControl.right);
          expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
          final reloaded = await _mount(
            tester,
            restoredState: game.gameStateSnapshot,
          );
          expect(reloaded.game.debugMapEntityPosition('tree'), isNull);
          expect(
            reloaded.game.debugPlayerGridPosition,
            const GridPos(x: 2, y: 1),
          );
          expect(reloaded.sfx.cuts, 0);
        }
      });
    });
  }

  testWidgets(
    'same-map warp preserves Cut and a different-map setup restores it',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(tester);
        final game = fixture.game;
        await _cut(game);
        final cutInstance = game.gameStateSnapshot.mapInstanceWorldState
            .instanceRef('route');
        expect(await _warp(game, 'route', 'tree-cell'), 'completed');
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          cutInstance,
        );
        expect(await game.saveGame(), isTrue);
        expect(await _warp(game, 'neighbor', 'safe'), 'completed');
        expect(await _warp(game, 'route', 'tree-cell'), 'blocked');
        expect(game.gameStateSnapshot.currentMapId, 'neighbor');
        expect(await _warp(game, 'route', 'safe'), 'completed');
        expect(game.debugMapEntityPosition('tree'), const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          isNot(cutInstance),
        );
        expect(await game.loadGame(), isTrue);
        expect(game.debugMapEntityPosition('tree'), isNull);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('route'),
          cutInstance,
        );
        expect(fixture.sfx.cuts, 1);
      });
    },
  );

  for (final retain in [false, true]) {
    testWidgets(
      'connection return uses the exact Cut instance retain=$retain',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await _mount(
            tester,
            startNeighbor: true,
            connections: true,
            retainInstances: retain,
          );
          final game = fixture.game;
          await _cut(game);
          final instance = game.gameStateSnapshot.mapInstanceWorldState
              .instanceRef('neighbor');
          expect(await _warp(game, 'neighbor', 'edge'), 'completed');
          await _press(game, RuntimeInputControl.left);
          await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          expect(game.gameStateSnapshot.currentMapId, 'route');
          expect(game.debugPlayerGridPosition, const GridPos(x: 4, y: 1));
          await _press(game, RuntimeInputControl.right);
          await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          if (retain) {
            expect(game.gameStateSnapshot.currentMapId, 'neighbor');
            expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
            expect(game.debugMapEntityPosition('tree'), isNull);
            expect(
              game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
                'neighbor',
              ),
              instance,
            );
          } else {
            expect(game.gameStateSnapshot.currentMapId, 'route');
            expect(
              game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
                'neighbor',
              ),
              isNull,
            );
          }
          expect(fixture.sfx.cuts, 1);
        });
      },
    );
  }
}

Future<({PlayableMapGame game, _Sfx sfx})> _mount(
  WidgetTester tester, {
  bool restoredCleared = false,
  GameState? restoredState,
  bool startNeighbor = false,
  bool connections = false,
  bool retainInstances = false,
  bool v2Only = false,
  bool declaredOwner = false,
}) async {
  final root = await Directory.systemTemp.createTemp('native-cut-player-');
  addTearDown(() => root.delete(recursive: true));
  final sfx = _Sfx();
  var state =
      restoredState ??
      GameState(
        saveId: 'cut-player',
        currentMapId: 'route',
        playerPosition: GridPos(x: restoredCleared ? 2 : 1, y: 1),
        playerFacing: EntityFacing.east,
        party: const PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'scyther',
              natureId: 'hardy',
              abilityId: 'swarm',
              level: 20,
              currentHp: 30,
              knownMoveIds: ['cut'],
            ),
          ],
        ),
        progression: const PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.cut],
        ),
        mapInstanceWorldState: restoredCleared
            ? MapInstanceWorldState(
                instancesByMapId: {
                  'route': MapInstanceRuntimeState(
                    instanceId: 'restored-route',
                    clearedFieldObstacleIds: {'tree'},
                  ),
                },
              )
            : MapInstanceWorldState(instancesByMapId: {}),
      );
  if (startNeighbor) {
    state = state.copyWith(
      currentMapId: 'neighbor',
      playerFacing: EntityFacing.west,
    );
  }
  final manifest = ProjectManifest(
    name: 'Cut Player',
    eventRegistry: v2Only
        ? NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: const [],
            records: [
              if (declaredOwner)
                NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                    id: 'evt_019abcde-1400-7000-8000-000000000009',
                    name: 'Tree owner',
                    source: NarrativeEventSourceRef.entityInteract(
                      'route',
                      'tree',
                    ),
                    sceneId: 'owner-scene',
                    conditions: const [],
                    reusePolicy: NarrativeEventReusePolicy.oneShot,
                    priority: 0,
                    order: 0,
                  ),
                  enabled: false,
                ),
            ],
          )
        : null,
    scenes: declaredOwner
        ? [
            SceneAsset(
              id: 'owner-scene',
              name: 'Owner',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'finish',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                ],
              ),
            ),
          ]
        : const [],
    maps: const [
      ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
      ProjectMapEntry(
        id: 'neighbor',
        name: 'Neighbor',
        relativePath: 'maps/neighbor.json',
      ),
    ],
    tilesets: const [],
    settings: ProjectSettings(
      mapInstanceRetentionPolicy: retainInstances
          ? MapInstanceRetentionPolicy(
              viewportWidthTiles: 20,
              viewportHeightTiles: 15,
              marginTiles: 2,
            )
          : null,
    ),
  );
  final route = MapData(
    id: 'route',
    name: 'Route',
    size: const GridSize(width: 5, height: 4),
    layers: const [],
    entities: const [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 1),
        blocksMovement: true,
        fieldObstacle: MapEntityFieldObstacleData(),
      ),
    ],
    warps: [_arrival('route', 'tree-cell', 2), _arrival('route', 'safe', 1)],
    connections: connections
        ? const [
            MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: 'neighbor',
              offset: 0,
            ),
          ]
        : const [],
  );
  final neighbor = MapData(
    id: 'neighbor',
    name: 'Neighbor',
    size: const GridSize(width: 5, height: 4),
    layers: const [],
    entities: const [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
      MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: true,
        fieldObstacle: MapEntityFieldObstacleData(),
      ),
    ],
    warps: [_arrival('neighbor', 'safe', 3), _arrival('neighbor', 'edge', 0)],
    connections: connections
        ? const [
            MapConnection(
              direction: MapConnectionDirection.west,
              targetMapId: 'route',
              offset: 0,
            ),
          ]
        : const [],
  );
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    manifest: manifest,
    map: startNeighbor ? neighbor : route,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: restoredCleared || restoredState != null
        ? MapActivationReason.saveRestore
        : MapActivationReason.initialBoot,
    overworldSfxPlayer: sfx,
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle.copyWith(map: mapId == 'route' ? route : neighbor),
    saveRepository: _MemorySave(),
    runtimePlayerPokemonProgressionCatalogLoader:
        ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async => const RuntimePlayerPokemonProgressionCatalogs(
          speciesById: {
            'scyther': PlayerPokemonHydrationSpecies(
              id: 'scyther',
              baseStats: PokemonBaseStats(
                hp: 70,
                attack: 110,
                defense: 80,
                specialAttack: 55,
                specialDefense: 80,
                speed: 105,
              ),
              primaryAbilityId: 'swarm',
              abilityIds: ['swarm'],
              growthRateId: 'medium_fast',
            ),
          },
          maxPpByMoveId: {'cut': 30},
        ),
  );
  game.onGameResize(Vector2(320, 240));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  addTearDown(game.onRemove);
  await _tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  return (game: game, sfx: sfx);
}

MapWarp _arrival(String mapId, String id, int x) => MapWarp(
  id: id,
  pos: GridPos(x: x, y: 1),
  targetMapId: mapId,
  targetPos: GridPos(x: x, y: 1),
  triggerMode: MapWarpTriggerMode.onBump,
);

Future<void> _cut(PlayableMapGame game) async {
  final request = game.overworldInteractionSnapshot.primaryAction?.request;
  expect(request, isNotNull);
  expect(game.dispatchOverworldInteraction(request!), isTrue);
  for (var i = 0; i < 8; i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  await _press(game, RuntimeInputControl.primary);
  await _press(game, RuntimeInputControl.primary);
  await _tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
  expect(game.debugMapEntityPosition('tree'), isNull);
}

Future<String> _warp(PlayableMapGame game, String mapId, String warpId) async {
  final result = game.debugExecuteSceneInteractiveCommand(
    SceneInteractiveCommand.warp(
      destinationMapId: mapId,
      warpId: warpId,
      transition: SceneWarpTransition.none,
    ),
  );
  var finished = false;
  result.whenComplete(() => finished = true);
  await _tickUntil(game, () => finished);
  return result;
}

final class _MemorySave implements GameSaveRepository {
  Map<String, dynamic>? data;
  @override
  Future<void> save(GameState state) async {
    data = state.toJson();
  }

  @override
  Future<GameState?> load() async =>
      data == null ? null : GameState.fromJson(data!);
  @override
  Future<bool> exists() async => data != null;
  @override
  Future<void> delete() async {
    data = null;
  }
}

Future<void> _press(PlayableMapGame game, RuntimeInputControl control) async {
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.update(.016);
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  for (var i = 0; i < 8; i++) {
    game.update(.04);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> _tickUntil(PlayableMapGame game, bool Function() predicate) async {
  for (var i = 0; i < 200 && !predicate(); i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(predicate(), isTrue);
}

final class _Sfx implements OverworldSfxPlayer {
  var cuts = 0;
  @override
  Future<void> playCut() async {
    cuts += 1;
  }

  @override
  Future<void> playJump() async {}
  @override
  Future<void> dispose() async {}
}
