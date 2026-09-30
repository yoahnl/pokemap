import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/clairbois_template_fixture.dart';
import '../support/project_creation_workspace_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/clairbois_player_recipe.dart';

void main() {
  testWidgets(
    'real home creator downloads Clairbois and opens an independent copy',
    (tester) async {
      final parent = (await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        return Directory.systemTemp.createTemp('clairbois-host-');
      }))!;
      final host = ProjectCreationWorkspaceFixture(
        tester,
        parent,
        File('${parent.path}/demo.avelunegame'),
      );
      addTearDown(() async {
        await host.dispose();
        await tester.runAsync(() => parent.delete(recursive: true));
      });
      final urls = <Uri>[];
      final key = GlobalKey();
      await host.mount(
        captureKey: key,
        creationPort: LocalProjectCreationService(
          clairbois: ClairboisProjectTemplate(
            read: (uri) async {
              urls.add(uri);
              return readClairboisFixture(uri);
            },
          ),
        ),
      );
      await tester.tap(find.text('Nouveau projet'));
      await pumpIo(tester, frames: 4);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du projet'),
        'Mon Clairbois',
      );
      await host.next();
      await tester.tap(find.text('Petit projet jouable'));
      await pumpIo(tester, frames: 8);
      expect(find.textContaining('Clairbois'), findsWidgets);
      expect(
        urls.where((uri) => uri == ClairboisProjectTemplate.archiveUri),
        isEmpty,
      );
      await captureM3Widget(tester, key, 'clairbois-model');
      await host.next();
      expect(find.byKey(const ValueKey('creation-grid-16')), findsNothing);
      expect(find.byKey(const ValueKey('creation-grid-48')), findsNothing);
      await host.next();
      await tester.tap(find.byKey(const ValueKey('creation-choose-parent')));
      await pumpIo(tester, frames: 8);
      expect(await tester.runAsync(() => parent.list().toList()), isEmpty);
      await tester.tap(find.byKey(const ValueKey('create-project-confirm')));
      for (var i = 0; i < 100 && host.session.state.project == null; i++) {
        await pumpIo(tester, frames: 3);
      }
      await pumpIo(tester, frames: 30);
      expect(
        urls.where((uri) => uri == ClairboisProjectTemplate.archiveUri).length,
        1,
      );
      final session = host.session.state.project!;
      expect(session.name, 'Mon Clairbois');
      expect(host.maps.project!.maps.length, 2);
      final resources =
          tester
                  .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
                  .visuals
              as StudioMapResources;
      var ready = false;
      resources.settled.then((_) => ready = true);
      final elapsed = Stopwatch()..start();
      while (!ready && elapsed.elapsed < const Duration(seconds: 20)) {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(ready, isTrue);
      expect(resources.diagnostics, isEmpty);
      expect(resources.images.length, greaterThan(10));
      await tester.pump();
      await captureM3Widget(tester, key, 'clairbois-opened');
      await tester.runAsync(() async {
        final adapter = LocalProjectSessionAdapter();
        final reopened = await adapter.open(session.directoryPath);
        try {
          final maps = LocalMapWorkspaceAdapter();
          final manifest = await maps.loadProject(reopened);
          expect(manifest.settings.tileWidth, 32);
          expect(manifest.maps.map((map) => map.id), ['first-map', 'maison']);
          expect(
            (await maps.loadMap(reopened, manifest.maps.last)).map.id,
            'maison',
          );
          expect(
            jsonDecode(
              await File(
                '${session.directoryPath}/project.json',
              ).readAsString(),
            )['name'],
            'Mon Clairbois',
          );
          expect(
            File(
              '${session.directoryPath}/dialogues/bienvenue.yarn',
            ).existsSync(),
            isTrue,
          );
        } finally {
          await adapter.close(reopened);
        }
      });
      await playCreatedClairbois(tester, session);
      expect(tester.takeException(), isNull);
    },
  );
}
