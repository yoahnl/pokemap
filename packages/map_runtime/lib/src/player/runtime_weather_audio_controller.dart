import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';
import 'runtime_music_service.dart';

final class RuntimeWeatherAudioController {
  RuntimeWeatherAudioController({
    required RuntimeAudioMixer mixer,
    FlameCinematicAudioDriver Function()? driverFactory,
  }) : _rain = RuntimeMusicService(
         mixer: mixer,
         driver: (driverFactory ?? _assetDriver)(),
       ),
       _wind = RuntimeMusicService(
         mixer: mixer,
         driver: (driverFactory ?? _assetDriver)(),
       );

  static const _prefix = 'packages/map_runtime/assets/audio/weather/';
  final RuntimeMusicService _rain, _wind;
  (double, double)? _gains;
  bool _disposed = false;
  Future<void> _pending = Future<void>.value();

  Object? get lastFailure => _rain.lastFailure ?? _wind.lastFailure;

  static FlameCinematicAudioDriver _assetDriver() =>
      FlameAudioCinematicRuntimeDriver(
        playerFactory: () => AudioPlayer()..audioCache = AudioCache(prefix: ''),
        sourceFactory: AssetSource.new,
      );

  Future<void> update(SpatialWeatherSettings settings, {bool indoors = false}) {
    if (_disposed) return _pending;
    final audible =
        settings.active &&
        settings.soundEnabled &&
        (!indoors || settings.indoors);
    final rainLevel = switch (settings.kind) {
      SpatialWeatherKind.drizzle => .25,
      SpatialWeatherKind.rain => .65,
      SpatialWeatherKind.downpour => .9,
      SpatialWeatherKind.storm => 1.0,
      _ => 0.0,
    };
    final next = (
      audible ? rainLevel * settings.intensity * settings.rainVolume : 0.0,
      audible
          ? (settings.windStrength / 2).clamp(0.0, 1.0) *
                settings.intensity *
                settings.windVolume
          : 0.0,
    );
    if (_gains == next) return _pending;
    _gains = next;
    return _pending = Future.wait([
      _rain.update(
        route: RuntimeAudioRoute.ambience,
        path: next.$1 > 0 ? '${_prefix}rain-loop.wav' : null,
        volume: next.$1,
      ),
      _wind.update(
        route: RuntimeAudioRoute.ambience,
        path: next.$2 > 0 ? '${_prefix}wind-loop.wav' : null,
        volume: next.$2,
      ),
    ]);
  }

  Future<void> setSuspended(bool suspended) {
    if (_disposed) return _pending;
    return Future.wait([
      _rain.setSuspended(suspended),
      _wind.setSuspended(suspended),
    ]);
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    return _pending = Future.wait([_rain.dispose(), _wind.dispose()]);
  }
}
