import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapData', () {
    test('should serialize and deserialize correctly', () {
      final map = MapData(
        id: 'map_01',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
        tilesetId: 'tileset_01',
        layers: [
          const MapLayerData(
            id: 'layer_01',
            name: 'Base',
            type: LayerType.tile,
            tiles: [],
          ),
        ],
      );

      final json = map.toJson();
      final decoded = MapData.fromJson(json);

      expect(decoded.id, equals(map.id));
      expect(decoded.layers.first.type, equals(LayerType.tile));
    });

    test('should fail validation on invalid dimensions', () {
      final map = MapData(
        id: 'map_fail',
        name: 'Invalid',
        size: const GridSize(width: -1, height: 10),
        tilesetId: 'ts',
      );

      expect(() => MapValidator.validate(map), throwsA(isA<ValidationException>()));
    });
  });
}
