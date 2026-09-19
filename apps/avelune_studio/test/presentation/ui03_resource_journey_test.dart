import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog_view.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:avelune_studio/presentation/features/resources/atlas_selection_view.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_resource_card.dart';
import '../support/m2_ui_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/ui03_resource_fixture.dart';

void main() {
  testWidgets('UI03 real previews selection search return and compact detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final f = (await tester.runAsync(() => createUi03Fixture(tester)))!;
    final overlayCapture = GlobalKey();
    Widget app({double scale = 1}) => RepaintBoundary(
      key: overlayCapture,
      child: f.app(tester, textScale: scale),
    );
    addTearDown(f.dispose);
    final before = File('${f.directory.path}/project.json').readAsStringSync();
    await tester.pumpWidget(app());
    await pumpIo(tester);
    final document = f.controller.active!;
    final beforeMap = document.current;
    Future<void> paintAndUndo() async {
      final canvas = find.byKey(const ValueKey('map-canvas'));
      final scale = tester
          .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      final settings = f.controller.project!.settings;
      final before = document.current;
      await tester.tapAt(
        tester.getTopLeft(canvas) +
            Offset(
              4.4 * settings.tileWidth * settings.displayScale * scale,
              4.4 * settings.tileHeight * settings.displayScale * scale,
            ),
      );
      await tester.pump();
      expect(
        document.current,
        isNot(before),
        reason:
            '${document.error}; ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().where((t) => t.contains('terrain') || t.contains('preset') || t.contains('Impossible')).join(' | ')}',
      );
      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pump();
      expect(document.current, before);
    }

    final transform = tester
        .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
        .transformationController!
        .value
        .clone();
    await tester.tap(find.text('Gérer les ressources'));
    await pumpIo(tester);
    final n = tester
        .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
        .navigation;
    final first = n.library.selectedId;
    expect(first, isNotNull);
    expect(find.byType(StudioResourceCard).evaluate().length, lessThan(20));
    expect(document.current, same(beforeMap));
    expect(document.dirty, isFalse);
    await f.capture(tester, '01-decors-detail');
    await tester.tap(find.text('Importer une image'));
    await pumpIo(tester);
    await tester.tap(find.text('Annuler'));
    await pumpIo(tester);
    expect(File('${f.directory.path}/project.json').readAsStringSync(), before);

    await tester.tap(find.byKey(const ValueKey('resource-category-objets')));
    await tester.pump();
    final query = find.widgetWithText(
      TextField,
      'Rechercher dans les ressources',
    );
    await tester.enterText(query, 'MOBILIER');
    await tester.pumpAndSettle();
    expect(find.text('40 résultats'), findsOneWidget);
    expect(n.library.selectedId, isNot(first));
    await f.capture(tester, '04-recherche-categorie');
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(document.current, same(beforeMap));
    await tester.enterText(query, 'inexistant');
    await tester.pump();
    expect(n.library.selectedId, isNull);
    expect(find.byKey(const ValueKey('resource-use')), findsNothing);
    await tester.enterText(query, '');
    await tester.tap(find.byKey(const ValueKey('resource-category-')));
    await tester.pump();

    await tester.drag(find.byType(ResourceCatalogView), const Offset(0, -350));
    await tester.pumpAndSettle();
    final offset = n.library.offset;
    expect(offset, greaterThan(100));
    await tester.tap(find.text('Carte : Jardin des essais'));
    await tester.pump();
    await tester.tap(find.text('Gérer les ressources'));
    await pumpIo(tester);
    expect(n.library.offset, closeTo(offset, 1));
    await tester.tap(find.byKey(const ValueKey('resource-use')));
    await pumpIo(tester);
    expect(f.controller.active, same(document));
    expect(document.current, same(beforeMap));
    final palette = tester.widget<MapWorkspacePalette>(
      find.byType(MapWorkspacePalette),
    );
    expect(palette.view.tool, StudioMapTool.place);
    expect(palette.view.brush!.id, n.library.selectedId);
    expect(palette.view.transform.value, transform);
    await paintAndUndo();

    await tester.tap(find.text('Gérer les ressources'));
    await pumpIo(tester);
    await tester.tap(find.text('Images et tuiles'));
    await pumpIo(tester);
    await f.capture(tester, '02-image-atlas');
    await tester.tap(find.byKey(const ValueKey('resource-use')));
    await pumpIo(tester);
    expect(find.byType(AtlasSelectionView), findsOneWidget);
    final selector = tester.widget<AtlasSelectionView>(
      find.byType(AtlasSelectionView),
    );
    selector.onSelected(const TilesetSourceRect(x: 3, y: 1));
    await tester.pump();
    await tester.tap(find.text('Utiliser sur la carte'));
    await pumpIo(tester);
    final tileView = tester
        .widget<MapWorkspacePalette>(find.byType(MapWorkspacePalette))
        .view;
    expect(tileView.tile!.localTileId, 13);
    expect(tileView.tool, StudioMapTool.paint);
    await paintAndUndo();

    await tester.tap(find.text('Gérer les ressources'));
    await pumpIo(tester);
    await tester.tap(find.text('Terrains'));
    await pumpIo(tester);
    expect(find.text('Exemple de raccord'), findsNWidgets(2));
    await f.capture(tester, '03-terrain-raccord');
    await tester.tap(find.byKey(const ValueKey('resource-use')));
    await pumpIo(tester);
    final terrainView = tester
        .widget<MapWorkspacePalette>(find.byType(MapWorkspacePalette))
        .view;
    expect(terrainView.terrain!.id, 'chemin');
    expect(terrainView.tool, StudioMapTool.terrain);
    await paintAndUndo();
    await f.capture(tester, '06-retour-carte');

    await tester.tap(find.text('Gérer les ressources'));
    await pumpIo(tester);
    await tester.tap(find.text('Décors'));
    await tester.pump();
    for (final width in [1440.0, 1280.0, 1024.0]) {
      tester.view.physicalSize = Size(width, width == 1024 ? 640 : 900);
      await tester.pumpWidget(app(scale: width == 1024 ? 1.5 : 1));
      await pumpIo(tester);
      expect(find.byType(ResourceLibraryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await f.capture(tester, '05-compact-150');
    await tester.tap(find.byType(StudioResourceCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Détail de la ressource'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('resource-use')).hitTestable(),
      findsOneWidget,
    );
    await captureM3Widget(tester, overlayCapture, '05b-detail-compact-150');
    await tester.tap(find.byTooltip('Retour aux ressources'));
    await tester.pumpAndSettle();
    n.library.query = 'ancien filtre incompatible';
    final revealed = f.controller.project!.elements.last;
    n.openElement(revealed);
    await pumpIo(tester);
    expect(n.library.selectedId, revealed.id);
    expect(n.library.query, isEmpty);
    expect(find.text('Détail de la ressource'), findsOneWidget);
    expect(n.library.kind, ResourceKind.decors);
    expect(File('${f.directory.path}/project.json').readAsStringSync(), before);
    expect(document.dirty, isFalse);
    await tester.pumpWidget(const SizedBox());
    await pumpIo(tester);
  });
}
