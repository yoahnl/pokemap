import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StoneChainAxis', () {
    test('rejects axes that are not unit-cardinal', () {
      for (final components in const <(int, int)>[
        (0, 0),
        (1, 1),
        (2, 0),
      ]) {
        expect(
          () => StoneChainAxis(dx: components.$1, dy: components.$2),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'StoneChainAxis must be unit-cardinal',
            ),
          ),
          reason: '$components',
        );
      }
    });
  });

  group('stone-chain expansion budgets', () {
    test('publishes stable limits sized for small stone assets', () {
      expect(stoneChainMaximumOpaquePixelsPerMask, 65536);
      expect(stoneChainMaximumRowOpaquePixels, 262144);
      expect(stoneChainMaximumRowSamples, 4096);
    });

    test('rejects a valid full 8192 square mask before expanding it', () {
      final huge = _uniformPlacedMask(
        width: 8192,
        height: 8192,
        occupancyMaskRle: 'border-rle-v1:67108864:1:67108864',
      );

      expect(
        () => measureStoneChainContact(
          first: huge,
          second: _mask(const <String>['#']),
          tangent: _east,
          normal: _south,
        ),
        _validationMessage(
          'Stone-chain mask opaque pixel count must not exceed 65536',
        ),
      );
    });

    test('rejects cumulative row occupancy before decoding any mask', () {
      final full = _uniformPlacedMask(
        width: 256,
        height: 256,
        occupancyMaskRle: 'border-rle-v1:65536:1:65536',
      );

      expect(
        () => measureStoneChainRowContinuity(
          samples: <StoneChainRowSample>[
            for (var index = 0; index < 5; index += 1)
              _sample(
                strokeId: 'over-budget',
                slotKey: 'slot-$index',
                pathDistancePx: index,
                mask: full,
              ),
          ],
          tangent: _east,
          normal: _south,
        ),
        _validationMessage(
          'Stone-chain row opaque pixel count must not exceed 262144',
        ),
      );
    });

    test('rejects too many samples before validating their masks', () {
      final invalid = _uniformPlacedMask(
        width: 1,
        height: 1,
        occupancyMaskRle: 'not-rle',
      );

      expect(
        () => measureStoneChainRowContinuity(
          samples: <StoneChainRowSample>[
            for (var index = 0; index < 4097; index += 1)
              _sample(
                strokeId: 'too-many',
                slotKey: 'slot-$index',
                pathDistancePx: index,
                mask: invalid,
              ),
          ],
          tangent: _east,
          normal: _south,
        ),
        _validationMessage(
          'Stone-chain row sample count must not exceed 4096',
        ),
      );
    });

    test('accepts the exact per-mask opaque-pixel limit', () {
      final full = _uniformPlacedMask(
        width: 256,
        height: 256,
        occupancyMaskRle: 'border-rle-v1:65536:1:65536',
      );

      final result = measureStoneChainContact(
        first: full,
        second: full,
        tangent: _east,
        normal: _south,
      );

      expect(result.tangentOverlapPx, 256);
      expect(result.normalOverlapPx, 256);
      expect(result.opaqueIntersectionPixels, 65536);
    });
  });

  group('measureStoneChainContact', () {
    test('measures projected gap overlap and opaque interlock separately', () {
      final result = measureStoneChainContact(
        first: _mask(const <String>['########', '########']),
        second: _mask(
          const <String>['########', '########'],
          topLeftX: 2,
        ),
        tangent: _east,
        normal: _south,
      );

      expect(result.projectedGapPx, 0);
      expect(result.tangentOverlapPx, 6);
      expect(result.normalOverlapPx, 2);
      expect(result.opaqueIntersectionPixels, 12);
    });

    test('counts genuinely empty projected columns as a gap', () {
      final result = measureStoneChainContact(
        first: _mask(const <String>['###', '###']),
        second: _mask(const <String>['##', '##'], topLeftX: 4),
        tangent: _east,
        normal: _south,
      );

      expect(result.projectedGapPx, 1);
      expect(result.tangentOverlapPx, 0);
      expect(result.normalOverlapPx, 2);
      expect(result.opaqueIntersectionPixels, 0);
    });

    test('reports zero gap for adjacent bounds without opaque intersection',
        () {
      final result = measureStoneChainContact(
        first: _mask(const <String>['##', '##']),
        second: _mask(const <String>['##', '##'], topLeftX: 2),
        tangent: _east,
        normal: _south,
      );

      expect(result.projectedGapPx, 0);
      expect(result.tangentOverlapPx, 0);
      expect(result.normalOverlapPx, 2);
      expect(result.opaqueIntersectionPixels, 0);
    });

    test('applies a clockwise quarter turn before world translation', () {
      final rotated = _mask(
        const <String>['##.', '..#'],
        topLeftX: 10,
        topLeftY: -2,
        quarterTurns: 1,
      );
      final expectedWorldMask = _mask(
        const <String>['.#', '.#', '#.'],
        topLeftX: 10,
        topLeftY: -2,
      );

      final result = measureStoneChainContact(
        first: rotated,
        second: expectedWorldMask,
        tangent: _east,
        normal: _south,
      );

      expect(result.projectedGapPx, 0);
      expect(result.tangentOverlapPx, 2);
      expect(result.normalOverlapPx, 3);
      expect(result.opaqueIntersectionPixels, 3);
    });

    test('applies source flip before clockwise rotation', () {
      final transformed = _mask(
        const <String>['##.', '..#'],
        topLeftX: -4,
        topLeftY: 7,
        quarterTurns: 1,
        flipX: true,
      );
      final expectedWorldMask = _mask(
        const <String>['#.', '.#', '.#'],
        topLeftX: -4,
        topLeftY: 7,
      );

      final result = measureStoneChainContact(
        first: transformed,
        second: expectedWorldMask,
        tangent: _east,
        normal: _south,
      );

      expect(result.tangentOverlapPx, 2);
      expect(result.normalOverlapPx, 3);
      expect(result.opaqueIntersectionPixels, 3);
    });

    test('is invariant when the normal axis is inverted', () {
      final first = _mask(const <String>['####', '.##.']);
      final second = _mask(
        const <String>['.###', '###.'],
        topLeftX: 1,
      );

      final forward = measureStoneChainContact(
        first: first,
        second: second,
        tangent: _east,
        normal: _south,
      );
      final inverted = measureStoneChainContact(
        first: first,
        second: second,
        tangent: _east,
        normal: _north,
      );

      expect(inverted.projectedGapPx, forward.projectedGapPx);
      expect(inverted.tangentOverlapPx, forward.tangentOverlapPx);
      expect(inverted.normalOverlapPx, forward.normalOverlapPx);
      expect(
        inverted.opaqueIntersectionPixels,
        forward.opaqueIntersectionPixels,
      );
    });

    test('measures two identical sparse masks exactly', () {
      final mask = _mask(const <String>['#.#', '.#.', '#.#']);

      final result = measureStoneChainContact(
        first: mask,
        second: mask,
        tangent: _east,
        normal: _south,
      );

      expect(result.projectedGapPx, 0);
      expect(result.tangentOverlapPx, 3);
      expect(result.normalOverlapPx, 3);
      expect(result.opaqueIntersectionPixels, 5);
    });

    test('rejects identical or opposite axes as non-perpendicular', () {
      final mask = _mask(const <String>['#']);

      for (final normal in <StoneChainAxis>[_east, _west]) {
        expect(
          () => measureStoneChainContact(
            first: mask,
            second: mask,
            tangent: _east,
            normal: normal,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Stone-chain tangent and normal axes must be perpendicular',
            ),
          ),
        );
      }
    });
  });

  group('measureStoneChainRowContinuity', () {
    test('defines empty and single-sample rows without neighbor statistics',
        () {
      expect(
        measureStoneChainRowContinuity(
          samples: const <StoneChainRowSample>[],
          tangent: _east,
          normal: _south,
        ),
        _continuity(
          maximumGapPx: 0,
          minimumOverlapPx: 0,
          medianOverlapPx: 0,
          maximumOverlapPx: 0,
          connectedComponentCount: 0,
        ),
      );

      expect(
        measureStoneChainRowContinuity(
          samples: <StoneChainRowSample>[
            _sample(
              strokeId: 'open',
              slotKey: 'only',
              pathDistancePx: 0,
              mask: _mask(const <String>['##', '##']),
            ),
          ],
          tangent: _east,
          normal: _south,
        ),
        _continuity(
          maximumGapPx: 0,
          minimumOverlapPx: 0,
          medianOverlapPx: 0,
          maximumOverlapPx: 0,
          connectedComponentCount: 1,
        ),
      );
    });

    test('sorts neighbors and uses a floor integer median', () {
      final result = measureStoneChainRowContinuity(
        samples: <StoneChainRowSample>[
          _sample(
            strokeId: 'coast',
            slotKey: 'c',
            pathDistancePx: 20,
            mask: _mask(const <String>['####', '####'], topLeftX: 7),
          ),
          _sample(
            strokeId: 'coast',
            slotKey: 'a',
            pathDistancePx: 0,
            mask: _mask(const <String>['####', '####']),
          ),
          _sample(
            strokeId: 'coast',
            slotKey: 'b',
            pathDistancePx: 10,
            mask: _mask(const <String>['####', '####'], topLeftX: 2),
          ),
        ],
        tangent: _east,
        normal: _south,
      );

      expect(
        result,
        _continuity(
          maximumGapPx: 1,
          minimumOverlapPx: 0,
          medianOverlapPx: 1,
          maximumOverlapPx: 2,
          connectedComponentCount: 2,
        ),
      );
    });

    test('measures a closed seam exactly once', () {
      final result = measureStoneChainRowContinuity(
        samples: <StoneChainRowSample>[
          _sample(
            strokeId: 'loop',
            slotKey: 'a',
            pathDistancePx: 0,
            closed: true,
            mask: _mask(const <String>['######']),
          ),
          _sample(
            strokeId: 'loop',
            slotKey: 'b',
            pathDistancePx: 10,
            closed: true,
            mask: _mask(const <String>['######'], topLeftX: 4),
          ),
          _sample(
            strokeId: 'loop',
            slotKey: 'c',
            pathDistancePx: 20,
            closed: true,
            mask: _mask(const <String>['######'], topLeftX: 8),
          ),
        ],
        tangent: _east,
        normal: _south,
      );

      expect(result.maximumGapPx, 2, reason: 'the closing seam is included');
      expect(result.minimumOverlapPx, 0);
      expect(
        result.medianOverlapPx,
        2,
        reason: 'the zero-overlap seam is included exactly once',
      );
      expect(result.maximumOverlapPx, 2);
      expect(result.connectedComponentCount, 1);
    });

    test('counts detached opaque components with 4-connectivity', () {
      final result = measureStoneChainRowContinuity(
        samples: <StoneChainRowSample>[
          _sample(
            strokeId: 'detached',
            slotKey: 'only',
            pathDistancePx: 0,
            closed: true,
            mask: _mask(const <String>['#.', '.#']),
          ),
        ],
        tangent: _east,
        normal: _south,
      );

      expect(result.maximumGapPx, 0);
      expect(result.minimumOverlapPx, 0);
      expect(result.medianOverlapPx, 0);
      expect(result.maximumOverlapPx, 0);
      expect(result.connectedComponentCount, 2);
    });

    test('aggregates neighbor metrics globally without crossing strokes', () {
      final result = measureStoneChainRowContinuity(
        samples: <StoneChainRowSample>[
          _sample(
            strokeId: 'a',
            slotKey: 'a-0',
            pathDistancePx: 0,
            mask: _mask(const <String>['##']),
          ),
          _sample(
            strokeId: 'b',
            slotKey: 'b-0',
            pathDistancePx: 0,
            mask: _mask(const <String>['####'], topLeftX: 10),
          ),
          _sample(
            strokeId: 'a',
            slotKey: 'a-1',
            pathDistancePx: 10,
            mask: _mask(const <String>['##'], topLeftX: 3),
          ),
          _sample(
            strokeId: 'b',
            slotKey: 'b-1',
            pathDistancePx: 10,
            mask: _mask(const <String>['####'], topLeftX: 12),
          ),
        ],
        tangent: _east,
        normal: _south,
      );

      expect(
        result,
        _continuity(
          maximumGapPx: 1,
          minimumOverlapPx: 0,
          medianOverlapPx: 1,
          maximumOverlapPx: 2,
          connectedComponentCount: 3,
        ),
      );
    });

    test('rejects mixed open and closed samples in one stroke', () {
      expect(
        () => measureStoneChainRowContinuity(
          samples: <StoneChainRowSample>[
            _sample(
              strokeId: 'mixed',
              slotKey: 'a',
              pathDistancePx: 0,
              mask: _mask(const <String>['#']),
            ),
            _sample(
              strokeId: 'mixed',
              slotKey: 'b',
              pathDistancePx: 1,
              closed: true,
              mask: _mask(const <String>['#'], topLeftX: 1),
            ),
          ],
          tangent: _east,
          normal: _south,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Stone-chain stroke "mixed" must not mix open and closed samples',
          ),
        ),
      );
    });

    test('rejects duplicate path distances and slot keys per stroke', () {
      final mask = _mask(const <String>['#']);

      expect(
        () => measureStoneChainRowContinuity(
          samples: <StoneChainRowSample>[
            _sample(
              strokeId: 'duplicate-distance',
              slotKey: 'a',
              pathDistancePx: 4,
              mask: mask,
            ),
            _sample(
              strokeId: 'duplicate-distance',
              slotKey: 'b',
              pathDistancePx: 4,
              mask: mask,
            ),
          ],
          tangent: _east,
          normal: _south,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Stone-chain stroke "duplicate-distance" has duplicate pathDistancePx',
          ),
        ),
      );

      expect(
        () => measureStoneChainRowContinuity(
          samples: <StoneChainRowSample>[
            _sample(
              strokeId: 'duplicate-slot',
              slotKey: 'same',
              pathDistancePx: 0,
              mask: mask,
            ),
            _sample(
              strokeId: 'duplicate-slot',
              slotKey: 'same',
              pathDistancePx: 1,
              mask: mask,
            ),
          ],
          tangent: _east,
          normal: _south,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Stone-chain stroke "duplicate-slot" has duplicate slotKey',
          ),
        ),
      );
    });
  });
}

