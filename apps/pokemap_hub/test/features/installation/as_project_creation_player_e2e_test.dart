import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;
import '../../../../avelune_studio/test/support/project_creation_workspace_fixture.dart';
import 'as_project_creation_player_support.dart';

void main() {
  testWidgets(
    'Studio Clairbois 32 exports, installs and plays without its author source',
    (tester) async {
      final root =
          (await tester.runAsync(
            () => Directory.systemTemp.createTemp('as-proj-clairbois-player-'),
          ))!;
      addTearDown(() => root.delete(recursive: true));
      final package = File(p.join(root.path, 'clairbois-32.avelunegame'));
      final fixture = ProjectCreationWorkspaceFixture(tester, root, package);
      addTearDown(fixture.dispose);
      await fixture.mount();
      await fixture.create(32, name: 'Mon Clairbois');
      final source = Directory(fixture.session.state.project!.directoryPath);
      final before = (await tester.runAsync(() => _authorFiles(source)))!;
      final manifest =
          (await tester.runAsync(() async {
            final adapter = LocalProjectSessionAdapter();
            final reopened = await adapter.open(source.path);
            try {
              final independent = LocalMapWorkspaceAdapter();
              final project = await independent.loadProject(reopened);
              expect(project.name, 'Mon Clairbois');
              expect(project.settings.tileWidth, 32);
              expect(project.settings.tileHeight, 32);
              expect(project.settings.defaultMapWidth, 32);
              expect(project.settings.defaultMapHeight, 26);
              expect(project.maps.map((map) => map.id), [
                'first-map',
                'maison',
              ]);
              for (final entry in project.maps) {
                final document = await independent.loadMap(reopened, entry);
                expect(document.map.id, entry.id);
                expect(
                  document.map.size,
                  entry.id == 'first-map'
                      ? const GridSize(width: 32, height: 26)
                      : const GridSize(width: 12, height: 10),
                );
              }
              expect(project.newGame.startMapId, 'first-map');
              expect(
                project.characters.map((character) => character.id),
                containsAll(['player', 'emile']),
              );
              expect(project.settings.defaultPlayerCharacterId, 'player');
              expect(project.pokemon.enabled, isFalse);
              return project;
            } finally {
              await adapter.close(reopened);
            }
          }))!;
      final workspace = tester.widget<MapWorkspaceScreen>(
        find.byType(MapWorkspaceScreen),
      );
      await tester.tap(find.text('Accueil'));
      await pumpIo(tester, frames: 8);
      await tester.tap(find.text('Exporter le jeu…'));
      await pumpIo(tester, frames: 12);
      expect(find.byType(StudioGameExportPage), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Recette locale',
      );
      await tester.tap(find.text('Test local').first);
      await tester.tap(find.byKey(const ValueKey('start-game-export')));
      for (
        var i = 0;
        i < 200 && workspace.gameExport!.outputPath == null;
        i++
      ) {
        await pumpIo(tester, frames: 2);
        if (workspace.gameExport!.error != null) break;
      }
      expect(
        workspace.gameExport!.outputPath,
        package.path,
        reason: workspace.gameExport!.error,
      );
      expect(find.text('Dernier paquet produit'), findsOneWidget);
      expect(await tester.runAsync(package.exists), isTrue);
      expect(await tester.runAsync(() => _authorFiles(source)), before);
      final evidence = Platform.environment['AVELUNE_CREATION_PACKAGE_DIR'];
      if (evidence != null) {
        await tester.runAsync(() async {
          await Directory(evidence).create(recursive: true);
          await package.copy(p.join(evidence, 'clairbois-32.avelunegame'));
        });
      }
      await fixture.dispose();
      expect(fixture.session.state.project, isNull);
      await tester.runAsync(() async {
        expect(
          p.isWithin(
            await root.resolveSymbolicLinks(),
            await source.resolveSymbolicLinks(),
          ),
          isTrue,
        );
        await source.delete(recursive: true);
        expect(await source.exists(), isFalse);
      });
      await playCreatedPackage(tester, package, root, manifest, 32);
      expect(await tester.runAsync(source.exists), isFalse);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<Map<String, List<int>>> _authorFiles(Directory source) async {
  final result = <String, List<int>>{};
  await for (final file in source.list(recursive: true)) {
    if (file is! File || p.basename(file.path) == 'export-profile-v1.json') {
      continue;
    }
    result[p.relative(file.path, from: source.path)] = await file.readAsBytes();
  }
  return result;
}
