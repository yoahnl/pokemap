import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('matches the immutable snapshot publication golden', () {
    final fingerprint = computeBorderSnapshotContentFingerprint(
      frames: <BorderSnapshotContentFrame>[
        BorderSnapshotContentFrame(
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
          durationMs: 100,
          rgbaBytes: Uint8List.fromList(<int>[
            1,
            2,
            3,
            255,
            4,
            5,
            6,
            0,
          ]),
        ),
        BorderSnapshotContentFrame(
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
          durationMs: 75,
          transparentColorArgb: 0xff0a0b0c,
          rgbaBytes: Uint8List.fromList(<int>[
            7,
            8,
            9,
            255,
            10,
            11,
            12,
            0,
          ]),
        ),
      ],
    );

    expect(
      fingerprint,
      'b6f337043610f81f17e2f9c78cdbfcb7945fec17fdb23aa7f11058f524d4e484',
    );
  });

  test('hashes decoded RGBA and metadata rather than encoded file bytes', () {
    BorderSnapshotContentFrame frame({required int durationMs}) =>
        BorderSnapshotContentFrame(
          sourceRectPx: BorderPixelRect(x: 3, y: 4, width: 1, height: 1),
          durationMs: durationMs,
          rgbaBytes: Uint8List.fromList(<int>[10, 20, 30, 255]),
        );

    final baseline = computeBorderSnapshotContentFingerprint(
      frames: <BorderSnapshotContentFrame>[frame(durationMs: 100)],
    );
    final sameDecodedContent = computeBorderSnapshotContentFingerprint(
      frames: <BorderSnapshotContentFrame>[frame(durationMs: 100)],
    );
    final changedMetadata = computeBorderSnapshotContentFingerprint(
      frames: <BorderSnapshotContentFrame>[frame(durationMs: 101)],
    );

    expect(sameDecodedContent, baseline);
    expect(changedMetadata, isNot(baseline));
  });
}
