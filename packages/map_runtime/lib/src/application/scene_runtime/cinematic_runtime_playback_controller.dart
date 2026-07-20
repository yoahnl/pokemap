import 'dart:async';

import 'package:map_core/map_core.dart';

import 'scene_cinematic_runtime_awaitable_adapter.dart';
import 'scene_cinematic_runtime_awaitable_result.dart';

enum CinematicRuntimeTermination {
  completed,
  cancelled,
  failed,
}

final class CinematicRuntimeSinkPreflightResult {
  const CinematicRuntimeSinkPreflightResult.ready()
      : errorCode = null,
        message = null;

  const CinematicRuntimeSinkPreflightResult.rejected({
    this.errorCode = SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
    required this.message,
  });

  final SceneCinematicRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get isReady => errorCode == null;
}

final class CinematicRuntimeStepContext {
  const CinematicRuntimeStepContext({
    required this.asset,
    required this.step,
    required this.stepIndex,
    required this.elapsed,
    required this.delta,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final int stepIndex;
  final Duration elapsed;
  final Duration delta;
}

/// Rendering/runtime boundary for the update-driven cinematic controller.
///
/// [preflight] must be read-only. [restore] is deliberately a single atomic
/// hook so a concrete runtime can restore camera, actors and overlays together.
abstract interface class CinematicRuntimePlaybackSink {
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset);

  void beginStep(CinematicRuntimeStepContext context);

  void updateStep(CinematicRuntimeStepContext context);

  bool isStepVisuallyComplete(CinematicRuntimeStepContext context);

  void endStep(CinematicRuntimeStepContext context);

  void restore(CinematicRuntimeTermination termination);
}

abstract interface class CinematicRuntimeStepCompletionPolicy {
  bool requiresSinkCompletion(CinematicRuntimeStepContext context);
}

abstract interface class CinematicRuntimeAsyncRestorationSink {
  Future<void> restoreAsync(CinematicRuntimeTermination termination);
}

/// Sequential, wall-clock-free playback state machine for CinematicAsset V1.
///
/// The controller owns ordering and duration accounting only. A Flame adapter
/// can implement [CinematicRuntimePlaybackSink] in a later lot without moving
/// gameplay or rendering concerns into this application layer.
final class CinematicRuntimePlaybackController
    implements SceneCinematicRuntimePlayer {
  CinematicRuntimePlaybackController({required this.sink});

  final CinematicRuntimePlaybackSink sink;

  _CinematicRuntimeSession? _session;

  bool get isPlaying => _session != null;

  CinematicTimelineStep? get currentStep {
    final session = _session;
    if (session == null || session.stepIndex >= session.steps.length) {
      return null;
    }
    return session.steps[session.stepIndex];
  }

  @override
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  ) {
    return play(request.asset);
  }

