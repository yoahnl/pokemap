import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'presentation_frame_renderer.dart';
import 'presentation_video_playback_driver.dart';

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
    PresentationStudioVideoPlayback? videoPlayback,
    this.continuityToleranceUs = 400000,
  })  : mediaUris = Map<String, Uri>.unmodifiable(mediaUris),
        _mixer = audioMixer ?? RuntimeAudioMixer(),
        _video = videoPlayback ?? VideoPlayerPresentationPlaybackDriver() {
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
  final PresentationStudioVideoPlayback _video;
  late final RuntimePresentationAudioController _audio;
  _StudioActiveVideo? _activeVideo;

  Future<void> _pending = Future<void>.value();
  _StudioMediaRequest? _queued;
  int? _lastFrameTimeUs;
  bool _suspended = false;
  bool _disposed = false;
  String? _diagnostic;
  String? _frameDiagnostic;

  /// The audio sources the device has already refused.
  ///
  /// The media store is content-addressed, so a file the platform cannot open
  /// will never become openable. Without this the plan re-issues the same
  /// start on the next synchronisation — sixty times a second while a preview
  /// runs — and hammers the audio device for a file it has already rejected.
  final Set<String> _unplayable = <String>{};
  String? _refusedAudioSignature;
  String? _refusedAudioDiagnostic;

  /// Completes once every synchronisation asked for so far has been applied.
  Future<void> get settled => _pending;

  /// The picture of [resourceId], when that media is the montage's live video.
  ///
  /// A montage shows at most one moving picture at a time, like the runtime.
  /// Every other visual keeps its poster, which is what the content port
  /// resolves on its own.
  Widget? videoFor(String resourceId) {
    final active = _activeVideo;
    if (active == null || active.resourceId != resourceId) return null;
    return _video.buildVideo(active.handle);
  }

  /// The audio sources this sink has stopped trying to open.
  Set<String> get unplayableResourceIds => Set<String>.unmodifiable(_unplayable);

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
      _refusedAudioSignature = null;
      _refusedAudioDiagnostic = null;
      await _releaseVideo();
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
    _enqueue(() async {
      await _releaseVideo();
      await _audio.dispose();
    });
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
      // One verdict per frame: audio and video are applied together, and a
      // later success must not erase what an earlier failure reported.
      _frameDiagnostic = null;
      await _apply(current);
      _setDiagnostic(_frameDiagnostic);
    });
  }

  Future<void> _apply(_StudioMediaRequest request) async {
    final timeUs = request.frame?.timeUs;
    final scrubbed = _scrubbed(timeUs);
    _lastFrameTimeUs = timeUs;

    if (!request.running) {
      await _guard(() => _applyVideo(request, scrubbed: scrubbed));
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
    await _synchronizeAudio(request);
    await _guard(() => _applyVideo(request, scrubbed: scrubbed));
  }

  Future<void> _synchronizeAudio(_StudioMediaRequest request) async {
    final signature = _audioSignatureOf(request.frame);
    if (signature == _refusedAudioSignature) {
      // The exact same set of sources the device just refused. Asking again
      // changes nothing, so the frame plays what it can and stays quiet — but
      // it keeps saying why, otherwise a silent montage looks like a montage
      // with nothing to play.
      _frameDiagnostic ??= _refusedAudioDiagnostic;
      return;
    }
    final before = _frameDiagnostic;
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
    if (identical(before, _frameDiagnostic)) {
      _refusedAudioSignature = null;
      _refusedAudioDiagnostic = null;
      return;
    }
    _refusedAudioSignature = signature;
    _refusedAudioDiagnostic = _frameDiagnostic;
    _unplayable.addAll(_audioResourcesOf(request.frame));
  }

  Set<String> _audioResourcesOf(PresentationFrame? frame) => <String>{
        for (final clip in frame?.audio ?? const <PresentationAudioFrameClip>[])
          clip.resourceId,
      };

  String _audioSignatureOf(PresentationFrame? frame) =>
      (_audioResourcesOf(frame).toList()..sort()).join('|');

  /// Keeps at most one decoder alive on the frame's topmost video clip.
  ///
  /// The runtime allows a single active decoder and the montage holds to that:
  /// an author must not discover in game that two simultaneous videos stutter.
  Future<void> _applyVideo(
    _StudioMediaRequest request, {
    required bool scrubbed,
  }) async {
    final clip = _videoClipOf(request.frame);
    if (clip == null) {
      await _releaseVideo();
      return;
    }
    final active = _activeVideo;
    if (active == null || active.resourceId != clip.resourceId) {
      await _releaseVideo();
      final media = catalog.find(clip.resourceId);
      if (media == null) return;
      final handle = await _video.prepare(
        _resolveMediaUri(media),
        initialVolume: _mixer.mix.volumeFor(RuntimeAudioRoute.cinematicMusic),
      );
      _activeVideo = _StudioActiveVideo(
        resourceId: clip.resourceId,
        clipId: clip.clipId,
        handle: handle,
        playing: false,
      );
      await _video.seek(handle, Duration(microseconds: clip.elapsedUs));
      await _setVideoPlaying(request.running);
      _notifyPicture();
      return;
    }
    // A decoder runs on the same wall clock as the montage, so it only has to
    // be told where to jump: entering the clip, scrubbing, or resuming after
    // a pause that let the playhead move on without it.
    if (scrubbed || (request.running && !active.playing)) {
      await _video.seek(
        active.handle,
        Duration(microseconds: clip.elapsedUs),
      );
    }
    await _setVideoPlaying(request.running);
  }

  Future<void> _setVideoPlaying(bool playing) async {
    final active = _activeVideo;
    if (active == null || active.playing == playing) return;
    active.playing = playing;
    await (playing ? _video.play(active.handle) : _video.pause(active.handle));
  }

  Future<void> _releaseVideo() async {
    final active = _activeVideo;
    if (active == null) return;
    _activeVideo = null;
    _notifyPicture();
    try {
      await _video.dispose(active.handle);
    } on Object {
      // Losing a decoder must never take the montage down with it.
    }
  }

  /// The clip whose picture the montage shows: the topmost active video.
  PresentationVisualFrameClip? _videoClipOf(PresentationFrame? frame) {
    if (frame == null) return null;
    PresentationVisualFrameClip? candidate;
    for (final clip in frame.visuals) {
      if (catalog.find(clip.resourceId)?.kind != ProjectMediaKind.video) {
        continue;
      }
      if (candidate == null || clip.zIndex >= candidate.zIndex) {
        candidate = clip;
      }
    }
    return candidate;
  }

  void _notifyPicture() {
    if (!_disposed) notifyListeners();
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
    } on RuntimePresentationAudioFailure catch (failure) {
      _frameDiagnostic ??= failure.diagnosticCode;
      await _audio.releaseAll().onError((_, __) {});
    } on Object catch (error) {
      _frameDiagnostic ??= '$error';
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

final class _StudioActiveVideo {
  _StudioActiveVideo({
    required this.resourceId,
    required this.clipId,
    required this.handle,
    required this.playing,
  });

  final String resourceId;
  final String clipId;
  final Object handle;
  bool playing;
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
