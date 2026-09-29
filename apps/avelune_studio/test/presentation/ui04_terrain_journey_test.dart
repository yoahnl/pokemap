import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui04_terrain_atlas.dart';
import '../support/map_tool_menu.dart';

void main() {
  testWidgets(
    'UI04 source rules trial publication and map preserve the current session',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
      addTearDown(f.dispose);
      await tester.pumpWidget(f.app(tester));
      await pumpIo(tester);
      final document = f.controller.active!;
      document.commit(
        document.current.copyWith(name: 'Travail sur carte conservé'),
      );
      final dirtyMap = document.current;
      final undoCount = document.undoCount;
      final transform = tester
          .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
          .transformationController!
          .value
          .clone();
      await chooseMapExtraTool(tester, 'Gérer les ressources');
      await pumpIo(tester);
      final n = tester
          .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
          .navigation;
      await tester.runAsync(() async {
        final source = File('${f.directory.path}/source-terrain-test.png');
        await source.writeAsBytes(ui04TerrainAtlas());
        await n.accept(
          await f.resources.importImage(
            ResourceImageImport(
              sourcePath: source.path,
              name: 'Chemins — atlas d’essai',
              tileWidth: 24,
              tileHeight: 24,
            ),
          ),
        );
      });
      n.showLibrary();
      await pumpIo(tester);
      await tester.tap(find.text('Créer un chemin'));
      await pumpIo(tester);
      expect(find.text('Choisir l’image du chemin'), findsOneWidget);
      await f.capture(tester, '00-creation-chemin-visible');
      await tester.tap(find.text('Chemins — atlas d’essai').last);
      await pumpIo(tester);
      final model = n.terrain!;
      final id = model.draft.targetPresetId;
      await f.capture(tester, '00b-patron-chemin-vide');
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await f.capture(tester, name);
      }

      Future<void> assign(int rule, int cell) async {
        final tile = find.byKey(ValueKey('terrain-rule-$rule'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pump();
        final source = tester.getRect(
          find.byKey(const ValueKey('atlas-selection')),
        );
        await tester.tapAt(
          source.topLeft +
              Offset(
                (cell % 4 + .5) * source.width / 4,
                (cell ~/ 4 + .5) * source.height / 4,
              ),
        );
        await tester.pump();
        expect(model.frameFor(rule)!.column, cell % 4);
        expect(model.frameFor(rule)!.row, cell ~/ 4);
      }

      await tester.enterText(
        find.byKey(const ValueKey('terrain-name')),
        'Chemins du jardin',
      );
      for (var mask = 0; mask < 5; mask++) {
        await assign(mask, mask * 5 % 16);
      }
      await capture('01-brouillon-incomplet');
      await tester.tap(find.text('Enregistrer le brouillon'));
      await pumpIo(tester);
      expect(model.dirty, isFalse);
      await tester.tap(find.text('Ressources › Terrains'));
      await pumpIo(tester);
      n.resumeTerrain(model.draft);
      await pumpIo(tester);
      expect(n.terrain, same(model));
      expect(model.assignedCount, 5);
      for (var mask = 5; mask < 16; mask++) {
        await assign(mask, mask * 5 % 16);
      }
      await assign(3, 0);
      final trial = tester.getRect(
        find.byKey(const ValueKey('terrain-scratch')),
      );
      await tester.tapAt(
        trial.topLeft + Offset(14.5 * trial.width / 17, 2.5 * trial.width / 17),
      );
      await tester.pump();
      expect(model.selectedRule, 3);
      await assign(3, 15);
      await tester.tap(find.byTooltip('Annuler la préparation'));
      await tester.pump();
      expect(model.frameFor(3)!.column, 0);
      await tester.tap(find.byTooltip('Rétablir la préparation'));
      await tester.pump();
      expect(model.frameFor(3)!.column, 3);
      await capture('02-raccord-corrige');
      await tester.tap(find.text('Peindre'));
      await tester.tap(find.text('Effacer l’essai'));
      await tester.pump();
      final cell = trial.width / 17;
      final start = trial.topLeft + Offset(cell * 3.5, cell * 3.5);
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(start + Offset(cell * 9, 0));
      await gesture.moveTo(start + Offset(cell * 9, cell * 8));
      await gesture.up();
      await tester.pump();
      final junction = await tester.startGesture(start + Offset(cell * 4, 0));
      await junction.moveTo(start + Offset(cell * 4, cell * 5));
      await junction.up();
      await tester.pump();
      expect(model.scratch.length, 23);
      await capture('03-terrain-complet');
      for (final width in [1440.0, 1280.0, 1024.0]) {
        tester.view.physicalSize = Size(width, width == 1024 ? 640 : 900);
        await tester.pumpWidget(
          f.app(tester, textScale: width == 1024 ? 1.5 : 1),
        );
        await pumpIo(tester);
        expect(find.byType(TerrainEditorScreen), findsOneWidget);
      }
      await tester.tap(find.text('Essayer'));
      await tester.pumpAndSettle();
      await capture('04-compact-150');
      tester.view.physicalSize = const Size(1536, 1024);
      await tester.pumpWidget(f.app(tester));
      await pumpIo(tester);
      await tester.tap(find.text('Publier et peindre'));
      await pumpIo(tester);
      expect(find.byType(TerrainEditorScreen), findsNothing);
      expect(document.current, same(dirtyMap));
      expect(document.undoCount, undoCount);
      final view = tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .view;
      expect(view.terrain!.id, id);
      expect(view.paletteTab, 'Terrains');
      expect(view.transform.value, transform);
      final canvas = tester.getTopLeft(
        find.byKey(const ValueKey('map-canvas')),
      );
      final size =
          f.controller.project!.settings.tileWidth *
          f.controller.project!.settings.displayScale *
          transform.getMaxScaleOnAxis();
      await tester.tapAt(canvas + Offset(size * 4.5, size * 4.5));
      await tester.pump();
      expect(document.current, isNot(same(dirtyMap)));
      await capture('05-retour-carte');
      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pump();
      expect(document.current, dirtyMap);
      expect(document.dirty, isTrue);
      expect(f.controller.project!.smartTileCatalog.presets.single.id, id);
      Offset mapCell(int x, int y) =>
          canvas + Offset(size * (x + .5), size * (y + .5));
      final horizontal = await tester.startGesture(mapCell(4, 6));
      await horizontal.moveTo(mapCell(9, 6));
      await horizontal.up();
      await tester.pump();
      final firstPath = document.current;
      final corner = await tester.startGesture(mapCell(9, 6));
      await corner.moveTo(mapCell(9, 9));
      await corner.up();
      await tester.pump();
      final completePath = document.current;
      final layer = completePath.layers.whereType<SmartTileLayer>().single;
      final mapWidth = completePath.size.width;
      for (var x = 4; x <= 9; x++) {
        expect(layer.field.semanticCells[6 * mapWidth + x], isNonZero);
      }
      for (var y = 7; y <= 9; y++) {
        expect(layer.field.semanticCells[y * mapWidth + 9], isNonZero);
      }
      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pump();
      expect(document.current, firstPath);
      await tester.tap(find.byKey(const ValueKey('Rétablir')));
      await tester.pump();
      expect(document.current, completePath);
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await pumpIo(tester);
      expect(document.dirty, isFalse);
      await tester.runAsync(() async {
        final fresh = LocalMapWorkspaceAdapter();
        final project = await fresh.loadProject(f.session);
        final reopened = await fresh.loadMap(f.session, project.maps.first);
        expect(reopened.map, completePath);
      });
      await capture('06-chemin-enregistre');
      await tester.pumpWidget(const SizedBox());
      await pumpIo(tester);
    },
  );
}
