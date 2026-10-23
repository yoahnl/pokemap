import 'dart:async';

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

  /// Encombrement visuel du sprite, en unités monde.
  ///
  /// BETA-TRN-001 : une emote se place et se dimensionne PAR RAPPORT au
  /// personnage. Sans cette taille, l'overlay ne pouvait que deviner — il
  /// décalait de 22 unités depuis le CENTRE de l'acteur, ce qui posait la bulle
  /// sur la tête au lieu de la mettre au-dessus.
  Vector2 get visualSize;

  EntityFacing get facing;

  void setFocusPoint(Vector2 focusPoint);

  void setFacing(EntityFacing facing);
}

abstract interface class FlameCinematicMotionActorHandle
    implements FlameCinematicRuntimeActorHandle {
  void setMotion(EntityFacing facing, CharacterAnimationState state);
}

abstract interface class FlameCinematicJumpActorHandle
    implements FlameCinematicRuntimeActorHandle {
  void setJumpLift(double lift);
}

final class FlameCinematicActorPose {
  const FlameCinematicActorPose({
    required this.focusX,
    required this.focusY,
    required this.facing,
  });

  final double focusX, focusY;
  final EntityFacing facing;
}

abstract interface class FlameCinematicPoseRuntimeHost {
  Object get cinematicActivationToken;

  void validateCinematicActorPoses(
      Map<CinematicActorBinding, FlameCinematicActorPose> poses);

  void commitCinematicActorPoses(
      Map<CinematicActorBinding, FlameCinematicActorPose> poses);
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
        CinematicRuntimeGroupPlaybackSink,
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
  Vector2? _playbackCameraPosition;
  Vector2? _playbackVisibleGameSize;
  Map<String, FlameCinematicRuntimeActorHandle> _actors = const {};
  String? _selectedStepId;
  final _stepStates = <String, _FlameCinematicStepState>{};
  final _animationControllers = <String, CharacterCustomAnimationRuntimeController>{};
  Map<String, FlameCinematicActorPose> _groupStartPoses = const {};
  Map<CinematicActorBinding, FlameCinematicActorPose> _groupFinalPoses = const {};
  _FlameCinematicStepState? get _stepState => _stepStates[_selectedStepId];
  set _stepState(_FlameCinematicStepState? state) {
    if (state == null) { _stepStates.remove(_selectedStepId); }
    else { _stepStates[_selectedStepId!] = state; }
  }
  bool _dialogueLineSignalled = false;
  Future<CinematicMediaPlaybackCheckpoint>? _mediaCheckpointFuture;
  Future<void>? _pendingMediaOperation;
  final _pendingMediaByChannel = <String?, Future<void>>{};
  CharacterCustomAnimationRuntimeController? get _characterAnimationController =>
      _animationControllers[_selectedStepId];
  set _characterAnimationController(CharacterCustomAnimationRuntimeController? value) {
    if (value == null) { _animationControllers.remove(_selectedStepId); }
    else { _animationControllers[_selectedStepId!] = value; }
  }

  bool get isAwaitingDialogueLineAdvance =>
      _stepStates.values.any((state) => state is _DialogueLineStepState) && !_dialogueLineSignalled;

  bool signalDialogueLineComplete() {
    if (!isAwaitingDialogueLineAdvance) {
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

    for (final placement in asset.stageContext?.initialPlacements ?? const <CinematicActorInitialPlacement>[]) {
      if (placement.kind != CinematicActorInitialPlacementKind.unset &&
          _initialPlacement(asset, placement) == null) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          errorCode: SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          message: 'Initial placement for "${placement.actorId}" is unavailable.',
        );
      }
    }

