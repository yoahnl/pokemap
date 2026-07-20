import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');

/// Semantic orientation of one canonical region contour.
enum BorderRegionContourKind {
  /// Clockwise in screen coordinates, with filled land on the right.
  landBoundary,

  /// Counter-clockwise in screen coordinates, with filled land on the right.
  holeBoundary,
}

/// Turn taken from one contour edge to the next.
enum BorderContourTurn { right, straight, left, uTurn }

/// One unit-cell boundary edge in a canonical region contour.
///
/// [direction] is the tangent direction. [outwardSide] is always its left
/// side, because every contour keeps the filled region on its right.
@immutable
final class BorderRegionContourEdge {
  BorderRegionContourEdge({
    required this.startVertex,
    required this.endVertex,
    required this.startWorldPx,
    required this.endWorldPx,
    required this.interiorCell,
    required this.direction,
    required this.outwardSide,
    required this.turnToNext,
    required this.startAbscissaPx,
    required this.endAbscissaPx,
  }) {
    _requirePortableInt(startVertex.x, 'startVertex.x');
    _requirePortableInt(startVertex.y, 'startVertex.y');
    _requirePortableInt(endVertex.x, 'endVertex.x');
    _requirePortableInt(endVertex.y, 'endVertex.y');
    _requirePortableInt(startWorldPx.x, 'startWorldPx.x');
    _requirePortableInt(startWorldPx.y, 'startWorldPx.y');
    _requirePortableInt(endWorldPx.x, 'endWorldPx.x');
    _requirePortableInt(endWorldPx.y, 'endWorldPx.y');
    _requirePortableInt(interiorCell.x, 'interiorCell.x');
    _requirePortableInt(interiorCell.y, 'interiorCell.y');
    _requirePortableInt(startAbscissaPx, 'startAbscissaPx');
    _requirePortableInt(endAbscissaPx, 'endAbscissaPx');
    if (startVertex == endVertex) {
      throw const ValidationException(
        'BorderRegionContourEdge vertices must be distinct',
      );
    }
    final vertexDx = BigInt.from(endVertex.x) - BigInt.from(startVertex.x);
    final vertexDy = BigInt.from(endVertex.y) - BigInt.from(startVertex.y);
    if (vertexDx.abs() + vertexDy.abs() != BigInt.one) {
      throw const ValidationException(
        'BorderRegionContourEdge must span one cardinal grid edge',
      );
    }
    if (_directionBetween(startVertex, endVertex) != direction ||
        outwardSide != _leftOf(direction) ||
        interiorCell != _interiorCellOnRight(startVertex, direction)) {
      throw const ValidationException(
        'BorderRegionContourEdge must keep its interior cell on the right',
      );
    }
    if (startAbscissaPx < 0 || endAbscissaPx <= startAbscissaPx) {
      throw const ValidationException(
        'BorderRegionContourEdge abscissas must form a positive interval',
      );
    }
    final worldDx = BigInt.from(endWorldPx.x) - BigInt.from(startWorldPx.x);
    final worldDy = BigInt.from(endWorldPx.y) - BigInt.from(startWorldPx.y);
    final worldDistance = worldDx.abs() + worldDy.abs();
    if (_directionBetweenDeltas(worldDx, worldDy) != direction ||
        worldDistance != BigInt.from(lengthPx)) {
      throw const ValidationException(
        'BorderRegionContourEdge world length must match its abscissa',
      );
    }
  }

  final GridPos startVertex;
  final GridPos endVertex;
  final BorderPixelPos startWorldPx;
  final BorderPixelPos endWorldPx;
  final GridPos interiorCell;
  final BorderCardinalDirection direction;
  final BorderCardinalDirection outwardSide;
  final BorderContourTurn turnToNext;
  final int startAbscissaPx;
  final int endAbscissaPx;

  int get lengthPx => endAbscissaPx - startAbscissaPx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderRegionContourEdge &&
          startVertex == other.startVertex &&
          endVertex == other.endVertex &&
          startWorldPx == other.startWorldPx &&
          endWorldPx == other.endWorldPx &&
          interiorCell == other.interiorCell &&
          direction == other.direction &&
          outwardSide == other.outwardSide &&
          turnToNext == other.turnToNext &&
          startAbscissaPx == other.startAbscissaPx &&
          endAbscissaPx == other.endAbscissaPx;

