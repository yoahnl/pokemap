import 'package:map_battle/map_battle.dart';

import 'battle_sdk_rmxp_animation_catalog.dart';

enum BattleVisualAnchor {
  attackerCenter,
  attackerBody,
  attackerHead,
  attackerMouth,
  attackerHand,
  attackerFoot,
  defenderCenter,
  defenderBody,
  defenderHead,
  defenderMouth,
  defenderHand,
  defenderImpact,
  defenderFoot,
  stageCenter,
  stageTop,
  stageBottom,
  screenCenter,
}

enum RmxpPlacementPolicy {
  sdkStage,
  subjectAttached,
  targetImpact,
  attackerCast,
  projectileLine,
  screenGlobal,
}

enum RmxpPlacementPhase {
  user,
  target,
}

final class RmxpPlacementSpec {
  const RmxpPlacementSpec({
    required this.policy,
    this.anchor,
    this.sourceAnchor,
    this.targetAnchor,
    this.rotateToLine = false,
    this.isImplicit = false,
  });

  final RmxpPlacementPolicy policy;
  final BattleVisualAnchor? anchor;
  final BattleVisualAnchor? sourceAnchor;
  final BattleVisualAnchor? targetAnchor;
  final bool rotateToLine;
  final bool isImplicit;
}

enum BattleFxMotionCurve {
  linear,
  easeOut,
  arcUnder,
  arcOver,
}

enum BattleFxAfterEffect {
  none,
  fade,
  explode,
}

enum BattleAnimationGroupMode {
  sequence,
  parallel,
}

enum BattleCameraFocusTarget {
  user,
  target,
  scene,
}

enum BattleBarrierStyle {
  protect,
  reflect,
  lightScreen,
  mist,
  auroraVeil,
  safeguard,
  quickGuard,
  wideGuard,
}

enum BattleCombatantMotionKind {
  lunge,
  fastDash,
  switchOut,
  switchIn,
}

class BattleAnimationPlan {
  const BattleAnimationPlan({
    required this.steps,
  });

  final List<BattleAnimationStep> steps;

  Set<String> get requiredFxIds => steps.fold(<String>{}, (ids, step) {
        _addRequiredFxIds(ids, step);
        return ids;
      });

  static void _addRequiredFxIds(Set<String> ids, BattleAnimationStep step) {
    switch (step) {
      case SpawnFxStep(:final effectId):
        ids.add(effectId);
      case PlaySpriteSheetFxStep(:final assetId):
      case ParticleBurstStep(:final assetId):
      case SpriteSheetOnCombatantStep(:final assetId):
      case WeatherParticleStep(:final assetId):
        ids.add(assetId);
      case PlaySdkParticleSequenceStep(:final particles):
        for (final particle in particles) {
          ids.add(particle.assetId);
        }
      case SdkFallingParticlesStep(:final assetId):
      case SdkRadiusParticleStep(:final assetId):
      case SdkScalarParticleStep(:final assetId):
      case SdkParticleZoomStep(:final assetId):
        ids.add(assetId);
      case PlayRmxpAnimationStep(:final animationId):
        final animation =
            BattleSdkRmxpAnimationCatalog.byAnimationId[animationId];
        if (animation != null) {
          ids.add(animation.assetId);
        }
      case AnimationGroupStep(:final steps):
        for (final child in steps) {
          _addRequiredFxIds(ids, child);
        }
      default:
        break;
    }
  }

  bool get isEmpty => steps.isEmpty;
}

sealed class BattleAnimationStep {
  const BattleAnimationStep();
}

final class ShowMessageStep extends BattleAnimationStep {
  const ShowMessageStep({
    required this.message,
  });

  final String message;
}

final class WaitStep extends BattleAnimationStep {
  const WaitStep({
    required this.durationSeconds,
  });

  final double durationSeconds;
}

final class AnimationGroupStep extends BattleAnimationStep {
  const AnimationGroupStep({
    required this.mode,
    required this.steps,
  });

  final BattleAnimationGroupMode mode;
  final List<BattleAnimationStep> steps;
}

final class SpawnFxStep extends BattleAnimationStep {
  const SpawnFxStep({
    required this.effectId,
    required this.attackerSide,
    required this.defenderSide,
    required this.from,
    required this.to,
    required this.durationSeconds,
    this.curve = BattleFxMotionCurve.easeOut,
    this.afterEffect = BattleFxAfterEffect.none,
    this.startScale = 1.0,
    this.endScale = 1.0,
    this.startOpacity = 1.0,
    this.endOpacity = 1.0,
    this.fromOffsetX = 0,
    this.fromOffsetY = 0,
    this.toOffsetX = 0,
    this.toOffsetY = 0,
    this.startDelaySeconds = 0,
    this.playAsAccent = false,
  });

