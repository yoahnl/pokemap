import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderPrimitiveAssetMetrics', () {
    test('rejects empty asset fingerprints and occupancy RLE payloads', () {
      expect(
        () => BorderPrimitiveAssetMetrics(
          assetFingerprint: '',
          pixelSize: const GridSize(width: 1, height: 1),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
          occupancyMaskRle: 'opaque',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderPrimitiveAssetMetrics(
          assetFingerprint: 'fingerprint',
          pixelSize: const GridSize(width: 1, height: 1),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
          occupancyMaskRle: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('owns source metrics without decoding the occupancy RLE', () {
      final metrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: 'source-fingerprint',
        pixelSize: const GridSize(width: 16, height: 12),
        opaqueBounds: BorderPixelRect(x: 1, y: 2, width: 10, height: 8),
        defaultAnchorPx: const BorderPixelPos(x: 5, y: 9),
        occupancyMaskRle: 'not-decoded-by-the-domain-model',
      );

      expect(metrics.assetFingerprint, 'source-fingerprint');
      expect(metrics.pixelSize, const GridSize(width: 16, height: 12));
      expect(metrics.opaqueBounds.width, 10);
      expect(metrics.defaultAnchorPx, const BorderPixelPos(x: 5, y: 9));
      expect(metrics.occupancyMaskRle, 'not-decoded-by-the-domain-model');
      expect(metrics, _metrics());
    });

    test('requires positive pixel dimensions and in-bounds opaque bounds', () {
      expect(
        () => BorderPrimitiveAssetMetrics(
          assetFingerprint: 'source-fingerprint',
          pixelSize: const GridSize(width: 0, height: 12),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
          occupancyMaskRle: 'opaque',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderPrimitiveAssetMetrics(
          assetFingerprint: 'source-fingerprint',
          pixelSize: const GridSize(width: 16, height: 12),
          opaqueBounds: BorderPixelRect(x: 10, y: 2, width: 7, height: 8),
          defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
          occupancyMaskRle: 'opaque',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BorderVisualFrameSnapshot', () {
    test('stores only effective frame rendering data', () {
      final frame = _frame();

      expect(frame.relativeAssetPath, 'assets/borders/snapshots/frame-a.png');
      expect(frame.sourceRectPx,
          BorderPixelRect(x: 0, y: 0, width: 16, height: 12));
      expect(frame.durationMs, 100);
      expect(frame.transparentColorArgb, 0x00ff00);
    });

    test('requires an already-effective positive duration', () {
      for (final duration in <int>[0, -1]) {
        expect(
          () => _frame(durationMs: duration),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects unsafe or non-canonical project-relative paths', () {
      for (final path in <String>[
        '',
        '/absolute.png',
        '../escape.png',
        'assets/../escape.png',
        './assets/frame.png',
        'assets//frame.png',
        'assets/frame.png',
        'frame.png',
        r'C:\absolute.png',
        r'assets\frame.png',
      ]) {
        expect(
          () => _frame(relativeAssetPath: path),
          throwsA(isA<ValidationException>()),
          reason: path,
        );
      }
    });

    test('requires non-negative source coordinates and a 32-bit ARGB key', () {
      expect(
        () => _frame(
          sourceRectPx: BorderPixelRect(x: -1, y: 0, width: 16, height: 12),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(_frame(transparentColorArgb: 0xffffffff).transparentColorArgb,
          0xffffffff);
      for (final color in <int>[-1, 0x100000000]) {
        expect(
          () => _frame(transparentColorArgb: color),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });

  group('BorderVisualSnapshot', () {
    test('requires exact content-addressed identity and ordered frames', () {
      final frames = <BorderVisualFrameSnapshot>[
        _frame(),
        _frame(
          relativeAssetPath: 'assets/borders/snapshots/frame-b.png',
          durationMs: 120,
        ),
      ];
      final snapshot = _snapshot(frames: frames);

      frames.clear();

      expect(snapshot.id, 'border-snapshot-sha256:$_fingerprint');
      expect(snapshot.contentFingerprint, _fingerprint);
      expect(snapshot.frames, hasLength(2));
      expect(
        () => snapshot.frames.add(_frame()),
        throwsUnsupportedError,
      );
      expect(snapshot, _snapshot());
      expect(
        snapshot,
        isNot(
          _snapshot(frames: snapshot.frames.reversed.toList()),
        ),
      );
    });

    test('rejects malformed or mismatched snapshot identities', () {
      for (final createInvalid in <BorderVisualSnapshot Function()>[
        () => BorderVisualSnapshot(
              id: '',
              contentFingerprint: '',
              frames: <BorderVisualFrameSnapshot>[_frame()],
            ),
        () => BorderVisualSnapshot(
              id: 'border-snapshot-sha256:$_uppercaseFingerprint',
              contentFingerprint: _uppercaseFingerprint,
              frames: <BorderVisualFrameSnapshot>[_frame()],
            ),
        () => BorderVisualSnapshot(
              id: 'border-snapshot-sha256:$_shortFingerprint',
              contentFingerprint: _shortFingerprint,
              frames: <BorderVisualFrameSnapshot>[_frame()],
            ),
        () => BorderVisualSnapshot(
              id: 'border-snapshot-sha256:$_otherFingerprint',
              contentFingerprint: _fingerprint,
              frames: <BorderVisualFrameSnapshot>[_frame()],
            ),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });

    test('rejects empty and dimensionally inconsistent frame lists', () {
      expect(
        () => _snapshot(frames: const <BorderVisualFrameSnapshot>[]),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _snapshot(
          frames: <BorderVisualFrameSnapshot>[
            _frame(),
            _frame(
              sourceRectPx: BorderPixelRect(
                x: 0,
                y: 0,
                width: 8,
                height: 12,
              ),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

const String _fingerprint =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _uppercaseFingerprint =
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
const String _shortFingerprint =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _otherFingerprint =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

BorderPrimitiveAssetMetrics _metrics() {
  return BorderPrimitiveAssetMetrics(
    assetFingerprint: 'source-fingerprint',
    pixelSize: const GridSize(width: 16, height: 12),
    opaqueBounds: BorderPixelRect(x: 1, y: 2, width: 10, height: 8),
    defaultAnchorPx: const BorderPixelPos(x: 5, y: 9),
    occupancyMaskRle: 'not-decoded-by-the-domain-model',
  );
}

BorderVisualFrameSnapshot _frame({
  String relativeAssetPath = 'assets/borders/snapshots/frame-a.png',
  BorderPixelRect? sourceRectPx,
  int durationMs = 100,
  int? transparentColorArgb = 0x00ff00,
}) {
  return BorderVisualFrameSnapshot(
    relativeAssetPath: relativeAssetPath,
    sourceRectPx:
        sourceRectPx ?? BorderPixelRect(x: 0, y: 0, width: 16, height: 12),
    durationMs: durationMs,
    transparentColorArgb: transparentColorArgb,
  );
}

BorderVisualSnapshot _snapshot({
  List<BorderVisualFrameSnapshot>? frames,
}) {
  return BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$_fingerprint',
    contentFingerprint: _fingerprint,
    frames: frames ??
        <BorderVisualFrameSnapshot>[
          _frame(),
          _frame(
            relativeAssetPath: 'assets/borders/snapshots/frame-b.png',
            durationMs: 120,
          ),
        ],
  );
}
