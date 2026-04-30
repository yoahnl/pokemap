import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/path_center_pattern_static_preview_renderer.dart';

void main() {
  group('renderPathCenterPatternStaticPreviewPng', () {
    test('renders a 1x1 preview from the first frame source tile', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 1, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 2,
      );
      final preview = _decodePng(previewBytes);

      expect(preview.width, 2);
      expect(preview.height, 2);
      _expectSolidRect(
        preview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
    });

    test('renders a 2x2 preview in local cell positions', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 255, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
          _Pixel(red: 255, green: 255, blue: 0, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 2,
        height: 2,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
          (1, 0): TilesetSourceRect(x: 1, y: 0),
          (0, 1): TilesetSourceRect(x: 2, y: 0),
          (1, 1): TilesetSourceRect(x: 3, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 2,
      );
      final preview = _decodePng(previewBytes);

      expect(preview.width, 4);
      expect(preview.height, 4);
      _expectSolidRect(
        preview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectSolidRect(
        preview,
        left: 2,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 0, green: 255, blue: 0, alpha: 255),
      );
      _expectSolidRect(
        preview,
        left: 0,
        top: 2,
        width: 2,
        height: 2,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectSolidRect(
        preview,
        left: 2,
        top: 2,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 255, blue: 0, alpha: 255),
      );
    });

    test('applies optional transparentColor before composing preview', () {
      final tilesetBytes = _customImagePng(2, 1, (image) {
        image.setPixelRgba(0, 0, 240, 91, 161, 255);
        image.setPixelRgba(1, 0, 0, 0, 255, 255);
      });
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final preview = _decodePng(previewBytes);

      expect(
        _pixelAt(preview, 0, 0),
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 0),
      );
      expect(
        _pixelAt(preview, 1, 0),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
    });

    test('keeps transparent-color-looking pixels opaque when color is null',
        () {
      final tilesetBytes = _customImagePng(2, 1, (image) {
        image.setPixelRgba(0, 0, 240, 91, 161, 255);
        image.setPixelRgba(1, 0, 0, 0, 255, 255);
      });
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
      );
      final preview = _decodePng(previewBytes);

      expect(
        _pixelAt(preview, 0, 0),
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      );
    });

    test('rejects source rects outside the tileset image', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 1, y: 0),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-1x1 source rects in V0', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0, width: 2),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid PNG bytes', () {
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: Uint8List.fromList([1, 2, 3]),
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-positive tile dimensions', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 0,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

PathCenterPattern _pattern({
  required int width,
  required int height,
  required Map<(int, int), TilesetSourceRect> sources,
}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: width, height: height),
    cells: [
      for (final entry in sources.entries)
        PathCenterPatternCell(
          localX: entry.key.$1,
          localY: entry.key.$2,
          frames: [
            TilesetVisualFrame(source: entry.value),
          ],
        ),
    ],
  );
}

Uint8List _horizontalTilesetPng({
  required int tileWidthPx,
  required int tileHeightPx,
  required List<_Pixel> colors,
}) {
  return _customImagePng(colors.length * tileWidthPx, tileHeightPx, (image) {
    for (var tileX = 0; tileX < colors.length; tileX += 1) {
      final color = colors[tileX];
      for (var y = 0; y < tileHeightPx; y += 1) {
        for (var x = 0; x < tileWidthPx; x += 1) {
          image.setPixelRgba(
            tileX * tileWidthPx + x,
            y,
            color.red,
            color.green,
            color.blue,
            color.alpha,
          );
        }
      }
    }
  });
}

Uint8List _customImagePng(
  int width,
  int height,
  void Function(img.Image image) paint,
) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  paint(image);
  return img.encodePng(image);
}

img.Image _decodePng(Uint8List imageBytes) {
  final image = img.decodePng(imageBytes);
  expect(image, isNotNull);
  return image!;
}

void _expectSolidRect(
  img.Image image, {
  required int left,
  required int top,
  required int width,
  required int height,
  required _Pixel color,
}) {
  for (var y = top; y < top + height; y += 1) {
    for (var x = left; x < left + width; x += 1) {
      expect(_pixelAt(image, x, y), color);
    }
  }
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