  final String effectId;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final BattleVisualAnchor from;
  final BattleVisualAnchor to;
  final double durationSeconds;
  final BattleFxMotionCurve curve;
  final BattleFxAfterEffect afterEffect;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double endOpacity;
  final double fromOffsetX;
  final double fromOffsetY;
  final double toOffsetX;
  final double toOffsetY;
  final double startDelaySeconds;
  final bool playAsAccent;
}

final class ScreenFlashStep extends BattleAnimationStep {
  const ScreenFlashStep({
    required this.colorArgb,
    required this.durationSeconds,
  });

  final int colorArgb;
  final double durationSeconds;
}

final class SceneTintStep extends BattleAnimationStep {
  const SceneTintStep({
    required this.colorArgb,
    required this.durationSeconds,
  });

  final int colorArgb;
  final double durationSeconds;
}

final class PlaySpriteSheetFxStep extends BattleAnimationStep {
  const PlaySpriteSheetFxStep({
    required this.assetId,
    required this.attackerSide,
    required this.defenderSide,
    required this.anchor,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.frameDurationSeconds,
    this.columns,
    this.originX,
    this.originY,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
    this.startDelaySeconds = 0,
    this.frameSequence,
    this.frameDurationsSeconds,
  });

  final String assetId;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final BattleVisualAnchor anchor;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final double frameDurationSeconds;
  final int? columns;
  final double? originX;
  final double? originY;
  final double scale;
  final double opacity;
  final double offsetX;
  final double offsetY;
  final double startDelaySeconds;
  final List<int>? frameSequence;
  final List<double>? frameDurationsSeconds;

  int get effectiveFrameCount => frameSequence?.length ?? frameCount;

  double get durationSeconds {
    final durations = frameDurationsSeconds;
    if (durations != null) {
      return startDelaySeconds +
          durations.fold<double>(0, (total, duration) => total + duration);
    }
    return startDelaySeconds + (effectiveFrameCount * frameDurationSeconds);
  }
}

final class SpriteSheetOnCombatantStep extends BattleAnimationStep {
  const SpriteSheetOnCombatantStep({
    required this.assetId,
    required this.side,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.frameDurationSeconds,
    this.attackerSide,
    this.defenderSide,
    this.columns,
    this.originX,
    this.originY,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
    this.startDelaySeconds = 0,
    this.frameSequence,
    this.frameDurationsSeconds,
  });

  final String assetId;
  final BattleSideId side;
  final BattleSideId? attackerSide;
  final BattleSideId? defenderSide;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final double frameDurationSeconds;
  final int? columns;
  final double? originX;
  final double? originY;
  final double scale;
  final double opacity;
  final double offsetX;
  final double offsetY;
  final double startDelaySeconds;
  final List<int>? frameSequence;
  final List<double>? frameDurationsSeconds;

  int get effectiveFrameCount => frameSequence?.length ?? frameCount;

  double get durationSeconds {
    final durations = frameDurationsSeconds;
    if (durations != null) {
      return startDelaySeconds +
          durations.fold<double>(0, (total, duration) => total + duration);
    }
    return startDelaySeconds + (effectiveFrameCount * frameDurationSeconds);
  }
}

final class PlayRmxpAnimationStep extends BattleAnimationStep {
  const PlayRmxpAnimationStep({
    required this.animationId,
    required this.subjectSide,
    required this.attackerSide,
    required this.defenderSide,
    required this.phase,
    required this.placementSpec,
    this.sdkMoveId,
    this.reverse = false,
    this.startDelaySeconds = 0,
  });

  final int animationId;
  final BattleSideId subjectSide;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final RmxpPlacementPhase phase;
  final RmxpPlacementSpec placementSpec;
  final String? sdkMoveId;
  final bool reverse;
  final double startDelaySeconds;

  double get durationSeconds =>
      BattleSdkRmxpAnimationCatalog.require(animationId).durationSeconds;

  double get totalDurationSeconds => startDelaySeconds + durationSeconds;
}

final class ParticleBurstStep extends BattleAnimationStep {
  const ParticleBurstStep({
    required this.assetId,
    required this.side,
    required this.anchor,
    required this.particleCount,
    required this.durationSeconds,
    this.radiusPx = 48,
    this.startScale = 0.2,
    this.endScale = 1.0,
    this.startOpacity = 1.0,
    this.endOpacity = 0.0,
    this.colorArgb,
    this.startDelaySeconds = 0,
  });

