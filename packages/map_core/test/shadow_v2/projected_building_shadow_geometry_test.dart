import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Projected building shadow geometry', () {
    test('disabled config returns null', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(enabled: false),
        preset: _preset(),
        metrics: _metrics(),
      );

      expect(geometry, isNull);
    });

    test('resolves basic horizontal geometry with stable point order', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          direction: ProjectedShadowDirection(x: 1, y: 0),
          shape: ProjectedShadowShapeTuning(
            lengthRatio: 0.5,
            nearWidthRatio: 1,
            farWidthRatio: 0.5,
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 60, y: 50);
      _expectPointClose(geometry.points[1], x: 60, y: 150);
      _expectPointClose(geometry.points[2], x: 100, y: 125);
      _expectPointClose(geometry.points[3], x: 100, y: 75);
    });

    test('normalizes direction before applying length', () {
      final unit = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 1, y: 0)),
        metrics: _metrics(),
      );
      final scaled = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 2, y: 0)),
        metrics: _metrics(),
      );

      expect(scaled, unit);
    });

    test('resolves vertical direction geometry', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 0, y: 1)),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 110, y: 100);
      _expectPointClose(geometry.points[1], x: 10, y: 100);
      _expectPointClose(geometry.points[2], x: 35, y: 140);
      _expectPointClose(geometry.points[3], x: 85, y: 140);
    });

    test('localOffset shifts all points', () {
      final withoutOffset = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(),
        metrics: _metrics(),
      );
      final withOffset = resolveProjectedBuildingShadowGeometry(
        config: _config(offset: ProjectedShadowOffset(x: 5, y: -3)),
        preset: _preset(),
        metrics: _metrics(),
      );

      expect(withoutOffset, isNotNull);
      expect(withOffset, isNotNull);
      for (var index = 0; index < withoutOffset!.points.length; index += 1) {
        _expectPointClose(
          withOffset!.points[index],
          x: withoutOffset.points[index].x + 5,
          y: withoutOffset.points[index].y - 3,
        );
      }
    });

    test('shape ratios control length and widths', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          shape: ProjectedShadowShapeTuning(
            lengthRatio: 0.25,
            nearWidthRatio: 0.5,
            farWidthRatio: 0.75,
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 60, y: 75);
      _expectPointClose(geometry.points[1], x: 60, y: 125);
      _expectPointClose(geometry.points[2], x: 80, y: 137.5);
      _expectPointClose(geometry.points[3], x: 80, y: 62.5);
    });

    test('propagates preset appearance', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          appearance: ProjectedShadowAppearance(
            opacity: 0.42,
            colorHexRgb: '445566',
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.42);
      expect(geometry.colorHexRgb, '445566');
    });

    test('followsSun uses preset direction as fixed in V0', () {
      final fixed = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed),
        metrics: _metrics(),
      );
      final followsSun = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun),
        metrics: _metrics(),
      );

      expect(followsSun, fixed);
    });

    test('resolves pokemon-building-shadow-v0 geometry with calibrated points',
        () {
      final preset = ProjectBuildingShadowPreset(
        id: 'pokemon-building-shadow-v0',
        name: 'Pokemon-like building shadow V0',
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.90,
          farWidthRatio: 0.72,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.30,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
      final config = ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'pokemon-building-shadow-v0',
        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
        localOffset: ProjectedShadowOffset(x: 0, y: 0),
      );
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: config,
        preset: preset,
        metrics: StaticShadowVisualMetrics(
          left: 32,
          top: 64,
          visualWidth: 64,
          visualHeight: 96,
        ),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.30);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      _expectPointClose(
        geometry.points[0],
        x: 75.54,
        y: 129.77,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[1],
        x: 52.46,
        y: 182.55,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[2],
        x: 82.91,
        y: 189.58,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[3],
        x: 101.38,
        y: 147.36,
        tolerance: 0.02,
      );
    });

    test('resolves footprint geometry with attached skewed rectangle points',
        () {
      final preset = ProjectBuildingShadowPreset(
        id: 'pokemon-building-shadow-footprint-v0',
        name: 'Pokemon-like footprint building shadow V0',
        direction: ProjectedShadowDirection(x: 1, y: 0),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0,
          nearWidthRatio: 1,
          farWidthRatio: 1,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.28,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: ProjectedShadowFootprintTuning(),
      );
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: ProjectElementProjectedBuildingShadowConfig(
          enabled: true,
          presetId: 'pokemon-building-shadow-footprint-v0',
          anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
          localOffset: ProjectedShadowOffset(x: 0, y: 0),
        ),
        preset: preset,
        metrics: StaticShadowVisualMetrics(
          left: 32,
          top: 64,
          visualWidth: 64,
          visualHeight: 96,
        ),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.28);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      _expectPointClose(
        geometry.points[0],
        x: 28.80,
        y: 146.56,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[1],
        x: 99.20,
        y: 146.56,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[2],
        x: 108.80,
        y: 173.44,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[3],
        x: 32.00,
        y: 173.44,
        tolerance: 0.02,
      );
    });

    test(
        'resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points',
        () {
      final preset = ProjectBuildingShadowPreset(
        id: 'pokemon-building-shadow-footprint-v1',
        name: 'Pokemon-like footprint building shadow V1',
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.90,
          farWidthRatio: 0.72,
        ),
        footprint: ProjectedShadowFootprintTuning(
          attachYRatio: 0.82,
          frontWidthRatio: 1.30,
          rearWidthRatio: 1.42,
          depthRatio: 0.26,
          skewXRatio: 0.08,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.24,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
      final config = ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'pokemon-building-shadow-footprint-v1',
        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
        localOffset: ProjectedShadowOffset(x: 0, y: 0),
      );
      final metrics = StaticShadowVisualMetrics(
        left: 32,
        top: 64,
        visualWidth: 64,
        visualHeight: 96,
      );
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: config,
        preset: preset,
        metrics: metrics,
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.24);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      _expectPointClose(
        geometry.points[0],
        x: 22.40,
        y: 142.72,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[1],
        x: 105.60,
        y: 142.72,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[2],
        x: 114.56,
        y: 167.68,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[3],
        x: 23.68,
        y: 167.68,
        tolerance: 0.02,
      );
    });

    test('footprint geometry localOffset shifts all points', () {
      final preset = _footprintPreset();
      final withoutOffset = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(),
        preset: preset,
        metrics: _footprintMetrics(),
      );
      final withOffset = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(
          offset: ProjectedShadowOffset(x: 5, y: -3),
        ),
        preset: preset,
        metrics: _footprintMetrics(),
      );

      expect(withoutOffset, isNotNull);
      expect(withOffset, isNotNull);
      for (var index = 0; index < withoutOffset!.points.length; index += 1) {
        _expectPointClose(
          withOffset!.points[index],
          x: withoutOffset.points[index].x + 5,
          y: withoutOffset.points[index].y - 3,
          tolerance: 0.02,
        );
      }
    });

    test('footprint geometry ignores anchor', () {
      final preset = _footprintPreset();
      final centeredAnchor = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(
          anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
        ),
        preset: preset,
        metrics: _footprintMetrics(),
      );
      final shiftedAnchor = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(
          anchor: ProjectedShadowAnchor(xRatio: 0.1, yRatio: 0.2),
        ),
        preset: preset,
        metrics: _footprintMetrics(),
      );

      expect(shiftedAnchor, centeredAnchor);
    });

    test('geometry defensively copies points and exposes an immutable list',
        () {
      final source = [
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ];
      final geometry = ProjectedBuildingShadowGeometry(
        points: source,
        opacity: 0.5,
        colorHexRgb: '000000',
      );

      source[0] = ProjectedBuildingShadowPoint(x: 99, y: 99);

      expect(geometry.points[0], ProjectedBuildingShadowPoint(x: 0, y: 0));
      expect(
        () => geometry.points.add(ProjectedBuildingShadowPoint(x: 1, y: 1)),
        throwsUnsupportedError,
      );
    });

    test('point and geometry equality include ordered values', () {
      final firstPoint = ProjectedBuildingShadowPoint(x: 1, y: 2);
      final samePoint = ProjectedBuildingShadowPoint(x: 1, y: 2);
      final differentPoint = ProjectedBuildingShadowPoint(x: 2, y: 2);

      expect(firstPoint, samePoint);
      expect(firstPoint.hashCode, samePoint.hashCode);
      expect(firstPoint, isNot(differentPoint));

      final first = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);
      final same = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);
      final reordered = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(reordered));
    });

    test('geometry validates points, opacity, and color', () {
      expect(
        () => ProjectedBuildingShadowPoint(x: double.nan, y: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: [
            ProjectedBuildingShadowPoint(x: 0, y: 0),
            ProjectedBuildingShadowPoint(x: 1, y: 1),
            ProjectedBuildingShadowPoint(x: 2, y: 2),
          ],
          opacity: 0.5,
          colorHexRgb: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: _validPoints(),
          opacity: 1.1,
          colorHexRgb: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: _validPoints(),
          opacity: 0.5,
          colorHexRgb: '00000G',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('geometry source stays independent from runtime editor and manifest',
        () {
      final source = File(
        'lib/src/operations/projected_building_shadow_geometry.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('map_runtime')));
      expect(source, isNot(contains('map_editor')));
      expect(source, isNot(contains('ProjectManifest')));
      expect(source, isNot(contains('ProjectElementEntry')));
      expect(source, isNot(contains('ProjectBuildingShadowPresetCatalog')));
      expect(source, isNot(contains('projected_building_shadow_diagnostics')));
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  ProjectedShadowOffset? offset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: 'short-west',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: offset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset({
  ProjectedShadowDirection? direction,
  ProjectedShadowShapeTuning? shape,
  ProjectedShadowAppearance? appearance,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
}) {
  return ProjectBuildingShadowPreset(
    id: 'short-west',
    name: 'Short west shadow',
    direction: direction ?? ProjectedShadowDirection(x: 1, y: 0),
    shape: shape ??
        ProjectedShadowShapeTuning(
          lengthRatio: 0.5,
          nearWidthRatio: 1,
          farWidthRatio: 0.5,
        ),
    appearance: appearance ?? ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: timeOfDayMode,
  );
}

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0,
      nearWidthRatio: 1,
      farWidthRatio: 1,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    footprint: ProjectedShadowFootprintTuning(),
  );
}

ProjectElementProjectedBuildingShadowConfig _footprintConfig({
  ProjectedShadowAnchor? anchor,
  ProjectedShadowOffset? offset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-footprint-v0',
    anchor: anchor ?? ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: offset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}

StaticShadowVisualMetrics _footprintMetrics() {
  return StaticShadowVisualMetrics(
    left: 32,
    top: 64,
    visualWidth: 64,
    visualHeight: 96,
  );
}

StaticShadowVisualMetrics _metrics() {
  return StaticShadowVisualMetrics(
    left: 10,
    top: 20,
    visualWidth: 100,
    visualHeight: 80,
  );
}

ProjectedBuildingShadowGeometry _geometry(
  List<ProjectedBuildingShadowPoint> points,
) {
  return ProjectedBuildingShadowGeometry(
    points: points,
    opacity: 0.5,
    colorHexRgb: '000000',
  );
}

List<ProjectedBuildingShadowPoint> _validPoints() {
  return [
    ProjectedBuildingShadowPoint(x: 0, y: 0),
    ProjectedBuildingShadowPoint(x: 0, y: 10),
    ProjectedBuildingShadowPoint(x: 10, y: 10),
    ProjectedBuildingShadowPoint(x: 10, y: 0),
  ];
}

void _expectPointClose(
  ProjectedBuildingShadowPoint actual, {
  required double x,
  required double y,
  double tolerance = 0.000001,
}) {
  expect(actual.x, closeTo(x, tolerance));
  expect(actual.y, closeTo(y, tolerance));
}
