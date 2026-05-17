import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('building static shadow contact ledge constants', () {
    test('defaults match Shadow-54 visible contact tuning', () {
      expect(buildingStaticShadowContactLedgeNearHalfWidthMultiplier, 0.72);
      expect(buildingStaticShadowContactLedgeFarHalfWidthMultiplier, 0.62);
      expect(buildingStaticShadowContactLedgeNearHeightOffsetMultiplier, 0.18);
      expect(buildingStaticShadowContactLedgeDepthRatio, 0.055);
      expect(buildingStaticShadowContactLedgeMinDepth, 6);
      expect(buildingStaticShadowContactLedgeMaxDepth, 20);
      expect(buildingStaticShadowContactLedgeSkewRatio, 0.020);
      expect(buildingStaticShadowContactLedgeMinSkew, 0);
      expect(buildingStaticShadowContactLedgeMaxSkew, 7);
    });
  });

  group('resolveBuildingStaticShadowContactLedgeGeometry', () {
    test('creates a shallow four point contact ledge', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      expect(geometry.points, hasLength(4));
      expect(geometry.nearLeft.y, closeTo(geometry.nearRight.y, 0.000001));
      expect(geometry.farLeft.y, closeTo(geometry.farRight.y, 0.000001));
      expect(geometry.farLeft.y, greaterThan(geometry.nearLeft.y));
      expect(geometry.farRight.y, greaterThan(geometry.nearRight.y));
      expect(_bounds(geometry).height, greaterThan(13));
      expect(_bounds(geometry).height, lessThan(15));
      expect(_bounds(geometry).width, greaterThan(118));
      expect(_bounds(geometry).width, lessThan(121));
    });

    test('matches the Shadow-54 runtime formula exactly', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final depth = _clamp(metrics.visualHeight * 0.055, 6, 20);
      final skew = _clamp(metrics.visualWidth * 0.020, 0, 7);
      expect(geometry.nearLeft.x,
          closeTo(base.centerX - base.width * 0.72, 0.000001));
      expect(geometry.nearLeft.y,
          closeTo(base.centerY - base.height * 0.18, 0.000001));
      expect(geometry.nearRight.x,
          closeTo(base.centerX + base.width * 0.72, 0.000001));
      expect(geometry.nearRight.y,
          closeTo(base.centerY - base.height * 0.18, 0.000001));
      expect(geometry.farRight.x,
          closeTo(base.centerX + skew + base.width * 0.62, 0.000001));
      expect(geometry.farRight.y, closeTo(base.centerY + depth, 0.000001));
      expect(geometry.farLeft.x,
          closeTo(base.centerX + skew - base.width * 0.62, 0.000001));
      expect(geometry.farLeft.y, closeTo(base.centerY + depth, 0.000001));
    });

    test('uses base footprint width', () {
      final metrics = _metrics();
      final narrow = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.25),
        metrics: metrics,
      );
      final wide = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.75),
        metrics: metrics,
      );

      expect(_bounds(narrow).width, lessThan(_bounds(wide).width));
    });

    test('applies offset and scale only through base geometry', () {
      final metrics = _metrics();
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(
          offsetX: 5,
          offsetY: 7,
          scaleX: 2,
          scaleY: 0.5,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final nearCenterX = (geometry.nearLeft.x + geometry.nearRight.x) / 2;
      expect(nearCenterX, closeTo(base.centerX, 0.000001));
      expect(_bounds(geometry).width, greaterThan(base.width));
      expect(_bounds(geometry).height, greaterThan(7));
      expect(_bounds(geometry).height, lessThan(9));
    });

    test('clamps minimum and maximum depth', () {
      final small = _metrics(visualHeight: 24);
      final large = _metrics(visualHeight: 800);

      final smallGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(small),
        metrics: small,
      );
      final largeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(large),
        metrics: large,
      );

      expect(
        smallGeometry.farLeft.y - _base(small).centerY,
        closeTo(6, 0.000001),
      );
      expect(
        largeGeometry.farLeft.y - _base(large).centerY,
        closeTo(20, 0.000001),
      );
    });

    test('clamps maximum skew', () {
      final metrics = _metrics(visualWidth: 640);
      final base = _base(metrics);

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final farCenterX = (geometry.farLeft.x + geometry.farRight.x) / 2;
      expect(farCenterX - base.centerX, closeTo(7, 0.000001));
    });

    test('geometry is immutable and all points are finite', () {
      final metrics = _metrics();
      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics),
        metrics: metrics,
      );

      for (final point in geometry.points) {
        expect(point.x.isFinite, isTrue);
        expect(point.y.isFinite, isTrue);
      }
      expect(() => geometry.points.add(ProjectedStaticShadowPoint(x: 0, y: 0)),
          throwsUnsupportedError);
    });
  });
}

StaticShadowVisualMetrics _metrics({
  double left = 80,
  double top = 120,
  double visualWidth = 40,
  double visualHeight = 60,
}) {
  return StaticShadowVisualMetrics(
    left: left,
    top: top,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
}

ResolvedStaticShadowGeometry _base(
  StaticShadowVisualMetrics metrics, {
  double footprintWidthRatio = 0.5,
}) {
  return resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: _shadowConfig(),
    elementFootprint: StaticShadowFootprintConfig(
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: 0.2,
    ),
  );
}

ResolvedShadowConfig _shadowConfig({
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'test-shadow',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: 1,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}

_TestBounds _bounds(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _TestBounds(width: maxX - minX, height: maxY - minY);
}

double _clamp(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

final class _TestBounds {
  const _TestBounds({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}
