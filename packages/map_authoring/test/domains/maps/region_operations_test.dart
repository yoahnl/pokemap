import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapRegionOperations', () {
    test('supports bounded paint, shapes, flood fill, and replace', () {
      var map = _map(width: 6, height: 5);
      const operations = MapRegionOperations();

      map = operations.apply(map, const {
        'kind': 'region.fill',
        'layerId': 'tiles',
        'x': 0,
        'y': 0,
        'width': 6,
        'height': 5,
        'value': 1,
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.rectangle',
        'layerId': 'tiles',
        'x': 1,
        'y': 1,
        'width': 4,
        'height': 3,
        'value': 2,
        'filled': false,
      }).map;
      map = operations.apply(map, const {
        'kind': 'region.flood_fill',
        'layerId': 'tiles',
        'x': 2,
        'y': 2,
        'value': 3,
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.line',
        'layerId': 'tiles',
        'from': {'x': 0, 'y': 4},
        'to': {'x': 5, 'y': 4},
        'value': 4,
      }).map;
      final result = operations.apply(map, const {
        'kind': 'region.replace',
        'layerId': 'tiles',
        'from': 2,
        'to': 5,
      });

      final tiles = (result.map.layers.single as TileLayer).tiles;
      expect(tiles[2 * 6 + 2], 3);
      expect(tiles.sublist(4 * 6), everyElement(4));
      expect(tiles.where((tile) => tile == 5), hasLength(10));
      expect(result.changedCells, 10);
    });

    test('supports polyline, polygon, and exact stamps', () {
      var map = _map(width: 5, height: 5);
      const operations = MapRegionOperations();
      map = operations.apply(map, const {
        'kind': 'region.stamp',
        'layerId': 'tiles',
        'x': 0,
        'y': 0,
        'width': 2,
        'height': 2,
        'values': [1, 2, 3, 4],
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.polyline',
        'layerId': 'tiles',
        'points': [
          {'x': 0, 'y': 4},
          {'x': 2, 'y': 2},
          {'x': 4, 'y': 4},
        ],
        'value': 8,
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.polygon',
        'layerId': 'tiles',
        'points': [
          {'x': 1, 'y': 1},
          {'x': 3, 'y': 1},
          {'x': 2, 'y': 3},
        ],
        'value': 9,
        'filled': true,
      }).map;

      final tiles = (map.layers.single as TileLayer).tiles;
      expect(tiles[0], 1);
      expect(tiles[1], 2);
      expect(tiles[5], 3);
      expect(tiles[6], 9);
      expect(tiles[2 * 5 + 2], 9);
      expect(tiles[4 * 5], 8);
      expect(tiles[4 * 5 + 4], 8);
    });

    test('copy, cut, paste, move, rotate, and flip preserve map references',
        () {
      var map = _map(width: 4, height: 4).copyWith(
        layers: [
          MapLayer.tile(
            id: 'tiles',
            name: 'Tiles',
            tiles: const [
              1,
              2,
              0,
              0,
              3,
              4,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        warps: const [
          MapWarp(
            id: 'warp',
            pos: GridPos(x: 3, y: 3),
            targetMapId: 'other',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      const operations = MapRegionOperations();
      final clipboard = MapRegionClipboard();

      map = operations
          .apply(
              map,
              const {
                'kind': 'region.copy',
                'layerId': 'tiles',
                'clipboardId': 'selection',
                'x': 0,
                'y': 0,
                'width': 2,
                'height': 2,
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.paste',
                'layerId': 'tiles',
                'clipboardId': 'selection',
                'x': 2,
                'y': 2,
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.rotate',
                'layerId': 'tiles',
                'x': 0,
                'y': 0,
                'width': 2,
                'height': 2,
                'quarterTurns': 1,
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.flip',
                'layerId': 'tiles',
                'x': 2,
                'y': 2,
                'width': 2,
                'height': 2,
                'axis': 'horizontal',
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.move',
                'layerId': 'tiles',
                'source': {'x': 0, 'y': 0, 'width': 2, 'height': 2},
                'target': {'x': 0, 'y': 2},
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.cut',
                'layerId': 'tiles',
                'clipboardId': 'cut',
                'x': 2,
                'y': 2,
                'width': 2,
                'height': 2,
              },
              clipboard: clipboard)
          .map;

      final tiles = (map.layers.single as TileLayer).tiles;
      expect(tiles.sublist(0, 8), everyElement(0));
      expect(tiles.sublist(8, 10), [3, 1]);
      expect(tiles.sublist(12, 14), [4, 2]);
      expect(tiles[10], 0);
      expect(tiles[15], 0);
      expect(map.size, const GridSize(width: 4, height: 4));
      expect(map.warps.single.id, 'warp');
      expect(map.layers.single.id, 'tiles');
      expect(clipboard.contains('cut'), isTrue);
    });

    test('normalizes values for every non-SmartTile addressable layer kind',
        () {
      var map = _map(width: 2, height: 2).copyWith(
        version: ProjectVersion.v4,
        layers: [
          MapLayer.tile(id: 'tile', name: 'Tile', tiles: List.filled(4, 0)),
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: List.filled(4, false),
          ),
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: List.filled(4, TerrainType.none),
          ),
          MapLayer.path(id: 'path', name: 'Path', cells: List.filled(4, false)),
          const MapLayer.surface(id: 'surface', name: 'Surface'),
        ],
      );
      const operations = MapRegionOperations();
      for (final entry in <String, Object?>{
        'tile': 7,
        'collision': true,
        'terrain': 'grass',
        'path': true,
        'surface': 'surface_grass',
      }.entries) {
        map = operations.apply(map, {
          'kind': 'region.paint',
          'layerId': entry.key,
          'x': 1,
          'y': 1,
          'value': entry.value,
        }).map;
      }

      expect((map.layers[0] as TileLayer).tiles.last, 7);
      expect((map.layers[1] as CollisionLayer).collisions.last, isTrue);
      expect((map.layers[2] as TerrainLayer).terrains.last, TerrainType.grass);
      expect((map.layers[3] as PathLayer).cells.last, isTrue);
      expect((map.layers[4] as SurfaceLayer).placements.single.x, 1);
    });

    test('rejects out-of-bounds and non-square odd rotations', () {
      const operations = MapRegionOperations();
      final map = _map(width: 4, height: 3);

      for (final operation in [
        const {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 4,
          'y': 0,
          'value': 1,
        },
        const {
          'kind': 'region.rotate',
          'layerId': 'tiles',
          'x': 0,
          'y': 0,
          'width': 2,
          'height': 3,
          'quarterTurns': 1,
        },
      ]) {
        expect(
          () => operations.apply(map, operation),
          throwsA(isA<MapAuthoringException>()),
        );
      }
    });

    test('cell Smart Tile fields keep paint, fill, and erase authoring', () {
      final map = _map(width: 2, height: 2).copyWith(
        version: ProjectVersion.v5,
        layers: const [
          MapLayer.smartTile(
            id: 'smart',
            name: 'Smart',
            presetId: 'preset',
            usage: SmartTileUsage.path,
            materialPalette: ['', 'road'],
            field: SmartTileField.cell(
              semanticCells: [0, 0, 0, 0],
            ),
          ),
        ],
      );

      const operations = MapRegionOperations();
      final painted = operations.apply(map, const {
        'kind': 'region.paint',
        'layerId': 'smart',
        'x': 0,
        'y': 0,
        'value': 'road',
      }).map;
      expect(
        smartTileSemanticCells(painted.layers.single as SmartTileLayer),
        [1, 0, 0, 0],
      );

      final filled = operations.apply(painted, const {
        'kind': 'region.fill',
        'layerId': 'smart',
        'x': 0,
        'y': 0,
        'width': 2,
        'height': 2,
        'value': 'road',
      }).map;
      expect(
        smartTileSemanticCells(filled.layers.single as SmartTileLayer),
        [1, 1, 1, 1],
      );

      final erased = operations.apply(filled, const {
        'kind': 'region.erase',
        'layerId': 'smart',
        'x': 0,
        'y': 0,
      }).map;
      expect(
        smartTileSemanticCells(erased.layers.single as SmartTileLayer),
        [0, 1, 1, 1],
      );
    });

    test(
        'rejects every v5 Smart Tile mutator for edge, corner, and mixed fields',
        () {
      final fields = <SmartTileField>[
        const SmartTileField.corner(
          semanticCells: [0, 0, 0, 0],
          corners: [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        const SmartTileField.edge(
          semanticCells: [0, 0, 0, 0],
          horizontalEdges: [0, 0, 0, 0, 0, 0],
          verticalEdges: [0, 0, 0, 0, 0, 0],
        ),
        const SmartTileField.mixed(
          semanticCells: [0, 0, 0, 0],
          horizontalEdges: [0, 0, 0, 0, 0, 0],
          verticalEdges: [0, 0, 0, 0, 0, 0],
          corners: [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ];
      final mutators = <Map<String, Object?>>[
        {
          'kind': 'region.paint',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'value': 'road'
        },
        {
          'kind': 'region.fill',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'value': 'road'
        },
        {'kind': 'region.erase', 'layerId': 'smart', 'x': 0, 'y': 0},
        {
          'kind': 'region.cut',
          'layerId': 'smart',
          'clipboardId': 'cut',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1
        },
        {
          'kind': 'region.flip',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'axis': 'horizontal'
        },
        {
          'kind': 'region.flood_fill',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'value': 'road'
        },
        {
          'kind': 'region.move',
          'layerId': 'smart',
          'source': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
          'target': {'x': 1, 'y': 1}
        },
        {
          'kind': 'region.paste',
          'layerId': 'smart',
          'clipboardId': 'paste',
          'x': 0,
          'y': 0
        },
        {
          'kind': 'region.replace',
          'layerId': 'smart',
          'from': null,
          'to': 'road'
        },
        {
          'kind': 'region.rotate',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'quarterTurns': 1
        },
        {
          'kind': 'region.stamp',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'values': ['road']
        },
        {
          'kind': 'shape.line',
          'layerId': 'smart',
          'from': {'x': 0, 'y': 0},
          'to': {'x': 1, 'y': 1},
          'value': 'road'
        },
        {
          'kind': 'shape.polygon',
          'layerId': 'smart',
          'points': [
            {'x': 0, 'y': 0},
            {'x': 1, 'y': 0},
            {'x': 0, 'y': 1}
          ],
          'value': 'road',
          'filled': true
        },
        {
          'kind': 'shape.polyline',
          'layerId': 'smart',
          'points': [
            {'x': 0, 'y': 0},
            {'x': 1, 'y': 1}
          ],
          'value': 'road'
        },
        {
          'kind': 'shape.rectangle',
          'layerId': 'smart',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'value': 'road',
          'filled': true
        },
      ];

      for (final field in fields) {
        final map = _map(width: 2, height: 2).copyWith(
          version: ProjectVersion.v5,
          layers: [
            MapLayer.smartTile(
              id: 'smart',
              name: 'Smart',
              presetId: 'preset',
              usage: SmartTileUsage.path,
              materialPalette: const ['', 'road'],
              field: field,
            ),
          ],
        );
        final before = map.toJson();
        for (final operation in mutators) {
          expect(
            () => const MapRegionOperations().apply(
              map,
              operation,
              clipboard: MapRegionClipboard(),
            ),
            throwsA(
              isA<MapAuthoringException>()
                  .having(
                    (error) => error.code,
                    'code',
                    'smart_tile_wang_paint_compiler_required',
                  )
                  .having(
                    (error) => error.details['operation'],
                    'operation',
                    operation['kind'],
                  ),
            ),
            reason: '${field.runtimeType} ${operation['kind']}',
          );
          expect(map.toJson(), before);
        }

        final clipboard = MapRegionClipboard();
        final copied = const MapRegionOperations().apply(
          map,
          const {
            'kind': 'region.copy',
            'layerId': 'smart',
            'clipboardId': 'read-only',
            'x': 0,
            'y': 0,
            'width': 1,
            'height': 1,
          },
          clipboard: clipboard,
        );
        expect(copied.map.toJson(), before);
        expect(copied.changedCells, 0);
        expect(clipboard.contains('read-only'), isTrue);
      }
    });
  });
}

MapData _map({required int width, required int height}) => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: GridSize(width: width, height: height),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          tiles: List<int>.filled(width * height, 0),
        ),
      ],
    );
