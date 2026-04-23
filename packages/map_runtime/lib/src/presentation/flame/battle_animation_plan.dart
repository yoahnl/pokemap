import 'package:map_battle/map_battle.dart';

enum BattleVisualAnchor {
  attackerCenter,
  attackerHead,
  defenderCenter,
  defenderHead,
  screenCenter,
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

  Set<String> get requiredFxIds =>
      steps.whereType<SpawnFxStep>().map((step) => step.effectId).toSet();

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
