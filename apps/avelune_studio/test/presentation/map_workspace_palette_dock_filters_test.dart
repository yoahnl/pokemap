import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {

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
