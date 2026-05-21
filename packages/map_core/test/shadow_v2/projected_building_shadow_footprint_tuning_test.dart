import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowFootprintTuning', () {
    test('uses footprint V0 defaults', () {
      final tuning = ProjectedShadowFootprintTuning();

      expect(tuning.attachYRatio, 0.86);
      expect(tuning.frontWidthRatio, 1.10);
      expect(tuning.rearWidthRatio, 1.20);
      expect(tuning.depthRatio, 0.28);
      expect(tuning.skewXRatio, 0.10);
    });

    test('uses value equality and matching hashCode', () {
      final first = ProjectedShadowFootprintTuning(
        attachYRatio: 0.8,
        frontWidthRatio: 1.1,
        rearWidthRatio: 1.2,
        depthRatio: 0.3,
        skewXRatio: 0.1,
      );
      final same = ProjectedShadowFootprintTuning(
        attachYRatio: 0.8,
        frontWidthRatio: 1.1,
        rearWidthRatio: 1.2,
        depthRatio: 0.3,
        skewXRatio: 0.1,
      );
      final different = ProjectedShadowFootprintTuning(
        attachYRatio: 0.9,
        frontWidthRatio: 1.1,
        rearWidthRatio: 1.2,
        depthRatio: 0.3,
        skewXRatio: 0.1,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    test('rejects invalid attachYRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(attachYRatio: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(attachYRatio: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(attachYRatio: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid frontWidthRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(
          frontWidthRatio: double.infinity,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(frontWidthRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(frontWidthRatio: 2.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid rearWidthRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(rearWidthRatio: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(rearWidthRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(rearWidthRatio: 2.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid depthRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(depthRatio: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(depthRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(depthRatio: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid skewXRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(skewXRatio: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(skewXRatio: -0.51),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(skewXRatio: 0.51),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectBuildingShadowPreset footprint mode', () {
    test('defaults to directional geometry mode', () {
      final preset = _preset();

      expect(preset.geometryMode, ProjectedBuildingShadowGeometryMode.directional);
      expect(preset.footprint, isNull);
    });

    test('accepts directional without footprint', () {
      final preset = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.directional,
      );

      expect(preset.geometryMode, ProjectedBuildingShadowGeometryMode.directional);
      expect(preset.footprint, isNull);
    });

    test('rejects directional with footprint', () {
      expect(
        () => _preset(
          geometryMode: ProjectedBuildingShadowGeometryMode.directional,
          footprint: ProjectedShadowFootprintTuning(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts footprint with footprint tuning', () {
      final footprint = ProjectedShadowFootprintTuning();
      final preset = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: footprint,
      );

      expect(preset.geometryMode, ProjectedBuildingShadowGeometryMode.footprint);
      expect(preset.footprint, footprint);
    });

    test('rejects footprint without footprint tuning', () {
      expect(
        () => _preset(
          geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('equality and hashCode include geometryMode and footprint', () {
      final footprint = ProjectedShadowFootprintTuning();
      final first = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: footprint,
      );
      final same = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: footprint,
      );
      final directional = _preset();

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(directional));
    });
  });
}

ProjectBuildingShadowPreset _preset({
  ProjectedBuildingShadowGeometryMode geometryMode =
      ProjectedBuildingShadowGeometryMode.directional,
  ProjectedShadowFootprintTuning? footprint,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: geometryMode,
    footprint: footprint,
  );
}
