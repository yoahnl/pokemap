import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import 'border_region_contours.dart';
import 'border_rle_codec.dart';
import 'narrative_event_canonical_json.dart';

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');

/// One half-open curvilinear interval in pixels.
@immutable
final class BorderCoverageInterval
    implements Comparable<BorderCoverageInterval> {
  BorderCoverageInterval({required this.startPx, required this.endPx}) {
    _requirePortableInt(startPx, 'startPx');
    _requirePortableInt(endPx, 'endPx');
    if (endPx <= startPx) {
      throw const ValidationException(
        'BorderCoverageInterval must be a non-empty half-open interval',
      );
    }
    if ((BigInt.from(endPx) - BigInt.from(startPx)) >
        _maximumPortableJsonInteger) {
      throw const ValidationException(
        'BorderCoverageInterval length must fit the portable integer range',
      );
    }
  }

  final int startPx;
  final int endPx;

  int get lengthPx => endPx - startPx;

  @override
  int compareTo(BorderCoverageInterval other) {
    final start = startPx.compareTo(other.startPx);
    return start != 0 ? start : endPx.compareTo(other.endPx);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderCoverageInterval &&
          startPx == other.startPx &&
          endPx == other.endPx;

  @override
  int get hashCode => Object.hash(startPx, endPx);

  @override
  String toString() => '[$startPx, $endPx)';
}

/// Structural coverage contributed by one placement on one loop.
@immutable
final class BorderStructuralCoverageProjection {
  BorderStructuralCoverageProjection({
    required this.placementId,
    required this.drawBand,
    required this.passIndex,
    required List<BorderCoverageInterval> intervals,
  }) : _intervals = List<BorderCoverageInterval>.unmodifiable(intervals) {
    if (placementId.trim().isEmpty || placementId != placementId.trim()) {
      throw const ValidationException(
        'BorderStructuralCoverageProjection.placementId must be stable text',
      );
    }
    if (passIndex < 0) {
      throw const ValidationException(
        'BorderStructuralCoverageProjection.passIndex must be >= 0',
      );
    }
    _requirePortableInt(passIndex, 'passIndex');
  }

  final String placementId;
  final BorderDrawBand drawBand;
  final int passIndex;
  final List<BorderCoverageInterval> _intervals;

  List<BorderCoverageInterval> get intervals => _intervals;
}

/// Pairwise overlap inside one draw-band/pass group.
@immutable
final class BorderCoverageOverlap {
  BorderCoverageOverlap._({
    required this.firstPlacementId,
    required this.secondPlacementId,
    required this.lengthPx,
  }) {
    if (compareNarrativeEventUtf16(firstPlacementId, secondPlacementId) >= 0 ||
        lengthPx <= 0) {
      throw const ValidationException(
        'BorderCoverageOverlap requires ordered distinct IDs and length > 0',
      );
    }
    _requirePortableInt(lengthPx, 'overlap.lengthPx');
  }

  final String firstPlacementId;
  final String secondPlacementId;
  final int lengthPx;
}

/// Deterministic coverage metrics for one circular contour domain.
@immutable
final class BorderLoopCoverageAssessment {
  BorderLoopCoverageAssessment._({
    required List<BorderCoverageInterval> targetIntervals,
    required List<BorderCoverageInterval> coveredIntervals,
    required List<BorderCoverageInterval> uncoveredIntervals,
    required List<BorderCoverageOverlap> overlaps,
    required this.longestContiguousGapPx,
    required this.maximumPairwiseOverlapPx,
    required this.gapTolerancePx,
    required this.maxOverlapPx,
  })  : _targetIntervals =
            List<BorderCoverageInterval>.unmodifiable(targetIntervals),
        _coveredIntervals =
            List<BorderCoverageInterval>.unmodifiable(coveredIntervals),
        _uncoveredIntervals =
            List<BorderCoverageInterval>.unmodifiable(uncoveredIntervals),
        _overlaps = List<BorderCoverageOverlap>.unmodifiable(overlaps) {
    _requirePortableInt(longestContiguousGapPx, 'longestContiguousGapPx');
    _requirePortableInt(maximumPairwiseOverlapPx, 'maximumPairwiseOverlapPx');
    _requirePortableInt(gapTolerancePx, 'gapTolerancePx');
    _requirePortableInt(maxOverlapPx, 'maxOverlapPx');
    if (longestContiguousGapPx < 0 ||
        maximumPairwiseOverlapPx < 0 ||
        gapTolerancePx < 0 ||
        maxOverlapPx < 0) {
      throw const ValidationException(
        'BorderLoopCoverageAssessment metrics must be non-negative',
      );
    }
  }

  final List<BorderCoverageInterval> _targetIntervals;
  final List<BorderCoverageInterval> _coveredIntervals;
  final List<BorderCoverageInterval> _uncoveredIntervals;
  final List<BorderCoverageOverlap> _overlaps;
  final int longestContiguousGapPx;
  final int maximumPairwiseOverlapPx;
  final int gapTolerancePx;
  final int maxOverlapPx;

  List<BorderCoverageInterval> get targetIntervals => _targetIntervals;
  List<BorderCoverageInterval> get coveredIntervals => _coveredIntervals;
  List<BorderCoverageInterval> get uncoveredIntervals => _uncoveredIntervals;
  List<BorderCoverageOverlap> get overlaps => _overlaps;

  bool get hasExcessiveGap => longestContiguousGapPx > gapTolerancePx;
  bool get hasExcessiveOverlap => maximumPairwiseOverlapPx > maxOverlapPx;
  bool get isWithinTolerance => !hasExcessiveGap && !hasExcessiveOverlap;
}

/// Assesses structural coverage on one circular contour.
///
/// [targetIntervals] and [excludedIntervals] must already be canonical pieces
/// inside `[0, perimeterPx)`. Placement projections may be unwrapped; they are
/// normalized circularly before union/intersection. Gaps use the union of all
/// placements, while overlaps remain pairwise and are compared only inside an
/// equal draw-band/pass group.
BorderLoopCoverageAssessment assessBorderLoopCoverage({
  required int perimeterPx,
  Iterable<BorderCoverageInterval>? targetIntervals,
  Iterable<BorderCoverageInterval> excludedIntervals =
      const <BorderCoverageInterval>[],
  required Iterable<BorderStructuralCoverageProjection> projections,
  required int gapTolerancePx,
  required int maxOverlapPx,
}) {
  _requirePortableInt(perimeterPx, 'perimeterPx');
  _requirePortableInt(gapTolerancePx, 'gapTolerancePx');
  _requirePortableInt(maxOverlapPx, 'maxOverlapPx');
  if (perimeterPx <= 0 || gapTolerancePx < 0 || maxOverlapPx < 0) {
    throw const ValidationException(
      'Border coverage perimeter must be positive and tolerances non-negative',
    );
  }

  final rawTarget = targetIntervals?.toList(growable: false) ??
      <BorderCoverageInterval>[
        BorderCoverageInterval(startPx: 0, endPx: perimeterPx),
      ];
  _requireIntervalsInsideLoop(rawTarget, perimeterPx, 'targetIntervals');
  final exclusions = excludedIntervals.toList(growable: false);
  _requireIntervalsInsideLoop(exclusions, perimeterPx, 'excludedIntervals');
  final target = _subtractIntervals(
    _mergeIntervals(rawTarget),
    _mergeIntervals(exclusions),
  );

  final sourceProjections = projections.toList(growable: false)
    ..sort(
      (left, right) => compareNarrativeEventUtf16(
        left.placementId,
        right.placementId,
      ),
    );
  final ids = <String>{};
  final normalizedByProjection =
      <BorderStructuralCoverageProjection, List<BorderCoverageInterval>>{};
  for (final projection in sourceProjections) {
    if (!ids.add(projection.placementId)) {
      throw ValidationException(
        'Duplicate structural coverage placementId: ${projection.placementId}',
      );
    }
    normalizedByProjection[projection] = _normalizeCircularIntervals(
      projection.intervals,
      perimeterPx,
    );
  }

  final allCoverage = _mergeIntervals(<BorderCoverageInterval>[
    for (final intervals in normalizedByProjection.values) ...intervals,
  ]);
  final covered = _intersectIntervals(target, allCoverage);
  final uncovered = _subtractIntervals(target, covered);
  final longestGap = _longestCircularGap(
    uncovered: uncovered,
    target: target,
    perimeterPx: perimeterPx,
  );

  final overlaps = _computePairwiseOverlaps(
    sourceProjections,
    normalizedByProjection,
  );
  var maximumOverlap = 0;
  for (final overlap in overlaps) {
    if (overlap.lengthPx > maximumOverlap) {
      maximumOverlap = overlap.lengthPx;
    }
  }

  return BorderLoopCoverageAssessment._(
    targetIntervals: target,
    coveredIntervals: covered,
    uncoveredIntervals: uncovered,
    overlaps: overlaps,
    longestContiguousGapPx: longestGap,
    maximumPairwiseOverlapPx: maximumOverlap,
    gapTolerancePx: gapTolerancePx,
    maxOverlapPx: maxOverlapPx,
  );
}

/// Projects a transformed structural occupancy mask onto one contour edge.
///
/// The returned intervals are deliberately unwrapped. The circular assessment
/// above performs the final split around zero. Transparent columns/rows remain
/// separate components rather than being replaced by the opaque bounding box.
List<BorderCoverageInterval> projectBorderStructuralMaskOntoEdge({
  required BorderPrimitiveAssetMetrics metrics,
  required BorderSpriteTransform transform,
  required BorderPixelPos topLeftWorldPx,
  required BorderRegionContourEdge edge,
}) {
  final projectsDestinationX = edge.direction == BorderCardinalDirection.east ||
      edge.direction == BorderCardinalDirection.west;
  final axis = _sourceAxisForDestination(
    quarterTurns: transform.quarterTurns,
    flipX: transform.flipX,
    destinationX: projectsDestinationX,
  );
  var sourceIntervals = _projectSourceMaskAxis(
    metrics: metrics,
    sourceX: axis.sourceX,
  );
  final sourceLength =
      axis.sourceX ? metrics.pixelSize.width : metrics.pixelSize.height;
  if (axis.reversed) {
    sourceIntervals = <BorderCoverageInterval>[
      for (final interval in sourceIntervals.reversed)
        BorderCoverageInterval(
          startPx: sourceLength - interval.endPx,
          endPx: sourceLength - interval.startPx,
        ),
    ];
  }

  final topLeftAxis =
      projectsDestinationX ? topLeftWorldPx.x : topLeftWorldPx.y;
  final edgeStartAxis =
      projectsDestinationX ? edge.startWorldPx.x : edge.startWorldPx.y;
  final forward = edge.direction == BorderCardinalDirection.east ||
      edge.direction == BorderCardinalDirection.south;
  final result = <BorderCoverageInterval>[];
  for (final interval in sourceIntervals) {
    final worldStart = BigInt.from(topLeftAxis) + BigInt.from(interval.startPx);
    final worldEnd = BigInt.from(topLeftAxis) + BigInt.from(interval.endPx);
    final edgeStart = BigInt.from(edgeStartAxis);
    final abscissa = BigInt.from(edge.startAbscissaPx);
    final start = forward
        ? abscissa + worldStart - edgeStart
        : abscissa + edgeStart - worldEnd;
    final end = forward
        ? abscissa + worldEnd - edgeStart
        : abscissa + edgeStart - worldStart;
    result.add(
      BorderCoverageInterval(
        startPx: _portableInt(start, 'projected interval start'),
        endPx: _portableInt(end, 'projected interval end'),
      ),
    );
  }
  return List<BorderCoverageInterval>.unmodifiable(_mergeIntervals(result));
}

({bool sourceX, bool reversed}) _sourceAxisForDestination({
  required int quarterTurns,
  required bool flipX,
  required bool destinationX,
}) =>
    switch ((quarterTurns, destinationX)) {
      (0, true) => (sourceX: true, reversed: flipX),
      (0, false) => (sourceX: false, reversed: false),
      (1, true) => (sourceX: false, reversed: true),
      (1, false) => (sourceX: true, reversed: flipX),
      (2, true) => (sourceX: true, reversed: !flipX),
      (2, false) => (sourceX: false, reversed: true),
      (3, true) => (sourceX: false, reversed: false),
      (3, false) => (sourceX: true, reversed: !flipX),
      _ => throw const ValidationException(
          'Border structural projection quarterTurns must be 0..3',
        ),
    };

List<BorderCoverageInterval> _projectSourceMaskAxis({
  required BorderPrimitiveAssetMetrics metrics,
  required bool sourceX,
}) {
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  final expectedLength = checkedBorderRleCellCount(
    width: width,
    height: height,
    path: r'$.publishedMetrics.pixelSize',
  );
  final occupied = List<bool>.filled(
    sourceX ? width : height,
    false,
    growable: false,
  );
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: expectedLength,
    path: r'$.publishedMetrics.occupancyMaskRle',
    visitor: (start, end) {
      final firstRow = start ~/ width;
      final lastRow = (end - 1) ~/ width;
      if (!sourceX) {
        for (var row = firstRow; row <= lastRow; row += 1) {
          occupied[row] = true;
        }
        return;
      }
      if (firstRow == lastRow) {
        final endColumn = (end - 1) % width + 1;
        for (var column = start % width; column < endColumn; column += 1) {
          occupied[column] = true;
        }
        return;
      }
      for (var column = start % width; column < width; column += 1) {
        occupied[column] = true;
      }
      for (var column = 0; column <= (end - 1) % width; column += 1) {
        occupied[column] = true;
      }
      if (lastRow - firstRow > 1) {
        occupied.fillRange(0, occupied.length, true);
      }
    },
  );
  return _intervalsFromOccupancy(occupied);
}

