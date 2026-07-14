import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'geometry.dart';

/// Geometry families supported by Border features.
///
/// These models validate already-rasterized unit-cardinal data. They do not
/// canonicalize gesture direction or validate against a particular map size.
@immutable
sealed class BorderFeatureGeometry {
  const BorderFeatureGeometry();
}

/// Row-major filled-cell mask used by region Border templates.
@immutable
final class BorderRegionGeometry extends BorderFeatureGeometry {
  BorderRegionGeometry({
    required this.width,
    required this.height,
    required List<bool> cells,
  }) : _cells = List<bool>.unmodifiable(cells) {
    if (width <= 0) {
      throw const ValidationException(
        'BorderRegionGeometry.width must be > 0',
      );
    }
    if (height <= 0) {
      throw const ValidationException(
        'BorderRegionGeometry.height must be > 0',
      );
    }
    if (!_hasExactCellCount(
      width: width,
      height: height,
      actualLength: _cells.length,
    )) {
      throw const ValidationException(
        'BorderRegionGeometry.cells must contain exactly width * height '
        'entries',
      );
    }
  }

  final int width;
  final int height;
  final List<bool> _cells;

  List<bool> get cells => _cells;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderRegionGeometry &&
          width == other.width &&
          height == other.height &&
          _listsEqual(_cells, other._cells);

  @override
  int get hashCode => Object.hash(
        width,
        height,
        Object.hashAll(_cells),
      );
}

/// One persisted unit-cardinal stroke.
///
/// Input order is significant and is preserved. Canonical direction belongs
/// to the later stroke-canonicalization operation.
@immutable
final class BorderStroke {
  BorderStroke({
    required this.id,
    required List<GridPos> points,
    required this.closed,
  }) : _points = List<GridPos>.unmodifiable(
          points.map((point) => GridPos(x: point.x, y: point.y)),
        ) {
    _requireStableId(id, 'BorderStroke.id');
    _validatePointCount();
    _validateNoRepeatedCells();
    _validateEdges();
  }

  final String id;
  final List<GridPos> _points;
  final bool closed;

  List<GridPos> get points => _points;

  void _validatePointCount() {
    final minimum = closed ? 4 : 2;
    if (_points.length < minimum) {
      throw ValidationException(
        'BorderStroke.points must contain at least $minimum distinct points '
        'when closed is $closed',
      );
    }
    if (closed && _points.first == _points.last) {
      throw const ValidationException(
        'BorderStroke.points must not repeat the first point at the end',
      );
    }
  }

  void _validateNoRepeatedCells() {
    final seen = <GridPos>{};
    for (final point in _points) {
      if (!seen.add(point)) {
        throw const ValidationException(
          'BorderStroke.points must not repeat cells or backtrack',
        );
      }
    }
  }

  void _validateEdges() {
    for (var index = 1; index < _points.length; index += 1) {
      if (!_isCardinallyAdjacent(_points[index - 1], _points[index])) {
        throw const ValidationException(
          'BorderStroke consecutive points must be cardinally adjacent',
        );
      }
    }
    if (closed && !_isCardinallyAdjacent(_points.last, _points.first)) {
      throw const ValidationException(
        'BorderStroke closing points must be cardinally adjacent',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderStroke &&
          id == other.id &&
          closed == other.closed &&
          _listsEqual(_points, other._points);

  @override
  int get hashCode => Object.hash(
        id,
        Object.hashAll(_points),
        closed,
      );
}

/// Ordered collection of independent V1 strokes.
@immutable
final class BorderStrokeGeometry extends BorderFeatureGeometry {
  BorderStrokeGeometry({required List<BorderStroke> strokes})
      : _strokes = List<BorderStroke>.unmodifiable(strokes) {
    _validateIndependentStrokes();
  }

  final List<BorderStroke> _strokes;

  List<BorderStroke> get strokes => _strokes;

  void _validateIndependentStrokes() {
    final seenIds = <String>{};
    final occupiedCells = <GridPos>{};
    final occupiedEdges = <_GridEdgeKey>{};

    for (final stroke in _strokes) {
      if (!seenIds.add(stroke.id)) {
        throw ValidationException(
          'BorderStrokeGeometry.strokes must not contain duplicate ids: '
          '${stroke.id}',
        );
      }

      final strokeEdges = _edgesOf(stroke).toList(growable: false);
      for (final edge in strokeEdges) {
        if (occupiedEdges.contains(edge)) {
          throw ValidationException(
            'BorderStrokeGeometry.strokes must not share edges: '
            '${stroke.id}',
          );
        }
      }
      for (final point in stroke.points) {
        if (occupiedCells.contains(point)) {
          throw ValidationException(
            'BorderStrokeGeometry.strokes must not share cells: '
            '${stroke.id}',
          );
        }
      }

      occupiedEdges.addAll(strokeEdges);
      occupiedCells.addAll(stroke.points);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderStrokeGeometry && _listsEqual(_strokes, other._strokes);

  @override
  int get hashCode => Object.hashAll(_strokes);
}

/// Stable region excluded from Border resolution.
@immutable
final class BorderKeepOutRegion {
  BorderKeepOutRegion({required this.id, required this.region}) {
    _requireStableId(id, 'BorderKeepOutRegion.id');
  }

  final String id;
  final BorderRegionGeometry region;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderKeepOutRegion && id == other.id && region == other.region;

  @override
  int get hashCode => Object.hash(id, region);
}

typedef _GridEdgeKey = ({int firstX, int firstY, int secondX, int secondY});

bool _hasExactCellCount({
  required int width,
  required int height,
  required int actualLength,
}) {
  return actualLength ~/ width == height && actualLength % width == 0;
}

void _requireStableId(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
}

bool _isCardinallyAdjacent(GridPos first, GridPos second) {
  if (first.x == second.x) {
    return _orderedValuesAreAdjacent(first.y, second.y);
  }
  if (first.y == second.y) {
    return _orderedValuesAreAdjacent(first.x, second.x);
  }
  return false;
}

bool _orderedValuesAreAdjacent(int first, int second) {
  if (first < second) {
    return first + 1 == second;
  }
  if (second < first) {
    return second + 1 == first;
  }
  return false;
}

Iterable<_GridEdgeKey> _edgesOf(BorderStroke stroke) sync* {
  for (var index = 1; index < stroke.points.length; index += 1) {
    yield _edgeKey(stroke.points[index - 1], stroke.points[index]);
  }
  if (stroke.closed) {
    yield _edgeKey(stroke.points.last, stroke.points.first);
  }
}

_GridEdgeKey _edgeKey(GridPos first, GridPos second) {
  final firstComesFirst =
      first.y < second.y || (first.y == second.y && first.x <= second.x);
  final start = firstComesFirst ? first : second;
  final end = firstComesFirst ? second : first;
  return (
    firstX: start.x,
    firstY: start.y,
    secondX: end.x,
    secondY: end.y,
  );
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
