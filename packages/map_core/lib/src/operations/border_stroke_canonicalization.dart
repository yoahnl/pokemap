import '../exceptions/map_exceptions.dart';
import '../models/border_geometry.dart';
import '../models/geometry.dart';

/// Rasterizes one sampled pair using the symmetric Border V1 rule.
///
/// Endpoints are first ordered by `(y, x)`. The canonical walk moves
/// horizontally, then vertically. When the caller's gesture runs from the
/// greater endpoint to the lesser one, the canonical walk is returned in
/// reverse so that `rasterize(B, A) == reverse(rasterize(A, B))`.
List<GridPos> rasterizeBorderStrokePairV1(GridPos start, GridPos end) {
  final startComesFirst = _comparePoint(start, end) <= 0;
  final lesser = startComesFirst ? start : end;
  final greater = startComesFirst ? end : start;
  final canonical = <GridPos>[
    GridPos(x: lesser.x, y: lesser.y),
  ];

  var x = lesser.x;
  while (x != greater.x) {
    x += x < greater.x ? 1 : -1;
    canonical.add(GridPos(x: x, y: lesser.y));
  }

  var y = lesser.y;
  while (y != greater.y) {
    y += y < greater.y ? 1 : -1;
    canonical.add(GridPos(x: greater.x, y: y));
  }

  return List<GridPos>.unmodifiable(
    startComesFirst ? canonical : canonical.reversed,
  );
}

/// Rasterizes and canonicalizes one V1 stroke from ordered gesture samples.
///
/// Pair joins are coalesced. Open strokes choose the lexicographically
/// smallest row-major direction. Closed strokes omit a repeated terminal
/// point and choose the smallest cyclic rotation across both directions.
BorderStroke canonicalizeBorderStrokeV1({
  required String id,
  required Iterable<GridPos> sampledPoints,
  required bool closed,
}) {
  final samples = List<GridPos>.unmodifiable(
    sampledPoints.map((point) => GridPos(x: point.x, y: point.y)),
  );
  if (samples.isEmpty) {
    throw const ValidationException(
      'A Border V1 stroke requires at least two distinct cells',
    );
  }

  final rasterized = <GridPos>[];
  if (samples.length == 1) {
    rasterized.add(samples.single);
  } else {
    for (var index = 1; index < samples.length; index += 1) {
      final pair = rasterizeBorderStrokePairV1(
        samples[index - 1],
        samples[index],
      );
      for (final point in pair) {
        if (rasterized.isEmpty || rasterized.last != point) {
          rasterized.add(point);
        }
      }
    }
  }

  if (closed && rasterized.length > 1 && rasterized.first == rasterized.last) {
    rasterized.removeLast();
  }

  _validateCanonicalizableChain(rasterized, closed: closed);
  final canonicalPoints = closed
      ? _minimumClosedRotation(rasterized)
      : _minimumOpenDirection(rasterized);

  return BorderStroke(
    id: id,
    points: canonicalPoints,
    closed: closed,
  );
}

/// Canonicalizes independent persisted strokes without changing their order.
///
/// The returned geometry owns fresh strokes. Its constructor also enforces
/// the V1 no-shared-cell/no-shared-edge contract between strokes, which keeps
/// separate strokes as explicit openings rather than inferred junctions.
BorderStrokeGeometry canonicalizeBorderStrokeGeometryV1(
  Iterable<BorderStroke> strokes,
) {
  final canonical = <BorderStroke>[
    for (final stroke in strokes)
      canonicalizeBorderStrokeV1(
        id: stroke.id,
        sampledPoints: stroke.points,
        closed: stroke.closed,
      ),
  ];
  return BorderStrokeGeometry(strokes: canonical);
}

