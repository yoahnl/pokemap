import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_model_geometry.dart';
import 'package:test/test.dart';

void main() {
  test('rotated source and part offsets compose with model pivot and scale',
      () {
    final catalog = ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: [
        ProjectSmartTilePreset(
          id: 'ground',
          name: 'Ground',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template),
          transformPolicy:
              const SmartTileTransformPolicy(allowQuarterTurns: true),
          defaultMaterialId: 'grass',
          allowedMaterialIds: ['grass'],
          rules: [
            SmartTileRule(
              id: 'model',
              centerMatch: SmartTileSlotMatch.material('grass'),
              candidates: [
                SmartTileCandidate(
                  id: 'model',
                  parts: [
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.model3d(
                        modelId: 'unit',
                        scale: .5,
                        offsetX: .0625,
                        offsetY: .1875,
                        offsetZ: -.125,
                      ),
                      offsetUnit: SmartTileOffsetUnit.pixel,
                      offsetX: 8,
                      offsetY: 8,
                      transform: SmartTileSpriteTransform(quarterTurns: 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: GridSize(width: 1, height: 1),
      spatialScene: MapSpatialScene(width: 1, depth: 1, heightLevels: [1]),
      layers: [
        SmartTileLayer(
          id: 'ground',
          name: 'Ground',
          presetId: 'ground',
          usage: SmartTileUsage.terrain,
          materialPalette: ['', 'grass'],
          field: SmartTileField.cell(semanticCells: [1]),
        ),
      ],
    );
    final model = ProjectModel3dEntry(
      id: 'unit',
      name: 'Unit',
      sourceAssetId: 'unit',
      relativePath: 'assets/models3d/unit.glb',
      scale: 2,
      pivot: Model3dVector3(x: 10, y: 2, z: -1),
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: 10, y: 2, z: -1),
          max: Model3dVector3(x: 14, y: 5, z: 0),
        ),
        meshCount: 1,
        triangleCount: 2,
      ),
    );
    final instance =
        resolveSpatialSmartTileInstances(map: map, catalog: catalog).single;
    final geometry = spatialModelWorldGeometry(instance, model);
    expect(instance.position.x, closeTo(.375, 1e-9));
    expect(instance.position.z, closeTo(.8125, 1e-9));
    expect(geometry.polygon[0].x, closeTo(.375, 1e-9));
    expect(geometry.polygon[0].z, closeTo(.8125, 1e-9));
    expect(geometry.polygon[1].x, closeTo(.375, 1e-9));
    expect(geometry.polygon[1].z, closeTo(4.8125, 1e-9));
    expect(geometry.polygon[2].x, closeTo(-.625, 1e-9));
    expect(geometry.polygon[2].z, closeTo(4.8125, 1e-9));
    expect(geometry.minY, 1.1875);
    expect(geometry.maxY, 4.1875);
  });
}
