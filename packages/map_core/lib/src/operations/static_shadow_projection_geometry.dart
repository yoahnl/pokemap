import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import 'static_shadow_geometry.dart';

const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;
const defaultProjectedStaticShadowFillBandCount = 7;
const defaultProjectedStaticShadowNearOpacityScale = 1.0;
const defaultProjectedStaticShadowFarOpacityScale = 0.52;

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

final class ProjectedStaticShadowOpacityBand {
  ProjectedStaticShadowOpacityBand({
    required this.startT,
    required this.endT,
    required this.opacityScale,
  }) {
    _validateBandT(startT, 'ProjectedStaticShadowOpacityBand.startT');
    _validateBandT(endT, 'ProjectedStaticShadowOpacityBand.endT');
    if (endT <= startT) {
      throw const ValidationException(
        'ProjectedStaticShadowOpacityBand.endT must be greater than startT',
      );
    }
    _validatePositiveFinite(
      opacityScale,
      'ProjectedStaticShadowOpacityBand.opacityScale',
    );
    if (opacityScale > 1) {
      throw const ValidationException(
        'ProjectedStaticShadowOpacityBand.opacityScale must be <= 1',
      );
    }
  }

  final double startT;
  final double endT;
  final double opacityScale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowOpacityBand &&
          other.startT == startT &&
          other.endT == endT &&
          other.opacityScale == opacityScale;

  @override
  int get hashCode => Object.hash(startT, endT, opacityScale);
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

List<ProjectedStaticShadowOpacityBand> createProjectedStaticShadowOpacityBands({
  int bandCount = defaultProjectedStaticShadowFillBandCount,
  double nearOpacityScale = defaultProjectedStaticShadowNearOpacityScale,
  double farOpacityScale = defaultProjectedStaticShadowFarOpacityScale,
}) {
  if (bandCount <= 0) {
    throw const ValidationException(
      'Projected static shadow bandCount must be greater than 0',
    );
  }
  _validatePositiveFinite(
    nearOpacityScale,
    'Projected static shadow nearOpacityScale',
  );
  _validatePositiveFinite(
    farOpacityScale,
    'Projected static shadow farOpacityScale',
  );
  if (nearOpacityScale > 1 || farOpacityScale > 1) {
    throw const ValidationException(
      'Projected static shadow opacity scales must be <= 1',
    );
  }
  if (farOpacityScale > nearOpacityScale) {
    throw const ValidationException(
      'Projected static shadow farOpacityScale must be <= nearOpacityScale',
    );
  }

  final bands = <ProjectedStaticShadowOpacityBand>[];
  for (var index = 0; index < bandCount; index += 1) {
    final startT = index / bandCount;
    final endT = (index + 1) / bandCount;
    final midT = (startT + endT) / 2;
    final opacityScale =
        nearOpacityScale + (farOpacityScale - nearOpacityScale) * midT;
    bands.add(
      ProjectedStaticShadowOpacityBand(
        startT: startT,
        endT: endT,
        opacityScale: opacityScale,
      ),
    );
  }
  return List<ProjectedStaticShadowOpacityBand>.unmodifiable(bands);
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

void _validateBandT(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
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
