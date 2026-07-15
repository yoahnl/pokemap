import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_stroke_canonicalization.dart';

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');

/// Closed V1 vocabulary for a node on a linear Border stroke.
enum BorderLinearNodeKind { endpoint, straight, corner }

/// Explicit cap/termination need for an open stroke endpoint.
enum BorderLinearTerminationNeed { none, startCap, endCap }

/// One canonical stroke node and the structural need at that node.
@immutable
final class BorderLinearNodeNeed {
  const BorderLinearNodeNeed._({
    required this.index,
    required this.cell,
    required this.abscissaPx,
    required this.kind,
    required this.termination,
    required this.incomingDirection,
    required this.outgoingDirection,
  });

  final int index;
  final GridPos cell;
  final int abscissaPx;
  final BorderLinearNodeKind kind;
  final BorderLinearTerminationNeed termination;
  final BorderCardinalDirection? incomingDirection;
  final BorderCardinalDirection? outgoingDirection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderLinearNodeNeed &&
          index == other.index &&
          cell == other.cell &&
          abscissaPx == other.abscissaPx &&
          kind == other.kind &&
          termination == other.termination &&
          incomingDirection == other.incomingDirection &&
          outgoingDirection == other.outgoingDirection;

  @override
  int get hashCode => Object.hash(
        index,
        cell,
        abscissaPx,
        kind,
        termination,
        incomingDirection,
        outgoingDirection,
      );
}

/// One unit-cardinal edge of a canonical linear Border lattice.
@immutable
final class BorderLinearEdge {
  const BorderLinearEdge._({
    required this.index,
    required this.startNodeIndex,
    required this.endNodeIndex,
    required this.startCell,
    required this.endCell,
    required this.direction,
    required this.startAbscissaPx,
    required this.endAbscissaPx,
  });

  final int index;
  final int startNodeIndex;
  final int endNodeIndex;
  final GridPos startCell;
  final GridPos endCell;
  final BorderCardinalDirection direction;
  final int startAbscissaPx;
  final int endAbscissaPx;

  int get lengthPx => endAbscissaPx - startAbscissaPx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderLinearEdge &&
          index == other.index &&
          startNodeIndex == other.startNodeIndex &&
          endNodeIndex == other.endNodeIndex &&
          startCell == other.startCell &&
          endCell == other.endCell &&
          direction == other.direction &&
          startAbscissaPx == other.startAbscissaPx &&
          endAbscissaPx == other.endAbscissaPx;

  @override
  int get hashCode => Object.hash(
        index,
        startNodeIndex,
        endNodeIndex,
        startCell,
        endCell,
        direction,
        startAbscissaPx,
        endAbscissaPx,
      );
}

/// Immutable deterministic lattice for one canonical V1 stroke.
@immutable
final class BorderLinearStrokeLattice {
  BorderLinearStrokeLattice._({
    required this.strokeId,
    required this.closed,
    required List<BorderLinearNodeNeed> nodes,
    required List<BorderLinearEdge> edges,
    required this.totalLengthPx,
  })  : _nodes = List<BorderLinearNodeNeed>.unmodifiable(nodes),
        _edges = List<BorderLinearEdge>.unmodifiable(edges);

  final String strokeId;
  final bool closed;
  final List<BorderLinearNodeNeed> _nodes;
  final List<BorderLinearEdge> _edges;
  final int totalLengthPx;

  List<BorderLinearNodeNeed> get nodes => _nodes;
  List<BorderLinearEdge> get edges => _edges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderLinearStrokeLattice &&
          strokeId == other.strokeId &&
          closed == other.closed &&
          totalLengthPx == other.totalLengthPx &&
          _listsEqual(_nodes, other._nodes) &&
          _listsEqual(_edges, other._edges);

  @override
  int get hashCode => Object.hash(
        strokeId,
        closed,
        totalLengthPx,
        Object.hashAll(_nodes),
        Object.hashAll(_edges),
      );
}

