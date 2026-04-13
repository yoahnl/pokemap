import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElementCollisionMaskCodec', () {
    test('packed bits roundtrip preserves mask', () {
      const width = 5;
      const height = 3;
      final pixels = <bool>[
        true, false, true, false, true,
        false, true, false, true, false,
        true, true, false, false, false,
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
  });
}
