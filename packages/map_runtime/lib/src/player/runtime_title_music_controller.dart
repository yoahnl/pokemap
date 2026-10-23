import 'dart:async';

import 'package:map_core/map_core.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';

/// Keeps optional installed title music aligned with runtime player state.
///
/// Playback failures are retained as diagnostics and never make the title
/// screen unavailable.
final class RuntimeTitleMusicController {
  RuntimeTitleMusicController({
    FlameCinematicAudioDriver? driver,
    RuntimeAudioMixer? mixer,
    Duration stopTimeout = const Duration(seconds: 1),
  }) : _driver = driver ?? FlameAudioCinematicRuntimeDriver(),
       _mixer = mixer ?? RuntimeAudioMixer(),
       _stopTimeout = stopTimeout;

  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final Duration _stopTimeout;

  final StreamController<void> _completions =
      StreamController<void>.broadcast();
  StreamSubscription<void>? _completionSubscription;
  ProjectTitleMusicEndBehavior _endBehavior = ProjectTitleMusicEndBehavior.loop;
  ProjectTitleMusicEndBehavior? _playingEndBehavior;
  int? _playingDesiredGeneration;
  bool _paused = false;
  bool _finished = false;
  bool _completionPending = false;
  int _playbackGeneration = 0;
  int _desiredGeneration = 0;

  Stream<void> get completions => _completions.stream;

  Future<void> _pending = Future<void>.value();
  Object? _handle;
  String? _playingPath;
  String? _desiredPath;
  double _desiredVolume = 0.8;
  bool _titleVisible = false;
  bool _lifecycleActive = true;
  bool _disposed = false;

  Object? lastFailure;

  bool get isPlaying => _handle != null;

  Future<void> update({
    required String? path,
    required bool titleVisible,
    double volume = 0.8,
    ProjectTitleMusicEndBehavior endBehavior =
        ProjectTitleMusicEndBehavior.loop,
  }) {
    if (_disposed) return Future<void>.value();
    if (_desiredPath != path || _endBehavior != endBehavior || !titleVisible) {
      _desiredGeneration++;
      _finished = false;
      _completionPending = false;
    }
    _endBehavior = endBehavior;
    _desiredPath = path;
    _titleVisible = titleVisible;
    _desiredVolume = volume.clamp(0.0, 1.0);
    return _enqueue(_applyDesiredState);
  }

  Future<void> pauseForLifecycle() {
    if (_disposed) return Future<void>.value();
    _lifecycleActive = false;
    return _enqueue(_applyDesiredState);
  }

  Future<void> resumeFromLifecycle() {
    if (_disposed) return Future<void>.value();
    _lifecycleActive = true;
    return _enqueue(_applyDesiredState);
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    _titleVisible = false;
    return _enqueue(() async {
      await _stop();
      await _completions.close();
    });
  }

  Future<void> _applyDesiredState() async {
    final path = _desiredPath;
    final desiredGeneration = _desiredGeneration;
    final shouldPlay = !_disposed && _titleVisible && path != null;
    if (!shouldPlay) {
      await _stop();
      return;
    }
    if (_finished) {
      if (_lifecycleActive && _completionPending) {
        _completionPending = false;
        _completions.add(null);
      }
      return;
    }
    if (_handle != null &&
        _playingPath == path &&
        _playingEndBehavior == _endBehavior &&
        _playingDesiredGeneration == _desiredGeneration) {
      try {
        final driver = _driver;
        if (driver is FlameCinematicAudioPausableDriver) {
          if (!_lifecycleActive && !_paused) {
            await (driver as FlameCinematicAudioPausableDriver).pause(_handle!);
            _paused = true;
          } else if (_lifecycleActive && _paused) {
            await (driver as FlameCinematicAudioPausableDriver).resume(
              _handle!,
            );
            _paused = false;
          }
        } else if (!_lifecycleActive) {
          await _stop();
          return;
        }
        await _mixer.updateSourceVolume(_handle!, _desiredVolume);
        lastFailure = null;
      } on Object catch (error) {
        lastFailure = error;
        await _stop();
      }
      return;
    }
    await _stop();
    if (!_lifecycleActive || _disposed || desiredGeneration != _desiredGeneration) return;
    final generation = ++_playbackGeneration;
    final endBehavior = _endBehavior;
    try {
      final handle = await _driver.play(
        path,
        volume: _mixer.mix.volumeFor(
          RuntimeAudioRoute.title,
          sourceVolume: _desiredVolume,
        ),
        loop: endBehavior == ProjectTitleMusicEndBehavior.loop,
      );
      _handle = handle;
      _playingPath = path;
      _playingEndBehavior = endBehavior;
      _playingDesiredGeneration = desiredGeneration;
      await _mixer.register(
        channel: handle,
        route: RuntimeAudioRoute.title,
        sourceVolume: _desiredVolume,
        setVolume: (volume) => _driver.setVolume(handle, volume),
        applyImmediately: false,
      );
      final driver = _driver;
      if (endBehavior == ProjectTitleMusicEndBehavior.replayIntro &&
          driver is FlameCinematicAudioLoopDriver) {
        _completionSubscription = (driver as FlameCinematicAudioLoopDriver)
            .onComplete(handle)
            .listen(
              (_) => unawaited(
                _enqueue(
                  () => _complete(generation, desiredGeneration, handle),
                ),
              ),
              onError: (Object error) => unawaited(
                _enqueue(() async {
                  if (generation != _playbackGeneration || desiredGeneration != _desiredGeneration || _disposed) return;
                  lastFailure = error;
                  _finished = true;
                  await _stop();
                }),
              ),
            );
      }
      lastFailure = null;
    } on Object catch (error) {
      await _stop();
      if (desiredGeneration != _desiredGeneration || _disposed) return;
      _finished = true;
      lastFailure = error;
    }
  }

  Future<void> _complete(
    int generation,
    int desiredGeneration,
    Object handle,
  ) async {
    if (_disposed ||
        generation != _playbackGeneration ||
        desiredGeneration != _desiredGeneration ||
        !identical(handle, _handle) ||
        !_titleVisible ||
        _desiredPath != _playingPath)
      return;
    _finished = true;
    await _stop();
    if (_disposed || !_titleVisible || desiredGeneration != _desiredGeneration)
      return;
    if (_lifecycleActive) {
      _completions.add(null);
    } else {
      _completionPending = true;
    }
  }

  Future<void> _stop() async {
    _playbackGeneration++;
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    final handle = _handle;
    _handle = null;
    _paused = false;
    _playingEndBehavior = null;
    _playingDesiredGeneration = null;
    _playingPath = null;
    if (handle == null) return;
    _mixer.unregister(handle);
    try {
      await _driver.stop(handle).timeout(_stopTimeout);
    } on Object catch (error) {
      lastFailure = error;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.onError((_, __) {});
    return result;
  }
}