    if (asset.stageContext?.stagePoints.any(
          (point) => point.relativeToActorId != null,
        ) ??
        false) {
      final poseHost = host;
      if (poseHost is! FlameCinematicPoseRuntimeHost) {
        return const CinematicRuntimeSinkPreflightResult.rejected(
          message: 'Actor-relative cinematic paths require pose validation.',
        );
      }
      try {
        for (final step in asset.timeline.steps.where(
          (step) =>
              step.kind == CinematicTimelineStepKind.actorMove ||
              step.kind == CinematicTimelineStepKind.actorJump,
        )) {
          final binding = asset.stageContext!.actorBindings
              .where((binding) => binding.actorId == step.actorId)
              .firstOrNull;
          final route = _movementRoute(asset, step);
          if (binding == null || route == null) {
            throw StateError(
              'Actor-relative path has no mounted actor or destination.',
            );
          }
          for (final point in route) {
            (poseHost as FlameCinematicPoseRuntimeHost)
                .validateCinematicActorPoses({
                  binding: FlameCinematicActorPose(
                    focusX: point.x,
                    focusY: point.y,
                    facing: _resolveActor(binding)!.facing,
                  ),
                });
          }
        }
      } catch (error) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          message: 'Actor-relative cinematic path is invalid: $error',
        );
      }
    }

    for (final step in asset.timeline.steps) {
      final failure = _preflightStep(asset, step);
      if (failure != null) return failure;
    }
    if ((asset.actorCompletionPolicy == CinematicActorCompletionPolicy.keepFinal ||
            asset.timeline.steps.any((step) => step.kind == CinematicTimelineStepKind.actorJump)) &&
        (asset.stageContext?.actorBindings.isNotEmpty ?? false)) {
      final poseHost = host;
      if (poseHost is! FlameCinematicPoseRuntimeHost) {
        return const CinematicRuntimeSinkPreflightResult.rejected(
          message: 'The runtime cannot persist cinematic actor poses.',
        );
      }
      try {
        (poseHost as FlameCinematicPoseRuntimeHost).validateCinematicActorPoses(_predictedActorPoses(asset));
      } catch (error) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          message: 'Cinematic final actor pose is invalid: $error',
        );
      }
    }
    return const CinematicRuntimeSinkPreflightResult.ready();
  }

  @override
  void beginGroup(List<CinematicRuntimeStepContext> contexts) {
    if (contexts.isEmpty) return;
    if (_snapshot == null) _beginSession(contexts.first.asset);
    _groupStartPoses = {for (final entry in _actors.entries)
      entry.key: FlameCinematicActorPose(focusX: entry.value.focusPoint.x,
          focusY: entry.value.focusPoint.y, facing: entry.value.facing)};
    _groupFinalPoses = _predictedActorPoses(contexts.first.asset,
        steps: contexts.map((context) => context.step).toList(),
        includeInitialPlacements: false);
    for (final context in contexts) { beginStep(context); }
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    _selectedStepId = context.step.id;
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
      case CinematicTimelineStepKind.actorJump:
        _beginActorJumpStep(context);
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
    _selectedStepId = context.step.id;
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
      case _ActorJumpStepState():
        _applyActorJumpState(state, progress);
      case _FadeStepState():
        host.setCinematicFadeOpacity(
          cinematicFadeOpacity(fadeOut: state.fadeOut, progress: progress),
        );
      case _ShakeStepState():
        final offset = cinematicShakeOffset(progress);
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
    _selectedStepId = context.step.id;
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
      _stepStates[context.step.id] is _AsyncStepState ||
      _stepStates[context.step.id] is _DialogueLineStepState;

  @override
  void endStep(CinematicRuntimeStepContext context) {
    _selectedStepId = context.step.id;
    final state = _stepState;
    if (state == null) return;
    switch (state) {
      case _CameraStepState():
        _applyCameraState(state, 1);
      case _ActorMoveStepState():
        _applyActorMoveState(state, 1);
      case _ActorJumpStepState():
        _applyActorJumpState(state, 1);
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
    if (state is _DialogueLineStepState) _dialogueLineSignalled = false;
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    _restoreVisualState(termination);
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
    if (checkpointFuture != null && port != null) {
      try {
        await pendingOperation;
      } catch (error, stackTrace) {
        firstError = error;
        firstStackTrace = stackTrace;
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
    try {
      _restoreVisualState(firstError == null
          ? termination : CinematicRuntimeTermination.failed);
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  void _restoreVisualState(CinematicRuntimeTermination termination) {
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
    for (final controller in _animationControllers.values.toList()) {
      attempt(controller.dispose);
    }
    for (final actor in _actors.values) {
      if (actor is FlameCinematicJumpActorHandle) {
        attempt(() => actor.setJumpLift(0));
      }
    }
    final poseHost = host;
    final current = snapshot != null && snapshot.mapId == host.activeMapId &&
        (poseHost is! FlameCinematicPoseRuntimeHost ||
            snapshot.activationToken == (poseHost as FlameCinematicPoseRuntimeHost).cinematicActivationToken);
    if (snapshot != null && current) {
      final keepFinal = termination == CinematicRuntimeTermination.completed &&
          firstError == null &&
          snapshot.asset.actorCompletionPolicy == CinematicActorCompletionPolicy.keepFinal;
      for (final actorSnapshot in snapshot.actors.values) {
        if (!keepFinal || firstError != null) {
          attempt(() => actorSnapshot.restore());
        } else {
          attempt(() => actorSnapshot.actor.setFacing(actorSnapshot.actor.facing));
        }
      }
      attempt(() => host.cameraPosition = snapshot.cameraPosition.clone());
      attempt(
        () => host.cameraVisibleGameSize =
            snapshot.cameraVisibleGameSize?.clone(),
      );
    }
    attempt(() => host.setCinematicInputLocked(false));
    if (snapshot != null && current) {
      if (termination == CinematicRuntimeTermination.completed &&
          snapshot.asset.actorCompletionPolicy == CinematicActorCompletionPolicy.keepFinal &&
          firstError == null && poseHost is FlameCinematicPoseRuntimeHost) {
        attempt(() => (poseHost as FlameCinematicPoseRuntimeHost).commitCinematicActorPoses({
          for (final binding in snapshot.asset.stageContext?.actorBindings ?? const <CinematicActorBinding>[])
            binding: FlameCinematicActorPose(
              focusX: _requireActor(binding.actorId).focusPoint.x,
              focusY: _requireActor(binding.actorId).focusPoint.y,
              facing: _requireActor(binding.actorId).facing,
            ),
        }));
      }
      if (firstError != null) {
        for (final actorSnapshot in snapshot.actors.values) {
          attempt(actorSnapshot.restore);
        }
      }
    }

    _snapshot = null;
    _playbackCameraPosition = null;
    _playbackVisibleGameSize = null;
    _actors = const {};
    _stepStates.clear();
    _animationControllers.clear();
    _selectedStepId = null;
    _groupStartPoses = const {};
    _groupFinalPoses = const {};
    _pendingMediaByChannel.clear();
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
      case CinematicTimelineStepKind.actorJump:
        if (_resolveActorById(asset, step.actorId) is! FlameCinematicJumpActorHandle ||
            host is! FlameCinematicPoseRuntimeHost ||
            cinematicTimelineActorJumpHeightCellsOf(step) == null ||
            !_hasPositiveDuration(step) || _movementRoute(asset, step) == null) {
          return invalid('requires a jump actor, valid landing, height and duration.');
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

  Map<CinematicActorBinding, FlameCinematicActorPose> _predictedActorPoses(
      CinematicAsset asset, {List<CinematicTimelineStep>? steps,
      bool includeInitialPlacements = true}) {
    final bindings = asset.stageContext?.actorBindings ?? const <CinematicActorBinding>[];
    final poses = <String, FlameCinematicActorPose>{
      for (final binding in bindings)
        binding.actorId: FlameCinematicActorPose(
          focusX: _resolveActor(binding)!.focusPoint.x,
          focusY: _resolveActor(binding)!.focusPoint.y,
          facing: _resolveActor(binding)!.facing,
        ),
    };
    for (final placement in includeInitialPlacements
        ? asset.stageContext?.initialPlacements ?? const <CinematicActorInitialPlacement>[]
        : const <CinematicActorInitialPlacement>[]) {
      if (placement.kind == CinematicActorInitialPlacementKind.fromMapEntity) continue;
      final point = _initialPlacement(asset, placement);
      final pose = poses[placement.actorId];
      if (point == null || pose == null) continue;
      poses[placement.actorId] = FlameCinematicActorPose(
        focusX: point.x, focusY: point.y,
        facing: bindings.any((binding) => binding.actorId == placement.actorId && binding.kind == CinematicActorBindingKind.player)
            ? EntityFacing.south : pose.facing,
      );
    }
    final width = (project?.settings.tileWidth ?? 1) * (project?.settings.displayScale ?? 1);
    final height = (project?.settings.tileHeight ?? 1) * (project?.settings.displayScale ?? 1);
    final groups = buildCinematicTimelineSchedule(steps == null ? asset
        : asset.copyWith(timeline: CinematicTimeline(steps: steps)),
        timing: CinematicTimelineScheduleTiming.runtime).groups;
    for (final group in groups) {
    final before = Map<String, FlameCinematicActorPose>.of(poses);
    final next = Map<String, FlameCinematicActorPose>.of(poses);
    for (final member in group.members) {
      final step = member.step;
      final pose = before[step.actorId];
      if (pose == null) continue;
      if (step.kind == CinematicTimelineStepKind.actorFace) {
        next[step.actorId!] = FlameCinematicActorPose(
          focusX: pose.focusX, focusY: pose.focusY, facing: _entityFacingOf(step));
      } else if (step.kind == CinematicTimelineStepKind.actorMove ||
          step.kind == CinematicTimelineStepKind.actorJump) {
        final route = _movementRoute(asset, step)!;
        var target = route.last;
        final targetBinding = asset.stageContext?.movementTargetBindings
            .where((binding) => binding.targetId == step.targetId).firstOrNull;
        if (targetBinding?.kind == CinematicMovementTargetBindingKind.mapEntity) {
          final binding = bindings.where((binding) => binding.kind == CinematicActorBindingKind.mapEntity &&
              binding.mapEntityId == targetBinding!.sourceId).firstOrNull;
          final targetPose = before[binding?.actorId];
          if (targetPose != null) target = Vector2(targetPose.focusX, targetPose.focusY);
        }
        final previous = route.length > 1 ? route[route.length - 2] : Vector2(pose.focusX, pose.focusY);
        final facing = cinematicTimelineActorFacingModeOf(step) == CinematicTimelineActorFacingMode.preserve
            ? pose.facing
            : _facingBetween(Vector2(previous.x / width, previous.y / height),
                Vector2(target.x / width, target.y / height), pose.facing);
        next[step.actorId!] = FlameCinematicActorPose(focusX: target.x, focusY: target.y, facing: facing);
      }
    }
    poses..clear()..addAll(next);
        if (group.members.any((member) => member.step.kind == CinematicTimelineStepKind.actorJump)) {
          (host as FlameCinematicPoseRuntimeHost).validateCinematicActorPoses({
            for (final binding in bindings) binding: poses[binding.actorId]!,
          });
        }
    }
    return {for (final binding in bindings) binding: poses[binding.actorId]!};
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
      asset: asset,
      mapId: host.activeMapId,
      activationToken: host is FlameCinematicPoseRuntimeHost
          ? (host as FlameCinematicPoseRuntimeHost).cinematicActivationToken : null,
      cameraPosition: host.cameraPosition.clone(),
      cameraVisibleGameSize: host.cameraVisibleGameSize?.clone(),
      actors: Map<String, _ActorVisualSnapshot>.unmodifiable(actorSnapshots),
    );
    for (final placement in asset.stageContext?.initialPlacements ?? const <CinematicActorInitialPlacement>[]) {
      if (placement.kind == CinematicActorInitialPlacementKind.fromMapEntity) continue;
      final position = _initialPlacement(asset, placement);
      if (position == null) continue;
      final actor = _requireActor(placement.actorId);
      actor.setFocusPoint(position);
      for (final binding in asset.stageContext!.actorBindings) {
        if (binding.actorId == placement.actorId && binding.kind == CinematicActorBindingKind.player) {
          actor.setFacing(EntityFacing.south);
        }
      }
    }
    for (final binding in asset.stageContext?.actorBindings ?? const <CinematicActorBinding>[]) {
      if (binding.kind != CinematicActorBindingKind.player) continue;
      final placed = asset.stageContext!.initialPlacements.any((placement) =>
          placement.actorId == binding.actorId &&
          placement.kind != CinematicActorInitialPlacementKind.unset &&
          placement.kind != CinematicActorInitialPlacementKind.fromMapEntity);
      if (placed) host.cameraPosition = _requireActor(binding.actorId).focusPoint.clone();
    }
    _playbackCameraPosition = host.cameraPosition.clone();
    _playbackVisibleGameSize = host.cameraVisibleGameSize?.clone();
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
    if (!_stepStates.values.contains(state) || state.completed) return;
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
    final queueChannel = command.channel ?? (command.kind == CinematicMediaPlaybackCommandKind.cancelFx
        ? mediaAssets.where((asset) => asset.id == command.assetId).firstOrNull?.channel ?? 'fx'
        : null);
    final previous = _pendingMediaByChannel[queueChannel];
    final operation = () async {
      if (previous != null) await previous;
      await checkpoint;
      await port.execute(command);
    }();
    _pendingMediaByChannel[queueChannel] = operation;
    _pendingMediaOperation = Future.wait(_pendingMediaByChannel.values).then((_) {});
    _pendingMediaOperation!.catchError((Object _) {});
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
        targetPosition = (_playbackCameraPosition ?? snapshot.cameraPosition).clone();
        targetSize = _playbackVisibleGameSize?.clone();
      case CinematicTimelineCameraMode.focus:
        final focus = cinematicTimelineCameraFocusBindingOf(context.step)!;
        targetPosition = _resolveCameraFocus(context.asset, focus)!.clone();
        final baseSize = _playbackVisibleGameSize ?? fromSize;
        if (baseSize != null) {
          targetSize = baseSize * cinematicCameraZoomFactor(focus.zoomPreset);
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

  Vector2? _initialPlacement(CinematicAsset asset, CinematicActorInitialPlacement placement) {
    return switch (placement.kind) {
      CinematicActorInitialPlacementKind.stagePoint => _stagePointById(asset, placement.stagePointId),
      CinematicActorInitialPlacementKind.fromMovementTarget => placement.targetId == null ? null : _resolveMovementTarget(asset, placement.targetId!),
      CinematicActorInitialPlacementKind.fromMapEntity => _resolveActorById(asset, placement.actorId)?.focusPoint.clone(),
      CinematicActorInitialPlacementKind.unset => null,
    };
  }

  void _beginActorMoveStep(CinematicRuntimeStepContext context) {
    final actor = _requireActor(context.step.actorId);
    final route = _movementRoute(context.asset, context.step)!;
    final initial = _groupStartPoses[context.step.actorId];
    final points = <Vector2>[initial == null ? actor.focusPoint.clone()
        : Vector2(initial.focusX, initial.focusY), ...route];
    _stepState = _ActorMoveStepState(
      actor: actor,
      points: points,
      preservedFacing: cinematicTimelineActorFacingModeOf(context.step) ==
              CinematicTimelineActorFacingMode.preserve
          ? initial?.facing ?? actor.facing
          : null,
      motion: cinematicTimelineActorMovementModeOf(context.step) ==
              CinematicTimelineActorMovementMode.run
          ? CharacterAnimationState.run
          : CharacterAnimationState.walk,
    );
    _applyActorMoveState(_stepState! as _ActorMoveStepState, 0);
    if (actor is FlameCinematicCharacterAnimationActorHandle) {
      actor.restoreBase(actor.facing);
      _applyActorMoveState(_stepState! as _ActorMoveStepState, 0);
    }
  }

  void _beginActorJumpStep(CinematicRuntimeStepContext context) {
    final step = context.step;
    final actor = _requireActor(step.actorId);
    final binding = context.asset.stageContext!.actorBindings
        .singleWhere((binding) => binding.actorId == step.actorId);
    final target = _movementRoute(context.asset, step)!.single;
    final width = (project?.settings.tileWidth ?? 1) * (project?.settings.displayScale ?? 1);
    final height = (project?.settings.tileHeight ?? 1) * (project?.settings.displayScale ?? 1);
    final facing = cinematicTimelineActorFacingModeOf(step) == CinematicTimelineActorFacingMode.preserve
        ? actor.facing : _facingBetween(
            Vector2(actor.focusPoint.x / width, actor.focusPoint.y / height),
            Vector2(target.x / width, target.y / height), actor.facing);
    final state = _ActorJumpStepState(
      actor: actor, binding: binding, start: actor.focusPoint.clone(),
      target: target.clone(), facing: facing,
      height: cinematicTimelineActorJumpHeightCellsOf(step)!,
    );
    _validateJumpLanding(state);
    _stepState = state;
    _applyActorJumpState(state, 0);
  }

  void _validateJumpLanding(_ActorJumpStepState state) {
    final snapshot = _snapshot!;
    (host as FlameCinematicPoseRuntimeHost).validateCinematicActorPoses({
      for (final binding in snapshot.asset.stageContext!.actorBindings)
        binding: _groupFinalPoses[binding] ?? FlameCinematicActorPose(
          focusX: _requireActor(binding.actorId).focusPoint.x,
          focusY: _requireActor(binding.actorId).focusPoint.y,
          facing: _requireActor(binding.actorId).facing,
        ),
      state.binding: FlameCinematicActorPose(focusX: state.target.x,
          focusY: state.target.y, facing: state.facing),
    });
  }

  void _applyActorJumpState(_ActorJumpStepState state, double progress) {
    if (progress >= 1) _validateJumpLanding(state);
    final sample = sampleCinematicJump(
      start: (x: state.start.x, y: state.start.y),
      end: (x: state.target.x, y: state.target.y),
      progress: progress, heightCells: state.height,
    );
    state.actor.setFocusPoint(Vector2(sample.x, sample.y));
    state.actor.setFacing(state.facing);
    final cellHeight = (project?.settings.tileHeight ?? 1) *
        (project?.settings.displayScale ?? 1);
    (state.actor as FlameCinematicJumpActorHandle).setJumpLift(sample.liftCells * cellHeight);
  }

  void _applyCameraState(_CameraStepState state, double progress) {
    host.cameraPosition = Vector2(
      cinematicVisualLerp(state.fromPosition.x, state.targetPosition.x, progress),
      cinematicVisualLerp(state.fromPosition.y, state.targetPosition.y, progress),
    );
    final fromSize = state.fromSize;
    final targetSize = state.targetSize;
    if (fromSize != null && targetSize != null) {
      host.cameraVisibleGameSize = Vector2(
        cinematicVisualLerp(fromSize.x, targetSize.x, progress),
        cinematicVisualLerp(fromSize.y, targetSize.y, progress),
      );
    } else if (progress >= 1) {
      host.cameraVisibleGameSize = targetSize?.clone();
    }
  }

  void _applyActorMoveState(_ActorMoveStepState state, double progress) {
    final width = (project?.settings.tileWidth ?? 1) * (project?.settings.displayScale ?? 1);
    final height = (project?.settings.tileHeight ?? 1) * (project?.settings.displayScale ?? 1);
    final sample = sampleCinematicRoute([
      for (final point in state.points) (x: point.x, y: point.y),
    ], progress, coordinateWidth: width.toDouble(), coordinateHeight: height.toDouble());
    final actor = state.actor;
    final facing = state.preservedFacing ?? (sample.segment < 0 ? actor.facing : _facingBetween(
      Vector2(state.points[sample.segment].x / width, state.points[sample.segment].y / height),
      Vector2(state.points[sample.segment + 1].x / width, state.points[sample.segment + 1].y / height), actor.facing));
    if (actor is FlameCinematicMotionActorHandle) {
      actor.setMotion(facing, progress >= 1 ? CharacterAnimationState.idle : state.motion);
    } else {
      actor.setFacing(facing);
    }
    actor.setFocusPoint(Vector2(sample.x, sample.y));
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

  Vector2? _resolveStagePoint(CinematicAsset asset, CinematicStagePoint point) {
    final actorId = point.relativeToActorId;
    if (actorId == null) return host.stagePointFocusPoint(point);
    final binding = asset.stageContext?.actorBindings
        .where((binding) => binding.actorId == actorId)
        .firstOrNull;
    if (binding == null) return null;
    final origin =
        _snapshot?.actors[actorId]?.focusPoint ??
        _resolveActor(binding)?.focusPoint;
    if (origin == null) return null;
    final zero = host.stagePointFocusPoint(
      CinematicStagePoint(id: point.id, label: point.label, x: 0, y: 0),
    );
    return origin + host.stagePointFocusPoint(point) - zero;
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
        final actorBinding = asset.stageContext?.actorBindings
            .where((actor) => actor.mapEntityId == sourceId).firstOrNull;
        final start = _groupStartPoses[actorBinding?.actorId];
        if (start != null) return Vector2(start.focusX, start.focusY);
        return host.mapEntityFocusPoint(sourceId);
      case CinematicMovementTargetBindingKind.stagePoint:
        for (final point in context.stagePoints) {
          if (point.id == sourceId) return _resolveStagePoint(asset, point);
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
      final resolved = _resolveStagePoint(asset, point);
      if (resolved == null) return null;
      route.add(resolved);
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
        _groupStartFocusPoint(focus.target.actorId) ??
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
      if (point.id == pointId) return _resolveStagePoint(asset, point);
    }
    return null;
  }

  Vector2? _groupStartFocusPoint(String? actorId) {
    final pose = _groupStartPoses[actorId];
    return pose == null ? null : Vector2(pose.focusX, pose.focusY);
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
      CinematicPlaybackPreflightIssueKind.invalidParallelGroup ||
      CinematicPlaybackPreflightIssueKind.missingDialogue ||
      CinematicPlaybackPreflightIssueKind.missingMedia ||
      CinematicPlaybackPreflightIssueKind.mediaTypeMismatch =>
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
    };

final class _CinematicRuntimeVisualSnapshot {
  const _CinematicRuntimeVisualSnapshot({
    required this.asset,
    required this.mapId,
    required this.activationToken,
    required this.cameraPosition,
    required this.cameraVisibleGameSize,
    required this.actors,
  });

  final Vector2 cameraPosition;
  final Vector2? cameraVisibleGameSize;
  final Map<String, _ActorVisualSnapshot> actors;
  final CinematicAsset asset;
  final String mapId;
  final Object? activationToken;
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
    final jumpActor = actor;
    if (jumpActor is FlameCinematicJumpActorHandle) jumpActor.setJumpLift(0);
    actor.setFocusPoint(focusPoint.clone());
    actor.setFacing(facing);
  }
}

sealed class _FlameCinematicStepState {
  const _FlameCinematicStepState();
}

final class _ActorJumpStepState extends _FlameCinematicStepState {
  const _ActorJumpStepState({required this.actor, required this.binding,
      required this.start, required this.target, required this.facing,
      required this.height});

  final FlameCinematicRuntimeActorHandle actor;
  final CinematicActorBinding binding;
  final Vector2 start, target;
  final EntityFacing facing;
  final double height;
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
  const _ActorMoveStepState({
    required this.actor,
    required this.points,
    required this.motion,
    required this.preservedFacing,
  });

  final FlameCinematicRuntimeActorHandle actor;
  final List<Vector2> points;
  final CharacterAnimationState motion;
  final EntityFacing? preservedFacing;
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
