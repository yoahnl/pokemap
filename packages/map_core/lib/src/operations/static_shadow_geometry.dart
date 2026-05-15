import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';
import 'shadow_config_resolver.dart';

const _defaultStaticShadowAnchorXRatio = 0.5;
const _defaultStaticShadowAnchorYRatio = 1.0;
const _defaultStaticShadowFootprintWidthRatio = 0.75;
const _defaultStaticShadowFootprintHeightRatio = 0.25;

final class StaticShadowVisualMetrics {
  StaticShadowVisualMetrics({
    required this.left,
    required this.top,
    required this.visualWidth,
    required this.visualHeight,
  }) {
    _validateFinite(left, 'StaticShadowVisualMetrics.left');
    _validateFinite(top, 'StaticShadowVisualMetrics.top');
    _validatePositiveFinite(
      visualWidth,
      'StaticShadowVisualMetrics.visualWidth',
    );
    _validatePositiveFinite(
      visualHeight,
      'StaticShadowVisualMetrics.visualHeight',
    );
  }

  final double left;
  final double top;
  final double visualWidth;
  final double visualHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticShadowVisualMetrics &&
          other.left == left &&
          other.top == top &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight;

  @override
  int get hashCode => Object.hash(
        left,
        top,
        visualWidth,
        visualHeight,
      );
}

final class ResolvedStaticShadowFootprint {
  ResolvedStaticShadowFootprint({
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.footprintWidthRatio,
    required this.footprintHeightRatio,
  }) {
    _validateRatio(
      anchorXRatio,
      'ResolvedStaticShadowFootprint.anchorXRatio',
    );
    _validateRatio(
      anchorYRatio,
      'ResolvedStaticShadowFootprint.anchorYRatio',
    );
    _validatePositiveFinite(
      footprintWidthRatio,
      'ResolvedStaticShadowFootprint.footprintWidthRatio',
    );
    _validatePositiveFinite(
      footprintHeightRatio,
      'ResolvedStaticShadowFootprint.footprintHeightRatio',
    );
  }

  final double anchorXRatio;
  final double anchorYRatio;
  final double footprintWidthRatio;
  final double footprintHeightRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedStaticShadowFootprint &&
          other.anchorXRatio == anchorXRatio &&
          other.anchorYRatio == anchorYRatio &&
          other.footprintWidthRatio == footprintWidthRatio &&
          other.footprintHeightRatio == footprintHeightRatio;

  @override
  int get hashCode => Object.hash(
        anchorXRatio,
        anchorYRatio,
        footprintWidthRatio,
        footprintHeightRatio,
      );
}

final class ResolvedStaticShadowGeometry {
  ResolvedStaticShadowGeometry({
    required this.anchorX,
    required this.anchorY,
    required this.baseWidth,
    required this.baseHeight,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.left,
    required this.top,
  }) {
    _validateFinite(anchorX, 'ResolvedStaticShadowGeometry.anchorX');
    _validateFinite(anchorY, 'ResolvedStaticShadowGeometry.anchorY');
    _validatePositiveFinite(
      baseWidth,
      'ResolvedStaticShadowGeometry.baseWidth',
    );
    _validatePositiveFinite(
      baseHeight,
      'ResolvedStaticShadowGeometry.baseHeight',
    );
    _validateFinite(centerX, 'ResolvedStaticShadowGeometry.centerX');
    _validateFinite(centerY, 'ResolvedStaticShadowGeometry.centerY');
    _validatePositiveFinite(width, 'ResolvedStaticShadowGeometry.width');
    _validatePositiveFinite(height, 'ResolvedStaticShadowGeometry.height');
    _validateFinite(left, 'ResolvedStaticShadowGeometry.left');
    _validateFinite(top, 'ResolvedStaticShadowGeometry.top');
  }

  final double anchorX;
  final double anchorY;
  final double baseWidth;
  final double baseHeight;
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final double left;
  final double top;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedStaticShadowGeometry &&
          other.anchorX == anchorX &&
          other.anchorY == anchorY &&
          other.baseWidth == baseWidth &&
          other.baseHeight == baseHeight &&
          other.centerX == centerX &&
          other.centerY == centerY &&
          other.width == width &&
          other.height == height &&
          other.left == left &&
          other.top == top;

  @override
  int get hashCode => Object.hash(
        anchorX,
        anchorY,
        baseWidth,
        baseHeight,
        centerX,
        centerY,
        width,
        height,
        left,
        top,
      );
}

ResolvedStaticShadowFootprint resolveStaticShadowFootprint({
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
}) {
  var anchorXRatio = _defaultStaticShadowAnchorXRatio;
  var anchorYRatio = _defaultStaticShadowAnchorYRatio;
  var footprintWidthRatio = _defaultStaticShadowFootprintWidthRatio;
  var footprintHeightRatio = _defaultStaticShadowFootprintHeightRatio;

  if (elementFootprint != null) {
    anchorXRatio = elementFootprint.anchorXRatio ?? anchorXRatio;
    anchorYRatio = elementFootprint.anchorYRatio ?? anchorYRatio;
    footprintWidthRatio =
        elementFootprint.footprintWidthRatio ?? footprintWidthRatio;
    footprintHeightRatio =
        elementFootprint.footprintHeightRatio ?? footprintHeightRatio;
  }

  if (overrideFootprint != null) {
    anchorXRatio = overrideFootprint.anchorXRatio ?? anchorXRatio;
    anchorYRatio = overrideFootprint.anchorYRatio ?? anchorYRatio;
    footprintWidthRatio =
        overrideFootprint.footprintWidthRatio ?? footprintWidthRatio;
    footprintHeightRatio =
        overrideFootprint.footprintHeightRatio ?? footprintHeightRatio;
  }

  return ResolvedStaticShadowFootprint(
    anchorXRatio: anchorXRatio,
    anchorYRatio: anchorYRatio,
    footprintWidthRatio: footprintWidthRatio,
    footprintHeightRatio: footprintHeightRatio,
  );
}

ResolvedStaticShadowGeometry resolveStaticShadowGeometry({
  required StaticShadowVisualMetrics metrics,
  required ResolvedShadowConfig shadowConfig,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
}) {
  final footprint = resolveStaticShadowFootprint(
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
  final anchorX = metrics.left + metrics.visualWidth * footprint.anchorXRatio;
  final anchorY = metrics.top + metrics.visualHeight * footprint.anchorYRatio;
  final baseWidth = metrics.visualWidth * footprint.footprintWidthRatio;
  final baseHeight = metrics.visualHeight * footprint.footprintHeightRatio;
  final width = baseWidth * shadowConfig.scaleX;
  final height = baseHeight * shadowConfig.scaleY;
  final centerX = anchorX + shadowConfig.offsetX;
  final centerY = anchorY + shadowConfig.offsetY;

  return ResolvedStaticShadowGeometry(
    anchorX: anchorX,
    anchorY: anchorY,
    baseWidth: baseWidth,
    baseHeight: baseHeight,
    centerX: centerX,
    centerY: centerY,
    width: width,
    height: height,
    left: centerX - width / 2,
    top: centerY - height / 2,
  );
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

void _validateRatio(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}