  Future<SceneCinematicRuntimeAwaitableResult> play(CinematicAsset asset) {
    if (_session != null) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        const SceneCinematicRuntimeAwaitableResult.failed(
          errorCode: SceneCinematicRuntimeAwaitableErrorCode.alreadyPlaying,
          message: 'A cinematic is already playing.',
        ),
      );
    }

    final structuralFailure = _preflightAsset(asset);
    if (structuralFailure != null) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        structuralFailure,
      );
    }

    final CinematicRuntimeSinkPreflightResult sinkPreflight;
    try {
      sinkPreflight = sink.preflight(asset);
    } catch (error) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        SceneCinematicRuntimeAwaitableResult.failed(
          errorCode: SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
          message: 'Cinematic sink preflight failed: $error',
        ),
      );
    }
    if (!sinkPreflight.isReady) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        SceneCinematicRuntimeAwaitableResult.failed(
          errorCode: sinkPreflight.errorCode ??
              SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
          message:
              sinkPreflight.message ?? 'Cinematic sink rejected preflight.',
        ),
      );
    }

    final session = _CinematicRuntimeSession(asset);
    _session = session;
    _beginCurrentStepOrComplete();
    return session.completer.future;
  }

  void update(Duration delta) {
    if (delta.isNegative) {
      throw ArgumentError.value(delta, 'delta', 'must not be negative');
    }
    var remaining = delta;
    while (_session != null) {
      final session = _session!;
      if (!session.stepBegun) {
        _beginCurrentStepOrComplete();
        if (_session == null || !_session!.stepBegun) return;
      }

      final step = session.steps[session.stepIndex];
      final duration = _positiveDurationOf(step);
      final stepRemaining =
          duration == null ? remaining : duration - session.stepElapsed;
      final applied = duration == null || remaining <= stepRemaining
          ? remaining
          : stepRemaining;
      session.stepElapsed += applied;
      final context = _contextFor(session, delta: applied);

      try {
        sink.updateStep(context);
        final visuallyComplete = sink.isStepVisuallyComplete(context);
        final durationComplete =
            duration != null && session.stepElapsed >= duration;
        final requiresSinkCompletion =
            sink is CinematicRuntimeStepCompletionPolicy &&
                (sink as CinematicRuntimeStepCompletionPolicy)
                    .requiresSinkCompletion(context);
        if (requiresSinkCompletion) {
          if (!visuallyComplete || (duration != null && !durationComplete)) {
            return;
          }
        } else if (!visuallyComplete && !durationComplete) {
          return;
        }
        sink.endStep(context);
      } catch (error) {
        _terminate(
          SceneCinematicRuntimeAwaitableResult.failed(
            errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
            message: 'Cinematic sink step failed: $error',
          ),
          CinematicRuntimeTermination.failed,
        );
        return;
      }

      session.stepIndex++;
      session.stepElapsed = Duration.zero;
      session.stepBegun = false;
      if (duration == null) {
        remaining = Duration.zero;
      } else {
        remaining -= applied;
      }
      _beginCurrentStepOrComplete();
      if (remaining == Duration.zero) return;
    }
  }

  bool cancel({String message = 'Cinematic playback was cancelled.'}) {
    if (_session == null) return false;
    _terminate(
      SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.cancelled,
        message: message,
      ),
      CinematicRuntimeTermination.cancelled,
    );
    return true;
  }

  void _beginCurrentStepOrComplete() {
    while (_session != null) {
      final session = _session!;
      if (session.stepIndex >= session.steps.length) {
        _terminate(
          const SceneCinematicRuntimeAwaitableResult.completed(),
          CinematicRuntimeTermination.completed,
        );
        return;
      }
      if (session.stepBegun) return;

      final context = _contextFor(session, delta: Duration.zero);
      try {
        sink.beginStep(context);
        session.stepBegun = true;
        final visuallyComplete = sink.isStepVisuallyComplete(context);
        final duration = _positiveDurationOf(context.step);
        if (!visuallyComplete && duration != Duration.zero) return;
        sink.endStep(context);
      } catch (error) {
        _terminate(
          SceneCinematicRuntimeAwaitableResult.failed(
            errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
            message: 'Cinematic sink step failed: $error',
          ),
          CinematicRuntimeTermination.failed,
        );
        return;
      }

      session.stepIndex++;
      session.stepElapsed = Duration.zero;
      session.stepBegun = false;
    }
  }

  CinematicRuntimeStepContext _contextFor(
    _CinematicRuntimeSession session, {
    required Duration delta,
  }) {
    return CinematicRuntimeStepContext(
      asset: session.asset,
      step: session.steps[session.stepIndex],
      stepIndex: session.stepIndex,
      elapsed: session.stepElapsed,
      delta: delta,
    );
  }

  void _terminate(
    SceneCinematicRuntimeAwaitableResult result,
    CinematicRuntimeTermination termination,
  ) {
    final session = _session;
    if (session == null) return;
    _session = null;
    if (sink is CinematicRuntimeAsyncRestorationSink) {
      Future.sync(
        () => (sink as CinematicRuntimeAsyncRestorationSink)
            .restoreAsync(termination),
      ).then(
        (_) {
          if (!session.completer.isCompleted) {
            session.completer.complete(result);
          }
        },
        onError: (Object error) {
          if (!session.completer.isCompleted) {
            session.completer.complete(
              SceneCinematicRuntimeAwaitableResult.failed(
                errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
                message: 'Cinematic sink restoration failed: $error',
              ),
            );
          }
        },
      );
      return;
    }
    var finalResult = result;
    try {
      sink.restore(termination);
    } catch (error) {
      finalResult = SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
        message: 'Cinematic sink restoration failed: $error',
      );
    } finally {
      if (!session.completer.isCompleted) {
        session.completer.complete(finalResult);
      }
    }
  }
}

final class _CinematicRuntimeSession {
  _CinematicRuntimeSession(this.asset)
      : steps = asset.timeline.steps
            .where((step) => step.kind != CinematicTimelineStepKind.marker)
            .toList(growable: false),
        completer = Completer<SceneCinematicRuntimeAwaitableResult>();

  final CinematicAsset asset;
  final List<CinematicTimelineStep> steps;
  final Completer<SceneCinematicRuntimeAwaitableResult> completer;
  int stepIndex = 0;
  Duration stepElapsed = Duration.zero;
  bool stepBegun = false;
}

const _supportedKinds = <CinematicTimelineStepKind>{
  CinematicTimelineStepKind.wait,
  CinematicTimelineStepKind.camera,
  CinematicTimelineStepKind.actorMove,
  CinematicTimelineStepKind.actorFace,
  CinematicTimelineStepKind.actorEmote,
  CinematicTimelineStepKind.dialogueLine,
  CinematicTimelineStepKind.fade,
  CinematicTimelineStepKind.shake,
  CinematicTimelineStepKind.sound,
  CinematicTimelineStepKind.music,
  CinematicTimelineStepKind.fx,
  CinematicTimelineStepKind.marker,
};

