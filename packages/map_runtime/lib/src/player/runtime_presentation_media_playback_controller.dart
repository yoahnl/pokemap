import 'package:map_core/map_core.dart';

import 'runtime_audio_mixer.dart';

enum RuntimePresentationVideoAudioMode { muted, mixerManaged }

enum RuntimePresentationMediaPlaybackStatus {
  idle,
  playingVideo,
  pausedVideo,
  showingPoster,
  failed,
}

abstract final class RuntimePresentationMediaPlaybackDiagnosticCodes {
  static const mediaMissing = PresentationDiagnosticCodes.mediaMissing;
  static const mediaUnsupported = PresentationDiagnosticCodes.mediaUnsupported;
  static const playbackFailed = PresentationDiagnosticCodes.playbackFailed;
}

final class RuntimePresentationMediaPlaybackSnapshot {
  const RuntimePresentationMediaPlaybackSnapshot({
    required this.status,
    this.requestedMediaId,
    this.resolvedMediaId,
    this.videoHandle,
    this.usedFallback = false,
    this.diagnosticCode,
    this.diagnosticSeverity,
    this.diagnosticMessage,
  });

  static const idle = RuntimePresentationMediaPlaybackSnapshot(
    status: RuntimePresentationMediaPlaybackStatus.idle,
  );

  final RuntimePresentationMediaPlaybackStatus status;
  final String? requestedMediaId;
  final String? resolvedMediaId;
  final Object? videoHandle;
  final bool usedFallback;
  final String? diagnosticCode;
  final PresentationDiagnosticSeverity? diagnosticSeverity;
  final String? diagnosticMessage;
}

abstract interface class RuntimePresentationVideoPlaybackDriver {
  Future<Object> prepare(
    Uri source, {
    required double initialVolume,
  });

  Future<void> play(Object handle);

  Future<void> pause(Object handle);

  Future<void> setVolume(Object handle, double volume);

  Future<void> dispose(Object handle);
}

typedef RuntimePresentationMediaUriResolver = Uri Function(
  ProjectMediaAsset media,
);

final class RuntimePresentationMediaPlaybackController {
  RuntimePresentationMediaPlaybackController({
    required this.catalog,
    required this.targetPlatform,
    required this.resolveUri,
    required this.videoDriver,
    RuntimeAudioMixer? audioMixer,
  }) : _audioMixer = audioMixer ?? RuntimeAudioMixer();

  final ProjectMediaCatalog catalog;
  final PresentationMediaTargetPlatform targetPlatform;
  final RuntimePresentationMediaUriResolver resolveUri;
  final RuntimePresentationVideoPlaybackDriver videoDriver;
  final RuntimeAudioMixer _audioMixer;

  static const maximumActiveDecoderCount = 1;
  static const maximumCachedDecoderCount = 0;

  Future<void> _pending = Future<void>.value();
  RuntimePresentationMediaPlaybackSnapshot _snapshot =
      RuntimePresentationMediaPlaybackSnapshot.idle;
  _RuntimePresentationActiveVideo? _activeVideo;
  bool _disposed = false;
  int _generation = 0;

  RuntimePresentationMediaPlaybackSnapshot get snapshot => _snapshot;

