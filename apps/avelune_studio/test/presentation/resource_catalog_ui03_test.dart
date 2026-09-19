import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

const _items = [
  ResourceItem(
    id: 'birch',
    name: 'Bouleau',
    kind: ResourceKind.decors,
    category: 'nature',
    tags: ['Forêt', 'BLANC'],
  ),
  ResourceItem(id: 'oak-b', name: 'Arbre', kind: ResourceKind.decors),
  ResourceItem(id: 'oak-a', name: 'arbre', kind: ResourceKind.decors),
  ResourceItem(id: 'oak-b', name: 'Zoo', kind: ResourceKind.images),
  ResourceItem(id: 'atlas', name: 'Atlas', kind: ResourceKind.images),
];

void main() {
  test('local search includes names and tags without case sensitivity', () {
    final state = ResourceLibraryState()..query = ' bLaNc ';
    expect(state.visibleItems(_items).single.id, 'birch');
    state.query = 'BOULE';
    expect(state.visibleItems(_items).single.id, 'birch');
    state.query = 'absent';
    expect(state.visibleItems(_items), isEmpty);
  });

  test('name sorting has stable canonical ties even after catalog refresh', () {
    final state = ResourceLibraryState();
    expect(state.grid, isTrue);
    expect(state.visibleItems(_items).map((item) => item.id), [
      'oak-a',
      'oak-b',
      'birch',
    ]);
    state.sort = ResourceSort.nameDescending;
    expect(
      state.visibleItems(_items.reversed.toList()).map((item) => item.id),
      ['birch', 'oak-a', 'oak-b'],
    );
  });

  test(
    'restored selection survives sorting and filtered selection is valid',
    () {
      final state = ResourceLibraryState()..selectedId = 'oak-b';
      expect(state.reconcileSelection(state.visibleItems(_items))!.id, 'oak-b');
      state.sort = ResourceSort.nameDescending;
      expect(state.reconcileSelection(state.visibleItems(_items))!.id, 'oak-b');
      state.category = 'nature';
      expect(state.reconcileSelection(state.visibleItems(_items))!.id, 'birch');
      expect(state.selectedIdentity, 'decors:birch');
      state.query = 'absent';
      expect(state.reconcileSelection(state.visibleItems(_items)), isNull);
      expect(state.selectedId, isNull);
    },
  );

  test('same ID in a different family does not inherit prior selection', () {
    final state = ResourceLibraryState()..selectedId = 'oak-b';
    state.kind = ResourceKind.images;
    final selection = state.reconcileSelection(state.visibleItems(_items));
    expect(selection!.id, 'atlas');
    expect(state.selectedIdentity, 'images:atlas');
    expect(_items[1].identity, isNot(_items[3].identity));
  });

  test('uncategorized filtering excludes resources with real categories', () {
    final state = ResourceLibraryState()
      ..category = uncategorizedResourceCategory;
    expect(state.visibleItems(_items).map((item) => item.id), [
      'oak-a',
      'oak-b',
    ]);
  });

  test('context reveal changes only filters which hide its exact resource', () {
    final state = ResourceLibraryState()
      ..query = 'BLANC'
      ..category = 'buildings'
      ..sort = ResourceSort.nameDescending
      ..grid = false
      ..offset = 450;
    expect(state.revealPending, isFalse);
    state.reveal(_items.first);
    expect(state.revealPending, isTrue);
    expect(state.query, 'BLANC');
    expect(state.category, '');
    expect(state.sort, ResourceSort.nameDescending);
    expect(state.grid, isFalse);
    expect(state.offset, 450);
    state
      ..category = 'nature'
      ..query = 'atlas';
    state.reveal(_items.first);
    expect(state.category, 'nature');
    expect(state.query, '');
    expect(state.reconcileSelection(state.visibleItems(_items)), _items.first);
  });

  test(
    'category options represent only occupied canonical catalog categories',
    () {
      final manifest = workspaceProject.copyWith(
        elementCategories: [
          const ProjectElementCategory(id: 'nature', name: 'Nature'),
          const ProjectElementCategory(id: 'unused', name: 'Inoccupée'),
        ],
        elements: [
          workspaceElement.copyWith(categoryId: 'nature'),
          workspaceElement.copyWith(id: 'unclassified', categoryId: ''),
        ],
        tilesetFolders: [
          const ProjectTilesetFolder(id: 'source', name: 'Images importées'),
        ],
        tilesets: [
          workspaceProject.tilesets.single.copyWith(folderId: 'source'),
        ],
      );
      expect(resourceCategories(manifest, ResourceKind.decors), {
        '': 'Toutes',
        'nature': 'Nature',
        uncategorizedResourceCategory: 'Sans catégorie',
      });
      expect(resourceCategories(manifest, ResourceKind.images), {
        '': 'Toutes',
        'source': 'Images importées',
      });
      expect(
        resourceCategories(
          manifest,
          ResourceKind.decors,
          items: resourceCatalog(manifest),
        ),
        resourceCategories(manifest, ResourceKind.decors),
      );
      expect(resourceCategories(manifest, ResourceKind.terrains), isEmpty);
      expect(
        resourceCategories(workspaceProject, ResourceKind.images),
        isEmpty,
      );
    },
  );
}