List<BorderCoverageInterval> _intervalsFromOccupancy(List<bool> occupied) {
  final result = <BorderCoverageInterval>[];
  var start = -1;
  for (var index = 0; index <= occupied.length; index += 1) {
    final filled = index < occupied.length && occupied[index];
    if (filled && start < 0) {
      start = index;
    } else if (!filled && start >= 0) {
      result.add(BorderCoverageInterval(startPx: start, endPx: index));
      start = -1;
    }
  }
  return result;
}

List<BorderCoverageInterval> _normalizeCircularIntervals(
  Iterable<BorderCoverageInterval> source,
  int perimeterPx,
) {
  final result = <BorderCoverageInterval>[];
  for (final interval in source) {
    final length = BigInt.from(interval.endPx) - BigInt.from(interval.startPx);
    if (length >= BigInt.from(perimeterPx)) {
      return <BorderCoverageInterval>[
        BorderCoverageInterval(startPx: 0, endPx: perimeterPx),
      ];
    }
    final perimeter = BigInt.from(perimeterPx);
    final start = _positiveModulo(interval.startPx, perimeterPx);
    final unwrappedEnd = start + length;
    if (unwrappedEnd <= perimeter) {
      result.add(
        BorderCoverageInterval(
          startPx: _portableInt(start, 'normalized interval start'),
          endPx: _portableInt(unwrappedEnd, 'normalized interval end'),
        ),
      );
    } else {
      result
        ..add(
          BorderCoverageInterval(
            startPx: _portableInt(start, 'wrapped interval start'),
            endPx: perimeterPx,
          ),
        )
        ..add(
          BorderCoverageInterval(
            startPx: 0,
            endPx: _portableInt(
              unwrappedEnd - perimeter,
              'wrapped interval end',
            ),
          ),
        );
    }
  }
  return _mergeIntervals(result);
}

