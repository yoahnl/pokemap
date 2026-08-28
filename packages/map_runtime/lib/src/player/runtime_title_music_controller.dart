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
  })  : _driver = driver ?? FlameAudioCinematicRuntimeDriver(),
        _mixer = mixer ?? RuntimeAudioMixer(),
        _stopTimeout = stopTimeout;

  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final Duration _stopTimeout;

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
  }) {
    if (_disposed) return Future<void>.value();
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
    return _enqueue(_stop);
  }

  Future<void> _applyDesiredState() async {
    final path = _desiredPath;
    final shouldPlay =
        !_disposed && _lifecycleActive && _titleVisible && path != null;
    if (!shouldPlay) {
      await _stop();
      return;
    }
    if (_handle != null && _playingPath == path) {
      try {
        await _mixer.updateSourceVolume(_handle!, _desiredVolume);
        lastFailure = null;
      } on Object catch (error) {
        lastFailure = error;
        await _stop();
      }
      return;
    }
    await _stop();
    try {
      final handle = await _driver.play(
        path,
        volume: _mixer.mix.volumeFor(
          RuntimeAudioRoute.title,
          sourceVolume: _desiredVolume,
        ),
        loop: true,
      );
      _handle = handle;
      _playingPath = path;
      await _mixer.register(
        channel: handle,
        route: RuntimeAudioRoute.title,
        sourceVolume: _desiredVolume,
        setVolume: (volume) => _driver.setVolume(handle, volume),
        applyImmediately: false,
      );
      lastFailure = null;
    } on Object catch (error) {
      _handle = null;
      _playingPath = null;
      lastFailure = error;
    }
  }

  Future<void> _stop() async {
    final handle = _handle;
    _handle = null;
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
