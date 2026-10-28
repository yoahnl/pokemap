import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'cold restore refuses orphaned illumination on a retained inactive map',
    (tester) async {
      await tester.runAsync(() async {
        final restored = GameState(
          saveId: 'retained-flash',
          currentMapId: 'cave',
          playerPosition: const GridPos(x: 1, y: 1),
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              'cave': MapInstanceRuntimeState(
                instanceId: 'cave-one',
                illuminatedZoneIds: {'dark'},
              ),
              'neighbor': MapInstanceRuntimeState(
                instanceId: 'neighbor-one',
                illuminatedZoneIds: {'deleted-darkness-zone'},
              ),
            },
          ),
        );
        await expectLater(
          mountFlash(tester, restored: restored, retainInstances: true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('neighbor/deleted-darkness-zone'),
            ),
          ),
        );
      });
    },
  );
  testWidgets(
    'cold restore accepts valid retained instances without resetting illumination',
    (tester) async {
      await tester.runAsync(() async {
        final restored = GameState(
          saveId: 'retained-flash',
          currentMapId: 'cave',
          playerPosition: const GridPos(x: 1, y: 1),
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              'cave': MapInstanceRuntimeState(
                instanceId: 'cave-one',
                illuminatedZoneIds: {'dark'},
              ),
              'neighbor': MapInstanceRuntimeState(instanceId: 'neighbor-one'),
            },
          ),
        );
        final game = await mountFlash(
          tester,
          restored: restored,
          retainInstances: true,
        );
        final saved = game.gameStateSnapshot.mapInstanceWorldState;
        expect(
          saved.isZoneIlluminated(saved.instanceRef('cave')!, 'dark'),
          isTrue,
        );
        expect(await worldPixelIntensity(game), greaterThan(240));
      });
    },
  );
  for (final answer in ['yes', 'no', 'cancel', 'stale']) {
    testWidgets(
      'mounted Flash $answer resolves through real Player dialogue and pixels',
      (tester) async {
        await tester.runAsync(() async {
          final game = await mountFlash(tester);
          final state = game.gameStateSnapshot;
          expect(state.mapInstanceWorldState.instanceRef('cave'), isNotNull);
          expect(await worldPixelIntensity(game), lessThan(100));
          final request =
              game.overworldInteractionSnapshot.primaryAction?.request;
          expect(request, isNotNull);
          expect(game.dispatchOverworldInteraction(request!), isTrue);
          for (var i = 0; i < 8; i++) {
            game.update(.016);
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          await press(game, RuntimeInputControl.primary);
          if (answer == 'no') await press(game, RuntimeInputControl.down);
          if (answer == 'stale') game.setPlayerMovementMode(MovementMode.surf);
          await press(
            game,
            answer == 'cancel'
                ? RuntimeInputControl.secondary
                : RuntimeInputControl.primary,
          );
          await tickUntil(game, () => game.debugFlowPhaseName == 'overworld');
          final saved = game.gameStateSnapshot;
          final scope = saved.mapInstanceWorldState.instanceRef('cave')!;
          expect(
            saved.mapInstanceWorldState.isZoneIlluminated(scope, 'dark'),
            answer == 'yes',
          );
          expect(saved.party, state.party);
          expect(
            await worldPixelIntensity(game),
            answer == 'yes' ? greaterThan(240) : lessThan(100),
          );
          if (answer == 'yes') {
            expect(game.dispatchOverworldInteraction(request), isFalse);
            expect(await game.saveGame(), isTrue);
            final cold = GameState.fromJson(
              jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
            );
            final restored = await mountFlash(tester, restored: cold);
            expect(await worldPixelIntensity(restored), greaterThan(240));
            expect(restored.overworldInteractionSnapshot.primaryAction, isNull);
            expect(await warp(restored, 'neighbor', 'safe'), 'completed');
            expect(await worldPixelIntensity(restored), greaterThan(240));
            expect(await warp(restored, 'cave', 'inside'), 'completed');
            expect(await worldPixelIntensity(restored), lessThan(100));
            expect(
              restored.gameStateSnapshot.mapInstanceWorldState.instanceRef(
                'cave',
              ),
              isNot(scope),
            );
          }
        });
      },
    );
  }

  testWidgets(
    'leaving an unlit rectangle clears the veil and reentry restores it',
    (tester) async {
      await tester.runAsync(() async {
        final game = await mountFlash(tester);
        expect(await worldPixelIntensity(game), lessThan(100));
        await press(game, RuntimeInputControl.left);
        expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
        expect(await worldPixelIntensity(game), greaterThan(240));
        await press(game, RuntimeInputControl.right);
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(await worldPixelIntensity(game), lessThan(100));
      });
    },
  );
}

