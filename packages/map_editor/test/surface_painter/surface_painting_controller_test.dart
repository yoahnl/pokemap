import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_painter/surface_painting_controller.dart';

void main() {
  group('SurfacePaintingController', () {
    const controller = SurfacePaintingController();

    test('paint without selected preset leaves the map unchanged', () {
      final map = _map(layers: const []);

      final result = controller.paint(
        map: map,
        targetLayerId: null,
        surfacePresetId: null,
        pos: const GridPos(x: 1, y: 1),
      );

      expect(result.changed, isFalse);
      expect(result.map, map);
      expect(result.layerId, isNull);
    });

    test('paint creates one SurfaceLayer on first surface placement', () {
      const terrainLayer = MapLayer.terrain(
        id: 'ground',
        name: 'Ground',
        terrains: [
          TerrainType.grass,
          TerrainType.grass,
          TerrainType.grass,
          TerrainType.grass,
        ],
      );
      final map = _map(layers: const [terrainLayer]);

      final result = controller.paint(
        map: map,
        targetLayerId: 'ground',
        surfacePresetId: 'water',
        pos: const GridPos(x: 1, y: 0),
      );

      expect(result.changed, isTrue);
      expect(result.layerId, 'surface-main');
      expect(result.map.layers.first, terrainLayer);
      final surfaceLayer = result.map.layers.whereType<SurfaceLayer>().single;
      expect(surfaceLayer.name, 'Surfaces');
      expect(surfaceLayer.placements, [
        const SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
      ]);
    });

    test('paint reuses an existing SurfaceLayer instead of creating another',
        () {
      final map = _map(
        layers: const [
          MapLayer.surface(id: 'surface-custom', name: 'Custom Surfaces'),
        ],
      );

      final result = controller.paint(
        map: map,
        targetLayerId: null,
        surfacePresetId: 'water',
        pos: const GridPos(x: 0, y: 1),
      );

      expect(result.layerId, 'surface-custom');
      expect(result.map.layers.whereType<SurfaceLayer>(), hasLength(1));
      expect(
        result.map.layers.whereType<SurfaceLayer>().single.placements,
        [
          const SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
        ],
      );
    });

    test('paint replaces an existing placement at the same coordinate', () {
      final first = controller.paint(
        map: _map(
          size: const GridSize(width: 3, height: 2),
          layers: const [
            MapLayer.surface(id: 'surface-main', name: 'Surfaces'),
          ],
        ),
        targetLayerId: 'surface-main',
        surfacePresetId: 'water',
        pos: const GridPos(x: 1, y: 1),
      );

      final second = controller.paint(
        map: first.map,
        targetLayerId: 'surface-main',
        surfacePresetId: 'lava',
        pos: const GridPos(x: 1, y: 1),
      );

      expect(second.map.layers.whereType<SurfaceLayer>().single.placements, [
        const SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'lava'),
      ]);
    });

    test('erase removes an existing sparse placement', () {
      final map = _map(
        layers: const [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ],
      );

      final result = controller.erase(
        map: map,
        targetLayerId: 'surface-main',
        pos: const GridPos(x: 0, y: 0),
      );

      expect(result.changed, isTrue);
      expect(result.map.layers.whereType<SurfaceLayer>().single.placements,
          isEmpty);
    });

    test('erase is a no-op when no surface placement exists', () {
      final map = _map(
        layers: const [
          MapLayer.surface(id: 'surface-main', name: 'Surfaces'),
        ],
      );

      final result = controller.erase(
        map: map,
        targetLayerId: 'surface-main',
        pos: const GridPos(x: 1, y: 1),
      );

      expect(result.changed, isFalse);
      expect(result.map, map);
    });

    test('paint keeps placements sorted for stable map diffs', () {
      final first = controller.paint(
        map: _map(
          size: const GridSize(width: 3, height: 2),
          layers: const [
            MapLayer.surface(id: 'surface-main', name: 'Surfaces'),
          ],
        ),
        targetLayerId: 'surface-main',
        surfacePresetId: 'water',
        pos: const GridPos(x: 2, y: 1),
      );
      final second = controller.paint(
        map: first.map,
        targetLayerId: 'surface-main',
        surfacePresetId: 'mud',
        pos: const GridPos(x: 0, y: 0),
      );

      expect(second.map.layers.whereType<SurfaceLayer>().single.placements, [
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'mud'),
        const SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      ]);
    });
  });
}

MapData _map({
  required List<MapLayer> layers,
  GridSize size = const GridSize(width: 2, height: 2),
}) {
  return MapData(
    id: 'map_1',
    name: 'Map 1',
    size: size,
    layers: layers,
  );
}
