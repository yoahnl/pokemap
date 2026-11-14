import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import 'resource_family_catalog_fixture.dart';

void main() {
  test('nature family descendants intersect usage search and availability', () {
    final project = familyCatalogProject();
    final items = resourceCatalog(project);
    final filters = ResourceCatalogFilterState(
      familyId: 'trees',
      usage: ResourceCatalogUsage.place,
    );
    expect(
      filterResourceCatalog(project, items, filters).map((item) => item.id),
      ['shared', 'map-a', 'map-b'],
    );
    filters.scope = ResourceCatalogScope.project;
    expect(filterResourceCatalog(project, items, filters).single.id, 'shared');
    filters.query = ' CaNoPéE ';
    expect(filterResourceCatalog(project, items, filters).single.id, 'shared');
    filters.query = 'absent';
    expect(filterResourceCatalog(project, items, filters), isEmpty);
    filters.reset();
    filters.familyId = unclassifiedResourceFamily;
    expect(
      filterResourceCatalog(project, items, filters).map((item) => item.id),
      ['unclassified', 'atlas'],
    );
  });

  test(
    'global private scope includes other maps while map pickers hide them',
    () {
      final project = familyCatalogProject();
      final items = resourceCatalog(project);
      final filters = ResourceCatalogFilterState(
        familyId: 'trees',
        scope: ResourceCatalogScope.map,
      );
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
          activeMapId: 'a',
        ).map((item) => item.id),
        ['map-a', 'map-b'],
      );
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
          activeMapId: 'a',
          forMapPicker: true,
        ).single.id,
        'map-a',
      );
      filters.scope = ResourceCatalogScope.all;
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
          activeMapId: 'b',
          forMapPicker: true,
        ).map((item) => item.id),
        ['shared', 'map-b'],
      );
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
          forMapPicker: true,
        ).single.id,
        'shared',
      );
    },
  );

  test(
    'all canonical kinds retain typed identity and dimension eligibility',
    () {
      final project = familyCatalogProject().copyWith(
        characters: const [
          ProjectCharacterEntry(
            id: 'shared',
            name: 'Gardien',
            tilesetId: 'atlas',
          ),
        ],
        borderCatalog: testBorderCatalog(),
        environmentPresets: [
          EnvironmentPreset(
            id: 'forest',
            name: 'Forêt',
            templateId: 'woodland',
            sortOrder: 0,
            defaultParams: EnvironmentGenerationParams.standard(),
            palette: [EnvironmentPaletteItem(elementId: 'shared', weight: 1)],
          ),
        ],
        models3d: [
          ProjectModel3dEntry(
            id: 'shared',
            name: 'Chêne en volume',
            sourceAssetId: 'oak-source',
            relativePath: 'assets/models3d/shared.glb',
            inspection: Model3dInspection(
              bounds: Model3dBounds(
                min: Model3dVector3.zero,
                max: Model3dVector3(x: 1, y: 2, z: 1),
              ),
              meshCount: 1,
              triangleCount: 4,
            ),
          ),
        ],
      );
      final catalog = resourceCatalog(project);
      expect(
        catalog.map((item) => item.identity).toSet(),
        containsAll([
          'element:shared',
          'model3d:shared',
          'character:shared',
          'borderBlueprint:muret',
          'environmentPreset:forest',
          'tileset:atlas',
        ]),
      );
      final global = filterResourceCatalog(
        project,
        catalog,
        ResourceCatalogFilterState(),
      );
      expect(global.length, catalog.length);
      final twoD = filterResourceCatalog(
        project,
        catalog,
        ResourceCatalogFilterState(),
        activeMapId: 'a',
        forMapPicker: true,
      );
      expect(twoD.any((item) => item.model3d != null), isFalse);
      expect(twoD.any((item) => item.character != null), isTrue);
      final threeD = filterResourceCatalog(
        project.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
        catalog,
        ResourceCatalogFilterState(),
        activeMapId: 'a',
        forMapPicker: true,
      );
      expect(threeD.map((item) => item.canonicalKind).toSet(), {
        'model3d',
        'character',
      });
      final state = ResourceLibraryState()
        ..select(catalog.singleWhere((item) => item.model3d != null));
      expect(state.reconcileSelection(catalog)?.canonicalKind, 'model3d');
      expect(state.selectedIdentity, 'model3d:shared');
    },
  );
}