/// Builds the unit-edge lattice and integer pixel abscissa for [stroke].
///
/// Horizontal edges contribute `tileSizePx.width`; vertical edges contribute
/// `tileSizePx.height`. Closed strokes append their implicit closing edge and
/// use a circular domain whose end abscissa is [BorderLinearStrokeLattice.totalLengthPx].
BorderLinearStrokeLattice buildBorderLinearLatticeV1({
  required BorderStroke stroke,
  required GridSize tileSizePx,
}) {
  if (tileSizePx.width <= 0 || tileSizePx.height <= 0) {
    throw const ValidationException(
      'Border linear lattice tile dimensions must be > 0',
    );
  }
  _requirePortableInt(tileSizePx.width, 'tileSizePx.width');
  _requirePortableInt(tileSizePx.height, 'tileSizePx.height');

  final canonical = canonicalizeBorderStrokeV1(
    id: stroke.id,
    sampledPoints: stroke.points,
    closed: stroke.closed,
  );
  final points = canonical.points;
  final edgeCount = canonical.closed ? points.length : points.length - 1;
  var abscissa = BigInt.zero;
  final edges = <BorderLinearEdge>[];

  for (var index = 0; index < edgeCount; index += 1) {
    final endIndex = (index + 1) % points.length;
    final start = points[index];
    final end = points[endIndex];
    final direction = _directionBetween(start, end);
    final length = switch (direction) {
      BorderCardinalDirection.east ||
      BorderCardinalDirection.west =>
        tileSizePx.width,
      BorderCardinalDirection.south ||
      BorderCardinalDirection.north =>
        tileSizePx.height,
    };
    final endAbscissa = abscissa + BigInt.from(length);
    if (endAbscissa > _maximumPortableJsonInteger) {
      throw const ValidationException(
        'Border linear lattice length exceeds the portable integer range',
      );
    }
    edges.add(
      BorderLinearEdge._(
        index: index,
        startNodeIndex: index,
        endNodeIndex: endIndex,
        startCell: start,
        endCell: end,
        direction: direction,
        startAbscissaPx: abscissa.toInt(),
        endAbscissaPx: endAbscissa.toInt(),
      ),
    );
    abscissa = endAbscissa;
  }

  final nodes = <BorderLinearNodeNeed>[];
  for (var index = 0; index < points.length; index += 1) {
    final incoming = index > 0
        ? edges[index - 1].direction
        : canonical.closed
            ? edges.last.direction
            : null;
    final outgoing = index < edges.length ? edges[index].direction : null;
    final endpoint = incoming == null || outgoing == null;
    final kind = endpoint
        ? BorderLinearNodeKind.endpoint
        : incoming == outgoing
            ? BorderLinearNodeKind.straight
            : BorderLinearNodeKind.corner;
    final termination = incoming == null
        ? BorderLinearTerminationNeed.startCap
        : outgoing == null
            ? BorderLinearTerminationNeed.endCap
            : BorderLinearTerminationNeed.none;
    final nodeAbscissa = index == 0 ? 0 : edges[index - 1].endAbscissaPx;
    nodes.add(
      BorderLinearNodeNeed._(
        index: index,
        cell: points[index],
        abscissaPx: nodeAbscissa,
        kind: kind,
        termination: termination,
        incomingDirection: incoming,
        outgoingDirection: outgoing,
      ),
    );
  }

  return BorderLinearStrokeLattice._(
    strokeId: canonical.id,
    closed: canonical.closed,
    nodes: nodes,
    edges: edges,
    totalLengthPx: abscissa.toInt(),
  );
}

BorderCardinalDirection _directionBetween(GridPos start, GridPos end) {
  final deltaX = BigInt.from(end.x) - BigInt.from(start.x);
  final deltaY = BigInt.from(end.y) - BigInt.from(start.y);
  if (deltaX == BigInt.one && deltaY == BigInt.zero) {
    return BorderCardinalDirection.east;
  }
  if (deltaX == BigInt.zero && deltaY == BigInt.one) {
    return BorderCardinalDirection.south;
  }
  if (deltaX == -BigInt.one && deltaY == BigInt.zero) {
    return BorderCardinalDirection.west;
  }
  if (deltaX == BigInt.zero && deltaY == -BigInt.one) {
    return BorderCardinalDirection.north;
  }
  throw const ValidationException(
    'Border linear lattice edges must be unit-cardinal',
  );
}

void _requirePortableInt(int value, String field) {
  final exact = BigInt.from(value);
  if (exact.abs() > _maximumPortableJsonInteger) {
    throw ValidationException(
      'Border linear lattice $field exceeds the portable integer range',
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
