import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';

void main() {
  test('runtime map bundles prepare painted 3D units before scene loading', () {
    final manifest = ProjectManifest(
      name: 'Grass',
      version: ProjectVersion.v9,
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: const [],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      models3d: [
        ProjectModel3dEntry(
          id: 'grass',
          name: 'Grass',
          sourceAssetId: 'model3d_grass',
          relativePath: 'assets/models3d/grass.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3.zero,
              max: Model3dVector3(x: 1, y: .5, z: 1),
            ),
            meshCount: 1,
            triangleCount: 6,
            materials: const [],
            animations: const [],
            diagnostics: const [],
          ),
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
          ),
        ],
        presets: const [
          ProjectSmartTilePreset(
            id: 'grass-path',
            name: 'Grass',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: ['grass'],
            rules: [
              SmartTileRule(
                id: 'grass',
                centerMatch: SmartTileSlotMatch.material('grass'),
                candidates: [
                  SmartTileCandidate(
                    id: 'grass',
                    parts: [
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.model3d(modelId: 'grass'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    const layer = SmartTileLayer(
      id: 'grass',
      name: 'Grass',
      presetId: 'grass-path',
      usage: SmartTileUsage.path,
      materialPalette: ['', 'grass'],
      field: SmartTileField.cell(semanticCells: [1, 0, 0, 0]),
    );
    final source = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 2, height: 2),
      layers: const [layer],
      spatialScene: MapSpatialScene(
        width: 2,
        depth: 2,
        heightLevels: const [2, 0, 0, 0],
        levelHeight: .25,
        navigation: SpatialNavigationProfile(
          spawn: SpatialSpawn(x: 1.5, z: 1.5),
        ),
      ),
    );
    ProjectValidator.validate(manifest);
    MapValidator.validate(source, projectDialogueContext: manifest);
    final bundle = RuntimeMapBundle(
      manifest: manifest,
      map: source,
      projectRootDirectory: '/runtime',
      tilesetAbsolutePathsById: const {},
    );
    expect(source.spatialScene!.instances, isEmpty);
    expect(bundle.map.spatialScene!.instances, hasLength(1));
    final grass = bundle.map.spatialScene!.instances.single;
    expect(grass.position, Model3dVector3(x: .5, y: .5, z: .5));
    expect(grass.blocksMovement, false);
    expect(bundle.copyWith().map.spatialScene!.instances, [grass]);
    final erased = source.copyWith(
      layers: [
        layer.copyWith(
          field: const SmartTileField.cell(semanticCells: [0, 0, 0, 0]),
        ),
      ],
    );
    expect(bundle.copyWith(map: erased).map.spatialScene!.instances, isEmpty);
    expect(
      source.toJson()['spatialScene'],
      isNot(containsPair('instances', [grass.toJson()])),
    );
  });
}
