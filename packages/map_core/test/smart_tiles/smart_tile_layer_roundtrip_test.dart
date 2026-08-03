import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const layer = MapLayer.smartTile(
    id: 'smart_path',
    name: 'Chemin organique',
    presetId: 'han_path',
    usage: SmartTileUsage.path,
    materialPalette: <String>['', 'dirt', 'grass'],
    field: SmartTileField.mixed(
      semanticCells: <int>[1, 0],
      horizontalEdges: <int>[2, 2, 1, 1],
      verticalEdges: <int>[2, 1, 2],
      corners: <int>[2, 2, 2, 1, 1, 1],
    ),
    layerSeed: 42,
    properties: <String, String>{'biome': 'hanazuki'},
  );

  test('SmartTileLayer round-trips as a v6 map layer', () {
    const map = MapData(
      id: 'hanazuki',
      name: 'Hanazuki',
      version: ProjectVersion.v6,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    );

    final decoded = MapData.fromJson(map.toJson());

    expect(decoded, map);
    expect(decoded.layers.single, isA<SmartTileLayer>());
  });

  test('v6 round-trip preserves an unassigned complete terrain draft', () {
    const terrain = SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[0]),
    );
    const map = MapData(
      id: 'draft',
      name: 'Draft',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[terrain],
    );

    final decoded = MapData.fromJson(map.toJson());
    final decodedLayer = decoded.layers.single as SmartTileLayer;

    expect(decodedLayer.field, const SmartTileField.cell(semanticCells: [0]));
    expect(() => MapValidator.validate(decoded), returnsNormally);
    final readiness = analyzeSmartTileLayerReadiness(
      map: decoded,
      layer: decodedLayer,
      preset: const ProjectSmartTilePreset(
        id: 'terrain',
        name: 'Terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ),
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
        ),
      ],
    );
    expect(readiness.unassignedCellCount, 1);
    expect(readiness.hasErrors, isTrue);
  });
}
