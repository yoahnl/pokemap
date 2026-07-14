import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('assessBorderLoopCoverage', () {
    test('adjacent projected intervals close the target without overlap', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection('a', [_interval(0, 5)]),
          _projection('b', [_interval(5, 10)]),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );

      expect(assessment.coveredIntervals, [_interval(0, 10)]);
      expect(assessment.uncoveredIntervals, isEmpty);
      expect(assessment.longestContiguousGapPx, 0);
      expect(assessment.maximumPairwiseOverlapPx, 0);
      expect(assessment.isWithinTolerance, isTrue);
    });

    test('triple overlap is measured for every pair in the same group', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection('a', [_interval(0, 7)]),
          _projection('b', [_interval(2, 9)]),
          _projection('c', [_interval(4, 10)]),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 4,
      );

      expect(
        assessment.overlaps.map((overlap) => (
              overlap.firstPlacementId,
              overlap.secondPlacementId,
              overlap.lengthPx,
            )),
        [('a', 'b', 5), ('a', 'c', 3), ('b', 'c', 5)],
      );
      expect(assessment.maximumPairwiseOverlapPx, 5);
      expect(assessment.hasExcessiveOverlap, isTrue);
    });

    test('joins one pairwise overlap component across circular zero', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection('a', [_interval(-2, 2)]),
          _projection('b', [_interval(-1, 1)]),
        ],
        gapTolerancePx: 10,
        maxOverlapPx: 1,
      );

      expect(assessment.overlaps.single.lengthPx, 2);
      expect(assessment.maximumPairwiseOverlapPx, 2);
      expect(assessment.hasExcessiveOverlap, isTrue);
    });

    test('sums disjoint components of one pairwise intersection', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 20,
        projections: <BorderStructuralCoverageProjection>[
          _projection('a', [_interval(0, 2), _interval(4, 6)]),
          _projection('b', [_interval(0, 2), _interval(4, 6)]),
        ],
        gapTolerancePx: 20,
        maxOverlapPx: 2,
      );

      expect(assessment.overlaps.single.lengthPx, 4);
      expect(assessment.maximumPairwiseOverlapPx, 4);
      expect(assessment.hasExcessiveOverlap, isTrue);
    });

    test('overlap is ignored across a different draw band or pass', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection('a', [_interval(0, 8)]),
          _projection('b', [_interval(2, 10)], passIndex: 1),
          _projection(
            'c',
            [_interval(1, 9)],
            drawBand: BorderDrawBand.innerFinish,
          ),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );

      expect(assessment.maximumPairwiseOverlapPx, 0);
      expect(assessment.overlaps, isEmpty);
      expect(assessment.longestContiguousGapPx, 0);
    });

    test('separates large numbers of unrelated pass groups before sweeping',
        () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          for (var index = 0; index < 2000; index += 1)
            _projection(
              'placement-${index.toString().padLeft(4, '0')}',
              [_interval(0, 10)],
              passIndex: index,
            ),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );

      expect(assessment.coveredIntervals, [_interval(0, 10)]);
      expect(assessment.overlaps, isEmpty);
    });

    test('joins uncovered components across circular abscissa zero', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection('middle', [_interval(2, 8)]),
        ],
        gapTolerancePx: 3,
        maxOverlapPx: 0,
      );

      expect(
          assessment.uncoveredIntervals, [_interval(0, 2), _interval(8, 10)]);
      expect(assessment.longestContiguousGapPx, 4);
      expect(assessment.hasExcessiveGap, isTrue);
    });

    test('uses the longest gap instead of summing separated small gaps', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection(
            'pieces',
            [_interval(0, 2), _interval(3, 5), _interval(6, 10)],
          ),
        ],
        gapTolerancePx: 1,
        maxOverlapPx: 0,
      );

      expect(assessment.uncoveredIntervals, [_interval(2, 3), _interval(5, 6)]);
      expect(assessment.longestContiguousGapPx, 1);
      expect(assessment.hasExcessiveGap, isFalse);
    });

    test('subtracts canonical exclusions from the target before gaps', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        excludedIntervals: <BorderCoverageInterval>[_interval(4, 6)],
        projections: <BorderStructuralCoverageProjection>[
          _projection('left', [_interval(0, 4)]),
          _projection('right', [_interval(6, 10)]),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );

      expect(assessment.targetIntervals, [_interval(0, 4), _interval(6, 10)]);
      expect(assessment.uncoveredIntervals, isEmpty);
      expect(assessment.isWithinTolerance, isTrue);
    });

    test('normalizes unwrapped placement components around the loop', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 10,
        projections: <BorderStructuralCoverageProjection>[
          _projection('wrapped', [_interval(-2, 3)]),
          _projection('middle', [_interval(3, 8)]),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );

      expect(assessment.coveredIntervals, [_interval(0, 10)]);
      expect(assessment.longestContiguousGapPx, 0);
    });

    test('wrap arithmetic stays exact at the portable integer boundary', () {
      final perimeter = int.parse('9007199254740991');
      final wrappedEnd = int.parse('9007199254740988');
      final assessment = assessBorderLoopCoverage(
        perimeterPx: perimeter,
        projections: <BorderStructuralCoverageProjection>[
          _projection('wrapped', [_interval(-1, wrappedEnd)]),
        ],
        gapTolerancePx: 2,
        maxOverlapPx: 0,
      );

      expect(
        assessment.coveredIntervals,
        [_interval(0, wrappedEnd), _interval(perimeter - 1, perimeter)],
      );
      expect(
        assessment.uncoveredIntervals,
        [_interval(wrappedEnd, perimeter - 1)],
      );
      expect(assessment.longestContiguousGapPx, 2);
    });

    test('rejects duplicate IDs, out-of-domain targets, and nonportable input',
        () {
      expect(
        () => assessBorderLoopCoverage(
          perimeterPx: 10,
          projections: <BorderStructuralCoverageProjection>[
            _projection('same', [_interval(0, 2)]),
            _projection('same', [_interval(2, 4)]),
          ],
          gapTolerancePx: 0,
          maxOverlapPx: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => assessBorderLoopCoverage(
          perimeterPx: 10,
          targetIntervals: <BorderCoverageInterval>[_interval(0, 11)],
          projections: const <BorderStructuralCoverageProjection>[],
          gapTolerancePx: 0,
          maxOverlapPx: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderCoverageInterval(
          startPx: 0,
          endPx: int.parse('9007199254740992'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('returns immutable interval views', () {
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 4,
        projections: <BorderStructuralCoverageProjection>[
          _projection('all', [_interval(0, 4)]),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );

      expect(
        () => assessment.coveredIntervals.add(_interval(0, 1)),
        throwsUnsupportedError,
      );
    });
  });

  group('projectBorderStructuralMaskOntoEdge', () {
    test('matches brute-force destination columns for every V1 transform', () {
      final metrics = _metrics(width: 5, height: 4, cells: _asymmetricMask);
      final edge = _eastEdge();

      for (var turns = 0; turns < 4; turns += 1) {
        for (final flipX in <bool>[false, true]) {
          final actual = projectBorderStructuralMaskOntoEdge(
            metrics: metrics,
            transform: BorderSpriteTransform(
              quarterTurns: turns,
              flipX: flipX,
            ),
            topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
            edge: edge,
          );
          expect(
            actual,
            _bruteDestinationXProjection(
              source: _asymmetricMask,
              width: 5,
              height: 4,
              quarterTurns: turns,
              flipX: flipX,
            ),
            reason: 'quarterTurns=$turns flipX=$flipX',
          );
        }
      }
    });

    test('matches brute-force destination rows for every V1 transform', () {
      final metrics = _metrics(width: 5, height: 4, cells: _asymmetricMask);
      final south = extractCanonicalBorderRegionContours(
        region: BorderRegionGeometry(
          width: 1,
          height: 1,
          cells: const <bool>[true],
        ),
        tileSizePx: const GridSize(width: 100, height: 100),
      ).single.edges[1];

      for (var turns = 0; turns < 4; turns += 1) {
        for (final flipX in <bool>[false, true]) {
          final actual = projectBorderStructuralMaskOntoEdge(
            metrics: metrics,
            transform: BorderSpriteTransform(
              quarterTurns: turns,
              flipX: flipX,
            ),
            topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
            edge: south,
          );
          final expected = <BorderCoverageInterval>[
            for (final interval in _bruteDestinationAxisProjection(
              source: _asymmetricMask,
              width: 5,
              height: 4,
              quarterTurns: turns,
              flipX: flipX,
              destinationX: false,
            ))
              _interval(
                interval.startPx + south.startAbscissaPx,
                interval.endPx + south.startAbscissaPx,
              ),
          ];
          expect(
            actual,
            expected,
            reason: 'quarterTurns=$turns flipX=$flipX',
          );
        }
      }
    });

    test('preserves gaps and reverses westward and northward abscissas', () {
      final metrics = _metrics(
        width: 5,
        height: 1,
        cells: const <bool>[true, true, false, false, true],
      );
      final west = extractCanonicalBorderRegionContours(
        region: BorderRegionGeometry(
          width: 1,
          height: 1,
          cells: const <bool>[true],
        ),
        tileSizePx: const GridSize(width: 100, height: 100),
      ).single.edges[2];

      expect(
        projectBorderStructuralMaskOntoEdge(
          metrics: metrics,
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          topLeftWorldPx: const BorderPixelPos(x: 95, y: 0),
          edge: west,
        ),
        [_interval(200, 201), _interval(203, 205)],
      );

      final northMetrics = _metrics(
        width: 1,
        height: 5,
        cells: const <bool>[true, true, false, false, true],
      );
      final north = extractCanonicalBorderRegionContours(
        region: BorderRegionGeometry(
          width: 1,
          height: 1,
          cells: const <bool>[true],
        ),
        tileSizePx: const GridSize(width: 100, height: 100),
      ).single.edges[3];
      expect(
        projectBorderStructuralMaskOntoEdge(
          metrics: northMetrics,
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          topLeftWorldPx: const BorderPixelPos(x: 0, y: 95),
          edge: north,
        ),
        [_interval(300, 301), _interval(303, 305)],
      );
    });

    test('fails closed when projected arithmetic leaves portable range', () {
      final metrics = _metrics(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      );
      final edge = _eastEdge();

      expect(
        () => projectBorderStructuralMaskOntoEdge(
          metrics: metrics,
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          topLeftWorldPx: BorderPixelPos(
            x: int.parse('9007199254740991'),
            y: 0,
          ),
          edge: edge,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

const List<bool> _asymmetricMask = <bool>[
  true,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  true,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  true,
];

BorderCoverageInterval _interval(int start, int end) =>
    BorderCoverageInterval(startPx: start, endPx: end);

BorderStructuralCoverageProjection _projection(
  String id,
  List<BorderCoverageInterval> intervals, {
  BorderDrawBand drawBand = BorderDrawBand.structure,
  int passIndex = 0,
}) =>
    BorderStructuralCoverageProjection(
      placementId: id,
      drawBand: drawBand,
      passIndex: passIndex,
      intervals: intervals,
    );

BorderPrimitiveAssetMetrics _metrics({
  required int width,
  required int height,
  required List<bool> cells,
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: width, height: height),
      defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
      occupancyMaskRle: encodeBorderRleMask(cells),
    );

BorderRegionContourEdge _eastEdge() => extractCanonicalBorderRegionContours(
      region: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      tileSizePx: const GridSize(width: 100, height: 100),
    ).single.edges.first;

List<BorderCoverageInterval> _bruteDestinationXProjection({
  required List<bool> source,
  required int width,
  required int height,
  required int quarterTurns,
  required bool flipX,
}) =>
    _bruteDestinationAxisProjection(
      source: source,
      width: width,
      height: height,
      quarterTurns: quarterTurns,
      flipX: flipX,
      destinationX: true,
    );

List<BorderCoverageInterval> _bruteDestinationAxisProjection({
  required List<bool> source,
  required int width,
  required int height,
  required int quarterTurns,
  required bool flipX,
  required bool destinationX,
}) {
  final destinationWidth = quarterTurns.isEven ? width : height;
  final destinationHeight = quarterTurns.isEven ? height : width;
  final occupiedAxis = List<bool>.filled(
    destinationX ? destinationWidth : destinationHeight,
    false,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      if (!source[y * width + x]) {
        continue;
      }
      final x1 = flipX ? width - 1 - x : x;
      final destX = switch (quarterTurns) {
        0 => x1,
        1 => height - 1 - y,
        2 => width - 1 - x1,
        3 => y,
        _ => throw StateError('unreachable'),
      };
      final destY = switch (quarterTurns) {
        0 => y,
        1 => x1,
        2 => height - 1 - y,
        3 => width - 1 - x1,
        _ => throw StateError('unreachable'),
      };
      occupiedAxis[destinationX ? destX : destY] = true;
    }
  }
  final result = <BorderCoverageInterval>[];
  var start = -1;
  for (var x = 0; x <= occupiedAxis.length; x += 1) {
    final occupied = x < occupiedAxis.length && occupiedAxis[x];
    if (occupied && start < 0) {
      start = x;
    } else if (!occupied && start >= 0) {
      result.add(_interval(start, x));
      start = -1;
    }
  }
  return result;
}
