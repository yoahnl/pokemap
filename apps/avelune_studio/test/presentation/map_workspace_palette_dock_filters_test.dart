import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock_filters.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_category_filter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_category_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('quick categories and full tree keep the chosen category', (
    tester,
  ) async {
    final project = workspaceProject.copyWith(
      elementCategories: const [
        ProjectElementCategory(id: 'buildings', name: 'Bâtiments'),
        ProjectElementCategory(
          id: 'houses',
          name: 'Maisons',
          parentCategoryId: 'buildings',
        ),
        ProjectElementCategory(id: 'nature', name: 'Nature'),
      ],
      elements: [
        workspaceElement.copyWith(id: 'house', categoryId: 'houses'),
        workspaceElement.copyWith(id: 'tree', categoryId: 'nature'),
      ],
    );
    final tree = ResourceCategoryTree(
      project,
      ResourceKind.decors,
      resourceCatalog(project),
    );
    final search = TextEditingController();
    addTearDown(search.dispose);
    var selected = '';
    var searches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, rebuild) => SizedBox(
              width: 900,
              child: MapWorkspacePaletteDockFilters(
                tree: tree,
                selected: selected,
                search: search,
                onCategoryChanged: (value) => rebuild(() => selected = value),
                onSearchChanged: () => searches++,
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
    expect(selected, 'houses');

    await tester.tap(find.text('Catégories'));
    await tester.pumpAndSettle();
    expect(find.byType(ResourceCategoryFilter), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resource-category-nature')));
    await tester.pumpAndSettle();
    expect(selected, 'nature');
    expect(find.byType(ResourceCategoryFilter), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('resource-quick-nature'))).dx,
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
    expect(searches, 1);
    await tester.tap(find.byTooltip('Masquer la recherche'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(search.text, isEmpty);
    expect(searches, 2);
  });

  testWidgets('the map dock filters real cards and clears a hidden search', (
    tester,
  ) async {
    final project = workspaceProject.copyWith(
      elementCategories: const [
        ProjectElementCategory(id: 'houses', name: 'Maisons'),
        ProjectElementCategory(id: 'nature', name: 'Nature'),
      ],
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
    await tester.tap(find.byKey(const ValueKey('resource-quick-nature')));
    await tester.pump();
    expect(view.decorCategoryId, 'nature');
    expect(find.byKey(const ValueKey('decor-house')), findsNothing);
    expect(find.byKey(const ValueKey('decor-tree')), findsOneWidget);

    await tester.tap(find.byTooltip('Rechercher une ressource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'maison');
    await tester.pump();
    expect(find.text('Aucune ressource dans cette catégorie.'), findsOneWidget);
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
    await tester.tap(find.text('Réduire'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
