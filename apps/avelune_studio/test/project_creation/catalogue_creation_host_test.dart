import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/synthetic_template_fixture.dart';
import '../support/project_creation_workspace_fixture.dart';
import '../support/real_test_io.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/synthetic_player_recipe.dart';

void main() {
  testWidgets(
    'canonical creation downloads Template Alpha once and opens an independent native copy',
    (tester) async {
      final parent = (await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        return Directory.systemTemp.createTemp('alpha-host-');
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
          templateCatalog: fixtureTemplateCatalog,
          readTemplate: (uri) async {
            urls.add(uri);
            return readSyntheticTemplate(uri);
          },
        ),
      );
      await host.submitCreation(
        16,
        name: 'Mon Template Alpha',
        templateId: 'alpha',
        confirm: false,
      );
      expect(host.creator!.selectedTemplate!.label, syntheticDescriptor.label);
      expect(host.creator!.previewBytes, isNotEmpty);
      expect(host.creator!.previewError, isNull);
      expect(
        urls.where((uri) => uri == syntheticDescriptor.archiveUri),
        isEmpty,
      );
      expect(
        await RealTestIo.run(tester, () => parent.list().toList()),
        isEmpty,
      );
      expect(await host.performCreation(), isTrue);
      await host.pump(frames: 30);
      expect(
        urls.where((uri) => uri == syntheticDescriptor.archiveUri).length,
        1,
      );
      final session = host.session.state.project!;
      expect(session.name, 'Mon Template Alpha');
      expect(host.maps.project!.maps.length, 2);
      final resources =
          tester
                  .widget<MapEditingViewport2D>(
                    find.byType(MapEditingViewport2D),
                  )
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
      expect(resources.images, isNotEmpty);
      await tester.pump();
      await captureM3Widget(tester, key, 'alpha-opened');
      await tester.runAsync(() async {
        final adapter = LocalProjectSessionAdapter();
        final reopened = await adapter.open(session.directoryPath);
        try {
          final maps = LocalMapWorkspaceAdapter();
          final manifest = await maps.loadProject(reopened);
          expect(manifest.settings.tileWidth, 16);
          expect(manifest.maps.map((map) => map.id), ['first-map', 'annex']);
          expect(
            (await maps.loadMap(reopened, manifest.maps.last)).map.id,
            'annex',
          );
          expect(
            jsonDecode(
              await File('${session.directoryPath}/project.json')
                  .readAsString(),
            )['name'],
            'Mon Template Alpha',
          );
          expect(
            File('${session.directoryPath}/dialogues/intro.yarn').existsSync(),
            isTrue,
          );
        } finally {
          await adapter.close(reopened);
        }
      });
      await playCreatedSyntheticTemplate(tester, session);
      expect(tester.takeException(), isNull);
    },
  );
}
