import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPreset footprintStrategy', () {
    test('legacy footprint fixed keeps footprint as source of truth', () {
      final footprint = _legacyFootprint();
      final preset = _legacyFootprintPreset(footprint: footprint);

      expect(
          preset.geometryMode, ProjectedBuildingShadowGeometryMode.footprint);
      expect(preset.footprint, footprint);
    });

    test('legacy footprint fixed keeps footprintStrategy null', () {
      final preset = _legacyFootprintPreset();

      expect(preset.footprintStrategy, isNull);
    });

    test('directional rejects footprintStrategy', () {
      expect(
        () => _directionalPreset(footprintStrategy: _adaptiveStrategy()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('directional still rejects footprint', () {
      expect(
        () => _directionalPreset(footprint: _legacyFootprint()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('directional accepts no footprint and no footprintStrategy', () {
      final preset = _directionalPreset();

      expect(
          preset.geometryMode, ProjectedBuildingShadowGeometryMode.directional);
      expect(preset.footprint, isNull);
      expect(preset.footprintStrategy, isNull);
    });

    test('footprint rejects missing footprint and missing footprintStrategy',
        () {
      expect(
        () => ProjectBuildingShadowPreset(
          id: 'shadow',
          name: 'Shadow',
          direction: _direction(),
          shape: _shape(),
          appearance: _appearance(),
          timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
          geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('footprint accepts adaptive footprintStrategy with null footprint',
        () {
      final strategy = _adaptiveStrategy();
      final preset = _adaptivePreset(footprintStrategy: strategy);

      expect(
          preset.geometryMode, ProjectedBuildingShadowGeometryMode.footprint);
      expect(preset.footprint, isNull);
      expect(preset.footprintStrategy, strategy);
    });

    test('footprint adaptive rejects non-null footprint', () {
      expect(
        () => _adaptivePreset(
          footprint: _legacyFootprint(),
          footprintStrategy: _adaptiveStrategy(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('footprint rejects fixed footprintStrategy in V0', () {
      expect(
        () => _adaptivePreset(
          footprintStrategy: ProjectedShadowFootprintFixedTuning(
            tuning: _legacyFootprint(),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('equality includes footprintStrategy', () {
      final first = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final same = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final changed = _adaptivePreset(
        footprintStrategy: _adaptiveStrategyVariant(),
      );

      expect(first, same);
      expect(first, isNot(changed));
    });

    test('hashCode includes footprintStrategy', () {
      final first = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final same = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final changed = _adaptivePreset(
        footprintStrategy: _adaptiveStrategyVariant(),
      );

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changed.hashCode));
    });
  });
}

ProjectedShadowDirection _direction() {
  return ProjectedShadowDirection(x: 1, y: 0);
}

ProjectedShadowShapeTuning _shape() {
  return ProjectedShadowShapeTuning(
    lengthRatio: 0.5,
    nearWidthRatio: 1,
    farWidthRatio: 0.5,
  );
}

ProjectedShadowAppearance _appearance() {
  return ProjectedShadowAppearance(opacity: 0.24, colorHexRgb: '606060');
}

ProjectedShadowFootprintTuning _legacyFootprint() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _targetFootprint() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy() {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: _legacyFootprint(),
    target: _targetFootprint(),
    gate: ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: 0.24,
    targetOpacity: 0.22,
  );
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategyVariant() {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: _legacyFootprint(),
    target: ProjectedShadowFootprintTuning(
      attachYRatio: 0.80,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.48,
      depthRatio: 0.42,
      skewXRatio: 0.08,
    ),
    gate: ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: 0.24,
    targetOpacity: 0.22,
  );
}

ProjectBuildingShadowPreset _directionalPreset({
  ProjectedShadowFootprintTuning? footprint,
  ProjectedShadowFootprintTuningStrategy? footprintStrategy,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: _direction(),
    shape: _shape(),
    appearance: _appearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    footprint: footprint,
    footprintStrategy: footprintStrategy,
  );
}

ProjectBuildingShadowPreset _legacyFootprintPreset({
  ProjectedShadowFootprintTuning? footprint,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: _direction(),
    shape: _shape(),
    appearance: _appearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    footprint: footprint ?? _legacyFootprint(),
  );
}

ProjectBuildingShadowPreset _adaptivePreset({
  ProjectedShadowFootprintTuning? footprint,
  required ProjectedShadowFootprintTuningStrategy footprintStrategy,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: _direction(),
    shape: _shape(),
    appearance: _appearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    footprint: footprint,
    footprintStrategy: footprintStrategy,
  );
}
