import 'dart:async';

import 'package:map_core/map_core.dart';

import '../application/scene_runtime/scene_presentation_cinematic_runtime_awaitable_adapter.dart';
import 'runtime_presentation_audio_controller.dart';
import 'runtime_presentation_execution_controller.dart';
import 'runtime_presentation_media_playback_controller.dart';

typedef RuntimePresentationFrameSink = void Function(
  ScenePresentationCinematicRuntimeRequest request,
  PresentationFrame? frame,
);

typedef RuntimePresentationFrameDeltas = Stream<int> Function(int durationUs);

typedef RuntimePresentationVisualMediaResolver = String Function(
  ScenePresentationCinematicRuntimeRequest request,
  PresentationVisualFrameClip clip,
);

typedef RuntimePresentationBeforeTerminal = Future<void> Function();

final class RuntimePresentationScenePlaybackController
    implements ScenePresentationCinematicRuntimePlayer {
  RuntimePresentationScenePlaybackController({
    required this.executionController,
    required this.onFrame,
    this.audioController,
    RuntimePresentationFrameDeltas? frameDeltas,
    RuntimePresentationVisualMediaResolver? resolveVisualMediaId,
    RuntimePresentationBeforeTerminal? beforeTerminal,
  })  : _frameDeltas = frameDeltas ?? _systemFrameDeltas,
        _resolveVisualMediaId =
            resolveVisualMediaId ?? _defaultVisualMediaResolver,
        _beforeTerminal = beforeTerminal ?? _noTerminalBarrier;

  final RuntimePresentationExecutionController executionController;
  final RuntimePresentationAudioController? audioController;
  final RuntimePresentationFrameSink onFrame;
  final RuntimePresentationFrameDeltas _frameDeltas;
  final RuntimePresentationVisualMediaResolver _resolveVisualMediaId;
  final RuntimePresentationBeforeTerminal _beforeTerminal;
  final PresentationCinematicEvaluator _evaluator =
      const PresentationCinematicEvaluator();

  _RuntimePresentationActiveRun? _active;
  int _generation = 0;
  bool _disposed = false;

  bool get isPlaying => _active != null;

  RuntimePresentationExecutionSnapshot get executionSnapshot =>
      executionController.snapshot;

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) {
    if (_disposed) {
      return Future<RuntimePresentationExecutionTerminal>.error(
        StateError('Presentation scene playback is disposed.'),
      );
    }
    if (_active != null) {
      return Future<RuntimePresentationExecutionTerminal>.error(
        StateError('A Presentation cinematic is already playing.'),
      );
    }
    final token = executionController.start(
      observability: _correlation(request),
    );
    final clock = PresentationPlaybackClock(
      durationUs: request.asset.durationUs,
    );
    final clockToken = clock.play();
    if (clockToken == null) {
      return Future<RuntimePresentationExecutionTerminal>.error(
        StateError('The Presentation cinematic has no playable duration.'),
      );
    }
    final generation = ++_generation;
    final active = _RuntimePresentationActiveRun(
      request: request,
      token: token,
      clock: clock,
      clockToken: clockToken,
      generation: generation,
    );
    _active = active;
    unawaited(_drive(active));
    return executionController.waitForTerminal(token).whenComplete(() {
      if (identical(_active, active)) {
        onFrame(request, null);
        _active = null;
      }
    });
  }

  Future<void> _drive(_RuntimePresentationActiveRun active) async {
    try {
      if (!await _publish(active)) return;
      await for (final deltaUs
          in _frameDeltas(active.request.asset.durationUs)) {
        if (!_isCurrent(active)) return;
        if (executionController.snapshot.phase ==
            RuntimePresentationExecutionPhase.paused) {
          continue;
        }
        if (!active.clock.advanceBy(deltaUs, token: active.clockToken)) return;
        if (!await _publish(active)) return;
        if (active.clock.status == PresentationPlaybackStatus.completed) {
          await _prepareTerminal(active);
          await executionController.complete(active.token);
          return;
        }
      }
    } on Object {
      if (_isCurrent(active)) {
        await _prepareTerminal(active);
        await executionController.fail(
          active.token,
          diagnosticCode: PresentationDiagnosticCodes.playbackFailed,
        );
      }
    }
  }

  Future<bool> _publish(_RuntimePresentationActiveRun active) async {
    while (true) {
      if (!_isCurrent(active)) return false;
      final frame = _evaluator.evaluate(
        active.request.asset,
        timeUs: active.clock.playheadUs,
      );
      if (!await _synchronizeVideo(active, frame)) return false;
      if (!await _synchronizeAudio(active, frame)) return false;
      if (!_isCurrent(active)) return false;
      onFrame(active.request, frame);
      switch (await _runInteractionCues(active)) {
        case _CueLoopDirective.proceed:
          return true;
        case _CueLoopDirective.abort:
          return false;
        case _CueLoopDirective.republish:
          // A seek or repeat moved the playhead: re-evaluate immediately so
          // re-armed cues fire in this same pass — the transition budget is
          // the loop bound.
          continue;
      }
    }
  }

  Future<bool> _synchronizeAudio(
    _RuntimePresentationActiveRun active,
    PresentationFrame frame,
  ) async {
    final audio = audioController;
    if (audio == null) return _isCurrent(active);
    try {
      await audio.synchronize(active.request.asset, frame);
    } on RuntimePresentationAudioFailure catch (failure) {
      if (!_isCurrent(active)) return false;
      await _prepareTerminal(active);
      await executionController.fail(
        active.token,
        diagnosticCode: failure.diagnosticCode,
      );
      return false;
    }
    return _isCurrent(active);
  }

  Future<_CueLoopDirective> _runInteractionCues(
    _RuntimePresentationActiveRun active,
  ) async {
    final handler = active.request.onInteractionCue;
    final currentPlayheadUs = active.clock.playheadUs;
    if (handler == null) {
      active.publishedPlayheadUs = currentPlayheadUs;
      return _CueLoopDirective.proceed;
    }
    final dueMarkerIds = <(int, String)>[];
    for (final track in active.request.asset.tracks) {
      for (final clip in track.clips) {
        if (clip is! PresentationMarkerClip ||
            clip.markerKind != PresentationMarkerKind.interactionCue ||
            !active.request.interactionCueMarkerIds.contains(clip.id) ||
            active.triggeredMarkerIds.contains(clip.id)) {
          continue;
        }
        final crossed = active.publishedPlayheadUs < 0
            ? clip.startUs <= currentPlayheadUs
            : clip.startUs > active.publishedPlayheadUs &&
                clip.startUs <= currentPlayheadUs;
        if (crossed) dueMarkerIds.add((clip.startUs, clip.id));
      }
    }
    dueMarkerIds.sort((left, right) {
      final time = left.$1.compareTo(right.$1);
      return time != 0 ? time : left.$2.compareTo(right.$2);
    });
    active.publishedPlayheadUs = currentPlayheadUs;
    for (final marker in dueMarkerIds) {
      active.triggeredMarkerIds.add(marker.$2);
      final cue = ScenePresentationInteractionCue(
        markerId: marker.$2,
        cueExecutionId:
            '${active.request.requestId}:cue:${marker.$2}#${active.nextCueSequence++}',
      );
      executionController.enterInteractionHold(active.token);
      await audioController?.pauseForHold();
      final freezeVideo = active.videoMediaId != null &&
          active.videoHoldPolicy == PresentationHoldTrackPolicy.frozen;
      if (freezeVideo) {
        await executionController.mediaController.pauseForHold();
      }
      final PresentationInteractionOutcome outcome;
      try {
        outcome = await handler(cue);
      } finally {
        if (freezeVideo) {
          await executionController.mediaController.resumeFromHold();
        }
        await audioController?.resumeFromHold();
        executionController.exitInteractionHold(active.token);
      }
      if (!_isCurrent(active)) return _CueLoopDirective.abort;
      if (!active.cueOutcomeGate.admit(cue.cueExecutionId)) continue;
      final directive = await _applyCueOutcome(active, outcome);
      if (directive != _CueLoopDirective.proceed) return directive;
    }
    return _CueLoopDirective.proceed;
  }

  /// Applies exactly one terminal cue outcome (BETA-CIN-070, routed by
  /// BETA-CIN-072).
  ///
  /// Seek and repeat destinations are resolved by marker identity against
  /// the playing asset; an unknown destination fails with a stable code and
  /// never moves the playhead. A resolved destination consumes one unit of
  /// the per-execution transition budget, moves the playhead to the marker,
  /// re-arms every marker at or after the destination (the replay window of
  /// repeatFromMarker), and asks the publish loop to re-evaluate — an
  /// exhausted budget terminates instead of looping forever.
  Future<_CueLoopDirective> _applyCueOutcome(
    _RuntimePresentationActiveRun active,
    PresentationInteractionOutcome outcome,
  ) async {
    switch (outcome) {
      case PresentationContinueTimelineOutcome():
        return _CueLoopDirective.proceed;
      case PresentationStopOutcome():
        await _prepareTerminal(active);
        await executionController.complete(active.token);
        return _CueLoopDirective.abort;
      case PresentationCancelledOutcome():
        await _prepareTerminal(active);
        await executionController.skip(active.token);
        return _CueLoopDirective.abort;
      case PresentationFailedOutcome(diagnosticCode: final diagnosticCode):
        await _prepareTerminal(active);
        await executionController.fail(
          active.token,
          diagnosticCode:
              diagnosticCode ?? PresentationDiagnosticCodes.playbackFailed,
        );
        return _CueLoopDirective.abort;
      case PresentationSeekMarkerOutcome() ||
            PresentationRepeatFromMarkerOutcome():
        final resolution = resolvePresentationOutcomeDestination(
          active.request.asset,
          outcome,
        );
        switch (resolution) {
          case PresentationOutcomeDestinationResolved(:final startUs):
            if (!active.transitionBudget.tryConsume()) {
              await _prepareTerminal(active);
              await executionController.fail(
                active.token,
                diagnosticCode:
                    PresentationCueOutcomeCodes.transitionBudgetExhausted,
              );
              return _CueLoopDirective.abort;
            }
            active.clock.seekTo(startUs);
            for (final track in active.request.asset.tracks) {
              for (final clip in track.clips) {
                if (clip is PresentationMarkerClip &&
                    clip.startUs >= startUs) {
                  active.triggeredMarkerIds.remove(clip.id);
                }
              }
            }
            active.publishedPlayheadUs = startUs - 1;
            return _CueLoopDirective.republish;
          case PresentationOutcomeDestinationUnknown() ||
                PresentationOutcomeDestinationNone():
            await _prepareTerminal(active);
            await executionController.fail(
              active.token,
              diagnosticCode:
                  PresentationCueOutcomeCodes.unknownSeekDestination,
            );
            return _CueLoopDirective.abort;
        }
    }
  }

  Future<bool> _synchronizeVideo(
    _RuntimePresentationActiveRun active,
    PresentationFrame frame,
  ) async {
    String? videoMediaId;
    var videoHoldPolicy = PresentationHoldTrackPolicy.frozen;
    for (final visual in frame.visuals) {
      final mediaId = _resolveVisualMediaId(active.request, visual);
      final media = executionController.mediaController.catalog.find(mediaId);
      if (media?.kind == ProjectMediaKind.video) {
        videoMediaId = mediaId;
        videoHoldPolicy = active.request.asset.tracks
                .where((track) => track.id == visual.trackId)
                .map((track) => track.holdPolicy)
                .firstOrNull ??
            PresentationHoldTrackPolicy.frozen;
        break;
      }
    }
    active.videoHoldPolicy = videoHoldPolicy;
    if (videoMediaId == active.videoMediaId) return true;
    active.videoMediaId = videoMediaId;
    if (videoMediaId == null) {
      await executionController.mediaController.release();
      return _isCurrent(active);
    }
    final media = await executionController.mediaController.playVideo(
      videoMediaId,
      audioMode: RuntimePresentationVideoAudioMode.mixerManaged,
    );
    executionController.observeMediaPlaybackSnapshot(active.token, media);
    if (media.status == RuntimePresentationMediaPlaybackStatus.failed) {
      await _prepareTerminal(active);
      await executionController.fail(
        active.token,
        diagnosticCode: media.diagnosticCode ??
            RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
      );
      return false;
    }
    return _isCurrent(active);
  }

  Future<RuntimePresentationExecutionTerminal?> skipActive() async {
    final active = _active;
    if (active == null) return null;
    await _prepareTerminal(active);
    return executionController.skip(active.token);
  }

  Future<RuntimePresentationExecutionTerminal?> cancelActive({
    RuntimePresentationCancellationReason reason =
        RuntimePresentationCancellationReason.requested,
  }) async {
    final active = _active;
    if (active == null) return null;
    await _prepareTerminal(active);
    return executionController.cancel(active.token, reason: reason);
  }

  Future<void> pauseForLifecycle() async {
    final active = _active;
    if (active == null) return;
    active.clock.pause();
    await audioController?.pauseForLifecycle();
    await executionController.pauseForLifecycle(active.token);
  }

  Future<void> resumeAfterLifecycle() async {
    final active = _active;
    if (active == null) return;
    final token = active.clock.resume();
    if (token != null) active.clockToken = token;
    await audioController?.resumeAfterLifecycle();
    await executionController.resumeAfterLifecycle(active.token);
  }

  Future<void> _prepareTerminal(_RuntimePresentationActiveRun active) async {
    if (!_isCurrent(active)) return;
    _generation += 1;
    onFrame(active.request, null);
    await audioController?.releaseAll();
    await _beforeTerminal();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await cancelActive(reason: RuntimePresentationCancellationReason.disposed);
    _disposed = true;
    await audioController?.dispose();
    await executionController.dispose();
  }

  bool _isCurrent(_RuntimePresentationActiveRun active) =>
      !_disposed &&
      identical(_active, active) &&
      active.generation == _generation;
}

