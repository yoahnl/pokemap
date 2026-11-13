import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../avelune_studio/test/support/combat_project_fixture.dart';
import '../../../../avelune_studio/test/support/game_export_fixture.dart';
import '../../../../avelune_studio/test/support/authoring_export_fixture.dart';
import '../../../../avelune_studio/test/support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'Studio combat package installs and starts battles from Player storage',
    (tester) async {
      final temporary = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('avelune-combat-player-'),
      ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final packageFile = File(p.join(temporary.path, 'combat.avelunegame'));
      final author = await AuthoringExportFixture.open(
        tester,
        prepareSource: _prepareCombatExportFixture,
        prepareProjectAssets: _prepareStudioPokemonResources,
      );
      await tester.runAsync(() => _configureCombatAuthoring(author));

      final authorBefore = await author.disk();
      await author.export(packageFile);
      expect(await tester.runAsync(packageFile.exists), isTrue);
      expect(await author.disk(), authorBefore);

      final source = author.source.directory;
      final hiddenSource = Directory('${source.path}.offline');
      await tester.runAsync(() => source.rename(hiddenSource.path));
      addTearDown(() async {
        if (await hiddenSource.exists()) {
          await hiddenSource.delete(recursive: true);
        }
      });
      expect(await tester.runAsync(source.exists), isFalse);

      await tester.runAsync(() async {
        final support = Directory(p.join(temporary.path, 'player'));
        final compatibility = _compatibility();
        final installed = await GamePackageInstaller(
          supportRoot: support,
          inspector: GamePackageInspector(hostCompatibility: compatibility),
          availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
          loadSmoke: (root, _) async {
            final bundle = await loadRuntimeMapBundle(
              projectFilePath: p.join(root.path, 'project', 'project.json'),
              mapId: 'jardin',
            );
            expect(bundle.map.gameplayZones.single.cellMask, hasLength(1));
          },
          prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
        ).install(packageFile, source: GamePackageInstallSource.localFile);
        final launch = await InstalledGameLaunchResolver(
          supportRoot: support,
          hostCompatibility: compatibility,
        ).resolve(installed.game);
        final installedProject = await launch.assets.resolveReference(
          launch.project,
        );
        expect(installedProject.path, isNot(source.path));
        final manifest = await loadProjectManifestFromFile(
          installedProject.path,
        );
        expect(manifest.encounterTables.single.id, 'jardin_sauvage');
        expect(manifest.trainers.single.id, 'chef_gare');
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: installedProject.path,
          mapId: manifest.newGame.startMapId,
        );
        expect(
          bundle.map.entities
              .singleWhere((entity) => entity.id == 'combat-guide')
              .npc
              ?.trainerId,
          'chef_gare',
        );
        final game = _InstalledCombatGame(
          bundle: bundle,
          projectFilePath: installedProject.path,
        );
        try {
          game.onGameResize(Vector2(640, 480));
          await game.onLoad();
          await _until(
            game,
            () =>
                !game.debugIsMapActivationDispatchInFlight &&
                !game.inputAuthoritySnapshot.isGameplayLocked,
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          );
          game.update(.016);
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          );
          await _until(game, () => game.debugFlowPhaseName == 'battle');
          expect(game.debugPlayerGridPosition, const GridPos(x: 9, y: 9));
          expect(game.debugActiveBattleRequest, isA<WildBattleStartRequest>());
          final wild = game.debugActiveBattleRequest! as WildBattleStartRequest;
          expect(wild.tableId, 'jardin_sauvage');
          expect(wild.speciesId, 'sproutle');
        } finally {
          game.onRemove();
        }
        final trainerGame = _InstalledCombatGame(
          bundle: bundle,
          projectFilePath: installedProject.path,
        );
        try {
          trainerGame.onGameResize(Vector2(640, 480));
          await trainerGame.onLoad();
          await _until(
            trainerGame,
            () =>
                !trainerGame.debugIsMapActivationDispatchInFlight &&
                !trainerGame.inputAuthoritySnapshot.isGameplayLocked,
          );
          trainerGame.debugSetPlayerStateForTest(
            position: const GridPos(x: 8, y: 9),
            facing: Direction.west,
          );
          trainerGame.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          );
          trainerGame.update(.016);
          trainerGame.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.primary),
          );
          await _until(
            trainerGame,
            () => trainerGame.debugFlowPhaseName == 'battle',
          );
          expect(
            trainerGame.debugActiveBattleRequest,
            isA<TrainerBattleStartRequest>(),
          );
          final trainer =
              trainerGame.debugActiveBattleRequest!
                  as TrainerBattleStartRequest;
          expect(trainer.trainerId, 'chef_gare');
          expect(trainer.npcEntityId, 'combat-guide');
        } finally {
          trainerGame.onRemove();
        }
      });
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _configureCombatAuthoring(AuthoringExportFixture author) async {
  final source = author.source;
  final combat = LocalPokemonCombatAdapter(
    session: source.session,
    mapAdapter: source.maps,
  );
  await combat.load();
  await combat.saveTable(
    null,
    ProjectEncounterTable(
      id: 'jardin_sauvage',
      name: 'Jardin sauvage',
      encounterKind: EncounterKind.walk,
      chancePerStep: 1,
      entries: [
        ProjectEncounterEntry(speciesId: 'sproutle', minLevel: 5, maxLevel: 5),
      ],
    ),
  );
  await combat.saveTrainer(
    null,
    ProjectTrainerEntry(
      id: 'chef_gare',
      name: 'Chef gare',
      trainerClass: 'Dresseur',
      team: [
        ProjectTrainerPokemonEntry(
          speciesId: 'sproutle',
          level: 5,
          moves: ['tackle'],
        ),
      ],
    ),
  );
  final saved = (await combat.load()).project;
  final current = author.maps.project!;
  author.maps.acceptResources(
    current,
    mergeProjectMetadataSections(current, saved, const {
      'pokemon',
      'trainers',
      'encounterTables',
    }),
  );
  expect(author.maps.project!.encounterTables, hasLength(1));
  expect(author.maps.project!.trainers, hasLength(1));
  final zones = GameplayZoneEditingCommands(
    author.document,
    author.maps.project!,
  );
  final zone = zones.paintEncounterCells([
    const GridPos(x: 9, y: 9),
  ], erase: false)!;
  zones.updateEncounter(zone.id, tableId: 'jardin_sauvage');
  CharacterEditingCommands(
    author.document,
    author.maps.project!,
  ).assignTrainer('combat-guide', 'chef_gare');
  expect(
    await author.maps.save(author.document),
    isTrue,
    reason: author.document.error,
  );
}

