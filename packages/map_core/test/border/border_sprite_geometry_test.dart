import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveBorderSpriteGeometry', () {
    final cases = <_ExpectedGeometry>[
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
        size: const GridSize(width: 5, height: 4),
        anchor: const BorderPixelPos(x: 1, y: 2),
        opaque: BorderPixelRect(x: 0, y: 0, width: 3, height: 2),
        topLeft: const BorderPixelPos(x: 99, y: 198),
        worldOpaque: BorderPixelRect(x: 99, y: 198, width: 3, height: 2),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 1, flipX: false),
        size: const GridSize(width: 4, height: 5),
        anchor: const BorderPixelPos(x: 1, y: 1),
        opaque: BorderPixelRect(x: 2, y: 0, width: 2, height: 3),
        topLeft: const BorderPixelPos(x: 99, y: 199),
        worldOpaque: BorderPixelRect(x: 101, y: 199, width: 2, height: 3),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 2, flipX: false),
        size: const GridSize(width: 5, height: 4),
        anchor: const BorderPixelPos(x: 3, y: 1),
        opaque: BorderPixelRect(x: 2, y: 2, width: 3, height: 2),
        topLeft: const BorderPixelPos(x: 97, y: 199),
        worldOpaque: BorderPixelRect(x: 99, y: 201, width: 3, height: 2),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 3, flipX: false),
        size: const GridSize(width: 4, height: 5),
        anchor: const BorderPixelPos(x: 2, y: 3),
        opaque: BorderPixelRect(x: 0, y: 2, width: 2, height: 3),
        topLeft: const BorderPixelPos(x: 98, y: 197),
        worldOpaque: BorderPixelRect(x: 98, y: 199, width: 2, height: 3),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 0, flipX: true),
        size: const GridSize(width: 5, height: 4),
        anchor: const BorderPixelPos(x: 3, y: 2),
        opaque: BorderPixelRect(x: 2, y: 0, width: 3, height: 2),
        topLeft: const BorderPixelPos(x: 97, y: 198),
        worldOpaque: BorderPixelRect(x: 99, y: 198, width: 3, height: 2),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 1, flipX: true),
        size: const GridSize(width: 4, height: 5),
        anchor: const BorderPixelPos(x: 1, y: 3),
        opaque: BorderPixelRect(x: 2, y: 2, width: 2, height: 3),
        topLeft: const BorderPixelPos(x: 99, y: 197),
        worldOpaque: BorderPixelRect(x: 101, y: 199, width: 2, height: 3),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 2, flipX: true),
        size: const GridSize(width: 5, height: 4),
        anchor: const BorderPixelPos(x: 1, y: 1),
        opaque: BorderPixelRect(x: 0, y: 2, width: 3, height: 2),
        topLeft: const BorderPixelPos(x: 99, y: 199),
        worldOpaque: BorderPixelRect(x: 99, y: 201, width: 3, height: 2),
      ),
      _ExpectedGeometry(
        transform: BorderSpriteTransform(quarterTurns: 3, flipX: true),
        size: const GridSize(width: 4, height: 5),
        anchor: const BorderPixelPos(x: 2, y: 1),
        opaque: BorderPixelRect(x: 0, y: 0, width: 2, height: 3),
        topLeft: const BorderPixelPos(x: 98, y: 199),
        worldOpaque: BorderPixelRect(x: 98, y: 199, width: 2, height: 3),
      ),
    ];

    for (final expected in cases) {
      test(
        'applies flip first then q${expected.transform.quarterTurns} '
        '(flipX=${expected.transform.flipX})',
        () {
          final result = resolveBorderSpriteGeometry(
            metrics: _metrics(
              width: 5,
              height: 4,
              opaqueBounds: BorderPixelRect(
                x: 0,
                y: 0,
                width: 3,
                height: 2,
              ),
            ),
            sourceAnchorPx: const BorderPixelPos(x: 1, y: 2),
            transform: expected.transform,
            targetAnchorWorldPx: const BorderPixelPos(x: 100, y: 200),
          );

          expect(result.transformedPixelSize, expected.size);
          expect(result.transformedAnchorPx, expected.anchor);
          expect(result.transformedOpaqueBoundsPx, expected.opaque);
          expect(result.topLeftWorldPx, expected.topLeft);
          expect(result.opaqueWorldBoundsPx, expected.worldOpaque);
          expect(result.maximumOpaqueExtentPx, 3);
        },
      );
    }

    test('keeps the target anchor exact for even and odd source sizes', () {
      for (final size in const <GridSize>[
        GridSize(width: 4, height: 2),
        GridSize(width: 5, height: 3),
      ]) {
        for (var turns = 0; turns < 4; turns += 1) {
          for (final flipX in const <bool>[false, true]) {
            final result = resolveBorderSpriteGeometry(
              metrics: _metrics(
                width: size.width,
                height: size.height,
                opaqueBounds: BorderPixelRect(
                  x: 0,
                  y: 0,
                  width: size.width,
                  height: size.height,
                ),
              ),
              sourceAnchorPx: BorderPixelPos(
                x: size.width - 1,
                y: size.height - 1,
              ),
              transform: BorderSpriteTransform(
                quarterTurns: turns,
                flipX: flipX,
              ),
              targetAnchorWorldPx: const BorderPixelPos(x: -7, y: 13),
            );

            expect(
              result.topLeftWorldPx.x + result.transformedAnchorPx.x,
              -7,
            );
            expect(
              result.topLeftWorldPx.y + result.transformedAnchorPx.y,
              13,
            );
          }
        }
      }
    });

    test('rejects source anchors outside the source pixel domain', () {
      final metrics = _metrics(
        width: 5,
        height: 4,
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      );

      for (final anchor in const <BorderPixelPos>[
        BorderPixelPos(x: -1, y: 0),
        BorderPixelPos(x: 5, y: 0),
        BorderPixelPos(x: 0, y: 4),
      ]) {
        expect(
          () => resolveBorderSpriteGeometry(
            metrics: metrics,
            sourceAnchorPx: anchor,
            transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
            targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
          ),
          throwsA(isA<ValidationException>()),
          reason: '$anchor',
        );
      }
    });

    test('rejects non-portable input and derived world coordinates', () {
      final max = int.parse('9007199254740991');
      final metrics = _metrics(
        width: 3,
        height: 2,
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 3, height: 2),
      );

      expect(
        () => resolveBorderSpriteGeometry(
          metrics: metrics,
          sourceAnchorPx: const BorderPixelPos(x: 1, y: 0),
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          targetAnchorWorldPx: BorderPixelPos(x: -max, y: 0),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => resolveBorderSpriteGeometry(
          metrics: metrics,
          sourceAnchorPx: const BorderPixelPos(x: 0, y: 0),
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          targetAnchorWorldPx: BorderPixelPos(x: max, y: 0),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => resolveBorderSpriteGeometry(
          metrics: _metrics(
            width: max + 1,
            height: 1,
            opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          ),
          sourceAnchorPx: const BorderPixelPos(x: 0, y: 0),
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Border sprite bounds helpers', () {
    test('uses strict half-open canvas intersection', () {
      const canvas = GridSize(width: 10, height: 8);

      expect(
        borderPixelRectIntersectsCanvas(
          rect: BorderPixelRect(x: -2, y: 1, width: 3, height: 2),
          canvasSizePx: canvas,
        ),
        isTrue,
      );

      final max = int.parse('9007199254740991');
      expect(
        () => borderPixelRectIntersectsCanvas(
          rect: BorderPixelRect(x: max, y: 0, width: 1, height: 1),
          canvasSizePx: canvas,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        borderPixelRectIntersectsCanvas(
          rect: BorderPixelRect(x: -2, y: 1, width: 2, height: 2),
          canvasSizePx: canvas,
        ),
        isFalse,
      );
      expect(
        borderPixelRectIntersectsCanvas(
          rect: BorderPixelRect(x: 10, y: 0, width: 1, height: 1),
          canvasSizePx: canvas,
        ),
        isFalse,
      );
      expect(
        borderPixelRectIntersectsCanvas(
          rect: BorderPixelRect(x: 9, y: 7, width: 1, height: 1),
          canvasSizePx: canvas,
        ),
        isTrue,
      );
    });

    test('finds the largest transformed opaque axis extent', () {
      expect(
        maximumBorderTransformedOpaqueExtentPx(<BorderPrimitiveAssetMetrics>[
          _metrics(
            width: 7,
            height: 4,
            opaqueBounds: BorderPixelRect(x: 1, y: 1, width: 3, height: 2),
          ),
          _metrics(
            width: 2,
            height: 9,
            opaqueBounds: BorderPixelRect(x: 0, y: 1, width: 1, height: 8),
          ),
        ]),
        8,
      );
      expect(
        maximumBorderTransformedOpaqueExtentPx(
          const <BorderPrimitiveAssetMetrics>[],
        ),
        0,
      );

      final max = int.parse('9007199254740991');
      expect(
        () => maximumBorderTransformedOpaqueExtentPx(
          <BorderPrimitiveAssetMetrics>[
            _metrics(
              width: max + 1,
              height: 1,
              opaqueBounds: BorderPixelRect(
                x: 0,
                y: 0,
                width: 1,
                height: 1,
              ),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Border jitter and dirty halo', () {
    test('quantizes jitter with exact integer floor semantics', () {
      expect(
        computeBorderJitterMaxPx(irregularityPermille: 1000, tileSizePx: 17),
        4,
      );
      expect(
        computeBorderJitterMaxPx(irregularityPermille: 999, tileSizePx: 16),
        3,
      );
      expect(
        computeBorderJitterMaxPx(irregularityPermille: 0, tileSizePx: 16),
        0,
      );
    });

    test('sums the approved pixel-only dirty halo terms', () {
      expect(
        computeBorderDirtyHaloRadiusPx(
          depthRows: 2,
          tileSizePx: 16,
          largestTransformedOpaqueExtentPx: 23,
          jitterMaxPx: 4,
          maxOverlapPx: 2,
          gapTolerancePx: 3,
        ),
        64,
      );
    });

    test('rejects invalid parameters and portable-integer overflow', () {
      final max = int.parse('9007199254740991');

      expect(
        () => computeBorderJitterMaxPx(
          irregularityPermille: 1001,
          tileSizePx: 16,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => computeBorderDirtyHaloRadiusPx(
          depthRows: 1,
          tileSizePx: max,
          largestTransformedOpaqueExtentPx: 1,
          jitterMaxPx: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

BorderPrimitiveAssetMetrics _metrics({
  required int width,
  required int height,
  required BorderPixelRect opaqueBounds,
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: opaqueBounds,
      defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
      occupancyMaskRle: '1:1',
    );

final class _ExpectedGeometry {
  const _ExpectedGeometry({
    required this.transform,
    required this.size,
    required this.anchor,
    required this.opaque,
    required this.topLeft,
    required this.worldOpaque,
  });

  final BorderSpriteTransform transform;
  final GridSize size;
  final BorderPixelPos anchor;
  final BorderPixelRect opaque;
  final BorderPixelPos topLeft;
  final BorderPixelRect worldOpaque;
}
