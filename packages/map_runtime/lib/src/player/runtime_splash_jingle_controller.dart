import 'package:flame_audio/flame_audio.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';

const runtimePremiumSplashJingleAsset = 'premium_splash_jingle.wav';

final class RuntimeSplashJingleController {
  RuntimeSplashJingleController({
    FlameCinematicAudioDriver? driver,
    RuntimeAudioMixer? mixer,
    this.volume = 0.6,
    this.enabled = true,
    this.asset = runtimePremiumSplashJingleAsset,
    this.resumeOnLifecycle = false,
  }) : assert(volume >= 0 && volume <= 1),
       _driver = driver ?? _FlameBundledSplashJingleDriver(),
       _mixer = mixer ?? RuntimeAudioMixer();

  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final double volume;
  final String asset;
  final bool resumeOnLifecycle;
  bool enabled;

  Future<void> _pending = Future<void>.value();
  Object? _handle;
  bool _hasPlayed = false;
  bool _lifecycleActive = true;
  bool _paused = false;
  bool _disposed = false;

  Object? lastFailure;

  bool get hasPlayed => _hasPlayed;
  bool get isPlaying => _handle != null;

  Future<void> playOnce() {
    if (_disposed || _hasPlayed || !enabled) return _pending;
    _hasPlayed = true;
    return _enqueue(_play);
  }

  Future<void> pauseForLifecycle() {
    if (_disposed) return Future<void>.value();
    _lifecycleActive = false;
    return _enqueue(_pause);
  }

  Future<void> resumeFromLifecycle() {
    if (_disposed) return Future<void>.value();
    _lifecycleActive = true;
    return resumeOnLifecycle ? _enqueue(_resume) : _pending;
  }

  Future<void> stop() {
    if (_disposed) return Future<void>.value();
    return _enqueue(_stop);
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    return _enqueue(_stop);
  }

  Future<void> _play() async {
    if (_disposed || !_lifecycleActive) return;
    try {
      final handle = await _driver.play(
        asset,
        volume: _mixer.mix.volumeFor(
          RuntimeAudioRoute.splash,
          sourceVolume: volume,
        ),
        loop: false,
      );
      if (_disposed) {
        await _driver.stop(handle);
        return;
      }
      _handle = handle;
      await _mixer.register(
        channel: handle,
        route: RuntimeAudioRoute.splash,
        sourceVolume: volume,
        setVolume: (nextVolume) => _driver.setVolume(handle, nextVolume),
        applyImmediately: false,
      );
      if (!_lifecycleActive) await _pause();
      lastFailure = null;
    } on Object catch (error) {
      _handle = null;
      lastFailure = error;
    }
  }

  Future<void> _pause() async {
    final driver = _driver;
    final handle = _handle;
    if (!resumeOnLifecycle || driver is! _FlameBundledSplashJingleDriver) {
      await _stop();
      return;
    }
    if (_lifecycleActive || handle == null || _paused) return;
    try {
      _paused = await driver.pause(handle);
    } on Object catch (error) {
      lastFailure = error;
      await _stop();
    }
  }

  Future<void> _resume() async {
    final driver = _driver;
    final handle = _handle;
    if (!_lifecycleActive ||
        !_paused ||
        handle == null ||
        driver is! _FlameBundledSplashJingleDriver) {
      return;
    }
    try {
      await driver.resume(handle);
      _paused = false;
    } on Object catch (error) {
      lastFailure = error;
      await _stop();
    }
  }

  Future<void> _stop() async {
    final handle = _handle;
    _handle = null;
    _paused = false;
    if (handle == null) return;
    _mixer.unregister(handle);
    try {
      await _driver.stop(handle);
    } on Object catch (error) {
      lastFailure = error;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.onError((_, _) {});
    return result;
  }
}

final class _FlameBundledSplashJingleDriver
    implements FlameCinematicAudioDriver {
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final player = AudioPlayer();
    player.audioCache = AudioCache(prefix: '');
    try {
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await player.play(
        AssetSource('packages/map_runtime/assets/audio/$path'),
        volume: volume,
      );
      return player;
    } on Object {
      await player.dispose();
      rethrow;
    }
  }

  @override
  Future<void> setVolume(Object handle, double volume) =>
      (handle as AudioPlayer).setVolume(volume);

  Future<bool> pause(Object handle) async {
    final player = handle as AudioPlayer;
    if (player.state != PlayerState.playing) return false;
    await player.pause();
    return true;
  }

  Future<void> resume(Object handle) => (handle as AudioPlayer).resume();

  @override
  Future<void> stop(Object handle) async {
    final player = handle as AudioPlayer;
    await player.stop();
    await player.dispose();
  }
}
