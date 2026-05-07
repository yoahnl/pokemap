import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/tileset_grid_metrics.dart';

void main() {
  group('TilesetGridMetrics', () {
    test('uses only full tile cells for non-aligned images', () {
      final metrics = TilesetGridMetrics.fromImagePixels(
        imageWidth: 124,
        imageHeight: 124,
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(metrics.columns, 3);
      expect(metrics.rows, 3);
      expect(metrics.usablePixelWidth, 96);
      expect(metrics.usablePixelHeight, 96);
      expect(metrics.hasTrailingPixels, isTrue);
    });

    test('keeps aligned tilesets unchanged', () {
      final metrics = TilesetGridMetrics.fromImagePixels(
        imageWidth: 512,
        imageHeight: 256,
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(metrics.columns, 16);
      expect(metrics.rows, 8);
      expect(metrics.usablePixelWidth, 512);
      expect(metrics.usablePixelHeight, 256);
      expect(metrics.hasTrailingPixels, isFalse);
    });
  });
}
