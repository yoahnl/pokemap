import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AuthoringResourceFixture> open() async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    return fixture;
  }

  test('a multiple selection stays on the same identities after sort and view changes', () async {
    final fixture = await open();
    final library = fixture.navigation.library;
    final items = resourceCatalog(fixture.workspace.project!);
    final tree = items.singleWhere((item) => item.identity == 'element:arbre');
    final box = items.singleWhere((item) => item.identity == 'element:caisse');
    library.select(tree);
    library.marking = true;
    library.toggleMark(tree);
    library.toggleMark(box);
    final selectedBefore = library.selectedIdentity;
    expect(library.marked, {'element:arbre', 'element:caisse'});
    library.sort = ResourceSort.nameDescending;
    library.grid = false;
    library.reconcileSelection(library.visibleItems(items));
    expect(library.marked, {'element:arbre', 'element:caisse'});
    expect(library.selectedIdentity, selectedBefore);
    expect(library.markedItems(items).map((item) => item.identity).toSet(), {
      'element:arbre',
      'element:caisse',
    });
    expect(library.marked, isNot(contains('element:rocher')));
  });

  test('opening a decor workshop and coming back keeps stored library context and the map', () async {
    final fixture = await open();
    final navigation = fixture.navigation;
    final library = navigation.library;
    final mapBefore = fixture.workspace.active!.base.mapId;
    final rock = resourceCatalog(fixture.workspace.project!)
        .singleWhere((item) => item.identity == 'element:rocher');
    library.filters.usableOnly = true;
    library.query = 'r';
    library.offset = 176;
    library.select(rock);
    final selected = library.selectedIdentity;
    navigation.edit(rock);
    expect(navigation.page, ResourcePage.decor);
    navigation.showLibrary();
    expect(navigation.page, ResourcePage.library);
    expect(library.query, 'r');
    expect(library.filters.usableOnly, isTrue);
    expect(library.selectedIdentity, selected);
    expect(library.offset, 176);
    expect(fixture.workspace.active!.base.mapId, mapBefore);
  });

  test('classifying two marked resources leaves other resources and map occurrences untouched', () async {
    final fixture = await open();
    final navigation = fixture.navigation;
    final items = resourceCatalog(fixture.workspace.project!);
    for (final id in ['arbre', 'rocher']) {
      navigation.library.toggleMark(
        items.singleWhere((item) => item.identity == 'element:$id'),
      );
    }
    final mapsBefore = await fixture.mapFiles();
    final selected = navigation.library.markedItems(items);
    final revision = await navigation.captureResourceRevision();
    final preparation = await navigation.prepareOperation(
      'resource.classify_batch',
      {
        'entries': [
          for (final item in selected)
            {
              'resourceKind': item.canonicalKind,
              'resourceId': item.id,
              'familyId': 'trees',
            },
        ],
      },
      expectedSnapshotRevision: revision,
    );
    await navigation.applyPrepared(preparation);
    final project = await fixture.reopen();
    final catalog = project.resourceLibraryCatalog;
    expect(catalog.entryFor('element', 'arbre')?.familyId, 'trees');
    expect(catalog.entryFor('element', 'rocher')?.familyId, 'trees');
    expect(catalog.entryFor('element', 'caisse'), isNull);
    expect(catalog.entryFor('tileset', 'atelier'), isNull);
    expect(catalog.entryFor('character', 'guide'), isNull);
    expect(await fixture.mapFiles(), mapsBefore);
    expect(navigation.library.marked, {'element:arbre', 'element:rocher'});
  });

  test('filtering the library leaves the map palette filters unchanged', () {
    final palette = MapWorkspaceEditingState();
    palette.resourceFilters.context = ResourceCatalogContext.exterior;
    final before = palette.resourceFilters.copy();
    final results = palette
        .paletteResourcesFor(workspaceProject, 'a', 'Décors')
        .map((item) => item.identity)
        .toList();
    final library = ResourceLibraryState();
    library.filters.usableOnly = true;
    library.filters.typeKind = 'element';
    expect(library.filters.usableOnly, isTrue);
    expect(library.filters.typeKind, 'element');
    expect(palette.resourceFilters.typeKind, isEmpty);
    expect(palette.resourceFilters.usableOnly, isFalse);
    expect(palette.resourceFilters.context, before.context);
    expect(palette.resourceFilters.scope, before.scope);
    expect(
      palette
          .paletteResourcesFor(workspaceProject, 'a', 'Décors')
          .map((item) => item.identity)
          .toList(),
      results,
    );
    library.filters.typeKind = '';
    expect(library.filters.typeKind, isEmpty);
    expect(library.filters.usableOnly, isTrue);
  });
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
}
