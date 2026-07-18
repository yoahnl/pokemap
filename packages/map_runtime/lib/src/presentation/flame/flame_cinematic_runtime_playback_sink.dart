import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';

import '../../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../../application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart';

/// Minimal visual handle used by the production Flame cinematic sink.
///
/// Positions use world-space focus points rather than component top-left
/// coordinates so player and NPC sprites can share the same runtime contract.
abstract interface class FlameCinematicRuntimeActorHandle {
  Vector2 get focusPoint;

  EntityFacing get facing;

  void setFocusPoint(Vector2 focusPoint);

  void setFacing(EntityFacing facing);
}

/// Host boundary implemented by [PlayableMapGame]'s Flame scene.
///
/// All methods are synchronous because playback is driven by the game update
/// loop. No timer or wall-clock future participates in cinematic completion.
abstract interface class FlameCinematicRuntimeHost {
  bool get isReady;

  String get activeMapId;

  Vector2 get cameraPosition;

  set cameraPosition(Vector2 value);

  Vector2? get cameraVisibleGameSize;

  set cameraVisibleGameSize(Vector2? value);

  Vector2 get sceneCenter;

  FlameCinematicRuntimeActorHandle? get playerActor;

  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId);

  Vector2? mapEntityFocusPoint(String entityId);

  Vector2 stagePointFocusPoint(CinematicStagePoint point);

  void setCinematicInputLocked(bool locked);

  void showCinematicDialogueLine(String? text);

  void setCinematicFadeOpacity(double? opacity);

  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  );
}