  final String assetId;
  final BattleSideId side;
  final BattleVisualAnchor anchor;
  final int particleCount;
  final double durationSeconds;
  final double radiusPx;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double endOpacity;
  final int? colorArgb;
  final double startDelaySeconds;
}

final class PlaySdkParticleSequenceStep extends BattleAnimationStep {
  const PlaySdkParticleSequenceStep({
    required this.attackerSide,
    required this.defenderSide,
    required this.particles,
    required this.durationSeconds,
  });

  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final List<SdkParticleSpec> particles;
  final double durationSeconds;
}

final class SdkParticleSpec {
  const SdkParticleSpec({
    required this.assetId,
    required this.anchor,
    required this.startOffsetX,
    required this.startOffsetY,
    required this.endOffsetX,
    required this.endOffsetY,
    required this.startScaleX,
    required this.startScaleY,
    required this.endScaleX,
    required this.endScaleY,
    required this.startOpacity,
    required this.endOpacity,
    required this.delaySeconds,
    required this.durationSeconds,
    this.colorArgb,
    this.rotationTurns = 0,
  });

  final String assetId;
  final BattleVisualAnchor anchor;
  final double startOffsetX;
  final double startOffsetY;
  final double endOffsetX;
  final double endOffsetY;
  final double startScaleX;
  final double startScaleY;
  final double endScaleX;
  final double endScaleY;
  final double startOpacity;
  final double endOpacity;
  final double delaySeconds;
  final double durationSeconds;
  final int? colorArgb;
  final double rotationTurns;
}

final class SdkFallingParticlesStep extends BattleAnimationStep {
  const SdkFallingParticlesStep({
    required this.assetId,
    required this.attackerSide,
    required this.defenderSide,
    required this.anchor,
    required this.particleCount,
    required this.durationSeconds,
    this.startAreaWidth = 54,
    this.startOffsetY = -44,
    this.fallDistanceY = 74,
    this.driftX = 18,
    this.startScaleX = 0.18,
    this.startScaleY = 0.18,
    this.endScaleX = 0.75,
    this.endScaleY = 0.75,
    this.startOpacity = 1,
    this.endOpacity = 0,
    this.intervalSeconds = 0.035,
    this.colorArgb,
  });

  final String assetId;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final BattleVisualAnchor anchor;
  final int particleCount;
  final double durationSeconds;
  final double startAreaWidth;
  final double startOffsetY;
  final double fallDistanceY;
  final double driftX;
  final double startScaleX;
  final double startScaleY;
  final double endScaleX;
  final double endScaleY;
  final double startOpacity;
  final double endOpacity;
  final double intervalSeconds;
  final int? colorArgb;
}

final class SdkRadiusParticleStep extends BattleAnimationStep {
  const SdkRadiusParticleStep({
    required this.assetId,
    required this.attackerSide,
    required this.defenderSide,
    required this.anchor,
    required this.particleCount,
    required this.startRadiusPx,
    required this.endRadiusPx,
    required this.durationSeconds,
    this.startScale = 0.2,
    this.endScale = 1,
    this.startOpacity = 1,
    this.endOpacity = 0,
    this.startAngleTurns = 0,
    this.intervalSeconds = 0.015,
    this.colorArgb,
  });

  final String assetId;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final BattleVisualAnchor anchor;
  final int particleCount;
  final double startRadiusPx;
  final double endRadiusPx;
  final double durationSeconds;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double endOpacity;
  final double startAngleTurns;
  final double intervalSeconds;
  final int? colorArgb;
}

final class SdkScalarParticleStep extends BattleAnimationStep {
  const SdkScalarParticleStep({
    required this.assetId,
    required this.attackerSide,
    required this.defenderSide,
    required this.anchor,
    required this.startScaleX,
    required this.startScaleY,
    required this.endScaleX,
    required this.endScaleY,
    required this.durationSeconds,
    this.offsetX = 0,
    this.offsetY = 0,
    this.endOffsetX = 0,
    this.endOffsetY = 0,
    this.startOpacity = 1,
    this.endOpacity = 0,
    this.delaySeconds = 0,
    this.colorArgb,
    this.rotationTurns = 0,
  });

  final String assetId;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final BattleVisualAnchor anchor;
  final double startScaleX;
  final double startScaleY;
  final double endScaleX;
  final double endScaleY;
  final double durationSeconds;
  final double offsetX;
  final double offsetY;
  final double endOffsetX;
  final double endOffsetY;
  final double startOpacity;
  final double endOpacity;
  final double delaySeconds;
  final int? colorArgb;
  final double rotationTurns;
}

