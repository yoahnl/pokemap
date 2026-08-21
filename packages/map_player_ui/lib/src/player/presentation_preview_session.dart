import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'presentation_frame_renderer.dart';
import 'runtime_presentation_frame_surface.dart';
import 'runtime_presentation_session_runtime.dart';
import 'runtime_presentation_surface_controller.dart';

enum PresentationPreviewStatus {
  idle,
  running,
  completed,
  cancelled,
  failed,
}

/// What a preview surface is allowed to know about a running journey.
///
/// The Studio talks to this and never to the runtime controller directly, so
/// the surface can be driven by a scripted double in a widget test while the
/// real journey keeps its own end-to-end parity proof.
abstract interface class PresentationPreviewController implements Listenable {
  PresentationPreviewStatus get status;

  SceneInteractionRequest? get pendingRequest;

  NewGameDraft? get resultDraft;

  Object? get failure;

  bool get isRunning;

  ValueListenable<RuntimePresentationFrameSnapshot?> get frames;

  PresentationFrameContentPort get contentPort;

  PresentationFrameOrientation get orientation;

  void setOrientation(PresentationFrameOrientation value);

  Future<void> run({
    required ProjectManifest project,
    required String projectRootDirectory,
    required String projectRevision,
    required String sceneId,
    required NewGameDraft sample,
    required String runId,
  });

  SceneInteractionResolution resolve(SceneInteractionResult result);

  Future<void> cancel();

  Future<void> close();
}

/// One authored Presentation journey, executed for an author instead of a
/// player — BETA-CIN-080.
///
/// Nothing here is a preview engine. The runner, the evaluator, the playback
/// clock, the renderer contract and the structured interaction port are the
/// player's own: this class only owns the wiring and the lifetime, so a Studio
/// preview cannot drift from the installed runtime. The sample draft lives in
/// memory and is never persisted.
final class PresentationPreviewSession extends ChangeNotifier
    implements PresentationPreviewController {
  PresentationPreviewSession({
    required this.runtimeSourceId,
    required ProjectMediaCatalog catalog,
    required Map<String, Uri> mediaUris,
    required PresentationMediaTargetPlatform targetPlatform,
    required bool reducedMotion,
    RuntimeAudioMixer? audioMixer,
    RuntimePresentationVideoPlaybackDriver? videoDriver,
    RuntimePresentationFrameDeltas? frameDeltas,
  }) : _runtime = RuntimePresentationSessionRuntime(
          runtimeSourceId: runtimeSourceId,
          catalog: catalog,
          mediaUris: mediaUris,
          targetPlatform: targetPlatform,
          audioMixer: audioMixer ?? RuntimeAudioMixer(),
          reducedMotion: reducedMotion,
          videoDriver: videoDriver,
          frameDeltas: frameDeltas,
        );

  final String runtimeSourceId;
  final RuntimePresentationSessionRuntime _runtime;

  HeadlessSceneInteractionPort? _interactions;
  StreamSubscription<SceneInteractionRequest>? _requestSubscription;
  int _generation = 0;
  bool _closed = false;

  var _status = PresentationPreviewStatus.idle;
  SceneInteractionRequest? _pendingRequest;
  NewGameDraft? _resultDraft;
  Object? _failure;

  @override
  PresentationPreviewStatus get status => _status;

  /// The interaction the journey is waiting on, rendered by the player's own
  /// surface rather than a Studio replica.
  @override
  SceneInteractionRequest? get pendingRequest => _pendingRequest;

  /// The draft the journey produced — what the authored Scene actually wrote.
  @override
  NewGameDraft? get resultDraft => _resultDraft;

  @override
  Object? get failure => _failure;

  /// Frames, published by the same controller the player renders.
  @override
  ValueListenable<RuntimePresentationFrameSnapshot?> get frames =>
      _runtime.controller;

  RuntimePresentationSurfaceController get controller => _runtime.controller;

  @override
  PresentationFrameContentPort get contentPort => _runtime.controller;

  @override
  PresentationFrameOrientation get orientation =>
      _runtime.controller.orientation;

  @override
  void setOrientation(PresentationFrameOrientation value) =>
      _runtime.controller.setOrientation(value);

  @override
  bool get isRunning => _status == PresentationPreviewStatus.running;

  /// Runs [sceneId] once. A second call supersedes the first: the previous
  /// generation can no longer publish, which is what makes a late callback,
  /// a route change or a project reload safe.
  @override
  Future<void> run({
    required ProjectManifest project,
    required String projectRootDirectory,
    required String projectRevision,
    required String sceneId,
    required NewGameDraft sample,
    required String runId,
  }) async {
    if (_closed) {
      throw StateError('The preview session is closed.');
    }
    await cancel();
    final generation = ++_generation;
    final interactions = HeadlessSceneInteractionPort();
    _interactions = interactions;
    _requestSubscription = interactions.requests.listen((request) {
      if (generation != _generation) return;
      _pendingRequest = request;
      notifyListeners();
    });
    _status = PresentationPreviewStatus.running;
    _pendingRequest = null;
    _resultDraft = null;
    _failure = null;
    notifyListeners();

    try {
      final draft = await _runtime
          .buildPreSessionRunner(
            project: project,
            projectRootDirectory: projectRootDirectory,
            projectRevision: projectRevision,
            sceneId: sceneId,
          )
          .run(runId: runId, draft: sample, interactions: interactions);
      _publish(generation, draft: draft);
    } on Object catch (error) {
      _publish(generation, failure: error);
    }
  }

  /// The single seam where a run may become visible. A superseded generation
  /// publishes nothing — that one guard is what makes a late callback, a route
  /// change and a project reload safe, whether the run ended well or badly.
  void _publish(int generation, {NewGameDraft? draft, Object? failure}) {
    if (generation != _generation) return;
    _resultDraft = draft;
    _failure = failure;
    _status = draft != null
        ? PresentationPreviewStatus.completed
        : PresentationPreviewStatus.failed;
    _pendingRequest = null;
    _releaseInteractions();
    notifyListeners();
  }

  /// Answers the pending interaction through the port the player uses, so
  /// validation, staleness and terminal rules are the runtime's.
  @override
  SceneInteractionResolution resolve(SceneInteractionResult result) {
    final interactions = _interactions;
    if (interactions == null) {
      return SceneInteractionResolution(
        status: SceneInteractionResolutionStatus.unknownRequest,
      );
    }
    final resolution = interactions.resolve(result);
    if (resolution.status == SceneInteractionResolutionStatus.accepted) {
      _pendingRequest = null;
      notifyListeners();
    }
    return resolution;
  }

  /// Abandons the running journey and every resource it holds.
  ///
  /// The returned future completes once the presentation player has actually
  /// stopped. Starting a new run before that point races the teardown and the
  /// next playback fails, so [run] awaits this.
  @override
  Future<void> cancel() async {
    if (_status != PresentationPreviewStatus.running) {
      _releaseInteractions();
      return;
    }
    _generation += 1;
    // Closing the port already cancels every pending interaction with the
    // disposed reason, so the runner unblocks without a second cancel call.
    _releaseInteractions();
    _pendingRequest = null;
    _status = PresentationPreviewStatus.cancelled;
    notifyListeners();
    await _runtime.controller.cancelActive();
  }

  void _releaseInteractions() {
    unawaited(_requestSubscription?.cancel());
    _requestSubscription = null;
    _interactions?.close();
    _interactions = null;
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }

  /// Closes the session for good: no timer, decoder, audio handle or frame
  /// survives it.
  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation += 1;
    _releaseInteractions();
    _pendingRequest = null;
    await _runtime.close();
  }
}