  @override
  int get hashCode => Object.hash(
        startVertex,
        endVertex,
        startWorldPx,
        endWorldPx,
        interiorCell,
        direction,
        outwardSide,
        turnToNext,
        startAbscissaPx,
        endAbscissaPx,
      );
}

/// One immutable canonical loop extracted from a region mask.
@immutable
final class BorderRegionContour {
  BorderRegionContour({
    required this.kind,
    required List<BorderRegionContourEdge> edges,
    required this.perimeterPx,
  }) : _edges = List<BorderRegionContourEdge>.unmodifiable(edges) {
    _requirePortableInt(perimeterPx, 'perimeterPx');
    if (_edges.isEmpty) {
      throw const ValidationException(
        'BorderRegionContour.edges must not be empty',
      );
    }
    if (perimeterPx <= 0 || _edges.first.startAbscissaPx != 0) {
      throw const ValidationException(
        'BorderRegionContour perimeter must be a positive zero-based range',
      );
    }
    final edgeKeys = <(GridPos, GridPos)>{};
    for (var index = 0; index < _edges.length; index += 1) {
      final edge = _edges[index];
      final next = _edges[(index + 1) % _edges.length];
      if (!edgeKeys.add(_undirectedEdgeKey(edge))) {
        throw const ValidationException(
          'BorderRegionContour must not reuse an edge',
        );
      }
      if (_classifyTurn(edge.direction, next.direction) != edge.turnToNext) {
        throw const ValidationException(
          'BorderRegionContour turn metadata must match adjacent edges',
        );
      }
      if (edge.endVertex != next.startVertex ||
          edge.endWorldPx != next.startWorldPx) {
        throw const ValidationException(
          'BorderRegionContour edges must form a closed continuous loop',
        );
      }
      if (index + 1 < _edges.length &&
          edge.endAbscissaPx != next.startAbscissaPx) {
        throw const ValidationException(
          'BorderRegionContour abscissas must be contiguous',
        );
      }
    }
    if (_edges.last.endAbscissaPx != perimeterPx) {
      throw const ValidationException(
        'BorderRegionContour perimeter must equal its final abscissa',
      );
    }
    for (final edge in _edges.skip(1)) {
      if (_comparePublicEdges(edge, _edges.first) < 0) {
        throw const ValidationException(
          'BorderRegionContour must start at its minimal canonical edge',
        );
      }
    }
    final signedAreaTwice = _signedAreaTwiceFromPublicEdges(_edges);
    if (signedAreaTwice == BigInt.zero ||
        (signedAreaTwice > BigInt.zero) !=
            (kind == BorderRegionContourKind.landBoundary)) {
      throw const ValidationException(
        'BorderRegionContour kind must match its signed screen-space area',
      );
    }
  }

  final BorderRegionContourKind kind;
  final List<BorderRegionContourEdge> _edges;
  final int perimeterPx;

  List<BorderRegionContourEdge> get edges => _edges;

  BorderPixelPos get originWorldPx => _edges.first.startWorldPx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderRegionContour &&
          kind == other.kind &&
          perimeterPx == other.perimeterPx &&
          _listsEqual(_edges, other._edges);

  @override
  int get hashCode => Object.hash(kind, perimeterPx, Object.hashAll(_edges));
}