final class SdkParticleZoomStep extends BattleAnimationStep {
  const SdkParticleZoomStep({
    required this.assetId,
    required this.attackerSide,
    required this.defenderSide,
    required this.anchor,
    required this.startScale,
    required this.endScale,
    required this.durationSeconds,
    this.offsetX = 0,
    this.offsetY = 0,
    this.startOpacity = 1,
    this.endOpacity = 0,
    this.delaySeconds = 0,
    this.colorArgb,
    this.rotationTurns = 0,
  });

  final String assetId;
  final BattleSideId attackerSide;
  final BattleSideId defenderSide;
  final BattleVisualAnchor anchor;
  final double startScale;
  final double endScale;
  final double durationSeconds;
  final double offsetX;
  final double offsetY;
  final double startOpacity;
  final double endOpacity;
  final double delaySeconds;
  final int? colorArgb;
  final double rotationTurns;
}

final class WeatherParticleStep extends BattleAnimationStep {
  const WeatherParticleStep({
    required this.assetId,
    required this.particleCount,
    required this.durationSeconds,
    this.colorArgb,
  });

  final String assetId;
  final int particleCount;
  final double durationSeconds;
  final int? colorArgb;
}

final class CombatantMotionStep extends BattleAnimationStep {
  const CombatantMotionStep({
    required this.side,
    required this.motionKind,
    required this.durationSeconds,
    this.distancePx = 0,
  });

  final BattleSideId side;
  final BattleCombatantMotionKind motionKind;
  final double durationSeconds;
  final double distancePx;
}

final class CombatantFlashStep extends BattleAnimationStep {
  const CombatantFlashStep({
    required this.side,
    required this.durationSeconds,
  });

  final BattleSideId side;
  final double durationSeconds;
}

final class CombatantShakeStep extends BattleAnimationStep {
  const CombatantShakeStep({
    required this.side,
    required this.amplitudePx,
    required this.durationSeconds,
  });

  final BattleSideId side;
  final double amplitudePx;
  final double durationSeconds;
}

final class CombatantToneStep extends BattleAnimationStep {
  const CombatantToneStep({
    required this.side,
    required this.colorArgb,
    required this.durationSeconds,
  });

  final BattleSideId side;
  final int colorArgb;
  final double durationSeconds;
}

final class CombatantCompressStep extends BattleAnimationStep {
  const CombatantCompressStep({
    required this.side,
    required this.scaleX,
    required this.scaleY,
    required this.durationSeconds,
    this.iteration = 1,
  });

  final BattleSideId side;
  final double scaleX;
  final double scaleY;
  final double durationSeconds;
  final int iteration;
}

final class CombatantEllipseStep extends BattleAnimationStep {
  const CombatantEllipseStep({
    required this.side,
    required this.radiusX,
    required this.radiusY,
    required this.turns,
    required this.durationSeconds,
  });

  final BattleSideId side;
  final double radiusX;
  final double radiusY;
  final int turns;
  final double durationSeconds;
}

final class CameraFocusStep extends BattleAnimationStep {
  const CameraFocusStep({
    required this.target,
    required this.durationSeconds,
  });

  final BattleCameraFocusTarget target;
  final double durationSeconds;
}

final class BattleCameraMoveStep extends BattleAnimationStep {
  const BattleCameraMoveStep({
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.durationSeconds,
    this.curve = BattleFxMotionCurve.easeOut,
  });

  final double offsetX;
  final double offsetY;
  final double scale;
  final double durationSeconds;
  final BattleFxMotionCurve curve;
}

final class BattleCameraResetStep extends BattleAnimationStep {
  const BattleCameraResetStep({
    required this.durationSeconds,
  });

  final double durationSeconds;
}

final class FaintCombatantStep extends BattleAnimationStep {
  const FaintCombatantStep({
    required this.side,
    required this.durationSeconds,
  });

  final BattleSideId side;
  final double durationSeconds;
}

final class HudHpTweenStep extends BattleAnimationStep {
  const HudHpTweenStep({
    required this.side,
    required this.fromHp,
    required this.toHp,
    this.durationMs = 320,
  });

  final BattleSideId side;
  final int fromHp;
  final int toHp;
  final int durationMs;
}

final class SwapCombatantVisualStep extends BattleAnimationStep {
  const SwapCombatantVisualStep({
    required this.side,
  });

  final BattleSideId side;
}

final class BarrierPulseStep extends BattleAnimationStep {
  const BarrierPulseStep({
    required this.side,
    required this.colorArgb,
    required this.durationSeconds,
    this.style = BattleBarrierStyle.protect,
  });

  final BattleSideId side;
  final int colorArgb;
  final double durationSeconds;
  final BattleBarrierStyle style;
}
