import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElementCollisionMaskCodec', () {
    test('packed bits roundtrip preserves mask', () {
      const width = 5;
      const height = 3;
      final pixels = <bool>[
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        false,
        false,
      ];
      final encoded = ElementCollisionMaskCodec.encodePackedBits(
        widthPx: width,
        heightPx: height,
        solidPixels: pixels,
      );
      final decoded = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: width,
        heightPx: height,
        dataBase64: encoded,
      );
      expect(decoded, pixels);
    });

    test('cellsFromPixelMask projects blocking cells from mask', () {
      // 2x2 tiles, 2x2 px per tile => 4x4 px mask
      const widthPx = 4;
      const heightPx = 4;
      final pixels = List<bool>.filled(widthPx * heightPx, false);
      // Active entire bottom-left tile (cell 0,1)
      for (var y = 2; y < 4; y++) {
        for (var x = 0; x < 2; x++) {
          pixels[y * widthPx + x] = true;
        }
      }
      final mask = ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );
      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 2,
        tileHeight: 2,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );
      expect(cells, const [GridPos(x: 0, y: 1)]);
    });

    test('cellsFromPixelMask activates a cell with one solid pixel by default',
        () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [GridPos(x: 3, y: 2)],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
      );

      expect(cells, const [GridPos(x: 0, y: 0)]);
    });

    test('cellsFromPixelMask returns empty cells for an empty mask', () {
      final mask = _mask(widthPx: 8, heightPx: 8);

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );

      expect(cells, isEmpty);
    });

    test('cellsFromPixelMask returns cells in stable y then x order', () {
      final mask = _mask(
        widthPx: 8,
        heightPx: 8,
        solidPoints: const [
          GridPos(x: 4, y: 4),
          GridPos(x: 0, y: 0),
          GridPos(x: 4, y: 0),
        ],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );

      expect(
        cells,
        const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('cellsFromPixelMask filters sparse cells with minimum ratio', () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [GridPos(x: 0, y: 0)],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
        minimumSolidRatioPerCell: 0.5,
      );

      expect(cells, isEmpty);
    });

    test('cellsFromPixelMask accepts cells dense enough for minimum ratio', () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
        ],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
        minimumSolidRatioPerCell: 0.5,
      );

      expect(cells, const [GridPos(x: 0, y: 0)]);
    });

    test('cellsFromPixelMask respects requested source tile dimensions', () {
      final mask = _mask(
        widthPx: 8,
        heightPx: 8,
        solidPoints: const [
          GridPos(x: 4, y: 0),
          GridPos(x: 7, y: 3),
        ],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
      );

      expect(cells, isEmpty);
    });
  });
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  List<GridPos> solidPoints = const [],
}) {
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final point in solidPoints) {
    pixels[point.y * widthPx + point.x] = true;
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
}
