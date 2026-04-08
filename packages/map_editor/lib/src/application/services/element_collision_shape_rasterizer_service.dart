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
  const ElementCollisionShapeRasterizerService({
    this.polygonPolicy = const ElementCollisionPolygonRasterizationPolicy(),
  });

  final ElementCollisionPolygonRasterizationPolicy polygonPolicy;

  /// Rasterizes a polygon into cells.
  ///
  /// The author manipulates a *shape*, not runtime cells. Conversion to grid
  /// cells therefore uses a coverage rule rather than a blunt "any touch wins"
  /// rule. That is the critical difference with the previous behaviour:
  ///
  /// - cells lightly grazed by the polygon should usually stay empty
  /// - cells meaningfully covered by the polygon should be retained
  /// - narrow silhouettes should stay plausible instead of expanding into
  ///   bulky blocks
  ///
  /// The default policy uses supersampling inside each cell and selects the
  /// cell when:
  /// - the cell center is inside the polygon, or
  /// - the measured coverage ratio reaches [polygonPolicy.minimumCoverage]
  ///
  /// This hybrid rule matches the author intent better than either extreme:
  /// - edge-touch alone is far too blocky
  /// - coverage-only can erase very thin but intentional silhouette parts
  /// - center-or-coverage keeps thin authored structures while ignoring
  ///   meaningless corner grazes
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
        if (_polygonCoversCell(normalizedVertices, cellRect)) {
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

  bool _polygonCoversCell(List<Offset> vertices, Rect cellRect) {
    final center = Offset(cellRect.left + 0.5, cellRect.top + 0.5);
    if (_pointInPolygon(center, vertices)) {
      return true;
    }

    final coverage = _estimateCellCoverage(vertices, cellRect);
    return coverage >= polygonPolicy.minimumCoverage;
  }

  double _estimateCellCoverage(List<Offset> vertices, Rect cellRect) {
    final resolution = polygonPolicy.sampleResolution;
    final stepX = cellRect.width / resolution;
    final stepY = cellRect.height / resolution;
    var coveredSamples = 0;
    var totalSamples = 0;

    for (var sampleY = 0; sampleY < resolution; sampleY++) {
      for (var sampleX = 0; sampleX < resolution; sampleX++) {
        totalSamples += 1;
        final point = Offset(
          cellRect.left + (sampleX + 0.5) * stepX,
          cellRect.top + (sampleY + 0.5) * stepY,
        );
        if (_pointInPolygon(point, vertices)) {
          coveredSamples += 1;
        }
      }
    }

    if (totalSamples == 0) {
      return 0;
    }
    return coveredSamples / totalSamples;
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

/// Backend conversion policy from an author polygon to runtime cells.
///
/// This stays editor-side only. Runtime still consumes only the final cells.
class ElementCollisionPolygonRasterizationPolicy {
  const ElementCollisionPolygonRasterizationPolicy({
    this.sampleResolution = 7,
    this.minimumCoverage = 0.32,
  })  : assert(sampleResolution > 0),
        assert(minimumCoverage >= 0),
        assert(minimumCoverage <= 1);

  /// Number of samples per axis used to estimate cell coverage.
  ///
  /// `7` means 49 sub-samples per cell, which stays cheap at editor scale
  /// while giving a much more shape-faithful estimate than edge-touch logic.
  final int sampleResolution;

  /// Minimum coverage ratio required to keep a cell.
  ///
  /// The value is deliberately below 0.5 because runtime cells are still
  /// coarse. We want narrow roofs or walls to survive conversion without
  /// collapsing, but not so low that a corner graze selects a full cell.
  final double minimumCoverage;
}
