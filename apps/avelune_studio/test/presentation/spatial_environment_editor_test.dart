import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:avelune_studio/features/resources/application/resource_family_tree.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test('environment candidates retain nature families eligibility exclusions and spatial offsets', () {
    final base = spatialEnvironmentProject();
    final project = base.copyWith(
      models3d: [
        ...base.models3d,
        ProjectModel3dEntry(
          id: 'other-oak',
          name: 'Chêne privé',
          sourceAssetId: 'other-source',
          relativePath: 'assets/models3d/other-oak.glb',
          inspection: base.models3d.single.inspection,
        ),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(id: 'oaks', name: 'Chênes', parentId: 'trees'),
        ],
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'oak',
            familyId: 'oaks',
          ),
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'other-oak',
            familyId: 'oaks',
            mapId: 'a',
          ),
        ],
      ),
    );
    final candidates = environmentPaletteCandidates(project);
    final filters = ResourceCatalogFilterState(showComponents: true);
    final eligible = filterResourceCatalog(
      project,
      candidates,
      filters,
      forMapPicker: true,
    );
    expect(eligible.map((item) => item.id), ['oak']);
    final tree = ResourceFamilyTree(
      project,
      candidates,
      forMapPicker: true,
      filters: filters,
    );
    expect(tree.nodes.singleWhere((node) => node.id == 'oaks').count, 1);
    filters.familyId = 'oaks';
    final selected = filterResourceCatalog(
      project,
      candidates,
      filters,
      forMapPicker: true,
    ).single;
    expect(selected.id, 'oak');
    final draft = EnvironmentDraft()..name = 'Bosquet';
    draft.add(selected.id, spatial: selected.model3d != null);
    draft.setOffsetInput('oak', 'x', '0,25');
    draft.setOffsetInput('oak', 'z', '-0,5');
    expect(draft.build().palette.single.modelId, 'oak');
    expect(draft.build().palette.single.cellOffsetWorld!.x, .25);
    expect(draft.build().palette.single.cellOffsetWorld!.z, -.5);
    expect(
      draft.build().palette.single.collisionMode,
      EnvironmentCollisionMode.useElementDefault,
    );
    final remaining = environmentPaletteCandidates(
      project,
      excluded: {'model3d:oak'},
    );
    expect(
      filterResourceCatalog(project, remaining, filters, forMapPicker: true),
      isEmpty,
    );
  });

  test('catalogue keeps 2D and spatial environments eligible only in their dimension', () {
    final spatial = spatialEnvironmentProject();
    final item = resourceCatalog(spatial)
        .firstWhere((item) => item.environment != null);
    expect(item.compatibleWith(ProjectDimension.threeD), isTrue);
    expect(item.compatibleWith(ProjectDimension.twoD), isFalse);
    final model = resourceCatalog(spatial)
        .firstWhere((item) => item.model3d != null);
    expect(model.usages, contains(ResourceCatalogUsage.scatter));
    final planar = ResourceItem(
      id: 'flowers',
      name: 'Fleurs',
      kind: ResourceKind.decors,
      environment: EnvironmentPreset(
        id: 'flowers',
        name: 'Fleurs',
        templateId: 'manual',
        sortOrder: 0,
        palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
      ),
    );
    expect(planar.compatibleWith(ProjectDimension.threeD), isFalse);
    expect(planar.compatibleWith(ProjectDimension.twoD), isTrue);
  });
}