BigInt _positiveModulo(int value, int modulus) {
  final bigModulus = BigInt.from(modulus);
  final result = BigInt.from(value).remainder(bigModulus);
  return result < BigInt.zero ? result + bigModulus : result;
}

List<BorderCoverageInterval> _mergeIntervals(
  Iterable<BorderCoverageInterval> source,
) {
  final sorted = source.toList(growable: false)..sort();
  if (sorted.isEmpty) {
    return <BorderCoverageInterval>[];
  }
  final result = <BorderCoverageInterval>[];
  var start = sorted.first.startPx;
  var end = sorted.first.endPx;
  for (final interval in sorted.skip(1)) {
    if (interval.startPx <= end) {
      if (interval.endPx > end) {
        end = interval.endPx;
      }
      continue;
    }
    result.add(BorderCoverageInterval(startPx: start, endPx: end));
    start = interval.startPx;
    end = interval.endPx;
  }
  result.add(BorderCoverageInterval(startPx: start, endPx: end));
  return result;
}

List<BorderCoverageInterval> _intersectIntervals(
  List<BorderCoverageInterval> left,
  List<BorderCoverageInterval> right,
) {
  final result = <BorderCoverageInterval>[];
  var leftIndex = 0;
  var rightIndex = 0;
  while (leftIndex < left.length && rightIndex < right.length) {
    final start = left[leftIndex].startPx > right[rightIndex].startPx
        ? left[leftIndex].startPx
        : right[rightIndex].startPx;
    final end = left[leftIndex].endPx < right[rightIndex].endPx
        ? left[leftIndex].endPx
        : right[rightIndex].endPx;
    if (start < end) {
      result.add(BorderCoverageInterval(startPx: start, endPx: end));
    }
    if (left[leftIndex].endPx <= right[rightIndex].endPx) {
      leftIndex += 1;
    } else {
      rightIndex += 1;
    }
  }
  return result;
}

