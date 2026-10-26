import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import '../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart';

final class SpatialCinematicActorPose {
  const SpatialCinematicActorPose({
    required this.x,
    required this.z,
    required this.facing,
    this.motion = CharacterAnimationState.idle,
    this.animationSeconds = 0,
    this.liftCells = 0,
    this.emoteId,
    this.emoteElapsedSeconds = 0,
  });

  final double x, z, animationSeconds, liftCells;
  final EntityFacing facing;
  final String? emoteId;
  final double emoteElapsedSeconds;
  final CharacterAnimationState motion;

  SpatialCinematicActorPose copyWith({
    double? x,
    double? z,
    EntityFacing? facing,
    CharacterAnimationState? motion,
    double? animationSeconds,
    double? liftCells,
    String? emoteId,
    double? emoteElapsedSeconds,
    bool clearEmote = false,
  }) =>
      SpatialCinematicActorPose(
        x: x ?? this.x,
        z: z ?? this.z,
        facing: facing ?? this.facing,
        motion: motion ?? this.motion,
        animationSeconds: animationSeconds ?? this.animationSeconds,
        liftCells: liftCells ?? this.liftCells,
        emoteId: clearEmote ? null : emoteId ?? this.emoteId,
        emoteElapsedSeconds: clearEmote
            ? 0
            : emoteElapsedSeconds ?? this.emoteElapsedSeconds,
      );

  @override
  bool operator ==(Object other) =>
      other is SpatialCinematicActorPose &&
      other.x == x &&
      other.z == z &&
      other.facing == facing &&
      other.motion == motion &&
      other.animationSeconds == animationSeconds && other.liftCells == liftCells &&
      other.emoteId == emoteId &&
      other.emoteElapsedSeconds == emoteElapsedSeconds;

  @override
  int get hashCode => Object.hash(x, z, facing, motion, animationSeconds, liftCells,
    emoteId,
    emoteElapsedSeconds,
  );
}

final class SpatialCinematicCameraPose {
  const SpatialCinematicCameraPose({
    required this.x,
    required this.y,
    required this.z,
    required this.zoom,
  });

  final double x, y, z, zoom;

  @override
  bool operator ==(Object other) =>
      other is SpatialCinematicCameraPose &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(x, y, z, zoom);
}

typedef SpatialCinematicTraversal = bool Function(
    CinematicActorBinding actor,
    double fromX,
    double fromZ,
    double toX,
    double toZ,
    Map<CinematicActorBinding, SpatialCinematicActorPose> poses,
    Set<CinematicActorBinding> crossingActors);

