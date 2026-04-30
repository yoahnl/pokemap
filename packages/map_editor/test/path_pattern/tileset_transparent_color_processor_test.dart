import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';

void main() {
  group('applyTilesetTransparentColorToPngBytes', () {
    test('returns the same bytes instance when transparentColor is null', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: null,
      );

      expect(identical(result, imageBytes), isTrue);
      expect(result, imageBytes);
    });

    test('turns matching RGB pixels transparent and preserves others', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
    });

    test('matches RGB while ignoring existing alpha', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 128),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 128),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 128));
    });

    test('uses the value object parser case-insensitively', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('#F05BA1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
    });

    test('leaves images without matching pixels unchanged by channel values',
        () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 0, green: 255, blue: 0, alpha: 64),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 128),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 0, green: 255, blue: 0, alpha: 64));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 128));
    });

    test('rejects invalid PNG bytes', () {
      expect(
        () => applyTilesetTransparentColorToPngBytes(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        ),
        throwsA(isA<ArgumentError>()),
      );
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

img.Image _decodePng(Uint8List imageBytes) {
  final image = img.decodePng(imageBytes);
  expect(image, isNotNull);
  return image!;
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
