import 'dart:async';
import 'dart:math' as math;

import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';

final class BattleAnimationRunner {
  BattleAnimationRunner({
    required this.onPresentationChanged,
    required this.onSpawnFx,
    required this.onScreenFlash,
    required this.onCombatantMotion,
    required this.onCombatantFlash,
    required this.onCombatantShake,
    required this.onFaintCombatant,
    required this.onHudHpTween,
    required this.onBarrierPulse,
    required this.onSwapCombatantVisual,
    this.onSpriteSheetFx,
    this.onSpriteSheetOnCombatant,
    this.onParticleBurst,
    this.onSdkParticleSequence,
    this.onSdkFallingParticles,
    this.onSdkRadiusParticles,
    this.onSdkScalarParticle,
    this.onSdkParticleZoom,
    this.onWeatherParticles,
    this.onSceneTint,
    this.onCombatantTone,
    this.onCombatantCompress,
    this.onCombatantEllipse,
    this.onCameraFocus,
    this.onBattleCameraMove,
    this.onBattleCameraReset,
    this.onRmxpAnimation,
    this.messageStepSeconds = 0.42,
  });

  final void Function() onPresentationChanged;
  final void Function(SpawnFxStep step) onSpawnFx;
  final void Function(ScreenFlashStep step) onScreenFlash;
  final void Function(CombatantMotionStep step) onCombatantMotion;
  final void Function(CombatantFlashStep step) onCombatantFlash;
  final void Function(CombatantShakeStep step) onCombatantShake;
  final void Function(FaintCombatantStep step) onFaintCombatant;
  final void Function(HudHpTweenStep step) onHudHpTween;
  final void Function(BarrierPulseStep step) onBarrierPulse;
  final void Function(BattleSideId side) onSwapCombatantVisual;
  final void Function(PlaySpriteSheetFxStep step)? onSpriteSheetFx;
  final void Function(SpriteSheetOnCombatantStep step)?
      onSpriteSheetOnCombatant;
  final void Function(ParticleBurstStep step)? onParticleBurst;
  final void Function(PlaySdkParticleSequenceStep step)? onSdkParticleSequence;
  final void Function(SdkFallingParticlesStep step)? onSdkFallingParticles;
  final void Function(SdkRadiusParticleStep step)? onSdkRadiusParticles;
  final void Function(SdkScalarParticleStep step)? onSdkScalarParticle;
  final void Function(SdkParticleZoomStep step)? onSdkParticleZoom;
  final void Function(WeatherParticleStep step)? onWeatherParticles;
  final void Function(SceneTintStep step)? onSceneTint;
  final void Function(CombatantToneStep step)? onCombatantTone;
  final void Function(CombatantCompressStep step)? onCombatantCompress;
  final void Function(CombatantEllipseStep step)? onCombatantEllipse;
  final void Function(CameraFocusStep step)? onCameraFocus;
  final void Function(BattleCameraMoveStep step)? onBattleCameraMove;
  final void Function(BattleCameraResetStep step)? onBattleCameraReset;
  final void Function(PlayRmxpAnimationStep step)? onRmxpAnimation;
  final double messageStepSeconds;

  BattleAnimationPlan? _plan;
  int _nextStepIndex = 0;
  double _phaseElapsed = 0;
  double _phaseDuration = 0;
  bool _active = false;
  String? _currentMessage;
  HudHpTweenStep? _currentHpTweenStep;
  Completer<void>? _completionCompleter;
  final List<_ScheduledAccentStep> _scheduledAccentSteps =
      <_ScheduledAccentStep>[];

  bool get isActive => _active;

  String? get currentMessage => _currentMessage;

  HudHpTweenStep? get currentHpTweenStep => _currentHpTweenStep;

  Future<void> get completionFuture {
    if (!_active) {
      return Future<void>.value();
    }
    return _completionCompleter?.future ?? Future<void>.value();
  }

  void start(BattleAnimationPlan plan) {
    cancel(clearMessage: false, notify: false);
    if (plan.isEmpty) {
      return;
    }
    _plan = BattleAnimationPlan(steps: _normalizeSteps(plan.steps));
    _nextStepIndex = 0;
    _phaseElapsed = 0;
    _phaseDuration = 0;
    _active = true;
    _currentHpTweenStep = null;
    _completionCompleter = Completer<void>();
    _beginNextPhase();
  }

  void cancel({
    bool clearMessage = true,
    bool notify = true,
  }) {
    _plan = null;
    _nextStepIndex = 0;
    _phaseElapsed = 0;
    _phaseDuration = 0;
    _active = false;
    _currentHpTweenStep = null;
    _scheduledAccentSteps.clear();
    _completeCurrentPlan();
    if (clearMessage) {
      _currentMessage = null;
    }
    if (notify) {
      onPresentationChanged();
    }
  }

  void update(double dt) {
    if (!_active) {
      return;
    }
    var remaining = dt;
    while (_active && remaining > 0) {
      final phaseRemaining = math.max(0, _phaseDuration - _phaseElapsed);
      if (remaining + 0.000001 < phaseRemaining) {
        _phaseElapsed += remaining;
        _dispatchDueScheduledAccents();
        return;
      }
      _phaseElapsed = _phaseDuration;
      _dispatchDueScheduledAccents();
      remaining -= phaseRemaining;
      _beginNextPhase();
    }
  }

