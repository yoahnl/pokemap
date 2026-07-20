import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

/// Finds the visually uppermost authored Border feature at one map cell.
///
/// Hit testing uses editable geometry only. It deliberately ignores blueprint
/// publication, materialization and every non-Border layer so stale content
/// remains selectable for repair.
BorderFeature? hitTestBorderFeature({
  required BorderLayer layer,
  required GridPos position,
}) {
  for (final feature in layer.content.features.reversed) {
    if (_geometryContains(feature.geometry, position)) {
      return feature;
    }
  }
  return null;
}

/// Finds the uppermost Border feature using a screen-space stroke tolerance.
///
/// Linear geometry is measured against its authored segments instead of the
/// neighboring tile. This is required for [BorderStrokeAlignment.gridEdges],
/// whose points lie on cell boundaries. Region geometry keeps the historical
/// cell hit test.
BorderFeature? hitTestBorderFeatureAtScreenPosition({
  required BorderLayer layer,
  required Offset localPosition,
  required Offset pan,
  required double zoom,
  required double tileWidth,
  required double tileHeight,
  double toleranceScreenPx = 8,
}) {
  if (!zoom.isFinite ||
      zoom <= 0 ||
      !tileWidth.isFinite ||
      tileWidth <= 0 ||
      !tileHeight.isFinite ||
      tileHeight <= 0 ||
      !toleranceScreenPx.isFinite ||
      toleranceScreenPx < 0) {
    return null;
  }

  final worldPosition = Offset(
    (localPosition.dx - pan.dx) / zoom,
    (localPosition.dy - pan.dy) / zoom,
  );
  for (final feature in layer.content.features.reversed) {
    switch (feature.geometry) {
      case final BorderRegionGeometry region:
        final cell = GridPos(
          x: (worldPosition.dx / tileWidth).floor(),
          y: (worldPosition.dy / tileHeight).floor(),
        );
        if (_geometryContains(region, cell)) return feature;
      case final BorderStrokeGeometry geometry:
        if (_strokeIsWithinScreenTolerance(
          geometry: geometry,
          localPosition: localPosition,
          pan: pan,
          zoom: zoom,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          toleranceScreenPx: toleranceScreenPx,
        )) {
          return feature;
        }
    }
  }
  return null;
}

bool _strokeIsWithinScreenTolerance({
  required BorderStrokeGeometry geometry,
  required Offset localPosition,
  required Offset pan,
  required double zoom,
  required double tileWidth,
  required double tileHeight,
  required double toleranceScreenPx,
}) {
  Offset screenPoint(GridPos point) {
    final worldPoint = switch (geometry.alignment) {
      BorderStrokeAlignment.cellCenters => Offset(
          (point.x + 0.5) * tileWidth,
          (point.y + 0.5) * tileHeight,
        ),
      BorderStrokeAlignment.gridEdges => Offset(
          point.x * tileWidth,
          point.y * tileHeight,
        ),
    };
    return Offset(
      pan.dx + worldPoint.dx * zoom,
      pan.dy + worldPoint.dy * zoom,
    );
  }

  for (final stroke in geometry.strokes) {
    if (stroke.points.isEmpty) continue;
    if (stroke.points.length == 1 &&
        (localPosition - screenPoint(stroke.points.single)).distance <=
            toleranceScreenPx) {
      return true;
    }
    for (var index = 1; index < stroke.points.length; index += 1) {
      if (_distanceToSegment(
            localPosition,
            screenPoint(stroke.points[index - 1]),
            screenPoint(stroke.points[index]),
          ) <=
          toleranceScreenPx) {
        return true;
      }
    }
    if (stroke.closed && stroke.points.length > 2) {
      if (_distanceToSegment(
            localPosition,
            screenPoint(stroke.points.last),
            screenPoint(stroke.points.first),
          ) <=
          toleranceScreenPx) {
        return true;
      }
    }
  }
  return false;
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final delta = end - start;
  final lengthSquared = delta.dx * delta.dx + delta.dy * delta.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final projection =
      ((point.dx - start.dx) * delta.dx + (point.dy - start.dy) * delta.dy) /
          lengthSquared;
  final clamped = math.max(0.0, math.min(1.0, projection));
  final nearest = Offset(
    start.dx + delta.dx * clamped,
    start.dy + delta.dy * clamped,
  );
  return (point - nearest).distance;
}

bool _geometryContains(BorderFeatureGeometry geometry, GridPos position) =>
    switch (geometry) {
      BorderRegionGeometry region => position.x >= 0 &&
          position.y >= 0 &&
          position.x < region.width &&
          position.y < region.height &&
          region.cells[position.y * region.width + position.x],
      BorderStrokeGeometry stroke => stroke.strokes.any(
          (segment) => segment.points.contains(position),
        ),
    };
