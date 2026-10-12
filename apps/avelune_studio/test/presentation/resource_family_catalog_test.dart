import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_family_tree.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

ProjectManifest _project() => workspaceProject.copyWith(
  elements: [
    workspaceElement.copyWith(id: 'shared', name: 'Chêne', tags: ['Canopée']),
    workspaceElement.copyWith(id: 'map-a', name: 'Bouleau'),
    workspaceElement.copyWith(id: 'map-b', name: 'Cèdre'),
    workspaceElement.copyWith(id: 'unclassified', name: 'Banc'),
  ],
  resourceLibraryCatalog: ResourceLibraryCatalog(
    families: [
      ResourceFamily(id: 'conifers', name: 'Conifères', parentId: 'trees'),
      ResourceFamily(id: 'cedars', name: 'Cèdres', parentId: 'conifers'),
      ResourceFamily(id: 'empty', name: 'Vide', parentId: 'trees'),
    ],
    entries: [
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'shared',
        familyId: 'trees',
      ),
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'map-a',
        familyId: 'conifers',
        mapId: 'a',
      ),
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'map-b',
        familyId: 'cedars',
        mapId: 'b',
      ),
    ],
  ),
);

void main() {
  test(
    '3D decor palette hides components while semantic sources stay available',
    () {
      final base = spatialEnvironmentProject();
      final project = base.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'oak',
              role: ResourceLibraryRole.component,
            ),
          ],
        ),
      );
      final view = MapWorkspaceViewState()..paletteTab = 'Décors';
      expect(view.paletteResources(project, 'a'), isEmpty);
      expect(
        view.paletteResources(project, 'a', applyFilters: false).single.id,
        'oak',
      );
      view.resourceFilters.showComponents = true;
      expect(view.paletteResources(project, 'a').single.id, 'oak');
      view.model3d = project.models3d.single;
      view.resourceFilters.showComponents = false;
      view.reconcileResources(project, mapId: 'a');
      expect(view.model3d?.id, 'oak');
      expect(
        project.resourceLibraryCatalog.availableForMap('model3d', 'oak', 'a'),
        isTrue,
      );
    },
  );
  test(
    'component role hides choices without changing availability or dimensions',
    () {
      final base = _project();
      final project = base.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: base.resourceLibraryCatalog.families,
          entries: [
            for (final entry in base.resourceLibraryCatalog.entries)
              ResourceLibraryEntry(
                resourceKind: entry.resourceKind,
                resourceId: entry.resourceId,
                familyId: entry.familyId,
                mapId: entry.mapId,
                role: entry.resourceId == 'map-a'
                    ? ResourceLibraryRole.component
                    : ResourceLibraryRole.standard,
              ),
          ],
        ),
      );
      final items = resourceCatalog(project);
      final filters = ResourceCatalogFilterState(familyId: 'trees');
      expect(
        filterResourceCatalog(project, items, filters).map((item) => item.id),
        ['shared', 'map-b'],
      );
      expect(
        ResourceFamilyTree(
          project,
          items,
        ).nodes.singleWhere((node) => node.id == 'trees').count,
        2,
      );
      expect(
        project.resourceLibraryCatalog.availableForMap('element', 'map-a', 'a'),
        isTrue,
      );
      filters.showComponents = true;
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
          forMapPicker: true,
          activeMapId: 'a',
        ).map((item) => item.id),
        ['shared', 'map-a'],
      );
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
          forMapPicker: true,
          activeMapId: 'b',
        ).map((item) => item.id),
        ['shared', 'map-b'],
      );
      expect(
        ResourceFamilyTree(
          project,
          items,
          showComponents: true,
        ).nodes.singleWhere((node) => node.id == 'trees').count,
        3,
      );
      expect(filters.copy().showComponents, isTrue);
      final copied = ResourceCatalogFilterState()..copyFrom(filters);
      expect(copied.showComponents, isTrue);
      filters.reset();
      expect(filters.showComponents, isFalse);
    },
  );
  test('nature family descendants intersect usage search and availability', () {
    final project = _project();
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
      final project = _project();
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
    'family tree preserves empty custom nodes and counts descendants once',
    () {
      final project = _project();
      final tree = ResourceFamilyTree(project, resourceCatalog(project));
      expect(tree.total, 5);
      expect(tree.unclassified, 2);
      expect(tree.nodes.singleWhere((node) => node.id == 'trees').count, 3);
      expect(tree.nodes.singleWhere((node) => node.id == 'conifers').count, 2);
      final cedar = tree.nodes.singleWhere((node) => node.id == 'cedars');
      expect(
        (cedar.parentId, cedar.depth, cedar.count, cedar.custom),
        ('conifers', 2, 1, true),
      );
      expect(tree.nodes.singleWhere((node) => node.id == 'empty').count, 0);
      final mapTree = ResourceFamilyTree(
        project,
        resourceCatalog(project),
        activeMapId: 'a',
        forMapPicker: true,
      );
      expect(mapTree.nodes.singleWhere((node) => node.id == 'trees').count, 2);
    },
  );

  test(
    'all canonical kinds retain typed identity and dimension eligibility',
    () {
      final project = _project().copyWith(
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
