import '../exceptions/map_exceptions.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import 'border_rle_codec.dart';

/// Maximum occupancy expanded for one mask (64 fully opaque 32×32 stones).
const int stoneChainMaximumOpaquePixelsPerMask = 65536;

/// Maximum occupancy expanded by one row measurement (256 opaque 32×32 stones).
const int stoneChainMaximumRowOpaquePixels = 262144;

/// Maximum number of placed-mask descriptors accepted by one row measurement.
const int stoneChainMaximumRowSamples = 4096;

/// Opaque-pixel contact between two already-placed stone masks.
final class StoneChainContactMetrics {
  const StoneChainContactMetrics({
    required this.projectedGapPx,
    required this.tangentOverlapPx,
    required this.normalOverlapPx,
    required this.opaqueIntersectionPixels,
  });

  final int projectedGapPx;
  final int tangentOverlapPx;
  final int normalOverlapPx;
  final int opaqueIntersectionPixels;
}

/// One signed unit-cardinal axis used to project world pixels.
final class StoneChainAxis {
  factory StoneChainAxis({required int dx, required int dy}) {
    if (dx.abs() + dy.abs() != 1) {
      throw ArgumentError('StoneChainAxis must be unit-cardinal');
    }
    return StoneChainAxis._(dx: dx, dy: dy);
  }

  const StoneChainAxis._({required this.dx, required this.dy});

  final int dx;
  final int dy;
}

/// One explicit occupancy mask placement in transformed world-pixel space.
///
/// [topLeftWorldPx] is the top-left of the transformed sprite canvas. Source
/// pixels are flipped horizontally before clockwise quarter turns, matching
/// the persisted [BorderSpriteTransform] contract.
final class StoneChainPlacedMask {
  const StoneChainPlacedMask({
    required this.metrics,
    required this.transform,
    required this.topLeftWorldPx,
  });

  final BorderPrimitiveAssetMetrics metrics;
  final BorderSpriteTransform transform;
  final BorderPixelPos topLeftWorldPx;
}

/// One placed mask ordered along a logical stone-chain stroke.
final class StoneChainRowSample {
  const StoneChainRowSample({
    required this.strokeId,
    required this.slotKey,
    required this.pathDistancePx,
    required this.closed,
    required this.mask,
  });

  final String strokeId;
  final String slotKey;
  final int pathDistancePx;
  final bool closed;
  final StoneChainPlacedMask mask;
}

/// Global continuity summary for one or more independently ordered strokes.
final class StoneChainRowContinuity {
  const StoneChainRowContinuity({
    required this.maximumGapPx,
    required this.minimumOverlapPx,
    required this.medianOverlapPx,
    required this.maximumOverlapPx,
    required this.connectedComponentCount,
  });

  final int maximumGapPx;
  final int minimumOverlapPx;
  final int medianOverlapPx;
  final int maximumOverlapPx;
  final int connectedComponentCount;
}

/// Measures actual occupied source pixels after transform and world placement.
///
/// Gap is the number of completely empty tangent coordinates between the two
/// opaque projections, so adjacent or overlapping projections have a zero
/// gap. Overlaps are lengths of the corresponding opaque projection bounds;
/// pixel interlock remains separate in [StoneChainContactMetrics].
StoneChainContactMetrics measureStoneChainContact({
  required StoneChainPlacedMask first,
  required StoneChainPlacedMask second,
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
}) {
  _requirePerpendicularAxes(tangent, normal);
  _preflightMask(first.metrics);
  _preflightMask(second.metrics);
  return _measurePreparedContact(
    first: _worldOpaquePixels(first),
    second: _worldOpaquePixels(second),
    tangent: tangent,
    normal: normal,
  );
}

