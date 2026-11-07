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