Future<void> _prepareCombatExportFixture(M3StoryFixture source) async {
  await prepareGameExportFixture(source);
  await seedCombatProject(source);
  const goldenRoot = '../../examples/playable_runtime_host/golden_item_system';
  final projectFile = File(p.join(source.directory.path, 'project.json'));
  final project = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  final golden = ProjectManifest.fromJson(
    jsonDecode(await File(p.join(goldenRoot, 'project.json')).readAsString())
        as Map<String, dynamic>,
  );
  await Directory(p.join(source.directory.path, 'data/pokemon'))
      .delete(recursive: true);
  await _copyDirectory(
    Directory(p.join(goldenRoot, 'data/pokemon')),
    Directory(p.join(source.directory.path, 'data/pokemon')),
  );
  await _copyDirectory(
    Directory(p.join(goldenRoot, 'assets/pokemon')),
    Directory(p.join(source.directory.path, 'assets/pokemon')),
  );
  await projectFile.writeAsString(
    jsonEncode(
      project
          .copyWith(
            pokemon: golden.pokemon,
            eventRegistry: NarrativeEventRegistry(
              schemaVersion: project.eventRegistry!.schemaVersion,
              mode: EventSystemMode.dualRead,
              records: project.eventRegistry!.records,
              legacyClaims: project.eventRegistry!.legacyClaims,
            ),
            newGame: ProjectNewGameConfig.fromJson({
              ...project.newGame.toJson(),
              'initialParty': [
                const PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: 10,
                  knownMoveIds: ['tackle'],
                ).toJson(),
              ],
            }),
          )
          .toJson(),
    ),
  );
  final file = File(
    p.join(source.directory.path, project.maps.first.relativePath),
  );
  final map = MapData.fromJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  await file.writeAsString(
    jsonEncode(
      map
          .copyWith(
            warps: [
              for (final warp in map.warps)
                warp.id == 'export-passage'
                    ? warp.copyWith(pos: const GridPos(x: 15, y: 9))
                    : warp,
            ],
          )
          .toJson(),
    ),
  );
  await _prepareStudioPokemonResources(source.directory.path);
}

Future<void> _prepareStudioPokemonResources(String projectPath) async {
  final assets = Directory('../avelune_studio/assets/pokemon');
  await provisionProjectItemIcons(
    projectPath: projectPath,
    loadPack: () async => ProjectItemIconPack(
      manifestBytes: await File(p.join(assets.path, 'item_icons/manifest.json'))
          .readAsBytes(),
      archiveBytes: await File(p.join(assets.path, 'item_icons/icons.zip'))
          .readAsBytes(),
    ),
  );
  try {
    await provisionProjectCaptureSprites(
      projectPath: projectPath,
      loadPack: () async => ProjectCaptureSpritePack(
        manifestBytes: await File(
          p.join(assets.path, 'capture_sprites/manifest.json'),
        ).readAsBytes(),
        archiveBytes: await File(
          p.join(assets.path, 'capture_sprites/sprites.zip'),
        ).readAsBytes(),
      ),
    );
  } on ProjectCaptureSpriteProvisioningPartialFailure catch (failure) {
    throw StateError(failure.error);
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (final entry in source.list(recursive: true)) {
    if (entry is! File) continue;
    final target = File(
      p.join(destination.path, p.relative(entry.path, from: source.path)),
    );
    await target.parent.create(recursive: true);
    await entry.copy(target.path);
  }
}

GamePackageHostCompatibility _compatibility() =>
    AveluneRuntimeCompatibility.host();

class _InstalledCombatGame extends PlayableMapGame {
  _InstalledCombatGame({required super.bundle, required super.projectFilePath});

  @override
  bool get isLoaded => true;
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError(
    'Le Player installé ne démarre pas le combat : '
    '${game.debugFlowPhaseName} à ${game.debugPlayerGridPosition}.',
  );
}