/// Extracts deterministic oriented contours from a row-major filled mask.
///
/// Every exposed unit edge keeps the filled cell on its right. At an
/// ambiguous vertex the next edge is chosen with the fixed priority right,
/// straight, left, then U-turn. This keeps diagonal land cells in separate
/// loops. Conversely, diagonally touching holes may intentionally form one
/// self-touching loop; the loop still never reuses an edge.
List<BorderRegionContour> extractCanonicalBorderRegionContours({
  required BorderRegionGeometry region,
  required GridSize tileSizePx,
}) {
  if (tileSizePx.width <= 0 || tileSizePx.height <= 0) {
    throw const ValidationException(
      'Border contour tile dimensions must be > 0',
    );
  }
  _requirePortableInt(tileSizePx.width, 'tileSizePx.width');
  _requirePortableInt(tileSizePx.height, 'tileSizePx.height');

  final boundaryEdges = _extractBoundaryEdges(region)..sort(_compareEdges);
  if (boundaryEdges.isEmpty) {
    return const <BorderRegionContour>[];
  }

  final outgoing = <GridPos, List<_BoundaryEdge>>{};
  for (final edge in boundaryEdges) {
    outgoing.putIfAbsent(edge.startVertex, () => <_BoundaryEdge>[]).add(edge);
  }
  for (final edges in outgoing.values) {
    edges.sort(_compareEdges);
  }

  final visited = <_BoundaryEdge>{};
  final contours = <BorderRegionContour>[];
  for (final start in boundaryEdges) {
    if (visited.contains(start)) {
      continue;
    }
    final rawLoop = _traceLoop(
      start: start,
      outgoing: outgoing,
      visited: visited,
      totalEdgeCount: boundaryEdges.length,
    );
    contours.add(_materializeLoop(rawLoop, tileSizePx));
  }

  return List<BorderRegionContour>.unmodifiable(contours);
}

List<_BoundaryEdge> _extractBoundaryEdges(BorderRegionGeometry region) {
  final result = <_BoundaryEdge>[];
  for (var y = 0; y < region.height; y += 1) {
    for (var x = 0; x < region.width; x += 1) {
      if (!_isFilled(region, x, y)) {
        continue;
      }
      final interiorCell = GridPos(x: x, y: y);
      if (!_isFilled(region, x, y - 1)) {
        result.add(
          _BoundaryEdge(
            startVertex: GridPos(x: x, y: y),
            endVertex: GridPos(x: x + 1, y: y),
            interiorCell: interiorCell,
            direction: BorderCardinalDirection.east,
          ),
        );
      }
      if (!_isFilled(region, x + 1, y)) {
        result.add(
          _BoundaryEdge(
            startVertex: GridPos(x: x + 1, y: y),
            endVertex: GridPos(x: x + 1, y: y + 1),
            interiorCell: interiorCell,
            direction: BorderCardinalDirection.south,
          ),
        );
      }
      if (!_isFilled(region, x, y + 1)) {
        result.add(
          _BoundaryEdge(
            startVertex: GridPos(x: x + 1, y: y + 1),
            endVertex: GridPos(x: x, y: y + 1),
            interiorCell: interiorCell,
            direction: BorderCardinalDirection.west,
          ),
        );
      }
      if (!_isFilled(region, x - 1, y)) {
        result.add(
          _BoundaryEdge(
            startVertex: GridPos(x: x, y: y + 1),
            endVertex: GridPos(x: x, y: y),
            interiorCell: interiorCell,
            direction: BorderCardinalDirection.north,
          ),
        );
      }
    }
  }
  return result;
}

List<_BoundaryEdge> _traceLoop({
  required _BoundaryEdge start,
  required Map<GridPos, List<_BoundaryEdge>> outgoing,
  required Set<_BoundaryEdge> visited,
  required int totalEdgeCount,
}) {
  final result = <_BoundaryEdge>[];
  var current = start;

  while (true) {
    if (!visited.add(current)) {
      throw StateError('Border contour attempted to reuse an edge');
    }
    result.add(current);
    if (result.length > totalEdgeCount) {
      throw StateError('Border contour did not close');
    }

    final next = _chooseNextEdge(
      current: current,
      start: start,
      candidates: outgoing[current.endVertex] ?? const <_BoundaryEdge>[],
      visited: visited,
    );
    if (next == null) {
      throw StateError('Border contour has an open boundary');
    }
    if (identical(next, start)) {
      return result;
    }
    current = next;
  }
}

_BoundaryEdge? _chooseNextEdge({
  required _BoundaryEdge current,
  required _BoundaryEdge start,
  required List<_BoundaryEdge> candidates,
  required Set<_BoundaryEdge> visited,
}) {
  _BoundaryEdge? best;
  var bestPriority = 5;
  for (final candidate in candidates) {
    if (!identical(candidate, start) && visited.contains(candidate)) {
      continue;
    }
    final priority = _turnPriority(current.direction, candidate.direction);
    if (priority < bestPriority ||
        (priority == bestPriority &&
            best != null &&
            _compareEdges(candidate, best) < 0)) {
      best = candidate;
      bestPriority = priority;
    }
  }
  return best;
}

