import 'package:avelune_studio/features/map_workspace/application/map_palette_queries.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_family_tree.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('quick family projections preserve the chosen family and rank nested leaves first', () {
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
    final choices = mapPaletteQuickFamilies(tree, 'trees');
    expect(choices.first.id, 'trees');
    expect(
      choices.map((node) => node.id).where((id) => id == 'trees'),
      hasLength(1),
    );
    expect(choices.map((node) => node.id), contains('houses'));
    expect(mapPaletteQuickFamilies(tree, '').first.id, 'houses');
  });

  test('family and text filters combine without hiding the full catalogue', () {
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
    final view = MapWorkspaceEditingState();
    final before = view.paletteResourcesFor(
      project,
      'a',
      'Décors',
      applyFilters: false,
    );
    view.resourceFilters.familyId = 'trees';
    expect(
      view.paletteResourcesFor(project, 'a', 'Décors').map((item) => item.id),
      ['tree'],
    );
    view.resourceFilters.query = 'maison';
    expect(view.paletteResourcesFor(project, 'a', 'Décors'), isEmpty);
    view.resourceFilters.query = '';
    expect(
      view.paletteResourcesFor(project, 'a', 'Décors').map((item) => item.id),
      ['tree'],
    );
    expect(
      view
          .paletteResourcesFor(project, 'a', 'Décors', applyFilters: false)
          .map((item) => item.id),
      before.map((item) => item.id),
    );
  });
}
