import 'dart:convert' show jsonEncode, utf8;

import 'package:crypto/crypto.dart' show sha256;
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_stroke_canonicalization.dart';

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');
final RegExp _strokeFragmentSuffix = RegExp(
  r'^(.*)__fragment_(?:[2-9]|[1-9][0-9]+)$',
);
const String _preservedLineageMarker = '__border_lineage_v1_p1_';
final RegExp _preservedLineageId = RegExp(
  r'^(.*)__border_lineage_v1_p1_o([0-9]+)_w(n|[1-9][0-9]*)_h([0-9a-f]{64})$',
);

/// Verified editor-owned lineage metadata carried by a stroke ID.
@immutable
final class BorderStrokeLineageIdentityV1 {
  const BorderStrokeLineageIdentityV1._({
    required this.authoredStrokeId,
    required this.lineageNamespace,
    required this.sourceEdgeOffset,
    required this.wrapLength,
    required this.preserveTraversal,
  });

  /// Human-meaningful stroke/fragment ID without the control suffix.
  final String authoredStrokeId;

  /// Stable original root used by deterministic generation.
  final String lineageNamespace;

  /// Index of local edge zero in the original lineage domain.
  final int sourceEdgeOffset;

  /// Original circular edge count, or `null` for an open source lineage.
  final int? wrapLength;

  /// Whether the stored point order is authoritative and must not be flipped.
  final bool preserveTraversal;
}

/// Builds a checksummed editor-owned ID for one traversal-preserved fragment.
String buildBorderPreservedStrokeIdV1({
  required String authoredStrokeId,
  required int sourceEdgeOffset,
  required int? wrapLength,
  required List<GridPos> orderedPoints,
}) {
  if (authoredStrokeId.trim().isEmpty ||
      authoredStrokeId != authoredStrokeId.trim() ||
      authoredStrokeId.contains(_preservedLineageMarker)) {
    throw const ValidationException(
      'Preserved Border authored stroke ID is invalid',
    );
  }
  _requirePortableNonNegative(sourceEdgeOffset, 'sourceEdgeOffset');
  if (wrapLength != null) {
    if (wrapLength <= 0 || sourceEdgeOffset >= wrapLength) {
      throw const ValidationException(
        'Preserved Border wrap metadata is invalid',
      );
    }
    _requirePortableInt(wrapLength, 'wrapLength');
  }
  if (orderedPoints.length < 2) {
    throw const ValidationException(
      'Preserved Border fragment requires at least two points',
    );
  }
  final wrapWire = wrapLength?.toString() ?? 'n';
  final checksum = _preservedLineageChecksum(
    authoredStrokeId: authoredStrokeId,
    sourceEdgeOffset: sourceEdgeOffset,
    wrapLength: wrapLength,
    orderedPoints: orderedPoints,
  );
  return '$authoredStrokeId$_preservedLineageMarker'
      'o${sourceEdgeOffset}_w${wrapWire}_h$checksum';
}

/// Resolves and verifies lineage control metadata for [stroke].
BorderStrokeLineageIdentityV1 resolveBorderStrokeLineageIdentityV1(
  BorderStroke stroke,
) {
  final match = _preservedLineageId.firstMatch(stroke.id);
  if (match == null) {
    if (stroke.id.contains(_preservedLineageMarker)) {
      throw const ValidationException(
        'Border preserved lineage marker is malformed',
      );
    }
    return BorderStrokeLineageIdentityV1._(
      authoredStrokeId: stroke.id,
      lineageNamespace: borderStrokeLineageNamespaceV1(stroke.id),
      sourceEdgeOffset: 0,
      wrapLength: null,
      preserveTraversal: false,
    );
  }

  final authoredStrokeId = match.group(1)!;
  final sourceEdgeOffset = _parsePortableNonNegative(
    match.group(2)!,
    'sourceEdgeOffset',
  );
  final wrapWire = match.group(3)!;
  final wrapLength =
      wrapWire == 'n' ? null : _parsePortablePositive(wrapWire, 'wrapLength');
  if (wrapLength != null && sourceEdgeOffset >= wrapLength) {
    throw const ValidationException(
      'Border preserved lineage offset must be inside its wrap domain',
    );
  }
  final expectedChecksum = _preservedLineageChecksum(
    authoredStrokeId: authoredStrokeId,
    sourceEdgeOffset: sourceEdgeOffset,
    wrapLength: wrapLength,
    orderedPoints: stroke.points,
  );
  if (match.group(4) != expectedChecksum) {
    throw const ValidationException(
      'Border preserved lineage checksum does not match its stroke',
    );
  }
  return BorderStrokeLineageIdentityV1._(
    authoredStrokeId: authoredStrokeId,
    lineageNamespace: borderStrokeLineageNamespaceV1(authoredStrokeId),
    sourceEdgeOffset: sourceEdgeOffset,
    wrapLength: wrapLength,
    preserveTraversal: true,
  );
}

