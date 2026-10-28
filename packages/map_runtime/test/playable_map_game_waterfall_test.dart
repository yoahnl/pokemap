import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final answer in ['yes', 'no', 'cancel', 'stale']) {
    testWidgets(
      'normal Cascade dialogue $answer uses finite steps and a single final arrival',
      (tester) async {
        await helpers.runWithFieldAudio(tester, (fieldAudio) async {
          final movements = <RuntimeCommittedMovement>[];
          final game = await mountWaterfall(
            tester,
            onMovement: movements.add,
            projectAudio: fieldAudio.audio,
          );
          final before = game.gameStateSnapshot;
          final request =
              game.overworldInteractionSnapshot.primaryAction?.request;
          expect(request, isNotNull);
          expect(game.dispatchOverworldInteraction(request!), isTrue);
          for (var i = 0; i < 8; i++) {
            game.update(.016);
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          await helpers.press(game, RuntimeInputControl.primary);
          if (answer == 'no') {
            await helpers.press(game, RuntimeInputControl.down);
          }
          if (answer == 'stale') game.setPlayerMovementMode(MovementMode.walk);
          await helpers.press(
            game,
            answer == 'cancel'
                ? RuntimeInputControl.secondary
                : RuntimeInputControl.primary,
          );
          await helpers.tickUntil(
            game,
            () =>
                game.debugFlowPhaseName == 'overworld' &&
                game.inputAuthoritySnapshot.acceptsOverworldInput,
          );
          expect(
            game.debugPlayerGridPosition,
            answer == 'yes' ? const GridPos(x: 2, y: 1) : before.playerPosition,
          );
          expect(movements.length, answer == 'yes' ? 3 : 0);
          await Future<void>.delayed(Duration.zero);
          expect(
            fieldAudio.driver.paths.where((path) => path == 'fieldWaterfall'),
            hasLength(answer == 'yes' ? 1 : 0),
          );
          expect(game.gameStateSnapshot.party, before.party);
          if (answer == 'yes') {
            expect(game.playerMovementMode, MovementMode.walk);
            expect(await game.saveGame(), isTrue);
            final cold = await mountWaterfall(
              tester,
              restored: GameState.fromJson(game.gameStateSnapshot.toJson()),
            );
            expect(cold.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
          }
        });
      },
    );
  }
  testWidgets(
    'Cascade suppresses the intermediate warp and resolves its exit warp once',
    (tester) async {
      await tester.runAsync(() async {
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWaterfall(
          tester,
          onMovement: movements.add,
          finalWarp: true,
        );
        expect(
          game.dispatchOverworldInteraction(
            game.overworldInteractionSnapshot.primaryAction!.request,
          ),
          isTrue,
        );
        for (var i = 0; i < 8; i++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await helpers.press(game, RuntimeInputControl.primary);
        await helpers.press(game, RuntimeInputControl.primary);
        await helpers.tickUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId == 'neighbor' &&
              !game.debugHasPendingMapTransition,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(
          movements.map((movement) => movement.movement.toCell).toList(),
          const [GridPos(x: 2, y: 3), GridPos(x: 2, y: 2), GridPos(x: 2, y: 1)],
        );
        expect(game.playerMovementMode, MovementMode.walk);
      });
    },
  );
  testWidgets(
    'Cascade refuses dispatch during a compensable Scene transaction',
    (tester) async {
      await tester.runAsync(() async {
        final scene = SceneAsset(
          id: 'wait-scene',
          name: 'Wait',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'wait',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload(
                  interactiveCommand: SceneInteractiveCommand.wait(
                    durationMs: 500,
                  ),
                ),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'start-wait',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'wait',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'wait-end',
                fromNodeId: 'wait',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
        );
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWaterfall(
          tester,
          onMovement: movements.add,
          scene: scene,
        );
        final request =
            game.overworldInteractionSnapshot.primaryAction!.request;
        var finished = false;
        final execution = game
            .debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'event',
                sceneId: scene.id,
                executionId: 'cascade-refusal',
                gameState: game.gameStateSnapshot,
              ),
            )
            .then((value) {
              finished = true;
              return value;
            });
        await helpers.tickUntil(
          game,
          () => !game.inputAuthoritySnapshot.acceptsOverworldInput || finished,
        );
        expect(finished, isFalse);
        expect(game.dispatchOverworldInteraction(request), isFalse);
        expect(movements, isEmpty);
        await helpers.tickUntil(game, () => finished);
        expect(await execution, isA<NarrativeSceneExecutionCompleted>());
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 4));
      });
    },
  );
  testWidgets('cold restore refuses a saved intermediate Cascade pose', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await mountWaterfall(tester);
      final invalid = game.gameStateSnapshot.copyWith(
        playerPosition: const GridPos(x: 2, y: 3),
        playerPixelPosition: null,
      );
      await expectLater(
        mountWaterfall(tester, restored: invalid),
        throwsA(isA<StateError>()),
      );
    });
  });
  testWidgets(
    'completed Cascade step remains accounted when following step invalidates',
    (tester) async {
      await tester.runAsync(() async {
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWaterfall(tester, onMovement: movements.add);
        expect(
          game.dispatchOverworldInteraction(
            game.overworldInteractionSnapshot.primaryAction!.request,
          ),
          isTrue,
        );
        for (var i = 0; i < 8; i++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await helpers.press(game, RuntimeInputControl.primary);
        game.handleRuntimeInputEvent(
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        game.update(.016);
        game.handleRuntimeInputEvent(
          RuntimeInputEvent.release(RuntimeInputControl.primary),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(game.debugIsPlayerStepping, isTrue);
        expect(movements, isEmpty);
        game.update(.25);
        expect(game.debugIsPlayerStepping, isTrue);
        expect(game.debugRenderedPlayerFootCell, const GridPos(x: 2, y: 3));
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 3));
        expect(movements, hasLength(1));
        expect(movements.single.movement.fromCell, const GridPos(x: 2, y: 4));
        expect(movements.single.movement.toCell, const GridPos(x: 2, y: 3));
        game.setPlayerMovementMode(MovementMode.walk);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 4));
        expect(game.playerMovementMode, MovementMode.surf);
        expect(
          movements.length,
          1,
          reason: 'Pose rollback must preserve the completed step and must not count the unfinished following step.',
        );
      });
    },
  );
  testWidgets(
    'unfinished Cascade step invalidation does not count its partial interpolation',
    (tester) async {
      await tester.runAsync(() async {
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWaterfall(tester, onMovement: movements.add);
        expect(
          game.dispatchOverworldInteraction(
            game.overworldInteractionSnapshot.primaryAction!.request,
          ),
          isTrue,
        );
        for (var i = 0; i < 8; i++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await helpers.press(game, RuntimeInputControl.primary);
        game.handleRuntimeInputEvent(
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        game.update(.016);
        game.handleRuntimeInputEvent(
          RuntimeInputEvent.release(RuntimeInputControl.primary),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(game.debugIsPlayerStepping, isTrue);
        expect(movements, isEmpty);
        game.update(.1);
        expect(game.debugIsPlayerStepping, isTrue);
        expect(movements, isEmpty);
        game.setPlayerMovementMode(MovementMode.walk);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 4));
        expect(game.playerMovementMode, MovementMode.surf);
        expect(
          movements.length,
          0,
          reason: 'A partial interpolation is not a completed physical step.',
        );
      });
    },
  );
  testWidgets(
    'interrupted traversal returns to the valid entry, counts completed steps and can restart',
    (tester) async {
      await helpers.runWithFieldAudio(tester, (fieldAudio) async {
        final movements = <RuntimeCommittedMovement>[];
        late PlayableMapGame game;
        Future<bool>? saveDuring;
        var interrupt = true;
        game = await mountWaterfall(
          tester,
          projectAudio: fieldAudio.audio,
          repelState: RepelState.active(itemId: 'repel', steps: 100),
          onMovement: (movement) {
            movements.add(movement);
            saveDuring = game.saveGame();
            if (interrupt) game.setPlayerMovementMode(MovementMode.walk);
          },
        );
        final party = game.gameStateSnapshot.party;
        Future<void> confirm() async {
          expect(
            game.dispatchOverworldInteraction(
              game.overworldInteractionSnapshot.primaryAction!.request,
            ),
            isTrue,
          );
          for (var i = 0; i < 8; i++) {
            game.update(.016);
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          await helpers.press(game, RuntimeInputControl.primary);
          await helpers.press(game, RuntimeInputControl.primary);
          await helpers.tickUntil(
            game,
            () => game.inputAuthoritySnapshot.acceptsOverworldInput,
          );
        }

        await confirm();
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 4));
        expect(game.playerMovementMode, MovementMode.surf);
        expect(movements.length, 1);
        expect(game.gameStateSnapshot.repelState.remainingSteps, 99);
        expect(await saveDuring, isFalse);
        expect(game.gameStateSnapshot.party, party);
        await Future<void>.delayed(Duration.zero);
        expect(
          fieldAudio.driver.paths.where((path) => path == 'fieldWaterfall'),
          isEmpty,
        );
        interrupt = false;
        await confirm();
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(movements.length, 4);
        expect(game.gameStateSnapshot.repelState.remainingSteps, 96);
        expect(game.debugEncounterCheckCount, 1);
        await Future<void>.delayed(Duration.zero);
        expect(
          fieldAudio.driver.paths.where((path) => path == 'fieldWaterfall'),
          hasLength(1),
        );
      });
    },
  );
}

