import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedStaticShadowPoint', () {
    test('valid point accepted', () {
      final point = ProjectedStaticShadowPoint(x: 1, y: 2);

      expect(point.x, 1);
      expect(point.y, 2);
    });

    test('rejects non-finite coordinates', () {
      for (final value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => ProjectedStaticShadowPoint(x: value, y: 0),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ProjectedStaticShadowPoint(x: 0, y: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include x and y', () {
      final first = ProjectedStaticShadowPoint(x: 1, y: 2);
      final same = ProjectedStaticShadowPoint(x: 1, y: 2);
      final different = ProjectedStaticShadowPoint(x: 2, y: 2);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('StaticShadowProjectionSpec', () {
    test('default spec has stable expected values', () {
      expect(defaultStaticShadowProjectionDirectionX, 1);
      expect(defaultStaticShadowProjectionDirectionY, 0.45);
      expect(defaultStaticShadowProjectionLengthRatio, 0.32);
      expect(defaultStaticShadowProjectionNearWidthMultiplier, 0.92);
      expect(defaultStaticShadowProjectionFarWidthMultiplier, 1.18);
      expect(
        defaultStaticShadowProjectionSpec,
        StaticShadowProjectionSpec(
          directionX: 1,
          directionY: 0.45,
          lengthRatio: 0.32,
          nearWidthMultiplier: 0.92,
          farWidthMultiplier: 1.18,
        ),
      );
    });

    test('valid direction accepted', () {
      final spec = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.8,
        farWidthMultiplier: 1.2,
      );

      expect(spec.directionX, -1);
      expect(spec.directionY, 0.5);
      expect(spec.lengthRatio, 0.25);
      expect(spec.nearWidthMultiplier, 0.8);
      expect(spec.farWidthMultiplier, 1.2);
    });

    test('rejects zero direction', () {
      expect(
        () => StaticShadowProjectionSpec(
          directionX: 0,
          directionY: 0,
          lengthRatio: 0.25,
          nearWidthMultiplier: 1,
          farWidthMultiplier: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-finite direction', () {
      for (final value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowProjectionSpec(
            directionX: value,
            directionY: 1,
            lengthRatio: 0.25,
            nearWidthMultiplier: 1,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: value,
            lengthRatio: 0.25,
            nearWidthMultiplier: 1,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid positive fields', () {
      for (final value in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: 1,
            lengthRatio: value,
            nearWidthMultiplier: 1,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: 1,
            lengthRatio: 0.25,
            nearWidthMultiplier: value,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: 1,
            lengthRatio: 0.25,
            nearWidthMultiplier: 1,
            farWidthMultiplier: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include all fields', () {
      final first = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );
      final same = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );
      final different = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('ProjectedStaticShadowOpacityBand', () {
    test('default opacity bands are stable and fade toward the far edge', () {
      final bands = createProjectedStaticShadowOpacityBands();

      expect(bands, hasLength(7));
      expect(bands.first.startT, 0);
      expect(bands.last.endT, 1);
      expect(bands.first.opacityScale, greaterThan(bands.last.opacityScale));
      expect(bands.last.opacityScale, closeTo(0.5542857143, 0.000001));
      expect(() => bands.add(bands.first), throwsUnsupportedError);
    });

    test('custom opacity bands cover 0..1 without overlap', () {
      final bands = createProjectedStaticShadowOpacityBands(
        bandCount: 4,
        nearOpacityScale: 0.8,
        farOpacityScale: 0.2,
      );

      expect(
        bands.map((band) => [band.startT, band.endT]),
        [
          [0.0, 0.25],
          [0.25, 0.5],
          [0.5, 0.75],
          [0.75, 1.0],
        ],
      );
      expect(bands.first.opacityScale, closeTo(0.725, 0.000001));
      expect(bands.last.opacityScale, closeTo(0.275, 0.000001));
    });

    test('rejects invalid opacity band inputs', () {
      expect(
        () => createProjectedStaticShadowOpacityBands(bandCount: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createProjectedStaticShadowOpacityBands(nearOpacityScale: 1.2),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createProjectedStaticShadowOpacityBands(farOpacityScale: 1.2),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createProjectedStaticShadowOpacityBands(
          nearOpacityScale: 0.2,
          farOpacityScale: 0.8,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('opacity band equality includes all fields', () {
      final first = ProjectedStaticShadowOpacityBand(
        startT: 0,
        endT: 0.5,
        opacityScale: 0.8,
      );
      final same = ProjectedStaticShadowOpacityBand(
        startT: 0,
        endT: 0.5,
        opacityScale: 0.8,
      );
      final different = ProjectedStaticShadowOpacityBand(
        startT: 0.5,
        endT: 1,
        opacityScale: 0.4,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('ProjectedStaticShadowGeometry', () {
    test('valid four-point polygon accepted', () {
      final geometry = _projectedGeometry();

      expect(geometry.nearLeft, ProjectedStaticShadowPoint(x: 0, y: 0));
      expect(geometry.nearRight, ProjectedStaticShadowPoint(x: 10, y: 0));
      expect(geometry.farRight, ProjectedStaticShadowPoint(x: 12, y: 8));
      expect(geometry.farLeft, ProjectedStaticShadowPoint(x: -2, y: 8));
    });

    test('rejects degenerate polygon', () {
      final point = ProjectedStaticShadowPoint(x: 0, y: 0);

      expect(
        () => ProjectedStaticShadowGeometry(
          nearLeft: point,
          nearRight: point,
          farRight: point,
          farLeft: point,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('points getter returns ordered polygon points', () {
      final geometry = _projectedGeometry();

      expect(
        geometry.points,
        [
          geometry.nearLeft,
          geometry.nearRight,
          geometry.farRight,
          geometry.farLeft,
        ],
      );
    });

    test('equality and hashCode include all four points', () {
      final first = _projectedGeometry();
      final same = _projectedGeometry();
      final different = ProjectedStaticShadowGeometry(
        nearLeft: ProjectedStaticShadowPoint(x: 0, y: 0),
        nearRight: ProjectedStaticShadowPoint(x: 9, y: 0),
        farRight: ProjectedStaticShadowPoint(x: 12, y: 8),
        farLeft: ProjectedStaticShadowPoint(x: -2, y: 8),
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('resolveProjectedStaticShadowGeometry', () {
    test('default projection moves far edge down-right', () {
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(),
      );

      final nearCenter = _midpoint(projected.nearLeft, projected.nearRight);
      final farCenter = _midpoint(projected.farLeft, projected.farRight);

      expect(farCenter.x, greaterThan(nearCenter.x));
      expect(farCenter.y, greaterThan(nearCenter.y));
    });

    test('custom down-left direction moves far edge down-left', () {
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(),
        projectionSpec: StaticShadowProjectionSpec(
          directionX: -1,
          directionY: 0.5,
          lengthRatio: 0.25,
          nearWidthMultiplier: 1,
          farWidthMultiplier: 1,
        ),
      );

      final nearCenter = _midpoint(projected.nearLeft, projected.nearRight);
      final farCenter = _midpoint(projected.farLeft, projected.farRight);

      expect(farCenter.x, lessThan(nearCenter.x));
      expect(farCenter.y, greaterThan(nearCenter.y));
    });

    test('projection length uses metrics visualHeight', () {
      final short = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(visualHeight: 40),
        projectionSpec: _horizontalProjectionSpec(),
      );
      final tall = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(visualHeight: 80),
        projectionSpec: _horizontalProjectionSpec(),
      );

      final shortNear = _midpoint(short.nearLeft, short.nearRight);
      final shortFar = _midpoint(short.farLeft, short.farRight);
      final tallNear = _midpoint(tall.nearLeft, tall.nearRight);
      final tallFar = _midpoint(tall.farLeft, tall.farRight);

      expect(shortFar.x - shortNear.x, closeTo(10, 0.000001));
      expect(tallFar.x - tallNear.x, closeTo(20, 0.000001));
    });

    test('near and far widths use base width multipliers', () {
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 20),
        metrics: _metrics(),
        projectionSpec: StaticShadowProjectionSpec(
          directionX: 1,
          directionY: 0,
          lengthRatio: 0.25,
          nearWidthMultiplier: 0.5,
          farWidthMultiplier: 1.5,
        ),
      );

      expect(_distance(projected.nearLeft, projected.nearRight), 10);
      expect(_distance(projected.farLeft, projected.farRight), 30);
    });

    test('changing base height does not change polygon width', () {
      final flat = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 20, height: 4),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );
      final tall = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 20, height: 40),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );

      expect(
        _distance(flat.nearLeft, flat.nearRight),
        _distance(tall.nearLeft, tall.nearRight),
      );
      expect(
        _distance(flat.farLeft, flat.farRight),
        _distance(tall.farLeft, tall.farRight),
      );
    });

    test('changing base width changes near and far widths', () {
      final narrow = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 10),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );
      final wide = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 30),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );

      expect(
        _distance(wide.nearLeft, wide.nearRight),
        greaterThan(_distance(narrow.nearLeft, narrow.nearRight)),
      );
      expect(
        _distance(wide.farLeft, wide.farRight),
        greaterThan(_distance(narrow.farLeft, narrow.farRight)),
      );
    });

    test('output points are finite and inputs are unchanged', () {
      final base = _baseGeometry();
      final metrics = _metrics();
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      for (final point in projected.points) {
        expect(point.x.isFinite, isTrue);
        expect(point.y.isFinite, isTrue);
      }
      expect(base, _baseGeometry());
      expect(metrics, _metrics());
    });

    test('composes with resolveStaticShadowGeometry without double scaling',
        () {
      final metrics = StaticShadowVisualMetrics(
        left: 10,
        top: 20,
        visualWidth: 32,
        visualHeight: 64,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 2, scaleY: 3),
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.25,
          footprintHeightRatio: 0.08,
        ),
      );
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: base,
        metrics: metrics,
        projectionSpec: StaticShadowProjectionSpec(
          directionX: 1,
          directionY: 0,
          lengthRatio: 0.25,
          nearWidthMultiplier: 1,
          farWidthMultiplier: 1,
        ),
      );

      expect(base.width, 16);
      expect(_distance(projected.nearLeft, projected.nearRight), 16);
      expect(_distance(projected.farLeft, projected.farRight), 16);
      expect(
        _midpoint(projected.farLeft, projected.farRight).x -
            _midpoint(projected.nearLeft, projected.nearRight).x,
        16,
      );
    });
  });
}

ProjectedStaticShadowGeometry _projectedGeometry() {
  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(x: 0, y: 0),
    nearRight: ProjectedStaticShadowPoint(x: 10, y: 0),
    farRight: ProjectedStaticShadowPoint(x: 12, y: 8),
    farLeft: ProjectedStaticShadowPoint(x: -2, y: 8),
  );
}

ResolvedStaticShadowGeometry _baseGeometry({
  double width = 24,
  double height = 8,
}) {
  return ResolvedStaticShadowGeometry(
    anchorX: 32,
    anchorY: 88,
    baseWidth: width,
    baseHeight: height,
    centerX: 32,
    centerY: 88,
    width: width,
    height: height,
    left: 32 - width / 2,
    top: 88 - height / 2,
  );
}

StaticShadowVisualMetrics _metrics({double visualHeight = 64}) {
  return StaticShadowVisualMetrics(
    left: 16,
    top: 24,
    visualWidth: 32,
    visualHeight: visualHeight,
  );
}

ResolvedShadowConfig _shadowConfig({
  double scaleX = 1,
  double scaleY = 1,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'test-shadow',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: 0,
    offsetY: 0,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: 0.35,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}

StaticShadowProjectionSpec _horizontalProjectionSpec() {
  return StaticShadowProjectionSpec(
    directionX: 1,
    directionY: 0,
    lengthRatio: 0.25,
    nearWidthMultiplier: 1,
    farWidthMultiplier: 1,
  );
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