BorderRegionContour _materializeLoop(
  List<_BoundaryEdge> rawLoop,
  GridSize tileSizePx,
) {
  var abscissaPx = BigInt.zero;
  final edges = <BorderRegionContourEdge>[];
  for (var index = 0; index < rawLoop.length; index += 1) {
    final raw = rawLoop[index];
    final next = rawLoop[(index + 1) % rawLoop.length];
    final lengthPx = switch (raw.direction) {
      BorderCardinalDirection.east ||
      BorderCardinalDirection.west =>
        tileSizePx.width,
      BorderCardinalDirection.south ||
      BorderCardinalDirection.north =>
        tileSizePx.height,
    };
    final endAbscissaPx = abscissaPx + BigInt.from(lengthPx);
    if (endAbscissaPx > _maximumPortableJsonInteger) {
      throw const ValidationException(
        'Border contour perimeter exceeds the portable integer range',
      );
    }
    edges.add(
      BorderRegionContourEdge(
        startVertex: raw.startVertex,
        endVertex: raw.endVertex,
        startWorldPx: _toWorld(raw.startVertex, tileSizePx),
        endWorldPx: _toWorld(raw.endVertex, tileSizePx),
        interiorCell: raw.interiorCell,
        direction: raw.direction,
        outwardSide: _leftOf(raw.direction),
        turnToNext: _classifyTurn(raw.direction, next.direction),
        startAbscissaPx: abscissaPx.toInt(),
        endAbscissaPx: endAbscissaPx.toInt(),
      ),
    );
    abscissaPx = endAbscissaPx;
  }

  final signedAreaTwice = _signedAreaTwice(rawLoop);
  if (signedAreaTwice == BigInt.zero) {
    throw StateError('Border contour has zero signed area');
  }
  return BorderRegionContour(
    kind: signedAreaTwice > BigInt.zero
        ? BorderRegionContourKind.landBoundary
        : BorderRegionContourKind.holeBoundary,
    edges: edges,
    perimeterPx: abscissaPx.toInt(),
  );
}

BigInt _signedAreaTwice(List<_BoundaryEdge> loop) {
  var result = BigInt.zero;
  for (final edge in loop) {
    result += BigInt.from(edge.startVertex.x) * BigInt.from(edge.endVertex.y) -
        BigInt.from(edge.endVertex.x) * BigInt.from(edge.startVertex.y);
  }
  return result;
}

BorderPixelPos _toWorld(GridPos vertex, GridSize tileSizePx) {
  final x = BigInt.from(vertex.x) * BigInt.from(tileSizePx.width);
  final y = BigInt.from(vertex.y) * BigInt.from(tileSizePx.height);
  if (x.abs() > _maximumPortableJsonInteger ||
      y.abs() > _maximumPortableJsonInteger) {
    throw const ValidationException(
      'Border contour world position exceeds the portable integer range',
    );
  }
  return BorderPixelPos(x: x.toInt(), y: y.toInt());
}

bool _isFilled(BorderRegionGeometry region, int x, int y) =>
    x >= 0 &&
    y >= 0 &&
    x < region.width &&
    y < region.height &&
    region.cells[y * region.width + x];

int _compareEdges(_BoundaryEdge left, _BoundaryEdge right) {
  final y = left.startVertex.y.compareTo(right.startVertex.y);
  if (y != 0) {
    return y;
  }
  final x = left.startVertex.x.compareTo(right.startVertex.x);
  if (x != 0) {
    return x;
  }
  return borderCardinalDirectionV1Rank(left.direction)
      .compareTo(borderCardinalDirectionV1Rank(right.direction));
}

int _comparePublicEdges(
  BorderRegionContourEdge left,
  BorderRegionContourEdge right,
) {
  final y = left.startVertex.y.compareTo(right.startVertex.y);
  if (y != 0) {
    return y;
  }
  final x = left.startVertex.x.compareTo(right.startVertex.x);
  if (x != 0) {
    return x;
  }
  return borderCardinalDirectionV1Rank(left.direction)
      .compareTo(borderCardinalDirectionV1Rank(right.direction));
}