  void _beginNextPhase() {
    _currentHpTweenStep = null;
    _phaseElapsed = 0;
    _phaseDuration = 0;
    _scheduledAccentSteps.clear();

    while (true) {
      final plan = _plan;
      if (plan == null || _nextStepIndex >= plan.steps.length) {
        _active = false;
        _currentMessage = null;
        _currentHpTweenStep = null;
        _plan = null;
        _completeCurrentPlan();
        onPresentationChanged();
        return;
      }

      final step = plan.steps[_nextStepIndex];
      switch (step) {
        case ShowMessageStep(:final message):
          _nextStepIndex += 1;
          _currentMessage = message;
          _phaseDuration = messageStepSeconds;
          onPresentationChanged();
          return;
        case WaitStep(:final durationSeconds):
          _nextStepIndex += 1;
          _phaseDuration = durationSeconds;
          onPresentationChanged();
          if (_phaseDuration <= 0) {
            continue;
          }
          return;
        case HudHpTweenStep():
          _nextStepIndex += 1;
          _currentHpTweenStep = step;
          onHudHpTween(step);
          _phaseDuration = step.durationMs / 1000;
          onPresentationChanged();
          if (_phaseDuration <= 0) {
            continue;
          }
          return;
        case CombatantMotionStep():
          _nextStepIndex += 1;
          onCombatantMotion(step);
          _phaseDuration = step.durationSeconds;
          onPresentationChanged();
          if (_phaseDuration <= 0) {
            continue;
          }
          return;
        case FaintCombatantStep():
          _nextStepIndex += 1;
          onFaintCombatant(step);
          _phaseDuration = step.durationSeconds;
          onPresentationChanged();
          if (_phaseDuration <= 0) {
            continue;
          }
          return;
        case SpawnFxStep()
            when !step.playAsAccent &&
                (step.from != step.to ||
                    step.curve == BattleFxMotionCurve.arcOver ||
                    step.curve == BattleFxMotionCurve.arcUnder):
          _nextStepIndex += 1;
          onSpawnFx(step);
          _phaseDuration = step.startDelaySeconds + step.durationSeconds;
          onPresentationChanged();
          if (_phaseDuration <= 0) {
            continue;
          }
          return;
        default:
          final accentDuration = _startAccentPhase();
          _dispatchDueScheduledAccents();
          onPresentationChanged();
          if (accentDuration <= 0) {
            continue;
          }
          _phaseDuration = accentDuration;
          return;
      }
    }
  }

  List<BattleAnimationStep> _normalizeSteps(List<BattleAnimationStep> steps) {
    final normalized = <BattleAnimationStep>[];
    for (final step in steps) {
      switch (step) {
        case AnimationGroupStep(
            mode: BattleAnimationGroupMode.sequence,
            :final steps,
          ):
          normalized.addAll(_normalizeSteps(steps));
        case _:
          normalized.add(step);
      }
    }
    return normalized;
  }

  double _startAccentPhase() {
    final plan = _plan;
    if (plan == null) {
      return 0;
    }

    var maxDuration = 0.0;
    while (_nextStepIndex < plan.steps.length) {
      final step = plan.steps[_nextStepIndex];
      if (!_isAccentStep(step)) {
        break;
      }
      maxDuration = math.max(
        maxDuration,
        _scheduleAccentStep(step, startAtSeconds: 0),
      );
      _nextStepIndex += 1;
    }
    return maxDuration;
  }

  bool _isAccentStep(BattleAnimationStep step) {
    return switch (step) {
      SpawnFxStep() => true,
      ScreenFlashStep() => true,
      SceneTintStep() => true,
      PlaySpriteSheetFxStep() => true,
      SpriteSheetOnCombatantStep() => true,
      ParticleBurstStep() => true,
      PlaySdkParticleSequenceStep() => true,
      SdkFallingParticlesStep() => true,
      SdkRadiusParticleStep() => true,
      SdkScalarParticleStep() => true,
      SdkParticleZoomStep() => true,
      WeatherParticleStep() => true,
      PlayRmxpAnimationStep() => true,
      CombatantFlashStep() => true,
      CombatantShakeStep() => true,
      CombatantToneStep() => true,
      CombatantCompressStep() => true,
      CombatantEllipseStep() => true,
      CameraFocusStep() => true,
      BattleCameraMoveStep() => true,
      BattleCameraResetStep() => true,
      SwapCombatantVisualStep() => true,
      BarrierPulseStep() => true,
      AnimationGroupStep() => true,
      _ => false,
    };
  }