List<BorderCoverageInterval> _subtractIntervals(
  List<BorderCoverageInterval> source,
  List<BorderCoverageInterval> removed,
) {
  final result = <BorderCoverageInterval>[];
  var removedIndex = 0;
  for (final interval in source) {
    var cursor = interval.startPx;
    while (removedIndex < removed.length &&
        removed[removedIndex].endPx <= cursor) {
      removedIndex += 1;
    }
    var scan = removedIndex;
    while (scan < removed.length && removed[scan].startPx < interval.endPx) {
      final cut = removed[scan];
      if (cut.startPx > cursor) {
        result.add(
          BorderCoverageInterval(
            startPx: cursor,
            endPx: cut.startPx < interval.endPx ? cut.startPx : interval.endPx,
          ),
        );
      }
      if (cut.endPx > cursor) {
        cursor = cut.endPx;
      }
      if (cursor >= interval.endPx) {
        break;
      }
      scan += 1;
    }
    if (cursor < interval.endPx) {
      result.add(
        BorderCoverageInterval(startPx: cursor, endPx: interval.endPx),
      );
    }
  }
  return result;
}

int _longestCircularGap({
  required List<BorderCoverageInterval> uncovered,
  required List<BorderCoverageInterval> target,
  required int perimeterPx,
}) {
  if (uncovered.isEmpty) {
    return 0;
  }
  var longest = 0;
  for (final interval in uncovered) {
    if (interval.lengthPx > longest) {
      longest = interval.lengthPx;
    }
  }
  if (uncovered.length >= 2 &&
      target.isNotEmpty &&
      target.first.startPx == 0 &&
      target.last.endPx == perimeterPx &&
      uncovered.first.startPx == 0 &&
      uncovered.last.endPx == perimeterPx) {
    final joined = uncovered.first.lengthPx + uncovered.last.lengthPx;
    if (joined > longest) {
      longest = joined;
    }
  }
  return longest;
}

