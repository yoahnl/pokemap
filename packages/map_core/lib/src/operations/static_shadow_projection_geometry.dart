import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import 'static_shadow_geometry.dart';

const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;

const defaultStaticShadowProjectionSpec = StaticShadowProjectionSpec._(
  directionX: defaultStaticShadowProjectionDirectionX,
  directionY: defaultStaticShadowProjectionDirectionY,
  lengthRatio: defaultStaticShadowProjectionLengthRatio,
  nearWidthMultiplier: defaultStaticShadowProjectionNearWidthMultiplier,
  farWidthMultiplier: defaultStaticShadowProjectionFarWidthMultiplier,
);

final class ProjectedStaticShadowPoint {
  ProjectedStaticShadowPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'ProjectedStaticShadowPoint.x');
    _validateFinite(y, 'ProjectedStaticShadowPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class StaticShadowProjectionSpec {
  factory StaticShadowProjectionSpec({
    required double directionX,
    required double directionY,
    required double lengthRatio,
    required double nearWidthMultiplier,
    required double farWidthMultiplier,
  }) {
    _validateFinite(directionX, 'StaticShadowProjectionSpec.directionX');
    _validateFinite(directionY, 'StaticShadowProjectionSpec.directionY');
    if (directionX == 0 && directionY == 0) {
      throw const ValidationException(
        'StaticShadowProjectionSpec direction must be non-zero',
      );
    }
    _validatePositiveFinite(
      lengthRatio,
      'StaticShadowProjectionSpec.lengthRatio',
    );
    _validatePositiveFinite(
      nearWidthMultiplier,
      'StaticShadowProjectionSpec.nearWidthMultiplier',
    );
    _validatePositiveFinite(
      farWidthMultiplier,
      'StaticShadowProjectionSpec.farWidthMultiplier',
    );
    return StaticShadowProjectionSpec._(
      directionX: directionX,
      directionY: directionY,
      lengthRatio: lengthRatio,
      nearWidthMultiplier: nearWidthMultiplier,
      farWidthMultiplier: farWidthMultiplier,
    );
  }

  const StaticShadowProjectionSpec._({
    required this.directionX,
    required this.directionY,
    required this.lengthRatio,
    required this.nearWidthMultiplier,
    required this.farWidthMultiplier,
  });

  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthMultiplier;
  final double farWidthMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticShadowProjectionSpec &&
          other.directionX == directionX &&
          other.directionY == directionY &&
          other.lengthRatio == lengthRatio &&
          other.nearWidthMultiplier == nearWidthMultiplier &&
          other.farWidthMultiplier == farWidthMultiplier;

  @override
  int get hashCode => Object.hash(
        directionX,
        directionY,
        lengthRatio,
        nearWidthMultiplier,
        farWidthMultiplier,
      );
}

final class ProjectedStaticShadowGeometry {
  ProjectedStaticShadowGeometry({
    required this.nearLeft,
    required this.nearRight,
    required this.farRight,
    required this.farLeft,
  }) {
    if (_polygonArea(points) <= 0) {
      throw const ValidationException(
        'ProjectedStaticShadowGeometry polygon must be non-degenerate',
      );
    }
  }

  final ProjectedStaticShadowPoint nearLeft;
  final ProjectedStaticShadowPoint nearRight;
  final ProjectedStaticShadowPoint farRight;
  final ProjectedStaticShadowPoint farLeft;

  List<ProjectedStaticShadowPoint> get points =>
      List<ProjectedStaticShadowPoint>.unmodifiable([
        nearLeft,
        nearRight,
        farRight,
        farLeft,
      ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowGeometry &&
          other.nearLeft == nearLeft &&
          other.nearRight == nearRight &&
          other.farRight == farRight &&
          other.farLeft == farLeft;

  @override
  int get hashCode => Object.hash(nearLeft, nearRight, farRight, farLeft);
}

ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec = defaultStaticShadowProjectionSpec,
}) {
  final directionLength = math.sqrt(
    projectionSpec.directionX * projectionSpec.directionX +
        projectionSpec.directionY * projectionSpec.directionY,
  );
  final dirX = projectionSpec.directionX / directionLength;
  final dirY = projectionSpec.directionY / directionLength;
  final perpX = -dirY;
  final perpY = dirX;
  final projectionLength = metrics.visualHeight * projectionSpec.lengthRatio;
  final nearCenterX = baseGeometry.centerX;
  final nearCenterY = baseGeometry.centerY;
  final farCenterX = nearCenterX + dirX * projectionLength;
  final farCenterY = nearCenterY + dirY * projectionLength;
  final nearHalfWidth =
      baseGeometry.width * projectionSpec.nearWidthMultiplier / 2;
  final farHalfWidth =
      baseGeometry.width * projectionSpec.farWidthMultiplier / 2;

  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(
      x: nearCenterX - perpX * nearHalfWidth,
      y: nearCenterY - perpY * nearHalfWidth,
    ),
    nearRight: ProjectedStaticShadowPoint(
      x: nearCenterX + perpX * nearHalfWidth,
      y: nearCenterY + perpY * nearHalfWidth,
    ),
    farRight: ProjectedStaticShadowPoint(
      x: farCenterX + perpX * farHalfWidth,
      y: farCenterY + perpY * farHalfWidth,
    ),
    farLeft: ProjectedStaticShadowPoint(
      x: farCenterX - perpX * farHalfWidth,
      y: farCenterY - perpY * farHalfWidth,
    ),
  );
}

double _polygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be > 0');
  }
}
