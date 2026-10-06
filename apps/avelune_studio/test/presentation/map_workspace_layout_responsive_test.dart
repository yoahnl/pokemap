import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_palette_card.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

const _families = [
  'Sélection',
  'Décors',
  'Terrains',
  'Bordures',
  'Environnements',
  'Zones',
  'Collisions',
  'Passages',
];

void main() {
  for (final size in [const Size(1600, 1000), const Size(1280, 800)]) {
    testWidgets(
      'navigator reserves canvas space and dock stays visible $size',
      (tester) async {
        await _mount(tester, size);
        final canvas = tester.getRect(find.byType(MapWorkspaceCanvas));
        final navigator = tester.getRect(find.byType(MapLibraryNavigator));
        expect(navigator.right, lessThanOrEqualTo(canvas.left));
        expect(find.byType(MapWorkspacePaletteDock), findsOneWidget);
        expect(
          tester.getSize(find.byType(GridView).first).height,
          greaterThan(80),
        );
        expect(
          find.byKey(const ValueKey('Enregistrer')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('Enregistrer et tester')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('compact workspace exposes all families at text $scale', (
      tester,
    ) async {
      await _mount(tester, const Size(1024, 640), scale: scale);
      expect(find.byType(MapWorkspaceToolStrip), findsOneWidget);
      for (final family in _families) {
        expect(
          find.widgetWithText(StudioButton, family).hitTestable(),
          findsOneWidget,
          reason: family,
        );
      }
      final rows = {
        for (final family in _families)
          tester.getRect(find.widgetWithText(StudioButton, family)).top,
      };
      expect(rows.length, lessThanOrEqualTo(2));
      expect(find.byType(MapWorkspacePaletteDock), findsOneWidget);
      final canvas = tester.getSize(find.byType(MapWorkspaceCanvas));
      expect(canvas.width, greaterThan(400));
      expect(canvas.height, greaterThan(160));
      expect(
        find.byKey(const ValueKey('Enregistrer')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('Enregistrer et tester')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'compact preview retains its accessible name and selects its asset',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final view = await _mount(tester, const Size(1024, 640), scale: 1.5);
        final finder = find.byKey(const ValueKey('decor-tree'));
        final card = tester.widget<StudioPaletteCard>(finder);
        expect(card.showName, isFalse);
        expect(
          find.descendant(of: finder, matching: find.text('Arbre')),
          findsNothing,
        );
        expect(tester.getSemantics(finder).label, contains('Arbre'));
        expect(
          tester.getSize(find.byWidget(card.preview)).height,
          greaterThanOrEqualTo(40),
        );
        await tester.tap(finder);
        await tester.pump();
        expect(view.brush?.id, 'tree');
        expect(view.tool, StudioMapTool.place);
        expect(tester.widget<StudioPaletteCard>(finder).selected, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('each compact family keeps its panel and canvas usable', (
    tester,
  ) async {
    await _mount(tester, const Size(1024, 640), scale: 1.5);
    for (final family in _families) {
      await tester.tap(find.widgetWithText(StudioButton, family));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: family);
      expect(
        tester.getSize(find.byType(MapWorkspaceCanvas)).height,
        greaterThanOrEqualTo(32),
        reason: family,
      );
    }
  });

  testWidgets(
    'compact large text canvas accepts a collision stroke and search',
    (tester) async {
      await _mount(tester, const Size(1024, 640), scale: 1.5);
      await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
      await tester.pump();
      final viewport = tester.getRect(
        find.byKey(const ValueKey('map-viewport')),
      );
      final gesture = await tester.startGesture(viewport.center);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      final canvas = tester.widget<MapWorkspaceCanvas>(
        find.byType(MapWorkspaceCanvas),
      );
      final collision = canvas.document.current.layers
          .whereType<CollisionLayer>()
          .single;
      expect(collision.collisions.where((value) => value), isNotEmpty);
      expect(canvas.document.canUndo, isTrue);
      await tester.tap(find.byTooltip('Rechercher une ressource'));
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byType(MapWorkspacePaletteDock),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'arbre');
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Masquer la recherche'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('decor-tree')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigator rail does not cover selection or change chosen tool', (
    tester,
  ) async {
    final view = await _mount(tester, const Size(1280, 800));
    await tester.tap(find.byTooltip('Masquer les cartes'));
    await tester.pump();
    expect(find.byType(MapLibraryNavigator), findsNothing);
    final rail = tester.getRect(find.byTooltip('Afficher les cartes'));
    final selection = find.byKey(const ValueKey('Sélectionner'));
    expect(rail.right, lessThanOrEqualTo(tester.getRect(selection).left));
    await tester.tap(selection);
    await tester.pump();
    expect(view.tool, StudioMapTool.select);
    await tester.tap(find.byTooltip('Afficher les cartes'));
    await tester.pump();
    expect(find.byType(MapLibraryNavigator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty terrain and decor families retain selection until chosen',
    (tester) async {
      final view = await _mount(tester, const Size(1024, 640));
      for (final family in ['Terrains', 'Décors']) {
        await tester.tap(find.widgetWithText(StudioButton, family));
        await tester.pump();
        expect(view.paletteTab, family);
        expect(view.tool, StudioMapTool.select);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(MapWorkspacePaletteDock), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}

Future<MapWorkspaceViewState> _mount(
  WidgetTester tester,
  Size size, {
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  );
  await controller.initialize();
  final view = MapWorkspaceViewState();
  final search = TextEditingController();
  final homeSearch = TextEditingController();
  addTearDown(controller.dispose);
  addTearDown(view.dispose);
  addTearDown(search.dispose);
  addTearDown(homeSearch.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, update) => MapWorkspaceLayout(
          controller: controller,
          view: view,
          visuals: WorkspaceTestVisuals(),
          search: search,
          homeSearch: homeSearch,
          error: null,
          palette: true,
          inspector: null,
          generation: 0,
          onPalette: () {},
          onInspector: () {},
          onChanged: () => update(() {}),
          onToolChanged: () => update(() {}),
          onActivate: (_) {},
          onSave: () {},
          onTest: () {},
          onClose: () {},
          onResources: () {},
          onMap: () {},
          onExport: () {},
          onPokemon: () {},
          onOpenElement: (_) {},
          onEditElement: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  return view;
}
