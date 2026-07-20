import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderPrimitiveAssetMetrics JSON codec', () {
    test('exposes the V1 effective frame duration default', () {
      expect(defaultBorderVisualFrameDurationMs, 100);
    });

    test('encodes the exact canonical map and round-trips', () {
      final metrics = _metrics();

      final encoded = encodeBorderPrimitiveAssetMetricsJson(metrics);

      expect(encoded, <String, Object?>{
        'assetFingerprint': _assetFingerprint,
        'pixelSize': <String, Object?>{'width': 3, 'height': 2},
        'opaqueBounds': <String, Object?>{
          'x': 0,
          'y': 0,
          'width': 3,
          'height': 2,
        },
        'defaultAnchorPx': <String, Object?>{'x': -2, 'y': 5},
        'occupancyMaskRle': 'border-rle-v1:6:1:2,2,2',
      });
      expect(decodeBorderPrimitiveAssetMetricsJson(encoded), metrics);
    });

    test('accepts a negative anchor and an all-false canonical mask', () {
      final decoded = decodeBorderPrimitiveAssetMetricsJson(
        _metricsJson(
          anchorX: -99,
          anchorY: -7,
          occupancyMaskRle: 'border-rle-v1:6:0:6',
        ),
      );

      expect(decoded.defaultAnchorPx, const BorderPixelPos(x: -99, y: -7));
      expect(decoded.occupancyMaskRle, 'border-rle-v1:6:0:6');
    });

    test('rejects malformed or wrong-length occupancy RLE on decode', () {
      for (final rle in <String>[
        'not-rle',
        'border-rle-v1:5:1:5',
        'border-rle-v1:6:1:2,0,4',
        'border-rle-v1:6:1:6,',
      ]) {
        expect(
          () => decodeBorderPrimitiveAssetMetricsJson(
            _metricsJson(occupancyMaskRle: rle),
          ),
          _formatExceptionAt(r'$.occupancyMaskRle'),
          reason: rle,
        );
      }
    });

    test('rejects malformed or wrong-length occupancy RLE on encode', () {
      for (final rle in <String>[
        'not-rle',
        'border-rle-v1:5:1:5',
      ]) {
        expect(
          () => encodeBorderPrimitiveAssetMetricsJson(
            _metrics(occupancyMaskRle: rle),
          ),
          _formatExceptionAt(r'$.occupancyMaskRle'),
          reason: rle,
        );
      }
    });

    test('rejects pixel dimensions outside the bounded V1 range', () {
      for (final width in <int>[0, 8193]) {
        expect(
          () => decodeBorderPrimitiveAssetMetricsJson(
            _metricsJson(pixelWidth: width),
          ),
          _formatExceptionAt(r'$.pixelSize.width'),
          reason: 'width: $width',
        );
      }
      for (final height in <int>[0, 8193]) {
        expect(
          () => decodeBorderPrimitiveAssetMetricsJson(
            _metricsJson(pixelHeight: height),
          ),
          _formatExceptionAt(r'$.pixelSize.height'),
          reason: 'height: $height',
        );
      }

      final oversized = BorderPrimitiveAssetMetrics(
        assetFingerprint: _assetFingerprint,
        pixelSize: const GridSize(width: 8193, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: 'border-rle-v1:8193:0:8193',
      );
      expect(
        () => encodeBorderPrimitiveAssetMetricsJson(oversized),
        _formatExceptionAt(r'$.pixelSize.width'),
      );
    });

    test('rejects opaque bounds outside pixelSize', () {
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(
          _metricsJson(opaqueX: -1),
        ),
        _formatExceptionAt(r'$.opaqueBounds.x'),
      );
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(
          _metricsJson(opaqueWidth: 4),
        ),
        _formatExceptionAt(r'$.opaqueBounds'),
      );
    });

    test('rejects an empty asset fingerprint at its field path', () {
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(
          _metricsJson(assetFingerprint: ''),
        ),
        _formatExceptionAt(r'$.assetFingerprint'),
      );
    });

    test('requires exact keys and strict nested scalar types', () {
      final unknownRoot = _metricsJson()..['unknown'] = true;
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(unknownRoot),
        _formatExceptionAt(r'$.unknown'),
      );

      final unknownSize = _metricsJson();
      (unknownSize['pixelSize']! as Map<String, Object?>)['columns'] = 3;
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(unknownSize),
        _formatExceptionAt(r'$.pixelSize.columns'),
      );

      final missingAnchorY = _metricsJson();
      (missingAnchorY['defaultAnchorPx']! as Map<String, Object?>).remove('y');
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(missingAnchorY),
        _formatExceptionAt(r'$.defaultAnchorPx.y'),
      );

      final wrongWidth = _metricsJson();
      (wrongWidth['pixelSize']! as Map<String, Object?>)['width'] = 3.0;
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(wrongWidth),
        _formatExceptionAt(r'$.pixelSize.width'),
      );
    });

    test('uses a custom JSONPath and never mutates decoder input', () {
      final input = _metricsJson();
      final before = _deepCopy(input);

      expect(
        decodeBorderPrimitiveAssetMetricsJson(
          input,
          path: r'$.catalog.blueprints[2].metrics',
        ),
        _metrics(),
      );
      expect(input, before);

      final invalid = _metricsJson()..remove('pixelSize');
      expect(
        () => decodeBorderPrimitiveAssetMetricsJson(
          invalid,
          path: r'$.catalog.blueprints[2].metrics',
        ),
        _formatExceptionAt(r'$.catalog.blueprints[2].metrics.pixelSize'),
      );
    });
  });

  group('BorderVisualSnapshot JSON codec', () {
    test('encodes a static snapshot exactly and always writes duration', () {
      final snapshot = _snapshot(
        frames: <BorderVisualFrameSnapshot>[_frame()],
      );

      final encoded = encodeBorderVisualSnapshotJson(snapshot);

      expect(encoded, <String, Object?>{
        'id': 'border-snapshot-sha256:$_snapshotFingerprint',
        'contentFingerprint': _snapshotFingerprint,
        'frames': <Object?>[
          <String, Object?>{
            'relativeAssetPath': _framePath,
            'sourceRectPx': <String, Object?>{
              'x': 4,
              'y': 8,
              'width': 16,
              'height': 12,
            },
            'durationMs': 100,
          },
        ],
      });
      expect(decodeBorderVisualSnapshotJson(encoded), snapshot);
    });

    test('decodes absent duration as 100 and omits absent transparency', () {
      final json = _snapshotJson();
      final frame =
          (json['frames']! as List<Object?>).single as Map<String, Object?>;
      frame.remove('durationMs');

      final decoded = decodeBorderVisualSnapshotJson(json);

      expect(decoded.frames.single.durationMs, 100);
      expect(decoded.frames.single.transparentColorArgb, isNull);
      expect(
        encodeBorderVisualSnapshotJson(decoded)['frames'],
        <Object?>[
          <String, Object?>{
            'relativeAssetPath': _framePath,
            'sourceRectPx': <String, Object?>{
              'x': 4,
              'y': 8,
              'width': 16,
              'height': 12,
            },
            'durationMs': 100,
          },
        ],
      );
    });

    test('preserves animated frame order, duplicates, offsets, and colors', () {
      final first = _frame(
        path: 'assets/borders/snapshots/a/first.png',
        x: 0,
        y: 1,
        durationMs: 80,
        transparentColorArgb: 0,
      );
      final duplicate = _frame(
        path: 'assets/borders/snapshots/a/first.png',
        x: 0,
        y: 1,
        durationMs: 80,
        transparentColorArgb: 0,
      );
      final third = _frame(
        path: 'assets/borders/snapshots/a/third.png',
        x: 30,
        y: 40,
        durationMs: 120,
        transparentColorArgb: 0xffffffff,
      );
      final snapshot = _snapshot(frames: <BorderVisualFrameSnapshot>[
        first,
        duplicate,
        third,
      ]);

      final decoded = decodeBorderVisualSnapshotJson(
        encodeBorderVisualSnapshotJson(snapshot),
      );

      expect(decoded.frames, <BorderVisualFrameSnapshot>[
        first,
        duplicate,
        third,
      ]);
      expect(decoded.frames[2].sourceRectPx.x, 30);
      expect(decoded.frames[2].sourceRectPx.y, 40);
    });

    test('accepts both inclusive 32-bit ARGB extrema without normalization',
        () {
      for (final color in <int>[0, 0xffffffff]) {
        final json = _snapshotJson(transparentColorArgb: color);
        final frame = decodeBorderVisualSnapshotJson(json).frames.single;

        expect(frame.transparentColorArgb, color);
        final encodedFrame = (encodeBorderVisualSnapshotJson(_snapshot(
                    frames: <BorderVisualFrameSnapshot>[frame]))['frames']!
                as List<Object?>)
            .single as Map<String, Object?>;
        expect(encodedFrame['transparentColorArgb'], color);
      }
    });

    test('rejects null, wrong, zero, and negative present duration values', () {
      for (final duration in <Object?>[null, '100', 100.0, 0, -1]) {
        expect(
          () => decodeBorderVisualSnapshotJson(
            _snapshotJson(durationMs: duration),
          ),
          _formatExceptionAt(r'$.frames[0].durationMs'),
          reason: 'duration: $duration',
        );
      }
    });

    test('rejects null, wrong, negative, and overflowing present ARGB', () {
      for (final color in <Object?>[null, '0', 0.0, -1, 0x100000000]) {
        expect(
          () => decodeBorderVisualSnapshotJson(
            _snapshotJson(transparentColorArgb: color),
          ),
          _formatExceptionAt(r'$.frames[0].transparentColorArgb'),
          reason: 'color: $color',
        );
      }
    });

    test('rejects an empty frame list and unequal frame dimensions', () {
      expect(
        () =>
            decodeBorderVisualSnapshotJson(_snapshotJson(frames: <Object?>[])),
        _formatExceptionAt(r'$.frames'),
      );

      final json = _snapshotJson(frames: <Object?>[
        _frameJson(),
        _frameJson(width: 15),
      ]);
      expect(
        () => decodeBorderVisualSnapshotJson(json),
        _formatExceptionAt(r'$.frames[1].sourceRectPx'),
      );
    });

    test('rejects unsafe snapshot paths', () {
      for (final path in <String>[
        '',
        '/assets/borders/snapshots/a.png',
        'assets/other/a.png',
        'assets/borders/snapshots/../a.png',
        r'assets\borders\snapshots\a.png',
        'assets/borders/snapshots/C:a.png',
      ]) {
        expect(
          () => decodeBorderVisualSnapshotJson(_snapshotJson(path: path)),
          _formatExceptionAt(r'$.frames[0].relativeAssetPath'),
          reason: path,
        );
      }
    });

    test('rejects malformed source rectangles at precise field paths', () {
      expect(
        () => decodeBorderVisualSnapshotJson(_snapshotJson(sourceX: -1)),
        _formatExceptionAt(r'$.frames[0].sourceRectPx.x'),
      );
      expect(
        () => decodeBorderVisualSnapshotJson(_snapshotJson(sourceY: -1)),
        _formatExceptionAt(r'$.frames[0].sourceRectPx.y'),
      );
      expect(
        () => decodeBorderVisualSnapshotJson(_snapshotJson(width: 0)),
        _formatExceptionAt(r'$.frames[0].sourceRectPx.width'),
      );
      expect(
        () => decodeBorderVisualSnapshotJson(_snapshotJson(height: 0)),
        _formatExceptionAt(r'$.frames[0].sourceRectPx.height'),
      );
    });

    test('rejects malformed content fingerprints and mismatched snapshot IDs',
        () {
      for (final fingerprint in <String>[
        'short',
        'A' * 64,
        'g' * 64,
      ]) {
        expect(
          () => decodeBorderVisualSnapshotJson(
            _snapshotJson(contentFingerprint: fingerprint),
          ),
          _formatExceptionAt(r'$.contentFingerprint'),
          reason: fingerprint,
        );
      }

      expect(
        () => decodeBorderVisualSnapshotJson(
          _snapshotJson(id: 'border-snapshot-sha256:${'b' * 64}'),
        ),
        _formatExceptionAt(r'$.id'),
      );
    });

    test('requires exact keys and strict nested types', () {
      final unknownRoot = _snapshotJson()..['unknown'] = true;
      expect(
        () => decodeBorderVisualSnapshotJson(unknownRoot),
        _formatExceptionAt(r'$.unknown'),
      );

      final unknownFrame = _snapshotJson();
      ((unknownFrame['frames']! as List<Object?>).single
          as Map<String, Object?>)['loop'] = true;
      expect(
        () => decodeBorderVisualSnapshotJson(unknownFrame),
        _formatExceptionAt(r'$.frames[0].loop'),
      );

      final unknownRect = _snapshotJson();
      ((((unknownRect['frames']! as List<Object?>).single
              as Map<String, Object?>)['sourceRectPx']!)
          as Map<String, Object?>)['right'] = 20;
      expect(
        () => decodeBorderVisualSnapshotJson(unknownRect),
        _formatExceptionAt(r'$.frames[0].sourceRectPx.right'),
      );

      final missingFrames = _snapshotJson()..remove('frames');
      expect(
        () => decodeBorderVisualSnapshotJson(missingFrames),
        _formatExceptionAt(r'$.frames'),
      );

      final wrongFrames = _snapshotJson()..['frames'] = <String, Object?>{};
      expect(
        () => decodeBorderVisualSnapshotJson(wrongFrames),
        _formatExceptionAt(r'$.frames'),
      );
    });

    test('uses a custom JSONPath and never mutates decoder input', () {
      final input = _snapshotJson();
      final before = _deepCopy(input);

      expect(
        decodeBorderVisualSnapshotJson(
          input,
          path: r'$.borderCatalog.visualSnapshots[4]',
        ),
        _snapshot(),
      );
      expect(input, before);

      final invalid = _snapshotJson();
      final frame =
          (invalid['frames']! as List<Object?>).single as Map<String, Object?>;
      frame['durationMs'] = 0;
      expect(
        () => decodeBorderVisualSnapshotJson(
          invalid,
          path: r'$.borderCatalog.visualSnapshots[4]',
        ),
        _formatExceptionAt(
          r'$.borderCatalog.visualSnapshots[4].frames[0].durationMs',
        ),
      );
    });

    test('encoding validates custom paths too', () {
      final invalidMetrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: _assetFingerprint,
        pixelSize: const GridSize(width: 8193, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: 'border-rle-v1:8193:0:8193',
      );

      expect(
        () => encodeBorderPrimitiveAssetMetricsJson(
          invalidMetrics,
          path: r'$.draft.metrics',
        ),
        _formatExceptionAt(r'$.draft.metrics.pixelSize.width'),
      );
    });
  });
}