/// Concrete deterministic visual sink for the CinematicAsset V1 subset.
final class FlameCinematicRuntimePlaybackSink
    implements CinematicRuntimePlaybackSink {
  FlameCinematicRuntimePlaybackSink({required this.host});

  final FlameCinematicRuntimeHost host;

  _CinematicRuntimeVisualSnapshot? _snapshot;
  Map<String, FlameCinematicRuntimeActorHandle> _actors = const {};
  _FlameCinematicStepState? _stepState;
  bool _dialogueLineSignalled = false;

  bool get isAwaitingDialogueLineAdvance =>
      _stepState is _DialogueLineStepState && !_dialogueLineSignalled;

  bool signalDialogueLineComplete() {
    if (_stepState is! _DialogueLineStepState || _dialogueLineSignalled) {
      return false;
    }
    _dialogueLineSignalled = true;
    return true;
  }

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) {
    if (!host.isReady) {
      return const CinematicRuntimeSinkPreflightResult.rejected(
        message: 'The Flame cinematic runtime is not ready.',
      );
    }
    final authoredMapId = asset.mapId;
    if (authoredMapId != null && authoredMapId != host.activeMapId) {
      return CinematicRuntimeSinkPreflightResult.rejected(
        message: 'Cinematic "${asset.id}" targets map "$authoredMapId" but '
            'the active map is "${host.activeMapId}".',
      );
    }

    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      if (_resolveActor(binding) == null) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          errorCode:
              SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          message: 'Cinematic actor "${binding.actorId}" is not mounted on '
              'the active Flame map.',
        );
      }
    }

    for (final binding
        in asset.stageContext?.movementTargetBindings ?? const []) {
      if (_resolveMovementTarget(asset, binding.targetId) == null) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          errorCode:
              SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          message: 'Cinematic movement target "${binding.targetId}" is not '
              'available on the active Flame map.',
        );
      }
    }

    for (final step in asset.timeline.steps) {
      final failure = _preflightStep(asset, step);
      if (failure != null) return failure;
    }
    return const CinematicRuntimeSinkPreflightResult.ready();
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    if (_snapshot == null) {
      _beginSession(context.asset);
    }
    if (_stepState != null) {
      throw StateError('A cinematic visual step is already active.');
    }

    final step = context.step;
    switch (step.kind) {
      case CinematicTimelineStepKind.wait:
        _stepState = const _PassiveStepState();
      case CinematicTimelineStepKind.camera:
        _beginCameraStep(context);
      case CinematicTimelineStepKind.actorMove:
        _beginActorMoveStep(context);
      case CinematicTimelineStepKind.actorFace:
        final actor = _requireActor(step.actorId);
        actor.setFacing(_entityFacingOf(step));
        _stepState = const _ImmediateStepState();
      case CinematicTimelineStepKind.actorEmote:
        final actor = _requireActor(step.actorId);
        final emoteId = cinematicTimelineActorEmoteEmoteIdOf(step)!;
        host.showCinematicActorEmote(actor, emoteId);
        _stepState = _ActorEmoteStepState(actor);
      case CinematicTimelineStepKind.dialogueLine:
        host.showCinematicDialogueLine(step.dialogueText);
        _dialogueLineSignalled = false;
        _stepState = const _DialogueLineStepState();
      case CinematicTimelineStepKind.fade:
        final fadeOut = step.metadata[cinematicTimelineFadeModeMetadataKey] ==
            CinematicTimelineFadeMode.fadeOut.name;
        host.setCinematicFadeOpacity(fadeOut ? 0 : 1);
        _stepState = _FadeStepState(fadeOut: fadeOut);
      case CinematicTimelineStepKind.shake:
        _stepState = _ShakeStepState(host.cameraPosition.clone());
      case CinematicTimelineStepKind.sound:
      case CinematicTimelineStepKind.music:
      case CinematicTimelineStepKind.fx:
      case CinematicTimelineStepKind.marker:
        throw StateError('Unsupported cinematic kind "${step.kind.name}".');
    }
  }

  @override
  void updateStep(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state == null) {
      throw StateError('No cinematic visual step is active.');
    }
    final progress = _progressOf(context);
    switch (state) {
      case _CameraStepState():
        _applyCameraState(state, progress);
      case _ActorMoveStepState():
        _applyActorMoveState(state, progress);
      case _FadeStepState():
        host.setCinematicFadeOpacity(
          state.fadeOut ? progress : 1 - progress,
        );
      case _ShakeStepState():
        final envelope = math.sin(progress * math.pi);
        final offset = math.sin(progress * math.pi * 3) * 6 * envelope;
        host.cameraPosition = state.basePosition + Vector2(offset, 0);
      case _PassiveStepState():
      case _ImmediateStepState():
      case _ActorEmoteStepState():
      case _DialogueLineStepState():
        break;
    }
  }

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state is _ImmediateStepState) return true;
    if (state is _DialogueLineStepState) return _dialogueLineSignalled;
    if ((state is _CameraStepState || state is _ActorMoveStepState) &&
        context.step.durationMs == null) {
      return true;
    }
    return false;
  }

  @override
  void endStep(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state == null) return;
    switch (state) {
      case _CameraStepState():
        _applyCameraState(state, 1);
      case _ActorMoveStepState():
        _applyActorMoveState(state, 1);
      case _FadeStepState():
        host.setCinematicFadeOpacity(state.fadeOut ? 1 : 0);
      case _ShakeStepState():
        host.cameraPosition = state.basePosition.clone();
      case _ActorEmoteStepState():
        host.showCinematicActorEmote(null, null);
      case _DialogueLineStepState():
        host.showCinematicDialogueLine(null);
      case _PassiveStepState():
      case _ImmediateStepState():
        break;
    }
    _stepState = null;
    _dialogueLineSignalled = false;
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    final snapshot = _snapshot;
    Object? firstError;
    StackTrace? firstStackTrace;

    void attempt(void Function() operation) {
      try {
        operation();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    attempt(() => host.showCinematicDialogueLine(null));
    attempt(() => host.showCinematicActorEmote(null, null));
    attempt(() => host.setCinematicFadeOpacity(null));
    if (snapshot != null) {
      for (final actorSnapshot in snapshot.actors.values) {
        attempt(() => actorSnapshot.restore());
      }
      attempt(() => host.cameraPosition = snapshot.cameraPosition.clone());
      attempt(
        () => host.cameraVisibleGameSize =
            snapshot.cameraVisibleGameSize?.clone(),
      );
    }
    attempt(() => host.setCinematicInputLocked(false));

    _snapshot = null;
    _actors = const {};
    _stepState = null;
    _dialogueLineSignalled = false;

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  CinematicRuntimeSinkPreflightResult? _preflightStep(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    CinematicRuntimeSinkPreflightResult invalid(String message) {
      return CinematicRuntimeSinkPreflightResult.rejected(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        message: 'Step "${step.id}" $message',
      );
    }

    switch (step.kind) {
      case CinematicTimelineStepKind.wait:
      case CinematicTimelineStepKind.dialogueLine:
        return null;
      case CinematicTimelineStepKind.camera:
        final mode = cinematicTimelineCameraModeOf(step);
        if (mode == null) return invalid('has no supported camera mode.');
        if (mode == CinematicTimelineCameraMode.hold &&
            !_hasPositiveDuration(step)) {
          return invalid('requires a positive duration for camera hold.');
        }
        if (mode == CinematicTimelineCameraMode.focus) {
          final focus = cinematicTimelineCameraFocusBindingOf(step);
          if (focus == null || _resolveCameraFocus(asset, focus) == null) {
            return CinematicRuntimeSinkPreflightResult.rejected(
              errorCode: SceneCinematicRuntimeAwaitableErrorCode
                  .invalidTargetReference,
              message: 'Step "${step.id}" has an unavailable camera target.',
            );
          }
        }
        return null;
      case CinematicTimelineStepKind.actorMove:
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive movement duration.');
        }
        if (cinematicTimelineActorMovementModeOf(step) == null ||
            cinematicTimelineActorPathModeOf(step) == null) {
          return invalid('has incomplete movement metadata.');
        }
        if (_resolveActorById(asset, step.actorId) == null) {
          return CinematicRuntimeSinkPreflightResult.rejected(
            errorCode:
                SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
            message: 'Step "${step.id}" has an unavailable actor.',
          );
        }
        if (_movementRoute(asset, step) == null) {
          return CinematicRuntimeSinkPreflightResult.rejected(
            errorCode:
                SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
            message: 'Step "${step.id}" has an unavailable movement route.',
          );
        }
        return null;
      case CinematicTimelineStepKind.actorFace:
        if (cinematicTimelineActorFacingDirectionOf(step) == null) {
          return invalid('has no facing direction.');
        }
        return null;
      case CinematicTimelineStepKind.actorEmote:
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive emote duration.');
        }
        if (cinematicTimelineActorEmoteEmoteIdOf(step) == null) {
          return invalid('has no emote id.');
        }
        return null;
      case CinematicTimelineStepKind.fade:
        final fadeMode = step.metadata[cinematicTimelineFadeModeMetadataKey];
        if (fadeMode != CinematicTimelineFadeMode.fadeIn.name &&
            fadeMode != CinematicTimelineFadeMode.fadeOut.name) {
          return invalid('has no supported fade mode.');
        }
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive fade duration.');
        }
        return null;
      case CinematicTimelineStepKind.shake:
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive shake duration.');
        }
        return null;
      case CinematicTimelineStepKind.sound:
      case CinematicTimelineStepKind.music:
      case CinematicTimelineStepKind.fx:
      case CinematicTimelineStepKind.marker:
        return invalid('uses an unsupported V1 kind.');
    }
  }

  void _beginSession(CinematicAsset asset) {
    final actors = <String, FlameCinematicRuntimeActorHandle>{};
    final actorSnapshots = <String, _ActorVisualSnapshot>{};
    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      final actor = _resolveActor(binding);
      if (actor == null) {
        throw StateError('Cinematic actor "${binding.actorId}" disappeared.');
      }
      actors[binding.actorId] = actor;
      actorSnapshots[binding.actorId] = _ActorVisualSnapshot(
        actor: actor,
        focusPoint: actor.focusPoint.clone(),
        facing: actor.facing,
      );
    }
    _actors =
        Map<String, FlameCinematicRuntimeActorHandle>.unmodifiable(actors);
    _snapshot = _CinematicRuntimeVisualSnapshot(
      cameraPosition: host.cameraPosition.clone(),
      cameraVisibleGameSize: host.cameraVisibleGameSize?.clone(),
      actors: Map<String, _ActorVisualSnapshot>.unmodifiable(actorSnapshots),
    );
    host.setCinematicInputLocked(true);
  }

  void _beginCameraStep(CinematicRuntimeStepContext context) {
    final mode = cinematicTimelineCameraModeOf(context.step)!;
    final fromPosition = host.cameraPosition.clone();
    final fromSize = host.cameraVisibleGameSize?.clone();
    var targetPosition = fromPosition.clone();
    var targetSize = fromSize?.clone();
    switch (mode) {
      case CinematicTimelineCameraMode.hold:
        break;
      case CinematicTimelineCameraMode.reset:
        final snapshot = _snapshot!;
        targetPosition = snapshot.cameraPosition.clone();
        targetSize = snapshot.cameraVisibleGameSize?.clone();
      case CinematicTimelineCameraMode.focus:
        final focus = cinematicTimelineCameraFocusBindingOf(context.step)!;
        targetPosition = _resolveCameraFocus(context.asset, focus)!.clone();
        final baseSize = _snapshot!.cameraVisibleGameSize ?? fromSize;
        if (baseSize != null) {
          targetSize = baseSize * _zoomFactor(focus.zoomPreset);
        }
    }
    final state = _CameraStepState(
      fromPosition: fromPosition,
      targetPosition: targetPosition,
      fromSize: fromSize,
      targetSize: targetSize,
    );
    _stepState = state;
    if (context.step.durationMs == null) _applyCameraState(state, 1);
  }

  void _beginActorMoveStep(CinematicRuntimeStepContext context) {
    final actor = _requireActor(context.step.actorId);
    final route = _movementRoute(context.asset, context.step)!;
    final points = <Vector2>[actor.focusPoint.clone(), ...route];
    _stepState = _ActorMoveStepState(actor: actor, points: points);
  }

  void _applyCameraState(_CameraStepState state, double progress) {
    host.cameraPosition =
        _lerp(state.fromPosition, state.targetPosition, progress);
    final fromSize = state.fromSize;
    final targetSize = state.targetSize;
    if (fromSize != null && targetSize != null) {
      host.cameraVisibleGameSize = _lerp(fromSize, targetSize, progress);
    } else if (progress >= 1) {
      host.cameraVisibleGameSize = targetSize?.clone();
    }
  }

  void _applyActorMoveState(_ActorMoveStepState state, double progress) {
    final points = state.points;
    if (points.length < 2) return;
    final scaled = progress.clamp(0.0, 1.0) * (points.length - 1);
    final segment = math.min(points.length - 2, scaled.floor());
    final localProgress = scaled - segment;
    final from = points[segment];
    final to = points[segment + 1];
    state.actor.setFacing(_facingBetween(from, to, state.actor.facing));
    state.actor.setFocusPoint(_lerp(from, to, localProgress));
  }

  FlameCinematicRuntimeActorHandle? _resolveActor(
    CinematicActorBinding binding,
  ) {
    final mapEntityId = binding.mapEntityId;
    return switch (binding.kind) {
      CinematicActorBindingKind.player => host.playerActor,
      CinematicActorBindingKind.mapEntity =>
        mapEntityId == null ? null : host.mapEntityActor(mapEntityId),
      CinematicActorBindingKind.cinematicOnly ||
      CinematicActorBindingKind.unbound =>
        null,
    };
  }

  FlameCinematicRuntimeActorHandle? _resolveActorById(
    CinematicAsset asset,
    String? actorId,
  ) {
    if (actorId == null) return null;
    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      if (binding.actorId == actorId) return _resolveActor(binding);
    }
    return null;
  }

  FlameCinematicRuntimeActorHandle _requireActor(String? actorId) {
    final actor = actorId == null ? null : _actors[actorId];
    if (actor == null) {
      throw StateError('Cinematic actor "$actorId" is unavailable.');
    }
    return actor;
  }

  Vector2? _resolveMovementTarget(CinematicAsset asset, String targetId) {
    final context = asset.stageContext;
    if (context == null) return null;
    CinematicMovementTargetBinding? binding;
    for (final candidate in context.movementTargetBindings) {
      if (candidate.targetId == targetId) {
        binding = candidate;
        break;
      }
    }
    final sourceId = binding?.sourceId;
    if (binding == null || sourceId == null) return null;
    switch (binding.kind) {
      case CinematicMovementTargetBindingKind.mapEntity:
        return host.mapEntityFocusPoint(sourceId);
      case CinematicMovementTargetBindingKind.stagePoint:
        for (final point in context.stagePoints) {
          if (point.id == sourceId) return host.stagePointFocusPoint(point);
        }
        return null;
      case CinematicMovementTargetBindingKind.abstractPoint:
      case CinematicMovementTargetBindingKind.mapEvent:
        return null;
    }
  }

  List<Vector2>? _movementRoute(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final targetId = step.targetId;
    if (targetId == null) return null;
    final target = _resolveMovementTarget(asset, targetId);
    if (target == null) return null;
    if (cinematicTimelineActorPathModeOf(step) !=
        CinematicTimelineActorPathMode.manual) {
      return <Vector2>[target.clone()];
    }
    final context = asset.stageContext!;
    CinematicManualPath? manualPath;
    for (final candidate in context.manualPaths) {
      if (candidate.ownerActorMoveStepId == step.id) {
        manualPath = candidate;
        break;
      }
    }
    if (manualPath == null) return null;
    final stagePoints = <String, CinematicStagePoint>{
      for (final point in context.stagePoints) point.id: point,
    };
    final route = <Vector2>[];
    for (final pointId in manualPath.waypointStagePointIds) {
      final point = stagePoints[pointId];
      if (point == null) return null;
      route.add(host.stagePointFocusPoint(point));
    }
    if (route.isEmpty || route.last != target) route.add(target.clone());
    return route;
  }

  Vector2? _resolveCameraFocus(
    CinematicAsset asset,
    CinematicTimelineCameraFocusBinding focus,
  ) {
    return switch (focus.target.kind) {
      CinematicCameraTargetKind.sceneCenter => host.sceneCenter,
      CinematicCameraTargetKind.actor =>
        _resolveActorById(asset, focus.target.actorId)?.focusPoint,
      CinematicCameraTargetKind.stagePoint => _stagePointById(
          asset,
          focus.target.stagePointId,
        ),
    };
  }

  Vector2? _stagePointById(CinematicAsset asset, String? pointId) {
    if (pointId == null) return null;
    for (final point in asset.stageContext?.stagePoints ?? const []) {
      if (point.id == pointId) return host.stagePointFocusPoint(point);
    }
    return null;
  }
}

