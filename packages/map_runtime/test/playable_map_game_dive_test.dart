import 'dart:async';
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
  testWidgets(
    'cold restore validates the saved pixel pose instead of the blocked cell center',
    (tester) async {
      await tester.runAsync(() async {
        final sea = diveMap('sea', DiveZoneRole.surface);
        final map = sea.copyWith(
          entities: [
            ...sea.entities,
            const MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 2),
              npc: MapEntityNpcData(),
            ),
          ],
        );
        final centered = GameplayWorldState.initial(
          map: map,
          playerPos: const GridPos(x: 2, y: 2),
          playerMovementMode: MovementMode.surf,
        );
        final pose = centered.withPlayer(
          centered.player.copyWith(
            playerPositionPx: const PixelPosition(leftPx: 24, topPx: 8),
          ),
        );
        expect(isDiveEndpointPoseSafe(world: centered), isFalse);
        expect(isDiveEndpointPoseSafe(world: pose), isTrue);
        expect(pose.player.pos, const GridPos(x: 2, y: 2));
        final normal = await mountDive(tester);
        final state = normal.gameStateSnapshot.copyWith(
          playerPixelPosition: const PixelOffset(x: 24, y: 8),
        );
        final restored = await mountDive(
          tester,
          restored: state,
          seaOverride: map,
        );
        expect(
          restored.gameStateSnapshot.playerPixelPosition,
          state.playerPixelPosition,
        );
        for (final offset in [null, const PixelOffset(x: 40, y: 16)]) {
          await expectLater(
            mountDive(
              tester,
              restored: state.copyWith(playerPixelPosition: offset),
              seaOverride: map,
            ),
            throwsA(isA<StateError>()),
          );
        }
      });
    },
  );
  testWidgets(
    'a newer destination pose during Dive fade in keeps ownership of the world',
    (tester) async {
      await tester.runAsync(() async {
        final game = await mountDive(tester);
        var done = false;
        final transfer = confirmDive(game).whenComplete(() => done = true);
        await helpers.tickUntil(
          game,
          () => game.gameStateSnapshot.currentMapId == 'deep',
        );
        expect(game.debugFlowPhaseName, 'mapTransition');
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 3, y: 2),
          facing: Direction.east,
          movementMode: MovementMode.dive,
        );
        final changed = game.gameStateSnapshot;
        await helpers.tickUntil(game, () => done);
        await transfer;
        expect(game.gameStateSnapshot, changed);
        expect(game.debugIsMapLoaded('deep'), isTrue);
        expect(game.debugRenderedPlayerFootCell, changed.playerPosition);
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      });
    },
  );
  for (final answer in ['yes', 'no', 'cancel', 'stale']) {
    testWidgets(
      'native Dive dialogue $answer transfers modes, preserves PP and cold returns',
      (tester) async {
        await tester.runAsync(() async {
          final save = helpers.MemorySave();
          final game = await mountDive(tester, save: save);
          final before = game.gameStateSnapshot;
          await confirmDive(game, answer: answer);
          if (answer != 'yes') {
            expect(game.gameStateSnapshot.currentMapId, 'sea');
            expect(
              game.gameStateSnapshot.playerPosition,
              before.playerPosition,
            );
            expect(game.gameStateSnapshot.party, before.party);
            return;
          }
          expect(game.gameStateSnapshot.currentMapId, 'deep');
          expect(game.playerMovementMode, MovementMode.dive);
          expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
          expect(game.gameStateSnapshot.party, before.party);
          expect(
            game.overworldInteractionSnapshot.primaryAction?.request.targetId,
            'point',
          );
          for (final direction in [EntityFacing.east, EntityFacing.west]) {
            var moved = false;
            final movement = game
                .movePlayerByForcedStep(
                  direction: direction,
                  expectedMapActivationId:
                      game.overworldInteractionSnapshot.mapActivationId,
                )
                .whenComplete(() => moved = true);
            await helpers.tickUntil(game, () => moved);
            expect(await movement, isTrue);
            expect(game.playerMovementMode, MovementMode.dive);
          }
          expect(await game.saveGame(), isTrue);
          final saved = await save.load();
          expect(saved!.playerMovementMode, MovementMode.dive);
          final cold = await mountDive(tester, restored: saved, save: save);
          expect(cold.playerMovementMode, MovementMode.dive);
          expect(
            cold.overworldInteractionSnapshot.primaryAction?.request.targetId,
            'point',
          );
          await confirmDive(cold);
          expect(cold.gameStateSnapshot.currentMapId, 'sea');
          expect(cold.playerMovementMode, MovementMode.surf);
        });
      },
    );
  }
  for (final failure in ['missing', 'blocked', 'mount']) {
    testWidgets(
      'Dive $failure refuses and retains the complete source checkpoint',
      (tester) async {
        await tester.runAsync(() async {
          final game = await mountDive(tester, failure: failure);
          final before = game.gameStateSnapshot;
          final activation = game.debugCompletedMapActivationDispatchCount;
          await confirmDive(game, available: failure == 'mount');
          expect(game.gameStateSnapshot, before);
          expect(game.debugIsMapLoaded('sea'), isTrue);
          expect(game.debugCompletedMapActivationDispatchCount, activation);
        });
      },
    );
  }
  for (final stage in ['visuals', 'mount']) {
    testWidgets(
      'Dive revalidates a changed source during $stage and preserves it on rollback',
      (tester) async {
        await tester.runAsync(() async {
          final entered = Completer<void>(), gate = Completer<void>();
          addTearDown(() {
            if (!gate.isCompleted) gate.complete();
          });
          final game = await mountDive(
            tester,
            visualGate: stage == 'visuals' ? gate : null,
            visualEntered: stage == 'visuals' ? entered : null,
            beforeMount: stage == 'mount'
                ? (id) async {
                    if (id == 'deep') {
                      if (!entered.isCompleted) entered.complete();
                      await gate.future;
                    }
                  }
                : null,
          );
          final before = game.gameStateSnapshot;
          var done = false;
          final transfer = confirmDive(game).whenComplete(() => done = true);
          await helpers.tickUntil(game, () => entered.isCompleted);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 3, y: 2),
            facing: Direction.east,
            movementMode: MovementMode.surf,
          );
          final changed = game.gameStateSnapshot;
          gate.complete();
          await helpers.tickUntil(game, () => done);
          await transfer;
          expect(game.gameStateSnapshot, changed);
          expect(game.gameStateSnapshot.party, before.party);
          expect(game.debugIsMapLoaded('sea'), isTrue);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
        });
      },
    );
  }
  testWidgets('return action rechecks an occupied surface after cold restore', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final save = helpers.MemorySave();
      final game = await mountDive(tester, save: save);
      await confirmDive(game);
      await game.saveGame();
      final state = await save.load();
      final cold = await mountDive(
        tester,
        restored: state,
        surfaceBlocked: true,
      );
      final before = cold.gameStateSnapshot;
      await confirmDive(cold, available: false);
      expect(cold.gameStateSnapshot, before);
      expect(cold.playerMovementMode, MovementMode.dive);
    });
  });
  testWidgets(
    'cold Dive rejects incompatible terrain without rewriting the save',
    (tester) async {
      await tester.runAsync(() async {
        final save = helpers.MemorySave();
        final game = await mountDive(tester, save: save);
        await confirmDive(game);
        await game.saveGame();
        final saved = await save.load();
        await expectLater(
          mountDive(tester, save: save, restored: saved, failure: 'terrain'),
          throwsA(isA<StateError>()),
        );
        expect(await save.load(), saved);
      });
    },
  );
}

