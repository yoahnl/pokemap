import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:flame/game.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:avelune_studio/presentation/features/resources/decor_editor_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog_view.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import '../support/m2_ui_fixture.dart';
import '../support/map_tool_menu.dart';
import '../support/resource_family_gestures.dart';

void main() {
  testWidgets('real import decor terrain save reload and runtime journey', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late M2UiFixture f;
    await tester.runAsync(() async => f = await M2UiFixture.create(tester));
    addTearDown(() => f.dispose());
    await tester.pumpWidget(f.app(tester));
    await pumpIo(tester);
    final original = f.controller.active!;
    await chooseMapExtraTool(tester, 'Décors');
    final tree = f.controller.project!.elements.singleWhere(
      (element) => element.name == 'Arbre du jardin',
    );
    final treeCard = find.byKey(ValueKey('decor-${tree.id}'));
    expect(treeCard.hitTestable(), findsOneWidget);
    await tester.tap(treeCard);
    await tester.pumpAndSettle();
    if (find.byType(Dialog).evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Retour à la carte'));
      await tester.pumpAndSettle();
    }
    Offset cell(int x, int y) {
      final canvas = find.byKey(const ValueKey('map-canvas'));
      final scale = tester
          .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      final settings = f.controller.project!.settings;
      return tester.getTopLeft(canvas) +
          Offset(
            (x + .4) * settings.tileWidth * settings.displayScale * scale,
            (y + .4) * settings.tileHeight * settings.displayScale * scale,
          );
    }

    await tester.tapAt(cell(4, 4));
    await tester.pump();
    expect(original.dirty, isTrue);
    await tester.tap(find.byKey(const ValueKey('Zoom avant')));
    await tester.pumpAndSettle();
    final transform = tester
        .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
        .transformationController!
        .value
        .clone();
    await chooseMapExtraTool(tester, 'Gérer les ressources');
    await pumpIo(tester);
    await f.capture(tester, '01-bibliotheque');
    await selectResourceFamily(tester, ResourceLibraryFamily.images);
    await tester.tap(find.text('Importer une image'));
    await pumpIo(tester);
    expect(find.text('Importer'), findsOneWidget);
    await tester.tap(find.text('Importer'));
    await pumpIo(tester, frames: 80);
    expect(
      find.byType(DecorEditorScreen),
      findsOneWidget,
      reason:
          'busy=${tester.widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane)).navigation.busy}; '
          '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | ')}',
    );
    final source = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('atlas-selection')),
    );
    final width = f.controller.project!.settings.tileWidth.toDouble();
    final height = f.controller.project!.settings.tileHeight.toDouble();
    final drag = await tester.startGesture(
      source.localToGlobal(Offset(2 * width + 2, 2)),
    );
    await drag.moveTo(
      source.localToGlobal(Offset(3 * width + 2, 2 * height + 2)),
    );
    await drag.up();
    await tester.pump();
    final editor = tester.widget<DecorEditorScreen>(
      find.byType(DecorEditorScreen),
    );
    expect(
      editor.draft.selection,
      const TilesetSourceRect(x: 2, y: 0, width: 2, height: 3),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du décor'),
      'Bosquet M2',
    );
    await tester.tap(find.text('Collisions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquer'));
    await tester.pump();
    final collision = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('decor-collision-canvas')),
    );
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 2; x++) {
        await tester.tapAt(
          collision.localToGlobal(Offset((x + .5) * width, (y + .5) * height)),
        );
        await tester.pump();
      }
    }
    expect(editor.draft.blocked, hasLength(6));
    await f.capture(tester, '02-preparation-decor');
    final beforeSave = original.current;
    await tester.tap(find.text('Enregistrer le décor'));
    await pumpIo(tester, frames: 60);
    final navigation = tester
        .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
        .navigation;
    final savedDecor = f.controller.project!.elements.singleWhere(
      (element) => element.name == 'Bosquet M2',
    );
    expect(navigation.library.selectedIdentity, 'decors:${savedDecor.id}');
    expect(original.current, beforeSave);
    await tester.tap(
      find.byKey(ValueKey('resource-card-decors:${savedDecor.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resource-use')));
    await pumpIo(tester);
    expect(f.controller.active, same(original));
    expect(original.dirty, isTrue);
    expect(
      tester
          .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
          .transformationController!
          .value,
      transform,
    );
    await tester.tapAt(cell(7, 4));
    await tester.pump();
    await tester.tapAt(cell(7, 4));
    await tester.pump();
    expect(
      original.current.placedElements
          .where((e) => e.elementId.startsWith('decor-'))
          .length,
      2,
    );
    await f.capture(tester, '03-carte-nouveau-decor');
    await tester.tap(find.byKey(const ValueKey('Passer derrière')));
    await tester.pump();
    await f.capture(tester, '04-empilement');
    await chooseMapExtraTool(tester, 'Gérer les ressources');
    await pumpIo(tester);
    await selectResourceFamily(tester, ResourceLibraryFamily.images);
    await tester.tap(find.text('Planche M2').first);
    await pumpIo(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('resource-create-path')),
    );
    await tester.tap(find.byKey(const ValueKey('resource-create-path')));
    await tester.pump();
    expect(find.byType(TerrainEditorScreen), findsOneWidget);
    for (var rule = 0; rule < 16; rule++) {
      final ruleFinder = find.byKey(ValueKey('terrain-rule-$rule'));
      await tester.ensureVisible(ruleFinder);
      await tester.tap(ruleFinder);
      await tester.pump();
      final atlas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('atlas-selection')),
      );
      await tester.tapAt(
        atlas.localToGlobal(
          Offset((rule % 10) * width + 2, (rule ~/ 10) * height + 2),
        ),
      );
      await tester.pump();
    }
    final terrain = tester.widget<TerrainEditorScreen>(
      find.byType(TerrainEditorScreen),
    );
    expect(terrain.controller.complete, isTrue);
    await f.capture(tester, '05-terrain-et-essai');
    await tester.tap(find.text('Publier et peindre'));
    await pumpIo(tester, frames: 80);
    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    await chooseMapExtraTool(tester, 'Déplacer la vue');
    await tester.pump();
    await chooseMapExtraTool(tester, 'Peindre');
    await tester.pump();
    final stroke = await tester.startGesture(cell(4, 10));
    await stroke.moveTo(cell(12, 10));
    await stroke.up();
    await pumpIo(tester);
    expect(original.current.layers.whereType<SmartTileLayer>(), isNotEmpty);
    await tester.tap(find.byKey(const ValueKey('Enregistrer')));
    await pumpIo(tester, frames: 50);
    expect(
      original.dirty,
      isFalse,
      reason: 'saving=${original.saving} error=${original.error}',
    );
    await tester.runAsync(() async {
      final fresh = LocalMapWorkspaceAdapter();
      final project = await fresh.loadProject(f.session);
      final loaded = await fresh.loadMap(f.session, project.maps.first);
      expect(loaded.map, original.current);
      expect(project.smartTileCatalog.presets, isNotEmpty);
      expect(project.elements.any((e) => e.name == 'Bosquet M2'), isTrue);
    });
    await tester.tap(find.byTooltip('Enregistrer et tester'));
    await WidgetResourcePort.pending;
    await tester.runAsync(() async {
      await tester.pump();
    });
    await pumpIo(tester, frames: 200);
    final gameFinder = find.byType(GameWidget<PlayableMapGame>);
    expect(gameFinder, findsOneWidget);
    final game = tester.widget<GameWidget<PlayableMapGame>>(gameFinder).game;
    expect(game!.isLoaded, isTrue);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 9));
    for (final y in [8, 7, 7]) {
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.up),
      );
      game.update(.3);
      expect(game.debugPlayerGridPosition, GridPos(x: 8, y: y));
    }
    await tester.tap(find.text('Retour à la carte'));
    await pumpIo(tester);
    expect(f.controller.active, same(original));
    await tester.pumpWidget(const SizedBox());
    await pumpIo(tester, frames: 2);
  });

  testWidgets('large resource library remains usable at narrow enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late M2UiFixture f;
    await tester.runAsync(
      () async => f = await M2UiFixture.create(tester, stress: true),
    );
    addTearDown(() => f.dispose());
    await tester.pumpWidget(f.app(tester, textScale: 1.5));
    await pumpIo(tester);
    await tester.tap(find.byTooltip('Ressources'));
    await pumpIo(tester);
    await selectResourceFamily(tester, ResourceLibraryFamily.images);
    await tester.drag(find.byType(GridView), const Offset(0, -900));
    await pumpIo(tester);
    await f.capture(tester, '06-catalogue-volumineux');
    expect(f.visuals!.manifest.tilesets.length, greaterThan(128));
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher dans les ressources'),
      'atlas tardif 132',
    );
    await pumpIo(tester);
    final results = tester.widget<ResourceCatalogView>(
      find.byType(ResourceCatalogView),
    );
    expect(results.items.single.id, 'stress-atlas-131');
    expect(results.selected!.id, 'stress-atlas-131');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await pumpIo(tester, frames: 2);
  });
}
