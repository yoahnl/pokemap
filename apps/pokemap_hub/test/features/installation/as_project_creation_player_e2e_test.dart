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
  for (final grid in [16, 32, 48]) {
    testWidgets(
      'Studio creation $grid px exports, installs and plays New Game',
      (tester) async {
        final root =
            (await tester.runAsync(
              () => Directory.systemTemp.createTemp('as-proj-player-$grid-'),
            ))!;
        addTearDown(() => root.delete(recursive: true));
        final package = File(p.join(root.path, 'created-$grid.avelunegame'));
        final fixture = ProjectCreationWorkspaceFixture(tester, root, package);
        addTearDown(fixture.dispose);
        await fixture.mount();
        await fixture.create(grid);
        final source = Directory(fixture.session.state.project!.directoryPath);
        final before = (await tester.runAsync(() => _authorFiles(source)))!;
        final manifest = await tester.runAsync(() async {
          final reopened = await LocalProjectSessionAdapter().open(source.path);
          final independent = LocalMapWorkspaceAdapter();
          final project = await independent.loadProject(reopened);
          final map = await independent.loadMap(reopened, project.maps.single);
          expect(project.name, 'Projet grille $grid');
          expect(project.settings.tileWidth, grid);
          expect(project.settings.tileHeight, grid);
          expect(project.settings.defaultMapWidth, 20);
          expect(project.settings.defaultMapHeight, 15);
          expect(map.map.size, const GridSize(width: 20, height: 15));
          expect(map.map.id, project.newGame.startMapId);
          expect(
            project.characters.single.id,
            project.settings.defaultPlayerCharacterId,
          );
          expect(project.pokemon.enabled, isFalse);
          return project;
        });
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
        expect(await tester.runAsync(() => _authorFiles(source)), before);
        final evidence = Platform.environment['AVELUNE_CREATION_PACKAGE_DIR'];
        if (evidence != null) {
          await tester.runAsync(() async {
            await Directory(evidence).create(recursive: true);
            await package.copy(p.join(evidence, 'created-$grid.avelunegame'));
          });
        }
        await fixture.dispose();
        final hidden = await tester.runAsync(
          () => source.rename('${source.path}.offline'),
        );
        expect(await tester.runAsync(source.exists), isFalse);
        await playCreatedPackage(tester, package, root, manifest!, grid);
        expect(await tester.runAsync(source.exists), isFalse);
        expect(hidden, isNotNull);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
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
