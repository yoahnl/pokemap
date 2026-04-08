import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:map_core/map_core.dart';

/// Converts author-drawn shapes into tile-grid collision cells.
///
/// This service is intentionally simple and deterministic:
/// - input shapes are expressed in grid space, not pixels
/// - output is always a list of [GridPos]
/// - no image analysis, no alpha sampling, no "smart" inference
///
/// Grid-space convention:
/// - `(0, 0)` is the top-left corner of the source rect
/// - `(width, height)` is the bottom-right corner
/// - a cell `(x, y)` occupies the rectangle `[x, x + 1] x [y, y + 1]`
class ElementCollisionShapeRasterizerService {
  const ElementCollisionShapeRasterizerService();

  /// Rasterizes a polygon into cells.
  ///
  /// We consider a cell selected when any of these is true:
  /// - the cell center is inside the polygon
  /// - a polygon vertex is inside the cell
  /// - a polygon edge intersects the cell rectangle
  ///
  /// This makes the tool feel much more natural than a strict "center only"
  /// fill, while still staying fully grid-based and predictable.
  List<GridPos> rasterizePolygon({
    required List<Offset> vertices,
    required int gridWidth,
    required int gridHeight,
  }) {
    if (vertices.length < 3 || gridWidth <= 0 || gridHeight <= 0) {
      return const <GridPos>[];
    }

    final normalizedVertices = vertices
        .map((point) =>
            _clampPoint(point, gridWidth: gridWidth, gridHeight: gridHeight))
        .toList(growable: false);
    final bounds = _polygonBounds(normalizedVertices);
    final minX =
        bounds.left.floor().clamp(0, math.max(0, gridWidth - 1)) as int;
    final minY =
        bounds.top.floor().clamp(0, math.max(0, gridHeight - 1)) as int;
    final maxX =
        (bounds.right.ceil() - 1).clamp(0, math.max(0, gridWidth - 1)) as int;
    final maxY =
        (bounds.bottom.ceil() - 1).clamp(0, math.max(0, gridHeight - 1)) as int;

    final cells = <GridPos>[];
    if (minX > maxX || minY > maxY) {
      return const <GridPos>[];
    }

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final cellRect = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
        if (_polygonTouchesCell(normalizedVertices, cellRect)) {
          cells.add(GridPos(x: x, y: y));
        }
      }
    }
    cells.sort(_compareCells);
    return cells;
  }

  /// Rasterizes a continuous brush stroke into cells.
  ///
  /// Each point is expressed in grid space. Consecutive points are connected
  /// with a grid line traversal so quick drags do not leave gaps.
  List<GridPos> rasterizeBrushStroke({
    required List<Offset> points,
    required int gridWidth,
    required int gridHeight,
  }) {
    if (points.isEmpty || gridWidth <= 0 || gridHeight <= 0) {
      return const <GridPos>[];
    }

    final normalizedPoints = points
        .map((point) =>
            _toCell(point, gridWidth: gridWidth, gridHeight: gridHeight))
        .toList(growable: false);
    final unique = <String, GridPos>{};
    for (var i = 0; i < normalizedPoints.length; i++) {
      final current = normalizedPoints[i];
      unique[_key(current)] = current;
      if (i == 0) {
        continue;
      }
      final previous = normalizedPoints[i - 1];
      for (final cell in _rasterizeSegment(previous, current)) {
        unique[_key(cell)] = cell;
      }
    }

    final cells = unique.values.toList(growable: false)..sort(_compareCells);
    return cells;
  }

  Rect _polygonBounds(List<Offset> vertices) {
    var minX = vertices.first.dx;
    var maxX = vertices.first.dx;
    var minY = vertices.first.dy;
    var maxY = vertices.first.dy;
    for (final vertex in vertices.skip(1)) {
      minX = math.min(minX, vertex.dx);
      maxX = math.max(maxX, vertex.dx);
      minY = math.min(minY, vertex.dy);
      maxY = math.max(maxY, vertex.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool _polygonTouchesCell(List<Offset> vertices, Rect cellRect) {
    final center = Offset(cellRect.left + 0.5, cellRect.top + 0.5);
    if (_pointInPolygon(center, vertices)) {
      return true;
    }

    // We intentionally test boundary interactions against a slightly deflated
    // cell rectangle. This prevents "border only" contact from filling a cell
    // that the polygon merely grazes on its edge, which keeps concave shapes
    // much closer to the author's visual intent.
    final interiorRect = cellRect.deflate(0.02);
    if (interiorRect.width <= 0 || interiorRect.height <= 0) {
      return false;
    }

    for (final vertex in vertices) {
      if (interiorRect.contains(vertex)) {
        return true;
      }
    }

    final cellEdges = <_Segment>[
      _Segment(interiorRect.topLeft, interiorRect.topRight),
      _Segment(interiorRect.topRight, interiorRect.bottomRight),
      _Segment(interiorRect.bottomRight, interiorRect.bottomLeft),
      _Segment(interiorRect.bottomLeft, interiorRect.topLeft),
    ];

    for (var i = 0; i < vertices.length; i++) {
      final start = vertices[i];
      final end = vertices[(i + 1) % vertices.length];
      final polygonEdge = _Segment(start, end);
      if (interiorRect.contains(start) || interiorRect.contains(end)) {
        return true;
      }
      for (final cellEdge in cellEdges) {
        if (_segmentsIntersect(polygonEdge, cellEdge)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _pointInPolygon(Offset point, List<Offset> vertices) {
    var inside = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final xi = vertices[i].dx;
      final yi = vertices[i].dy;
      final xj = vertices[j].dx;
      final yj = vertices[j].dy;
      final intersects = ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx <
              (xj - xi) *
                      (point.dy - yi) /
                      ((yj - yi) == 0 ? 1e-9 : (yj - yi)) +
                  xi);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  bool _segmentsIntersect(_Segment a, _Segment b) {
    final o1 = _orientation(a.start, a.end, b.start);
    final o2 = _orientation(a.start, a.end, b.end);
    final o3 = _orientation(b.start, b.end, a.start);
    final o4 = _orientation(b.start, b.end, a.end);

    if (o1 != o2 && o3 != o4) {
      return true;
    }

    if (o1 == 0 && _onSegment(a.start, b.start, a.end)) return true;
    if (o2 == 0 && _onSegment(a.start, b.end, a.end)) return true;
    if (o3 == 0 && _onSegment(b.start, a.start, b.end)) return true;
    if (o4 == 0 && _onSegment(b.start, a.end, b.end)) return true;

    return false;
  }

  int _orientation(Offset a, Offset b, Offset c) {
    final value = (b.dy - a.dy) * (c.dx - b.dx) - (b.dx - a.dx) * (c.dy - b.dy);
    const epsilon = 1e-9;
    if (value.abs() < epsilon) {
      return 0;
    }
    return value > 0 ? 1 : 2;
  }

  bool _onSegment(Offset a, Offset b, Offset c) {
    return b.dx <= math.max(a.dx, c.dx) + 1e-9 &&
        b.dx + 1e-9 >= math.min(a.dx, c.dx) &&
        b.dy <= math.max(a.dy, c.dy) + 1e-9 &&
        b.dy + 1e-9 >= math.min(a.dy, c.dy);
  }

  GridPos _toCell(
    Offset point, {
    required int gridWidth,
    required int gridHeight,
  }) {
    final normalized = _clampPoint(
      point,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
    );
    final maxCellX = math.max(0, gridWidth - 1);
    final maxCellY = math.max(0, gridHeight - 1);
    return GridPos(
      x: normalized.dx.floor().clamp(0, maxCellX),
      y: normalized.dy.floor().clamp(0, maxCellY),
    );
  }

  Offset _clampPoint(
    Offset point, {
    required int gridWidth,
    required int gridHeight,
  }) {
    final maxX = math.max(0.0, gridWidth.toDouble() - 1e-6);
    final maxY = math.max(0.0, gridHeight.toDouble() - 1e-6);
    return Offset(
      point.dx.clamp(0.0, maxX),
      point.dy.clamp(0.0, maxY),
    );
  }

  Iterable<GridPos> _rasterizeSegment(GridPos start, GridPos end) sync* {
    var x0 = start.x;
    var y0 = start.y;
    final x1 = end.x;
    final y1 = end.y;

    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;

    while (true) {
      yield GridPos(x: x0, y: y0);
      if (x0 == x1 && y0 == y1) {
        break;
      }
      final e2 = err * 2;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  String _key(GridPos cell) => '${cell.x}:${cell.y}';

  int _compareCells(GridPos a, GridPos b) {
    final yCompare = a.y.compareTo(b.y);
    if (yCompare != 0) {
      return yCompare;
    }
    return a.x.compareTo(b.x);
  }
}

class _Segment {
  const _Segment(this.start, this.end);

  final Offset start;
  final Offset end;
}
