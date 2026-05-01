import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/terrain_editor/path_mapping_editor_helpers.dart';

void main() {
  group('path mapping editor helpers', () {
    test('converts zoomed local positions to tile coordinates', () {
      final pos = pathMappingTileFromLocalPosition(
        localPosition: const ui.Offset(175, 72),
        displaySize: const ui.Size(256, 128),
        columns: 4,
        rows: 2,
      );

      expect(pos, const GridPos(x: 2, y: 1));
    });

    test('clamps zoom controls to the supported range', () {
      expect(pathMappingTilesetZoomIn(1), 1.25);
      expect(pathMappingTilesetZoomOut(1.25), 1);
      expect(pathMappingTilesetZoomOut(0.5), 0.5);
      expect(pathMappingTilesetZoomIn(8), 8);
    });

    test('keeps original bytes when alpha preview is disabled', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      ]);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: imageBytes,
        enabled: false,
        hexRgb: 'f05ba1',
      );

      expect(identical(result.bytes, imageBytes), isTrue);
      expect(result.errorMessage, isNull);
    });

    test('applies alpha preview for a valid RGB hex color', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: imageBytes,
        enabled: true,
        hexRgb: 'f05ba1',
      );
      final image = img.decodePng(result.bytes)!;

      expect(result.errorMessage, isNull);
      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
    });

    test('reports invalid alpha preview hex without modifying bytes', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      ]);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: imageBytes,
        enabled: true,
        hexRgb: 'not-hex',
      );

      expect(identical(result.bytes, imageBytes), isTrue);
      expect(result.errorMessage, 'Couleur hex invalide');
    });

    test('alpha preview never writes back to the source image file', () async {
      final temp = await Directory.systemTemp.createTemp('path_mapping_alpha_');
      addTearDown(() => temp.delete(recursive: true));
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      ]);
      final file = File('${temp.path}/tileset.png');
      await file.writeAsBytes(imageBytes);

      final result = createPathMappingAlphaPreviewBytes(
        originalPngBytes: await file.readAsBytes(),
        enabled: true,
        hexRgb: 'f05ba1',
      );
      final after = await file.readAsBytes();

      expect(result.bytes, isNot(imageBytes));
      expect(after, imageBytes);
    });
  });
}

Uint8List _pngBytes(List<_Pixel> pixels) {
  final image = img.Image(width: pixels.length, height: 1, numChannels: 4);
  for (var x = 0; x < pixels.length; x += 1) {
    final pixel = pixels[x];
    image.setPixelRgba(x, 0, pixel.red, pixel.green, pixel.blue, pixel.alpha);
  }
  return img.encodePng(image);
}

_Pixel _pixelAt(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return _Pixel(
    red: pixel.r.toInt(),
    green: pixel.g.toInt(),
    blue: pixel.b.toInt(),
    alpha: pixel.a.toInt(),
  );
}

final class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _Pixel &&
            other.red == red &&
            other.green == green &&
            other.blue == blue &&
            other.alpha == alpha;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  @override
  String toString() {
    return '_Pixel(red: $red, green: $green, blue: $blue, alpha: $alpha)';
  }
}
