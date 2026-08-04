import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('canonical TileLayer palette', () {
    test('round-trips sparse multi-tileset D4 references', () {
      const layer = TileLayer(
        id: 'ground',
        name: 'Ground',
        palette: <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(
            tilesetId: 'terrain',
            localTileId: 0,
          ),
          TileLayerPaletteEntry(
            tilesetId: 'props',
            localTileId: 639,
            transform: SmartTileSpriteTransform(
              quarterTurns: 1,
              flipX: true,
            ),
          ),
        ],
        cells: <int>[1, 2, 0, 2],
      );

      final json = layer.toJson();
      expect(json, isNot(contains('tilesetId')));
      expect(json, isNot(contains('tiles')));
      expect(json['cells'], <int>[1, 2, 0, 2]);
      final decoded = MapLayer.fromJson(json) as TileLayer;
      expect(decoded, layer);
      expect(resolveTileLayerCell(decoded, 0), layer.palette.first);
      expect(resolveTileLayerCell(decoded, 1), layer.palette.last);
      expect(resolveTileLayerCell(decoded, 2), isNull);
    });

    test('migrates one legacy map layer through its map tileset fallback', () {
      final map = MapData.fromJson(<String, dynamic>{
        'id': 'legacy',
        'name': 'Legacy',
        'size': <String, Object?>{'width': 2, 'height': 2},
        'version': 'v6',
        'tilesetId': 'terrain',
        'layers': <Object?>[
          <String, Object?>{
            'runtimeType': 'tile',
            'id': 'ground',
            'name': 'Ground',
            'isVisible': true,
            'opacity': 1.0,
            'tiles': <int>[1, 0, 7, 1],
          },
        ],
      });

      final layer = map.layers.single as TileLayer;
      expect(layer.cells, <int>[1, 0, 2, 1]);
      expect(
        layer.palette,
        const <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: 'terrain', localTileId: 0),
          TileLayerPaletteEntry(tilesetId: 'terrain', localTileId: 6),
        ],
      );
      final serialized = map.toJson();
      final serializedLayer =
          (serialized['layers']! as List).single as Map<String, dynamic>;
      expect(serializedLayer, isNot(contains('tilesetId')));
      expect(serializedLayer, isNot(contains('tiles')));
      expect(serializedLayer, containsPair('cells', <int>[1, 0, 2, 1]));
    });

    test('rejects an out-of-bounds palette cell', () {
      final map = MapData(
        id: 'invalid',
        name: 'Invalid',
        size: const GridSize(width: 1, height: 1),
        layers: const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            palette: <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(
                tilesetId: 'terrain',
                localTileId: 0,
              ),
            ],
            cells: <int>[2],
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
