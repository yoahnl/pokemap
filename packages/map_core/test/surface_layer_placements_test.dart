import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceLayer placement operations', () {
    test('identifies SurfaceLayer and exposes its sparse placements', () {
      const layer = MapLayer.surface(
        id: 'surfaces',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        ],
      );

      expect(isSurfaceLayer(layer), isTrue);
      expect(isSurfaceLayer(const MapLayer.object(id: 'objects', name: 'O')),
          isFalse);
      expect(getSurfacePlacements(layer), [
        const SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      ]);
      expect(
        surfacePlacementAt(layer: layer, x: 2, y: 1),
        const SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      );
      expect(surfacePlacementAt(layer: layer, x: 0, y: 0), isNull);
    });

    test('paintSurfacePlacement adds a placement and trims the preset id', () {
      final updated = paintSurfacePlacement(
        layer: const MapLayer.surface(id: 'surfaces', name: 'Surfaces'),
        mapSize: const GridSize(width: 4, height: 4),
        x: 1,
        y: 2,
        surfacePresetId: '  water  ',
      ) as SurfaceLayer;

      expect(updated.placements, [
        const SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'water'),
      ]);
    });

    test(
        'paintSurfacePlacement replaces an existing placement at the same cell',
        () {
      final updated = paintSurfacePlacement(
        layer: const MapLayer.surface(
          id: 'surfaces',
          name: 'Surfaces',
          placements: [
            SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'water'),
            SurfaceCellPlacement(x: 2, y: 2, surfacePresetId: 'lava'),
          ],
        ),
        mapSize: const GridSize(width: 4, height: 4),
        x: 1,
        y: 2,
        surfacePresetId: 'ice',
      ) as SurfaceLayer;

      expect(updated.placements, [
        const SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'ice'),
        const SurfaceCellPlacement(x: 2, y: 2, surfacePresetId: 'lava'),
      ]);
    });

    test('paintSurfacePlacement accepts different presets at different cells',
        () {
      final first = paintSurfacePlacement(
        layer: const MapLayer.surface(id: 'surfaces', name: 'Surfaces'),
        mapSize: const GridSize(width: 4, height: 4),
        x: 3,
        y: 0,
        surfacePresetId: 'water',
      );
      final second = paintSurfacePlacement(
        layer: first,
        mapSize: const GridSize(width: 4, height: 4),
        x: 0,
        y: 2,
        surfacePresetId: 'mud',
      ) as SurfaceLayer;

      // The model is sparse, but writes are sorted to keep JSON diffs stable.
      expect(second.placements, [
        const SurfaceCellPlacement(x: 3, y: 0, surfacePresetId: 'water'),
        const SurfaceCellPlacement(x: 0, y: 2, surfacePresetId: 'mud'),
      ]);
    });

    test('paintSurfacePlacement refuses coordinates outside the map', () {
      const layer = MapLayer.surface(id: 'surfaces', name: 'Surfaces');
      const mapSize = GridSize(width: 2, height: 2);

      expect(
        () => paintSurfacePlacement(
          layer: layer,
          mapSize: mapSize,
          x: -1,
          y: 0,
          surfacePresetId: 'water',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => paintSurfacePlacement(
          layer: layer,
          mapSize: mapSize,
          x: 2,
          y: 0,
          surfacePresetId: 'water',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => paintSurfacePlacement(
          layer: layer,
          mapSize: mapSize,
          x: 0,
          y: 2,
          surfacePresetId: 'water',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('paintSurfacePlacement refuses an empty surfacePresetId', () {
      expect(
        () => paintSurfacePlacement(
          layer: const MapLayer.surface(id: 'surfaces', name: 'Surfaces'),
          mapSize: const GridSize(width: 2, height: 2),
          x: 0,
          y: 0,
          surfacePresetId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('eraseSurfacePlacement removes an existing placement', () {
      final updated = eraseSurfacePlacement(
        layer: const MapLayer.surface(
          id: 'surfaces',
          name: 'Surfaces',
          placements: [
            SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
          ],
        ),
        x: 0,
        y: 0,
      ) as SurfaceLayer;

      expect(updated.placements, [
        const SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
      ]);
    });

    test('eraseSurfacePlacement is a no-op when the cell is empty', () {
      const layer = MapLayer.surface(
        id: 'surfaces',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
        ],
      );

      expect(eraseSurfacePlacement(layer: layer, x: 0, y: 0), layer);
    });

    test('clearSurfacePlacements empties placements and preserves metadata',
        () {
      final updated = clearSurfacePlacements(
        const MapLayer.surface(
          id: 'surfaces',
          name: 'Surfaces',
          isVisible: false,
          opacity: 0.5,
          properties: {'mode': 'authoring'},
          placements: [
            SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
          ],
        ),
      ) as SurfaceLayer;

      expect(updated.id, 'surfaces');
      expect(updated.name, 'Surfaces');
      expect(updated.isVisible, isFalse);
      expect(updated.opacity, 0.5);
      expect(updated.properties, {'mode': 'authoring'});
      expect(updated.placements, isEmpty);
    });

    test('replaceSurfacePlacements sorts placements by y, x, then preset id',
        () {
      final updated = replaceSurfacePlacements(
        layer: const MapLayer.surface(id: 'surfaces', name: 'Surfaces'),
        mapSize: const GridSize(width: 4, height: 4),
        placements: const [
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'lava'),
          SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'mud'),
        ],
      ) as SurfaceLayer;

      expect(updated.placements, [
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'lava'),
        const SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'mud'),
        const SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      ]);
    });

    test('replaceSurfacePlacements refuses duplicate coordinates', () {
      expect(
        () => replaceSurfacePlacements(
          layer: const MapLayer.surface(id: 'surfaces', name: 'Surfaces'),
          mapSize: const GridSize(width: 4, height: 4),
          placements: const [
            SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
            SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'lava'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('operations require a SurfaceLayer', () {
      const layer = MapLayer.object(id: 'objects', name: 'Objects');

      expect(() => getSurfacePlacements(layer),
          throwsA(isA<ValidationException>()));
      expect(
        () => paintSurfacePlacement(
          layer: layer,
          mapSize: const GridSize(width: 2, height: 2),
          x: 0,
          y: 0,
          surfacePresetId: 'water',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => clearSurfacePlacements(layer),
        throwsA(isA<ValidationException>()),
      );
    });

    test('resizeMapData keeps in-bounds SurfaceLayer placements only', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surfaces',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
              SurfaceCellPlacement(x: 3, y: 3, surfacePresetId: 'lava'),
            ],
          ),
        ],
      );

      final resized = resizeMapData(map, width: 2, height: 2);
      expect((resized.layers.single as SurfaceLayer).placements, [
        const SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
      ]);
    });

    test('generic MapLayer helpers tolerate SurfaceLayer', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 2),
        layers: [
          MapLayer.surface(id: 'surfaces', name: 'Surfaces'),
        ],
      );

      final renamed =
          renameMapLayer(map, layerId: 'surfaces', name: 'Surface Overlay');
      final hidden = setMapLayerVisibility(
        renamed,
        layerId: 'surfaces',
        isVisible: false,
      );
      final translucent =
          setMapLayerOpacity(hidden, layerId: 'surfaces', opacity: 0.25);

      final layer = translucent.layers.single as SurfaceLayer;
      expect(layer.name, 'Surface Overlay');
      expect(layer.isVisible, isFalse);
      expect(layer.opacity, 0.25);
    });
  });
}