Future<PlayableMapGame> mountFlash(
  WidgetTester tester, {
  GameState? restored,
  bool retainInstances = false,
  ProjectFieldAbilitiesSettings? fieldAbilities,
}) async {
  final root = await Directory.systemTemp.createTemp('native-flash-player-');
  addTearDown(() => root.delete(recursive: true));
  final cave = MapData(
    id: 'cave',
    name: 'Cave',
    size: const GridSize(width: 6, height: 4),
    entities: const [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        blocksMovement: false,
        pos: GridPos(x: 1, y: 1),
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
    ],
    gameplayZones: const [
      MapGameplayZone(
        id: 'dark',
        kind: GameplayZoneKind.fieldAction,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 4, height: 4),
        ),
        fieldAction: FieldActionZonePayload(
          actionKind: FieldActionZoneKind.darkness,
          darkness: DarknessZonePayload(opacity: .7),
        ),
      ),
    ],
    connections: retainInstances
        ? const [
            MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: 'neighbor',
            ),
          ]
        : const [],
    warps: [arrival('cave', 'inside', 1)],
  );
  final neighbor = MapData(
    id: 'neighbor',
    name: 'Neighbor',
    size: const GridSize(width: 6, height: 4),
    warps: [arrival('neighbor', 'safe', 1)],
  );
  final manifest = ProjectManifest(
    name: 'Flash Player',
    settings: ProjectSettings(
      fieldAbilities: fieldAbilities,
      mapInstanceRetentionPolicy: retainInstances
          ? MapInstanceRetentionPolicy(
              viewportWidthTiles: 10,
              viewportHeightTiles: 8,
              marginTiles: 0,
            )
          : null,
    ),
    tilesets: const [],
    maps: const [
      ProjectMapEntry(id: 'cave', name: 'Cave', relativePath: 'maps/cave.json'),
      ProjectMapEntry(
        id: 'neighbor',
        name: 'Neighbor',
        relativePath: 'maps/neighbor.json',
      ),
    ],
  );
  final state =
      restored ??
      const GameState(
        saveId: 'flash-player',
        currentMapId: 'cave',
        playerPosition: GridPos(x: 1, y: 1),
        playerFacing: EntityFacing.west,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'pikachu',
              natureId: 'hardy',
              abilityId: 'static',
              level: 20,
              currentHp: 30,
              knownMoveIds: ['flash'],
              currentPpByMoveId: {'flash': 0},
            ),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.flash],
        ),
      );
  final bundle = RuntimeMapBundle(
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    manifest: manifest,
    map: cave,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: restored == null
        ? MapActivationReason.initialBoot
        : MapActivationReason.saveRestore,
    runtimeTilesetImageLoader: (
      paths, {
      transparentColorByTilesetId = const {},
    }) async => {},
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle.copyWith(map: mapId == 'cave' ? cave : neighbor),
    saveRepository: MemorySave(),
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
          maxPpByMoveId: {'flash': 20},
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
  game.world.add(
    RectangleComponent(
      position: Vector2.all(-5000),
      size: Vector2.all(10000),
      paint: ui.Paint()..color = const ui.Color(0xffffffff),
      priority: -100000,
    ),
  );
  game.update(.016);
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  game.update(.016);
  return game;
}

Future<int> worldPixelIntensity(PlayableMapGame game) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  game.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(game.size.x.ceil(), game.size.y.ceil());
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final intensity = <int>[];
  for (var i = 0; i < bytes.lengthInBytes; i += 4) {
    intensity.add(bytes.getUint8(i));
  }
  intensity.sort();
  final brightest = intensity[intensity.length ~/ 2];
  image.dispose();
  picture.dispose();
  return brightest;
}

MapWarp arrival(String mapId, String id, int x) => MapWarp(
  id: id,
  pos: GridPos(x: x, y: 1),
  targetMapId: mapId,
  targetPos: GridPos(x: x, y: 1),
  triggerMode: MapWarpTriggerMode.onBump,
);
Future<String> warp(PlayableMapGame game, String mapId, String warpId) async {
  final result = game.debugExecuteSceneInteractiveCommand(
    SceneInteractiveCommand.warp(
      destinationMapId: mapId,
      warpId: warpId,
      transition: SceneWarpTransition.none,
    ),
  );
  var finished = false;
  result.whenComplete(() => finished = true);
  await tickUntil(game, () => finished);
  return result;
}

Future<void> press(PlayableMapGame game, RuntimeInputControl control) async {
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.update(.016);
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  for (var i = 0; i < 8; i++) {
    game.update(.04);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> tickUntil(PlayableMapGame game, bool Function() predicate) async {
  for (var i = 0; i < 200 && !predicate(); i++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(predicate(), isTrue);
}

final class MemorySave implements GameSaveRepository {
  Map<String, dynamic>? data;
  @override
  Future<void> save(GameState state) async {
    data = jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
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
