import 'dart:convert';
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
      'Whirlpool $answer crosses the canonical route through physical steps',
      (tester) async {
        await tester.runAsync(() async {
          final movements = <RuntimeCommittedMovement>[];
          final game = await mountWhirlpool(tester, onMovement: movements.add);
          final before = game.gameStateSnapshot;
          await openWhirlpool(game);
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
          expect(
            movements.map((m) => m.movement.toCell).toList(),
            answer == 'yes'
                ? const [
                    GridPos(x: 2, y: 3),
                    GridPos(x: 2, y: 2),
                    GridPos(x: 2, y: 1),
                  ]
                : isEmpty,
          );
          expect(game.gameStateSnapshot.party, before.party);
          if (answer == 'yes') {
            expect(game.playerMovementMode, MovementMode.surf);
            expect(game.gameStateSnapshot.progression, before.progression);
            expect(game.canCapturePlayerCheckpoint, isTrue);
            expect(await game.saveGame(), isTrue);
            expect(await game.loadGame(), isTrue);
            await helpers.tickUntil(
              game,
              () => !game.debugIsMapActivationDispatchInFlight,
            );
            expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
            expect(game.playerMovementMode, MovementMode.surf);
            final cold = await mountWhirlpool(
              tester,
              initial: GameState.fromJson(game.gameStateSnapshot.toJson()),
            );
            expect(cold.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
            expect(cold.playerMovementMode, MovementMode.surf);
            await helpers.press(cold, RuntimeInputControl.up);
            await helpers.tickUntil(cold, () => !cold.debugIsPlayerStepping);
            expect(cold.debugPlayerGridPosition, const GridPos(x: 2, y: 0));
            expect(cold.playerMovementMode, MovementMode.walk);
          }
        });
      },
    );
  }

  for (final gate in [
    'move',
    'ko',
    'unlock',
    'surf',
    'direction',
    'obstacle',
  ]) {
    testWidgets('Whirlpool refuses $gate without moving or consuming PP', (
      tester,
    ) async {
      await tester.runAsync(() async {
        var state = whirlpoolState();
        if (gate == 'move' || gate == 'ko') {
          state = state.copyWith(
            party: state.party.copyWith(
              members: [
                state.party.members.single.copyWith(
                  knownMoveIds: gate == 'move'
                      ? const ['surf']
                      : const ['whirlpool'],
                  currentPpByMoveId: gate == 'move'
                      ? const {'surf': 15}
                      : const {'whirlpool': 0},
                  currentHp: gate == 'ko' ? 0 : 30,
                ),
              ],
            ),
          );
        }
        if (gate == 'unlock') {
          state = state.copyWith(progression: const PlayerProgression());
        }
        if (gate == 'direction') {
          state = state.copyWith(playerFacing: EntityFacing.east);
        }
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWhirlpool(
          tester,
          initial: state,
          onMovement: movements.add,
          entities: gate == 'obstacle'
              ? const [
                  MapEntity(
                    id: 'wall',
                    kind: MapEntityKind.npc,
                    pos: GridPos(x: 2, y: 2),
                    blocksMovement: true,
                    npc: MapEntityNpcData(),
                  ),
                ]
              : const [],
        );
        if (gate == 'surf') game.setPlayerMovementMode(MovementMode.walk);
        final before = game.gameStateSnapshot;
        await openWhirlpool(game);
        await helpers.tickUntil(
          game,
          () => game.debugFlowPhaseName == 'overworld',
        );
        expect(game.debugPlayerGridPosition, before.playerPosition);
        expect(game.playerMovementMode, before.playerMovementMode);
        expect(game.gameStateSnapshot.party, before.party);
        expect(movements, isEmpty);
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      });
    });
  }

  testWidgets(
    'Whirlpool blocks checkpoint save load menu and input during interpolation',
    (tester) async {
      await tester.runAsync(() async {
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWhirlpool(tester, onMovement: movements.add);
        await startWhirlpool(game);
        expect(game.debugIsPlayerStepping, isTrue);
        expect(game.canCapturePlayerCheckpoint, isFalse);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.menu),
          ),
          isTrue,
        );
        final start = game.debugPlayerWorldTopLeft;
        game.update(.125);
        expect(game.debugPlayerWorldTopLeft.y, lessThan(start.y));
        expect(
          game.debugPlayerWorldTopLeft.y,
          greaterThan(
            game.debugWorldTopLeftForSpawnCell(const GridPos(x: 2, y: 3)).y,
          ),
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 4));
        expect(movements, isEmpty);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        );
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.canCapturePlayerCheckpoint, isTrue);
        await frames(game, 8);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
      });
    },
  );

  testWidgets(
    'Whirlpool interruption restores only the entry pose and can restart',
    (tester) async {
      await tester.runAsync(() async {
        final movements = <RuntimeCommittedMovement>[];
        late PlayableMapGame game;
        var interrupt = true;
        game = await mountWhirlpool(
          tester,
          initial: whirlpoolState().copyWith(
            repelState: RepelState.active(itemId: 'repel', steps: 100),
          ),
          onMovement: (movement) {
            movements.add(movement);
            if (interrupt) game.setPlayerMovementMode(MovementMode.walk);
          },
        );
        await startWhirlpool(game);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 4));
        expect(game.playerMovementMode, MovementMode.surf);
        expect(movements, hasLength(1));
        expect(game.gameStateSnapshot.repelState.remainingSteps, 99);
        expect(game.canCapturePlayerCheckpoint, isTrue);
        expect(await game.saveGame(), isTrue);
        interrupt = false;
        await startWhirlpool(game);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.playerMovementMode, MovementMode.surf);
        expect(movements, hasLength(4));
        expect(game.gameStateSnapshot.repelState.remainingSteps, 96);
        expect(game.debugEncounterCheckCount, 1);
      });
    },
  );

  testWidgets(
    'Whirlpool reserves the player destination against a live scripted NPC',
    (tester) async {
      await tester.runAsync(() async {
        final game = await mountWhirlpool(
          tester,
          entities: const [
            MapEntity(
              id: 'walker',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 3, y: 3),
              blocksMovement: true,
              npc: MapEntityNpcData(characterId: 'walker-character'),
            ),
          ],
        );
        await startWhirlpool(game);
        expect(
          game.debugScriptedNpcDynamicBlockedCells(ignoreEntityId: 'walker'),
          contains(const GridPos(x: 2, y: 3)),
        );
        final move = game.startScriptedNpcMove(
          entityId: 'walker',
          destination: const GridPos(x: 2, y: 3),
        );
        await frames(game, 4);
        expect(
          game.debugMapEntityPosition('walker'),
          isNot(const GridPos(x: 2, y: 3)),
        );
        expect(move.state, isNot(ScriptedEntityMovementState.completed));
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
      });
    },
  );

  testWidgets(
    'Whirlpool ignores intermediate warps and resolves one final arrival',
    (tester) async {
      await tester.runAsync(() async {
        final movements = <RuntimeCommittedMovement>[];
        final game = await mountWhirlpool(
          tester,
          intermediateWarp: true,
          onMovement: movements.add,
        );
        await startWhirlpool(game);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.gameStateSnapshot.currentMapId, 'whirls');
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.playerMovementMode, MovementMode.surf);
        expect(movements, hasLength(3));
        expect(game.debugEncounterCheckCount, 1);
      });
    },
  );

  testWidgets('cold restore refuses a transient Whirlpool path position', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await expectLater(
        mountWhirlpool(
          tester,
          initial: whirlpoolState().copyWith(
            playerPosition: const GridPos(x: 2, y: 3),
            playerPixelPosition: null,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  testWidgets(
    'the public Whirlpool session pauses without advancing and completes at its entry',
    (tester) async {
      await tester.runAsync(() async {
        late PlayableMapGameSessionRuntime runtime;
        final game = await mountWhirlpool(
          tester,
          onSession: (value) => runtime = value,
        );
        await startWhirlpool(game);
        expect(await runtime.captureCheckpoint(), isNull);
        await expectLater(runtime.pause(), throwsA(isA<StateError>()));
        await runtime.setInputLock(
          RuntimeExternalInputLock.lifecycle,
          locked: true,
        );
        await runtime.pause();
        final before = game.debugPlayerWorldTopLeft;
        await tester.pump(const Duration(seconds: 1));
        expect(game.debugPlayerWorldTopLeft, before);
        expect(await runtime.captureCheckpoint(), isNull);
        await runtime.setInputLock(
          RuntimeExternalInputLock.lifecycle,
          locked: false,
        );
        await runtime.resume();
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        final checkpoint = await runtime.captureCheckpoint();
        expect(checkpoint, isNotNull);
        expect(
          gameStateFromStrictSaveJson(checkpoint!.state).playerPosition,
          const GridPos(x: 2, y: 1),
        );
        final restored = await mountWhirlpool(
          tester,
          initial: gameStateFromStrictSaveJson(checkpoint.state),
          onSession: (_) {},
        );
        expect(restored.playerMovementMode, MovementMode.surf);
        await helpers.press(game, RuntimeInputControl.down);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        game.onRemove();
        late PlayableMapGameSessionRuntime completionRuntime;
        final completing = await mountWhirlpool(
          tester,
          onSession: (value) => completionRuntime = value,
        );
        await startWhirlpool(completing);
        final events = <GameSessionAdapterEvent>[];
        final subscription = completionRuntime.events.listen(events.add);
        addTearDown(subscription.cancel);
        await completionRuntime.emitCompletion(
          const GameCompletionRequest(
            endingId: 'whirlpool-ending',
            outcome: GameCompletionOutcome.completed,
            result: GameResultSnapshot(
              title: 'Fin',
              summary: 'Traversée interrompue',
            ),
            credits: GameCreditsSnapshot(
              title: 'Tourbillon',
              author: 'PokeMap',
              endingLabel: 'Fin',
            ),
            destination: GameCompletionDestination.hub,
            allowPostGameContinue: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        final finalState = gameStateFromStrictSaveJson(
          events
              .whereType<GameSessionCompleted>()
              .single
              .completion
              .finalCheckpoint
              .state,
        );
        expect(finalState.playerPosition, const GridPos(x: 2, y: 4));
        expect(finalState.playerMovementMode, MovementMode.surf);
        expect(completing.debugIsPlayerStepping, isFalse);
        expect(
          completing.debugScriptedNpcDynamicBlockedCells(),
          isNot(contains(const GridPos(x: 2, y: 3))),
        );
      });
    },
  );
}

Future<void> frames(PlayableMapGame game, int count) async {
  for (var i = 0; i < count; i++) {
    game.update(.04);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> openWhirlpool(PlayableMapGame game) async {
  final request = game.overworldInteractionSnapshot.primaryAction?.request;
  expect(request, isNotNull);
  expect(request!.targetId, 'whirlpool');
  expect(game.dispatchOverworldInteraction(request), isTrue);
  await frames(game, 8);
  await helpers.press(game, RuntimeInputControl.primary);
}

Future<void> startWhirlpool(PlayableMapGame game) async {
  await openWhirlpool(game);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
  game.update(.016);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

GameState whirlpoolState() => const GameState(
  saveId: '00000000-0000-4000-8000-000000000027',
  currentMapId: 'whirls',
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
        knownMoveIds: ['whirlpool'],
        currentPpByMoveId: {'whirlpool': 0},
      ),
    ],
  ),
  progression: PlayerProgression(
    unlockedFieldAbilities: [FieldAbility.whirlpool],
  ),
);

Future<PlayableMapGame> mountWhirlpool(
  WidgetTester tester, {
  GameState? initial,
  List<MapEntity> entities = const [],
  void Function(RuntimeCommittedMovement)? onMovement,
  void Function(PlayableMapGameSessionRuntime)? onSession,
  bool intermediateWarp = false,
}) async {
  final root = await Directory.systemTemp.createTemp('whirlpool-player-');
  addTearDown(() => root.delete(recursive: true));
  final zone = MapGameplayZone.fromJson(
    jsonDecode(
      await File('../map_core/test/fixtures/whirlpool_field_zone.json')
          .readAsString(),
    ) as Map<String, dynamic>,
  );
  final map = MapData(
    id: 'whirls',
    name: 'Whirls',
    size: const GridSize(width: 8, height: 8),
    entities: [
      const MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        blocksMovement: false,
        pos: GridPos(x: 2, y: 4),
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.north,
        ),
      ),
      ...entities,
    ],
    warps: [
      if (intermediateWarp)
        const MapWarp(
          id: 'intermediate',
          pos: GridPos(x: 2, y: 3),
          targetMapId: 'neighbor',
          targetPos: GridPos(x: 1, y: 1),
        ),
    ],
    gameplayZones: [
      zone,
      const MapGameplayZone(
        id: 'water',
        kind: GameplayZoneKind.movement,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 3, height: 4),
        ),
        movement: MovementZonePayload(requiredMode: MovementMode.surf),
      ),
    ],
  );
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    map: map,
    manifest: ProjectManifest(
      name: 'Whirlpool Player',
      tilesets: const [],
      characters: const [
        ProjectCharacterEntry(
          id: 'walker-character',
          name: 'Walker',
          tilesetId: 'walker-sheet',
        ),
      ],
      maps: const [
        ProjectMapEntry(
          id: 'neighbor',
          name: 'Neighbor',
          relativePath: 'maps/neighbor.json',
        ),
        ProjectMapEntry(
          id: 'whirls',
          name: 'Whirls',
          relativePath: 'maps/whirls.json',
        ),
      ],
    ),
  );
  Future<void> mount(PlayableMapGame game) async {
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
  }

  late PlayableMapGame game;
  if (onSession != null) {
    final data = Directory('${root.path}/data/pokemon');
    await Directory('${data.path}/catalogs').create(recursive: true);
    await Directory('${data.path}/species').create(recursive: true);
    await Directory('${data.path}/learnsets').create(recursive: true);
    const sourceRoot =
        '../../examples/playable_runtime_host/golden_battle_slice/data/pokemon';
    final moves = jsonDecode(
      await File('$sourceRoot/catalogs/moves.json').readAsString(),
    ) as Map<String, dynamic>;
    final move = Map<String, dynamic>.from(
      (moves['entries'] as List).first as Map,
    );
    move['id'] = 'whirlpool';
    move['pp'] = 20;
    await File('${data.path}/catalogs/moves.json').writeAsString(
      jsonEncode({
        ...moves,
        'entries': [move],
      }),
    );
    final species = jsonDecode(
      await File('$sourceRoot/species/004-sparkitten.json').readAsString(),
    ) as Map<String, dynamic>;
    species['id'] = 'pikachu';
    species['slug'] = 'pikachu';
    species['abilities'] = {'primary': 'static'};
    await File('${data.path}/species/pikachu.json')
        .writeAsString(jsonEncode(species));
    await File('$sourceRoot/learnsets/sparkitten.json')
        .copy('${data.path}/learnsets/sparkitten.json');
    final identity = GameIdentity(
      gameId: 'org.example.whirlpool',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v1,
      saveFormat: 1,
      compatibilityId: 'whirlpool-v1',
    );
    final date = DateTime.utc(2026, 10, 20);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: 'player',
      slotId: 'slot',
      saveId: (initial ?? whirlpoolState()).saveId,
      createdAt: date,
      updatedAt: date,
      status: SaveStatus.active,
      playTimeSeconds: 0,
      gameState: initial ?? whirlpoolState(),
    );
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: GameSessionDescriptor(
        sessionId: 'whirlpool-session',
        sessionToken: 'secret',
        identity: identity,
        profileId: 'player',
        slotId: 'slot',
        launchMode: GameSessionLaunchMode.continueGame,
        installedVersionHandle: 'fixture',
        saveReadHandle: 'save',
        runtimeApiVersion: '1.0.0',
        grantedCapabilities: const {'map.v1'},
        locale: 'fr-FR',
        accessibility: const GameSessionAccessibilityOptions(),
      ),
      projectFilePath: () async => '${root.path}/project.json',
      initialSave: () async => save,
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountGame: (value) async {
        game = value;
        await mount(game);
      },
      unmountGame: (_) async => tester.pumpWidget(const SizedBox.shrink()),
      now: () => date,
    );
    addTearDown(runtime.dispose);
    await runtime.load((_) {});
    await runtime.resume();
    onSession(runtime);
  } else {
    game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: '${root.path}/project.json',
      saveData: saveDataFromGameState(initial ?? whirlpoolState()),
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
            maxPpByMoveId: {'whirlpool': 20, 'surf': 15},
          ),
    );
    addTearDown(game.onRemove);
    await mount(game);
  }
  await helpers.tickUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
  game.update(.016);
  await Future<void>.delayed(const Duration(milliseconds: 1));
  return game;
}
