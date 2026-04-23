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
  final double messageStepSeconds;

  BattleAnimationPlan? _plan;
  int _nextStepIndex = 0;
  double _phaseElapsed = 0;
  double _phaseDuration = 0;
  bool _active = false;
  String? _currentMessage;
  HudHpTweenStep? _currentHpTweenStep;
  Completer<void>? _completionCompleter;

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
    _plan = plan;
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
      if (remaining < phaseRemaining) {
        _phaseElapsed += remaining;
        return;
      }
      _phaseElapsed = _phaseDuration;
      remaining -= phaseRemaining;
      _beginNextPhase();
    }
  }

  void _beginNextPhase() {
    _currentHpTweenStep = null;
    _phaseElapsed = 0;
    _phaseDuration = 0;

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
          onPresentationChanged();
          if (accentDuration <= 0) {
            continue;
          }
          _phaseDuration = accentDuration;
          return;
      }
    }
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
      maxDuration = math.max(maxDuration, _playAccentStep(step));
      _nextStepIndex += 1;
    }
    return maxDuration;
  }

  bool _isAccentStep(BattleAnimationStep step) {
    return switch (step) {
      SpawnFxStep() => true,
      ScreenFlashStep() => true,
      CombatantFlashStep() => true,
      CombatantShakeStep() => true,
      SwapCombatantVisualStep() => true,
      BarrierPulseStep() => true,
      _ => false,
    };
  }

  double _playAccentStep(BattleAnimationStep step) {
    return switch (step) {
      SpawnFxStep(:final durationSeconds, :final startDelaySeconds) => () {
          onSpawnFx(step);
          return startDelaySeconds + durationSeconds;
        }(),
      ScreenFlashStep(:final durationSeconds) => () {
          onScreenFlash(step);
          return durationSeconds;
        }(),
      CombatantFlashStep(:final durationSeconds) => () {
          onCombatantFlash(step);
          return durationSeconds;
        }(),
      CombatantShakeStep(:final durationSeconds) => () {
          onCombatantShake(step);
          return durationSeconds;
        }(),
      BarrierPulseStep(:final durationSeconds) => () {
          onBarrierPulse(step);
          return durationSeconds;
        }(),
      SwapCombatantVisualStep(:final side) => () {
          onSwapCombatantVisual(side);
          return 0.0;
        }(),
      _ => 0.0,
    };
  }

  void _completeCurrentPlan() {
    final completer = _completionCompleter;
    _completionCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
