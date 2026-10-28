import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' as helpers;
import 'support/project_audio_test_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '2D committed steps and Surf transitions use the configured shared audio owner',
    (tester) async {
      await tester.runAsync(() async {
        final driver = ProjectAudioTestDriver();
        final audio = RuntimeProjectAudioController(
          mixer: RuntimeAudioMixer(),
          driver: driver,
          settings: ProjectAudioSettings(
            cues: {
              for (final cue in [
                ProjectSoundCue.overworldStep,
                ProjectSoundCue.surfEnter,
                ProjectSoundCue.surfExit,
              ])
                cue: const ProjectSoundBinding(
                  source: ProjectSoundSource.builtin,
                ),
            },
          ),
        );
        final game = await _mount(
          tester,
          projectAudio: audio,
          settings: const ProjectSurfSettings(
            requiresKnownMove: false,
            accessMode: ProjectSurfAccessMode.always,
          ),
        );
        expect(driver.paths, isEmpty);
        await helpers.press(game, RuntimeInputControl.right);
        await helpers.press(game, RuntimeInputControl.primary);
        await helpers.press(game, RuntimeInputControl.primary);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          driver.paths.where(
            (p) =>
                p ==
                RuntimeProjectAudioController.builtinPaths[ProjectSoundCue
                    .surfEnter],
          ),
          hasLength(1),
        );
        for (var i = 0; i < 3; i++)
          await helpers.press(game, RuntimeInputControl.right);
        await Future<void>.delayed(Duration.zero);
        expect(game.playerMovementMode, MovementMode.walk);
        expect(
          driver.paths.where(
            (p) =>
                p ==
                RuntimeProjectAudioController.builtinPaths[ProjectSoundCue
                    .surfExit],
          ),
          hasLength(1),
        );
        expect(
          driver.paths.where(
            (p) =>
                p ==
                RuntimeProjectAudioController.builtinPaths[ProjectSoundCue
                    .overworldStep],
          ),
          isNotEmpty,
        );
        game.onRemove();
        await audio.dispose();
        expect(driver.stopped.length, driver.paths.length);
      });
    },
  );

  testWidgets(
    '2D free Surf confirms, crosses water, persists and exits to land',
    (tester) async {
      await tester.runAsync(() async {
        const settings = ProjectSurfSettings(
          requiresKnownMove: false,
          accessMode: ProjectSurfAccessMode.always,
          speedCellsPerSecond: 5,
        );
        final save = helpers.MemorySave();
        final game = await _mount(tester, settings: settings, save: save);
        await helpers.press(game, RuntimeInputControl.right);
        expect(game.debugPendingFieldActionTicket, isNotNull);
        await helpers.press(game, RuntimeInputControl.primary);
        await helpers.press(game, RuntimeInputControl.primary);
        await helpers.tickUntil(
          game,
          () => game.inputAuthoritySnapshot.acceptsOverworldInput,
        );
        expect(game.debugLastFieldActionCommit, isA<FieldActionApplied>());
        expect(game.playerMovementMode, MovementMode.surf);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        );
        game.update(.001);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        );
        expect(game.debugIsPlayerStepping, isTrue);
        game.update(.1);
        expect(game.debugIsPlayerStepping, isTrue);
        game.update(.11);
        expect(game.debugIsPlayerStepping, isFalse);
        expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 3));
        expect(await game.saveGame(), isTrue);
        final restored = await save.load();
        expect(restored!.playerMovementMode, MovementMode.surf);
        final cold = await _mount(
          tester,
          settings: settings,
          restored: restored,
        );
        expect(cold.playerMovementMode, MovementMode.surf);
        expect(cold.debugPlayerGridPosition, const GridPos(x: 3, y: 3));
        await helpers.press(cold, RuntimeInputControl.right);
        await helpers.press(cold, RuntimeInputControl.right);
        expect(cold.debugPlayerGridPosition, const GridPos(x: 5, y: 3));
        expect(cold.playerMovementMode, MovementMode.walk);
      });
    },
  );

  testWidgets('2D disabled Surf refuses water without prompting', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(
        tester,
        settings: const ProjectSurfSettings(enabled: false),
      );
      await helpers.press(game, RuntimeInputControl.right);
      expect(game.debugPendingFieldActionTicket, isNull);
      expect(game.playerMovementMode, MovementMode.walk);
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 3));
      expect(game.debugFlowPhaseName, 'overworld');
    });
  });

  testWidgets('2D legacy Surf still requires a usable party move', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      await helpers.press(game, RuntimeInputControl.right);
      expect(game.debugPendingFieldActionTicket, isNull);
      expect(game.playerMovementMode, MovementMode.walk);
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 3));
      expect(game.debugFlowPhaseName, 'dialogue');
    });
  });
}

Future<PlayableMapGame> _mount(
  WidgetTester tester, {
  ProjectSurfSettings? settings,
  RuntimeProjectAudioController? projectAudio,
  GameState? restored,
  helpers.MemorySave? save,
}) async {
  const root = '/Users/karim/Library/Caches/AveluneQA/surf-v1';
  final map = MapData(
    id: 'surf',
    name: 'Surf',
    size: const GridSize(width: 8, height: 8),
    entities: const [
      MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 3),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    gameplayZones: const [
      MapGameplayZone(
        id: 'water',
        kind: GameplayZoneKind.movement,
        area: MapRect(
          pos: GridPos(x: 3, y: 2),
          size: GridSize(width: 2, height: 3),
        ),
        movement: MovementZonePayload(requiredMode: MovementMode.surf),
      ),
    ],
  );
  final bundle = RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Surf',
      maps: const [
        ProjectMapEntry(
          id: 'surf',
          name: 'Surf',
          relativePath: 'maps/surf.json',
        ),
      ],
      tilesets: const [],
      settings: ProjectSettings(surf: settings),
    ),
    map: map,
    projectRootDirectory: root,
    tilesetAbsolutePathsById: const {},
  );
  final state =
      restored ??
      const GameState(
        saveId: 'surf2d',
        currentMapId: 'surf',
        playerPosition: GridPos(x: 2, y: 3),
        playerFacing: EntityFacing.east,
      );
  final game = PlayableMapGame(
    bundle: bundle,
    projectAudio: projectAudio,
    projectFilePath: '$root/project.json',
    saveData: saveDataFromGameState(state),
    saveRepository: save ?? helpers.MemorySave(),
    initialMapActivationReason: MapActivationReason.saveRestore,
    runtimeTilesetImageLoader: (
      paths, {
      transparentColorByTilesetId = const {},
    }) async => {},
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle,
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
  await helpers.tickUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
  return game;
}