/// Builds one fragment while composing its original traversal position.
BorderStroke buildBorderTraversalPreservedFragmentV1({
  required BorderStroke sourceStroke,
  required String authoredStrokeId,
  required int sourceStartIndex,
  required List<GridPos> orderedPoints,
}) {
  if (sourceStartIndex < 0 || sourceStartIndex >= sourceStroke.points.length) {
    throw const ValidationException(
      'Border preserved fragment source index is out of range',
    );
  }
  final sourceIdentity = resolveBorderStrokeLineageIdentityV1(sourceStroke);
  final wrapLength = sourceIdentity.wrapLength ??
      (sourceStroke.closed ? sourceStroke.points.length : null);
  var sourceEdgeOffset = sourceIdentity.sourceEdgeOffset + sourceStartIndex;
  if (wrapLength != null) {
    sourceEdgeOffset %= wrapLength;
  }
  final id = buildBorderPreservedStrokeIdV1(
    authoredStrokeId: authoredStrokeId,
    sourceEdgeOffset: sourceEdgeOffset,
    wrapLength: wrapLength,
    orderedPoints: orderedPoints,
  );
  canonicalizeBorderStrokeV1(
    id: id,
    sampledPoints: orderedPoints,
    closed: false,
  );
  return BorderStroke(
    id: id,
    points: orderedPoints,
    closed: false,
  );
}

/// Returns the authored portion without interpreting unverified metadata.
String borderStrokeAuthoredIdV1(String strokeId) =>
    _preservedLineageId.firstMatch(strokeId)?.group(1) ?? strokeId;

/// Returns the stable RNG/slot namespace shared by generated stroke fragments.
///
/// Erasing may split a stroke repeatedly. Authored fragment IDs remain unique,
/// while the resolver namespace keeps the original lineage so distant edges do
/// not receive new slots or variants merely because a local opening was made.
String borderStrokeLineageNamespaceV1(String strokeId) {
  var namespace = borderStrokeAuthoredIdV1(strokeId);
  while (true) {
    final match = _strokeFragmentSuffix.firstMatch(namespace);
    final parent = match?.group(1);
    if (parent == null || parent.isEmpty) return namespace;
    namespace = parent;
  }
}

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
    required this.generationEdgeIndex,
  });

  final int index;
  final int startNodeIndex;
  final int endNodeIndex;
  final GridPos startCell;
  final GridPos endCell;
  final BorderCardinalDirection direction;
  final int startAbscissaPx;
  final int endAbscissaPx;
  final int generationEdgeIndex;

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
          endAbscissaPx == other.endAbscissaPx &&
          generationEdgeIndex == other.generationEdgeIndex;

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
        generationEdgeIndex,
      );
}

/// Immutable deterministic lattice for one canonical V1 stroke.
@immutable
final class BorderLinearStrokeLattice {
  BorderLinearStrokeLattice._({
    required this.strokeId,
    required this.persistedStrokeId,
    required this.lineageNamespace,
    required this.sourceEdgeOffset,
    required this.wrapLength,
    required this.preservesTraversal,
    required this.closed,
    required List<BorderLinearNodeNeed> nodes,
    required List<BorderLinearEdge> edges,
    required this.totalLengthPx,
  })  : _nodes = List<BorderLinearNodeNeed>.unmodifiable(nodes),
        _edges = List<BorderLinearEdge>.unmodifiable(edges);

