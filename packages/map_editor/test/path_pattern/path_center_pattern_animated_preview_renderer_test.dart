import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/path_center_pattern_animated_preview_renderer.dart';

void main() {
  group('renderPathCenterPatternAnimatedPreviewPng', () {
    test('keeps a single-frame 1x1 pattern stable across elapsed time', () {
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      final initialPreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
      );
      final latePreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 1000,
        ),
      );

      _expectSolidRect(
        initialPreview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectSolidRect(
        latePreview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
    });

    test('loops two explicit-duration frames for a 1x1 pattern', () {
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
        frames: {
          (0, 0): [
            _frame(0, durationMs: 100),
            _frame(1, durationMs: 200),
          ],
        },
      );

      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 0,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 99,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 100,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 299,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 300,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 399,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 400,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
    });

    test('resolves independent 2x2 cell timelines', () {
      const colors = [
        _Pixel(red: 10, green: 0, blue: 0, alpha: 255),
        _Pixel(red: 20, green: 0, blue: 0, alpha: 255),
        _Pixel(red: 0, green: 10, blue: 0, alpha: 255),
        _Pixel(red: 0, green: 20, blue: 0, alpha: 255),
        _Pixel(red: 0, green: 0, blue: 10, alpha: 255),
        _Pixel(red: 0, green: 0, blue: 20, alpha: 255),
        _Pixel(red: 10, green: 10, blue: 0, alpha: 255),
        _Pixel(red: 20, green: 20, blue: 0, alpha: 255),
      ];
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: colors,
      );
      final pattern = _pattern(
        width: 2,
        height: 2,
        frames: {
          (0, 0): [_frame(0, durationMs: 100), _frame(1, durationMs: 100)],
          (1, 0): [_frame(2, durationMs: 100), _frame(3, durationMs: 100)],
          (0, 1): [_frame(4, durationMs: 100), _frame(5, durationMs: 100)],
          (1, 1): [_frame(6, durationMs: 100), _frame(7, durationMs: 100)],
        },
      );

      final initialPreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
      );
      final secondFramePreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 100,
        ),
      );

      expect(initialPreview.width, 4);
      expect(initialPreview.height, 4);
      _expectQuadrants(
        initialPreview,
        topLeft: colors[0],
        topRight: colors[2],
        bottomLeft: colors[4],
        bottomRight: colors[6],
      );
      _expectQuadrants(
        secondFramePreview,
        topLeft: colors[1],
        topRight: colors[3],
        bottomLeft: colors[5],
        bottomRight: colors[7],
      );
    });

    test('uses map_core default duration for null frame durations', () {
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
        frames: {
          (0, 0): [_frame(0), _frame(1)],
        },
      );

      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 0,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: defaultPlacedElementAnimationFrameDurationMs - 1,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: defaultPlacedElementAnimationFrameDurationMs,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: defaultPlacedElementAnimationFrameDurationMs * 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
    });

    test('rejects non-positive frame durations', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
        ],
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: _pattern(
            width: 1,
            height: 1,
            frames: {
              (0, 0): [_frame(0, durationMs: 0)],
            },
          ),
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: _pattern(
            width: 1,
            height: 1,
            frames: {
              (0, 0): [_frame(0, durationMs: -1)],
            },
          ),
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      final previewBytes = renderPathCenterPatternAnimatedPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
        elapsedMs: 0,
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      final previewBytes = renderPathCenterPatternAnimatedPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
        elapsedMs: 0,
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
        frames: {
          (0, 0): [_frame(1)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
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
        frames: {
          (0, 0): [_frame(0, width: 2)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid PNG bytes', () {
      final pattern = _pattern(
        width: 1,
        height: 1,
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: Uint8List.fromList([1, 2, 3]),
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative elapsedMs and non-positive tile dimensions', () {
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 0,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 0,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

PathCenterPattern _pattern({
  required int width,
  required int height,
  required Map<(int, int), List<TilesetVisualFrame>> frames,
}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: width, height: height),
    cells: [
      for (final entry in frames.entries)
        PathCenterPatternCell(
          localX: entry.key.$1,
          localY: entry.key.$2,
          frames: entry.value,
        ),
    ],
  );
}

TilesetVisualFrame _frame(
  int sourceX, {
  int sourceY = 0,
  int width = 1,
  int height = 1,
  int? durationMs,
}) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(
      x: sourceX,
      y: sourceY,
      width: width,
      height: height,
    ),
    durationMs: durationMs,
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

void _expectTopLeftColorAtElapsed({
  required Uint8List tilesetBytes,
  required PathCenterPattern pattern,
  required int elapsedMs,
  required _Pixel color,
}) {
  final preview = _decodePng(
    renderPathCenterPatternAnimatedPreviewPng(
      tilesetPngBytes: tilesetBytes,
      pattern: pattern,
      tileWidthPx: 2,
      tileHeightPx: 2,
      elapsedMs: elapsedMs,
    ),
  );

  _expectSolidRect(
    preview,
    left: 0,
    top: 0,
    width: 2,
    height: 2,
    color: color,
  );
}

void _expectQuadrants(
  img.Image image, {
  required _Pixel topLeft,
  required _Pixel topRight,
  required _Pixel bottomLeft,
  required _Pixel bottomRight,
}) {
  _expectSolidRect(
    image,
    left: 0,
    top: 0,
    width: 2,
    height: 2,
    color: topLeft,
  );
  _expectSolidRect(
    image,
    left: 2,
    top: 0,
    width: 2,
    height: 2,
    color: topRight,
  );
  _expectSolidRect(
    image,
    left: 0,
    top: 2,
    width: 2,
    height: 2,
    color: bottomLeft,
  );
  _expectSolidRect(
    image,
    left: 2,
    top: 2,
    width: 2,
    height: 2,
    color: bottomRight,
  );
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