BorderPrimitiveAssetMetrics _metrics({
  String occupancyMaskRle = 'border-rle-v1:6:1:2,2,2',
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: _assetFingerprint,
      pixelSize: const GridSize(width: 3, height: 2),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 3, height: 2),
      defaultAnchorPx: const BorderPixelPos(x: -2, y: 5),
      occupancyMaskRle: occupancyMaskRle,
    );

Map<String, Object?> _metricsJson({
  String assetFingerprint = _assetFingerprint,
  int pixelWidth = 3,
  int pixelHeight = 2,
  int opaqueX = 0,
  int opaqueY = 0,
  int opaqueWidth = 3,
  int opaqueHeight = 2,
  int anchorX = -2,
  int anchorY = 5,
  String occupancyMaskRle = 'border-rle-v1:6:1:2,2,2',
}) =>
    <String, Object?>{
      'assetFingerprint': assetFingerprint,
      'pixelSize': <String, Object?>{
        'width': pixelWidth,
        'height': pixelHeight,
      },
      'opaqueBounds': <String, Object?>{
        'x': opaqueX,
        'y': opaqueY,
        'width': opaqueWidth,
        'height': opaqueHeight,
      },
      'defaultAnchorPx': <String, Object?>{'x': anchorX, 'y': anchorY},
      'occupancyMaskRle': occupancyMaskRle,
    };

