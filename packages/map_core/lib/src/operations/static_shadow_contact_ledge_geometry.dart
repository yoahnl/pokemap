import 'static_shadow_geometry.dart';
import 'static_shadow_projection_geometry.dart';

const buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.72;
const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.62;
const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.18;
const buildingStaticShadowContactLedgeDepthRatio = 0.055;
const buildingStaticShadowContactLedgeMinDepth = 6.0;
const buildingStaticShadowContactLedgeMaxDepth = 20.0;
const buildingStaticShadowContactLedgeSkewRatio = 0.020;
const buildingStaticShadowContactLedgeMinSkew = 0.0;
const buildingStaticShadowContactLedgeMaxSkew = 7.0;

ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
}) {
  final centerX = baseGeometry.centerX;
  final nearY = baseGeometry.centerY -
      baseGeometry.height *
          buildingStaticShadowContactLedgeNearHeightOffsetMultiplier;
  final farY =
      baseGeometry.centerY + _buildingStaticShadowContactLedgeDepth(metrics);
  final nearHalfWidth = baseGeometry.width *
      buildingStaticShadowContactLedgeNearHalfWidthMultiplier;
  final farHalfWidth = baseGeometry.width *
      buildingStaticShadowContactLedgeFarHalfWidthMultiplier;
  final skewX = _buildingStaticShadowContactLedgeSkew(metrics);

  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(
      x: centerX - nearHalfWidth,
      y: nearY,
    ),
    nearRight: ProjectedStaticShadowPoint(
      x: centerX + nearHalfWidth,
      y: nearY,
    ),
    farRight: ProjectedStaticShadowPoint(
      x: centerX + skewX + farHalfWidth,
      y: farY,
    ),
    farLeft: ProjectedStaticShadowPoint(
      x: centerX + skewX - farHalfWidth,
      y: farY,
    ),
  );
}

double _buildingStaticShadowContactLedgeDepth(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualHeight * buildingStaticShadowContactLedgeDepthRatio,
    buildingStaticShadowContactLedgeMinDepth,
    buildingStaticShadowContactLedgeMaxDepth,
  );
}

double _buildingStaticShadowContactLedgeSkew(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualWidth * buildingStaticShadowContactLedgeSkewRatio,
    buildingStaticShadowContactLedgeMinSkew,
    buildingStaticShadowContactLedgeMaxSkew,
  );
}

double _clampDouble(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
