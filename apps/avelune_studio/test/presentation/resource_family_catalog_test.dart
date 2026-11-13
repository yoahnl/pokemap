import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
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
  test('individual description participates in catalog search', () {
    final project = _project().copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry.fromJson({
            'resourceKind': 'element',
            'resourceId': 'shared',
            'description': 'Ombrage pour les places du village.',
          }),
        ],
      ),
    );
    expect(
      filterResourceCatalog(
        project,
        resourceCatalog(project),
        ResourceCatalogFilterState(query: ' PLACES DU VILLAGE '),
      ).single.id,
      'shared',
    );
  });

  test(
    'context intersects family query scope component and dimension eligibility',
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
                placementContext: entry.resourceId == 'map-b'
                    ? ResourcePlacementContext.exterior
                    : ResourcePlacementContext.both,
                role: entry.resourceId == 'map-a'
                    ? ResourceLibraryRole.component
                    : ResourceLibraryRole.standard,
              ),
          ],
        ),
      );
      final filters = ResourceCatalogFilterState(
        context: ResourceCatalogContext.interior,
        familyId: 'trees',
        query: 'canopée',
        scope: ResourceCatalogScope.project,
        usage: ResourceCatalogUsage.place,
      );
      expect(
        filterResourceCatalog(
          project,
          resourceCatalog(project),
          filters,
        ).single.id,
        'shared',
      );
      filters.query = '';
      filters.scope = ResourceCatalogScope.map;
      expect(
        filterResourceCatalog(project, resourceCatalog(project), filters),
        isEmpty,
      );
      filters.showComponents = true;
      expect(
        filterResourceCatalog(
          project,
          resourceCatalog(project),
          filters,
          forMapPicker: true,
          activeMapId: 'a',
        ).single.id,
        'map-a',
      );
      expect(
        filterResourceCatalog(
          project.copyWith(
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          ),
          resourceCatalog(project),
          filters,
          forMapPicker: true,
          activeMapId: 'a',
        ),
        isEmpty,
      );
    },
  );

  test(
    'context hides a brush without disarming it or inferring from map role',
    () {
      final project = workspaceProject.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: workspaceElement.id,
              placementContext: ResourcePlacementContext.interior,
            ),
          ],
        ),
      );
      final view = MapWorkspaceEditingState()
        ..brush = workspaceElement
        ..tool = StudioMapTool.place;
      expect(view.resourceFilters.context, ResourceCatalogContext.all);
      view.resourceFilters.context = ResourceCatalogContext.exterior;
      expect(view.paletteResourcesFor(project, 'a', 'Décors'), isEmpty);
      view.reconcileResources(project, mapId: 'a', map: workspaceMap('a'));
      expect(view.brush?.id, workspaceElement.id);
      expect(view.tool, StudioMapTool.place);
      expect(view.resourceFilters.context, ResourceCatalogContext.exterior);
      expect(
        project.resourceLibraryCatalog.availableForMap(
          'element',
          workspaceElement.id,
          'a',
        ),
        isTrue,
      );
      view.resourceFilters.context = ResourceCatalogContext.all;
      expect(
        view.paletteResourcesFor(project, 'a', 'Décors').single.id,
        workspaceElement.id,
      );
    },
  );

  test('map role and indoor metadata never infer a context selection', () {
    for (final role in MapRole.values) {
      for (final indoor in [false, true]) {
        final project = workspaceProject.copyWith(
          maps: [
            for (final map in workspaceProject.maps) map.copyWith(role: role),
          ],
        );
        final view = MapWorkspaceEditingState();
        view.reconcileResources(
          project,
          mapId: 'a',
          map: workspaceMap('a')
              .copyWith(mapMetadata: MapMetadata(isIndoor: indoor)),
        );
        expect(
          view.resourceFilters.context,
          ResourceCatalogContext.all,
          reason: '$role $indoor',
        );
        expect(
          view
              .paletteResourcesFor(project, 'a', 'Décors')
              .map((item) => item.id),
          [workspaceElement.id],
        );
        view.resourceFilters.context = ResourceCatalogContext.interior;
        view.reconcileResources(
          project,
          mapId: 'b',
          map: workspaceMap('b')
              .copyWith(mapMetadata: MapMetadata(isIndoor: !indoor)),
        );
        expect(view.resourceFilters.context, ResourceCatalogContext.interior);
      }
    }
  });

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
      final view = MapWorkspaceEditingState();
      expect(view.paletteResourcesFor(project, 'a', 'Décors'), isEmpty);
      expect(
        view
            .paletteResourcesFor(project, 'a', 'Décors', applyFilters: false)
            .single
            .id,
        'oak',
      );
      view.resourceFilters.showComponents = true;
      expect(view.paletteResourcesFor(project, 'a', 'Décors').single.id, 'oak');
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
