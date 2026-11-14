import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/border_catalog_fixture.dart';
import '../support/spatial_narrative_fixture.dart';

ProjectManifest familiesProject() {
  final character = spatialNarrativeProject().characters.single;
  final border = testBorderCatalog().records.single;
  final environment = EnvironmentPreset(
    id: 'garden',
    name: 'Jardin',
    templateId: 'manual',
    sortOrder: 0,
    palette: [EnvironmentPaletteItem(elementId: 'shared-tree', weight: 1)],
    defaultParams: EnvironmentGenerationParams.standard(),
  );
  return workspaceProject.copyWith(
    models3d: spatialNarrativeProject().models3d,
    elements: [
      for (final id in ['shared-tree', 'a-tree', 'b-tree', 'house'])
        workspaceElement.copyWith(id: id, name: id),
    ],
    characters: [
      character,
      character.copyWith(id: 'guide-other', name: 'Autre guide'),
    ],
    tilesets: [
      workspaceProject.tilesets.single,
      workspaceProject.tilesets.single.copyWith(id: 'atlas-other'),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: testBorderCatalog().formatVersion,
      visualSnapshots: testBorderCatalog().visualSnapshots,
      records: [
        border,
        BorderBlueprintRecord(
          id: 'muret-other',
          draft: border.draft,
          latestPublished: border.latestPublished,
        ),
      ],
    ),
    environmentPresets: [
      environment,
      EnvironmentPreset(
        id: 'garden-other',
        name: 'Autre jardin',
        templateId: environment.templateId,
        sortOrder: 0,
        palette: environment.palette,
        defaultParams: environment.defaultParams,
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      presets: [
        const ProjectSmartTilePreset(
          id: 'path',
          name: 'Chemin',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.cardinal4,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'path',
          allowedMaterialIds: ['path'],
        ),
      ],
    ),
    resourceLibraryCatalog: ResourceLibraryCatalog(
      families: [
        ResourceFamily(
          id: 'small-trees',
          name: 'Petits arbres',
          parentId: 'trees',
        ),
      ],
      entries: [
        for (final id in ['shared-tree', 'a-tree', 'b-tree'])
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: id,
            familyId: id == 'a-tree' ? 'small-trees' : 'trees',
            mapId: id == 'a-tree'
                ? 'a'
                : id == 'b-tree'
                ? 'b'
                : null,
          ),
        ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'house',
          familyId: 'buildings',
        ),
        for (final kindAndId in {
          'character': 'guide-other',
          'tileset': 'atlas-other',
          'borderBlueprint': 'muret-other',
          'environmentPreset': 'garden-other',
        }.entries)
          ResourceLibraryEntry(
            resourceKind: kindAndId.key,
            resourceId: kindAndId.value,
            mapId: 'b',
          ),
      ],
    ),
  );
}
