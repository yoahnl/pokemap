import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'static_shadow_geometry.dart';

enum ProjectedShadowFootprintEffectiveTuningStrategyKind {
  fixed,
  adaptiveHeightDepth,
}

enum ProjectedShadowFootprintEffectiveTuningBlockReason {
  adaptiveDepthRequiresCasterKind,
  adaptiveDepthUnsupportedCasterKind,
}

final class ProjectedShadowEffectiveFootprintTuning {
  factory ProjectedShadowEffectiveFootprintTuning({
    required ProjectedShadowFootprintTuning tuning,
    required double opacity,
    required double adaptiveT,
    required ProjectedShadowFootprintEffectiveTuningStrategyKind strategyKind,
  }) {
    _validateUnitInterval(
      opacity,
      'ProjectedShadowEffectiveFootprintTuning.opacity',
    );
    _validateUnitInterval(
      adaptiveT,
      'ProjectedShadowEffectiveFootprintTuning.adaptiveT',
    );
    return ProjectedShadowEffectiveFootprintTuning._(
      tuning: tuning,
      opacity: opacity,
      adaptiveT: adaptiveT,
      strategyKind: strategyKind,
    );
  }

  const ProjectedShadowEffectiveFootprintTuning._({
    required this.tuning,
    required this.opacity,
    required this.adaptiveT,
    required this.strategyKind,
  });

  final ProjectedShadowFootprintTuning tuning;
  final double opacity;
  final double adaptiveT;
  final ProjectedShadowFootprintEffectiveTuningStrategyKind strategyKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowEffectiveFootprintTuning &&
          other.tuning == tuning &&
          other.opacity == opacity &&
          other.adaptiveT == adaptiveT &&
          other.strategyKind == strategyKind;

  @override
  int get hashCode => Object.hash(
        tuning,
        opacity,
        adaptiveT,
        strategyKind,
      );
}

sealed class ProjectedShadowFootprintEffectiveTuningResult {
  const ProjectedShadowFootprintEffectiveTuningResult();
}

final class ProjectedShadowFootprintEffectiveTuningResolved
    extends ProjectedShadowFootprintEffectiveTuningResult {
  const ProjectedShadowFootprintEffectiveTuningResolved({
    required this.value,
  });

  final ProjectedShadowEffectiveFootprintTuning value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintEffectiveTuningResolved &&
          other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class ProjectedShadowFootprintEffectiveTuningBlocked
    extends ProjectedShadowFootprintEffectiveTuningResult {
  const ProjectedShadowFootprintEffectiveTuningBlocked({
    required this.reason,
  });

  final ProjectedShadowFootprintEffectiveTuningBlockReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintEffectiveTuningBlocked &&
          other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

ProjectedShadowFootprintEffectiveTuningResult
    resolveProjectedShadowFootprintEffectiveTuning({
  required ProjectedShadowFootprintTuningStrategy strategy,
  required StaticShadowVisualMetrics metrics,
  required double fixedOpacity,
  ProjectedBuildingShadowCasterKind? casterKind,
}) {
  return switch (strategy) {
    ProjectedShadowFootprintFixedTuning() =>
      _resolveFixedFootprintEffectiveTuning(
        strategy: strategy,
        fixedOpacity: fixedOpacity,
      ),
    ProjectedShadowFootprintAdaptiveDepthTuning() =>
      _resolveAdaptiveHeightDepthFootprintEffectiveTuning(
        strategy: strategy,
        metrics: metrics,
        casterKind: casterKind,
      ),
  };
}

ProjectedShadowFootprintEffectiveTuningResolved
    _resolveFixedFootprintEffectiveTuning({
  required ProjectedShadowFootprintFixedTuning strategy,
  required double fixedOpacity,
}) {
  _validateUnitInterval(
    fixedOpacity,
    'resolveProjectedShadowFootprintEffectiveTuning.fixedOpacity',
  );
  return ProjectedShadowFootprintEffectiveTuningResolved(
    value: ProjectedShadowEffectiveFootprintTuning(
      tuning: strategy.tuning,
      opacity: fixedOpacity,
      adaptiveT: 0,
      strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
    ),
  );
}

ProjectedShadowFootprintEffectiveTuningResult
    _resolveAdaptiveHeightDepthFootprintEffectiveTuning({
  required ProjectedShadowFootprintAdaptiveDepthTuning strategy,
  required StaticShadowVisualMetrics metrics,
  required ProjectedBuildingShadowCasterKind? casterKind,
}) {
  if (casterKind == null) {
    return const ProjectedShadowFootprintEffectiveTuningBlocked(
      reason: ProjectedShadowFootprintEffectiveTuningBlockReason
          .adaptiveDepthRequiresCasterKind,
    );
  }
  if (!_isAdaptiveCompatibleCasterKind(casterKind)) {
    return const ProjectedShadowFootprintEffectiveTuningBlocked(
      reason: ProjectedShadowFootprintEffectiveTuningBlockReason
          .adaptiveDepthUnsupportedCasterKind,
    );
  }

  final gate = strategy.gate;
  final heightGate = _clamp01(
    (metrics.visualHeight - gate.referenceHeight) /
        (gate.targetHeight - gate.referenceHeight),
  );
  final ratioGate = _clamp01(
    (metrics.visualHeight / metrics.visualWidth - gate.referenceRatio) /
        (gate.targetRatio - gate.referenceRatio),
  );
  final adaptiveT = heightGate * ratioGate;
  final base = strategy.base;
  final target = strategy.target;

  return ProjectedShadowFootprintEffectiveTuningResolved(
    value: ProjectedShadowEffectiveFootprintTuning(
      tuning: ProjectedShadowFootprintTuning(
        attachYRatio: _lerp(
          base.attachYRatio,
          target.attachYRatio,
          adaptiveT,
        ),
        frontWidthRatio: _lerp(
          base.frontWidthRatio,
          target.frontWidthRatio,
          adaptiveT,
        ),
        rearWidthRatio: _lerp(
          base.rearWidthRatio,
          target.rearWidthRatio,
          adaptiveT,
        ),
        depthRatio: _lerp(
          base.depthRatio,
          target.depthRatio,
          adaptiveT,
        ),
        skewXRatio: _lerp(
          base.skewXRatio,
          target.skewXRatio,
          adaptiveT,
        ),
      ),
      opacity: _lerp(strategy.baseOpacity, strategy.targetOpacity, adaptiveT),
      adaptiveT: adaptiveT,
      strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind
          .adaptiveHeightDepth,
    ),
  );
}

bool _isAdaptiveCompatibleCasterKind(
  ProjectedBuildingShadowCasterKind casterKind,
) {
  return switch (casterKind) {
    ProjectedBuildingShadowCasterKind.building => true,
    ProjectedBuildingShadowCasterKind.largeVolume => true,
  };
}

double _clamp01(double value) {
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return value;
}

double _lerp(double start, double end, double t) {
  return start + (end - start) * t;
}

void _validateUnitInterval(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}
