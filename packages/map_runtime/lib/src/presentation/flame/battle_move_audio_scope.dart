import 'dart:async';
import 'dart:math' as math;

import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_recipe_audio_program.dart';

final class BattleTurnAudioSelection {
  const BattleTurnAudioSelection({
    required this.event,
    required this.audio,
    required this.silentVisuals,
    this.trackedEffectId,
  });

  final BattleTurnExecutionEvent event;
  final BattleRecipeAudioResult audio;
  final AnimationGroupStep silentVisuals;
  final String? trackedEffectId;
}

final class BattleTurnAudioRequest {
  const BattleTurnAudioRequest({
    required this.event,
    required this.coordinator,
    required this.audio,
    required this.silentVisuals,
    this.trackedEffectId,
  });

  final BattleTurnExecutionEvent event;
  final BattleRecipeAudioCoordinator coordinator;
  final BattleRecipeAudioSelection audio;
  final AnimationGroupStep silentVisuals;
  final String? trackedEffectId;
}

final class BattleMoveAudioScopeResult {
  const BattleMoveAudioScopeResult._(this.status, this.steps, this.audioScopes);

  final BattleRecipeAudioStatus status;
  final List<BattleAnimationStep> steps;
  final List<BattleAnimationAudioScope> audioScopes;
}

final class BattleMoveAudioScope {
  static BattleMoveAudioScopeResult compose({
    required BattleRecipeAudioResult audio,
    required AnimationGroupStep silentVisuals,
    required List<BattleAnimationStep> fallback,
    BattleSlotRef? forbiddenTargetFlash,
    BattleSlotRef? attackerSlot,
  }) {
    if (audio.status == BattleRecipeAudioStatus.cancelled) {
      return const BattleMoveAudioScopeResult._(
        BattleRecipeAudioStatus.cancelled,
        [],
        [],
      );
    }
    if (audio.status == BattleRecipeAudioStatus.fallback) {
      return BattleMoveAudioScopeResult._(
        BattleRecipeAudioStatus.fallback,
        List.unmodifiable(fallback),
        const [],
      );
    }
    final program = audio.program!;
    if (!program.claim()) throw StateError('Move audio already claimed');
    try {
      final visual = _freezeSilentVisuals(
        silentVisuals,
        forbiddenTargetFlash,
        attackerSlot,
      );
      if (visual == null) {
        unawaited(program.cancel().then<void>((_) {}, onError: (Object _) {}));
        return BattleMoveAudioScopeResult._(
          BattleRecipeAudioStatus.fallback,
          List.unmodifiable(fallback),
          const [],
        );
      }
      final anchor = AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: List.unmodifiable([
          visual,
          AnimationGroupStep(
            mode: BattleAnimationGroupMode.sequence,
            steps: program.steps,
          ),
        ]),
      );
      final scope = _PreparedMoveAudioScope(anchor, program);
      return BattleMoveAudioScopeResult._(
        BattleRecipeAudioStatus.ready,
        List.unmodifiable([anchor]),
        List.unmodifiable([scope]),
      );
    } catch (_) {
      unawaited(program.cancel().then<void>((_) {}, onError: (Object _) {}));
      rethrow;
    }
  }
}

final class _PreparedMoveAudioScope implements BattleAnimationAudioScope {
  _PreparedMoveAudioScope(this.anchor, this._program);

  @override
  final AnimationGroupStep anchor;
  final BattlePreparedRecipeAudio _program;
  bool _started = false;

  @override
  Iterable<PlaySeStep> get cues => _program.steps.whereType<PlaySeStep>();

  @override
  bool claim() {
    if (_started || !_program.canStartReserved) return false;
    _started = true;
    return true;
  }

  @override
  bool dispatch(PlaySeStep step) => _program.dispatch(step);

  @override
  bool get anyDispatched => _program.anyDispatched;

  @override
  bool get fullyDispatched => _program.fullyDispatched;

  @override
  Future<void> get finished => _program.finished;

  @override
  Future<void> cancel() => _program.cancel();
}

AnimationGroupStep? _freezeSilentVisuals(
  AnimationGroupStep root,
  BattleSlotRef? forbiddenTargetFlash,
  BattleSlotRef? attackerSlot,
) {
  var count = 0;
  (BattleAnimationStep, double)? freeze(BattleAnimationStep step, int depth) {
    if (++count > 256 || depth > 32) return null;
    if (step is CombatantFlashStep && step.slot == forbiddenTargetFlash) {
      return null;
    }
    if (step is AnimationGroupStep) {
      if (step.steps.isEmpty) return null;
      final children = <BattleAnimationStep>[];
      var duration = 0.0;
      for (final child in step.steps) {
        final frozen = freeze(child, depth + 1);
        if (frozen == null) return null;
        children.add(frozen.$1);
        duration = step.mode == BattleAnimationGroupMode.sequence
            ? duration + frozen.$2
            : math.max(duration, frozen.$2);
        if (!duration.isFinite || duration > 30) return null;
      }
      return (
        AnimationGroupStep(mode: step.mode, steps: List.unmodifiable(children)),
        duration,
      );
    }
    final durations = switch (step) {
      WaitStep(:final durationSeconds) => [durationSeconds],
      SpawnFxStep(:final durationSeconds, :final startDelaySeconds) => [
        durationSeconds,
        startDelaySeconds,
      ],
      ScreenFlashStep(:final durationSeconds) => [durationSeconds],
      SceneTintStep(:final durationSeconds) => [durationSeconds],
      ParticleBurstStep(:final durationSeconds, :final startDelaySeconds) => [
        durationSeconds,
        startDelaySeconds,
      ],
      CombatantFlashStep(:final durationSeconds) => [durationSeconds],
      CombatantShakeStep(:final durationSeconds) => [durationSeconds],
      CombatantToneStep(:final durationSeconds) => [durationSeconds],
      CombatantCompressStep(:final durationSeconds) => [durationSeconds],
      CombatantEllipseStep(:final durationSeconds) => [durationSeconds],
      CameraFocusStep(:final durationSeconds) => [durationSeconds],
      BattleCameraMoveStep(:final durationSeconds) => [durationSeconds],
      BattleCameraResetStep(:final durationSeconds) => [durationSeconds],
      _ => null,
    };
    if (durations == null ||
        durations.any((value) => !value.isFinite || value < 0)) {
      return null;
    }
    final duration = durations.fold<double>(0, (sum, value) => sum + value);
    if (!duration.isFinite || duration > 30) return null;
    if (step is CameraFocusStep &&
        step.side == null &&
        step.target != BattleCameraFocusTarget.scene &&
        attackerSlot != null) {
      final slot = step.target == BattleCameraFocusTarget.user
          ? attackerSlot
          : forbiddenTargetFlash ?? attackerSlot;
      return (
        CameraFocusStep(
          target: step.target,
          side: slot.side,
          slotIndex: slot.slotIndex,
          durationSeconds: step.durationSeconds,
        ),
        duration,
      );
    }
    return (step, duration);
  }

  final frozen = freeze(root, 0);
  return frozen?.$1 as AnimationGroupStep?;
}