  double _scheduleAccentStep(
    BattleAnimationStep step, {
    required double startAtSeconds,
  }) {
    return switch (step) {
      SpawnFxStep(:final durationSeconds, :final startDelaySeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + startDelaySeconds + durationSeconds;
        }(),
      ScreenFlashStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      SceneTintStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      PlaySpriteSheetFxStep() => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + step.durationSeconds;
        }(),
      SpriteSheetOnCombatantStep() => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + step.durationSeconds;
        }(),
      ParticleBurstStep(:final durationSeconds, :final startDelaySeconds) =>
        () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + startDelaySeconds + durationSeconds;
        }(),
      PlaySdkParticleSequenceStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      SdkFallingParticlesStep(
        :final durationSeconds,
        :final particleCount,
        :final intervalSeconds
      ) =>
        () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds +
              durationSeconds +
              (math.max(0, particleCount - 1) * intervalSeconds);
        }(),
      SdkRadiusParticleStep(
        :final durationSeconds,
        :final particleCount,
        :final intervalSeconds
      ) =>
        () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds +
              durationSeconds +
              (math.max(0, particleCount - 1) * intervalSeconds);
        }(),
      SdkScalarParticleStep(:final durationSeconds, :final delaySeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + delaySeconds + durationSeconds;
        }(),
      SdkParticleZoomStep(:final durationSeconds, :final delaySeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + delaySeconds + durationSeconds;
        }(),
      WeatherParticleStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      PlayRmxpAnimationStep() => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + step.totalDurationSeconds;
        }(),
      CombatantFlashStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      CombatantShakeStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      CombatantToneStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      CombatantCompressStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      CombatantEllipseStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      CameraFocusStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      BattleCameraMoveStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      BattleCameraResetStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      BarrierPulseStep(:final durationSeconds) => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds + durationSeconds;
        }(),
      SwapCombatantVisualStep() => () {
          _scheduledAccentSteps.add(_ScheduledAccentStep(startAtSeconds, step));
          return startAtSeconds;
        }(),
      AnimationGroupStep(:final mode, :final steps) => () {
          if (mode == BattleAnimationGroupMode.sequence) {
            var cursor = startAtSeconds;
            for (final child in _normalizeSteps(steps)) {
              cursor = _scheduleAccentStep(child, startAtSeconds: cursor);
            }
            return cursor;
          }
          var maxDuration = 0.0;
          for (final child in steps) {
            maxDuration = math.max(
              maxDuration,
              _scheduleAccentStep(child, startAtSeconds: startAtSeconds),
            );
          }
          return maxDuration;
        }(),
      _ => 0.0,
    };
  }

  void _dispatchDueScheduledAccents() {
    for (final scheduledStep in _scheduledAccentSteps) {
      if (scheduledStep.dispatched ||
          scheduledStep.startAtSeconds > _phaseElapsed + 0.000001) {
        continue;
      }
      scheduledStep.dispatched = true;
      _dispatchAccentStep(scheduledStep.step);
    }
  }

  void _dispatchAccentStep(BattleAnimationStep step) {
    switch (step) {
      case SpawnFxStep():
        onSpawnFx(step);
      case ScreenFlashStep():
        onScreenFlash(step);
      case SceneTintStep():
        onSceneTint?.call(step);
      case PlaySpriteSheetFxStep():
        onSpriteSheetFx?.call(step);
      case SpriteSheetOnCombatantStep():
        onSpriteSheetOnCombatant?.call(step);
      case ParticleBurstStep():
        onParticleBurst?.call(step);
      case PlaySdkParticleSequenceStep():
        onSdkParticleSequence?.call(step);
      case SdkFallingParticlesStep():
        onSdkFallingParticles?.call(step);
      case SdkRadiusParticleStep():
        onSdkRadiusParticles?.call(step);
      case SdkScalarParticleStep():
        onSdkScalarParticle?.call(step);
      case SdkParticleZoomStep():
        onSdkParticleZoom?.call(step);
      case WeatherParticleStep():
        onWeatherParticles?.call(step);
      case PlayRmxpAnimationStep():
        onRmxpAnimation?.call(step);
      case CombatantFlashStep():
        onCombatantFlash(step);
      case CombatantShakeStep():
        onCombatantShake(step);
      case CombatantToneStep():
        onCombatantTone?.call(step);
      case CombatantCompressStep():
        onCombatantCompress?.call(step);
      case CombatantEllipseStep():
        onCombatantEllipse?.call(step);
      case CameraFocusStep():
        onCameraFocus?.call(step);
      case BattleCameraMoveStep():
        onBattleCameraMove?.call(step);
      case BattleCameraResetStep():
        onBattleCameraReset?.call(step);
      case BarrierPulseStep():
        onBarrierPulse(step);
      case SwapCombatantVisualStep(:final side):
        onSwapCombatantVisual(side);
      case AnimationGroupStep():
      case ShowMessageStep():
      case WaitStep():
      case CombatantMotionStep():
      case FaintCombatantStep():
      case HudHpTweenStep():
        break;
    }
  }

  void _completeCurrentPlan() {
    final completer = _completionCompleter;
    _completionCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}

final class _ScheduledAccentStep {
  _ScheduledAccentStep(this.startAtSeconds, this.step);

  final double startAtSeconds;
  final BattleAnimationStep step;
  bool dispatched = false;
}
