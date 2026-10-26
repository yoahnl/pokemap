import 'dart:async';

import 'package:map_core/map_core.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';

final class RuntimeStormAudioController {
  RuntimeStormAudioController({required this.mixer, required this.driver});
  final RuntimeAudioMixer mixer;
  final FlameCinematicAudioDriver driver;
  Future<void> _pending = Future.value();
  StreamSubscription<void>? _completion;
  Object? _handle, lastFailure;
  double? _previousSeconds;
  int _generation = 0;
  int? _lastEvent;
  bool _enabled = false, _suspended = false, _disposed = false;
  int playedCount = 0;
  double? lastPlayedAtSeconds;
  int? lastVariant;
  bool get isPlaying => _handle != null;

  Future<void> update(
    SpatialWeatherSettings settings, {
    required double seconds,
    bool indoors = false,
  }) {
    if (_disposed) return _pending;
    final enabled =
        settings.active &&
        settings.soundEnabled &&
        settings.lightning &&
        (settings.kind == SpatialWeatherKind.storm ||
            settings.kind == SpatialWeatherKind.hail) &&
        (!indoors || settings.indoors);
    if (!enabled) {
      _previousSeconds = null;
      if (!_enabled) return _pending;
      _enabled = false;
      _generation++;
      return _enqueue(_stop);
    }
    _enabled = true;
    final previous = _previousSeconds;
    _previousSeconds = seconds;
    if (previous == null || seconds < previous) {
      _lastEvent = null;
      if (previous != null) {
        _generation++;
        return _enqueue(_stop);
      }
      return _pending;
    }
    final event = spatialStormEventAt(seconds);
    if (_suspended ||
        event.id == _lastEvent ||
        previous >= event.thunderSeconds ||
        seconds < event.thunderSeconds ||
        seconds - event.thunderSeconds > .5) {
      return _pending;
    }
    _lastEvent = event.id;
    final generation = _generation;
    return _enqueue(
      () => _play(event, settings.intensity, seconds, generation),
    );
  }

  Future<void> _enqueue(Future<void> Function() action) {
    return _pending = _pending.then((_) async {
      try {
        await action();
      } on Object catch (error) {
        lastFailure = error;
        try {
          await _stop();
        } on Object {
          return;
        }
      }
    });
  }

  Future<void> _play(
    SpatialStormEvent event,
    double intensity,
    double seconds,
    int generation,
  ) async {
    if (_disposed || generation != _generation) return;
    await _stop();
    _lastIntensity = intensity;
    final volume = .7 * intensity * event.strength;
    final handle = await driver.play(
      'packages/map_runtime/assets/audio/weather/thunder-${event.soundVariant}.wav',
      volume: _suspended
          ? 0
          : mixer.mix.volumeFor(
              RuntimeAudioRoute.ambience,
              sourceVolume: volume,
            ),
      loop: false,
    );
    if (_disposed || generation != _generation) {
      await driver.stop(handle);
      return;
    }
    _handle = handle;
    await mixer.register(
      channel: this,
      route: RuntimeAudioRoute.ambience,
      sourceVolume: volume,
      setVolume: (value) => driver.setVolume(handle, _suspended ? 0 : value),
    );
    if (_suspended && driver is FlameCinematicAudioPausableDriver) {
      await (driver as FlameCinematicAudioPausableDriver).pause(handle);
    }
    playedCount++;
    lastPlayedAtSeconds = seconds;
    lastVariant = event.soundVariant;
    lastFailure = null;
    if (driver is FlameCinematicAudioLoopDriver) {
      _completion = (driver as FlameCinematicAudioLoopDriver)
          .onComplete(handle)
          .listen((_) {
            unawaited(
              _enqueue(() async {
                if (identical(_handle, handle)) await _stop();
              }),
            );
          });
    }
  }

  Future<void> _stop() async {
    final handle = _handle;
    _handle = null;
    await _completion?.cancel();
    _completion = null;
    mixer.unregister(this);
    if (handle != null) await driver.stop(handle);
  }

  Future<void> setSuspended(bool value) {
    if (_disposed || _suspended == value) return _pending;
    _suspended = value;
    return _enqueue(() async {
      final handle = _handle;
      if (handle == null) return;
      if (driver is FlameCinematicAudioPausableDriver) {
        final pausable = driver as FlameCinematicAudioPausableDriver;
        if (value) {
          await pausable.pause(handle);
        } else {
          await pausable.resume(handle);
        }
      }
      final event = spatialStormEventAt(lastPlayedAtSeconds!);
      await driver.setVolume(
        handle,
        value
            ? 0
            : mixer.mix.volumeFor(
                RuntimeAudioRoute.ambience,
                sourceVolume: .7 * event.strength * _lastIntensity,
              ),
      );
    });
  }

  double _lastIntensity = 1;
  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    _generation++;
    return _enqueue(_stop);
  }
}
