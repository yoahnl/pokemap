import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData _map() => workspaceMap('a').copyWith(
  layers: [
    ...workspaceMap('a').layers,
    MapLayer.tile(
      id: 'night',
      name: 'Nuit',
      isVisible: false,
      palette: const [
        TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
      ],
      cells: List.filled(320, 0),
    ),
  ],
  placedElements: const [
    MapPlacedElement(
      id: 'bed',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 2, y: 2),
    ),
    MapPlacedElement(
      id: 'desk',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 5, y: 2),
    ),
    MapPlacedElement(
      id: 'lamp',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 8, y: 2),
    ),
  ],
);

void main() {
  late EditableMapDocument document;
  late MapEditorController editor;
  late MapWorkspaceViewState view;

  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(map: _map(), revision: 'base', mapId: 'a'),
    );
    editor = MapEditorController(
      session: workspaceSession,
      mapId: 'a',
      port: _MemoryEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'initial',
      ),
    );
    document.editor = editor;
    view = MapWorkspaceViewState();
  });
  tearDown(() {
    editor.dispose();
    view.dispose();
  });

  test('a generated decor names the zone that owns it in content', () {
    final base = workspaceMap('a');
    final map = base.copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'oak-1',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 2, y: 2),
        ),
        MapPlacedElement(
          id: 'bench',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 6, y: 2),
        ),
      ],
      layers: [
        ...base.layers,
        MapLayer.environment(
          id: 'forest',
          name: 'Forêt',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'north',
                name: 'Bois du nord',
                presetId: 'woodland',
                mask: EnvironmentAreaMask(
                  width: base.size.width,
                  height: base.size.height,
                  cells: List.filled(base.size.width * base.size.height, true),
                ),
                seed: 7,
                generatedPlacementIds: const ['oak-1'],
              ),
            ],
          ),
        ),
      ],
    );
    final entries = {
      for (final entry in MapElementCatalog(map, workspaceProject).entries)
        entry.id: entry,
    };
    expect(
      entries['oak-1']!.detail,
      endsWith('généré par la zone « Bois du nord »'),
    );
    expect(entries['bench']!.detail, isNot(contains('généré')));
    expect(entries['oak-1']!.kind, 'decor');
  });

  test('counts come from one index and keep every identity', () async {
    await editor.setHidden('decor', 'desk', true);
    await editor.setLocked('decor', 'lamp', true);
    view.select(document, MapSelectionFamily.decor, 'bed');
    final catalog = MapElementCatalog(document.current, workspaceProject);
    final counts = mapContentCounts(
      catalog,
      isHidden: (entry) => document.isElementHidden(entry.kind, entry.id),
      isLocked: (entry) => document.isElementLocked(entry.kind, entry.id),
      isSelected: (entry) => entry.kind == 'decor' && entry.id == 'bed',
    );
    expect(counts[MapContentFilter.all], catalog.entries.length);
    expect(counts[MapContentFilter.hidden], 1);
    expect(counts[MapContentFilter.locked], 1);
    expect(counts[MapContentFilter.selection], 1);
    final before = [for (final entry in catalog.entries) entry.key];
    await editor.setHidden('decor', 'desk', false);
    final after = MapElementCatalog(document.current, workspaceProject);
    expect([for (final entry in after.entries) entry.key], before);
  });

  testWidgets('filters find hidden and locked items and restore everything', (
    tester,
  ) async {
    await editor.setHidden('decor', 'desk', true);
    await editor.setLocked('decor', 'lamp', true);
    await _mount(tester, document, view);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-content-filter-menu')),
        matching: find.text('Tous · 5'),
      ),
      findsOneWidget,
    );
    await _chooseFilter(tester, 'hidden');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-element-decor-desk')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-element-decor-bed')), findsNothing);
    expect(find.byKey(const ValueKey('map-element-decor-lamp')), findsNothing);
    await _chooseFilter(tester, 'locked');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-element-decor-lamp')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-element-decor-desk')), findsNothing);
    await _chooseFilter(tester, 'all');
    await tester.pumpAndSettle();
    for (final id in ['bed', 'desk', 'lamp']) {
      expect(find.byKey(ValueKey('map-element-decor-$id')), findsOneWidget);
    }
    expect(document.dirty, isFalse);
  });

  testWidgets('selection filter follows the element chosen on the map', (
    tester,
  ) async {
    await _mount(tester, document, view);
    view.select(document, MapSelectionFamily.decor, 'desk');
    await _chooseFilter(tester, 'selection');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-element-decor-desk')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-element-decor-bed')), findsNothing);
  });

  testWidgets('editing hide and in-game visibility are named differently', (
    tester,
  ) async {
    await editor.setHidden('decor', 'desk', true);
    await _mount(tester, document, view);
    expect(find.textContaining('Masqué pendant l’édition'), findsOneWidget);
    expect(find.textContaining('invisible en jeu'), findsOneWidget);
    expect(find.textContaining('· masqué'), findsNothing);
  });

  testWidgets('map content is a tab beside the maps and keeps its search', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort()..saved['a'] = _map();
    final controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
    final layoutView = MapWorkspaceViewState();
    final search = TextEditingController();
    final homeSearch = TextEditingController();
    addTearDown(controller.dispose);
    addTearDown(layoutView.dispose);
    addTearDown(search.dispose);
    addTearDown(homeSearch.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: StatefulBuilder(
          builder: (context, update) => MapWorkspaceLayout(
            controller: controller,
            view: layoutView,
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
            onSave: () => controller.save(controller.active!),
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
    await tester.pumpAndSettle();
    expect(find.byType(MapLibraryNavigator), findsOneWidget);
    expect(find.byType(MapElementsPanel), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-left-tab-content')));
    await tester.pumpAndSettle();
    expect(find.byType(MapElementsPanel), findsOneWidget);
    expect(find.byType(MapLibraryNavigator), findsNothing);
    final panel = tester.getRect(find.byType(MapElementsPanel));
    final canvas = tester.getRect(find.byType(MapWorkspaceCanvas));
    expect(panel.right, lessThanOrEqualTo(canvas.left));
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('map-elements-search')),
        matching: find.byType(TextField),
      ),
      'arbre',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-left-tab-maps')));
    await tester.pumpAndSettle();
    expect(find.byType(MapLibraryNavigator), findsOneWidget);
    expect(find.byType(MapElementsPanel), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-left-tab-content')));
    await tester.pumpAndSettle();
    expect(find.text('arbre'), findsOneWidget);
    expect(controller.active!.dirty, isFalse);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _chooseFilter(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('map-content-filter-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('map-content-filter-$name')));
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  EditableMapDocument document,
  MapWorkspaceViewState view,
) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: StatefulBuilder(
            builder: (context, setState) => MapElementsPanel(
              document: document,
              project: workspaceProject,
              view: view,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _MemoryEditorPort implements MapEditorPort {
  var state = MapEditorState();
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'initial');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) async {
    this.state = state;
    return MapEditorWorkspaceState(state: state, revision: 'saved');
  }
}
