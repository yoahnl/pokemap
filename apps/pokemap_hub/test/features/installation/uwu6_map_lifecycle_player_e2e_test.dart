import 'dart:io';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart'
    show createNewGameStateFromProject;
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/capture_m3_widget.dart';
import '../../../../avelune_studio/test/support/map_catalogue_host_fixture.dart';
import '../../../../avelune_studio/test/support/load_desktop_capture_fonts.dart';
import '../../../../avelune_studio/test/support/project_creation_workspace_fixture.dart';
import 'as_project_creation_player_support.dart';
import 'uwu6_map_player_route.dart';
import 'uwu6_map_authoring_steps.dart';

void main() {
  testWidgets(
    'Native map CRUD persists and traverses real passages in the installed Player',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final capture = GlobalKey();
      final fixture = await MapCatalogueHostFixture.open(
        tester,
        captureKey: capture,
      );
      final ui = Uwu6MapAuthoringSteps(fixture);
      final initial = await fixture.reopen();
      expect(initial.project.newGame.startMapId, 'first-map');
      final start = createNewGameStateFromProject(
        project: initial.project,
        startMap: initial.maps['first-map']!,
      ).playerPosition;
      print('UWU6_MAP_STAGE=create-rename-folder');
      final source = await fixture.createMap('Île des essais');
      await captureM3Widget(tester, capture, 'uwu6-map-new-empty');
      await ui.collision(const GridPos(x: 4, y: 4));
      await fixture.saveActive();
      await fixture.renameMap(source.id, 'Île aux étoiles');
      final folder = await fixture.createFolder('Région des étoiles');
      expect(await fixture.moveMap(source.id, folder.id), isNull);
      final sourceDisk = await fixture.reopen();
      final renamed = sourceDisk.project.maps.singleWhere(
        (m) => m.id == source.id,
      );
      expect(renamed.relativePath, source.relativePath);
      expect(renamed.groupId, folder.id);
      expect(sourceDisk.maps[source.id]!.name, 'Île aux étoiles');
      print('UWU6_MAP_STAGE=duplicate-resize');
      final copy = await ui.duplicate(renamed);
      final duplicated = await fixture.reopen();
      expect(copy.id, isNot(source.id));
      expect(copy.relativePath, isNot(source.relativePath));
      expect(
        duplicated.maps[copy.id],
        sourceDisk.maps[source.id]!.copyWith(id: copy.id, name: copy.name),
      );
      await ui.collision(const GridPos(x: 5, y: 4));
      await fixture.saveActive();
      final beforeGrowth = await fixture.reopen();
      expect(beforeGrowth.maps[source.id], sourceDisk.maps[source.id]);
      expect(beforeGrowth.maps[copy.id], isNot(duplicated.maps[copy.id]));
      final grown = GridSize(
        width: beforeGrowth.maps[copy.id]!.size.width + 4,
        height: beforeGrowth.maps[copy.id]!.size.height + 3,
      );
      await ui.resize(copy.id, grown);
      fixture.view.recenter?.call();
      await fixture.host.pump();
      await ui.collision(GridPos(x: grown.width - 2, y: 2));
      await fixture.saveActive();
      final beforeRefusal = await fixture.reopen();
      final beforeRefusalBytes = await tester.runAsync(
        () => _documents(
          fixture.host.session.state.project!.directoryPath,
          beforeRefusal.project,
        ),
      );
      expect(beforeRefusal.maps[copy.id]!.size, grown);
      final refusedResize = await ui.resize(
        copy.id,
        const GridSize(width: 3, height: 3),
        apply: false,
      );
      expect(refusedResize.canApply, isFalse);
      expect(refusedResize.issues, isNotEmpty);
      expect((await fixture.reopen()).maps, beforeRefusal.maps);
      expect(
        await tester.runAsync(
          () => _documents(
            fixture.host.session.state.project!.directoryPath,
            beforeRefusal.project,
          ),
        ),
        beforeRefusalBytes,
      );
      print('UWU6_MAP_STAGE=passages-delete');
      await ui.passage('first-map', const GridPos(x: 2, y: 3), start);
      await ui.select('first-map');
      await ui.passage(
        copy.id,
        GridPos(x: start.x, y: start.y + 1),
        const GridPos(x: 2, y: 2),
      );
      final referenced = await fixture.reopen();
      final referencedBytes = await tester.runAsync(
        () => _documents(
          fixture.host.session.state.project!.directoryPath,
          referenced.project,
        ),
      );
      final refusedDeletion = (await fixture.prepareDeletion(copy.id))!;
      expect(refusedDeletion.canApply, isFalse);
      expect(refusedDeletion.issues, isNotEmpty);
      expect((await fixture.reopen()).maps, referenced.maps);
      expect(
        await tester.runAsync(
          () => _documents(
            fixture.host.session.state.project!.directoryPath,
            referenced.project,
          ),
        ),
        referencedBytes,
      );
      final work = await fixture.createMap('Travail provisoire');
      final deletion = (await fixture.prepareDeletion(work.id))!;
      expect(
        (await fixture.apply(deletion, confirmDestructive: true)).integrated,
        isTrue,
      );
      final persisted = await fixture.reopen();
      expect(persisted.project.maps.any((m) => m.id == work.id), false);
      expect(persisted.maps[source.id], sourceDisk.maps[source.id]);
      expect(persisted.maps['annex'], isNotNull);
      expect(initial.maps['annex'], isNotNull);
      expect(persisted.maps['annex'], initial.maps['annex']);
      expect(
        persisted.maps['first-map']!.warps,
        containsAll(initial.maps['first-map']!.warps),
      );
      expect(persisted.project.settings, initial.project.settings);
      await captureM3Widget(tester, capture, 'uwu6-map-crud-persisted');
      final author = Directory(
        fixture.host.session.state.project!.directoryPath,
      );
      await fixture.host.dispose();
      expect(fixture.host.session.state.project, isNull);
      final reopened = ProjectCreationWorkspaceFixture(
        tester,
        fixture.parent,
        fixture.host.packageFile,
      );
      addTearDown(reopened.dispose);
      await reopened.mount(captureKey: capture, size: const Size(1536, 1024));
      expect(await reopened.openExisting(author.path), isTrue);
      expect(reopened.maps.project, persisted.project);
      expect(reopened.maps.project!.maps.any((m) => m.id == work.id), false);
      print('UWU6_MAP_STAGE=export-independent-session');
      final beforeExportBytes = await tester.runAsync(
        () => _documents(author.path, persisted.project),
      );
      final export = reopened.gameExport!;
      final exporting = Stopwatch()..start();
      var observedStage = export.stage;
      final stages = export.changes.listen((_) {
        if (observedStage == export.stage) return;
        observedStage = export.stage;
        print(
          'UWU6_EXPORT_PHASE=$observedStage:${exporting.elapsedMilliseconds}ms',
        );
      });
      addTearDown(stages.cancel);
      final exported = await reopened.exportPackage(
        metadata: StudioGameExportMetadata(
          gameId: 'games.avelune.uwu6-maps',
          title: export.projectName,
          version: '0.1.0',
          author: 'Recette UwU VI',
          locale: 'fr',
          locales: 'fr',
        ),
      );
      expect(exported, isTrue, reason: export.error);
      print(
        'UWU6_EXPORT_DIAGNOSTIC=elapsedMs:${exporting.elapsedMilliseconds};stage:${export.stage};busy:${export.busy};active:${export.operationActive};canStart:${export.canStart};error:${export.error}',
      );
      await captureM3Widget(tester, capture, 'uwu6-map-export-observed');
      expect(
        export.outputPath,
        fixture.host.packageFile.path,
        reason: export.error,
      );
      print(
        'UWU6_MAP_PACKAGE_SHA256=${await tester.runAsync(() async => sha256.convert(await fixture.host.packageFile.readAsBytes()).toString())}',
      );
      final witness = Platform.environment['AVELUNE_CREATION_PACKAGE_DIR'];
      if (witness != null) {
        await tester.runAsync(() async {
          await Directory(witness).create(recursive: true);
          await fixture.host.packageFile.copy(
            p.join(witness, 'uwu6-map-lifecycle.avelunegame'),
          );
        });
      }
      for (final entry in persisted.project.maps) {
        print(
          'UWU6_MAP_IDENTITY=${entry.id}:${entry.relativePath}:${entry.name}',
        );
      }
      expect(
        await tester.runAsync(() => _documents(author.path, persisted.project)),
        beforeExportBytes,
      );
      await captureM3Widget(tester, capture, 'uwu6-map-export-result');
      await reopened.dispose();
      await tester.runAsync(() async {
        expect(
          p.isWithin(
            await fixture.parent.resolveSymbolicLinks(),
            await author.resolveSymbolicLinks(),
          ),
          true,
        );
        await author.rename('${author.path}.offline');
        expect(await author.exists(), false);
      });
      await playCreatedPackage(
        tester,
        fixture.host.packageFile,
        fixture.parent,
        persisted.project,
        32,
        expectedMaps: persisted.maps,
        beforeTemplateRoute: (game, input) =>
            playUwu6AddedMap(tester, game, input, copy.id, start),
      );
      expect(await tester.runAsync(author.exists), false);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<Map<String, List<int>>> _documents(
  String root,
  ProjectManifest project,
) async => {
  for (final path in [
    'project.json',
    ...project.maps.map((entry) => entry.relativePath),
  ])
    path: await File(p.join(root, path)).readAsBytes(),
};