BorderVisualSnapshot _snapshot({
  List<BorderVisualFrameSnapshot>? frames,
}) =>
    BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$_snapshotFingerprint',
      contentFingerprint: _snapshotFingerprint,
      frames: frames ?? <BorderVisualFrameSnapshot>[_frame()],
    );

BorderVisualFrameSnapshot _frame({
  String path = _framePath,
  int x = 4,
  int y = 8,
  int width = 16,
  int height = 12,
  int durationMs = 100,
  int? transparentColorArgb,
}) =>
    BorderVisualFrameSnapshot(
      relativeAssetPath: path,
      sourceRectPx: BorderPixelRect(
        x: x,
        y: y,
        width: width,
        height: height,
      ),
      durationMs: durationMs,
      transparentColorArgb: transparentColorArgb,
    );

Map<String, Object?> _snapshotJson({
  String id = 'border-snapshot-sha256:$_snapshotFingerprint',
  String contentFingerprint = _snapshotFingerprint,
  List<Object?>? frames,
  String path = _framePath,
  int sourceX = 4,
  int sourceY = 8,
  int width = 16,
  int height = 12,
  Object? durationMs = 100,
  Object? transparentColorArgb = _absent,
}) =>
    <String, Object?>{
      'id': id,
      'contentFingerprint': contentFingerprint,
      'frames': frames ??
          <Object?>[
            _frameJson(
              path: path,
              x: sourceX,
              y: sourceY,
              width: width,
              height: height,
              durationMs: durationMs,
              transparentColorArgb: transparentColorArgb,
            ),
          ],
    };

Map<String, Object?> _frameJson({
  String path = _framePath,
  int x = 4,
  int y = 8,
  int width = 16,
  int height = 12,
  Object? durationMs = 100,
  Object? transparentColorArgb = _absent,
}) {
  final result = <String, Object?>{
    'relativeAssetPath': path,
    'sourceRectPx': <String, Object?>{
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    },
    'durationMs': durationMs,
  };
  if (!identical(transparentColorArgb, _absent)) {
    result['transparentColorArgb'] = transparentColorArgb;
  }
  return result;
}

Map<String, Object?> _deepCopy(Map<String, Object?> input) => <String, Object?>{
      for (final entry in input.entries) entry.key: _deepCopyValue(entry.value),
    };

Object? _deepCopyValue(Object? value) {
  if (value is Map<String, Object?>) {
    return _deepCopy(value);
  }
  if (value is List<Object?>) {
    return value.map(_deepCopyValue).toList(growable: false);
  }
  return value;
}

Matcher _formatExceptionAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

const Object _absent = Object();
const String _assetFingerprint =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const String _snapshotFingerprint =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _framePath = 'assets/borders/snapshots/aa/frame.png';
