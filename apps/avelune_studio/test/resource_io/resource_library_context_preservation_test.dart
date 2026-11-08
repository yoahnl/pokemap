import 'dart:io';

import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/uwu_resource_host.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 8);
}

Future<Map<String, String>> _mapFiles(Directory directory) async => {
  for (final file in Directory(
    '${directory.path}/maps',
  ).listSync().whereType<File>())
    file.uri.pathSegments.last: await file.readAsString(),
};

void main() {
  _removedSelectionTests();
  testWidgets(
    'a multiple selection stays on the same identities after sort and view changes',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      await _tap(tester, 'resource-multi-select');
      await _tap(tester, 'resource-mark-element:arbre');
      await _tap(tester, 'resource-mark-element:caisse');
      expect(host.navigation.library.marked, {
        'element:arbre',
        'element:caisse',
      });
      expect(find.text('2 ressources sélectionnées'), findsOneWidget);

      final selectedBefore = host.navigation.library.selectedIdentity;
      await tester.tap(find.byType(DropdownButtonFormField<ResourceSort>));
      await pumpIo(tester, frames: 4);
      await tester.tap(find.text('Nom Z à A').last);
      await pumpIo(tester, frames: 6);
      await tester.tap(find.byTooltip('Mode liste').first);
      await pumpIo(tester, frames: 6);

      expect(host.navigation.library.marked, {
        'element:arbre',
        'element:caisse',
      });
      expect(host.navigation.library.selectedIdentity, selectedBefore);
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('resource-mark-element:arbre')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('resource-mark-element:rocher')),
            )
            .value,
        isFalse,
      );
      expect(find.text('2 ressources sélectionnées'), findsOneWidget);
    },
  );

  testWidgets(
    'opening a decor workshop and coming back keeps the library context and the map',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final library = host.navigation.library;
      final mapBefore = host.fixture.controller.active!.base.mapId;
      await tester.tap(find.text('Ressources utilisables'));
      await pumpIo(tester, frames: 6);
      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher dans les ressources').first,
        'r',
      );
      await pumpIo(tester, frames: 6);
      await tester.tap(find.text('Rocher bleu').first);
      await pumpIo(tester, frames: 6);
      final selected = library.selectedIdentity;
      expect(selected, 'element:rocher');
      expect(library.query, 'r');
      expect(library.filters.usableOnly, isTrue);

      final edit = find.text('Modifier le décor').last;
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await pumpIo(tester, frames: 8);
      expect(find.text('Retour aux ressources'), findsWidgets);
      await tester.tap(find.text('Retour aux ressources').last);
      await pumpIo(tester, frames: 8);

      expect(library.query, 'r');
      expect(library.filters.usableOnly, isTrue);
      expect(library.selectedIdentity, selected);
      expect(
        find.byKey(const ValueKey('resource-filter-tag-usable')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find
                  .widgetWithText(TextField, 'Rechercher dans les ressources')
                  .first,
            )
            .controller!
            .text,
        'r',
      );
      final back = find.textContaining('Carte : ').first;
      await tester.tap(back);
      await pumpIo(tester, frames: 8);
      expect(find.byType(ResourceLibraryScreen), findsNothing);
      expect(host.fixture.controller.active!.base.mapId, mapBefore);
    },
  );

  testWidgets('a rebuilt library returns to the remembered scroll offset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final template = workspaceProject.elements.first;
    final project = workspaceProject.copyWith(
      elements: [
        for (var index = 0; index < 40; index++)
          template.copyWith(id: 'decor_$index', name: 'Décor $index'),
      ],
    );
    final library = ResourceLibraryState();
    Widget screen() => MaterialApp(
      home: Scaffold(
        body: ResourceLibraryScreen(
          project: project,
          visuals: WorkspaceTestVisuals(),
          state: library,
          onUse: (_) {},
          onEdit: (_) {},
          onTerrain: (_) {},
          onCreateBorder: () {},
          onResumeBorder: (_) {},
          onImport: () {},
          onBack: () {},
        ),
      ),
    );
    Finder grid() => find
        .descendant(
          of: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == 'StudioResourceGrid',
          ),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.drag(grid(), const Offset(0, -300));
    await tester.pumpAndSettle();
    final offset = library.offset;
    expect(offset, greaterThan(0));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Atelier'))),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(grid()).position.pixels, offset);
  });

  testWidgets(
    'classifying two marked resources leaves other resources and map occurrences untouched',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final mapsBefore = (await tester.runAsync(
        () => _mapFiles(host.fixture.directory),
      ))!;
      await _tap(tester, 'resource-multi-select');
      await _tap(tester, 'resource-mark-element:arbre');
      await _tap(tester, 'resource-mark-element:rocher');
      await _tap(tester, 'resource-marked-classify');
      expect(find.text('Ranger 2 ressources'), findsOneWidget);
      await host.choose('resource-batch-family', 'Arbres');
      await host.tap('resource-management-save');

      final project = await host.reopen();
      final catalog = project.resourceLibraryCatalog;
      expect(catalog.entryFor('element', 'arbre')?.familyId, 'trees');
      expect(catalog.entryFor('element', 'rocher')?.familyId, 'trees');
      expect(catalog.entryFor('element', 'caisse'), isNull);
      expect(catalog.entryFor('tileset', 'atelier'), isNull);
      expect(catalog.entryFor('character', 'guide'), isNull);
      final mapsAfter = (await tester.runAsync(
        () => _mapFiles(host.fixture.directory),
      ))!;
      expect(mapsAfter, mapsBefore);
      expect(host.navigation.library.marked, {
        'element:arbre',
        'element:rocher',
      });
    },
  );

  testWidgets(
    'filtering the library leaves the map palette filters unchanged',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final palette = MapWorkspaceViewState();
      addTearDown(palette.dispose);
      palette.resourceFilters.context = ResourceCatalogContext.exterior;
      final paletteBefore = palette.resourceFilters.copy();
      final paletteResults = palette
          .paletteResources(workspaceProject, 'a')
          .map((item) => item.identity)
          .toList();
      final library = ResourceLibraryState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceLibraryScreen(
              project: workspaceProject,
              visuals: WorkspaceTestVisuals(),
              state: library,
              onUse: (_) {},
              onEdit: (_) {},
              onTerrain: (_) {},
              onCreateBorder: () {},
              onResumeBorder: (_) {},
              onImport: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ressources utilisables'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('resource-filter-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Décors 2D').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
      await tester.pumpAndSettle();

      expect(library.filters.usableOnly, isTrue);
      expect(library.filters.typeKind, 'element');
      expect(find.byKey(const ValueKey('resource-filter-tag-type')), findsOne);
      expect(
        find.byKey(const ValueKey('resource-filter-tag-usable')),
        findsOne,
      );
      expect(palette.resourceFilters.typeKind, isEmpty);
      expect(palette.resourceFilters.usableOnly, isFalse);
      expect(palette.resourceFilters.context, paletteBefore.context);
      expect(palette.resourceFilters.scope, paletteBefore.scope);
      expect(
        palette
            .paletteResources(workspaceProject, 'a')
            .map((item) => item.identity)
            .toList(),
        paletteResults,
      );

      await tester.tap(find.byTooltip('Retirer le filtre Décors 2D'));
      await tester.pumpAndSettle();
      expect(library.filters.typeKind, isEmpty);
      expect(library.filters.usableOnly, isTrue);
    },
  );

  test(
    'usable resources exclude components, other profiles and other maps',
    () {
      final project = workspaceProject.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: workspaceElement.id,
              role: ResourceLibraryRole.component,
            ),
          ],
        ),
      );
      final items = resourceCatalog(project);
      final complete = filterResourceCatalog(
        project,
        items,
        ResourceCatalogFilterState()..showComponents = true,
        activeMapId: 'a',
      );
      final usable = filterResourceCatalog(
        project,
        items,
        ResourceCatalogFilterState()
          ..showComponents = true
          ..usableOnly = true,
        activeMapId: 'a',
      );
      expect(
        complete.map((item) => item.identity),
        contains('element:${workspaceElement.id}'),
      );
      expect(
        usable.map((item) => item.identity),
        isNot(contains('element:${workspaceElement.id}')),
      );
    },
  );
}

