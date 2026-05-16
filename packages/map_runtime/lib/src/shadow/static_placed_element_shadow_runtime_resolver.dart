import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';
import 'shadow_runtime_resolver.dart';

const _buildingContactLedgeNearHalfWidthMultiplier = 0.55;
const _buildingContactLedgeFarHalfWidthMultiplier = 0.48;
const _buildingContactLedgeNearHeightOffsetMultiplier = 0.30;
const _buildingContactLedgeDepthRatio = 0.035;
const _buildingContactLedgeMinDepth = 4.0;
const _buildingContactLedgeMaxDepth = 14.0;
const _buildingContactLedgeSkewRatio = 0.025;
const _buildingContactLedgeMinSkew = 0.0;
const _buildingContactLedgeMaxSkew = 8.0;

/// Runtime static element metrics used to derive a ground shadow anchor.
///
/// The default ratios and multipliers are V0 heuristics for common static
/// props. They are intentionally adjustable once real rendered shadows can be
/// evaluated.
final class StaticPlacedElementShadowRuntimeMetrics {
  StaticPlacedElementShadowRuntimeMetrics({
    required this.worldLeft,
    required this.worldTop,
    required this.visualWidth,
    required this.visualHeight,
    this.anchorXRatio = 0.5,
    this.anchorYRatio = 1.0,
    this.baseWidthMultiplier = 0.75,
    this.baseHeightMultiplier = 0.25,
  }) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
    _validateRatio(anchorXRatio, 'anchorXRatio');
    _validateRatio(anchorYRatio, 'anchorYRatio');
    _validatePositiveFinite(baseWidthMultiplier, 'baseWidthMultiplier');
    _validatePositiveFinite(baseHeightMultiplier, 'baseHeightMultiplier');
  }

  final double worldLeft;
  final double worldTop;
  final double visualWidth;
  final double visualHeight;
  final double anchorXRatio;
  final double anchorYRatio;
  final double baseWidthMultiplier;
  final double baseHeightMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeMetrics &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.anchorXRatio == anchorXRatio &&
          other.anchorYRatio == anchorYRatio &&
          other.baseWidthMultiplier == baseWidthMultiplier &&
          other.baseHeightMultiplier == baseHeightMultiplier;

  @override
  int get hashCode => Object.hash(
        worldLeft,
        worldTop,
        visualWidth,
        visualHeight,
        anchorXRatio,
        anchorYRatio,
        baseWidthMultiplier,
        baseHeightMultiplier,
      );
}

/// Single static placed element shadow resolution request.
final class StaticPlacedElementShadowRuntimeInput {
  const StaticPlacedElementShadowRuntimeInput({
    required this.resolvedConfig,
    required this.metrics,
    this.elementFootprint,
    this.overrideFootprint,
    this.elementFamily,
    this.overrideFamily,
  });

  final ResolvedShadowConfig resolvedConfig;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final StaticShadowFootprintConfig? elementFootprint;
  final StaticShadowFootprintConfig? overrideFootprint;
  final StaticShadowFamily? elementFamily;
  final StaticShadowFamily? overrideFamily;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics &&
          other.elementFootprint == elementFootprint &&
          other.overrideFootprint == overrideFootprint &&
          other.elementFamily == elementFamily &&
          other.overrideFamily == overrideFamily;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
        elementFootprint,
        overrideFootprint,
        elementFamily,
        overrideFamily,
      );
}

ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics, {
  ResolvedShadowConfig? shadowConfig,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
}) {
  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
    metrics: metrics,
    elementFootprint: elementFootprint,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: _visualMetricsFromRuntimeMetrics(metrics),
    shadowConfig: shadowConfig ?? _identityShadowConfig,
    elementFootprint: legacyAndElementFootprint,
    overrideFootprint: overrideFootprint,
  );

  return ShadowRuntimeAnchor(
    worldX: geometry.anchorX,
    worldY: geometry.anchorY,
    baseWidth: geometry.baseWidth,
    baseHeight: geometry.baseHeight,
  );
}

ShadowRuntimeRenderInstruction?
    resolveStaticPlacedElementShadowRuntimeInstruction(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }
  if (resolved.renderPass != ShadowRenderPass.groundStatic) {
    throw const ValidationException(
      'Static placed element shadow resolver requires groundStatic render pass',
    );
  }
  if (resolved.mode != ShadowCasterMode.ellipse &&
      resolved.mode != ShadowCasterMode.contactBlob) {
    throw const ValidationException(
      'Static placed element shadow resolver requires ellipse or contactBlob mode',
    );
  }

  final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
  final family = resolveStaticShadowFamily(
    elementFamily: input.elementFamily,
    overrideFamily: input.overrideFamily,
  );
  if (family == StaticShadowFamily.building) {
    return _resolveBuildingContactLedgeRuntimeInstruction(
      input,
      baseGeometry,
    );
  }

  final projectedGeometry = resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
      family: family,
    ),
  );
  final points = _runtimePointsFromProjection(projectedGeometry);
  final bounds = _boundsFromRuntimePoints(points);

  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: resolved.renderPass,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: resolved.opacity,
    colorHexRgb: resolved.colorHexRgb,
    softnessMode: resolved.softnessMode,
    polygonPoints: points,
  );
}