  Future<RuntimePresentationMediaPlaybackSnapshot> playVideo(
    String mediaId, {
    RuntimePresentationVideoAudioMode audioMode =
        RuntimePresentationVideoAudioMode.muted,
    double sourceVolume = 1,
  }) {
    if (!sourceVolume.isFinite || sourceVolume < 0 || sourceVolume > 1) {
      return Future<RuntimePresentationMediaPlaybackSnapshot>.error(
        ArgumentError.value(
          sourceVolume,
          'sourceVolume',
          'must be between zero and one',
        ),
      );
    }
    if (_disposed) {
      return Future.value(
        _fail(
          mediaId,
          RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
        ),
      );
    }
    final generation = ++_generation;
    final result = _pending.then(
      (_) => _playVideo(
        mediaId,
        generation: generation,
        audioMode: audioMode,
        sourceVolume: sourceVolume,
      ),
    );
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<RuntimePresentationMediaPlaybackSnapshot> pauseForLifecycle() {
    final result = _pending.then((_) => _suspend(lifecycle: true));
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<RuntimePresentationMediaPlaybackSnapshot> resumeAfterLifecycle() {
    final result = _pending.then((_) => _resume(lifecycle: true));
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  /// Suspends the active video while an interaction cue holds the timeline
  /// — an independent reason from the lifecycle, so answering during a
  /// backgrounded app never resumes anything (BETA-CIN-077).
  Future<RuntimePresentationMediaPlaybackSnapshot> pauseForHold() {
    final result = _pending.then((_) => _suspend(lifecycle: false));
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<RuntimePresentationMediaPlaybackSnapshot> resumeFromHold() {
    final result = _pending.then((_) => _resume(lifecycle: false));
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<void> release() {
    ++_generation;
    final result = _pending.then((_) async {
      await _releaseActiveVideo();
      _snapshot = RuntimePresentationMediaPlaybackSnapshot.idle;
    });
    _pending = result.onError((_, __) {});
    return result;
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    ++_generation;
    final result = _pending.then((_) async {
      await _releaseActiveVideo();
      _snapshot = RuntimePresentationMediaPlaybackSnapshot.idle;
    });
    _pending = result.onError((_, __) {});
    return result;
  }

  Future<RuntimePresentationMediaPlaybackSnapshot> _playVideo(
    String mediaId, {
    required int generation,
    required RuntimePresentationVideoAudioMode audioMode,
    required double sourceVolume,
  }) async {
    if (!_isCurrent(generation)) {
      return _snapshot;
    }
    try {
      await _releaseActiveVideo();
    } on Object {
      return _fail(
        mediaId,
        RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
      );
    }
    final requestedExists = catalog.find(mediaId) != null;
    var currentMediaId = mediaId;
    var usedFallback = false;
    final visited = <String>{};
    while (visited.add(currentMediaId)) {
      final resolution = resolvePresentationMediaForPlatform(
        catalog,
        currentMediaId,
        targetPlatform,
      );
      final resolvedMediaId = resolution.resolvedMediaId;
      if (!resolution.compatible || resolvedMediaId == null) {
        return _fail(
          mediaId,
          requestedExists
              ? RuntimePresentationMediaPlaybackDiagnosticCodes.mediaUnsupported
              : RuntimePresentationMediaPlaybackDiagnosticCodes.mediaMissing,
        );
      }
      final media = catalog.require(resolvedMediaId);
      usedFallback = usedFallback || resolvedMediaId != mediaId;
      if (media.kind == ProjectMediaKind.image ||
          media.kind == ProjectMediaKind.poster) {
        _snapshot = RuntimePresentationMediaPlaybackSnapshot(
          status: RuntimePresentationMediaPlaybackStatus.showingPoster,
          requestedMediaId: mediaId,
          resolvedMediaId: media.id,
          usedFallback: usedFallback,
        );
        return _snapshot;
      }
      if (media.kind != ProjectMediaKind.video) {
        return _fail(
          mediaId,
          RuntimePresentationMediaPlaybackDiagnosticCodes.mediaUnsupported,
        );
      }
      final initialVolume =
          audioMode == RuntimePresentationVideoAudioMode.mixerManaged
              ? _audioMixer.mix.volumeFor(
                  RuntimeAudioRoute.cinematicMusic,
                  sourceVolume: sourceVolume,
                )
              : 0.0;
      Object? handle;
      var registered = false;
      try {
        handle = await videoDriver.prepare(
          resolveUri(media),
          initialVolume: initialVolume,
        );
        if (!_isCurrent(generation)) {
          final staleHandle = handle;
          handle = null;
          await videoDriver.dispose(staleHandle);
          _snapshot = RuntimePresentationMediaPlaybackSnapshot.idle;
          return _snapshot;
        }
        if (audioMode == RuntimePresentationVideoAudioMode.mixerManaged) {
          await _audioMixer.register(
            channel: handle,
            route: RuntimeAudioRoute.cinematicMusic,
            sourceVolume: sourceVolume,
            setVolume: (volume) => videoDriver.setVolume(handle!, volume),
            applyImmediately: false,
          );
          registered = true;
        }
        if (!_isCurrent(generation)) {
          if (registered) _audioMixer.unregister(handle);
          final staleHandle = handle;
          handle = null;
          await videoDriver.dispose(staleHandle);
          _snapshot = RuntimePresentationMediaPlaybackSnapshot.idle;
          return _snapshot;
        }
        await videoDriver.play(handle);
        if (!_isCurrent(generation)) {
          if (registered) _audioMixer.unregister(handle);
          final staleHandle = handle;
          handle = null;
          await videoDriver.dispose(staleHandle);
          _snapshot = RuntimePresentationMediaPlaybackSnapshot.idle;
          return _snapshot;
        }
        _activeVideo = _RuntimePresentationActiveVideo(
          handle: handle,
          mixerManaged: registered,
        );
        _snapshot = RuntimePresentationMediaPlaybackSnapshot(
          status: RuntimePresentationMediaPlaybackStatus.playingVideo,
          requestedMediaId: mediaId,
          resolvedMediaId: media.id,
          videoHandle: handle,
          usedFallback: usedFallback,
        );
        return _snapshot;
      } on Object {
        if (handle != null) {
          if (registered) _audioMixer.unregister(handle);
          final failedHandle = handle;
          handle = null;
          try {
            await videoDriver.dispose(failedHandle);
          } on Object {
            return _fail(
              mediaId,
              RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
            );
          }
        }
        final fallbackMediaId = nextPresentationMediaFallbackId(media);
        if (fallbackMediaId == null) {
          return _fail(
            mediaId,
            RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
          );
        }
        usedFallback = true;
        currentMediaId = fallbackMediaId;
      }
    }
    return _fail(
      mediaId,
      RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  var _suspendedByLifecycle = false;
  var _suspendedByHold = false;

  Future<RuntimePresentationMediaPlaybackSnapshot> _suspend({
    required bool lifecycle,
  }) async {
    final wasSuspended = _suspendedByLifecycle || _suspendedByHold;
    if (lifecycle) {
      _suspendedByLifecycle = true;
    } else {
      _suspendedByHold = true;
    }
    if (wasSuspended) return _snapshot;
    return _pauseActiveVideo();
  }

  Future<RuntimePresentationMediaPlaybackSnapshot> _resume({
    required bool lifecycle,
  }) async {
    if (lifecycle) {
      _suspendedByLifecycle = false;
    } else {
      _suspendedByHold = false;
    }
    if (_suspendedByLifecycle || _suspendedByHold) return _snapshot;
    return _resumeActiveVideo();
  }

  Future<RuntimePresentationMediaPlaybackSnapshot> _pauseActiveVideo() async {
    final active = _activeVideo;
    if (_disposed || active == null || active.paused) return _snapshot;
    try {
      await videoDriver.pause(active.handle);
      active.paused = true;
      _snapshot = RuntimePresentationMediaPlaybackSnapshot(
        status: RuntimePresentationMediaPlaybackStatus.pausedVideo,
        requestedMediaId: _snapshot.requestedMediaId,
        resolvedMediaId: _snapshot.resolvedMediaId,
        videoHandle: active.handle,
        usedFallback: _snapshot.usedFallback,
      );
      return _snapshot;
    } on Object {
      await _releaseActiveVideo();
      return _fail(
        _snapshot.requestedMediaId ?? '',
        RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
      );
    }
  }

  Future<RuntimePresentationMediaPlaybackSnapshot>
      _resumeActiveVideo() async {
    final active = _activeVideo;
    if (_disposed || active == null || !active.paused) return _snapshot;
    try {
      await videoDriver.play(active.handle);
      active.paused = false;
      _snapshot = RuntimePresentationMediaPlaybackSnapshot(
        status: RuntimePresentationMediaPlaybackStatus.playingVideo,
        requestedMediaId: _snapshot.requestedMediaId,
        resolvedMediaId: _snapshot.resolvedMediaId,
        videoHandle: active.handle,
        usedFallback: _snapshot.usedFallback,
      );
      return _snapshot;
    } on Object {
      await _releaseActiveVideo();
      return _fail(
        _snapshot.requestedMediaId ?? '',
        RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
      );
    }
  }

  RuntimePresentationMediaPlaybackSnapshot _fail(String mediaId, String code) {
    _snapshot = RuntimePresentationMediaPlaybackSnapshot(
      status: RuntimePresentationMediaPlaybackStatus.failed,
      requestedMediaId: mediaId,
      diagnosticCode: code,
      diagnosticSeverity: PresentationDiagnosticSeverity.error,
      diagnosticMessage: 'Presentation media is unavailable.',
    );
    return _snapshot;
  }

  Future<void> _releaseActiveVideo() async {
    final active = _activeVideo;
    if (active == null) return;
    _activeVideo = null;
    if (active.mixerManaged) _audioMixer.unregister(active.handle);
    await videoDriver.dispose(active.handle);
  }
}

final class _RuntimePresentationActiveVideo {
  _RuntimePresentationActiveVideo({
    required this.handle,
    required this.mixerManaged,
  });

  final Object handle;
  final bool mixerManaged;
  bool paused = false;
}
