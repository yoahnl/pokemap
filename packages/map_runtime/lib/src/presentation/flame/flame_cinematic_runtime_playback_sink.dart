import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';

import '../../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../../application/scene_runtime/cinematic_media_playback_port.dart';
import '../../application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart';
import '../../application/character_custom_animation_runtime_controller.dart';

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

abstract interface class FlameCinematicCharacterAnimationActorHandle
    implements
        FlameCinematicRuntimeActorHandle,
        CharacterCustomAnimationRuntimeActor {}

/// Host boundary implemented by [PlayableMapGame]'s Flame scene.
///
/// Visual methods are update-driven. Referenced Dialogue assets are awaitable
/// because their completion depends on the player's choices.
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

  Future<void> playCinematicDialogueAsset(String dialogueId);

  void cancelCinematicDialogueAsset();

  void setCinematicFadeOpacity(double? opacity);

  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  );
}

/// Concrete deterministic visual sink for the CinematicAsset V1 subset.
final class FlameCinematicRuntimePlaybackSink
    implements
        CinematicRuntimePlaybackSink,
        CinematicRuntimeStepCompletionPolicy,
        CinematicRuntimeAsyncRestorationSink {
  FlameCinematicRuntimePlaybackSink({
    required this.host,
    this.mediaPlaybackPort,
    this.dialogues = const [],
    this.mediaAssets = const [],
    this.project,
  });

  final FlameCinematicRuntimeHost host;
  final CinematicRuntimeMediaPlaybackPort? mediaPlaybackPort;
  final List<ProjectDialogueEntry> dialogues;
  final List<CinematicMediaAsset> mediaAssets;
  final ProjectManifest? project;

  _CinematicRuntimeVisualSnapshot? _snapshot;
  Map<String, FlameCinematicRuntimeActorHandle> _actors = const {};
  _FlameCinematicStepState? _stepState;
  bool _dialogueLineSignalled = false;
  Future<CinematicMediaPlaybackCheckpoint>? _mediaCheckpointFuture;
  Future<void>? _pendingMediaOperation;
  CharacterCustomAnimationRuntimeController? _characterAnimationController;

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
    final shared = preflightCinematicPlayback(
      cinematic: asset,
      dialogues: dialogues,
      mediaAssets: mediaAssets,
      availableMapIds: [host.activeMapId],
      activeMapId: host.activeMapId,
      mode: CinematicPlaybackPreflightMode.runtime,
    );
    if (!shared.isReady) {
      final issue = shared.issues.first;
      return CinematicRuntimeSinkPreflightResult.rejected(
        errorCode: _runtimeErrorCodeFor(issue.kind),
        message: issue.message,
      );
    }
    if (asset.timeline.steps.any(
          (step) => cinematicExpectedMediaKind(step.kind) != null,
        ) &&
        mediaPlaybackPort == null) {
      return const CinematicRuntimeSinkPreflightResult.rejected(
        message: 'The cinematic media playback adapter is unavailable.',
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
      case CinematicTimelineStepKind.actorAnimation:
        _beginCharacterAnimationStep(step);
      case CinematicTimelineStepKind.dialogueLine:
        final dialogueId = step.assetRef;
        if (dialogueId == null) {
          host.showCinematicDialogueLine(step.dialogueText);
          _dialogueLineSignalled = false;
          _stepState = const _DialogueLineStepState();
        } else {
          final state = _AsyncDialogueStepState();
          _stepState = state;
          host.playCinematicDialogueAsset(dialogueId).then(
            (_) {
              state.completed = true;
            },
            onError: (Object error, StackTrace stackTrace) {
              state.error = error;
              state.stackTrace = stackTrace;
            },
          );
        }
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
        _beginMediaStep(step);
      case CinematicTimelineStepKind.marker:
        throw StateError('Editorial marker reached the runtime sink.');
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
      case _AsyncStepState():
        if (state is _AsyncCharacterAnimationStepState) {
          final controller = _characterAnimationController;
          controller?.update(context.delta);
          final result = controller?.lastResultFor(state.actorId);
          if (result != null) {
            _applyCharacterAnimationResult(state, result);
          }
        }
        final error = state.error;
        if (error != null) {
          Error.throwWithStackTrace(
              error, state.stackTrace ?? StackTrace.current);
        }
    }
  }

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state is _ImmediateStepState) return true;
    if (state is _DialogueLineStepState) return _dialogueLineSignalled;
    if (state is _AsyncStepState) {
      return state.completed;
    }
    if ((state is _CameraStepState || state is _ActorMoveStepState) &&
        context.step.durationMs == null) {
      return true;
    }
    return false;
  }

  @override
  bool requiresSinkCompletion(CinematicRuntimeStepContext context) =>
      _stepState is _AsyncStepState;

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
      case _AsyncDialogueStepState():
      case _AsyncCharacterAnimationStepState():
        break;
      case _AsyncMediaStepState():
        final command = cinematicMediaEndCommandForStep(context.step);
        if (command != null) _queueMediaCommand(command);
      case _PassiveStepState():
      case _ImmediateStepState():
        break;
    }
    _stepState = null;
    _dialogueLineSignalled = false;
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    _restoreVisualState();
    final checkpointFuture = _mediaCheckpointFuture;
    final pendingOperation = _pendingMediaOperation;
    final port = mediaPlaybackPort;
    _mediaCheckpointFuture = null;
    _pendingMediaOperation = null;
    if (checkpointFuture != null && port != null) {
      unawaited(() async {
        try {
          await pendingOperation;
        } catch (_) {
          // Restoration still has priority over the original command failure.
        }
        await port.restore(await checkpointFuture);
      }());
    }
  }

  @override
  Future<void> restoreAsync(CinematicRuntimeTermination termination) async {
    final checkpointFuture = _mediaCheckpointFuture;
    final pendingOperation = _pendingMediaOperation;
    final port = mediaPlaybackPort;
    Object? firstError;
    StackTrace? firstStackTrace;
    try {
      _restoreVisualState();
    } catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }
    if (checkpointFuture != null && port != null) {
      try {
        await pendingOperation;
      } catch (_) {
        // The command error is already reported by the active step. Continue
        // with rollback so no loop or FX survives it.
      }
      try {
        await port.restore(await checkpointFuture);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    _mediaCheckpointFuture = null;
    _pendingMediaOperation = null;
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  void _restoreVisualState() {
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
    attempt(host.cancelCinematicDialogueAsset);
    attempt(() => host.showCinematicActorEmote(null, null));
    attempt(() => host.setCinematicFadeOpacity(null));
    attempt(() => _characterAnimationController?.dispose());
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
    _characterAnimationController = null;
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
      case CinematicTimelineStepKind.actorAnimation:
        final command = cinematicCharacterCustomAnimationCommandOf(step);
        if (command == null) {
          return invalid('has invalid character animation metadata.');
        }
        final actor = _resolveActorById(asset, step.actorId);
        if (actor is! FlameCinematicCharacterAnimationActorHandle) {
          return invalid('targets an actor without animation capability.');
        }
        if (project == null) {
          return invalid('has no Character Studio runtime catalog.');
        }
        return _preflightCharacterAnimation(actor, command, invalid);
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
        return null;
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
    final port = mediaPlaybackPort;
    _mediaCheckpointFuture = port?.captureCheckpoint();
    host.setCinematicInputLocked(true);
  }

  void _beginMediaStep(CinematicTimelineStep step) {
    final command = cinematicMediaCommandForStep(
      step,
      mediaAssets: mediaAssets,
    );
    if (command == null) {
      throw StateError('Cinematic media step "${step.id}" is unsupported.');
    }
    final state = _AsyncMediaStepState();
    _stepState = state;
    _queueMediaCommand(command).then(
      (_) {
        state.completed = true;
      },
      onError: (Object error, StackTrace stackTrace) {
        state.error = error;
        state.stackTrace = stackTrace;
      },
    );
  }

  void _beginCharacterAnimationStep(CinematicTimelineStep step) {
    final command = cinematicCharacterCustomAnimationCommandOf(step);
    if (command == null) {
      throw StateError('Invalid character animation step "${step.id}".');
    }
    final controller = _characterAnimationController ??=
        CharacterCustomAnimationRuntimeController(
      manifest: project!,
      actorLookup: (actorId) {
        final actor = _actors[actorId];
        return actor is FlameCinematicCharacterAnimationActorHandle
            ? actor
            : null;
      },
    );
    final state = _AsyncCharacterAnimationStepState(command.actorId);
    _stepState = state;
    controller.play(command).then(
      (result) => _applyCharacterAnimationResult(state, result),
      onError: (Object error, StackTrace stackTrace) {
        state.error = error;
        state.stackTrace = stackTrace;
      },
    );
  }

  CinematicRuntimeSinkPreflightResult? _preflightCharacterAnimation(
    FlameCinematicCharacterAnimationActorHandle actor,
    CharacterCustomAnimationRuntimeCommand command,
    CinematicRuntimeSinkPreflightResult Function(String message) invalid,
  ) {
    try {
      final definitions =
          project!.characterStudioCatalog.customAnimationDefinitions;
      CharacterCustomAnimationDefinition? definition;
      for (final candidate in definitions) {
        if (candidate.id == command.definitionId) {
          definition = candidate;
          break;
        }
      }
      if (definition == null) {
        return invalid('references an unknown definition.');
      }
      if (definition.mode == CharacterCustomAnimationMode.single &&
          command.direction != null) {
        return invalid('sets a direction on a single animation.');
      }
      if (definition.mode == CharacterCustomAnimationMode.directional &&
          command.direction == null) {
        return invalid('requires an animation direction.');
      }
      CharacterCustomAnimationClip? clip;
      for (final candidate in actor.character.customAnimations) {
        if (candidate.definitionId != command.definitionId) continue;
        if (definition.mode == CharacterCustomAnimationMode.single &&
            candidate.direction == null) {
          clip = candidate;
          break;
        }
        if (definition.mode == CharacterCustomAnimationMode.directional &&
            candidate.direction == command.direction) {
          clip = candidate;
          break;
        }
      }
      if (clip == null ||
          clip.frames.isEmpty ||
          !actor.canPlayCustomAnimation(clip)) {
        return invalid('has no playable character animation clip.');
      }
      return null;
    } on Object {
      return invalid('cannot resolve its character animation actor.');
    }
  }

  void _applyCharacterAnimationResult(
    _AsyncCharacterAnimationStepState state,
    CharacterCustomAnimationRuntimeResult result,
  ) {
    if (!identical(_stepState, state) || state.completed) return;
    switch (result.status) {
      case CharacterCustomAnimationRuntimeStatus.completed:
      case CharacterCustomAnimationRuntimeStatus.fallbackApplied:
        state.completed = true;
      case CharacterCustomAnimationRuntimeStatus.interrupted:
      case CharacterCustomAnimationRuntimeStatus.failed:
        state.error = StateError(
          'Character animation ${result.definitionId} ended with '
          '${result.status.name}: ${result.diagnosticCode?.name ?? 'unknown'}.',
        );
        state.stackTrace = StackTrace.current;
    }
  }

  Future<void> _queueMediaCommand(CinematicMediaPlaybackCommand command) {
    final port = mediaPlaybackPort;
    final checkpoint = _mediaCheckpointFuture;
    if (port == null || checkpoint == null) {
      return Future<void>.error(
        StateError('Cinematic media playback is not initialized.'),
      );
    }
    final previous = _pendingMediaOperation;
    final operation = () async {
      if (previous != null) await previous;
      await checkpoint;
      await port.execute(command);
    }();
    _pendingMediaOperation = operation;
    return operation;
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

SceneCinematicRuntimeAwaitableErrorCode _runtimeErrorCodeFor(
  CinematicPlaybackPreflightIssueKind kind,
) =>
    switch (kind) {
      CinematicPlaybackPreflightIssueKind.invalidActorReference =>
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      CinematicPlaybackPreflightIssueKind.unsupportedActorBinding =>
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedActorBinding,
      CinematicPlaybackPreflightIssueKind.invalidMapReference =>
        SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
      CinematicPlaybackPreflightIssueKind.invalidTargetReference =>
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
      CinematicPlaybackPreflightIssueKind.invalidStep ||
      CinematicPlaybackPreflightIssueKind.missingDialogue ||
      CinematicPlaybackPreflightIssueKind.missingMedia ||
      CinematicPlaybackPreflightIssueKind.mediaTypeMismatch =>
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
    };

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

sealed class _AsyncStepState extends _FlameCinematicStepState {
  _AsyncStepState();

  bool completed = false;
  Object? error;
  StackTrace? stackTrace;
}

final class _AsyncDialogueStepState extends _AsyncStepState {}

final class _AsyncMediaStepState extends _AsyncStepState {}

final class _AsyncCharacterAnimationStepState extends _AsyncStepState {
  _AsyncCharacterAnimationStepState(this.actorId);

  final String actorId;
}

final class _FadeStepState extends _FlameCinematicStepState {
  const _FadeStepState({required this.fadeOut});

  final bool fadeOut;
}

final class _ShakeStepState extends _FlameCinematicStepState {
  const _ShakeStepState(this.basePosition);

  final Vector2 basePosition;
}
