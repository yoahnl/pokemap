import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapCore Strict Tests', () {
    test('MapLayer serialization (Union)', () {
      const layer = MapLayer.tile(
        id: 'l1', 
        name: 'Ground', 
        tiles: [1, 2, 3, 4]
      );
      final json = layer.toJson();
      
      expect(json['type'], 'tile'); // Discriminator check
      
      final decoded = MapLayer.fromJson(json);
      expect(decoded, isA<TileLayer>());
      expect((decoded as TileLayer).tiles, [1, 2, 3, 4]);
    });

    test('ProjectValidator detects duplicates', () {
      final project = ProjectManifest(
        name: 'Test',
        maps: [
          const ProjectMapEntry(id: 'm1', name: 'Map1', relativePath: 'm1.json'),
          const ProjectMapEntry(id: 'm1', name: 'Map2', relativePath: 'm2.json'),
        ],
        tilesets: [],
      );
      
      expect(() => ProjectValidator.validate(project), throwsA(isA<ValidationException>()));
    });

    test('MapValidator detects layer size mismatch', () {
      final map = MapData(
        id: 'm1',
        name: 'Map1',
        size: const GridSize(width: 2, height: 2), // 4 tiles expected
        tilesetId: 'ts1',
        layers: [
          const MapLayer.tile(id: 'l1', name: 'Ground', tiles: [0, 0, 0]), // Only 3 tiles
        ],
      );

      expect(() => MapValidator.validate(map), throwsA(isA<ValidationException>()));
    });

    test('MapValidator detects entity out of bounds', () {
      final map = MapData(
        id: 'm1',
        name: 'Map1',
        size: const GridSize(width: 5, height: 5),
        tilesetId: 'ts1',
        entities: [
          const MapEntity(
            id: 'e1',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 10, y: 10) // Out of bounds
          ),
        ],
      );

      expect(() => MapValidator.validate(map), throwsA(isA<ValidationException>()));
    });
  });
}