SceneCinematicRuntimeAwaitableResult? _preflightAsset(CinematicAsset asset) {
  final context = asset.stageContext;
  final bindings = <String, CinematicActorBinding>{};
  for (final binding in context?.actorBindings ?? const []) {
    if (bindings.containsKey(binding.actorId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
        'Actor "${binding.actorId}" has duplicate bindings.',
      );
    }
    if (binding.kind == CinematicActorBindingKind.cinematicOnly ||
        binding.kind == CinematicActorBindingKind.unbound) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedActorBinding,
        'Actor "${binding.actorId}" uses unsupported binding '
        '"${_enumLabel(binding.kind)}".',
      );
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        (binding.mapEntityId == null || binding.mapEntityId!.isEmpty)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
        'Actor "${binding.actorId}" is missing mapEntityId.',
      );
    }
    bindings[binding.actorId] = binding;
  }
  for (final actor in asset.requiredActors) {
    if (!bindings.containsKey(actor.actorId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
        'Required actor "${actor.actorId}" has no runtime binding.',
      );
    }
  }

  final targetRefs = <String>{
    for (final target in asset.movementTargets) target.targetId,
  };
  final stagePointIds = <String>{
    for (final point in context?.stagePoints ?? const []) point.id,
  };
  final targetBindings = <String, CinematicMovementTargetBinding>{};
  for (final binding in context?.movementTargetBindings ?? const []) {
    if (!targetRefs.contains(binding.targetId) ||
        targetBindings.containsKey(binding.targetId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" has an invalid binding.',
      );
    }
    if (binding.kind != CinematicMovementTargetBindingKind.mapEntity &&
        binding.kind != CinematicMovementTargetBindingKind.stagePoint) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" uses unsupported binding '
        '"${_enumLabel(binding.kind)}".',
      );
    }
    final sourceId = binding.sourceId;
    if (sourceId == null || sourceId.isEmpty) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" is missing sourceId.',
      );
    }
    if (binding.kind == CinematicMovementTargetBindingKind.stagePoint &&
        !stagePointIds.contains(sourceId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" references unknown stage point '
        '"$sourceId".',
      );
    }
    targetBindings[binding.targetId] = binding;
  }
  for (final targetId in targetRefs) {
    if (!targetBindings.containsKey(targetId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "$targetId" has no runtime binding.',
      );
    }
  }

  for (final step in asset.timeline.steps) {
    if (!_supportedKinds.contains(step.kind)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedStepKind,
        'Step "${step.id}" uses unsupported kind "${step.kind.name}".',
      );
    }
    if (step.durationMs != null && step.durationMs! < 0) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        'Step "${step.id}" has a negative duration.',
      );
    }
    if (step.kind == CinematicTimelineStepKind.wait &&
        step.durationMs == null) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        'Wait step "${step.id}" requires durationMs.',
      );
    }
    if (_requiresActor(step.kind)) {
      final actorId = step.actorId;
      if (actorId == null || !bindings.containsKey(actorId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          'Step "${step.id}" references an unavailable actor.',
        );
      }
    }
    if (step.kind == CinematicTimelineStepKind.actorMove) {
      final targetId = step.targetId;
      if (targetId == null || !targetBindings.containsKey(targetId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          'Step "${step.id}" references an unavailable movement target.',
        );
      }
    }
    if (step.kind == CinematicTimelineStepKind.dialogueLine &&
        (step.dialogueText == null || step.dialogueText!.isEmpty) &&
        (step.assetRef == null || step.assetRef!.isEmpty)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        'Dialogue line step "${step.id}" requires dialogueText or assetRef.',
      );
    }
    if (step.kind == CinematicTimelineStepKind.camera &&
        cinematicTimelineCameraModeOf(step) ==
            CinematicTimelineCameraMode.focus) {
      final focus = cinematicTimelineCameraFocusBindingOf(step);
      if (focus == null) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          'Camera focus step "${step.id}" has an invalid target.',
        );
      }
      final target = focus.target;
      if (target.kind == CinematicCameraTargetKind.actor &&
          !bindings.containsKey(target.actorId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          'Camera step "${step.id}" references an unavailable actor.',
        );
      }
      if (target.kind == CinematicCameraTargetKind.stagePoint &&
          !stagePointIds.contains(target.stagePointId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          'Camera step "${step.id}" references an unavailable stage point.',
        );
      }
    }
  }
  return null;
}

bool _requiresActor(CinematicTimelineStepKind kind) {
  return kind == CinematicTimelineStepKind.actorMove ||
      kind == CinematicTimelineStepKind.actorFace ||
      kind == CinematicTimelineStepKind.actorEmote;
}

Duration? _positiveDurationOf(CinematicTimelineStep step) {
  final milliseconds = step.durationMs;
  if (milliseconds != null) return Duration(milliseconds: milliseconds);
  if (step.kind == CinematicTimelineStepKind.sound ||
      step.kind == CinematicTimelineStepKind.music) {
    return const Duration(
      milliseconds: cinematicTimelineFallbackVisualDurationMs,
    );
  }
  return null;
}

SceneCinematicRuntimeAwaitableResult _failure(
  SceneCinematicRuntimeAwaitableErrorCode code,
  String message,
) {
  return SceneCinematicRuntimeAwaitableResult.failed(
    errorCode: code,
    message: message,
  );
}

String _enumLabel(Object value) {
  final text = value.toString();
  final separator = text.lastIndexOf('.');
  return separator < 0 ? text : text.substring(separator + 1);
}