void _validateCanonicalizableChain(
  List<GridPos> points, {
  required bool closed,
}) {
  final minimum = closed ? 4 : 2;
  if (points.length < minimum) {
    throw ValidationException(
      'A ${closed ? 'closed' : 'open'} Border V1 stroke requires at least '
      '$minimum distinct cells',
    );
  }

  final indexByPoint = <GridPos, int>{};
  for (var index = 0; index < points.length; index += 1) {
    final point = points[index];
    if (indexByPoint.containsKey(point)) {
      throw const ValidationException(
        'Border V1 strokes must not repeat cells, backtrack, or self-cross',
      );
    }
    indexByPoint[point] = index;
  }

  for (var index = 1; index < points.length; index += 1) {
    if (!_areCardinallyAdjacent(points[index - 1], points[index])) {
      throw const ValidationException(
        'Border V1 stroke cells must form one unit-cardinal chain',
      );
    }
  }
  if (closed && !_areCardinallyAdjacent(points.last, points.first)) {
    throw const ValidationException(
      'A closed Border V1 stroke requires an implicit cardinal closing edge',
    );
  }

  // A non-consecutive cardinal contact introduces an undeclared edge and can
  // create a branch/crossing even though the ordered chain itself is valid.
  // The point index keeps this check linear: inspect only the four possible
  // cardinal neighbors and visit each discovered pair once.
  for (var first = 0; first < points.length; first += 1) {
    final point = points[first];
    for (final offset in _cardinalNeighborOffsets) {
      final second =
          indexByPoint[GridPos(x: point.x + offset.$1, y: point.y + offset.$2)];
      if (second == null || second <= first) continue;
      final consecutive = second == first + 1;
      final implicitClosure =
          closed && first == 0 && second == points.length - 1;
      if (!consecutive && !implicitClosure) {
        throw const ValidationException(
          'Border V1 strokes must not contain implicit branches or crossings',
        );
      }
    }
  }
}

const List<(int, int)> _cardinalNeighborOffsets = <(int, int)>[
  (-1, 0),
  (1, 0),
  (0, -1),
  (0, 1),
];

List<GridPos> _minimumOpenDirection(List<GridPos> points) {
  final forward = List<GridPos>.of(points, growable: false);
  final reverse = List<GridPos>.of(points.reversed, growable: false);
  return List<GridPos>.unmodifiable(
    _comparePointSequences(forward, reverse) <= 0 ? forward : reverse,
  );
}

List<GridPos> _minimumClosedRotation(List<GridPos> points) {
  final forward = List<GridPos>.of(points, growable: false);
  final reverse = List<GridPos>.of(points.reversed, growable: false);
  final forwardRotation = _rotateFrom(
    forward,
    _minimumRotationIndex(forward),
  );
  final reverseRotation = _rotateFrom(
    reverse,
    _minimumRotationIndex(reverse),
  );
  return List<GridPos>.unmodifiable(
    _comparePointSequences(forwardRotation, reverseRotation) <= 0
        ? forwardRotation
        : reverseRotation,
  );
}

/// Booth's minimum-rotation search specialized to the row-major point order.
///
/// Each candidate start is discarded once, so closed-stroke
/// canonicalization stays linear even for long authored cycles.
int _minimumRotationIndex(List<GridPos> points) {
  final length = points.length;
  var first = 0;
  var second = 1;
  var matched = 0;
  while (first < length && second < length && matched < length) {
    final comparison = _comparePoint(
      points[(first + matched) % length],
      points[(second + matched) % length],
    );
    if (comparison == 0) {
      matched += 1;
      continue;
    }
    if (comparison > 0) {
      first += matched + 1;
      if (first <= second) first = second + 1;
    } else {
      second += matched + 1;
      if (second <= first) second = first + 1;
    }
    matched = 0;
  }
  final result = first < second ? first : second;
  return result < length ? result : 0;
}

List<GridPos> _rotateFrom(List<GridPos> points, int offset) =>
    List<GridPos>.generate(
      points.length,
      (index) => points[(offset + index) % points.length],
      growable: false,
    );

int _comparePointSequences(List<GridPos> left, List<GridPos> right) {
  final commonLength = left.length < right.length ? left.length : right.length;
  for (var index = 0; index < commonLength; index += 1) {
    final comparison = _comparePoint(left[index], right[index]);
    if (comparison != 0) {
      return comparison;
    }
  }
  return left.length.compareTo(right.length);
}

int _comparePoint(GridPos left, GridPos right) {
  final rowComparison = left.y.compareTo(right.y);
  return rowComparison != 0 ? rowComparison : left.x.compareTo(right.x);
}

bool _areCardinallyAdjacent(GridPos first, GridPos second) {
  final deltaX = BigInt.from(first.x) - BigInt.from(second.x);
  final deltaY = BigInt.from(first.y) - BigInt.from(second.y);
  return deltaX.abs() + deltaY.abs() == BigInt.one;
}