/// Aggregates consecutive contact metrics and 4-connected world occupancy.
///
/// Samples are grouped by [StoneChainRowSample.strokeId]. Each group is sorted
/// by path distance then slot key, without introducing contacts between
/// strokes. A closed group with at least two samples measures its last-to-first
/// seam exactly once. A zero- or one-sample group has no neighbor statistics.
/// For an even number of overlaps, the median is the floor of the arithmetic
/// mean of the two central values.
StoneChainRowContinuity measureStoneChainRowContinuity({
  required List<StoneChainRowSample> samples,
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
}) {
  _requirePerpendicularAxes(tangent, normal);
  if (samples.length > stoneChainMaximumRowSamples) {
    throw const ValidationException(
      'Stone-chain row sample count must not exceed 4096',
    );
  }
  var cumulativeOpaquePixels = 0;
  for (final sample in samples) {
    final opaquePixels = _preflightMask(sample.mask.metrics);
    if (opaquePixels >
        stoneChainMaximumRowOpaquePixels - cumulativeOpaquePixels) {
      throw const ValidationException(
        'Stone-chain row opaque pixel count must not exceed 262144',
      );
    }
    cumulativeOpaquePixels += opaquePixels;
  }

  final groups = <String, List<_PreparedRowSample>>{};
  final union = <_WorldPixel>{};
  for (final sample in samples) {
    final pixels = _worldOpaquePixels(sample.mask);
    union.addAll(pixels);
    (groups[sample.strokeId] ??= <_PreparedRowSample>[]).add(
      _PreparedRowSample(sample: sample, pixels: pixels),
    );
  }

  final contacts = <StoneChainContactMetrics>[];
  for (final entry in groups.entries) {
    final group = entry.value;
    _validateRowGroup(entry.key, group);
    group.sort((left, right) {
      final byDistance = left.sample.pathDistancePx.compareTo(
        right.sample.pathDistancePx,
      );
      return byDistance != 0
          ? byDistance
          : left.sample.slotKey.compareTo(right.sample.slotKey);
    });
    for (var index = 1; index < group.length; index += 1) {
      contacts.add(
        _measurePreparedContact(
          first: group[index - 1].pixels,
          second: group[index].pixels,
          tangent: tangent,
          normal: normal,
        ),
      );
    }
    if (group.length > 1 && group.first.sample.closed) {
      contacts.add(
        _measurePreparedContact(
          first: group.last.pixels,
          second: group.first.pixels,
          tangent: tangent,
          normal: normal,
        ),
      );
    }
  }

  final overlaps = <int>[
    for (final contact in contacts) contact.tangentOverlapPx,
  ]..sort();
  var maximumGapPx = 0;
  for (final contact in contacts) {
    if (contact.projectedGapPx > maximumGapPx) {
      maximumGapPx = contact.projectedGapPx;
    }
  }
  return StoneChainRowContinuity(
    maximumGapPx: maximumGapPx,
    minimumOverlapPx: overlaps.isEmpty ? 0 : overlaps.first,
    medianOverlapPx: _integerMedian(overlaps),
    maximumOverlapPx: overlaps.isEmpty ? 0 : overlaps.last,
    connectedComponentCount: _countConnectedComponents(union),
  );
}

int _preflightMask(BorderPrimitiveAssetMetrics metrics) {
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  var opaquePixels = 0;
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: checkedBorderRleCellCount(
      width: width,
      height: height,
      path: r'$.metrics.pixelSize',
    ),
    path: r'$.metrics.occupancyMaskRle',
    visitor: (start, end) {
      opaquePixels += end - start;
    },
  );
  if (opaquePixels > stoneChainMaximumOpaquePixelsPerMask) {
    throw const ValidationException(
      'Stone-chain mask opaque pixel count must not exceed 65536',
    );
  }
  return opaquePixels;
}

StoneChainContactMetrics _measurePreparedContact({
  required Set<_WorldPixel> first,
  required Set<_WorldPixel> second,
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
}) {
  final firstTangent = _projectedRange(first, tangent);
  final secondTangent = _projectedRange(second, tangent);
  final firstNormal = _projectedRange(first, normal);
  final secondNormal = _projectedRange(second, normal);
  final smaller = first.length <= second.length ? first : second;
  final larger = identical(smaller, first) ? second : first;
  var intersections = 0;
  for (final pixel in smaller) {
    if (larger.contains(pixel)) intersections += 1;
  }
  return StoneChainContactMetrics(
    projectedGapPx: _projectedGap(firstTangent, secondTangent),
    tangentOverlapPx: _projectedOverlap(firstTangent, secondTangent),
    normalOverlapPx: _projectedOverlap(firstNormal, secondNormal),
    opaqueIntersectionPixels: intersections,
  );
}

Set<_WorldPixel> _worldOpaquePixels(StoneChainPlacedMask placed) {
  final metrics = placed.metrics;
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  final pixels = <_WorldPixel>{};
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: checkedBorderRleCellCount(
      width: width,
      height: height,
      path: r'$.metrics.pixelSize',
    ),
    path: r'$.metrics.occupancyMaskRle',
    visitor: (start, end) {
      for (var index = start; index < end; index += 1) {
        final transformed = _transformSourcePixel(
          x: index % width,
          y: index ~/ width,
          width: width,
          height: height,
          transform: placed.transform,
        );
        pixels.add((
          x: placed.topLeftWorldPx.x + transformed.x,
          y: placed.topLeftWorldPx.y + transformed.y,
        ));
      }
    },
  );
  return pixels;
}

