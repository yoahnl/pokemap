import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player/support/runtime_player_test_harness.dart';
import 'playable_map_game_flash_test.dart'
    show MemorySave, tickUntil, runWithFieldAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'normal Player menu opens the native service without blocking commands and resumes after real Fly',
    (tester) async {
      await tester.runAsync(() async {
        final mounted = await mountFly(tester, save: MemorySave());
        final harness = RuntimePlayerTestHarness(
          grantedCapabilities: {'battle.v1', 'map.v1'},
        );
        addTearDown(harness.dispose);
        await launchHarnessToPlaying(harness);
        harness.adapter.regionalMapOpener = mounted.game.openPlayerRegionalMap;
        harness.adapter.worldServiceDispatcher =
            mounted.controller.dispatchWorldService;
        final subscription = mounted.controller.worldServiceSnapshots.listen(
          harness.adapter.publishWorldService,
        );
        addTearDown(subscription.cancel);
        harness.adapter.pauseDetails = {
          RuntimePlayerPauseSection.map: RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.map,
            title: 'Carte',
            regionalMap: RuntimePlayerRegionMapSnapshot(
              regions: [
                RuntimePlayerRegionSnapshot(
                  id: 'region',
                  label: 'Region',
                  points: const [
                    RuntimePlayerMapPointSnapshot(
                      id: 'town',
                      label: 'Town',
                      status: RuntimePlayerMapPointStatus.discovered,
                    ),
                  ],
                ),
              ],
            ),
          ),
        };
        mounted.game.pauseEngine();
        Future<RuntimePlayerCommandResult> action(RuntimePlayerAction action) =>
            harness.coordinator.dispatch(
              RuntimePlayerCommand(
                action: action,
                snapshotRevision: harness.coordinator.snapshot.revision,
              ),
            );
        expect(
          (await action(RuntimePlayerAction.openMenu)).status,
          RuntimePlayerCommandStatus.accepted,
        );
        expect(
          (await action(RuntimePlayerAction.openMap)).status,
          RuntimePlayerCommandStatus.accepted,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          harness.coordinator.snapshot.worldService!.request.kind,
          RuntimeWorldServiceKind.regionalMap,
        );
        expect(
          (await action(RuntimePlayerAction.save)).status,
          RuntimePlayerCommandStatus.unavailable,
        );
        await harness.coordinator.requestBack(
          snapshotRevision: harness.coordinator.snapshot.revision,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          harness.coordinator.snapshot.pauseSection,
          RuntimePlayerPauseSection.root,
        );
        expect(mounted.game.gameStateSnapshot.currentMapId, 'source');
        await action(RuntimePlayerAction.openMap);
        await Future<void>.delayed(Duration.zero);
        await harness.coordinator.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.select,
            targetId: 'town',
            snapshotRevision: mounted.controller.worldServiceSnapshot!.revision,
          ),
        );
        var done = false;
        final fly = harness.coordinator
            .dispatchWorldService(
              RuntimeWorldServiceCommand(
                action: RuntimeWorldServiceAction.confirm,
                snapshotRevision:
                    mounted.controller.worldServiceSnapshot!.revision,
              ),
            )
            .whenComplete(() => done = true);
        await tickUntil(mounted.game, () => done);
        expect((await fly).status, RuntimeWorldServiceCommandStatus.accepted);
        await Future<void>.delayed(Duration.zero);
        expect(mounted.game.gameStateSnapshot.currentMapId, 'target');
        expect(harness.coordinator.snapshot.phase, RuntimePlayerPhase.playing);
        expect(harness.adapter.calls.last, 'resume');
      });
    },
  );
  for (final sceneFails in [false, true]) {
    testWidgets(
      'a Scene regional map ${sceneFails ? 'compensates later failure after Fly' : 'keeps the actual Fly arrival when it commits'}',
      (tester) async {
        await tester.runAsync(() async {
          final mounted = await mountFly(
            tester,
            save: MemorySave(),
            withScene: true,
            sceneFails: sceneFails,
          );
          final game = mounted.game, controller = mounted.controller;
          final before = game.gameStateSnapshot;
          var done = false;
          final execution = game
              .debugExecuteNarrativeSceneForTest(
                NarrativeSceneExecutionRequest(
                  eventId: 'fly-event',
                  sceneId: 'fly-scene',
                  executionId: 'fly-scene-execution',
                  gameState: before,
                ),
              )
              .whenComplete(() => done = true);
          await tickUntil(game, () => controller.worldServiceSnapshot != null);
          await controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: RuntimeWorldServiceAction.select,
              targetId: 'town',
              snapshotRevision: controller.worldServiceSnapshot!.revision,
            ),
          );
          var transferred = false;
          final result = controller
              .dispatchWorldService(
                RuntimeWorldServiceCommand(
                  action: RuntimeWorldServiceAction.confirm,
                  snapshotRevision: controller.worldServiceSnapshot!.revision,
                ),
              )
              .whenComplete(() => transferred = true);
          await tickUntil(game, () => transferred);
          expect(
            (await result).status,
            RuntimeWorldServiceCommandStatus.accepted,
          );
          await tickUntil(game, () => done);
          if (sceneFails) {
            expect(await execution, isA<NarrativeSceneExecutionFailed>());
            expect(game.gameStateSnapshot, before);
            expect(game.debugIsMapLoaded('source'), isTrue);
          } else {
            expect(await execution, isA<NarrativeSceneExecutionCompleted>());
            expect(game.gameStateSnapshot.currentMapId, 'target');
            expect(
              game.gameStateSnapshot.playerPosition,
              const GridPos(x: 3, y: 2),
            );
            expect(
              game.gameStateSnapshot.playerMovementMode,
              MovementMode.walk,
            );
          }
        });
      },
    );
  }
  testWidgets(
    'Fly revalidates after target loading and preserves a newer source state without saving',
    (tester) async {
      await runWithFieldAudio(tester, (fieldAudio) async {
        final gate = Completer<void>(), entered = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        final mounted = await mountFly(
          tester,
          projectAudio: fieldAudio.audio,
          save: MemorySave(),
          targetImagesGate: gate,
          targetImagesEntered: entered,
        );
        final controller = mounted.controller, game = mounted.game;
        final opening = (await game.openPlayerRegionalMap())!;
        await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.select,
            targetId: 'town',
            snapshotRevision: controller.worldServiceSnapshot!.revision,
          ),
        );
        var done = false;
        final result = controller
            .dispatchWorldService(
              RuntimeWorldServiceCommand(
                action: RuntimeWorldServiceAction.confirm,
                snapshotRevision: controller.worldServiceSnapshot!.revision,
              ),
            )
            .whenComplete(() => done = true);
        await tickUntil(game, () => entered.isCompleted);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        game.setPlayerMovementMode(MovementMode.walk);
        final newer = game.gameStateSnapshot;
        gate.complete();
        await tickUntil(game, () => done);
        expect(
          (await result).status,
          RuntimeWorldServiceCommandStatus.unavailable,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          fieldAudio.driver.paths.where((path) => path == 'fieldFly'),
          isEmpty,
        );
        expect(game.gameStateSnapshot, newer);
        expect(game.debugIsMapLoaded('source'), isTrue);
        await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.close,
            snapshotRevision: controller.worldServiceSnapshot!.revision,
          ),
        );
        expect(await opening.completed, RuntimeRegionalMapClosing.closed);
      });
    },
  );
  for (final mountFails in [false, true]) {
    testWidgets(
      'Fly preserves accepted source changes after unmount when target mount ${mountFails ? 'throws' : 'completes'}',
      (tester) async {
        await tester.runAsync(() async {
          final gate = Completer<void>(), entered = Completer<void>();
          addTearDown(() {
            if (!gate.isCompleted) gate.complete();
          });
          final mounted = await mountFly(
            tester,
            save: MemorySave(),
            retainInstances: true,
            beforeMapMount: (mapId) async {
              if (mapId != 'target') return;
              if (!entered.isCompleted) entered.complete();
              await gate.future;
              if (mountFails) throw StateError('Target mount failed');
            },
          );
          final controller = mounted.controller, game = mounted.game;
          final before = game.gameStateSnapshot;
          final opening = (await game.openPlayerRegionalMap())!;
          await controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: RuntimeWorldServiceAction.select,
              targetId: 'town',
              snapshotRevision: controller.worldServiceSnapshot!.revision,
            ),
          );
          var done = false;
          final result = controller
              .dispatchWorldService(
                RuntimeWorldServiceCommand(
                  action: RuntimeWorldServiceAction.confirm,
                  snapshotRevision: controller.worldServiceSnapshot!.revision,
                ),
              )
              .whenComplete(() => done = true);
          await tickUntil(game, () => entered.isCompleted);
          expect(game.debugIsMapLoaded('source'), isFalse);
          expect(game.gameStateSnapshot.currentMapId, 'source');
          expect(before.mapInstanceWorldState.instanceRef('source'), isNotNull);
          expect(
            game.gameStateSnapshot.mapInstanceWorldState.instanceRef('target'),
            isNotNull,
          );
          final acceptedMode = mountFails
              ? MovementMode.cut
              : MovementMode.walk;
          game.setPlayerMovementMode(acceptedMode);
          final accepted = game.gameStateSnapshot.copyWith(
            mapInstanceWorldState: before.mapInstanceWorldState,
          );
          expect(accepted.playerMovementMode, acceptedMode);
          expect(accepted, isNot(before));
          gate.complete();
          await tickUntil(game, () => done);
          expect(
            (await result).status,
            RuntimeWorldServiceCommandStatus.unavailable,
          );
          expect(game.gameStateSnapshot, accepted);
          expect(
            game.companionGameStateSnapshot.playerMovementMode,
            acceptedMode,
          );
          expect(game.debugIsMapLoaded('source'), isTrue);
          expect(game.debugIsMapLoaded('target'), isFalse);
          expect(game.debugPlayerGridPosition, accepted.playerPosition);
          expect(
            game.debugPlayerWorldTopLeft,
            game.debugExpectedPlayerWorldTopLeft,
          );
          await controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: RuntimeWorldServiceAction.close,
              snapshotRevision: controller.worldServiceSnapshot!.revision,
            ),
          );
          expect(await opening.completed, RuntimeRegionalMapClosing.closed);
          expect(await game.saveGame(), isTrue);
        });
      },
    );
  }
  testWidgets(
    'an explicit safe boundary spawn is used without a fallback location',
    (tester) async {
      await tester.runAsync(() async {
        final mounted = await mountFly(
          tester,
          save: MemorySave(),
          rejection: 'edge',
        );
        final opening = (await mounted.game.openPlayerRegionalMap())!;
        final controller = mounted.controller;
        await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.select,
            targetId: 'town',
            snapshotRevision: controller.worldServiceSnapshot!.revision,
          ),
        );
        var done = false;
        final result = controller
            .dispatchWorldService(
              RuntimeWorldServiceCommand(
                action: RuntimeWorldServiceAction.confirm,
                snapshotRevision: controller.worldServiceSnapshot!.revision,
              ),
            )
            .whenComplete(() => done = true);
        await tickUntil(mounted.game, () => done);
        expect(
          (await result).status,
          RuntimeWorldServiceCommandStatus.accepted,
        );
        expect(await opening.completed, RuntimeRegionalMapClosing.travelled);
        expect(
          mounted.game.gameStateSnapshot.playerPosition,
          const GridPos(x: 0, y: 0),
        );
        expect(
          mounted.game.gameStateSnapshot.playerMovementMode,
          MovementMode.walk,
        );
      });
    },
  );
  for (final rejection in [
    'water',
    'wall',
    'activation',
    'load',
    'visual',
    'same-map-activation',
  ]) {
    testWidgets(
      'mounted Fly refuses $rejection and restores the complete source checkpoint',
      (tester) async {
        await runWithFieldAudio(tester, (fieldAudio) async {
          var sawTarget = false;
          final mounted = await mountFly(
            tester,
            projectAudio: fieldAudio.audio,
            save: MemorySave(),
            rejection: rejection == 'same-map-activation'
                ? 'activation'
                : rejection,
            sameMapDestination: rejection == 'same-map-activation',
            sawTarget: () => sawTarget = true,
          );
          final game = mounted.game, controller = mounted.controller;
          final before = game.gameStateSnapshot;
          final activationCount = game.debugCompletedMapActivationDispatchCount;
          final opening = (await game.openPlayerRegionalMap())!;
          final selected = await controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: RuntimeWorldServiceAction.select,
              targetId: 'town',
              snapshotRevision: controller.worldServiceSnapshot!.revision,
            ),
          );
          if (rejection == 'load') {
            expect(
              selected.status,
              RuntimeWorldServiceCommandStatus.unavailable,
            );
          } else {
            expect(selected.status, RuntimeWorldServiceCommandStatus.accepted);
            var done = false;
            final result = controller
                .dispatchWorldService(
                  RuntimeWorldServiceCommand(
                    action: RuntimeWorldServiceAction.confirm,
                    snapshotRevision: controller.worldServiceSnapshot!.revision,
                  ),
                )
                .whenComplete(() => done = true);
            await tickUntil(game, () => done);
            expect(
              (await result).status,
              RuntimeWorldServiceCommandStatus.unavailable,
            );
          }
          await Future<void>.delayed(Duration.zero);
          expect(
            fieldAudio.driver.paths.where((path) => path == 'fieldFly'),
            isEmpty,
          );
          expect(game.gameStateSnapshot, before);
          expect(game.debugIsMapLoaded('source'), isTrue);
          expect(
            game.debugCompletedMapActivationDispatchCount,
            activationCount,
          );
          expect(game.debugPlayerGridPosition, before.playerPosition);
          if (rejection == 'activation' || rejection == 'same-map-activation') {
            expect(sawTarget, isTrue);
          }
          await controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: RuntimeWorldServiceAction.close,
              snapshotRevision: controller.worldServiceSnapshot!.revision,
            ),
          );
          await opening.completed;
          expect(game.debugIsGameplayInputLocked, isFalse);
        });
      },
    );
  }
  testWidgets('closing selected Fly destination stays silent', (tester) async {
    await runWithFieldAudio(tester, (fieldAudio) async {
      final mounted = await mountFly(
        tester,
        save: MemorySave(),
        projectAudio: fieldAudio.audio,
      );
      final game = mounted.game, controller = mounted.controller;
      final before = game.gameStateSnapshot;
      final opening = (await game.openPlayerRegionalMap())!;
      await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.select,
          targetId: 'town',
          snapshotRevision: controller.worldServiceSnapshot!.revision,
        ),
      );
      await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.close,
          snapshotRevision: controller.worldServiceSnapshot!.revision,
        ),
      );
      expect(await opening.completed, RuntimeRegionalMapClosing.closed);
      await Future<void>.delayed(Duration.zero);
      expect(game.gameStateSnapshot, before);
      expect(
        fieldAudio.driver.paths.where((path) => path == 'fieldFly'),
        isEmpty,
      );
    });
  });
  for (final blocked in [false, true]) {
    testWidgets(
      'mounted Player Fly ${blocked ? 'refuses occupied arrival and keeps source' : 'transfers to the authored spawn in walk and saves cold'}',
      (tester) async {
        await runWithFieldAudio(tester, (fieldAudio) async {
          final saved = MemorySave();
          final mounted = await mountFly(
            tester,
            blocked: blocked,
            save: saved,
            projectAudio: fieldAudio.audio,
          );
          final game = mounted.game;
          final before = game.gameStateSnapshot;
          game.pauseEngine();
          final opening = (await game.openPlayerRegionalMap())!;
          expect(game.isPaused, isTrue);
          final service = mounted.controller;
          Future<RuntimeWorldServiceCommandResult> dispatch(
            RuntimeWorldServiceAction action, {
            String? id,
          }) => service.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: action,
              targetId: id,
              snapshotRevision: service.worldServiceSnapshot!.revision,
            ),
          );
          expect(
            (await dispatch(
              RuntimeWorldServiceAction.select,
              id: 'town',
            )).status,
            RuntimeWorldServiceCommandStatus.accepted,
          );
          var done = false;
          final confirmation = dispatch(RuntimeWorldServiceAction.confirm)
              .whenComplete(() => done = true);
          await tickUntil(game, () => done);
          expect(
            (await confirmation).status,
            blocked
                ? RuntimeWorldServiceCommandStatus.unavailable
                : RuntimeWorldServiceCommandStatus.accepted,
          );
          await Future<void>.delayed(Duration.zero);
          expect(
            fieldAudio.driver.paths.where((path) => path == 'fieldFly'),
            hasLength(blocked ? 0 : 1),
          );
          if (blocked) {
            expect(game.gameStateSnapshot, before);
            expect(game.debugIsMapLoaded('source'), isTrue);
            await dispatch(RuntimeWorldServiceAction.close);
            expect(await opening.completed, RuntimeRegionalMapClosing.closed);
          } else {
            expect(
              await opening.completed,
              RuntimeRegionalMapClosing.travelled,
            );
            expect(game.gameStateSnapshot.currentMapId, 'target');
            expect(
              game.gameStateSnapshot.playerPosition,
              const GridPos(x: 3, y: 2),
            );
            expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
            expect(
              game.gameStateSnapshot.playerMovementMode,
              MovementMode.walk,
            );
            expect(game.gameStateSnapshot.party, before.party);
            expect(await game.saveGame(), isTrue);
            final cold = await saved.load();
            expect(cold!.currentMapId, 'target');
            expect(cold.playerPosition, const GridPos(x: 3, y: 2));
            expect(cold.playerMovementMode, MovementMode.walk);
            final restored = (await mountFly(
              tester,
              save: saved,
              restored: cold,
            )).game;
            expect(restored.gameStateSnapshot.currentMapId, 'target');
            expect(
              restored.gameStateSnapshot.playerPosition,
              cold.playerPosition,
            );
            expect(restored.gameStateSnapshot.party, cold.party);
          }
        });
      },
    );
  }
}

