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
    this.onHudXpTween,
    this.onHudLevelUp,
    this.onShowDefeatedTrainer,
    this.onPlayBallSequence,
    this.onPlayBallCaptureSequence,
    this.onEnemyTrainerIntro,
    this.onStatStageAura,
    this.onShowTeamInfo,
    this.onPlayCry,
    this.onPlaySe,
    required this.onBarrierPulse,
    required this.onSwapCombatantVisual,
    this.onSwapCombatantVisualSlot,
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
    this.onStartTrackedEffect,
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
  final void Function(HudXpTweenStep step)? onHudXpTween;
  final void Function()? onHudLevelUp;
  final void Function()? onShowDefeatedTrainer;
  final void Function(PlayBallSequenceStep step)? onPlayBallSequence;
  final void Function(PlayBallCaptureSequenceStep step)?
  onPlayBallCaptureSequence;
  final void Function(EnemyTrainerIntroStep step)? onEnemyTrainerIntro;
  final void Function(StatStageAuraStep step)? onStatStageAura;
  final void Function()? onShowTeamInfo;
  final void Function(PlayCryStep step)? onPlayCry;

  /// BETA-BAT-014 : un son du plan. Nul chez un hôte sans audio — les
  /// harnais de test et les hôtes silencieux gardent exactement l'ancien
  /// comportement.
  final void Function(PlaySeStep step)? onPlaySe;
  final void Function(BarrierPulseStep step) onBarrierPulse;
  final void Function(BattleSideId side) onSwapCombatantVisual;
  final void Function(BattleSlotRef slot)? onSwapCombatantVisualSlot;
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
  final void Function() Function(StartTrackedEffectStep, void Function())?
      onStartTrackedEffect;
  final double messageStepSeconds;

  BattleAnimationPlan? _plan;
  int _nextStepIndex = 0;
  double _phaseElapsed = 0;
  double _phaseDuration = 0;
  bool _active = false;
  bool _phaseStarted = false;
  bool _phaseNotificationPending = false;
  bool _isDraining = false;
  int? _sharedWorkRemaining;
  double _pendingSeconds = 0;
  int _nextAccentIndex = 0;
  bool _cameraSequenceActive = false;
  bool _cameraResetPending = false;
  bool _waitingTrackedEffects = false;
  int _generation = 0;
  final Map<Object, void Function()?> _trackedEffects = {};
  String? _currentMessage;
  HudHpTweenStep? _currentHpTweenStep;
  HudXpTweenStep? _currentXpTweenStep;
  Completer<void>? _completionCompleter;
  final List<_ScheduledAccentStep> _scheduledAccentSteps =
      <_ScheduledAccentStep>[];

  bool get isActive => _active;
  bool get hasImmediateWork =>
      _active &&
      (!_waitingTrackedEffects || _trackedEffects.isEmpty) &&
      (!_phaseStarted ||
          _phaseNotificationPending ||
          _pendingSeconds > 0 ||
          _phaseElapsed + 0.000001 >= _phaseDuration ||
          (_nextAccentIndex < _scheduledAccentSteps.length &&
              _scheduledAccentSteps[_nextAccentIndex].startAtSeconds <=
                  _phaseElapsed + 0.000001));

  double get secondsUntilNextPhase {
    if (!_active) return double.infinity;
    if (_waitingTrackedEffects && _trackedEffects.isNotEmpty) {
      return double.infinity;
    }
    if (hasImmediateWork) return 0;
    final nextAccent = _nextAccentIndex < _scheduledAccentSteps.length
        ? _scheduledAccentSteps[_nextAccentIndex].startAtSeconds
        : double.infinity;
    return math.max(0, math.min(_phaseDuration, nextAccent) - _phaseElapsed);
  }

  bool get areGaugesHidden => _cameraSequenceActive;

  String? get currentMessage => _currentMessage;

  HudHpTweenStep? get currentHpTweenStep => _currentHpTweenStep;
  HudXpTweenStep? get currentXpTweenStep => _currentXpTweenStep;

  Future<void> get completionFuture {
    if (!_active) {
      return Future<void>.value();
    }
    return _completionCompleter?.future ?? Future<void>.value();
  }

  void start(BattleAnimationPlan plan) {
    void validate(List<BattleAnimationStep> steps, bool inParallel) {
      for (final step in steps) {
        if (step is StartTrackedEffectStep && onStartTrackedEffect == null) {
          throw StateError('Tracked effects are not supported by this host');
        }
        if (step is WaitTrackedEffectsStep && inParallel) {
          throw StateError('Tracked effect barriers are not supported inside parallel groups');
        }
        if (step is AnimationGroupStep) {
          validate(step.steps, inParallel || step.mode == BattleAnimationGroupMode.parallel);
        }
      }
    }
    validate(plan.steps, false);
    final previousGeneration = _generation;
    cancel(clearMessage: false, notify: false);
    if (_generation != previousGeneration + 1) return;
    if (plan.isEmpty) {
      return;
    }
    _plan = BattleAnimationPlan(steps: _normalizeSteps(plan.steps));
    _nextStepIndex = 0;
    _phaseElapsed = 0;
    _phaseDuration = 0;
    _active = true;
    _currentHpTweenStep = null;
    _currentXpTweenStep = null;
    _completionCompleter = Completer<void>();
    _drain(256);
  }

  void cancel({bool clearMessage = true, bool notify = true}) {
    _generation += 1;
    final cancellations = _trackedEffects.values.toList();
    _trackedEffects.clear();
    _waitingTrackedEffects = false;
    _plan = null;
    _nextStepIndex = 0;
    _phaseElapsed = 0;
    _phaseDuration = 0;
    _active = false;
    _phaseStarted = false;
    _phaseNotificationPending = false;
    _pendingSeconds = 0;
    _nextAccentIndex = 0;
    _cameraSequenceActive = false;
    _cameraResetPending = false;
    _currentHpTweenStep = null;
    _currentXpTweenStep = null;
    _scheduledAccentSteps.clear();
    _completeCurrentPlan();
    if (clearMessage) {
      _currentMessage = null;
    }
    _cancelAllTrackedEffects(cancellations);
    if (notify) {
      onPresentationChanged();
    }
  }

  int update(double dt, {int workBudget = 256}) {
    if (!_active || !dt.isFinite || dt < 0) return 0;
    if (_waitingTrackedEffects) {
      _pendingSeconds = 0;
      return _drain(workBudget.clamp(0, 256));
    }
    final pending = _pendingSeconds + dt;
    if (!pending.isFinite) return 0;
    _pendingSeconds = pending;
    return _drain(workBudget.clamp(0, 256));
  }

  void withWorkBudget(void Function() advance) {
    if (_sharedWorkRemaining != null) {
      advance();
      return;
    }
    _sharedWorkRemaining = 256;
    try {
      advance();
    } finally {
      _sharedWorkRemaining = null;
    }
  }

  int _drain(int workBudget) {
    if (_isDraining) return 0;
    _isDraining = true;
    workBudget = math.min(workBudget, _sharedWorkRemaining ?? workBudget);
    var workRemaining = workBudget;
    try {
      while (_active && workRemaining > 0) {
        if (_waitingTrackedEffects) {
          if (_trackedEffects.isNotEmpty) {
            _pendingSeconds = 0;
            break;
          }
          _waitingTrackedEffects = false;
        }
        if (!_phaseStarted) {
          workRemaining -= 1;
          _beginNextPhase();
          continue;
        }
        if (_nextAccentIndex < _scheduledAccentSteps.length &&
            _scheduledAccentSteps[_nextAccentIndex].startAtSeconds <=
                _phaseElapsed + 0.000001) {
          workRemaining -= 1;
          final step = _scheduledAccentSteps[_nextAccentIndex++].step;
          _dispatchAccentStep(step);
          continue;
        }
        if (_phaseNotificationPending) {
          workRemaining -= 1;
          _phaseNotificationPending = false;
          onPresentationChanged();
          continue;
        }
        if (_phaseElapsed + 0.000001 >= _phaseDuration) {
          _phaseStarted = false;
          continue;
        }
        if (_pendingSeconds <= 0) break;
        final nextAccent = _nextAccentIndex < _scheduledAccentSteps.length
            ? _scheduledAccentSteps[_nextAccentIndex].startAtSeconds
            : double.infinity;
        final untilNext = math.min(_phaseDuration, nextAccent) - _phaseElapsed;
        final elapsed = math.min(_pendingSeconds, untilNext);
        _phaseElapsed += elapsed;
        _pendingSeconds = math.max(0, _pendingSeconds - elapsed);
      }
    } finally {
      _isDraining = false;
      if (_sharedWorkRemaining != null) {
        _sharedWorkRemaining = _sharedWorkRemaining! - (workBudget - workRemaining);
      }
    }
    return workBudget - workRemaining;
  }

  void _beginNextPhase() {
    if (_cameraResetPending) {
      _cameraSequenceActive = false;
      _cameraResetPending = false;
    }
    _currentHpTweenStep = null;
    _currentXpTweenStep = null;
    _phaseElapsed = 0;
    _phaseDuration = 0;
    _nextAccentIndex = 0;
    _scheduledAccentSteps.clear();
    final plan = _plan;
    if (plan == null || _nextStepIndex >= plan.steps.length) {
      _active = false;
      _cameraSequenceActive = false;
      _currentMessage = null;
      _plan = null;
      _pendingSeconds = 0;
      _completeCurrentPlan();
      final generation = ++_generation;
      final cancellations = _trackedEffects.values.toList();
      _trackedEffects.clear();
      _cancelAllTrackedEffects(cancellations);
      if (_generation != generation) return;
      onPresentationChanged();
      return;
    }
    _phaseStarted = true;
    _phaseNotificationPending = true;
    final step = plan.steps[_nextStepIndex];
    switch (step) {
      case ShowMessageStep(:final message):
        _nextStepIndex += 1;
        _currentMessage = message;
        _phaseDuration = messageStepSeconds;
      case WaitStep(:final durationSeconds):
        _nextStepIndex += 1;
        _phaseDuration = durationSeconds;
      case WaitTrackedEffectsStep():
        _nextStepIndex += 1;
        _waitingTrackedEffects = true;
      case HudHpTweenStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationMs / 1000;
        _currentHpTweenStep = step;
        onHudHpTween(step);
      case HudXpTweenStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationMs / 1000;
        _currentXpTweenStep = step;
        onHudXpTween?.call(step);
      case PlayBallSequenceStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onPlayBallSequence?.call(step);
      case PlayBallCaptureSequenceStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onPlayBallCaptureSequence?.call(step);
      case EnemyTrainerIntroStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onEnemyTrainerIntro?.call(step);
      case StatStageAuraStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onStatStageAura?.call(step);
      case ShowTeamInfoStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onShowTeamInfo?.call();
      case CombatantMotionStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onCombatantMotion(step);
      case FaintCombatantStep():
        _nextStepIndex += 1;
        _phaseDuration = step.durationSeconds;
        onFaintCombatant(step);
      case SpawnFxStep()
          when !step.playAsAccent &&
              (step.from != step.to ||
                  step.curve == BattleFxMotionCurve.arcOver ||
                  step.curve == BattleFxMotionCurve.arcUnder):
        _nextStepIndex += 1;
        _phaseDuration = step.startDelaySeconds + step.durationSeconds;
        onSpawnFx(step);
      default:
        _phaseDuration = _startAccentPhase();
        _scheduledAccentSteps.sort((left, right) {
          final time = left.startAtSeconds.compareTo(right.startAtSeconds);
          return time != 0 ? time : left.order.compareTo(right.order);
        });
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
    var consumed = 0;
    while (_nextStepIndex < plan.steps.length) {
      final step = plan.steps[_nextStepIndex];
      if (!_isAccentStep(step)) {
        break;
      }
      // BETA-BAT-013 : un groupe PARALLÈLE déclare « ceux-là et eux seuls
      // partent ensemble ». Le fusionner avec les accents voisins contredirait
      // cette déclaration : le groupe clignotement + barre de PV se retrouvait
      // démarré en même temps que le FX d'impact qui le précède, c'est-à-dire
      // exactement le défaut que ce ticket corrige. Il forme donc sa propre
      // phase — seul s'il ouvre la suite, sinon il attend la suivante.
      if (step is AnimationGroupStep &&
          step.mode == BattleAnimationGroupMode.parallel) {
        if (consumed > 0) {
          break;
        }
        maxDuration = _scheduleAccentStep(step, startAtSeconds: 0);
        _nextStepIndex += 1;
        return maxDuration;
      }
      maxDuration = math.max(
        maxDuration,
        _scheduleAccentStep(step, startAtSeconds: 0),
      );
      consumed += 1;
      _nextStepIndex += 1;
    }
    return maxDuration;
  }

  bool _isAccentStep(BattleAnimationStep step) {
    return switch (step) {
      SpawnFxStep() => true,
      StartTrackedEffectStep() => true,
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
      PlaySeStep() => true,
      PlayCryStep() => true,
      CombatantShakeStep() => true,
      CombatantToneStep() => true,
      CombatantCompressStep() => true,
      CombatantEllipseStep() => true,
      CameraFocusStep() => true,
      BattleCameraMoveStep() => true,
      BattleCameraResetStep() => true,
      SwapCombatantVisualStep() => true,
      ShowDefeatedTrainerStep() => true,
      HudLevelUpStep() => true,
      BarrierPulseStep() => true,
      AnimationGroupStep() => true,
      _ => false,
    };
  }

  void _addScheduledAccentStep(
    double startAtSeconds,
    BattleAnimationStep step,
  ) {
    _scheduledAccentSteps.add(
      _ScheduledAccentStep(startAtSeconds, step, _scheduledAccentSteps.length),
    );
  }

  double _scheduleAccentStep(
    BattleAnimationStep step, {
    required double startAtSeconds,
  }) {
    return switch (step) {
      WaitStep(:final durationSeconds) =>
        startAtSeconds + math.max(0, durationSeconds),
      WaitTrackedEffectsStep() => throw StateError(
        'Tracked effect barriers are not supported inside parallel groups',
      ),
      StartTrackedEffectStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds;
      }(),
      SpawnFxStep(:final durationSeconds, :final startDelaySeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + startDelaySeconds + durationSeconds;
      }(),
      ScreenFlashStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      SceneTintStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      PlaySpriteSheetFxStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + step.durationSeconds;
      }(),
      SpriteSheetOnCombatantStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + step.durationSeconds;
      }(),
      ParticleBurstStep(:final durationSeconds, :final startDelaySeconds) =>
        () {
          _addScheduledAccentStep(startAtSeconds, step);
          return startAtSeconds + startDelaySeconds + durationSeconds;
        }(),
      PlaySdkParticleSequenceStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      SdkFallingParticlesStep(
        :final durationSeconds,
        :final particleCount,
        :final intervalSeconds,
      ) =>
        () {
          _addScheduledAccentStep(startAtSeconds, step);
          return startAtSeconds +
              durationSeconds +
              (math.max(0, particleCount - 1) * intervalSeconds);
        }(),
      SdkRadiusParticleStep(
        :final durationSeconds,
        :final particleCount,
        :final intervalSeconds,
      ) =>
        () {
          _addScheduledAccentStep(startAtSeconds, step);
          return startAtSeconds +
              durationSeconds +
              (math.max(0, particleCount - 1) * intervalSeconds);
        }(),
      SdkScalarParticleStep(:final durationSeconds, :final delaySeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + delaySeconds + durationSeconds;
      }(),
      SdkParticleZoomStep(:final durationSeconds, :final delaySeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + delaySeconds + durationSeconds;
      }(),
      WeatherParticleStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      PlayRmxpAnimationStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + step.totalDurationSeconds;
      }(),
      CombatantFlashStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      PlaySeStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds;
      }(),
      PlayCryStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds;
      }(),
      ShowDefeatedTrainerStep() || HudLevelUpStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds;
      }(),
      // BETA-BAT-013 : la barre de PV est ordonnançable À L'INTÉRIEUR d'un
      // groupe, pour qu'elle puisse partir sur la même frame que le
      // clignotement de la cible. Hors groupe elle reste une phase bloquante :
      // `_isAccentStep` ne la reconnaît pas, donc rien ne change pour les plans
      // qui l'émettent seule.
      HudHpTweenStep(:final durationMs) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationMs / 1000;
      }(),
      CombatantShakeStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      CombatantToneStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      CombatantCompressStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      CombatantEllipseStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      CameraFocusStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      BattleCameraMoveStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      BattleCameraResetStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      BarrierPulseStep(:final durationSeconds) => () {
        _addScheduledAccentStep(startAtSeconds, step);
        return startAtSeconds + durationSeconds;
      }(),
      SwapCombatantVisualStep() => () {
        _addScheduledAccentStep(startAtSeconds, step);
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

  void _dispatchAccentStep(BattleAnimationStep step) {
    switch (step) {
      case StartTrackedEffectStep():
        final startEffect = onStartTrackedEffect;
        if (startEffect == null) {
          throw StateError('Tracked effects are not supported by this host');
        }
        final token = Object();
        final generation = _generation;
        _trackedEffects[token] = null;
        late final void Function() cancelEffect;
        try {
          cancelEffect = startEffect(step, () {
            if (_generation == generation) _trackedEffects.remove(token);
          });
        } catch (_) {
          if (_generation == generation) cancel();
          rethrow;
        }
        if (_generation != generation) {
          cancelEffect();
        } else if (_trackedEffects.containsKey(token)) {
          _trackedEffects[token] = cancelEffect;
        }
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
      case PlaySeStep():
        onPlaySe?.call(step);
      case PlayCryStep():
        onPlayCry?.call(step);
      case CombatantShakeStep():
        onCombatantShake(step);
      case CombatantToneStep():
        onCombatantTone?.call(step);
      case CombatantCompressStep():
        onCombatantCompress?.call(step);
      case CombatantEllipseStep():
        onCombatantEllipse?.call(step);
      case CameraFocusStep():
        _cameraSequenceActive = true;
        onCameraFocus?.call(step);
      case BattleCameraMoveStep():
        _cameraSequenceActive = true;
        onBattleCameraMove?.call(step);
      case BattleCameraResetStep():
        _cameraResetPending = true;
        onBattleCameraReset?.call(step);
      case BarrierPulseStep():
        onBarrierPulse(step);
      case SwapCombatantVisualStep(:final side):
        if (onSwapCombatantVisualSlot case final callback?) {
          callback(step.slot);
        } else {
          onSwapCombatantVisual(side);
        }
      case ShowDefeatedTrainerStep():
        onShowDefeatedTrainer?.call();
      case HudLevelUpStep():
        onHudLevelUp?.call();
      case HudHpTweenStep():
        // Le chemin bloquant renseigne `_currentHpTweenStep`, que l'overlay lit
        // pour interpoler la barre image par image. Sans lui, la barre recevait
        // sa cible et y SAUTAIT au lieu de descendre.
        _currentHpTweenStep = step;
        onHudHpTween(step);
      case HudXpTweenStep():
        onHudXpTween?.call(step);
      case PlayBallSequenceStep():
        onPlayBallSequence?.call(step);
      case PlayBallCaptureSequenceStep():
        onPlayBallCaptureSequence?.call(step);
      case EnemyTrainerIntroStep():
        onEnemyTrainerIntro?.call(step);
      case StatStageAuraStep():
        onStatStageAura?.call(step);
      case ShowTeamInfoStep():
        onShowTeamInfo?.call();
      case AnimationGroupStep():
      case ShowMessageStep():
      case WaitStep():
      case WaitTrackedEffectsStep():
      case CombatantMotionStep():
      case FaintCombatantStep():
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

void _cancelAllTrackedEffects(Iterable<void Function()?> cancellations) {
  Object? firstError;
  StackTrace? firstStack;
  for (final cancelEffect in cancellations) {
    try {
      cancelEffect?.call();
    } catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
    }
  }
  if (firstError != null) {
    Error.throwWithStackTrace(firstError, firstStack!);
  }
}

final class _ScheduledAccentStep {
  _ScheduledAccentStep(this.startAtSeconds, this.step, this.order);

  final double startAtSeconds;
  final BattleAnimationStep step;
  final int order;
}
