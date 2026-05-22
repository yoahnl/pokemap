import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowFootprintFixedTuning', () {
    test('stores explicit tuning', () {
      final tuning = _standardTuning();

      final strategy = ProjectedShadowFootprintFixedTuning(tuning: tuning);

      expect(strategy.tuning, tuning);
      expect(strategy, isA<ProjectedShadowFootprintTuningStrategy>());
    });

    test('equality includes tuning', () {
      final first = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final same = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final changed = ProjectedShadowFootprintFixedTuning(
        tuning: _targetTuning(),
      );

      expect(first, same);
      expect(first, isNot(changed));
    });

    test('hashCode includes tuning', () {
      final first = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final same = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final changed = ProjectedShadowFootprintFixedTuning(
        tuning: _targetTuning(),
      );

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changed.hashCode));
    });
  });

  group('ProjectedShadowAdaptiveDepthGate', () {
    test('uses canonical defaults', () {
      final gate = ProjectedShadowAdaptiveDepthGate();

      expect(gate.referenceHeight, 80);
      expect(gate.targetHeight, 112);
      expect(gate.referenceRatio, 1.25);
      expect(gate.targetRatio, 1.75);
    });

    test('equality includes all fields', () {
      final first = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final same = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 80,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedTargetHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 140,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.2,
        targetRatio: 1.9,
      );
      final changedTargetRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 2.0,
      );

      expect(first, same);
      expect(first, isNot(changedReferenceHeight));
      expect(first, isNot(changedTargetHeight));
      expect(first, isNot(changedReferenceRatio));
      expect(first, isNot(changedTargetRatio));
    });

    test('hashCode includes all fields', () {
      final first = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final same = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 80,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedTargetHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 140,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.2,
        targetRatio: 1.9,
      );
      final changedTargetRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 2.0,
      );

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changedReferenceHeight.hashCode));
      expect(first.hashCode, isNot(changedTargetHeight.hashCode));
      expect(first.hashCode, isNot(changedReferenceRatio.hashCode));
      expect(first.hashCode, isNot(changedTargetRatio.hashCode));
    });

    test('rejects non-positive referenceHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceHeight: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceHeight: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive targetHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetHeight: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetHeight: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetHeight equal to referenceHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 80,
          targetHeight: 80,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetHeight below referenceHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 80,
          targetHeight: 79,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive referenceRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceRatio: -0.1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive targetRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetRatio: -0.1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetRatio equal to referenceRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceRatio: 1.25,
          targetRatio: 1.25,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetRatio below referenceRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceRatio: 1.25,
          targetRatio: 1.24,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowFootprintAdaptiveDepthTuning', () {
    test('stores base target gate and opacity endpoints', () {
      final base = _standardTuning();
      final target = _targetTuning();
      final gate = ProjectedShadowAdaptiveDepthGate();

      final strategy = ProjectedShadowFootprintAdaptiveDepthTuning(
        base: base,
        target: target,
        gate: gate,
        baseOpacity: 0.24,
        targetOpacity: 0.22,
      );

      expect(strategy.base, base);
      expect(strategy.target, target);
      expect(strategy.gate, gate);
      expect(strategy.baseOpacity, 0.24);
      expect(strategy.targetOpacity, 0.22);
      expect(strategy, isA<ProjectedShadowFootprintTuningStrategy>());
    });

    test('equality includes every field', () {
      final first = _adaptiveStrategy();
      final same = _adaptiveStrategy();
      final changedBase = _adaptiveStrategy(base: _alternateBaseTuning());
      final changedTarget = _adaptiveStrategy(target: _alternateTargetTuning());
      final changedGate = _adaptiveStrategy(
        gate: ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 70,
          targetHeight: 120,
          referenceRatio: 1.2,
          targetRatio: 1.8,
        ),
      );
      final changedBaseOpacity = _adaptiveStrategy(baseOpacity: 0.25);
      final changedTargetOpacity = _adaptiveStrategy(targetOpacity: 0.21);

      expect(first, same);
      expect(first, isNot(changedBase));
      expect(first, isNot(changedTarget));
      expect(first, isNot(changedGate));
      expect(first, isNot(changedBaseOpacity));
      expect(first, isNot(changedTargetOpacity));
    });

    test('hashCode includes every field', () {
      final first = _adaptiveStrategy();
      final same = _adaptiveStrategy();
      final changedBase = _adaptiveStrategy(base: _alternateBaseTuning());
      final changedTarget = _adaptiveStrategy(target: _alternateTargetTuning());
      final changedGate = _adaptiveStrategy(
        gate: ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 70,
          targetHeight: 120,
          referenceRatio: 1.2,
          targetRatio: 1.8,
        ),
      );
      final changedBaseOpacity = _adaptiveStrategy(baseOpacity: 0.25);
      final changedTargetOpacity = _adaptiveStrategy(targetOpacity: 0.21);

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changedBase.hashCode));
      expect(first.hashCode, isNot(changedTarget.hashCode));
      expect(first.hashCode, isNot(changedGate.hashCode));
      expect(first.hashCode, isNot(changedBaseOpacity.hashCode));
      expect(first.hashCode, isNot(changedTargetOpacity.hashCode));
    });

    test('rejects baseOpacity below 0', () {
      expect(
        () => _adaptiveStrategy(baseOpacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects baseOpacity above 1', () {
      expect(
        () => _adaptiveStrategy(baseOpacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetOpacity below 0', () {
      expect(
        () => _adaptiveStrategy(targetOpacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetOpacity above 1', () {
      expect(
        () => _adaptiveStrategy(targetOpacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts opacity endpoints 0 and 1', () {
      final strategy = _adaptiveStrategy(baseOpacity: 0, targetOpacity: 1);

      expect(strategy.baseOpacity, 0);
      expect(strategy.targetOpacity, 1);
    });
  });

  group('ProjectedBuildingShadowCasterKind', () {
    test('exposes building and largeVolume', () {
      expect(ProjectedBuildingShadowCasterKind.values, [
        ProjectedBuildingShadowCasterKind.building,
        ProjectedBuildingShadowCasterKind.largeVolume,
      ]);
    });
  });

  group('ProjectedShadowFootprintTuning defaults', () {
    test('remain unchanged', () {
      final tuning = ProjectedShadowFootprintTuning();

      expect(tuning.attachYRatio, 0.86);
      expect(tuning.frontWidthRatio, 1.10);
      expect(tuning.rearWidthRatio, 1.20);
      expect(tuning.depthRatio, 0.28);
      expect(tuning.skewXRatio, 0.10);
    });
  });
}

ProjectedShadowFootprintTuning _standardTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _targetTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _alternateBaseTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.81,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _alternateTargetTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.80,
    frontWidthRatio: 1.32,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy({
  ProjectedShadowFootprintTuning? base,
  ProjectedShadowFootprintTuning? target,
  ProjectedShadowAdaptiveDepthGate? gate,
  double baseOpacity = 0.24,
  double targetOpacity = 0.22,
}) {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: base ?? _standardTuning(),
    target: target ?? _targetTuning(),
    gate: gate ?? ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: baseOpacity,
    targetOpacity: targetOpacity,
  );
}