_WorldPixel _transformSourcePixel({
  required int x,
  required int y,
  required int width,
  required int height,
  required BorderSpriteTransform transform,
}) {
  final flippedX = transform.flipX ? width - 1 - x : x;
  return switch (transform.quarterTurns) {
    0 => (x: flippedX, y: y),
    1 => (x: height - 1 - y, y: flippedX),
    2 => (x: width - 1 - flippedX, y: height - 1 - y),
    3 => (x: y, y: width - 1 - flippedX),
    _ => throw const ValidationException(
        'Border quarterTurns must be between 0 and 3',
      ),
  };
}

_ProjectedRange? _projectedRange(
  Set<_WorldPixel> pixels,
  StoneChainAxis axis,
) {
  if (pixels.isEmpty) return null;
  int? minimum;
  int? maximum;
  for (final pixel in pixels) {
    final projection = pixel.x * axis.dx + pixel.y * axis.dy;
    if (minimum == null || projection < minimum) minimum = projection;
    if (maximum == null || projection > maximum) maximum = projection;
  }
  return _ProjectedRange(minimum: minimum!, maximum: maximum!);
}

int _projectedGap(_ProjectedRange? first, _ProjectedRange? second) {
  if (first == null || second == null) return 0;
  if (first.maximum < second.minimum) {
    return second.minimum - first.maximum - 1;
  }
  if (second.maximum < first.minimum) {
    return first.minimum - second.maximum - 1;
  }
  return 0;
}

int _projectedOverlap(_ProjectedRange? first, _ProjectedRange? second) {
  if (first == null || second == null) return 0;
  final start = first.minimum > second.minimum ? first.minimum : second.minimum;
  final end = first.maximum < second.maximum ? first.maximum : second.maximum;
  return end < start ? 0 : end - start + 1;
}

void _requirePerpendicularAxes(
  StoneChainAxis tangent,
  StoneChainAxis normal,
) {
  if (tangent.dx * normal.dx + tangent.dy * normal.dy != 0) {
    throw ArgumentError(
      'Stone-chain tangent and normal axes must be perpendicular',
    );
  }
}

void _validateRowGroup(String strokeId, List<_PreparedRowSample> group) {
  final closed = group.first.sample.closed;
  final pathDistances = <int>{};
  final slotKeys = <String>{};
  for (final prepared in group) {
    final sample = prepared.sample;
    if (sample.closed != closed) {
      throw ArgumentError(
        'Stone-chain stroke "$strokeId" must not mix open and closed samples',
      );
    }
    if (!pathDistances.add(sample.pathDistancePx)) {
      throw ArgumentError(
        'Stone-chain stroke "$strokeId" has duplicate pathDistancePx',
      );
    }
    if (!slotKeys.add(sample.slotKey)) {
      throw ArgumentError(
        'Stone-chain stroke "$strokeId" has duplicate slotKey',
      );
    }
  }
}

int _integerMedian(List<int> sortedValues) {
  if (sortedValues.isEmpty) return 0;
  final middle = sortedValues.length ~/ 2;
  if (sortedValues.length.isOdd) return sortedValues[middle];
  final lower = sortedValues[middle - 1];
  final upper = sortedValues[middle];
  return lower + (upper - lower) ~/ 2;
}

int _countConnectedComponents(Set<_WorldPixel> pixels) {
  final remaining = Set<_WorldPixel>.of(pixels);
  var count = 0;
  while (remaining.isNotEmpty) {
    count += 1;
    final pending = <_WorldPixel>[remaining.first];
    remaining.remove(pending.first);
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final neighbor in <_WorldPixel>[
        (x: current.x - 1, y: current.y),
        (x: current.x + 1, y: current.y),
        (x: current.x, y: current.y - 1),
        (x: current.x, y: current.y + 1),
      ]) {
        if (remaining.remove(neighbor)) pending.add(neighbor);
      }
    }
  }
  return count;
}

typedef _WorldPixel = ({int x, int y});

final class _ProjectedRange {
  const _ProjectedRange({required this.minimum, required this.maximum});

  final int minimum;
  final int maximum;
}

final class _PreparedRowSample {
  const _PreparedRowSample({required this.sample, required this.pixels});

  final StoneChainRowSample sample;
  final Set<_WorldPixel> pixels;
}
