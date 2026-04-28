import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceCellPlacement', () {
    test('stores sparse cell coordinates and a surfacePresetId', () {
      const placement = SurfaceCellPlacement(
        x: 4,
        y: 8,
        surfacePresetId: 'water-surface',
      );

      expect(placement.x, 4);
      expect(placement.y, 8);
      expect(placement.surfacePresetId, 'water-surface');
    });

    test('round-trips JSON with only V0 placement fields', () {
      const placement = SurfaceCellPlacement(
        x: 1,
        y: 2,
        surfacePresetId: 'lava-surface',
      );

      final json = wireJson(placement.toJson());
      expect(json, {
        'x': 1,
        'y': 2,
        'surfacePresetId': 'lava-surface',
      });
      expect(json, isNot(contains('variantRole')));
      expect(json, isNot(contains('animationId')));
      expect(json, isNot(contains('atlasId')));
      expect(json, isNot(contains('tilesetId')));

      expect(SurfaceCellPlacement.fromJson(json), placement);
    });
  });

  group('SurfaceLayer', () {
    test('stores sparse placements and preserves their order', () {
      const layer = MapLayer.surface(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(
            x: 4,
            y: 8,
            surfacePresetId: 'water-surface',
          ),
          SurfaceCellPlacement(
            x: 1,
            y: 2,
            surfacePresetId: 'lava-surface',
          ),
        ],
      );

      final surfaceLayer = layer as SurfaceLayer;
      expect(surfaceLayer.placements, hasLength(2));
      expect(surfaceLayer.placements[0].surfacePresetId, 'water-surface');
      expect(surfaceLayer.placements[1].surfacePresetId, 'lava-surface');
    });

    test('serializes with runtimeType surface and no computed autotile role',
        () {
      const layer = MapLayer.surface(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(
            x: 4,
            y: 8,
            surfacePresetId: 'water-surface',
          ),
        ],
        properties: {'purpose': 'authoring'},
      );

      final json = wireJson(layer.toJson());
      expect(json['runtimeType'], 'surface');
      expect(json['id'], 'surface-main');
      expect(json['name'], 'Surfaces');
      expect(json['isVisible'], isTrue);
      expect(json['opacity'], 1.0);
      expect(json['properties'], {'purpose': 'authoring'});
      expect(json['placements'], [
        {
          'x': 4,
          'y': 8,
          'surfacePresetId': 'water-surface',
        },
      ]);
      expect(json, isNot(contains('surfacePresetId')));
      expect(json, isNot(contains('variantRole')));
      expect(json, isNot(contains('animationId')));
      expect(json, isNot(contains('atlasId')));
      expect(json, isNot(contains('tilesetId')));

      final decoded = MapLayer.fromJson(json);
      expect(decoded, isA<SurfaceLayer>());
      expect(decoded, layer);
    });

    test('MapData round-trips with a SurfaceLayer', () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        size: GridSize(width: 8, height: 8),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 4,
                y: 5,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );

      final json = wireJson(map.toJson());
      final decoded = MapData.fromJson(json);

      expect(decoded, map);
      expect(decoded.layers.single, isA<SurfaceLayer>());
    });

    test('legacy MapData without SurfaceLayer remains readable', () {
      final json = wireJson({
        'id': 'legacy-map',
        'name': 'Legacy Map',
        'size': {'width': 2, 'height': 2},
        'version': 'v1',
        'tilesetId': '',
        'layers': [
          {
            'runtimeType': 'tile',
            'id': 'tiles',
            'name': 'Tiles',
            'tiles': [0, 1, 2, 3],
          },
          {
            'runtimeType': 'terrain',
            'id': 'terrain',
            'name': 'Terrain',
            'terrains': ['none', 'grass', 'sand', 'rock'],
          },
          {
            'runtimeType': 'path',
            'id': 'water',
            'name': 'Water',
            'presetId': 'water-path',
            'cells': [true, false, false, true],
          },
          {
            'runtimeType': 'object',
            'id': 'objects',
            'name': 'Objects',
          },
        ],
      });

      final map = MapData.fromJson(json);

      expect(map.layers[0], isA<TileLayer>());
      expect(map.layers[1], isA<TerrainLayer>());
      expect(map.layers[2], isA<PathLayer>());
      expect(map.layers[3], isA<ObjectLayer>());
      expect(
        map.toJson()['layers'],
        isNot(contains(isA<Map<String, dynamic>>().having(
            (layer) => layer['runtimeType'], 'runtimeType', 'surface'))),
      );
    });

    test('legacy layer JSON remains unchanged for existing layer kinds', () {
      expect(
        wireJson(const MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          tilesetId: 'world',
          tiles: [1, 2],
        ).toJson()),
        {
          'id': 'tiles',
          'name': 'Tiles',
          'tilesetId': 'world',
          'isVisible': true,
          'opacity': 1.0,
          'tiles': [1, 2],
          'runtimeType': 'tile',
        },
      );
      expect(
        wireJson(const MapLayer.terrain(
          id: 'terrain',
          name: 'Terrain',
          terrains: [TerrainType.none, TerrainType.grass],
        ).toJson()),
        {
          'id': 'terrain',
          'name': 'Terrain',
          'isVisible': true,
          'opacity': 1.0,
          'terrains': ['none', 'grass'],
          'runtimeType': 'terrain',
        },
      );
      expect(
        wireJson(const MapLayer.path(
          id: 'path',
          name: 'Path',
          presetId: 'water-path',
          cells: [true, false],
        ).toJson()),
        {
          'id': 'path',
          'name': 'Path',
          'isVisible': true,
          'opacity': 1.0,
          'presetId': 'water-path',
          'cells': [true, false],
          'properties': <String, dynamic>{},
          'animationMode': 'triggered',
          'animationTriggers': <dynamic>[],
          'runtimeType': 'path',
        },
      );
      expect(
        wireJson(const MapLayer.object(
          id: 'objects',
          name: 'Objects',
        ).toJson()),
        {
          'id': 'objects',
          'name': 'Objects',
          'isVisible': true,
          'opacity': 1.0,
          'runtimeType': 'object',
        },
      );
    });
  });

  group('SurfaceLayer validation', () {
    test('accepts valid sparse placements', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 0,
                y: 0,
                surfacePresetId: 'water-surface',
              ),
              SurfaceCellPlacement(
                x: 3,
                y: 3,
                surfacePresetId: 'lava-surface',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('rejects negative x', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: -1,
                y: 0,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map),
          throwsA(isA<ValidationException>()));
    });

    test('rejects negative y', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 0,
                y: -1,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map),
          throwsA(isA<ValidationException>()));
    });

    test('rejects out-of-bounds placements', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 4,
                y: 0,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map),
          throwsA(isA<ValidationException>()));
    });

    test('rejects empty surfacePresetId', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 0,
                y: 0,
                surfacePresetId: '   ',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map),
          throwsA(isA<ValidationException>()));
    });

    test('rejects duplicate placement coordinates in one SurfaceLayer', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 1,
                y: 2,
                surfacePresetId: 'water-surface',
              ),
              SurfaceCellPlacement(
                x: 1,
                y: 2,
                surfacePresetId: 'lava-surface',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map),
          throwsA(isA<ValidationException>()));
    });

    test('allows the same coordinate in different SurfaceLayers', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-a',
            name: 'Surfaces A',
            placements: [
              SurfaceCellPlacement(
                x: 1,
                y: 2,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
          MapLayer.surface(
            id: 'surface-b',
            name: 'Surfaces B',
            placements: [
              SurfaceCellPlacement(
                x: 1,
                y: 2,
                surfacePresetId: 'lava-surface',
              ),
            ],
          ),
        ],
      );

      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('rejects empty SurfaceLayer property keys', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            properties: {' ': 'invalid'},
          ),
        ],
      );

      expect(() => MapValidator.validate(map),
          throwsA(isA<ValidationException>()));
    });
  });

  group('SurfaceLayer and map resize', () {
    test('resizeMapData keeps sparse placements that remain in bounds', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 1,
                y: 1,
                surfacePresetId: 'water-surface',
              ),
              SurfaceCellPlacement(
                x: 3,
                y: 3,
                surfacePresetId: 'lava-surface',
              ),
            ],
          ),
        ],
      );

      final resized = resizeMapData(map, width: 2, height: 2);
      final layer = resized.layers.single as SurfaceLayer;

      expect(layer.placements, [
        const SurfaceCellPlacement(
          x: 1,
          y: 1,
          surfacePresetId: 'water-surface',
        ),
      ]);
    });
  });
}

Map<String, dynamic> wireJson(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