final class SpatialCinematicRuntimePlaybackSink
    implements CinematicRuntimePlaybackSink, CinematicRuntimeGroupPlaybackSink {
  SpatialCinematicRuntimePlaybackSink({
    required this.project,
    required this.activeMap,
    required this.readActor,
    required this.writeActor,
    required this.readCamera,
    required this.writeCamera,
    required this.canTraverse,
    required this.setInputLocked,
    required this.onCompletedPoses,
    this.isReady,
    this.containsPoint,
    this.heightAt,
    this.readVisuals,
    this.readVisualOverrides,
    this.writeVisuals,
    this.writeFadeOpacity,
    this.retainFadeOnCompletion,
    this.onRestored,
  });

  final ProjectManifest project;
  final MapData Function() activeMap;
  final SpatialCinematicActorPose? Function(CinematicActorBinding) readActor;
  final void Function(CinematicActorBinding, SpatialCinematicActorPose)
      writeActor;
  final SpatialCinematicCameraPose? Function() readCamera;
  final void Function(SpatialCinematicCameraPose?) writeCamera;
  final SpatialCinematicTraversal canTraverse;
  final void Function(bool) setInputLocked;
  final void Function(Map<CinematicActorBinding, SpatialCinematicActorPose>)
      onCompletedPoses;
  final bool Function()? isReady;
  final bool Function(double x, double z)? containsPoint;
  final double Function(double x, double z)? heightAt;
  final SpatialVisualPatch Function()? readVisuals, readVisualOverrides;
  final void Function(SpatialVisualPatch)? writeVisuals;
  final void Function(double?)? writeFadeOpacity;
  final bool Function()? retainFadeOnCompletion;
  final void Function(bool keepFinal)? onRestored;
  SpatialVisualPatch? _savedVisuals;
  final _visualFrom = <String, SpatialVisualPatch>{};
  final _visualTo = <String, SpatialVisualPatch>{};

  _SpatialCinematicPreparation? _prepared;
  _SpatialCinematicSnapshot? _snapshot;
  String? _selectedStepId;
  final _states = <String, _SpatialCinematicStepState>{};
  _SpatialCinematicStepState get _state => _states[_selectedStepId!]!;
  CinematicActorBinding? get _stepActor => _state.actor;
  set _stepActor(CinematicActorBinding? value) => _state.actor = value;
  List<({double x, double y})>? get _route => _state.route;
  set _route(List<({double x, double y})>? value) => _state.route = value;
  double get _routeProgress => _state.progress;
  set _routeProgress(double value) => _state.progress = value;
  EntityFacing? get _preservedFacing => _state.facing;
  set _preservedFacing(EntityFacing? value) => _state.facing = value;
  double? get _jumpHeight => _state.jumpHeight;
  set _jumpHeight(double? value) => _state.jumpHeight = value;
  SpatialCinematicCameraPose? get _cameraFrom => _state.cameraFrom;
  set _cameraFrom(SpatialCinematicCameraPose? value) => _state.cameraFrom = value;
  SpatialCinematicCameraPose? get _cameraTarget => _state.cameraTarget;
  set _cameraTarget(SpatialCinematicCameraPose? value) => _state.cameraTarget = value;
  Map<CinematicActorBinding, SpatialCinematicActorPose> _groupStartPoses = const {};
  List<CinematicTimelineStep> _groupSteps = const [];

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) {
    _prepared = null;
    try {
      if (!(isReady?.call() ?? true)) {
        throw StateError('The spatial cinematic host is unavailable.');
      }
      final map = activeMap();
      if (map.spatialScene == null || asset.mapId != map.id) {
        return _rejected(
            'The cinematic does not target the active spatial map.');
      }
      for (final step in asset.timeline.steps) {
        if (!{
          CinematicTimelineStepKind.wait,
          if (writeFadeOpacity != null) CinematicTimelineStepKind.fade,
          if (readVisuals != null && readVisualOverrides != null && writeVisuals != null) CinematicTimelineStepKind.atmosphere,
          CinematicTimelineStepKind.camera,
          CinematicTimelineStepKind.actorMove,
          CinematicTimelineStepKind.actorJump,
          CinematicTimelineStepKind.actorFace,
          CinematicTimelineStepKind.actorEmote,
          CinematicTimelineStepKind.marker,
        }.contains(step.kind)) {
          return _rejected(
              'Unsupported spatial cinematic step ${step.kind.name}.',
              SceneCinematicRuntimeAwaitableErrorCode.unsupportedStepKind);
        }
      }
      final shared = preflightCinematicPlayback(
          cinematic: asset,
          availableMapIds: [map.id],
          activeMapId: map.id,
          mode: CinematicPlaybackPreflightMode.runtime);
      if (!shared.isReady) {
        final issue = shared.issues.first;
        return _rejected(
            issue.message,
            switch (issue.kind) {
              CinematicPlaybackPreflightIssueKind.invalidActorReference =>
                SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
              CinematicPlaybackPreflightIssueKind.unsupportedActorBinding =>
                SceneCinematicRuntimeAwaitableErrorCode.unsupportedActorBinding,
              CinematicPlaybackPreflightIssueKind.invalidTargetReference =>
                SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
              _ => SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
            });
      }
      final bindings = <String, CinematicActorBinding>{};
      final poses = <CinematicActorBinding, SpatialCinematicActorPose>{};
      final identities = <String>{};
      for (final binding in asset.stageContext?.actorBindings ?? const []) {
        final identity = binding.kind == CinematicActorBindingKind.player
            ? 'player'
            : 'entity:${binding.mapEntityId}';
        final pose = readActor(binding);
        if (pose == null ||
            !_inside(map, pose.x, pose.z) ||
            !identities.add(identity)) {
          return _rejected(
              'Actor ${binding.actorId} is unavailable or aliased.',
              SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference);
        }
        bindings[binding.actorId] = binding;
        poses[binding] = pose;
      }
      final initial = <CinematicActorBinding, SpatialCinematicActorPose>{};
      for (final placement
          in asset.stageContext?.initialPlacements ?? const []) {
        if (placement.kind == CinematicActorInitialPlacementKind.unset) {
          continue;
        }
        final binding = bindings[placement.actorId];
        if (binding == null || initial.containsKey(binding)) {
          throw StateError('Invalid or duplicate cinematic initial placement.');
        }
        final point = _initialPoint(asset, map, placement, poses);
        if (!_inside(map, point.x, point.y)) {
          throw StateError(
              'Initial placement ${placement.actorId} is blocked.');
        }
        final pose = poses[binding]!.copyWith(
            x: point.x,
            z: point.y,
            motion: CharacterAnimationState.idle,
            animationSeconds: 0);
        initial[binding] = pose;
        poses[binding] = pose;
      }
      final initialPoses =
          Map<CinematicActorBinding, SpatialCinematicActorPose>.unmodifiable(
              poses);
      for (final entry in initial.entries) {
        final pose = entry.value;
        if (!canTraverse(
            entry.key, pose.x, pose.z, pose.x, pose.z, initialPoses, const {})) {
          throw StateError(
              'Initial placement ${entry.key.actorId} is blocked.');
        }
      }
      final routes = <String, List<({double x, double y})>>{};
      for (final group in buildCinematicTimelineSchedule(asset,
          timing: CinematicTimelineScheduleTiming.runtime).groups) {
        final before = Map<CinematicActorBinding, SpatialCinematicActorPose>.of(poses);
        final next = Map<CinematicActorBinding, SpatialCinematicActorPose>.of(poses);
        for (final member in group.members) {
        final step = member.step;
        switch (step.kind) {
          case CinematicTimelineStepKind.fade:
            final mode = step.metadata[cinematicTimelineFadeModeMetadataKey];
            if ((mode != CinematicTimelineFadeMode.fadeIn.name &&
                    mode != CinematicTimelineFadeMode.fadeOut.name) ||
                (step.durationMs ?? 0) <= 0) {
              throw StateError('Fade ${step.id} requires a mode and duration.');
            }
          case CinematicTimelineStepKind.actorJump:
            final binding = bindings[step.actorId]!;
            final route = _movementRoute(asset, map, step, before);
            final target = route.single;
            _terminalPose(binding, before[binding]!.copyWith(x: target.x, z: target.y), finalPosition: false);
            routes[step.id] = route;
            next[binding] = before[binding]!.copyWith(x: target.x, z: target.y);
          case CinematicTimelineStepKind.actorMove:
            if ((step.durationMs ?? 0) <= 0 ||
                cinematicTimelineActorMovementModeOf(step) == null ||
                cinematicTimelineActorPathModeOf(step) == null) {
              throw StateError(
                  'Movement ${step.id} requires a duration and mode.');
            }
            final binding = bindings[step.actorId]!;
            final pose = before[binding]!;
            final route = _movementRoute(asset, map, step, before);
            routes[step.id] = route;
            next[binding] = pose.copyWith(x: route.last.x, z: route.last.y);
          case CinematicTimelineStepKind.actorEmote:
            final emote = cinematicTimelineActorEmoteEmoteIdOf(step);
            if (cinematicEmoteCatalogEntryById(emote) == null ||
                (step.durationMs ?? 0) <= 0) {
              throw StateError(
                'Emote ${step.id} requires a catalog entry and duration.',
              );
            }
          case CinematicTimelineStepKind.actorFace:
            final facing = cinematicTimelineActorFacingDirectionOf(step);
            if (facing == null) {
              throw StateError('Facing ${step.id} is missing.');
            }
            final binding = bindings[step.actorId]!;
            next[binding] = before[binding]!.copyWith(facing: _facing(facing));
          case CinematicTimelineStepKind.camera:
            final mode = cinematicTimelineCameraModeOf(step);
            if (mode == null ||
                mode == CinematicTimelineCameraMode.hold &&
                    (step.durationMs ?? 0) <= 0) {
              throw StateError(
                  'Camera ${step.id} has an invalid mode or duration.');
            }
            if (mode == CinematicTimelineCameraMode.focus) {
              _focusPoint(asset, map, step, before);
            }
          default:
            break;
        }
        }
        _validateGroupMotion(map: map, bindings: bindings, start: before,
            routes: routes, steps: group.members.map((member) => member.step).toList(),
            allowCrossing: asset.allowMobileActorCrossing);
        poses..clear()..addAll(next);
      }
      for (final entry in poses.entries) {
        _terminalPose(entry.key, entry.value);
        _validateLanding(map, entry.key, (x: entry.value.x, y: entry.value.z), poses);
      }
      _prepared =
          _SpatialCinematicPreparation(asset, map, bindings, initial, routes);
      return const CinematicRuntimeSinkPreflightResult.ready();
    } catch (error) {
      return _rejected('Spatial cinematic preflight rejected: $error');
    }
  }

  @override
  void beginGroup(List<CinematicRuntimeStepContext> contexts) {
    if (contexts.isEmpty) return;
    if (_snapshot == null) _begin(contexts.first.asset);
    final prepared = _current(contexts.first.asset);
    _groupStartPoses = _livePoses(prepared);
    _groupSteps = contexts.map((context) => context.step).toList();
    _validateGroupMotion(map: prepared.map, bindings: prepared.bindings,
        start: _groupStartPoses, routes: prepared.routes, steps: _groupSteps, allowCrossing: prepared.asset.allowMobileActorCrossing);
    for (final context in contexts) { beginStep(context); }
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    _selectedStepId = context.step.id;
    _states[_selectedStepId!] = _SpatialCinematicStepState();
    if (_snapshot == null) _begin(context.asset);
    final prepared = _current(context.asset);
    _stepActor = null;
    _route = null;
    _routeProgress = 0;
    _preservedFacing = null;
    _jumpHeight = null;
    _cameraFrom = _cameraTarget = null;
    final step = context.step;
    switch (step.kind) {
      case CinematicTimelineStepKind.atmosphere:
        final before = readVisuals!();
        final override = readVisualOverrides!().overriddenBy(step.visualSettings!);
        _visualFrom[step.id] = SpatialVisualPatch({
          for (final key in override.values.keys)
            if (before.value(key) != null) key: before.value(key)!,
        });
        _visualTo[step.id] = override;
      case CinematicTimelineStepKind.actorJump:
        _jumpHeight = cinematicTimelineActorJumpHeightCellsOf(step)!;
        final binding = _stepActor = prepared.bindings[step.actorId]!;
        final pose = _actor(binding);
        final target = prepared.routes[step.id]!.single;
        _validateLanding(prepared.map, binding, target, _groupSteps.isEmpty
            ? _livePoses(prepared) : _groupPosesAt(_groupStartPoses,
                prepared.bindings, prepared.routes, _groupSteps, 1));
        _route = [(x: pose.x, y: pose.z), target];
        _preservedFacing = cinematicTimelineActorFacingModeOf(step) ==
                CinematicTimelineActorFacingMode.preserve
            ? pose.facing : _segmentFacing(_route!.first, target, pose.facing);
      case CinematicTimelineStepKind.actorMove:
        final binding = _stepActor = prepared.bindings[step.actorId]!;
        final pose = _actor(binding);
        if (cinematicTimelineActorFacingModeOf(step) ==
            CinematicTimelineActorFacingMode.preserve) {
          _preservedFacing = pose.facing;
        }
        _route = [(x: pose.x, y: pose.z), ...prepared.routes[step.id]!];
        if (_groupSteps.isEmpty) {
          _validateRoute(prepared.map, binding, _route!, poses: _livePoses(prepared));
        }
        writeActor(binding, pose.copyWith(animationSeconds: 0));
      case CinematicTimelineStepKind.actorEmote:
        final binding = _stepActor = prepared.bindings[step.actorId]!;
        writeActor(
          binding,
          _actor(binding).copyWith(
            emoteId: cinematicTimelineActorEmoteEmoteIdOf(step),
            emoteElapsedSeconds: 0,
          ),
        );
      case CinematicTimelineStepKind.actorFace:
        final binding = _stepActor = prepared.bindings[step.actorId]!;
        writeActor(
            binding,
            _actor(binding).copyWith(
                facing: _facing(cinematicTimelineActorFacingDirectionOf(step)!),
                motion: CharacterAnimationState.idle,
                animationSeconds: 0));
      case CinematicTimelineStepKind.camera:
        _cameraFrom = readCamera() ?? _defaultCamera(prepared);
        _cameraTarget = switch (cinematicTimelineCameraModeOf(step)!) {
          CinematicTimelineCameraMode.hold => _cameraFrom,
          CinematicTimelineCameraMode.reset =>
            _snapshot!.camera ?? _defaultCamera(prepared),
          CinematicTimelineCameraMode.focus => _focusCamera(prepared, step),
        };
      default:
        break;
    }
    updateStep(context);
  }

  @override
  void updateStep(CinematicRuntimeStepContext context) {
    _selectedStepId = context.step.id;
    final prepared = _current(context.asset);
    final duration = context.step.durationMs ?? 0;
    final progress = duration <= 0
        ? 1.0
        : (context.elapsed.inMicroseconds / (duration * 1000)).clamp(0.0, 1.0);
    if (context.step.kind == CinematicTimelineStepKind.atmosphere) {
      writeVisuals!(SpatialVisualPatch.interpolate(_visualFrom[context.step.id]!, _visualTo[context.step.id]!, progress));
    }
    if (context.step.kind == CinematicTimelineStepKind.fade) {
      writeFadeOpacity!(cinematicFadeOpacity(
        fadeOut: context.step.metadata[cinematicTimelineFadeModeMetadataKey] ==
            CinematicTimelineFadeMode.fadeOut.name,
        progress: progress,
      ));
    }
    final route = _route, binding = _stepActor;
    if (context.step.kind == CinematicTimelineStepKind.actorEmote &&
        binding != null) {
      writeActor(
        binding,
        _actor(binding).copyWith(
          emoteElapsedSeconds:
              context.elapsed.inMicroseconds / Duration.microsecondsPerSecond,
        ),
      );
    }
    if (route != null && binding != null && _groupSteps.isNotEmpty) {
      _validateGroupMotion(map: prepared.map, bindings: prepared.bindings,
          start: _groupStartPoses, routes: prepared.routes, steps: _groupSteps,
          from: _routeProgress, to: progress,
          allowCrossing: prepared.asset.allowMobileActorCrossing);
    }
    if (route != null && binding != null && _jumpHeight != null) {
      if (progress >= 1) {
        _validateLanding(prepared.map, binding, route.last, _groupSteps.isEmpty
            ? _livePoses(prepared) : _groupPosesAt(_groupStartPoses,
                prepared.bindings, prepared.routes, _groupSteps, 1));
      }
      final sample = sampleCinematicJump(start: route.first, end: route.last,
          progress: progress, heightCells: _jumpHeight!);
      writeActor(binding, _actor(binding).copyWith(x: sample.x, z: sample.y,
          liftCells: sample.liftCells, facing: _preservedFacing,
          motion: CharacterAnimationState.idle, animationSeconds: 0));
      _routeProgress = progress;
    } else if (route != null && binding != null) {
      final pose = _actor(binding);
      final sample = sampleCinematicRoute(route, progress);
      final previousSample = sampleCinematicRoute(route, _routeProgress);
      if (_groupSteps.isEmpty) {
      _validateRoute(
          prepared.map,
          binding,
          [
            (x: pose.x, y: pose.z),
            if (previousSample.segment >= 0)
              for (var segment = previousSample.segment + 1;
                  segment <= sample.segment;
                  segment++)
                route[segment],
            (x: sample.x, y: sample.y),
          ],
          poses: _livePoses(prepared));
      }
      _routeProgress = progress;
      final segment = sample.segment;
      final facing = _preservedFacing ?? (segment < 0
          ? pose.facing
          : _segmentFacing(route[segment], route[segment + 1], pose.facing));
      writeActor(
          binding,
          pose.copyWith(
              x: sample.x,
              z: sample.y,
              facing: facing,
              motion: progress >= 1
                  ? CharacterAnimationState.idle
                  : cinematicTimelineActorMovementModeOf(context.step) ==
                          CinematicTimelineActorMovementMode.run
                      ? CharacterAnimationState.run
                      : CharacterAnimationState.walk,
              animationSeconds: progress >= 1
                  ? 0
                  : context.elapsed.inMicroseconds /
                      Duration.microsecondsPerSecond));
    }
    final from = _cameraFrom, target = _cameraTarget;
    if (from != null && target != null) {
      writeCamera(SpatialCinematicCameraPose(
          x: cinematicVisualLerp(from.x, target.x, progress),
          y: cinematicVisualLerp(from.y, target.y, progress),
          z: cinematicVisualLerp(from.z, target.z, progress),
          zoom: cinematicVisualLerp(from.zoom, target.zoom, progress)));
    }
  }

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) {
    _current(context.asset);
    return context.elapsed.inMicroseconds >=
        (context.step.durationMs ?? 0) * 1000;
  }

  @override
  void endStep(CinematicRuntimeStepContext context) {
    updateStep(context);
    final binding = _stepActor;
    if (binding != null) {
      writeActor(
          binding,
          _actor(binding).copyWith(
              motion: CharacterAnimationState.idle, animationSeconds: 0, liftCells: 0,
          clearEmote: context.step.kind == CinematicTimelineStepKind.actorEmote,
        ));
    }
    _stepActor = null;
    _route = null;
    _preservedFacing = null;
    _cameraFrom = _cameraTarget = null;
    _states.remove(context.step.id);
    _visualFrom.remove(context.step.id);
    _visualTo.remove(context.step.id);
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    final snapshot = _snapshot;
    _snapshot = null;
    _states.clear();
    _selectedStepId = null;
    _groupStartPoses = const {};
    _groupSteps = const [];
    if (snapshot == null) return;
    Object? failure;
    StackTrace? stack;
    void attempt(void Function() action) {
      try {
        action();
      } catch (error, trace) {
        failure ??= error;
        stack ??= trace;
      }
    }

    var current = false;
    attempt(() => current = identical(activeMap(), snapshot.map));
    if (current) attempt(() => writeCamera(snapshot.camera));
    if (current && _savedVisuals != null) attempt(() => writeVisuals?.call(_savedVisuals!));
    if (termination != CinematicRuntimeTermination.completed ||
        !current ||
        failure != null ||
        !(retainFadeOnCompletion?.call() ?? false)) {
      attempt(() => writeFadeOpacity?.call(null));
    }
    _savedVisuals = null;
    _visualFrom.clear();
    _visualTo.clear();
    attempt(() => setInputLocked(false));
    if (current && termination == CinematicRuntimeTermination.completed &&
        failure == null &&
        snapshot.actorCompletionPolicy == CinematicActorCompletionPolicy.keepFinal) {
      attempt(() => onCompletedPoses(Map.unmodifiable({
            for (final binding in snapshot.actors.keys)
              binding: _terminalPose(binding, _actor(binding)),
          })));
    }
    if (current &&
        (termination != CinematicRuntimeTermination.completed ||
            snapshot.actorCompletionPolicy == CinematicActorCompletionPolicy.restoreInitial ||
            failure != null)) {
      for (final entry in snapshot.actors.entries) {
        attempt(() => writeActor(entry.key, entry.value));
      }
    }
    attempt(() => onRestored?.call(current &&
        termination == CinematicRuntimeTermination.completed &&
        snapshot.actorCompletionPolicy == CinematicActorCompletionPolicy.keepFinal &&
        failure == null));
    _prepared = null;
    if (failure != null) attempt(() => writeFadeOpacity?.call(null));
    if (failure != null) Error.throwWithStackTrace(failure!, stack!);
  }

  void _begin(CinematicAsset asset) {
    final prepared = _prepared;
    if (prepared == null || !identical(prepared.asset, asset)) {
      throw StateError('Spatial cinematic playback was not prepared.');
    }
    _current(asset);
    _savedVisuals = readVisualOverrides?.call();
    _snapshot = _SpatialCinematicSnapshot(prepared.map, readCamera(), {
      for (final binding in prepared.bindings.values) binding: _actor(binding),
    }, asset.actorCompletionPolicy);
    setInputLocked(true);
    for (final entry in prepared.initial.entries) {
      writeActor(entry.key, entry.value);
    }
  }

  _SpatialCinematicPreparation _current(CinematicAsset asset) {
    final prepared = _prepared;
    if (prepared == null ||
        !identical(prepared.asset, asset) ||
        !identical(prepared.map, activeMap()) ||
        !(isReady?.call() ?? true)) {
      throw StateError('The spatial cinematic map activation changed.');
    }
    return prepared;
  }

  SpatialCinematicActorPose _actor(CinematicActorBinding binding) =>
      readActor(binding) ??
      (throw StateError('Actor ${binding.actorId} disappeared.'));

  SpatialCinematicActorPose _terminalPose(
      CinematicActorBinding binding, SpatialCinematicActorPose pose,
      {bool finalPosition = true}) {
    var x = pose.x, z = pose.z;
    if (binding.kind == CinematicActorBindingKind.player) {
      final pixelX = x * 16, pixelZ = z * 16;
      if ((pixelX - pixelX.roundToDouble()).abs() > 1e-7 ||
          (pixelZ - pixelZ.roundToDouble()).abs() > 1e-7) {
        throw StateError(
            'The player terminal position must align to the 1/16-cell movement precision.');
      }
      x = pixelX.round() / 16;
      z = pixelZ.round() / 16;
      final map = activeMap();
      if (finalPosition && !(x >= 0 && z >= 0 && x < map.size.width && z < map.size.height)) {
        throw StateError('The player terminal position must remain inside the active map.');
      }
    }
    return pose.copyWith(
        x: x, z: z, motion: CharacterAnimationState.idle, animationSeconds: 0, liftCells: 0,
      clearEmote: true,
    );
  }

  Map<CinematicActorBinding, SpatialCinematicActorPose> _livePoses(
          _SpatialCinematicPreparation prepared) =>
      {
        for (final binding in prepared.bindings.values) binding: _actor(binding)
      };

  bool _inside(MapData map, double x, double z) =>
      x.isFinite &&
      z.isFinite &&
      (containsPoint?.call(x, z) ??
          (x >= 0 && z >= 0 && x < map.size.width && z < map.size.height));

  Map<CinematicActorBinding, SpatialCinematicActorPose> _groupPosesAt(
      Map<CinematicActorBinding, SpatialCinematicActorPose> start,
      Map<String, CinematicActorBinding> bindings,
      Map<String, List<({double x, double y})>> routes,
      List<CinematicTimelineStep> steps, double progress) {
    final result = Map<CinematicActorBinding, SpatialCinematicActorPose>.of(start);
    for (final step in steps) {
      final binding = bindings[step.actorId];
      final pose = start[binding];
      if (binding == null || pose == null) continue;
      if (step.kind == CinematicTimelineStepKind.actorMove ||
          step.kind == CinematicTimelineStepKind.actorJump) {
        final route = [(x: pose.x, y: pose.z), ...routes[step.id]!];
        final sample = sampleCinematicRoute(route, progress);
        result[binding] = pose.copyWith(x: sample.x, z: sample.y);
      }
    }
    return result;
  }

  void _validateGroupMotion({
    required MapData map,
    required Map<String, CinematicActorBinding> bindings,
    required Map<CinematicActorBinding, SpatialCinematicActorPose> start,
    required Map<String, List<({double x, double y})>> routes,
    required List<CinematicTimelineStep> steps,
    double from = 0, double to = 1,
    bool allowCrossing = false,
  }) {
    final crossingActors = <CinematicActorBinding>{
      if (allowCrossing)
        for (final step in steps)
          if ((step.kind == CinematicTimelineStepKind.actorMove || step.kind == CinematicTimelineStepKind.actorJump) &&
              bindings[step.actorId] != null &&
              routes[step.id]?.any((point) =>
                  (point.x - start[bindings[step.actorId]]!.x).abs() > .000000001 ||
                  (point.y - start[bindings[step.actorId]]!.z).abs() > .000000001) == true)
            bindings[step.actorId]!,
    };
    var length = 0.0;
    for (final step in steps) {
      final binding = bindings[step.actorId];
      final pose = start[binding];
      if (pose == null || routes[step.id] == null) continue;
      final route = [(x: pose.x, y: pose.z), ...routes[step.id]!];
      var total = 0.0;
      for (var i = 1; i < route.length; i++) {
        total += math.sqrt(math.pow(route[i].x - route[i - 1].x, 2) +
            math.pow(route[i].y - route[i - 1].y, 2));
      }
      length = math.max(length, total);
      for (final point in route) {
        if (!_inside(map, point.x, point.y)) {
          throw StateError('A cinematic group route is outside its map.');
        }
      }
    }
    final count = math.max(1, (length * (to - from).abs() * 16).ceil());
    var previous = _groupPosesAt(start, bindings, routes, steps, from);
    var previousProgress = from;
    for (var i = 1; i <= count; i++) {
      final progress = i == count ? to : from + (to - from) * i / count;
      final candidates = _groupPosesAt(start, bindings, routes, steps, progress);
      for (final step in steps) {
        final binding = bindings[step.actorId];
        if (binding == null || routes[step.id] == null) continue;
        final pose = candidates[binding]!;
        if (step.kind == CinematicTimelineStepKind.actorJump) {
          if (progress >= 1) {
            _validateLanding(map, binding, (x: pose.x, y: pose.z), candidates);
          }
        } else if (step.kind == CinematicTimelineStepKind.actorMove) {
          final initial = start[binding]!;
          final route = [(x: initial.x, y: initial.z), ...routes[step.id]!];
          final before = sampleCinematicRoute(route, previousProgress);
          final after = sampleCinematicRoute(route, progress);
          _validateRoute(map, binding, [
            (x: previous[binding]!.x, y: previous[binding]!.z),
            if (before.segment >= 0)
              for (var segment = before.segment + 1; segment <= after.segment; segment++)
                route[segment],
            (x: pose.x, y: pose.z),
          ], poses: candidates, crossingActors: crossingActors);
        }
      }
      previous = candidates;
      previousProgress = progress;
    }
  }

  void _validateRoute(MapData map, CinematicActorBinding binding,
      List<({double x, double y})> route,
      {required Map<CinematicActorBinding, SpatialCinematicActorPose> poses,
      Set<CinematicActorBinding> crossingActors = const {}}) {
    final traversalPoses =
        Map<CinematicActorBinding, SpatialCinematicActorPose>.unmodifiable(
            poses);
    for (final point in route) {
      if (!_inside(map, point.x, point.y)) {
        throw StateError('Actor ${binding.actorId} route is outside its map.');
      }
    }
    for (var segment = 1; segment < route.length; segment++) {
      final from = route[segment - 1], to = route[segment];
      final count = math.max(
          1,
          (math.sqrt(math.pow(to.x - from.x, 2) + math.pow(to.y - from.y, 2)) *
                  16)
              .ceil());
      var previous = from;
      for (var i = 1; i <= count; i++) {
        final point = (
          x: from.x + (to.x - from.x) * i / count,
          y: from.y + (to.y - from.y) * i / count
        );
        if (!canTraverse(binding, previous.x, previous.y, point.x, point.y,
            traversalPoses, crossingActors)) {
          throw StateError('Actor ${binding.actorId} route is blocked: (${previous.x}, ${previous.y}) -> (${point.x}, ${point.y}).');
        }
        previous = point;
      }
    }
  }

  void _validateLanding(MapData map, CinematicActorBinding binding,
      ({double x, double y}) target,
      Map<CinematicActorBinding, SpatialCinematicActorPose> poses) {
    if (!_inside(map, target.x, target.y) ||
        !canTraverse(binding, target.x, target.y, target.x, target.y, poses, const {})) {
      throw StateError('Actor ${binding.actorId} jump landing is blocked.');
    }
  }

  ({double x, double y}) _stagePoint(CinematicAsset asset, String? id) {
    final point = asset.stageContext?.stagePoints
        .where((point) => point.id == id)
        .firstOrNull;
    if (point == null) {
      throw StateError('Cinematic stage point $id is missing.');
    }
    final actorId = point.relativeToActorId;
    if (actorId == null) return (x: point.x, y: point.y);
    final binding = asset.stageContext?.actorBindings
        .where((binding) => binding.actorId == actorId)
        .firstOrNull;
    final origin = binding == null
        ? null
        : _snapshot?.actors[binding] ?? readActor(binding);
    final resolved = resolveCinematicStagePoint(point, {
      if (origin != null) actorId: (x: origin.x, y: origin.z),
    });
    if (resolved == null) {
      throw StateError('Cinematic stage point $id has no actor origin.');
    }
    return (x: resolved.x, y: resolved.y);
  }

  ({double x, double y}) _entityPoint(CinematicAsset asset, MapData map,
      String? id, Map<CinematicActorBinding, SpatialCinematicActorPose> poses) {
    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      if (binding.kind == CinematicActorBindingKind.mapEntity &&
          binding.mapEntityId == id) {
        final pose = poses[binding] ?? readActor(binding);
        if (pose != null) return (x: pose.x, y: pose.z);
      }
    }
    final entity = map.entities.where((entity) => entity.id == id).firstOrNull;
    if (entity == null) {
      throw StateError('Cinematic entity target $id is missing.');
    }
    return (x: entity.pos.x + .5, y: entity.pos.y + .5);
  }

  ({double x, double y}) _targetPoint(CinematicAsset asset, MapData map,
      String? id, Map<CinematicActorBinding, SpatialCinematicActorPose> poses) {
    final binding = asset.stageContext?.movementTargetBindings
        .where((binding) => binding.targetId == id)
        .firstOrNull;
    if (binding == null) {
      throw StateError('Cinematic movement target $id is missing.');
    }
    return switch (binding.kind) {
      CinematicMovementTargetBindingKind.stagePoint =>
        _stagePoint(asset, binding.sourceId),
      CinematicMovementTargetBindingKind.mapEntity =>
        _entityPoint(asset, map, binding.sourceId, poses),
      _ => throw StateError('Unsupported cinematic target binding.'),
    };
  }

  ({double x, double y}) _initialPoint(
          CinematicAsset asset,
          MapData map,
          CinematicActorInitialPlacement placement,
          Map<CinematicActorBinding, SpatialCinematicActorPose> poses) =>
      switch (placement.kind) {
        CinematicActorInitialPlacementKind.stagePoint =>
          _stagePoint(asset, placement.stagePointId),
        CinematicActorInitialPlacementKind.fromMapEntity => (() {
            final binding = asset.stageContext!.actorBindings
                .where((binding) => binding.actorId == placement.actorId)
                .firstOrNull;
            if (binding == null) {
              throw StateError('Initial placement actor is unavailable.');
            }
            final pose = poses[binding] ?? _actor(binding);
            return (x: pose.x, y: pose.z);
          })(),
        CinematicActorInitialPlacementKind.fromMovementTarget =>
          _targetPoint(asset, map, placement.targetId, poses),
        CinematicActorInitialPlacementKind.unset =>
          throw StateError('No initial placement point.'),
      };

  List<({double x, double y})> _movementRoute(
      CinematicAsset asset,
      MapData map,
      CinematicTimelineStep step,
      Map<CinematicActorBinding, SpatialCinematicActorPose> poses) {
    final route = <({double x, double y})>[];
    if (cinematicTimelineActorPathModeOf(step) ==
        CinematicTimelineActorPathMode.manual) {
      final path = asset.stageContext?.manualPaths
          .where((path) => path.ownerActorMoveStepId == step.id)
          .firstOrNull;
      if (path == null) {
        throw StateError('Manual movement ${step.id} has no route.');
      }
      if (path.waypointStagePointIds.isEmpty) {
        throw StateError('Manual movement ${step.id} requires a waypoint.');
      }
      route.addAll(
          path.waypointStagePointIds.map((id) => _stagePoint(asset, id)));
    }
    final target = _targetPoint(asset, map, step.targetId, poses);
    if (route.isEmpty || route.last != target) route.add(target);
    return List.unmodifiable(route);
  }

  ({double x, double y}) _focusPoint(
      CinematicAsset asset,
      MapData map,
      CinematicTimelineStep step,
      Map<CinematicActorBinding, SpatialCinematicActorPose> poses) {
    final focus = cinematicTimelineCameraFocusBindingOf(step);
    if (focus == null) throw StateError('Camera ${step.id} has no focus.');
    final point = switch (focus.target.kind) {
      CinematicCameraTargetKind.sceneCenter => (
          x: map.size.width / 2,
          y: map.size.height / 2
        ),
      CinematicCameraTargetKind.stagePoint =>
        _stagePoint(asset, focus.target.stagePointId),
      CinematicCameraTargetKind.actor => (() {
          final binding = asset.stageContext!.actorBindings
              .where((binding) => binding.actorId == focus.target.actorId)
              .firstOrNull;
          if (binding == null) throw StateError('Camera actor is unavailable.');
          final pose = poses[binding] ?? _actor(binding);
          return (x: pose.x, y: pose.z);
        })(),
    };
    if (!_inside(map, point.x, point.y)) {
      throw StateError('Camera focus is outside map.');
    }
    return point;
  }

  SpatialCinematicCameraPose _focusCamera(
      _SpatialCinematicPreparation prepared, CinematicTimelineStep step) {
    final point = _focusPoint(prepared.asset, prepared.map, step, {});
    return SpatialCinematicCameraPose(
        x: point.x,
        y: (heightAt?.call(point.x, point.y) ??
          prepared.map.spatialScene!.worldHeightAt(point.x, point.y)),
        z: point.y,
        zoom: cinematicCameraZoomFactor(
            cinematicTimelineCameraFocusBindingOf(step)!.zoomPreset));
  }

  SpatialCinematicCameraPose _defaultCamera(
      _SpatialCinematicPreparation prepared) {
    final player = readActor(CinematicActorBinding(
        actorId: 'spatial-camera-player',
        kind: CinematicActorBindingKind.player));
    final x = player?.x ?? prepared.map.size.width / 2,
        z = player?.z ?? prepared.map.size.height / 2;
    return SpatialCinematicCameraPose(
        x: x, y: (heightAt?.call(x, z) ??
          prepared.map.spatialScene!.worldHeightAt(x, z)), z: z, zoom: 1);
  }

  EntityFacing _facing(CinematicTimelineActorFacingDirection direction) =>
      switch (direction) {
        CinematicTimelineActorFacingDirection.up => EntityFacing.north,
        CinematicTimelineActorFacingDirection.down => EntityFacing.south,
        CinematicTimelineActorFacingDirection.left => EntityFacing.west,
        CinematicTimelineActorFacingDirection.right => EntityFacing.east,
      };

  EntityFacing _segmentFacing(({double x, double y}) from,
      ({double x, double y}) to, EntityFacing fallback) {
    final dx = to.x - from.x, dz = to.y - from.y;
    if (dx == 0 && dz == 0) return fallback;
    return dz.abs() >= dx.abs()
        ? (dz >= 0 ? EntityFacing.south : EntityFacing.north)
        : (dx >= 0 ? EntityFacing.east : EntityFacing.west);
  }

  CinematicRuntimeSinkPreflightResult _rejected(String message,
          [SceneCinematicRuntimeAwaitableErrorCode code =
              SceneCinematicRuntimeAwaitableErrorCode.preflightRejected]) =>
      CinematicRuntimeSinkPreflightResult.rejected(
          errorCode: code, message: message);
}

final class _SpatialCinematicStepState {
  CinematicActorBinding? actor;
  List<({double x, double y})>? route;
  double progress = 0;
  EntityFacing? facing;
  double? jumpHeight;
  SpatialCinematicCameraPose? cameraFrom, cameraTarget;
}

final class _SpatialCinematicPreparation {
  const _SpatialCinematicPreparation(
      this.asset, this.map, this.bindings, this.initial, this.routes);
  final CinematicAsset asset;
  final MapData map;
  final Map<String, CinematicActorBinding> bindings;
  final Map<CinematicActorBinding, SpatialCinematicActorPose> initial;
  final Map<String, List<({double x, double y})>> routes;
}

final class _SpatialCinematicSnapshot {
  const _SpatialCinematicSnapshot(this.map, this.camera, this.actors, this.actorCompletionPolicy);
  final MapData map;
  final SpatialCinematicCameraPose? camera;
  final Map<CinematicActorBinding, SpatialCinematicActorPose> actors;
  final CinematicActorCompletionPolicy actorCompletionPolicy;
}
