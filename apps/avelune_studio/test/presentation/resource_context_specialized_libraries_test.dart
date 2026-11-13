import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

const _ids = ['interior', 'exterior', 'both', 'unspecified'];

ProjectManifest _project() {
  final base = spatialEnvironmentProject();
  final border = testBorderCatalog().records.single;
  return workspaceProject.copyWith(
    elements: [
      for (final id in _ids) workspaceElement.copyWith(id: id, name: id),
    ],
    models3d: [
      for (final id in _ids)
        ProjectModel3dEntry.fromJson({
          ...base.models3d.single.toJson(),
          'id': id,
          'name': id,
          'relativePath': 'assets/models3d/$id.glb',
        }),
    ],
    environmentPresets: [
      for (final id in _ids)
        EnvironmentPreset(
          id: id,
          name: id,
          templateId: 'manual',
          sortOrder: 0,
          palette: [EnvironmentPaletteItem(elementId: 'interior', weight: 1)],
          defaultParams: EnvironmentGenerationParams.standard(),
        ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: testBorderCatalog().formatVersion,
      visualSnapshots: testBorderCatalog().visualSnapshots,
      records: [
        for (final id in _ids)
          BorderBlueprintRecord(
            id: id,
            draft: border.draft,
            latestPublished: border.latestPublished,
          ),
      ],
    ),
    resourceLibraryCatalog: ResourceLibraryCatalog(
      entries: [
        for (final kind in [
          'element',
          'model3d',
          'environmentPreset',
          'borderBlueprint',
        ])
          for (final value in ResourcePlacementContext.values)
            ResourceLibraryEntry(
              resourceKind: kind,
              resourceId: value.name,
              placementContext: value,
            ),
      ],
    ),
  );
}

void main() {
  test(
    'map environment secondary choices filter positive and negative contexts',
    () {
      final project = _project();
      final view = MapWorkspaceEditingState();
      view.resourceFilters.context = ResourceCatalogContext.interior;
      expect(
        view
            .paletteResourcesFor(project, 'a', 'Environnements')
            .map((item) => item.id),
        ['interior', 'both'],
      );
      view.resourceFilters.context = ResourceCatalogContext.unspecified;
      expect(
        view.paletteResourcesFor(project, 'a', 'Environnements').single.id,
        'unspecified',
      );
    },
  );

  test('map border secondary choices preserve a hidden active brush', () {
    final project = _project();
    final view = MapWorkspaceEditingState()
      ..borderBlueprintId = 'exterior'
      ..tool = StudioMapTool.border;
    view.resourceFilters.context = ResourceCatalogContext.interior;
    expect(
      view.paletteResourcesFor(project, 'a', 'Bordures').map((item) => item.id),
      ['interior', 'both'],
    );
    expect(view.borderBlueprintId, 'exterior');
    expect(view.tool, StudioMapTool.border);
    view.resourceFilters.context = ResourceCatalogContext.unspecified;
    expect(
      view.paletteResourcesFor(project, 'a', 'Bordures').single.id,
      'unspecified',
    );
    expect(view.borderBlueprintId, 'exterior');
    expect(view.tool, StudioMapTool.border);
  });
}