(GridPos, GridPos) _undirectedEdgeKey(BorderRegionContourEdge edge) =>
    _compareVertices(edge.startVertex, edge.endVertex) <= 0
        ? (edge.startVertex, edge.endVertex)
        : (edge.endVertex, edge.startVertex);

int _compareVertices(GridPos left, GridPos right) {
  final y = left.y.compareTo(right.y);
  return y != 0 ? y : left.x.compareTo(right.x);
}

int _turnDelta(
  BorderCardinalDirection from,
  BorderCardinalDirection to,
) =>
    (borderCardinalDirectionV1Rank(to) -
        borderCardinalDirectionV1Rank(from) +
        4) %
    4;

int _turnPriority(
  BorderCardinalDirection from,
  BorderCardinalDirection to,
) =>
    switch (_turnDelta(from, to)) {
      1 => 0,
      0 => 1,
      3 => 2,
      2 => 3,
      _ => throw StateError('Unreachable cardinal turn'),
    };

BorderContourTurn _classifyTurn(
  BorderCardinalDirection from,
  BorderCardinalDirection to,
) =>
    switch (_turnDelta(from, to)) {
      1 => BorderContourTurn.right,
      0 => BorderContourTurn.straight,
      3 => BorderContourTurn.left,
      2 => BorderContourTurn.uTurn,
      _ => throw StateError('Unreachable cardinal turn'),
    };

BorderCardinalDirection _leftOf(BorderCardinalDirection direction) =>
    switch (direction) {
      BorderCardinalDirection.east => BorderCardinalDirection.north,
      BorderCardinalDirection.south => BorderCardinalDirection.east,
      BorderCardinalDirection.west => BorderCardinalDirection.south,
      BorderCardinalDirection.north => BorderCardinalDirection.west,
    };

BorderCardinalDirection _directionBetween(GridPos start, GridPos end) =>
    _directionBetweenDeltas(
      BigInt.from(end.x) - BigInt.from(start.x),
      BigInt.from(end.y) - BigInt.from(start.y),
    );

BorderCardinalDirection _directionBetweenDeltas(BigInt dx, BigInt dy) {
  if (dx > BigInt.zero && dy == BigInt.zero) {
    return BorderCardinalDirection.east;
  }
  if (dx == BigInt.zero && dy > BigInt.zero) {
    return BorderCardinalDirection.south;
  }
  if (dx < BigInt.zero && dy == BigInt.zero) {
    return BorderCardinalDirection.west;
  }
  if (dx == BigInt.zero && dy < BigInt.zero) {
    return BorderCardinalDirection.north;
  }
  throw const ValidationException('Border contour edge must be cardinal');
}

GridPos _interiorCellOnRight(
  GridPos start,
  BorderCardinalDirection direction,
) =>
    switch (direction) {
      BorderCardinalDirection.east => GridPos(x: start.x, y: start.y),
      BorderCardinalDirection.south => GridPos(x: start.x - 1, y: start.y),
      BorderCardinalDirection.west => GridPos(x: start.x - 1, y: start.y - 1),
      BorderCardinalDirection.north => GridPos(x: start.x, y: start.y - 1),
    };

BigInt _signedAreaTwiceFromPublicEdges(
  List<BorderRegionContourEdge> edges,
) {
  var result = BigInt.zero;
  for (final edge in edges) {
    result += BigInt.from(edge.startVertex.x) * BigInt.from(edge.endVertex.y) -
        BigInt.from(edge.endVertex.x) * BigInt.from(edge.startVertex.y);
  }
  return result;
}

void _requirePortableInt(int value, String field) {
  if (BigInt.from(value).abs() > _maximumPortableJsonInteger) {
    throw ValidationException(
      'Border contour $field must fit the portable integer range',
    );
  }
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

final class _BoundaryEdge {
  const _BoundaryEdge({
    required this.startVertex,
    required this.endVertex,
    required this.interiorCell,
    required this.direction,
  });

  final GridPos startVertex;
  final GridPos endVertex;
  final GridPos interiorCell;
  final BorderCardinalDirection direction;
}
