import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock_filters.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_family_tree_view.dart';
import 'package:avelune_studio/presentation/features/resources/resource_family_tree.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('quick families and full tree keep the chosen family', (
    tester,
  ) async {
    final project = workspaceProject.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(id: 'houses', name: 'Maisons', parentId: 'buildings'),
        ],
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'house',
            familyId: 'houses',
          ),
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'tree',
            familyId: 'trees',
          ),
        ],
      ),
      elements: [
        workspaceElement.copyWith(id: 'house', categoryId: 'houses'),
        workspaceElement.copyWith(id: 'tree', categoryId: 'nature'),
      ],
    );
    final tree = ResourceFamilyTree(project, resourceCatalog(project));
    final search = TextEditingController();
    addTearDown(search.dispose);
    final filters = ResourceCatalogFilterState();
    var searches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, rebuild) => SizedBox(
              width: 900,
              child: MapWorkspacePaletteDockFilters(
                tree: tree,
                filters: filters,
                search: search,
                onChanged: () => rebuild(() => searches++),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('resource-quick-houses')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resource-quick-houses')));
    await tester.pump();
    expect(filters.familyId, 'houses');

    await tester.tap(find.text('Familles'));
    await tester.pumpAndSettle();
    expect(find.byType(ResourceFamilyTreeView), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('resource-nature-family-trees')),
    );
    await tester.pumpAndSettle();
    expect(filters.familyId, 'trees');
    expect(find.byType(ResourceFamilyTreeView), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('resource-quick-trees'))).dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('resource-quick-houses')))
            .dx,
      ),
    );

    await tester.tap(find.byTooltip('Rechercher une ressource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'arbre');
    await tester.pump();
    expect(search.text, 'arbre');
    expect(searches, 3);
    await tester.tap(find.byTooltip('Masquer la recherche'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(search.text, isEmpty);
    expect(searches, 4);
    await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
    await tester.pumpAndSettle();
    tester
        .widget<StudioSelect>(
          find.byKey(const ValueKey('resource-filter-context')),
        )
        .onChanged!('interior');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
    await tester.pumpAndSettle();
    expect(filters.context, ResourceCatalogContext.interior);
    expect(filters.familyId, 'trees');
    expect(searches, 5);
  });

  testWidgets('the map dock filters real cards and clears a hidden search', (
    tester,
  ) async {
    final project = workspaceProject.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'house',
            familyId: 'buildings',
          ),
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'tree',
            familyId: 'trees',
          ),
        ],
      ),
      elements: [
        workspaceElement.copyWith(
          id: 'house',
          name: 'Maison',
          categoryId: 'houses',
        ),
        workspaceElement.copyWith(
          id: 'tree',
          name: 'Arbre',
          categoryId: 'nature',
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState();
    final search = TextEditingController();
    addTearDown(view.dispose);
    addTearDown(search.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: MapWorkspacePaletteDock(
                project: project,
                document: document,
                visuals: WorkspaceTestVisuals(),
                view: view,
                search: search,
                onChanged: () {},
                onResources: () {},
                onOpenFullPalette: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('decor-house')), findsOneWidget);
    expect(find.byKey(const ValueKey('decor-tree')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resource-quick-trees')));
    await tester.pump();
    expect(view.resourceFilters.familyId, 'trees');
    expect(find.byKey(const ValueKey('decor-house')), findsNothing);
    expect(find.byKey(const ValueKey('decor-tree')), findsOneWidget);

    await tester.tap(find.byTooltip('Rechercher une ressource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'maison');
    await tester.pump();
    expect(
      find.text('Aucune ressource ne correspond aux filtres.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Masquer la recherche'));
    await tester.pumpAndSettle();
    expect(search.text, isEmpty);
    expect(find.byKey(const ValueKey('decor-tree')), findsOneWidget);

    final initialGrid = tester.widget<GridView>(find.byType(GridView).first);
    expect(
      (initialGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    await tester.drag(
      find.byKey(const ValueKey('palette-resize-handle')),
      const Offset(0, -110),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(MapWorkspacePaletteDock)).height,
      greaterThan(250),
    );
    final enlargedGrid = tester.widget<GridView>(find.byType(GridView).first);
    expect(
      (enlargedGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
      reason: 'Palette utile : ${tester.getSize(find.byType(GridView).first)}',
    );
    await tester.tap(find.byTooltip('Réduire'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