final StoneChainAxis _east = StoneChainAxis(dx: 1, dy: 0);
final StoneChainAxis _south = StoneChainAxis(dx: 0, dy: 1);
final StoneChainAxis _west = StoneChainAxis(dx: -1, dy: 0);
final StoneChainAxis _north = StoneChainAxis(dx: 0, dy: -1);

StoneChainPlacedMask _mask(
  List<String> rows, {
  int topLeftX = 0,
  int topLeftY = 0,
  int quarterTurns = 0,
  bool flipX = false,
}) {
  final height = rows.length;
  final width = rows.singleOrNull?.length ?? rows.first.length;
  if (rows.any((row) => row.length != width)) {
    throw ArgumentError('Synthetic mask rows must have one width');
  }
  final cells = <bool>[
    for (final row in rows)
      for (final pixel in row.codeUnits) pixel == 0x23,
  ];
  final occupiedX = <int>[];
  final occupiedY = <int>[];
  for (var index = 0; index < cells.length; index += 1) {
    if (!cells[index]) continue;
    occupiedX.add(index % width);
    occupiedY.add(index ~/ width);
  }
  final left = occupiedX.reduce((left, right) => left < right ? left : right);
  final right = occupiedX.reduce((left, right) => left > right ? left : right);
  final top = occupiedY.reduce((left, right) => left < right ? left : right);
  final bottom = occupiedY.reduce((left, right) => left > right ? left : right);

  return StoneChainPlacedMask(
    metrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'synthetic:${rows.join('/')}',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: BorderPixelRect(
        x: left,
        y: top,
        width: right - left + 1,
        height: bottom - top + 1,
      ),
      defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
      occupancyMaskRle: encodeBorderRleMask(cells),
    ),
    transform: BorderSpriteTransform(
      quarterTurns: quarterTurns,
      flipX: flipX,
    ),
    topLeftWorldPx: BorderPixelPos(x: topLeftX, y: topLeftY),
  );
}