List<ShadowRuntimeRenderInstruction>
    resolveStaticPlacedElementShadowRuntimeInstructions(
  Iterable<StaticPlacedElementShadowRuntimeInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction =
        resolveStaticPlacedElementShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

ShadowRuntimeRenderInstruction _resolveBuildingContactLedgeRuntimeInstruction(
  StaticPlacedElementShadowRuntimeInput input,
  ResolvedStaticShadowGeometry baseGeometry,
) {
  final points = _buildingContactLedgePoints(
    geometry: baseGeometry,
    metrics: input.metrics,
  );
  final bounds = _boundsFromRuntimePoints(points);
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: input.resolvedConfig.renderPass,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: input.resolvedConfig.opacity,
    colorHexRgb: input.resolvedConfig.colorHexRgb,
    softnessMode: input.resolvedConfig.softnessMode,
    polygonPoints: points,
  );
}

List<ShadowRuntimePoint> _buildingContactLedgePoints({
  required ResolvedStaticShadowGeometry geometry,
  required StaticPlacedElementShadowRuntimeMetrics metrics,
}) {
  final centerX = geometry.centerX;
  final nearY = geometry.centerY -
      geometry.height * _buildingContactLedgeNearHeightOffsetMultiplier;
  final farY = geometry.centerY + _buildingContactLedgeDepth(metrics);
  final nearHalfWidth =
      geometry.width * _buildingContactLedgeNearHalfWidthMultiplier;
  final farHalfWidth =
      geometry.width * _buildingContactLedgeFarHalfWidthMultiplier;
  final skewX = _buildingContactLedgeSkew(metrics);

  return List<ShadowRuntimePoint>.unmodifiable([
    ShadowRuntimePoint(
      worldX: centerX - nearHalfWidth,
      worldY: nearY,
    ),
    ShadowRuntimePoint(
      worldX: centerX + nearHalfWidth,
      worldY: nearY,
    ),
    ShadowRuntimePoint(
      worldX: centerX + skewX + farHalfWidth,
      worldY: farY,
    ),
    ShadowRuntimePoint(
      worldX: centerX + skewX - farHalfWidth,
      worldY: farY,
    ),
  ]);
}

double _buildingContactLedgeDepth(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return _clampDouble(
    metrics.visualHeight * _buildingContactLedgeDepthRatio,
    _buildingContactLedgeMinDepth,
    _buildingContactLedgeMaxDepth,
  );
}

double _buildingContactLedgeSkew(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return _clampDouble(
    metrics.visualWidth * _buildingContactLedgeSkewRatio,
    _buildingContactLedgeMinSkew,
    _buildingContactLedgeMaxSkew,
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

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be greater than 0',
    );
  }
}

void _validateRatio(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be between 0 and 1',
    );
  }
}

StaticShadowFootprintConfig _legacyFootprintFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return StaticShadowFootprintConfig(
    anchorXRatio: metrics.anchorXRatio,
    anchorYRatio: metrics.anchorYRatio,
    footprintWidthRatio: metrics.baseWidthMultiplier,
    footprintHeightRatio: metrics.baseHeightMultiplier,
  );
}

StaticShadowFootprintConfig _mergeLegacyAndElementFootprint({
  required StaticPlacedElementShadowRuntimeMetrics metrics,
  required StaticShadowFootprintConfig? elementFootprint,
}) {
  final resolved = resolveStaticShadowFootprint(
    elementFootprint: _legacyFootprintFromMetrics(metrics),
    overrideFootprint: elementFootprint,
  );
  return StaticShadowFootprintConfig(
    anchorXRatio: resolved.anchorXRatio,
    anchorYRatio: resolved.anchorYRatio,
    footprintWidthRatio: resolved.footprintWidthRatio,
    footprintHeightRatio: resolved.footprintHeightRatio,
  );
}

ResolvedStaticShadowGeometry _resolveStaticPlacedElementBaseGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
    metrics: input.metrics,
    elementFootprint: input.elementFootprint,
  );
  return resolveStaticShadowGeometry(
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
    shadowConfig: input.resolvedConfig,
    elementFootprint: legacyAndElementFootprint,
    overrideFootprint: input.overrideFootprint,
  );
}

StaticShadowVisualMetrics _visualMetricsFromRuntimeMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return StaticShadowVisualMetrics(
    left: metrics.worldLeft,
    top: metrics.worldTop,
    visualWidth: metrics.visualWidth,
    visualHeight: metrics.visualHeight,
  );
}

List<ShadowRuntimePoint> _runtimePointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<ShadowRuntimePoint>.unmodifiable(
    geometry.points.map(
      (point) => ShadowRuntimePoint(
        worldX: point.x,
        worldY: point.y,
      ),
    ),
  );
}

_ProjectedRuntimeShadowBounds _boundsFromRuntimePoints(
  List<ShadowRuntimePoint> points,
) {
  var minX = points.first.worldX;
  var maxX = points.first.worldX;
  var minY = points.first.worldY;
  var maxY = points.first.worldY;
  for (final point in points.skip(1)) {
    if (point.worldX < minX) {
      minX = point.worldX;
    }
    if (point.worldX > maxX) {
      maxX = point.worldX;
    }
    if (point.worldY < minY) {
      minY = point.worldY;
    }
    if (point.worldY > maxY) {
      maxY = point.worldY;
    }
  }
  return _ProjectedRuntimeShadowBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _ProjectedRuntimeShadowBounds {
  const _ProjectedRuntimeShadowBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

const _identityShadowConfig = ResolvedShadowConfig(
  shadowProfileId: 'runtime-static-shadow-anchor',
  mode: ShadowCasterMode.ellipse,
  renderPass: ShadowRenderPass.groundStatic,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 1,
  colorHexRgb: '000000',
  softnessMode: ShadowSoftnessMode.hardEdge,
);