enum _CueLoopDirective { proceed, abort, republish }

final class _RuntimePresentationActiveRun {
  _RuntimePresentationActiveRun({
    required this.request,
    required this.token,
    required this.clock,
    required this.clockToken,
    required this.generation,
  });

  final ScenePresentationCinematicRuntimeRequest request;
  final RuntimePresentationRunToken token;
  final PresentationPlaybackClock clock;
  int clockToken;
  final int generation;
  String? videoMediaId;
  PresentationHoldTrackPolicy videoHoldPolicy =
      PresentationHoldTrackPolicy.frozen;
  int publishedPlayheadUs = -1;
  int nextCueSequence = 1;
  final Set<String> triggeredMarkerIds = <String>{};
  final PresentationCueOutcomeGate cueOutcomeGate = PresentationCueOutcomeGate();
  final PresentationTransitionBudget transitionBudget =
      PresentationTransitionBudget();
}

PresentationExecutionCorrelation _correlation(
  ScenePresentationCinematicRuntimeRequest request,
) =>
    PresentationExecutionCorrelation(
      runId: request.requestId,
      projectRevision: request.projectRevision,
      assetId: buildPresentationExecutionAssetCorrelationId(
        request.presentationCinematicId,
      ),
      contentHash: request.contentHash,
    );

String _defaultVisualMediaResolver(
  ScenePresentationCinematicRuntimeRequest _,
  PresentationVisualFrameClip clip,
) =>
    clip.resourceId;

Stream<int> _systemFrameDeltas(int durationUs) async* {
  final stopwatch = Stopwatch()..start();
  var previousUs = 0;
  while (previousUs < durationUs) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final nowUs = stopwatch.elapsedMicroseconds;
    yield nowUs - previousUs;
    previousUs = nowUs;
  }
}

Future<void> _noTerminalBarrier() async {}
