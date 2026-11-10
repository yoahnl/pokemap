import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/project_creation_workspace_fixture.dart';
import '../../../../avelune_studio/test/support/synthetic_template_fixture.dart';
import 'as_project_creation_player_support.dart';

void main() {
  testWidgets(
    'Studio catalogue template exports, installs and plays without its author source',
    (tester) async {
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('as-proj-template-player-'),
      ))!;
      addTearDown(() => root.delete(recursive: true));
      final package = File(p.join(root.path, 'synthetic-32.avelunegame'));
      final fixture = ProjectCreationWorkspaceFixture(tester, root, package);
      addTearDown(fixture.dispose);
      await fixture.mount(creationPort: workspaceProjectCreation);
      await fixture.create(
        32,
        name: 'Mon projet catalogue',
        templateId: 'workspace',
      );
      final source = Directory(fixture.session.state.project!.directoryPath);
      final before = (await tester.runAsync(() => _authorFiles(source)))!;
      final expectedMaps = <String, MapData>{};
      final manifest = (await tester.runAsync(() async {
        final adapter = LocalProjectSessionAdapter();
        final reopened = await adapter.open(source.path);
        try {
          final independent = LocalMapWorkspaceAdapter();
          final project = await independent.loadProject(reopened);
          expect(project.name, 'Mon projet catalogue');
          expect(project.settings.tileWidth, 32);
          expect(project.settings.tileHeight, 32);
          expect(project.settings.defaultMapWidth, 32);
          expect(project.settings.defaultMapHeight, 26);
          expect(project.maps.map((map) => map.id), ['first-map', 'annex']);
          for (final entry in project.maps) {
            final document = await independent.loadMap(reopened, entry);
            expectedMaps[entry.id] = document.map;
            expect(document.map.id, entry.id);
            expect(document.map.size, const GridSize(width: 32, height: 26));
          }
          expect(project.newGame.startMapId, 'first-map');
          expect(project.characters.map((character) => character.id), [
            'player',
          ]);
          expect(project.settings.defaultPlayerCharacterId, 'player');
          expect(project.pokemon.enabled, isFalse);
          return project;
        } finally {
          await adapter.close(reopened);
        }
      }))!;
      final exporting = Stopwatch()..start();
      expect(
        await fixture.exportPackage(
          metadata: const StudioGameExportMetadata(
            gameId: 'games.avelune.synthetic-template',
            title: 'Mon projet catalogue',
            version: '0.1.0',
            author: 'Recette locale',
            locale: 'fr',
            locales: 'fr',
          ),
        ),
        isTrue,
        reason: fixture.gameExport!.error,
      );
      print('TEMPLATE_EXPORT_COMPLETED_MS=${exporting.elapsedMilliseconds}');
      expect(
        fixture.gameExport!.outputPath,
        package.path,
        reason: fixture.gameExport!.error,
      );
      expect(await tester.runAsync(package.exists), isTrue);
      expect(await tester.runAsync(() => _authorFiles(source)), before);
      final evidence = Platform.environment['AVELUNE_CREATION_PACKAGE_DIR'];
      if (evidence != null) {
        await tester.runAsync(() async {
          await Directory(evidence).create(recursive: true);
          await package.copy(p.join(evidence, 'synthetic-32.avelunegame'));
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
      await playCreatedPackage(
        tester,
        package,
        root,
        manifest,
        32,
        expectedMaps: expectedMaps,
      );
      expect(await tester.runAsync(source.exists), isFalse);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<Map<String, List<int>>> _authorFiles(Directory source) async {
  final result = <String, List<int>>{};
  await for (final file in source.list(recursive: true)) {
    if (file is! File) continue;
    final relative = p.relative(file.path, from: source.path);
    if (relative == '.pokemap/export-profile-v1.json' ||
        relative == '.pokemap/export-profile-v1.json.lock') {
      continue;
    }
    result[relative] = await file.readAsBytes();
  }
  return result;
}
