import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../packages/map_runtime/test/session/spatial_exploration_game_session_runtime_test.dart'
    as fixtures;

void main() {
  testWidgets(
    'Player keyboard hold crosses encounter cell checks until key release',
    (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      final controller = _Controller();
      final runtime = SpatialExplorationGameSessionRuntime(
        descriptor: fixtures.descriptor(initialState: fixture.state),
        projectFilePath: () async => '${fixture.root.path}/project.json',
        preloadedInitialMap:
            ({
              required projectFilePath,
              required descriptor,
              required initialSave,
            }) async => RuntimeInitialMapPreloadResult(bundle: fixture.bundle),
        mountSession: (_) async {},
        unmountSession: (_) async {},
      );
      addTearDown(() async {
        await runtime.dispose();
        await controller.close();
        await fixture.root.delete(recursive: true);
      });
      await tester.runAsync(() async {
        await runtime.load((_) {});
        await runtime.gameplayReady;
      });
      expect(runtime.battle, isNotNull);
      final inputs = <RuntimeInputEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: PokeMapPlayerSessionView(
            controller: controller,
            titlePresentation: const RuntimePlayerTitlePresentation(
              author: 'QA',
              description: 'Spatial cell checks',
            ),
            gameSceneBuilder: (_) => const SizedBox.expand(),
            gameplayInputAuthority: runtime.inputAuthority,
            gameplayInputRoute: (event) {
              inputs.add(event);
              return runtime.handleInput(event);
            },
            touchControlsAvailable: false,
            controllerInputEnabled: false,
            hapticFeedback: () async {},
          ),
        ),
      );
      await tester.pump();
      final start = runtime.session!.movement.x;
      final cells = <int>{start.floor()};
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 24; i++) {
        runtime.session!.frame(.05);
        await tester.runAsync(() async {
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pump(const Duration(milliseconds: 50));
        cells.add(runtime.session!.movement.x.floor());
      }
      expect(
        inputs.where(
          (event) =>
              event.control == RuntimeInputControl.right && event.isPress,
        ),
        hasLength(1),
      );
      expect(
        inputs.where(
          (event) =>
              event.control == RuntimeInputControl.right && event.isRelease,
        ),
        isEmpty,
        reason:
            'The Player shell must not cancel a held key during a non-interactive cell check.',
      );
      expect(cells.length, greaterThanOrEqualTo(4));
      expect(runtime.session!.movement.x, greaterThan(start + 3));
      expect(
        runtime.inputAuthority.value.context,
        RuntimeInputContext.overworld,
      );
      expect(runtime.battle!.isActive, false);
      expect(runtime.session!.interactionError.value, isNull);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      final stopped = runtime.session!.movement.x;
      for (var i = 0; i < 6; i++) {
        runtime.session!.frame(.05);
        await tester.runAsync(() async {
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        inputs.where(
          (event) =>
              event.control == RuntimeInputControl.right && event.isRelease,
        ),
        hasLength(1),
      );
      expect(runtime.session!.movement.x, stopped);
      expect(runtime.session!.movement.moving, false);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<({Directory root, RuntimeMapBundle bundle, GameState state})>
_fixture() async {
  final root = await Directory.systemTemp.createTemp(
    'spatial-player-held-direction-',
  );
  await File('${root.path}/hero.png').writeAsBytes(
    await File(
      'golden_battle_slice/assets/battle_backgrounds/trainer_rookie.png',
    ).readAsBytes(),
  );
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'field',
    name: 'Field',
    size: const GridSize(width: 12, height: 8),
    gameplayZones: const [
      MapGameplayZone(
        id: 'quiet-grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 12, height: 8),
        ),
        encounter: EncounterZonePayload(encounterTableId: 'quiet'),
      ),
    ],
    spatialScene: MapSpatialScene(
      width: 12,
      depth: 8,
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 2, z: 4)),
    ),
  );
  final project = ProjectManifest(
    version: ProjectVersion.v9,
    name: 'Held input',
    pokemon: const ProjectPokemonConfig(
      enabled: false,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ),
    settings: const ProjectSettings(
      dimension: ProjectDimension.threeD,
      defaultPlayerCharacterId: 'hero',
    ),
    newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'field'),
    maps: const [
      ProjectMapEntry(id: 'field', name: 'Field', relativePath: 'field.json'),
    ],
    tilesets: const [],
    encounterTables: const [
      ProjectEncounterTable(
        id: 'quiet',
        name: 'Quiet grass',
        encounterKind: EncounterKind.walk,
        chancePerStep: 0,
        entries: [
          ProjectEncounterEntry(
            speciesId: 'sproutle',
            minLevel: 2,
            maxLevel: 2,
            weight: 1,
          ),
        ],
      ),
    ],
    characters: [
      ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'unused',
        animations: [
          for (final direction in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: direction,
              sourceAssetId: 'hero-sheet',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  final bundle = RuntimeMapBundle(
    manifest: project,
    map: map,
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    characterAnimationAbsolutePathsByAssetId: {
      'hero-sheet': '${root.path}/hero.png',
    },
  );
  final state = fixtures.descriptor().initialGameState!.copyWith(
    playerPosition: const GridPos(x: 2, y: 4),
    playerSpatialPosition: PlayerSpatialPosition(x: 2, z: 4),
  );
  return (root: root, bundle: bundle, state: state);
}

final class _Controller implements RuntimePlayerViewController {
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  @override
  RuntimePlayerSnapshot get snapshot => RuntimePlayerSnapshot(
    revision: 1,
    phase: RuntimePlayerPhase.playing,
    gameTitle: 'Held input',
    actions: [
      RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
    ],
  );
  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;
  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) async => const RuntimePlayerCommandResult(
    status: RuntimePlayerCommandStatus.accepted,
  );
  @override
  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  }) async => const RuntimePlayerCommandResult(
    status: RuntimePlayerCommandStatus.accepted,
  );
  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) async => const RuntimeWorldServiceCommandResult(
    status: RuntimeWorldServiceCommandStatus.accepted,
  );
  Future<void> close() => _snapshots.close();
}