Future<void> confirmDive(
  PlayableMapGame game, {
  String answer = 'yes',
  bool available = true,
}) async {
  final request = game.overworldInteractionSnapshot.primaryAction?.request;
  expect(request, isNotNull);
  expect(game.dispatchOverworldInteraction(request!), isTrue);
  await helpers.tickUntil(game, () => game.debugFlowPhaseName == 'dialogue');
  for (var i = 0; i < 8; i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  await helpers.press(game, RuntimeInputControl.primary);
  if (!available) {
    return;
  }
  if (answer == 'no') await helpers.press(game, RuntimeInputControl.down);
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
        !game.debugHasPendingMapTransition &&
        game.inputAuthoritySnapshot.acceptsOverworldInput,
  );
}

MapData diveMap(
  String id,
  DiveZoneRole role, {
  bool blocked = false,
  bool invalidTerrain = false,
}) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 8, height: 8),
  entities: [
    MapEntity(
      id: '$id-spawn',
      kind: MapEntityKind.spawn,
      blocksMovement: false,
      pos: const GridPos(x: 2, y: 2),
      spawn: const MapEntitySpawnData(),
    ),
    if (blocked)
      const MapEntity(
        id: 'rock',
        kind: MapEntityKind.sign,
        pos: GridPos(x: 2, y: 2),
        sign: MapEntitySignData(),
      ),
  ],
  gameplayZones: [
    if (!invalidTerrain)
      MapGameplayZone(
        id: 'terrain',
        kind: GameplayZoneKind.movement,
        area: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 8, height: 8),
        ),
        movement: MovementZonePayload(
          requiredMode: role == DiveZoneRole.surface
              ? MovementMode.surf
              : MovementMode.dive,
        ),
      ),
    MapGameplayZone(
      id: 'point',
      kind: GameplayZoneKind.fieldAction,
      area: const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
      fieldAction: FieldActionZonePayload(
        actionKind: FieldActionZoneKind.dive,
        dive: DiveZonePayload(
          role: role,
          arrivalSpawnId: '$id-spawn',
          link: DiveZoneLink(
            mapId: id == 'sea' ? 'deep' : 'sea',
            zoneId: 'point',
          ),
        ),
      ),
    ),
  ],
);
Future<PlayableMapGame> mountDive(
  WidgetTester tester, {
  GameState? restored,
  String? failure,
  helpers.MemorySave? save,
  Future<void> Function(String)? beforeMount,
  Completer<void>? visualGate,
  Completer<void>? visualEntered,
  bool surfaceBlocked = false,
  MapData? seaOverride,
  ProjectFieldAbilitiesSettings? fieldAbilities,
}) async {
  final root = await Directory.systemTemp.createTemp('native-dive-player-');
  addTearDown(() => root.delete(recursive: true));
  final sea =
      seaOverride ??
      diveMap('sea', DiveZoneRole.surface, blocked: surfaceBlocked);
  final deep = diveMap(
    'deep',
    DiveZoneRole.underwater,
    blocked: failure == 'blocked',
    invalidTerrain: failure == 'terrain',
  );
  final manifest = ProjectManifest(
    name: 'Dive Player',
    settings: ProjectSettings(fieldAbilities: fieldAbilities),
    tilesets: const [],
    maps: const [
      ProjectMapEntry(id: 'sea', name: 'Sea', relativePath: 'maps/sea.json'),
      ProjectMapEntry(id: 'deep', name: 'Deep', relativePath: 'maps/deep.json'),
    ],
  );
  final state =
      restored ??
      const GameState(
        saveId: 'dive',
        currentMapId: 'sea',
        playerPosition: GridPos(x: 2, y: 2),
        playerFacing: EntityFacing.south,
        playerMovementMode: MovementMode.surf,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'pikachu',
              natureId: 'hardy',
              abilityId: 'static',
              level: 20,
              currentHp: 30,
              knownMoveIds: ['dive'],
              currentPpByMoveId: {'dive': 0},
            ),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.dive],
        ),
      );
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    manifest: manifest,
    map: state.currentMapId == 'deep' ? deep : sea,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: MapActivationReason.saveRestore,
    saveRepository: save ?? helpers.MemorySave(),
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async {
          if (paths.containsKey('deep-sheet')) {
            if (visualEntered != null && !visualEntered.isCompleted) {
              visualEntered.complete();
            }
            await visualGate?.future;
          }
          return {};
        },
    runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
      if (mapId == 'deep' && failure == 'missing') {
        throw StateError('Absent destination');
      }
      return bundle.copyWith(
        map: mapId == 'sea' ? sea : deep,
        tilesetAbsolutePathsById: mapId == 'deep' && visualGate != null
            ? {'deep-sheet': '${root.path}/deep.png'}
            : {},
      );
    },
    beforeMapMount: (mapId) async {
      await beforeMount?.call(mapId);
      if (mapId == 'deep' && failure == 'mount') {
        throw StateError('Interrupted mounting');
      }
    },
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
          maxPpByMoveId: {'dive': 20},
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