void _removedSelectionTests() {
  test(
    'a removed selection is reported instead of jumping to another resource',
    () {
      final kept = ResourceItem(
        id: 'kept',
        name: 'Conservé',
        kind: ResourceKind.decors,
        element: workspaceElement.copyWith(id: 'kept', name: 'Conservé'),
      );
      final removed = ResourceItem(
        id: 'removed',
        name: 'Retiré',
        kind: ResourceKind.decors,
        element: workspaceElement.copyWith(id: 'removed', name: 'Retiré'),
      );
      final state = ResourceLibraryState()..select(removed);
      state.reconcileRemoval([kept], [kept]);
      expect(state.selectionRemoved, isFalse);
      expect(state.reconcileSelection([kept, removed]), removed);
      state.reconcileRemoval([kept, removed], [kept]);
      expect(state.selectionRemoved, isTrue);
      expect(state.reconcileSelection([kept]), isNull);
      expect(state.reconcileSelection([kept]), isNull);
      state.select(kept);
      expect(state.selectionRemoved, isFalse);
      expect(state.reconcileSelection([kept]), kept);
    },
  );

  testWidgets('the detail panel names a removed selection', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = ResourceLibraryState();
    final second = workspaceElement.copyWith(
      id: 'second',
      name: 'Second décor',
    );
    Widget screen(ProjectManifest project) => MaterialApp(
      home: Scaffold(
        body: ResourceLibraryScreen(
          project: project,
          visuals: WorkspaceTestVisuals(),
          state: state,
          onUse: (_) {},
          onEdit: (_) {},
          onTerrain: (_) {},
          onCreateBorder: () {},
          onResumeBorder: (_) {},
          onImport: () {},
          onBack: () {},
        ),
      ),
    );
    final project = workspaceProject.copyWith(
      elements: [workspaceElement, second],
    );
    await tester.pumpWidget(screen(project));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('resource-card-element:second')),
    );
    await tester.pumpAndSettle();
    expect(state.selectedIdentity, 'element:second');
    await tester.pumpWidget(
      screen(project.copyWith(elements: [workspaceElement])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cette ressource n’existe plus'), findsOneWidget);
    expect(state.selectedIdentity, isNull);
  });
}
