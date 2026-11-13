import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

final _project = workspaceProject.copyWith(
  elements: [
    workspaceElement.copyWith(id: 'bed', name: 'Lit'),
    workspaceElement.copyWith(id: 'desk', name: 'Bureau'),
  ],
);

void main() {

  test('a model released by a 2D catalogue disarms placement', () {
    final view = MapWorkspaceEditingState()
      ..model3d = spatialEnvironmentProject().models3d.first
      ..tool = StudioMapTool.place;
    view.reconcileResources(_project, mapId: 'a');
    expect(view.model3d, isNull);
    expect(view.tool, StudioMapTool.select);
  });

  test('an empty catalogue differs from resources hidden by a query', () {
    final view = MapWorkspaceEditingState();
    final empty = workspaceProject.copyWith(elements: const []);
    expect(
      view.paletteResourcesFor(empty, 'a', 'Décors', applyFilters: false),
      isEmpty,
    );
    expect(
      view.paletteResourcesFor(_project, 'a', 'Décors', applyFilters: false),
      hasLength(2),
    );
    view.resourceFilters.query = 'armoire';
    expect(view.paletteResourcesFor(_project, 'a', 'Décors'), isEmpty);
    view.resourceFilters.query = '';
    expect(
      view.paletteResourcesFor(_project, 'a', 'Décors').map((item) => item.id),
      containsAll(['bed', 'desk']),
    );
  });
}
