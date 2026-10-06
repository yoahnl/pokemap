import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';

void main() {
  testWidgets(
    'environment recipe is created through controls and reopened from disk',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final before = host.fixture.controller.project!;
      final map = host.fixture.controller.active!.current;
      await tester.tap(
        find.byKey(const ValueKey('resource-family-environments')),
      );
      await tester.pump();
      await tester.tap(find.text('Créer un environnement'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’environnement'),
        'Forêt étoilée',
      );
      await tester.tap(find.byKey(const ValueKey('environment-add-decor')));
      await tester.pumpAndSettle();
      final id = before.elements.first.id;
      await tester.tap(find.byKey(ValueKey('environment-decor-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('environment-save')));
      await pumpIo(tester, frames: 20);
      expect(host.navigation.error, isNull);
      expect(host.navigation.page, ResourcePage.library);
      expect(host.fixture.controller.active!.current, map);
      final reopened = ProjectManifest.fromJson(
        jsonDecode(
          (await tester.runAsync(
            () => File(
              '${host.fixture.directory.path}/project.json',
            ).readAsString(),
          ))!,
        ),
      );
      expect(reopened.environmentPresets.single.name, 'Forêt étoilée');
      expect(reopened.environmentPresets.single.palette.single.elementId, id);
      expect(reopened.elements, before.elements);
      expect(reopened.tilesets, before.tilesets);
      expect(host.navigation.dirty, isFalse);
      final preset = reopened.environmentPresets.single;
      await tester.tap(find.byKey(ValueKey('environment-${preset.id}')));
      await tester.pump();
      await tester.tap(find.text('Dessiner sur la carte'));
      await pumpIo(tester, frames: 10);
      expect(find.byType(MapWorkspaceCanvas), findsOneWidget);
      final canvas = tester.widget<MapWorkspaceCanvas>(
        find.byType(MapWorkspaceCanvas),
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
      await tester.ensureVisible(
        find.byKey(const ValueKey('environment-tool-rectangle')),
      );
      await tester.tap(
        find.byKey(const ValueKey('environment-tool-rectangle')),
      );
      await tester.pump();
      final history = document.undoCount;
      final gesture = await tester.startGesture(cell(5, 4));
      await gesture.moveTo(cell(9, 8));
      await gesture.up();
      await tester.pump();
      expect(document.undoCount, history + 1);
      await tester.tap(find.byKey(const ValueKey('environment-tool-erase')));
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
      await tester.ensureVisible(
        find.byKey(const ValueKey('environment-preview')),
      );
      await tester.tap(find.byKey(const ValueKey('environment-preview')));
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
      await tester.tap(find.byKey(const ValueKey('environment-apply')));
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

  testWidgets('invalid recipe and return retain the draft without writes', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester);
    final file = File('${host.fixture.directory.path}/project.json');
    final before = await tester.runAsync(file.readAsString);
    await tester.tap(
      find.byKey(const ValueKey('resource-family-environments')),
    );
    await tester.pump();
    await tester.tap(find.text('Créer un environnement'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom de l’environnement'),
      'Brouillon à garder',
    );
    await tester.tap(find.byKey(const ValueKey('environment-save')));
    await pumpIo(tester);
    expect(find.textContaining('Ajoutez au moins un décor'), findsWidgets);
    expect(await tester.runAsync(file.readAsString), before);
    await tester.tap(find.text('Retour à la bibliothèque'));
    await tester.pump();
    expect(host.navigation.environment!.name, 'Brouillon à garder');
    expect(find.text('Reprendre l’environnement'), findsOneWidget);
    expect(host.navigation.dirty, isTrue);
  });
}