StoneChainPlacedMask _uniformPlacedMask({
  required int width,
  required int height,
  required String occupancyMaskRle,
}) =>
    StoneChainPlacedMask(
      metrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'synthetic:$width:$height',
        pixelSize: GridSize(width: width, height: height),
        opaqueBounds: BorderPixelRect(
          x: 0,
          y: 0,
          width: width,
          height: height,
        ),
        defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: occupancyMaskRle,
      ),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
    );

StoneChainRowSample _sample({
  required String strokeId,
  required String slotKey,
  required int pathDistancePx,
  required StoneChainPlacedMask mask,
  bool closed = false,
}) =>
    StoneChainRowSample(
      strokeId: strokeId,
      slotKey: slotKey,
      pathDistancePx: pathDistancePx,
      closed: closed,
      mask: mask,
    );

Matcher _continuity({
  required int maximumGapPx,
  required int minimumOverlapPx,
  required int medianOverlapPx,
  required int maximumOverlapPx,
  required int connectedComponentCount,
}) =>
    isA<StoneChainRowContinuity>()
        .having((value) => value.maximumGapPx, 'maximumGapPx', maximumGapPx)
        .having(
          (value) => value.minimumOverlapPx,
          'minimumOverlapPx',
          minimumOverlapPx,
        )
        .having(
          (value) => value.medianOverlapPx,
          'medianOverlapPx',
          medianOverlapPx,
        )
        .having(
          (value) => value.maximumOverlapPx,
          'maximumOverlapPx',
          maximumOverlapPx,
        )
        .having(
          (value) => value.connectedComponentCount,
          'connectedComponentCount',
          connectedComponentCount,
        );

Matcher _validationMessage(String message) => throwsA(
      isA<ValidationException>().having(
        (error) => error.message,
        'message',
        message,
      ),
    );