Future<PlayableMapGame> mountWaterfall(
  WidgetTester tester, {
  GameState? restored,
  SceneAsset? scene,
  bool finalWarp = false,
  RepelState? repelState,
  void Function(RuntimeCommittedMovement)? onMovement,
  ProjectFieldAbilitiesSettings? fieldAbilities,
  RuntimeProjectAudioController? projectAudio,
}) async {
  final root = await Directory.systemTemp.createTemp('native-flash-player-');
  addTearDown(() => root.delete(recursive: true));
  final cave = MapData(
    id: 'falls',
    name: 'Falls',
    size: const GridSize(width: 8, height: 8),
    entities: const [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        blocksMovement: false,
        pos: GridPos(x: 2, y: 4),
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.north,
        ),
      ),
    ],
    warps: [
      if (finalWarp)
        const MapWarp(
          id: 'exit',
          pos: GridPos(x: 2, y: 1),
          targetMapId: 'neighbor',
          targetPos: GridPos(x: 1, y: 1),
        ),
      const MapWarp(
        id: 'intermediate',
        pos: GridPos(x: 2, y: 3),
        targetMapId: 'neighbor',
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    gameplayZones: const [
      MapGameplayZone(
        id: 'water',
        kind: GameplayZoneKind.movement,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 3),
        ),
        movement: MovementZonePayload(requiredMode: MovementMode.surf),
      ),
      MapGameplayZone(
        id: 'fall',
        kind: GameplayZoneKind.fieldAction,
        area: MapRect(
          pos: GridPos(x: 2, y: 1),
          size: GridSize(width: 1, height: 4),
        ),
        fieldAction: FieldActionZonePayload(
          actionKind: FieldActionZoneKind.waterfall,
          waterfall: WaterfallZonePayload(
            entry: GridPos(x: 0, y: 3),
            path: [GridPos(x: 0, y: 2), GridPos(x: 0, y: 1)],
            exit: GridPos(x: 0, y: 0),
            direction: MapConnectionDirection.north,
          ),
        ),
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Cascade Player',
    settings: ProjectSettings(fieldAbilities: fieldAbilities),
    scenes: [?scene],
    eventRegistry: scene == null
        ? null
        : NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: const [],
            legacyClaims: const [],
          ),
    tilesets: const [],
    maps: const [
      ProjectMapEntry(
        id: 'falls',
        name: 'Cave',
        relativePath: 'maps/cave.json',
      ),
      ProjectMapEntry(
        id: 'neighbor',
        name: 'Neighbor',
        relativePath: 'maps/neighbor.json',
      ),
    ],
  );
  final initialState =
      restored ??
      const GameState(
        saveId: 'flash-player',
        currentMapId: 'falls',
        playerPosition: GridPos(x: 2, y: 4),
        playerFacing: EntityFacing.north,
        playerMovementMode: MovementMode.surf,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'pikachu',
              natureId: 'hardy',
              abilityId: 'static',
              level: 20,
              currentHp: 30,
              knownMoveIds: ['waterfall'],
              currentPpByMoveId: {'waterfall': 0},
            ),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.waterfall],
        ),
      );
  final state = repelState == null
      ? initialState
      : initialState.copyWith(repelState: repelState);
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    manifest: manifest,
    map: cave,
  );
  final game = PlayableMapGame(
    projectAudio: projectAudio,
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: MapActivationReason.saveRestore,
    runtimeTilesetImageLoader: (
      paths, {
      transparentColorByTilesetId = const {},
    }) async => {},
    runtimeMapBundleLoader:
        ({required projectFilePath, required mapId}) async => bundle.copyWith(
          map: mapId == 'falls'
              ? cave
              : MapData(
                  id: mapId,
                  name: 'Neighbor',
                  size: const GridSize(width: 8, height: 8),
                ),
        ),
    saveRepository: helpers.MemorySave(),
    onCommittedMovement: onMovement,
    runtimePlayerPokemonProgressionCatalogLoader:
        ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async => const RuntimePlayerPokemonProgressionCatalogs(
          speciesById: {
            'pikachu': PlayerPokemonHydrationSpecies(
              id: 'pikachu',
              baseStats: PokemonBaseStats(
                hp: 35,
                attack: 55,
                defense: 40,
                specialAttack: 50,
                specialDefense: 50,
                speed: 90,
              ),
              primaryAbilityId: 'static',
              abilityIds: ['static'],
              growthRateId: 'medium_fast',
            ),
          },
          maxPpByMoveId: {'waterfall': 20},
        ),
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(320, 240));
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
  game.update(.016);
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await helpers.tickUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
  game.update(.016);
  return game;
}
