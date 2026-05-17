import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveStaticShadowFamily', () {
    test('uses generic projection when no family is provided', () {
      expect(
        resolveStaticShadowFamily(),
        StaticShadowFamily.genericProjection,
      );
    });

    test('uses element family when no override family is provided', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
        ),
        StaticShadowFamily.building,
      );
    });

    test('uses override family over element family', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
          overrideFamily: StaticShadowFamily.tallProp,
        ),
        StaticShadowFamily.tallProp,
      );
    });
  });

  group('resolveStaticShadowFamilyProjectionSpec', () {
    test('genericProjection returns the base projection unchanged', () {
      final base = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.4,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );

      expect(
        resolveStaticShadowFamilyProjectionSpec(
          family: StaticShadowFamily.genericProjection,
          baseProjectionSpec: base,
        ),
        base,
      );
    });

    test('preserves base direction for every non-generic family', () {
      final base = StaticShadowProjectionSpec(
        directionX: -0.75,
        directionY: 0.35,
        lengthRatio: 0.32,
        nearWidthMultiplier: 0.92,
        farWidthMultiplier: 1.18,
      );

      for (final family in <StaticShadowFamily>[
        StaticShadowFamily.compactProp,
        StaticShadowFamily.tallProp,
        StaticShadowFamily.building,
        StaticShadowFamily.foliage,
      ]) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX, base.directionX);
        expect(spec.directionY, base.directionY);
      }
    });

    test('compact props are shorter and tighter than generic projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('tall props are narrow and shorter than generic', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('buildings keep a broad but shorter block-like projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );
      final tall = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.nearWidthMultiplier,
        greaterThan(tall.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('foliage is broader than tall prop', () {
      final foliage = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );
      final tallProp = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        foliage.nearWidthMultiplier,
        greaterThan(tallProp.nearWidthMultiplier),
      );
      expect(
        foliage.farWidthMultiplier,
        greaterThan(tallProp.farWidthMultiplier),
      );
    });

    test('compactProp Shadow-54 calibration is readable and tapered', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(spec.lengthRatio, closeTo(0.1120, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.5200, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.4300, 0.0000001));
      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
    });

    test('tallProp Shadow-54 calibration stays narrow but visible', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(spec.lengthRatio, closeTo(0.1280, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.5400, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.4000, 0.0000001));
      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
    });

    test('building Shadow-54 calibration keeps a grounded block projection',
        () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );

      expect(spec.lengthRatio, closeTo(0.1120, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.6400, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.5400, 0.0000001));
      expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
    });

    test('foliage Shadow-54 calibration is broader than tall props', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );
      final tall = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(spec.lengthRatio, closeTo(0.1300, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.7000, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.6400, 0.0000001));
      expect(spec.nearWidthMultiplier, greaterThan(tall.nearWidthMultiplier));
    });

    test('scaled family specs remain valid for a custom positive base', () {
      final base = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.45,
        lengthRatio: 0.1,
        nearWidthMultiplier: 0.2,
        farWidthMultiplier: 0.3,
      );

      for (final family in StaticShadowFamily.values) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX.isFinite, isTrue);
        expect(spec.directionY.isFinite, isTrue);
        expect(spec.lengthRatio, greaterThan(0));
        expect(spec.nearWidthMultiplier, greaterThan(0));
        expect(spec.farWidthMultiplier, greaterThan(0));
      }
    });
  });

  group('family projection geometry composition', () {
    test('tall prop polygon stays much narrower than building polygon', () {
      final tall = _projectedCase(
        family: StaticShadowFamily.tallProp,
        visualWidth: 16,
        visualHeight: 64,
        footprintWidthRatio: 0.18,
        footprintHeightRatio: 0.07,
      );
      final building = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 96,
        visualHeight: 80,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      );

      expect(_maxWidth(tall), lessThan(_maxWidth(building) * 0.45));
      expect(_polygonArea(tall), lessThan(_polygonArea(building) * 0.45));
    });

    test('compact prop projects less area than generic for same metrics', () {
      final compact = _projectedCase(
        family: StaticShadowFamily.compactProp,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );
      final generic = _projectedCase(
        family: StaticShadowFamily.genericProjection,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );

      expect(_polygonArea(compact), lessThan(_polygonArea(generic)));
    });

    test('Selbrume lamp projected geometry is narrow but readable', () {
      final geometry = _projectedCase(
        family: StaticShadowFamily.tallProp,
        visualWidth: 96,
        visualHeight: 160,
        footprintWidthRatio: 0.28 * 0.80,
        footprintHeightRatio: 0.05 * 0.55,
      );

      expect(_projectedLength(geometry), greaterThan(20));
      expect(_maxWidth(geometry), greaterThan(10));
      expect(_maxWidth(geometry), lessThan(16));
      expect(_polygonArea(geometry), greaterThan(180));
    });

    test(
        'building Shadow-54 projected geometry stays compact for a Selbrume house',
        () {
      final geometry = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 192,
        visualHeight: 224,
        footprintWidthRatio: 0.60 * 0.72,
        footprintHeightRatio: 0.06 * 0.48,
      );

      expect(_projectedLength(geometry), greaterThan(24));
      expect(_projectedLength(geometry), lessThan(27));
      expect(_maxWidth(geometry), greaterThan(50));
      expect(_maxWidth(geometry), lessThan(56));
      expect(_polygonArea(geometry), greaterThan(1100));
      expect(_polygonArea(geometry), lessThan(1400));
    });

    test(
        'building Shadow-54 projected area is far smaller than legacy Selbrume slab',
        () {
      final calibrated = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 192,
        visualHeight: 224,
        footprintWidthRatio: 0.60 * 0.72,
        footprintHeightRatio: 0.06 * 0.48,
      );
      final legacy = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 192,
        visualHeight: 224,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12 * 0.85,
        projectionSpec: StaticShadowProjectionSpec(
          directionX: defaultStaticShadowProjectionDirectionX,
          directionY: defaultStaticShadowProjectionDirectionY,
          lengthRatio: 0.1984,
          nearWidthMultiplier: 0.7176,
          farWidthMultiplier: 0.7316,
        ),
      );

      expect(
        _polygonArea(calibrated),
        lessThan(_polygonArea(legacy) * 0.30),
      );
    });
  });
}

ProjectedStaticShadowGeometry _projectedCase({
  required StaticShadowFamily family,
  required double visualWidth,
  required double visualHeight,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
  StaticShadowProjectionSpec? projectionSpec,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: 'default-ground-soft-ellipse',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: 0,
      offsetY: 0,
      scaleX: 1,
      scaleY: 1,
      opacity: 0.3,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: footprintHeightRatio,
    ),
  );

  return resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: projectionSpec ??
        resolveStaticShadowFamilyProjectionSpec(family: family),
  );
}

double _maxWidth(ProjectedStaticShadowGeometry geometry) {
  return [
    _distance(geometry.nearLeft, geometry.nearRight),
    _distance(geometry.farLeft, geometry.farRight),
  ].reduce((first, second) => first > second ? first : second);
}

double _projectedLength(ProjectedStaticShadowGeometry geometry) {
  final near = _midpoint(geometry.nearLeft, geometry.nearRight);
  final far = _midpoint(geometry.farLeft, geometry.farRight);
  return _distance(near, far);
}

ProjectedStaticShadowPoint _midpoint(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  return ProjectedStaticShadowPoint(
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  );
}

double _distance(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _polygonArea(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}
