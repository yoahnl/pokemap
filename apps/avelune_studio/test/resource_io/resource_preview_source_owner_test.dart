import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: 'model3d_$id',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);

const _terrainSheet = ProjectTilesetEntry(
  id: 'terrain',
  name: 'Chemin',
  relativePath: 'terrain.png',
  source: ProjectTilesetSource.regularAtlas(
    assetId: 'terrain',
    pixelWidth: 128,
    pixelHeight: 128,
    tileWidth: 32,
    tileHeight: 32,
  ),
);

ProjectSmartTilePreset _terrainPreset(String atlasId) => ProjectSmartTilePreset(
  id: 'path',
  name: 'Chemin',
  usage: SmartTileUsage.path,
  topology: SmartTileTopology.cardinal4,
  coveragePolicy: SmartTileCoveragePolicy.complete,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: 'path',
  allowedMaterialIds: ['path'],
  rules: [
    for (var mask = 0; mask < 16; mask++)
      terrainConnectionRule(
        mask,
        SmartTileFrameRef(atlasId: atlasId, column: 2, row: 1),
        'path',
      ),
  ],
);

ProjectManifest _terrainProject(String ruleAtlasId) => workspaceProject.copyWith(
  tilesets: [_terrainSheet],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: [terrainAtlas(_terrainSheet, 'atlas')],
    materials: [
      const ProjectSmartTileMaterial(
        id: 'path',
        name: 'Chemin',
        connectionGroupId: 'path',
      ),
    ],
    presets: [_terrainPreset(ruleAtlasId)],
  ),
);

EnvironmentPreset _environment(EnvironmentPaletteItem item) => EnvironmentPreset(
  id: 'garden',
  name: 'Jardin',
  templateId: 'manual',
  sortOrder: 0,
  palette: [item],
  defaultParams: EnvironmentGenerationParams.standard(),
);

ResourceItem _environmentItem(EnvironmentPreset preset) => ResourceItem(
  id: preset.id,
  name: preset.name,
  kind: ResourceKind.decors,
  environment: preset,
);

void main() {
  test('a 3D model previews itself and wins over every other source', () {
    final model = _model('lamp');
    final source = resourcePreviewSource(
      ResourceItem(
        id: 'lamp',
        name: 'Lamp',
        kind: ResourceKind.decors,
        model3d: model,
      ),
      workspaceProject,
    );
    expect(source, isA<ModelPreviewSource>());
    expect((source as ModelPreviewSource).model, same(model));
  });

  test('a decor previews its element', () {
    final source = resourcePreviewSource(
      const ResourceItem(
        id: 'tree',
        name: 'Arbre',
        kind: ResourceKind.decors,
        element: workspaceElement,
      ),
      workspaceProject,
    );
    expect((source as ElementPreviewSource).element, workspaceElement);
  });

  test('an environment previews its first palette model, else its first palette element', () {
    final project = workspaceProject.copyWith(models3d: [_model('lamp')]);
    final withModel = resourcePreviewSource(
      _environmentItem(
        _environment(
          EnvironmentPaletteItem(
            modelId: 'lamp',
            cellOffsetWorld: Model3dVector3.zero,
            weight: 1,
          ),
        ),
      ),
      project,
    );
    expect((withModel as ModelPreviewSource).model.id, 'lamp');
    final withElement = resourcePreviewSource(
      _environmentItem(
        _environment(EnvironmentPaletteItem(elementId: 'tree', weight: 1)),
      ),
      workspaceProject,
    );
    expect((withElement as ElementPreviewSource).element.id, 'tree');
    final missing = resourcePreviewSource(
      _environmentItem(
        _environment(EnvironmentPaletteItem(elementId: 'absent', weight: 1)),
      ),
      workspaceProject,
    );
    expect(missing, isA<FallbackPreviewSource>());
  });

  test('a character and an image sheet preview themselves', () {
    const character = ProjectCharacterEntry(
      id: 'guide',
      name: 'Guide',
      tilesetId: 'atlas',
    );
    final fromCharacter = resourcePreviewSource(
      const ResourceItem(
        id: 'guide',
        name: 'Guide',
        kind: ResourceKind.images,
        character: character,
      ),
      workspaceProject,
    );
    expect((fromCharacter as CharacterPreviewSource).character, character);
    final fromSheet = resourcePreviewSource(
      ResourceItem(
        id: 'atlas',
        name: 'Exemple',
        kind: ResourceKind.images,
        tileset: workspaceProject.tilesets.single,
      ),
      workspaceProject,
    );
    expect((fromSheet as AtlasPreviewSource).tilesetId, 'atlas');
  });

  test('a terrain previews its connection pattern when asked, else the tile of its first frame', () {
    final project = _terrainProject('atlas');
    final item = resourceCatalog(
      project,
    ).singleWhere((item) => item.terrain != null);
    final pattern = resourcePreviewSource(item, project, terrainPattern: true);
    expect((pattern as TerrainPatternPreviewSource).preset, item.terrain);
    final frame = resourcePreviewSource(item, project);
    final entry = (frame as TileFramePreviewSource).entry;
    expect(entry.tilesetId, 'terrain');
    expect(entry.localTileId, 1 * 4 + 2);
  });

  test('a terrain whose frames point at an unknown atlas falls back to the generic icon', () {
    final project = _terrainProject('absent');
    final item = resourceCatalog(
      project,
    ).singleWhere((item) => item.terrain != null);
    expect(resourcePreviewSource(item, project), isA<FallbackPreviewSource>());
    expect(
      resourcePreviewSource(item, project, terrainPattern: true),
      isA<TerrainPatternPreviewSource>(),
    );
  });
}
