import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'presentation_frame_renderer.dart';

/// Plays the media of an evaluated Presentation frame under a montage clock.
///
/// The Studio owns its own playhead: it scrubs, steps a frame at a time and
/// pauses wherever the author stops. The runtime never does any of that, so
/// the runtime surface controller — which drives its own clock — cannot be
/// reused as is. What is reused is everything below it: the pure audio plan of
/// [PresentationAudioOrientation], the runtime audio controller with its
/// mixer, buses, fades and ducking, and the runtime video driver. This class
/// owns nothing but the mapping from "here is the frame, and the clock is
/// running or not" onto that stack, so an author hears and sees what a player
/// will.
///
/// Only [synchronize] is called from the build path, sixty times a second
/// while a preview runs. It never awaits: work is serialised internally and a
/// superseded request is dropped rather than queued, so a slow device cannot
/// build a backlog of stale commands.
final class PresentationStudioMediaSink extends ChangeNotifier {
  PresentationStudioMediaSink({
    required this.catalog,
    required Map<String, Uri> mediaUris,
    required this.targetPlatform,
    RuntimePresentationAudioDriver? audioDriver,
    RuntimeAudioMixer? audioMixer,
    this.continuityToleranceUs = 400000,
  })  : mediaUris = Map<String, Uri>.unmodifiable(mediaUris),
        _mixer = audioMixer ?? RuntimeAudioMixer() {
    _audio = RuntimePresentationAudioController(
      catalog: catalog,
      resolveUri: _resolveMediaUri,
      driver: audioDriver ?? FlameRuntimePresentationAudioDriver(),
      mixer: _mixer,
    );
  }

  final ProjectMediaCatalog catalog;
  final Map<String, Uri> mediaUris;
  final PresentationMediaTargetPlatform targetPlatform;

  /// How far the playhead may move between two synchronisations before the
  /// jump is read as a scrub rather than as elapsed time.
  ///
  /// A tick moves the playhead by one frame; dragging the playhead moves it by
  /// whatever the author grabbed. Sources are position-preserving, so a scrub
  /// has to release them and let the plan restart each one at the new instant
  /// — otherwise the music keeps playing from where the author no longer is.
  final int continuityToleranceUs;

  final RuntimeAudioMixer _mixer;
  late final RuntimePresentationAudioController _audio;

  Future<void> _pending = Future<void>.value();
  _StudioMediaRequest? _queued;
  int? _lastFrameTimeUs;
  bool _suspended = false;
  bool _disposed = false;
  String? _diagnostic;

  /// Completes once every synchronisation asked for so far has been applied.
  Future<void> get settled => _pending;

  /// Why the frame could not be played, when it could not.
  ///
  /// A montage must stay usable with a broken reference: a missing media is
  /// reported here and leaves the rest of the frame playing, rather than
  /// throwing out of a build.
  String? get diagnostic => _diagnostic;

  /// Applies [frame] to the audio device.
  ///
  /// [running] is the montage clock, not the transport button: a paused
  /// preview suspends its sources position-preserving so resuming does not
  /// restart a loop audibly.
  void synchronize({
    required PresentationCinematicAsset asset,
    required PresentationFrame? frame,
    required PresentationFrameOrientation orientation,
    required bool running,
  }) {
    if (_disposed) return;
    _queued = _StudioMediaRequest(
      asset: asset,
      frame: frame,
      orientation: orientation,
      running: running,
    );
    _drain();
  }

  /// Stops every source and forgets where the playhead was.
  Future<void> release() {
    _queued = null;
    return _enqueue(() async {
      _suspended = false;
      _lastFrameTimeUs = null;
      await _audio.releaseAll();
    });
  }

  @override
  void dispose() {
    if (_disposed) {
      super.dispose();
      return;
    }
    _disposed = true;
    _queued = null;
    _enqueue(_audio.dispose);
    super.dispose();
  }

  void _drain() {
    final request = _queued;
    if (request == null) return;
    _enqueue(() async {
      // Only the latest request matters: a preview publishes a frame every
      // vsync, and applying a superseded one would fight the current state.
      final current = _queued;
      if (current == null) return;
      _queued = null;
      await _apply(current);
    });
  }

  Future<void> _apply(_StudioMediaRequest request) async {
    final timeUs = request.frame?.timeUs;
    final scrubbed = _scrubbed(timeUs);
    _lastFrameTimeUs = timeUs;

    if (!request.running) {
      // Scrubbing while paused makes the suspended sources worthless: they
      // hold a position the author has left. Releasing them means the next
      // play starts the frame where the playhead now is.
      if (scrubbed) {
        _suspended = false;
        await _guard(_audio.releaseAll);
        return;
      }
      if (_suspended) return;
      _suspended = true;
      await _guard(_audio.pauseForLifecycle);
      return;
    }

    if (scrubbed) {
      _suspended = false;
      await _guard(_audio.releaseAll);
    } else if (_suspended) {
      _suspended = false;
      await _guard(_audio.resumeAfterLifecycle);
    }
    await _guard(
      () => _audio.synchronize(
        request.asset,
        request.frame,
        orientation: switch (request.orientation) {
          PresentationFrameOrientation.landscape =>
            PresentationAudioOrientation.landscape,
          PresentationFrameOrientation.portrait =>
            PresentationAudioOrientation.portrait,
        },
      ),
    );
  }

  /// Whether the playhead jumped rather than elapsed.
  bool _scrubbed(int? timeUs) {
    final previous = _lastFrameTimeUs;
    if (previous == null || timeUs == null) return false;
    return timeUs < previous || timeUs - previous > continuityToleranceUs;
  }

  /// Runs one media operation, turning a failure into a reportable diagnostic.
  ///
  /// A montage that throws out of a frame is worse than a silent one: the
  /// canvas would lose the whole preview over a single missing file.
  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
      _setDiagnostic(null);
    } on RuntimePresentationAudioFailure catch (failure) {
      _setDiagnostic(failure.diagnosticCode);
      await _audio.releaseAll().onError((_, __) {});
    } on Object catch (error) {
      _setDiagnostic('$error');
      await _audio.releaseAll().onError((_, __) {});
    }
  }

  void _setDiagnostic(String? value) {
    if (_diagnostic == value) return;
    _diagnostic = value;
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.onError((_, __) {});
    return result;
  }

  Uri _resolveMediaUri(ProjectMediaAsset media) {
    final uri = mediaUris[media.id];
    if (uri == null || uri.scheme != 'file') {
      throw StateError('Presentation media ${media.id} is missing.');
    }
    return uri;
  }
}

final class _StudioMediaRequest {
  const _StudioMediaRequest({
    required this.asset,
    required this.frame,
    required this.orientation,
    required this.running,
  });

  final PresentationCinematicAsset asset;
  final PresentationFrame? frame;
  final PresentationFrameOrientation orientation;
  final bool running;
}