double _progressOf(CinematicRuntimeStepContext context) {
  final durationMs = context.step.durationMs;
  if (durationMs == null || durationMs <= 0) return 1;
  return (context.elapsed.inMicroseconds /
          (durationMs * Duration.microsecondsPerMillisecond))
      .clamp(0.0, 1.0);
}

bool _hasPositiveDuration(CinematicTimelineStep step) =>
    (step.durationMs ?? 0) > 0;

double _zoomFactor(CinematicCameraZoomPreset preset) {
  return switch (preset) {
    CinematicCameraZoomPreset.wide => 1,
    CinematicCameraZoomPreset.medium => 0.8,
    CinematicCameraZoomPreset.close => 0.6,
  };
}

EntityFacing _entityFacingOf(CinematicTimelineStep step) {
  return switch (cinematicTimelineActorFacingDirectionOf(step)!) {
    CinematicTimelineActorFacingDirection.up => EntityFacing.north,
    CinematicTimelineActorFacingDirection.down => EntityFacing.south,
    CinematicTimelineActorFacingDirection.left => EntityFacing.west,
    CinematicTimelineActorFacingDirection.right => EntityFacing.east,
  };
}

EntityFacing _facingBetween(
  Vector2 from,
  Vector2 to,
  EntityFacing fallback,
) {
  final dx = to.x - from.x;
  final dy = to.y - from.y;
  if (dx.abs() >= dy.abs() && dx != 0) {
    return dx > 0 ? EntityFacing.east : EntityFacing.west;
  }
  if (dy != 0) return dy > 0 ? EntityFacing.south : EntityFacing.north;
  return fallback;
}

