import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';
import 'resource_family_catalog_fixture.dart';

void main() {
  test('individual description participates in catalog search', () {
    final project = familyCatalogProject().copyWith(
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
      final base = familyCatalogProject();
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
}
