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

  /// Glissement d'entrée en combat — BETA-BAT-016. L'ennemi traverse depuis
  /// la gauche, le joueur depuis la droite (parité RBY : `x ± 360` → `x`),
  /// opacité pleine du premier au dernier pixel.
  introSlide,

  /// Apparition depuis la Poké Ball — BETA-BAT-022. Le sprite grandit de
  /// zéro à sa taille (parité `ya.scalar(0.1, self, :zoom=, 0, sprite_zoom)`).
  materializeIn,

  /// Retour dans la Poké Ball — le sprite rétrécit jusqu'à zéro (parité
  /// `go_back_ball_animation`).
  materializeOut,
}

class BattleAnimationPlan {
  const BattleAnimationPlan({
    required this.steps,
  });

  final List<BattleAnimationStep> steps;

  /// Toutes les étapes du plan, celles imbriquées dans un groupe comprises.
  ///
  /// BETA-BAT-013 : le clignotement de dégât et la barre de PV vivent dans un
  /// groupe parallèle, donc un consommateur qui parcourt [steps] ne les voit
  /// plus. Ceux qui cherchent une étape par son type doivent passer par ici —
  /// un scan de surface renverrait silencieusement rien, et une barre de PV
  /// introuvable saute au lieu de s'animer.
  Iterable<BattleAnimationStep> get flattenedSteps => _flatten(steps);

  static Iterable<BattleAnimationStep> _flatten(
    List<BattleAnimationStep> steps,
  ) sync* {
    for (final step in steps) {
      yield step;
      if (step is AnimationGroupStep) {
        yield* _flatten(step.steps);
      }
    }
  }

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

/// Joue un son de combat nommé — BETA-BAT-014.
///
/// Durée nulle : dans un groupe parallèle il part à l'offset du groupe, dans
/// une suite d'accents il part avec elle, exactement comme le `se_play` de la
/// référence est un nœud sans durée dans son arbre d'animation. Le volume et
/// le pitch sont des pourcentages RMXP, 100 neutre.
final class PlaySeStep extends BattleAnimationStep {
  const PlaySeStep({
    required this.seName,
    this.volume = 100,
    this.pitch = 100,
  });

  final String seName;
  final int volume;
  final int pitch;
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

/// La Poké Ball d'un envoi ou d'un rappel — BETA-BAT-022.
///
/// Parité `100 PokemonSprite.rb` : côté joueur, la Ball est LANCÉE (0,5 s
/// en arc, cellules de vol 0-3 de la planche, SE de lancer) puis s'ouvre
/// (0,1 s, cellules 4-5, SE d'ouverture) ; côté adverse et au rappel, elle
/// s'ouvre sur place après 0,2 s. Le grossissement/rétrécissement du
/// Pokémon est un [CombatantMotionStep] séparé (materializeIn/Out) — cette
/// étape ne joue QUE la Ball. Sans planche chargeable, l'étape ne montre
/// rien et la durée s'écoule quand même : l'entrée ne casse jamais.
final class PlayBallSequenceStep extends BattleAnimationStep {
  const PlayBallSequenceStep({
    required this.side,
    required this.kind,
    this.sheetName = 'ball_1',
  });

  final BattleSideId side;
  final BattleBallSequenceKind kind;
  final String sheetName;

  double get durationSeconds => switch (kind) {
        BattleBallSequenceKind.sendOutThrown => 0.6,
        BattleBallSequenceKind.sendOutHeld => 0.3,
        BattleBallSequenceKind.recall => 0.3,
      };
}

/// Les trois emplois de la Ball dans la référence.
enum BattleBallSequenceKind {
  /// Lancée par le joueur : vol en arc 0,5 s puis ouverture 0,1 s.
  sendOutThrown,

  /// Posée côté adverse : 0,2 s d'attente puis ouverture 0,1 s.
  sendOutHeld,

  /// Le rappel : 0,2 s d'attente puis ouverture 0,1 s (le Pokémon rentre).
  recall,
}

/// Fait réapparaître le dresseur vaincu à la place de son Pokémon —
/// BETA-BAT-017. Accent instantané : l'image a été préparée par l'hôte
/// ([BattleOverlayComponent.prepareDefeatedTrainerVisual]) ; sans image
/// préparée, le step est ignoré et le message seul fait l'annonce.
final class ShowDefeatedTrainerStep extends BattleAnimationStep {
  const ShowDefeatedTrainerStep();
}

/// Remplit la barre d'XP du joueur dans le HUD — BETA-BAT-017.
///
/// Étape À DURÉE (elle tient sa phase) : la référence anime la barre pendant
/// que le message « a gagné N points Exp. ! » reste affiché. Les progrès sont
/// des ratios 0..1 du niveau courant ; une montée de niveau se joue en
/// plusieurs étapes (jusqu'à 1, puis repart de 0).
final class HudXpTweenStep extends BattleAnimationStep {
  const HudXpTweenStep({
    required this.fromProgress,
    required this.toProgress,
    this.durationMs = 600,
  });

  final double fromProgress;
  final double toProgress;
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
