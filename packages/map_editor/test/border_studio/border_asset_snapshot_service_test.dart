import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';

void main() {
  group('BorderAssetSnapshotService', () {
    const service = BorderAssetSnapshotService();

    test('deduplicates identical pixels independently from the source path',
        () {
      final pixels = _png(<int>[255, 0, 0, 255, 0, 0, 0, 0]);

      final first = service.prepare(
        BorderAssetSnapshotRequest(
          sourceElementId: 'first-element',
          frames: <BorderAssetSnapshotSourceFrame>[
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/tilesets/first.png',
              encodedImageBytes: pixels,
            ),
          ],
        ),
      );
      final second = service.prepare(
        BorderAssetSnapshotRequest(
          sourceElementId: 'second-element',
          frames: <BorderAssetSnapshotSourceFrame>[
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/imported/second.png',
              encodedImageBytes: pixels,
            ),
          ],
        ),
      );

      expect(first.snapshot, second.snapshot);
      expect(first.files, second.files);
      expect(first.sourceElementId, 'first-element');
      expect(second.sourceElementId, 'second-element');
      expect(
        first.metrics.assetFingerprint,
        isNot(second.metrics.assetFingerprint),
      );
      expect(
        first.snapshot.id,
        'border-snapshot-sha256:${first.snapshot.contentFingerprint}',
      );
      expect(
        first.snapshot.frames.single.relativeAssetPath,
        startsWith(
          'assets/borders/snapshots/${first.snapshot.contentFingerprint}/',
        ),
      );
      expect(
        first.snapshot.frames.single.relativeAssetPath.startsWith('/'),
        isFalse,
      );
    });

    test('deduplicates identical RGBA pixels across different PNG encodings',
        () {
      const rgba = <int>[255, 0, 0, 255, 0, 0, 0, 0];
      final fastPng = _png(rgba, level: 0);
      final compressedPng = _png(rgba, level: 9);
      expect(fastPng, isNot(compressedPng));

      BorderAssetSnapshotPreparation prepare(
        String sourceElementId,
        Uint8List bytes,
      ) =>
          service.prepare(
            BorderAssetSnapshotRequest(
              sourceElementId: sourceElementId,
              frames: <BorderAssetSnapshotSourceFrame>[
                BorderAssetSnapshotSourceFrame(
                  sourceProjectRelativePath:
                      'assets/tilesets/$sourceElementId.png',
                  encodedImageBytes: bytes,
                ),
              ],
            ),
          );

      final first = prepare('encoded-fast', fastPng);
      final second = prepare('encoded-compressed', compressedPng);

      expect(first.snapshot, second.snapshot);
      expect(first.files, second.files);
      expect(
        first.metrics.assetFingerprint,
        isNot(second.metrics.assetFingerprint),
      );
    });

    test('freezes source bytes and exposes defensive file payload copies', () {
      final mutableSource = _png(<int>[1, 2, 3, 255, 4, 5, 6, 0]);
      final request = BorderAssetSnapshotRequest(
        sourceElementId: 'mutable-element',
        frames: <BorderAssetSnapshotSourceFrame>[
          BorderAssetSnapshotSourceFrame(
            sourceProjectRelativePath: 'assets/tilesets/source.png',
            encodedImageBytes: mutableSource,
          ),
        ],
      );

      final prepared = service.prepare(request);
      final frozenFingerprint = prepared.snapshot.contentFingerprint;
      final frozenBytes = prepared.files.single.bytes;
      mutableSource.fillRange(0, mutableSource.length, 0);
      frozenBytes.fillRange(0, frozenBytes.length, 0);

      expect(service.prepare(request).snapshot.contentFingerprint,
          frozenFingerprint);
      expect(prepared.files.single.bytes, isNot(everyElement(0)));
    });

    test('persists normalized animation metadata and aggregate alpha metrics',
        () {
      final first = _png(<int>[
        10,
        20,
        30,
        255,
        40,
        50,
        60,
        255,
      ]);
      final second = _png(<int>[
        10,
        20,
        30,
        0,
        40,
        50,
        60,
        255,
      ]);

      final prepared = service.prepare(
        BorderAssetSnapshotRequest(
          sourceElementId: 'animated-element',
          frames: <BorderAssetSnapshotSourceFrame>[
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/tilesets/a.png',
              encodedImageBytes: first,
              durationMs: null,
            ),
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/tilesets/b.png',
              encodedImageBytes: second,
              durationMs: 75,
              transparentColorArgb: 0xffff00ff,
            ),
          ],
        ),
      );

      expect(prepared.snapshot.frames.map((frame) => frame.durationMs),
          <int>[100, 75]);
      expect(
        prepared.snapshot.frames.map((frame) => frame.sourceRectPx),
        <BorderPixelRect>[
          BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
          BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
        ],
      );
      expect(prepared.metrics.pixelSize, const GridSize(width: 2, height: 1));
      expect(
        prepared.metrics.opaqueBounds,
        BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
      );
      expect(prepared.metrics.occupancyMaskRle, 'border-rle-v1:2:0:1,1');
      expect(prepared.files, hasLength(2));
      expect(
        prepared.files.map((file) => file.relativePath).toSet(),
        hasLength(2),
      );
    });

    test('snapshot identity changes with effective timing and frame order', () {
      final red = _png(<int>[255, 0, 0, 255, 0, 0, 0, 0]);
      final blue = _png(<int>[0, 0, 255, 255, 0, 0, 0, 0]);

      BorderAssetSnapshotPreparation prepare({
        required List<Uint8List> frames,
        required int duration,
      }) =>
          service.prepare(
            BorderAssetSnapshotRequest(
              sourceElementId: 'ordered-element',
              frames: <BorderAssetSnapshotSourceFrame>[
                for (var index = 0; index < frames.length; index += 1)
                  BorderAssetSnapshotSourceFrame(
                    sourceProjectRelativePath: 'assets/source/$index.png',
                    encodedImageBytes: frames[index],
                    durationMs: duration,
                  ),
              ],
            ),
          );

      final baseline = prepare(frames: <Uint8List>[red, blue], duration: 100);
      expect(
        prepare(frames: <Uint8List>[blue, red], duration: 100)
            .snapshot
            .contentFingerprint,
        isNot(baseline.snapshot.contentFingerprint),
      );
      expect(
        prepare(frames: <Uint8List>[red, blue], duration: 101)
            .snapshot
            .contentFingerprint,
        isNot(baseline.snapshot.contentFingerprint),
      );
    });

    test('keeps the canonical snapshot hash and paths stable', () {
      final prepared = service.prepare(
        BorderAssetSnapshotRequest(
          sourceElementId: 'golden-element',
          frames: <BorderAssetSnapshotSourceFrame>[
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/source/golden-a.png',
              encodedImageBytes: _png(<int>[
                1,
                2,
                3,
                255,
                4,
                5,
                6,
                0,
              ]),
              durationMs: 100,
            ),
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/source/golden-b.png',
              encodedImageBytes: _png(<int>[
                7,
                8,
                9,
                255,
                10,
                11,
                12,
                255,
              ]),
              durationMs: 75,
              transparentColorArgb: 0xff0a0b0c,
            ),
          ],
        ),
      );

      const fingerprint =
          'b6f337043610f81f17e2f9c78cdbfcb7945fec17fdb23aa7f11058f524d4e484';
      expect(prepared.snapshot.contentFingerprint, fingerprint);
      expect(
        prepared.snapshot.frames.map((frame) => frame.relativeAssetPath),
        <String>[
          'assets/borders/snapshots/$fingerprint/frame_0000.png',
          'assets/borders/snapshots/$fingerprint/frame_0001.png',
        ],
      );
    });

    test('rejects a fully transparent source before metrics publication', () {
      expect(
        () => service.prepare(
          BorderAssetSnapshotRequest(
            sourceElementId: 'empty-element',
            frames: <BorderAssetSnapshotSourceFrame>[
              BorderAssetSnapshotSourceFrame(
                sourceProjectRelativePath: 'assets/empty.png',
                encodedImageBytes: _png(<int>[0, 0, 0, 0, 0, 0, 0, 0]),
              ),
            ],
          ),
        ),
        throwsA(
          isA<BorderAssetSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderAssetSnapshotErrorCode.fullyTransparent,
          ),
        ),
      );
    });
  });
}

Uint8List _png(List<int> rgba, {int? level}) {
  assert(rgba.length == 8);
  final image = img.Image(width: 2, height: 1, numChannels: 4);
  for (var x = 0; x < 2; x += 1) {
    final offset = x * 4;
    image.setPixelRgba(
      x,
      0,
      rgba[offset],
      rgba[offset + 1],
      rgba[offset + 2],
      rgba[offset + 3],
    );
  }
  return Uint8List.fromList(
    level == null ? img.encodePng(image) : img.encodePng(image, level: level),
  );
}
