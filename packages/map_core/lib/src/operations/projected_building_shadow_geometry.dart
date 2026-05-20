import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'static_shadow_geometry.dart';

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

final class ProjectedBuildingShadowPoint {
  ProjectedBuildingShadowPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'ProjectedBuildingShadowPoint.x');
    _validateFinite(y, 'ProjectedBuildingShadowPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedBuildingShadowPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class ProjectedBuildingShadowGeometry {
  ProjectedBuildingShadowGeometry({
    required Iterable<ProjectedBuildingShadowPoint> points,
    required this.opacity,
    required String colorHexRgb,
  })  : points = List<ProjectedBuildingShadowPoint>.unmodifiable(points),
        colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
    if (this.points.length != 4) {
      throw const ValidationException(
        'ProjectedBuildingShadowGeometry.points must contain exactly 4 points',
      );
    }
    _validateOpacity(opacity, 'ProjectedBuildingShadowGeometry.opacity');
  }

  final List<ProjectedBuildingShadowPoint> points;
  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedBuildingShadowGeometry &&
          _pointsEqualInOrder(other.points, points) &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(points),
        opacity,
        colorHexRgb,
      );
}

ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
}) {
  if (!config.enabled) {
    return null;
  }

  final direction = switch (preset.timeOfDayMode) {
    ProjectedShadowTimeOfDayMode.fixed => preset.direction.normalized,
    ProjectedShadowTimeOfDayMode.followsSun => preset.direction.normalized,
  };
  final directionX = direction.x;
  final directionY = direction.y;
  final perpendicularX = -directionY;
  final perpendicularY = directionX;

  final anchorWorldX = metrics.left +
      metrics.visualWidth * config.anchor.xRatio +
      config.localOffset.x;
  final anchorWorldY = metrics.top +
      metrics.visualHeight * config.anchor.yRatio +
      config.localOffset.y;

  final length = metrics.visualHeight * preset.shape.lengthRatio;
  final nearHalfWidth = metrics.visualWidth * preset.shape.nearWidthRatio / 2;
  final farHalfWidth = metrics.visualWidth * preset.shape.farWidthRatio / 2;

  final farCenterX = anchorWorldX + directionX * length;
  final farCenterY = anchorWorldY + directionY * length;

  return ProjectedBuildingShadowGeometry(
    points: [
      ProjectedBuildingShadowPoint(
        x: anchorWorldX - perpendicularX * nearHalfWidth,
        y: anchorWorldY - perpendicularY * nearHalfWidth,
      ),
      ProjectedBuildingShadowPoint(
        x: anchorWorldX + perpendicularX * nearHalfWidth,
        y: anchorWorldY + perpendicularY * nearHalfWidth,
      ),
      ProjectedBuildingShadowPoint(
        x: farCenterX + perpendicularX * farHalfWidth,
        y: farCenterY + perpendicularY * farHalfWidth,
      ),
      ProjectedBuildingShadowPoint(
        x: farCenterX - perpendicularX * farHalfWidth,
        y: farCenterY - perpendicularY * farHalfWidth,
      ),
    ],
    opacity: preset.appearance.opacity,
    colorHexRgb: preset.appearance.colorHexRgb,
  );
}

String _normalizeColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'ProjectedBuildingShadowGeometry.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
  return value.toUpperCase();
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validateOpacity(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

bool _pointsEqualInOrder(
  List<ProjectedBuildingShadowPoint> a,
  List<ProjectedBuildingShadowPoint> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
