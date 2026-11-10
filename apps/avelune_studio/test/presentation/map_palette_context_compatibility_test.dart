import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock_filters.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_family_tree.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

final _project = workspaceProject.copyWith(
  elements: [
    workspaceElement.copyWith(id: 'bed', name: 'Lit'),
    workspaceElement.copyWith(id: 'desk', name: 'Bureau'),
  ],
);

void main() {
  test('a search typed for decors never filters another intention', () {
    final view = MapWorkspaceViewState()..paletteTab = 'Décors';
    final search = TextEditingController();
    addTearDown(view.dispose);
    addTearDown(search.dispose);
    view.paletteSearch = search;
    search.text = 'lit';
    view.resourceFilters
      ..query = 'lit'
      ..familyId = 'furniture';
    view.paletteTab = 'Terrains';
    expect(search.text, isEmpty);
    expect(view.resourceFilters.query, isEmpty);
    expect(view.resourceFilters.familyId, isEmpty);
    view.paletteTab = 'Décors';
    expect(search.text, 'lit');
    expect(view.resourceFilters.familyId, 'furniture');
  });

  test('a 3D model chosen before switching to a 2D map is released', () {
    final view = MapWorkspaceViewState()
      ..paletteTab = 'Décors'
      ..model3d = spatialEnvironmentProject().models3d.first
      ..tool = StudioMapTool.place;
    addTearDown(view.dispose);
    view.reconcileResources(_project, mapId: 'a');
    expect(view.model3d, isNull);
    expect(view.tool, StudioMapTool.select);
  });

  testWidgets('dock names an empty catalogue and offers to prepare it', (
    tester,
  ) async {
    var prepared = 0;
    await _mountDock(
      tester,
      workspaceProject.copyWith(elements: const []),
      onResources: () => prepared++,
    );
    expect(find.text('Aucun décor prêt pour cette carte.'), findsOneWidget);
    expect(
      find.text('Aucune ressource ne correspond aux filtres.'),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('palette-prepare-resources')));
    await tester.pump();
    expect(prepared, 1);
  });

  testWidgets('preparing resources opens the workshop of the gesture', (
    tester,
  ) async {
    var library = 0, workshop = 0;
    await _mountDock(
      tester,
      workspaceProject.copyWith(elements: const []),
      onResources: () => library++,
      onPrepare: () => workshop++,
    );
    await tester.tap(find.byKey(const ValueKey('palette-prepare-resources')));
    await tester.pump();
    expect((library, workshop), (0, 1));
  });

  testWidgets('dock separates no match from no resource and clears filters', (
    tester,
  ) async {
    final (view, search) = await _mountDock(tester, _project);
    await tester.tap(find.byTooltip('Rechercher une ressource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'armoire');
    await tester.pump();
    expect(
      find.text('Aucune ressource ne correspond aux filtres.'),
      findsOneWidget,
    );
    expect(find.text('Aucun décor prêt pour cette carte.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('palette-clear-filters')));
    await tester.pumpAndSettle();
    expect(search.text, isEmpty);
    expect(view.resourceFilters.query, isEmpty);
    expect(find.byKey(const ValueKey('decor-bed')), findsOneWidget);
    expect(find.byKey(const ValueKey('decor-desk')), findsOneWidget);
  });

  testWidgets('a narrow dock keeps a named search entry', (tester) async {
    final search = TextEditingController();
    addTearDown(search.dispose);
    final filters = ResourceCatalogFilterState();
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, rebuild) => SizedBox(
              width: 380,
              child: MapWorkspacePaletteDockFilters(
                tree: ResourceFamilyTree(_project, resourceCatalog(_project)),
                filters: filters,
                search: search,
                onChanged: () => rebuild(() {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Rechercher une ressource'), findsOneWidget);
    await tester.tap(find.byTooltip('Rechercher une ressource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lit');
    await tester.pump();
    expect(filters.query, 'lit');
    expect(find.byTooltip('Masquer la recherche'), findsOneWidget);
    await tester.tap(find.byTooltip('Masquer la recherche'));
    await tester.pumpAndSettle();
    expect(search.text, isEmpty);
    expect(find.text('Familles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<(MapWorkspaceViewState, TextEditingController)> _mountDock(
  WidgetTester tester,
  ProjectManifest project, {
  VoidCallback? onResources,
  VoidCallback? onPrepare,
}) async {
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r0', mapId: 'a'),
  );
  final view = MapWorkspaceViewState();
  final search = TextEditingController();
  addTearDown(view.dispose);
  addTearDown(search.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 1100,
          child: StatefulBuilder(
            builder: (context, rebuild) => MapWorkspacePaletteDock(
              project: project,
              document: document,
              visuals: WorkspaceTestVisuals(),
              view: view,
              search: search,
              onChanged: () => rebuild(() {}),
              onResources: onResources ?? () {},
              onPrepare: onPrepare,
              onOpenFullPalette: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (view, search);
}
