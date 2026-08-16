import 'dart:async';

import 'package:map_core/map_core.dart';

import '../application/scene_runtime/scene_presentation_cinematic_runtime_awaitable_adapter.dart';
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
    RuntimePresentationFrameDeltas? frameDeltas,
    RuntimePresentationVisualMediaResolver? resolveVisualMediaId,
    RuntimePresentationBeforeTerminal? beforeTerminal,
  })  : _frameDeltas = frameDeltas ?? _systemFrameDeltas,
        _resolveVisualMediaId =
            resolveVisualMediaId ?? _defaultVisualMediaResolver,
        _beforeTerminal = beforeTerminal ?? _noTerminalBarrier;

  final RuntimePresentationExecutionController executionController;
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
    if (!_isCurrent(active)) return false;
    final frame = _evaluator.evaluate(
      active.request.asset,
      timeUs: active.clock.playheadUs,
    );
    if (!await _synchronizeVideo(active, frame)) return false;
    if (!_isCurrent(active)) return false;
    onFrame(active.request, frame);
    if (!await _runInteractionCues(active)) return false;
    return true;
  }

  Future<bool> _runInteractionCues(
    _RuntimePresentationActiveRun active,
  ) async {
    final handler = active.request.onInteractionCue;
    final currentPlayheadUs = active.clock.playheadUs;
    if (handler == null) {
      active.publishedPlayheadUs = currentPlayheadUs;
      return true;
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
      await handler(marker.$2);
      if (!_isCurrent(active)) return false;
    }
    return true;
  }

  Future<bool> _synchronizeVideo(
    _RuntimePresentationActiveRun active,
    PresentationFrame frame,
  ) async {
    String? videoMediaId;
    for (final visual in frame.visuals) {
      final mediaId = _resolveVisualMediaId(active.request, visual);
      final media = executionController.mediaController.catalog.find(mediaId);
      if (media?.kind == ProjectMediaKind.video) {
        videoMediaId = mediaId;
        break;
      }
    }
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
    await executionController.pauseForLifecycle(active.token);
  }

  Future<void> resumeAfterLifecycle() async {
    final active = _active;
    if (active == null) return;
    final token = active.clock.resume();
    if (token != null) active.clockToken = token;
    await executionController.resumeAfterLifecycle(active.token);
  }

  Future<void> _prepareTerminal(_RuntimePresentationActiveRun active) async {
    if (!_isCurrent(active)) return;
    _generation += 1;
    onFrame(active.request, null);
    await _beforeTerminal();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await cancelActive(reason: RuntimePresentationCancellationReason.disposed);
    _disposed = true;
    await executionController.dispose();
  }

  bool _isCurrent(_RuntimePresentationActiveRun active) =>
      !_disposed &&
      identical(_active, active) &&
      active.generation == _generation;
}

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
  int publishedPlayheadUs = -1;
  final Set<String> triggeredMarkerIds = <String>{};
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
