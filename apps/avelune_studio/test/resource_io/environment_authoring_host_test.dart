import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';
import '../support/resource_family_gestures.dart';

void main() {
  testWidgets(
    'canonical environment owner publication and catalogue use keep canvas gestures and disk reopen',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final before = host.fixture.controller.project!;
      final map = host.fixture.controller.active!.current;
      await selectResourceFamily(tester, ResourceLibraryFamily.environments);
      await tester.pump();
      host.navigation.openEnvironment();
      await tester.pump();
      final id = before.elements.first.id;
      host.navigation.environment!
        ..name = 'Forêt étoilée'
        ..add(id);
      final saving = host.navigation.saveEnvironment();
      await pumpIoUntil(tester, () => !host.navigation.busy);
      await saving;
      expect(host.navigation.error, isNull);
      expect(host.navigation.page, ResourcePage.library);
      expect(host.fixture.controller.active!.current, map);
      final reopened = ProjectManifest.fromJson(
        jsonDecode(
          (await tester.runAsync(
            () =>
                File('${host.fixture.directory.path}/project.json')
                    .readAsString(),
          ))!,
        ),
      );
      expect(reopened.environmentPresets.single.name, 'Forêt étoilée');
      expect(reopened.environmentPresets.single.palette.single.elementId, id);
      expect(reopened.elements, before.elements);
      expect(reopened.tilesets, before.tilesets);
      expect(host.navigation.dirty, isFalse);
      final preset = reopened.environmentPresets.single;
      await tester.tap(
        find.byKey(
          const ValueKey('resource-environment-library-return-to-catalog'),
        ),
      );
      await tester.pump();
      host.navigation.library.query = preset.name;
      host.navigation.changed();
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('resource-card-environmentPreset:${preset.id}')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('resource-use')));
      await pumpIo(tester, frames: 10);
      expect(find.byType(MapEditingViewport2D), findsOneWidget);
      final canvas = tester.widget<MapEditingViewport2D>(
        find.byType(MapEditingViewport2D),
      );
      final document = host.fixture.controller.active!;
      final session = canvas.view.environment!;
      Offset cell(int x, int y) =>
          tester.getTopLeft(find.byKey(const ValueKey('map-canvas'))) +
          Offset(
            (x + .4) *
                reopened.settings.tileWidth *
                reopened.settings.displayScale *
                canvas.view.scale,
            (y + .4) *
                reopened.settings.tileHeight *
                reopened.settings.displayScale *
                canvas.view.scale,
          );
      session.tool = EnvironmentPaintTool.rectangle;
      host.fixture.controller.notify();
      await tester.pump();
      final history = document.undoCount;
      final gesture = await tester.startGesture(cell(5, 4));
      await gesture.moveTo(cell(9, 8));
      await gesture.up();
      await tester.pump();
      expect(document.undoCount, history + 1);
      session.tool = EnvironmentPaintTool.erase;
      host.fixture.controller.notify();
      await tester.pump();
      await tester.tapAt(cell(7, 6));
      await tester.pump();
      final area = document.current.layers
          .whereType<EnvironmentLayer>()
          .single
          .content
          .areas
          .single;
      expect(area.mask.isActiveAt(5, 4), isTrue);
      expect(area.mask.isActiveAt(7, 6), isFalse);
      expect(area.mask.isActiveAt(10, 8), isFalse);
      final beforePreview = document.current;
      final commands = EnvironmentEditingCommands(
        document,
        host.fixture.controller.project!,
      );
      commands.preview(session);
      host.fixture.controller.notify();
      await tester.pump();
      expect(document.error, isNull);
      expect(document.current, beforePreview);
      expect(session.generation!.placements, isNotEmpty);
      expect(
        session.generation!.placements.any(
          (placement) => placement.pos == const GridPos(x: 7, y: 6),
        ),
        isFalse,
      );
      commands.apply(session);
      host.fixture.controller.notify();
      await tester.pump();
      expect(
        document.current.placedElements.length,
        greaterThan(beforePreview.placedElements.length),
      );
      final savedArea = document.current.layers
          .whereType<EnvironmentLayer>()
          .single
          .content
          .areas
          .single;
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await pumpIo(tester, frames: 20);
      expect(document.dirty, isFalse, reason: document.error);
      final disk = (await tester.runAsync(() async {
        final owner = LocalMapWorkspaceAdapter();
        final project = await owner.loadProject(host.fixture.session);
        return owner.loadMap(
          host.fixture.session,
          project.maps.firstWhere((entry) => entry.id == document.current.id),
        );
      }))!;
      expect(
        disk.map.layers
            .whereType<EnvironmentLayer>()
            .single
            .content
            .areas
            .single,
        savedArea,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'canonical resource editor entry rejects an invalid recipe and retains its draft on library return without writes',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final file = File('${host.fixture.directory.path}/project.json');
      final before = await tester.runAsync(file.readAsString);
      await selectResourceFamily(tester, ResourceLibraryFamily.environments);
      await tester.pump();
      host.navigation.openEnvironment();
      await tester.pump();
      host.navigation.environment!.name = 'Brouillon à garder';
      final saving = expectLater(
        host.navigation.saveEnvironment(),
        throwsFormatException,
      );
      await pumpIoUntil(tester, () => !host.navigation.busy);
      await saving;
      expect(find.textContaining('Ajoutez au moins un décor'), findsWidgets);
      expect(await tester.runAsync(file.readAsString), before);
      final error = host.navigation.error;
      await tester.tap(
        find.byKey(const ValueKey('resource-environment-return-to-catalog')),
      );
      await tester.pump();
      expect(host.navigation.error, error);
      expect(host.navigation.environment!.name, 'Brouillon à garder');
      expect(
        find.byKey(const ValueKey('resource-environment-draft-preserved')),
        findsOneWidget,
      );
      expect(host.navigation.library.atelierVisible, isFalse);
      expect(host.navigation.dirty, isTrue);
    },
  );
}
