import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const layer = MapLayer.smartTile(
    id: 'smart_path',
    name: 'Chemin organique',
    presetId: 'han_path',
    usage: SmartTileUsage.path,
    materialPalette: <String>['', 'dirt', 'grass'],
    materialCells: <int>[1, 0],
    horizontalEdges: <int>[2, 2, 1, 1],
    verticalEdges: <int>[2, 1, 2],
    corners: <int>[2, 2, 2, 1, 1, 1],
    layerSeed: 42,
    properties: <String, String>{'biome': 'hanazuki'},
  );

  test('SmartTileLayer round-trips only as a v4 map layer', () {
    const map = MapData(
      id: 'hanazuki',
      name: 'Hanazuki',
      version: ProjectVersion.v4,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    );

    final decoded = MapData.fromJson(map.toJson());

    expect(decoded, map);
    expect(decoded.layers.single, isA<SmartTileLayer>());
  });

  test('MapData.fromJson rejects SmartTileLayer in a v3 map', () {
    final json = <String, dynamic>{
      'id': 'hanazuki',
      'name': 'Hanazuki',
      'version': 'v3',
      'size': const GridSize(width: 2, height: 1).toJson(),
      'layers': <Map<String, dynamic>>[layer.toJson()],
    };

    expect(
      () => MapData.fromJson(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Smart Tile layers require ProjectVersion.v4'),
        ),
      ),
    );
  });

  test('MapValidator rejects SmartTileLayer in a pre-v4 map', () {
    const map = MapData(
      id: 'hanazuki',
      name: 'Hanazuki',
      version: ProjectVersion.v3,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    );

    expect(
      () => MapValidator.validate(map),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.message,
          'message',
          contains('Smart Tile layers require ProjectVersion.v4'),
        ),
      ),
    );
  });
}
