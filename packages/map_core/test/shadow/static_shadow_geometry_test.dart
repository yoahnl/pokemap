import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowVisualMetrics', () {
    test('accepts valid metrics', () {
      final metrics = StaticShadowVisualMetrics(
        left: 16,
        top: 24,
        visualWidth: 32,
        visualHeight: 64,
      );

      expect(metrics.left, 16);
      expect(metrics.top, 24);
      expect(metrics.visualWidth, 32);
      expect(metrics.visualHeight, 64);
    });

    test('rejects non-finite left and top', () {
      for (final value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowVisualMetrics(
            left: value,
            top: 0,
            visualWidth: 32,
            visualHeight: 64,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowVisualMetrics(
            left: 0,
            top: value,
            visualWidth: 32,
            visualHeight: 64,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid visual sizes', () {
      for (final value in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowVisualMetrics(
            left: 0,
            top: 0,
            visualWidth: value,
            visualHeight: 64,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowVisualMetrics(
            left: 0,
            top: 0,
            visualWidth: 32,
            visualHeight: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include all fields', () {
      final first = StaticShadowVisualMetrics(
        left: 16,
        top: 24,
        visualWidth: 32,
        visualHeight: 64,
      );
      final same = StaticShadowVisualMetrics(
        left: 16,
        top: 24,
        visualWidth: 32,
        visualHeight: 64,
      );
      final different = StaticShadowVisualMetrics(
        left: 17,
        top: 24,
        visualWidth: 32,
        visualHeight: 64,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('ResolvedStaticShadowFootprint', () {
    test('defaults match current V0 ratios', () {
      expect(
        resolveStaticShadowFootprint(),
        ResolvedStaticShadowFootprint(
          anchorXRatio: 0.5,
          anchorYRatio: 1,
          footprintWidthRatio: 0.75,
          footprintHeightRatio: 0.25,
        ),
      );
    });

    test('element footprint overrides defaults field by field', () {
      final footprint = resolveStaticShadowFootprint(
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.4,
          footprintHeightRatio: 0.2,
        ),
      );

      expect(footprint.anchorXRatio, 0.4);
      expect(footprint.anchorYRatio, 1);
      expect(footprint.footprintWidthRatio, 0.75);
      expect(footprint.footprintHeightRatio, 0.2);
    });

    test('override footprint wins over element footprint field by field', () {
      final footprint = resolveStaticShadowFootprint(
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.4,
          anchorYRatio: 0.9,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
        overrideFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.8,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(
        footprint,
        ResolvedStaticShadowFootprint(
          anchorXRatio: 0.4,
          anchorYRatio: 0.8,
          footprintWidthRatio: 0.25,
          footprintHeightRatio: 0.2,
        ),
      );
    });

    test('rejects invalid direct resolved ratios', () {
      expect(
        () => ResolvedStaticShadowFootprint(
          anchorXRatio: -0.01,
          anchorYRatio: 1,
          footprintWidthRatio: 0.75,
          footprintHeightRatio: 0.25,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ResolvedStaticShadowFootprint(
          anchorXRatio: 0.5,
          anchorYRatio: 1,
          footprintWidthRatio: 0,
          footprintHeightRatio: 0.25,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('equality and hashCode include all fields', () {
      final first = ResolvedStaticShadowFootprint(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final same = ResolvedStaticShadowFootprint(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final different = ResolvedStaticShadowFootprint(
        anchorXRatio: 0.4,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('resolveStaticShadowGeometry', () {
    test('without footprint reproduces current V0 formula', () {
      final geometry = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
      );

      expect(
        geometry,
        ResolvedStaticShadowGeometry(
          anchorX: 32,
          anchorY: 88,
          baseWidth: 24,
          baseHeight: 16,
          centerX: 32,
          centerY: 88,
          width: 24,
          height: 16,
          left: 20,
          top: 80,
        ),
      );
    });

    test('element footprint changes anchor and footprint size', () {
      final geometry = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
      );

      expect(geometry.anchorX, 24);
      expect(geometry.anchorY, 56);
      expect(geometry.baseWidth, 16);
      expect(geometry.baseHeight, 8);
      expect(geometry.left, 16);
      expect(geometry.top, 52);
    });

    test('override footprint wins while partial override keeps element fields',
        () {
      final geometry = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
        overrideFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.75,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(geometry.anchorX, 24);
      expect(geometry.anchorY, 72);
      expect(geometry.baseWidth, 8);
      expect(geometry.baseHeight, 8);
      expect(geometry.left, 20);
      expect(geometry.top, 68);
    });

    test('offset and scale apply after footprint', () {
      final geometry = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(
          offsetX: 3,
          offsetY: -4,
          scaleX: 2,
          scaleY: 0.5,
        ),
      );

      expect(geometry.anchorX, 32);
      expect(geometry.anchorY, 88);
      expect(geometry.baseWidth, 24);
      expect(geometry.baseHeight, 16);
      expect(geometry.centerX, 35);
      expect(geometry.centerY, 84);
      expect(geometry.width, 48);
      expect(geometry.height, 8);
      expect(geometry.left, 11);
      expect(geometry.top, 80);
    });

    test('mode renderPass opacity color and softness do not affect geometry',
        () {
      final base = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
      );
      final changedStyle = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(
          mode: ShadowCasterMode.none,
          renderPass: ShadowRenderPass.actorContact,
          opacity: 0,
          colorHexRgb: 'FFFFFF',
        ),
      );

      expect(changedStyle, base);
    });

    test('rejects invalid direct geometry values', () {
      expect(
        () => ResolvedStaticShadowGeometry(
          anchorX: double.nan,
          anchorY: 88,
          baseWidth: 24,
          baseHeight: 16,
          centerX: 32,
          centerY: 88,
          width: 24,
          height: 16,
          left: 20,
          top: 80,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ResolvedStaticShadowGeometry(
          anchorX: 32,
          anchorY: 88,
          baseWidth: 0,
          baseHeight: 16,
          centerX: 32,
          centerY: 88,
          width: 24,
          height: 16,
          left: 20,
          top: 80,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ResolvedStaticShadowGeometry(
          anchorX: 32,
          anchorY: 88,
          baseWidth: 24,
          baseHeight: 16,
          centerX: 32,
          centerY: 88,
          width: 0,
          height: 16,
          left: 20,
          top: 80,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('equality and hashCode include all fields', () {
      final first = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
      );
      final same = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
      );
      final different = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(offsetX: 1),
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('static shadow geometry integration with existing configs', () {
    test('ProjectElementShadowConfig footprint can be passed directly', () {
      final elementShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'ground',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
      );

      final geometry = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
        elementFootprint: elementShadow.footprint,
      );

      expect(geometry.anchorX, 24);
      expect(geometry.anchorY, 88);
    });

    test('MapPlacedElementShadowOverride footprint can be passed directly', () {
      final placedOverride = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        footprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );

      final geometry = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
        overrideFootprint: placedOverride.footprint,
      );

      expect(geometry.anchorX, 32);
      expect(geometry.anchorY, 72);
    });

    test(
        'custom override with null footprint uses element or default footprint',
        () {
      final placedOverride = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        offsetX: 1,
      );

      final withElement = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: placedOverride.footprint,
      );
      final withoutElement = resolveStaticShadowGeometry(
        metrics: _defaultMetrics(),
        shadowConfig: _shadowConfig(),
        overrideFootprint: placedOverride.footprint,
      );

      expect(withElement.anchorX, 24);
      expect(withoutElement.anchorX, 32);
    });
  });
}

StaticShadowVisualMetrics _defaultMetrics() {
  return StaticShadowVisualMetrics(
    left: 16,
    top: 24,
    visualWidth: 32,
    visualHeight: 64,
  );
}

ResolvedShadowConfig _shadowConfig({
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'ground',
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}
