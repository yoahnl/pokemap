import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveProjectedShadowFootprintEffectiveTuning fixed', () {
    test('resolves fixed tuning with fixed opacity', () {
      final tuning = _baseTuning();

      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: ProjectedShadowFootprintFixedTuning(tuning: tuning),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
      );

      final value = _expectResolved(result);
      expect(value.tuning, tuning);
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
    });

    test('ignores casterKind for fixed tuning', () {
      final tuning = _baseTuning();

      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: ProjectedShadowFootprintFixedTuning(tuning: tuning),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      final value = _expectResolved(result);
      expect(value.tuning, tuning);
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
    });

    test('rejects invalid fixedOpacity below 0', () {
      expect(
        () => resolveProjectedShadowFootprintEffectiveTuning(
          strategy: ProjectedShadowFootprintFixedTuning(tuning: _baseTuning()),
          metrics: _tallShopMetrics(),
          fixedOpacity: -0.01,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid fixedOpacity above 1', () {
      expect(
        () => resolveProjectedShadowFootprintEffectiveTuning(
          strategy: ProjectedShadowFootprintFixedTuning(tuning: _baseTuning()),
          metrics: _tallShopMetrics(),
          fixedOpacity: 1.01,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveProjectedShadowFootprintEffectiveTuning adaptive', () {
    test('blocks adaptive depth without casterKind', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
      );

      final blocked = _expectBlocked(result);
      expect(
        blocked.reason,
        ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthRequiresCasterKind,
      );
    });

    test('resolves adaptive depth for building caster', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _targetTuning());
      expect(value.opacity, 0.22);
      expect(value.adaptiveT, 1);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.adaptiveHeightDepth,
      );
    });

    test('resolves adaptive depth for largeVolume caster', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _targetTuning());
      expect(value.opacity, 0.22);
      expect(value.adaptiveT, 1);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.adaptiveHeightDepth,
      );
    });

    test('keeps wide_house_6x5 at base tuning', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 52,
          top: 80,
          visualWidth: 96,
          visualHeight: 80,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _baseTuning());
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
    });

    test('keeps medium_shop_5x6 at base tuning', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 60,
          top: 64,
          visualWidth: 80,
          visualHeight: 96,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _baseTuning());
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
    });

    test('partially adapts thin_prop_like_2x6 canary', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 84,
          top: 64,
          visualWidth: 32,
          visualHeight: 96,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      _expectTuningClose(
        value.tuning,
        attachYRatio: 0.81,
        frontWidthRatio: 1.30,
        rearWidthRatio: 1.445,
        depthRatio: 0.34,
        skewXRatio: 0.08,
      );
      expect(value.opacity, closeTo(0.23, 0.000001));
      expect(value.adaptiveT, closeTo(0.5, 0.000001));
    });

    test('interpolates both gates multiplicatively', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 68,
          top: 64,
          visualWidth: 64,
          visualHeight: 96,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      _expectTuningClose(
        value.tuning,
        attachYRatio: 0.815,
        frontWidthRatio: 1.30,
        rearWidthRatio: 1.4325,
        depthRatio: 0.30,
        skewXRatio: 0.08,
      );
      expect(value.opacity, closeTo(0.235, 0.000001));
      expect(value.adaptiveT, closeTo(0.25, 0.000001));
    });
  });

  group('ProjectedShadowEffectiveFootprintTuning', () {
    test('equality includes all fields', () {
      final first = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.24,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final same = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.24,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final changedTuning = ProjectedShadowEffectiveFootprintTuning(
        tuning: _targetTuning(),
        opacity: 0.24,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final changedOpacity = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.25,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final changedAdaptiveT = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.24,
        adaptiveT: 0.5,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind
            .adaptiveHeightDepth,
      );

      expect(first, same);
      expect(first, isNot(changedTuning));
      expect(first, isNot(changedOpacity));
      expect(first, isNot(changedAdaptiveT));
      expect(first.hashCode, same.hashCode);
    });

    test('rejects opacity below 0', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: -0.01,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects opacity above 1', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 1.01,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects adaptiveT below 0', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: -0.01,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects adaptiveT above 1', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: 1.01,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowFootprintEffectiveTuningResult', () {
    test('resolved equality includes value', () {
      final first = ProjectedShadowFootprintEffectiveTuningResolved(
        value: ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
      );
      final same = ProjectedShadowFootprintEffectiveTuningResolved(
        value: ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
      );
      final changed = ProjectedShadowFootprintEffectiveTuningResolved(
        value: ProjectedShadowEffectiveFootprintTuning(
          tuning: _targetTuning(),
          opacity: 0.22,
          adaptiveT: 1,
          strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind
              .adaptiveHeightDepth,
        ),
      );

      expect(first, same);
      expect(first, isNot(changed));
      expect(first.hashCode, same.hashCode);
    });

    test('blocked equality includes reason', () {
      final first = ProjectedShadowFootprintEffectiveTuningBlocked(
        reason: ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthRequiresCasterKind,
      );
      final same = ProjectedShadowFootprintEffectiveTuningBlocked(
        reason: ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthRequiresCasterKind,
      );
      final changed = ProjectedShadowFootprintEffectiveTuningBlocked(
        reason: ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthUnsupportedCasterKind,
      );

      expect(first, same);
      expect(first, isNot(changed));
      expect(first.hashCode, same.hashCode);
    });
  });
}

ProjectedShadowEffectiveFootprintTuning _expectResolved(
  ProjectedShadowFootprintEffectiveTuningResult result,
) {
  expect(result, isA<ProjectedShadowFootprintEffectiveTuningResolved>());
  return (result as ProjectedShadowFootprintEffectiveTuningResolved).value;
}

ProjectedShadowFootprintEffectiveTuningBlocked _expectBlocked(
  ProjectedShadowFootprintEffectiveTuningResult result,
) {
  expect(result, isA<ProjectedShadowFootprintEffectiveTuningBlocked>());
  return result as ProjectedShadowFootprintEffectiveTuningBlocked;
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy() {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: _baseTuning(),
    target: _targetTuning(),
    gate: ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: 0.24,
    targetOpacity: 0.22,
  );
}

ProjectedShadowFootprintTuning _baseTuning() {
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

StaticShadowVisualMetrics _tallShopMetrics() {
  return StaticShadowVisualMetrics(
    left: 68,
    top: 48,
    visualWidth: 64,
    visualHeight: 112,
  );
}

void _expectTuningClose(
  ProjectedShadowFootprintTuning tuning, {
  required double attachYRatio,
  required double frontWidthRatio,
  required double rearWidthRatio,
  required double depthRatio,
  required double skewXRatio,
}) {
  expect(tuning.attachYRatio, closeTo(attachYRatio, 0.000001));
  expect(tuning.frontWidthRatio, closeTo(frontWidthRatio, 0.000001));
  expect(tuning.rearWidthRatio, closeTo(rearWidthRatio, 0.000001));
  expect(tuning.depthRatio, closeTo(depthRatio, 0.000001));
  expect(tuning.skewXRatio, closeTo(skewXRatio, 0.000001));
}