Vector2 _lerp(Vector2 from, Vector2 to, double progress) {
  final t = progress.clamp(0.0, 1.0);
  return Vector2(
    from.x + (to.x - from.x) * t,
    from.y + (to.y - from.y) * t,
  );
}

final class _CinematicRuntimeVisualSnapshot {
  const _CinematicRuntimeVisualSnapshot({
    required this.cameraPosition,
    required this.cameraVisibleGameSize,
    required this.actors,
  });

  final Vector2 cameraPosition;
  final Vector2? cameraVisibleGameSize;
  final Map<String, _ActorVisualSnapshot> actors;
}

final class _ActorVisualSnapshot {
  const _ActorVisualSnapshot({
    required this.actor,
    required this.focusPoint,
    required this.facing,
  });

  final FlameCinematicRuntimeActorHandle actor;
  final Vector2 focusPoint;
  final EntityFacing facing;

  void restore() {
    actor.setFocusPoint(focusPoint.clone());
    actor.setFacing(facing);
  }
}

sealed class _FlameCinematicStepState {
  const _FlameCinematicStepState();
}

final class _PassiveStepState extends _FlameCinematicStepState {
  const _PassiveStepState();
}

final class _ImmediateStepState extends _FlameCinematicStepState {
  const _ImmediateStepState();
}

final class _CameraStepState extends _FlameCinematicStepState {
  const _CameraStepState({
    required this.fromPosition,
    required this.targetPosition,
    required this.fromSize,
    required this.targetSize,
  });

  final Vector2 fromPosition;
  final Vector2 targetPosition;
  final Vector2? fromSize;
  final Vector2? targetSize;
}

final class _ActorMoveStepState extends _FlameCinematicStepState {
  const _ActorMoveStepState({required this.actor, required this.points});

  final FlameCinematicRuntimeActorHandle actor;
  final List<Vector2> points;
}

final class _ActorEmoteStepState extends _FlameCinematicStepState {
  const _ActorEmoteStepState(this.actor);

  final FlameCinematicRuntimeActorHandle actor;
}

final class _DialogueLineStepState extends _FlameCinematicStepState {
  const _DialogueLineStepState();
}

final class _FadeStepState extends _FlameCinematicStepState {
  const _FadeStepState({required this.fadeOut});

  final bool fadeOut;
}

final class _ShakeStepState extends _FlameCinematicStepState {
  const _ShakeStepState(this.basePosition);

  final Vector2 basePosition;
}
