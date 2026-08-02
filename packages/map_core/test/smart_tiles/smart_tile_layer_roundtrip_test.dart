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

  test('SmartTileLayer round-trips only as a v5 map layer', () {
    const map = MapData(
      id: 'hanazuki',
      name: 'Hanazuki',
      version: ProjectVersion.v5,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    );

    final decoded = MapData.fromJson(map.toJson());

    expect(decoded, map);
    expect(decoded.layers.single, isA<SmartTileLayer>());
  });

  test('MapData.fromJson rejects SmartTileLayer in a v4 map', () {
    final json = <String, dynamic>{
      'id': 'hanazuki',
      'name': 'Hanazuki',
      'version': 'v4',
      'size': const GridSize(width: 2, height: 1).toJson(),
      'layers': <Map<String, dynamic>>[layer.toJson()],
    };

    expect(
      () => MapData.fromJson(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Smart Tile layers require ProjectVersion.v5'),
        ),
      ),
    );
  });

  test('MapValidator rejects SmartTileLayer in a pre-v5 map', () {
    const map = MapData(
      id: 'hanazuki',
      name: 'Hanazuki',
      version: ProjectVersion.v4,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    );

    expect(
      () => MapValidator.validate(map),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.message,
          'message',
          contains('Smart Tile layers require ProjectVersion.v5'),
        ),
      ),
    );
  });

  test('v5 round-trip preserves an unassigned complete terrain draft', () {
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
      version: ProjectVersion.v5,
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