List<BorderCoverageOverlap> _computePairwiseOverlaps(
  List<BorderStructuralCoverageProjection> projections,
  Map<BorderStructuralCoverageProjection, List<BorderCoverageInterval>>
      normalized,
) {
  final groups =
      <(BorderDrawBand, int), List<BorderStructuralCoverageProjection>>{};
  for (final projection in projections) {
    groups.putIfAbsent(
      (projection.drawBand, projection.passIndex),
      () => <BorderStructuralCoverageProjection>[],
    ).add(projection);
  }

  final totals = <(String, String), BigInt>{};
  for (final group in groups.values) {
    if (group.length < 2) {
      continue;
    }
    final pieces = <_CoveragePiece>[
      for (final projection in group)
        for (final interval in normalized[projection]!)
          _CoveragePiece(projection: projection, interval: interval),
    ]..sort(_compareCoveragePieces);
    final active = <_CoveragePiece>[];
    for (final current in pieces) {
      active.removeWhere(
        (candidate) => candidate.interval.endPx <= current.interval.startPx,
      );
      for (final candidate in active) {
        if (candidate.projection.placementId ==
            current.projection.placementId) {
          continue;
        }
        final end = candidate.interval.endPx < current.interval.endPx
            ? candidate.interval.endPx
            : current.interval.endPx;
        final length = end - current.interval.startPx;
        if (length <= 0) {
          continue;
        }
        final comparison = compareNarrativeEventUtf16(
          candidate.projection.placementId,
          current.projection.placementId,
        );
        final key = comparison < 0
            ? (
                candidate.projection.placementId,
                current.projection.placementId,
              )
            : (
                current.projection.placementId,
                candidate.projection.placementId,
              );
        totals[key] = (totals[key] ?? BigInt.zero) + BigInt.from(length);
      }
      active.add(current);
    }
  }

  final keys = totals.keys.toList(growable: false)
    ..sort((left, right) {
      final first = compareNarrativeEventUtf16(left.$1, right.$1);
      return first != 0 ? first : compareNarrativeEventUtf16(left.$2, right.$2);
    });
  return <BorderCoverageOverlap>[
    for (final key in keys)
      BorderCoverageOverlap._(
        firstPlacementId: key.$1,
        secondPlacementId: key.$2,
        lengthPx: _portableInt(
          totals[key]!,
          'pairwise overlap length',
        ),
      ),
  ];
}

final class _CoveragePiece {
  const _CoveragePiece({required this.projection, required this.interval});

  final BorderStructuralCoverageProjection projection;
  final BorderCoverageInterval interval;
}

int _compareCoveragePieces(_CoveragePiece left, _CoveragePiece right) {
  final interval = left.interval.compareTo(right.interval);
  return interval != 0
      ? interval
      : compareNarrativeEventUtf16(
          left.projection.placementId,
          right.projection.placementId,
        );
}

void _requireIntervalsInsideLoop(
  Iterable<BorderCoverageInterval> intervals,
  int perimeterPx,
  String field,
) {
  for (final interval in intervals) {
    if (interval.startPx < 0 || interval.endPx > perimeterPx) {
      throw ValidationException(
        'Border coverage $field must stay inside the loop domain',
      );
    }
  }
}

void _requirePortableInt(int value, String field) {
  if (BigInt.from(value).abs() > _maximumPortableJsonInteger) {
    throw ValidationException(
      'Border coverage $field must fit the portable integer range',
    );
  }
}

int _portableInt(BigInt value, String field) {
  if (value.abs() > _maximumPortableJsonInteger) {
    throw ValidationException(
      'Border coverage $field must fit the portable integer range',
    );
  }
  return value.toInt();
}
