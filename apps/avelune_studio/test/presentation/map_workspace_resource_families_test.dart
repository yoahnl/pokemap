import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_workspace_resource_families_fixture.dart';

void main() {
  test(
    'context filtering masks a resource without releasing an armed brush',
    () {
      final base = familiesProject();
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
                placementContext: entry.resourceId == 'house'
                    ? ResourcePlacementContext.exterior
                    : ResourcePlacementContext.interior,
              ),
          ],
        ),
      );
      final view = MapWorkspaceEditingState()
        ..brush = project.elements.firstWhere((item) => item.id == 'a-tree')
        ..tool = StudioMapTool.place;
      view.resourceFilters.context = ResourceCatalogContext.exterior;
      expect(
        view.paletteResourcesFor(project, 'a', 'Décors').map((item) => item.id),
        ['house'],
      );
      expect(view.brush!.id, 'a-tree');
      expect(view.tool, StudioMapTool.place);
      view.resourceFilters.context = ResourceCatalogContext.all;
      expect(
        view.paletteResourcesFor(project, 'a', 'Décors').map((item) => item.id),
        contains('a-tree'),
      );
      expect(view.brush!.id, 'a-tree');
    },
  );

  test('draft counts retain a resource search and can report zero results', () {
    final project = familiesProject();
    final view = MapWorkspaceEditingState();
    view.resourceFilters
      ..familyId = 'trees'
      ..query = 'a-tree';
    final all = view.paletteResourcesFor(
      project,
      'a',
      'Décors',
      applyFilters: false,
    );
    final draft = view.resourceFilters.copy()
      ..scope = ResourceCatalogScope.project;
    expect(
      filterResourceCatalog(
        project,
        all,
        view.resourceFilters,
        activeMapId: 'a',
        forMapPicker: true,
      ),
      hasLength(1),
    );
    expect(
      filterResourceCatalog(
        project,
        all,
        draft,
        activeMapId: 'a',
        forMapPicker: true,
      ),
      isEmpty,
    );
    expect(view.resourceFilters.scope, ResourceCatalogScope.all);
    view.resourceFilters.copyFrom(draft);
    expect(view.resourceFilters.familyId, 'trees');
    expect(view.resourceFilters.query, 'a-tree');
    expect(view.paletteResourcesFor(project, 'a', 'Décors'), isEmpty);
  });

  test('resource kinds retain map scope for borders environments characters and tile sources', () {
    final project = familiesProject();
    final view = MapWorkspaceEditingState();
    for (final entry in {
      'Bordures': 'muret',
      'Environnements': 'garden',
      'Personnages': 'guide',
      'Tuiles': 'atlas',
    }.entries) {
      expect(
        view
            .paletteResourcesFor(project, 'a', entry.key)
            .map((item) => item.id),
        [entry.value],
      );
    }
  });

  test('spatial resources retain compatible terrains models characters and environments', () {
    final project = familiesProject().copyWith(
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      environmentPresets: [
        ...familiesProject().environmentPresets,
        EnvironmentPreset(
          id: 'spatial-grove',
          name: 'Bosquet spatial',
          templateId: 'manual',
          sortOrder: 0,
          palette: [EnvironmentPaletteItem(modelId: 'door', weight: 1)],
          defaultParams: EnvironmentGenerationParams.standard(),
        ),
      ],
    );
    final view = MapWorkspaceEditingState();
    expect(
      view.paletteResourcesFor(project, 'a', 'Terrains').map((item) => item.id),
      ['path'],
    );
    view.prepareTerrainPainting(project.smartTileCatalog.presets.single);
    expect(view.terrain!.id, 'path');
    expect(
      view.paletteResourcesFor(project, 'a', 'Décors').map((item) => item.id),
      ['door'],
    );
    expect(
      view
          .paletteResourcesFor(project, 'a', 'Personnages')
          .map((item) => item.id),
      ['guide'],
    );
    expect(
      view
          .paletteResourcesFor(project, 'a', 'Environnements')
          .map((item) => item.id),
      ['spatial-grove'],
    );
    expect(view.paletteResourcesFor(project, 'a', 'Tuiles'), isEmpty);
  });

  test(
    'map changes clear unavailable brushes without resetting family filters',
    () {
      final project = familiesProject();
      final view = MapWorkspaceEditingState();
      view.resourceFilters.familyId = 'trees';
      view.resourceFilters.usage = ResourceCatalogUsage.trace;
      expect(
        view
            .paletteResourcesFor(project, 'a', 'Décors')
            .any((item) => item.id == 'a-tree'),
        isTrue,
      );
      view.reconcileResources(project, mapId: 'a', map: workspaceMap('a'));
      expect(view.resourceFilters.usage, ResourceCatalogUsage.all);
      view.brush = project.elements.firstWhere(
        (element) => element.id == 'a-tree',
      );
      view.tool = StudioMapTool.place;
      view.reconcileResources(project, mapId: 'b', map: workspaceMap('b'));
      expect(view.brush, isNull);
      expect(view.tool, StudioMapTool.select);
      expect(view.resourceFilters.familyId, 'trees');
      view.brush = project.elements.firstWhere(
        (element) => element.id == 'shared-tree',
      );
      view.tool = StudioMapTool.place;
      view.reconcileResources(project, mapId: 'a', map: workspaceMap('a'));
      expect(view.brush?.id, 'shared-tree');
      expect(view.tool, StudioMapTool.place);
    },
  );
  test(
    'map changes disarm character tile terrain border and model brushes',
    () {
      for (final kind in [
        'character',
        'tileset',
        'smartTilePreset',
        'borderBlueprint',
        'model3d',
      ]) {
        var project = familiesProject();
        if (kind == 'model3d') {
          project = project.copyWith(
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          );
        }
        final id = switch (kind) {
          'character' => 'guide-other',
          'tileset' => 'atlas-other',
          'borderBlueprint' => 'muret-other',
          'model3d' => 'door',
          _ => 'path',
        };
        if (kind == 'smartTilePreset' || kind == 'model3d') {
          project = project.copyWith(
            resourceLibraryCatalog: ResourceLibraryCatalog(
              families: project.resourceLibraryCatalog.families,
              entries: [
                ...project.resourceLibraryCatalog.entries,
                ResourceLibraryEntry(
                  resourceKind: kind,
                  resourceId: id,
                  mapId: 'b',
                ),
              ],
            ),
          );
        }
        final view = MapWorkspaceEditingState();
        view.reconcileResources(project, mapId: 'b');
        switch (kind) {
          case 'character':
            view.character = project.characters.firstWhere(
              (item) => item.id == id,
            );
            view.tool = StudioMapTool.character;
          case 'tileset':
            view.tile = TileLayerPaletteEntry(tilesetId: id, localTileId: 0);
            view.paletteAtlasId = id;
            view.tool = StudioMapTool.paint;
          case 'smartTilePreset':
            view.terrain = project.smartTileCatalog.presets.single;
            view.tool = StudioMapTool.terrain;
          case 'borderBlueprint':
            view.borderBlueprintId = id;
            view.tool = StudioMapTool.border;
          case 'model3d':
            view.model3d = project.models3d.single;
            view.tool = StudioMapTool.place;
        }
        view.reconcileResources(project, mapId: 'a');
        expect(view.tool, StudioMapTool.select, reason: kind);
        expect(view.character, isNull);
        expect(view.tile, isNull);
        expect(view.paletteAtlasId, isNull);
        expect(view.terrain, isNull);
        expect(view.borderBlueprintId, isNull);
        expect(view.model3d, isNull);
      }
    },
  );
}
