import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../avelune_studio/test/support/combat_project_fixture.dart';
import '../../../../avelune_studio/test/support/game_export_fixture.dart';
import '../../../../avelune_studio/test/support/map_host_fixture.dart';
import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;
import '../../../../avelune_studio/test/support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'Studio combat package installs and starts battles from Player storage',
    (tester) async {
      final temporary =
          (await tester.runAsync(
            () => Directory.systemTemp.createTemp('avelune-combat-player-'),
          ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final packageFile = File(p.join(temporary.path, 'combat.avelunegame'));
      final author = await MapHostFixture.open(
        tester,
        prepareSource: _prepareCombatExportFixture,
        gameExportPicker: (_) async => packageFile,
        assetBundle: _StudioAssetBundle(),
      );

      await author.go('Pokémon');
      await tester.tap(find.text('Combats').first);
      await pumpIo(tester);
      await tester.tap(find.text('Créer une table').last);
      await pumpIo(tester);
      await tester.enterText(find.byType(TextField).last, 'Jardin sauvage');
      await tester.tap(find.text('Créer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Ajouter une espèce').last);
      await pumpIo(tester);
      await tester.tap(find.text('sproutle').last);
      await pumpIo(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('jardin_sauvage:chance')),
          matching: find.byType(TextField),
        ),
        '100',
      );
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester);
      expect(author.maps.project!.encounterTables, hasLength(1));

      await tester.tap(find.text('Dresseurs').last);
      await pumpIo(tester);
      await tester.tap(find.text('Créer un dresseur').last);
      await pumpIo(tester);
      await tester.enterText(find.byType(TextField).last, 'Chef gare');
      await tester.tap(find.text('Créer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Ajouter un Pokémon').last);
      await pumpIo(tester);
      await tester.tap(find.text('sproutle').last);
      await pumpIo(tester);
      final movePicker = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Ajouter une attaque',
      );
      await tester.ensureVisible(movePicker);
      await tester.tap(movePicker);
      await pumpIo(tester);
      await tester.tap(find.text('Charge').last);
      await pumpIo(tester);
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester);
      expect(author.maps.project!.trainers, hasLength(1));

      await author.go('Carte');
      await tester.ensureVisible(find.text('Zones').first);
      await tester.tap(find.text('Zones').first);
      await pumpIo(tester);
      await tester.ensureVisible(find.text('Case par case'));
      await tester.tap(find.text('Case par case'));
      await pumpIo(tester);
      await author.tapCell(9, 9);
      final zone = author.document.current.gameplayZones.single;
      await tester.tap(find.byKey(ValueKey('zone-table-${zone.id}')));
      await pumpIo(tester);
      await tester.tap(find.text('Jardin sauvage').last);
      await pumpIo(tester);
      final selectTool = find.byKey(const ValueKey('Sélectionner')).first;
      await tester.ensureVisible(selectTool);
      await tester.tap(selectTool);
      await pumpIo(tester);
      await author.tapCell(7, 9);
      await tester.tap(find.byKey(const ValueKey('trainer-combat-guide-null')));
      await pumpIo(tester);
      await tester.tap(find.text('Chef gare').last);
      await pumpIo(tester);
      expect(
        await tester.runAsync(() => author.maps.save(author.document)),
        isTrue,
      );

      final authorBefore = await author.disk();
      await author.openExport();
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Avelune',
      );
      await tester.tap(find.byKey(const ValueKey('start-game-export')));
      await pumpIo(tester, frames: 120);
      expect(
        find.text('Dernier paquet produit'),
        findsOneWidget,
        reason:
            tester
                .widget<StudioGameExportPage>(find.byType(StudioGameExportPage))
                .controller
                .error,
      );
      expect(await tester.runAsync(packageFile.exists), isTrue);
      expect(await author.disk(), authorBefore);
      await tester.pumpWidget(const SizedBox());

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
        final manifest = ProjectManifest.fromJson(
          jsonDecode(await installedProject.readAsString())
              as Map<String, dynamic>,
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
  await Directory(
    p.join(source.directory.path, 'data/pokemon'),
  ).delete(recursive: true);
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

GamePackageHostCompatibility _compatibility() => GamePackageHostCompatibility(
  hubVersion: Version.parse('1.2.0'),
  runtimeApiVersion: Version.parse('1.4.0'),
  capabilities: const {
    'dialogue.choices@1',
    'map@1',
    'overworld.menu@1',
    'world.shop@1',
  },
  supportedProjectFormats: const {'v8'},
  currentProjectFormat: 'v8',
  supportedSaveFormats: const {1},
);

class _InstalledCombatGame extends PlayableMapGame {
  _InstalledCombatGame({required super.bundle, required super.projectFilePath});

  @override
  bool get isLoaded => true;
}

class _StudioAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/home/')) {
      final bytes =
          await File(
            p.join(Directory.current.path, '../avelune_studio', key),
          ).readAsBytes();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    return rootBundle.load(key);
  }
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