  /// Unique authored stroke/fragment identity used by diagnostics and grouping.
  final String strokeId;

  /// Exact persisted ID, including verified lineage control metadata.
  final String persistedStrokeId;

  /// Stable root identity used only by local RNG and generated slot keys.
  final String lineageNamespace;
  final int sourceEdgeOffset;
  final int? wrapLength;
  final bool preservesTraversal;
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
          persistedStrokeId == other.persistedStrokeId &&
          lineageNamespace == other.lineageNamespace &&
          sourceEdgeOffset == other.sourceEdgeOffset &&
          wrapLength == other.wrapLength &&
          preservesTraversal == other.preservesTraversal &&
          closed == other.closed &&
          totalLengthPx == other.totalLengthPx &&
          _listsEqual(_nodes, other._nodes) &&
          _listsEqual(_edges, other._edges);

  @override
  int get hashCode => Object.hash(
        strokeId,
        persistedStrokeId,
        lineageNamespace,
        sourceEdgeOffset,
        wrapLength,
        preservesTraversal,
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

  final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
  final validatedCanonical = canonicalizeBorderStrokeV1(
    id: stroke.id,
    sampledPoints: stroke.points,
    closed: stroke.closed,
  );
  final points =
      lineage.preserveTraversal ? stroke.points : validatedCanonical.points;
  final closed =
      lineage.preserveTraversal ? stroke.closed : validatedCanonical.closed;
  final edgeCount = closed ? points.length : points.length - 1;
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
    final sourceIndex =
        BigInt.from(lineage.sourceEdgeOffset) + BigInt.from(index);
    final generationEdgeIndex = lineage.wrapLength == null
        ? sourceIndex
        : sourceIndex % BigInt.from(lineage.wrapLength!);
    if (generationEdgeIndex > _maximumPortableJsonInteger) {
      throw const ValidationException(
        'Border generation edge index exceeds the portable integer range',
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
        generationEdgeIndex: generationEdgeIndex.toInt(),
      ),
    );
    abscissa = endAbscissa;
  }

  final nodes = <BorderLinearNodeNeed>[];
  for (var index = 0; index < points.length; index += 1) {
    final incoming = index > 0
        ? edges[index - 1].direction
        : closed
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
    strokeId: lineage.authoredStrokeId,
    persistedStrokeId: stroke.id,
    lineageNamespace: lineage.lineageNamespace,
    sourceEdgeOffset: lineage.sourceEdgeOffset,
    wrapLength: lineage.wrapLength,
    preservesTraversal: lineage.preserveTraversal,
    closed: closed,
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

void _requirePortableNonNegative(int value, String field) {
  if (value < 0) {
    throw ValidationException('Border linear lattice $field must be >= 0');
  }
  _requirePortableInt(value, field);
}

int _parsePortableNonNegative(String wire, String field) {
  final exact = BigInt.parse(wire);
  if (exact < BigInt.zero || exact > _maximumPortableJsonInteger) {
    throw ValidationException(
      'Border preserved lineage $field exceeds the portable integer range',
    );
  }
  return exact.toInt();
}

int _parsePortablePositive(String wire, String field) {
  final value = _parsePortableNonNegative(wire, field);
  if (value == 0) {
    throw ValidationException('Border preserved lineage $field must be > 0');
  }
  return value;
}

String _preservedLineageChecksum({
  required String authoredStrokeId,
  required int sourceEdgeOffset,
  required int? wrapLength,
  required List<GridPos> orderedPoints,
}) =>
    sha256
        .convert(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'version': 1,
              'authoredStrokeId': authoredStrokeId,
              'sourceEdgeOffset': sourceEdgeOffset,
              'wrapLength': wrapLength,
              'points': <List<int>>[
                for (final point in orderedPoints) <int>[point.x, point.y],
              ],
            }),
          ),
        )
        .toString();

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