Future<({PlayableMapGame game, PlayerServiceRuntimeController controller})>
mountFly(
  WidgetTester tester, {
  bool blocked = false,
  required MemorySave save,
  GameState? restored,
  String? rejection,
  VoidCallback? sawTarget,
  Completer<void>? targetImagesGate,
  Completer<void>? targetImagesEntered,
  Future<void> Function(String mapId)? beforeMapMount,
  bool withScene = false,
  bool sceneFails = false,
  bool retainInstances = false,
  bool sameMapDestination = false,
  ProjectFieldAbilitiesSettings? fieldAbilities,
  RuntimeProjectAudioController? projectAudio,
}) async {
  final root = await Directory.systemTemp.createTemp('native-fly-');
  addTearDown(() => root.delete(recursive: true));
  const source = MapData(
    id: 'source',
    name: 'Source',
    size: GridSize(width: 8, height: 6),
    entities: [
      MapEntity(
        id: 'start',
        kind: MapEntityKind.spawn,
        blocksMovement: false,
        pos: GridPos(x: 1, y: 1),
        spawn: MapEntitySpawnData(),
      ),
    ],
  );
  final target = MapData(
    id: 'target',
    name: 'Target',
    size: const GridSize(width: 8, height: 6),
    layers: [
      if (rejection == 'wall')
        MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: List.generate(48, (index) => index == 19),
        ),
    ],
    gameplayZones: [
      if (rejection == 'water')
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
      MapEntity(
        id: 'arrival',
        kind: MapEntityKind.spawn,
        blocksMovement: false,
        pos: rejection == 'edge'
            ? const GridPos(x: 0, y: 0)
            : const GridPos(x: 3, y: 2),
        spawn: const MapEntitySpawnData(facing: EntityFacing.west),
      ),
      if (blocked)
        const MapEntity(
          id: 'occupied',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 2),
          npc: MapEntityNpcData(),
        ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Fly',
    settings: ProjectSettings(
      fieldAbilities: fieldAbilities,
      mapInstanceRetentionPolicy: retainInstances
          ? MapInstanceRetentionPolicy(
              viewportWidthTiles: 8,
              viewportHeightTiles: 6,
              marginTiles: 0,
            )
          : null,
    ),
    dialogues: [
      if (sceneFails)
        const ProjectDialogueEntry(
          id: 'after',
          name: 'After',
          relativePath: 'dialogues/after.yarn',
          declaredOutcomes: [
            DialogueDeclaredOutcome(id: 'done', label: 'Done'),
          ],
        ),
    ],
    scenes: [if (withScene) flyScene(sceneFails)],
    tilesets: [],
    maps: const [
      ProjectMapEntry(
        id: 'source',
        name: 'Source',
        relativePath: 'maps/source.json',
      ),
      ProjectMapEntry(
        id: 'target',
        name: 'Target',
        relativePath: 'maps/target.json',
      ),
    ],
    regionalMap: ProjectRegionalMapCatalog(
      regions: [ProjectRegionDefinition(id: 'region', label: 'Region')],
      pointsOfInterest: [
        ProjectRegionPointOfInterest(
          id: 'town',
          regionId: 'region',
          label: 'Town',
          u: .5,
          v: .5,
          mapIds: [sameMapDestination ? 'source' : 'target'],
          destination: ProjectRegionDestination(
            mapId: sameMapDestination ? 'source' : 'target',
            spawnId: sameMapDestination ? 'start' : 'arrival',
          ),
        ),
      ],
    ),
  );
  final state =
      restored ??
      GameState(
        saveId: 'fly',
        currentMapId: 'source',
        playerPosition: const GridPos(x: 1, y: 1),
        playerMovementMode: MovementMode.surf,
        party: const PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'pidgeot',
              natureId: 'hardy',
              abilityId: 'keen_eye',
              level: 20,
              currentHp: 30,
              knownMoveIds: ['fly'],
              currentPpByMoveId: {'fly': 0},
            ),
          ],
        ),
        progression: const PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.fly],
        ),
        narrativeEventProgress: NarrativeEventProgress(
          visitedNarrativeMapIds: {'target'},
        ),
      );
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: {},
    manifest: manifest,
    map: state.currentMapId == 'target' ? target : source,
  );
  var gameMounted = false;
  final game = PlayableMapGame(
    projectAudio: projectAudio,
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    beforeMapMount: beforeMapMount,
    saveData: saveDataFromGameState(state),
    saveRepository: save,
    dialogueSessionLoader: (_) async =>
        throw StateError('Dialogue failed after Fly'),
    initialMapActivationReason: restored == null
        ? MapActivationReason.initialBoot
        : MapActivationReason.saveRestore,
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async {
          if (paths.containsKey('target-sheet')) {
            if (targetImagesEntered != null &&
                !targetImagesEntered.isCompleted) {
              targetImagesEntered.complete();
            }
            await targetImagesGate?.future;
            if (rejection == 'visual') {
              throw StateError('Target visuals failed');
            }
          }
          return {};
        },
    runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
      if (rejection == 'load' && mapId == 'target') {
        throw StateError('Target load failed');
      }
      return bundle.copyWith(
        map: mapId == 'target' ? target : source,
        tilesetAbsolutePathsById:
            mapId == 'target' &&
                (targetImagesGate != null || rejection == 'visual')
            ? {'target-sheet': '${root.path}/target.png'}
            : {},
      );
    },
    beforeNarrativeAuthorityPreparation: (occurrence) async {
      if (gameMounted &&
          occurrence.source.toJson()['mapId'] ==
              (sameMapDestination ? 'source' : 'target')) {
        sawTarget?.call();
        if (rejection == 'activation') {
          throw StateError('Target activation failed after swap');
        }
      }
    },
    runtimePlayerPokemonProgressionCatalogLoader:
        ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async => const RuntimePlayerPokemonProgressionCatalogs(
          speciesById: {
            'pidgeot': PlayerPokemonHydrationSpecies(
              id: 'pidgeot',
              baseStats: PokemonBaseStats(
                hp: 83,
                attack: 80,
                defense: 75,
                specialAttack: 70,
                specialDefense: 70,
                speed: 101,
              ),
              primaryAbilityId: 'keen_eye',
              abilityIds: ['keen_eye'],
              growthRateId: 'medium_slow',
            ),
          },
          maxPpByMoveId: {'fly': 15},
        ),
  );
  final services = PlayerServiceRuntimeController.contextual(
    currentGameState: () => game.playerServiceGameStateSnapshot,
    commitAndSave: game.commitAndSavePlayerServiceState,
    setInputLocked: (locked) => game.setExternalInputLock(
      RuntimeExternalInputLock.playerService,
      locked: locked,
    ),
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
  );
  game.setPlayerServiceRuntimeController(services);
  addTearDown(services.dispose);
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
  if (restored == null) game.setPlayerMovementMode(state.playerMovementMode);
  gameMounted = true;
  return (game: game, controller: services);
}

SceneAsset flyScene(bool fails) => SceneAsset(
  id: 'fly-scene',
  name: 'Fly scene',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'map',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.openRegionalMap(),
        ),
      ),
      if (fails)
        SceneNode(
          id: 'after',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'after',
            yarnNodeName: 'Start',
            expectedOutcomes: ['done'],
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'map',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'cancelled'])
        SceneEdge(
          id: 'map-$port',
          fromNodeId: 'map',
          fromPortId: port,
          toNodeId: fails ? 'after' : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      if (fails)
        SceneEdge(
          id: 'after-done',
          fromNodeId: 'after',
          fromPortId: 'done',
          toNodeId: 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);
