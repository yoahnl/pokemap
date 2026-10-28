import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';
import 'runtime_project_audio_controller.dart';
import 'runtime_music_service.dart';
import 'runtime_weather_loop_driver.dart';
import 'runtime_storm_audio_controller.dart';

final class RuntimeWeatherAudioController {
  RuntimeWeatherAudioController({
    required RuntimeAudioMixer mixer,
    FlameCinematicAudioDriver Function()? driverFactory,
    this.projectAudio,
  }) : _rain = RuntimeMusicService(
         mixer: mixer,
         driver: driverFactory?.call() ?? _loopDriver(projectAudio),
       ),
       _wind = RuntimeMusicService(
         mixer: mixer,
         driver: driverFactory?.call() ?? _loopDriver(projectAudio),
       ),
       _storm = RuntimeStormAudioController(
         mixer: mixer,
         driver:
             driverFactory?.call() ??
             projectAudio?.createDriver() ??
             _nativeDriver(),
         projectAudio: projectAudio,
       );

  static FlameCinematicAudioDriver _loopDriver(
    RuntimeProjectAudioController? audio,
  ) => audio == null
      ? _assetDriver()
      : RuntimeWeatherLoopDriver(
          audio.createDriver(),
          crossfadePath: (path) => path.startsWith('packages/map_runtime/'),
        );

  static const _prefix = 'packages/map_runtime/assets/audio/weather/';
  final RuntimeProjectAudioController? projectAudio;
  final RuntimeMusicService _rain, _wind;
  final RuntimeStormAudioController _storm;
  (double, double)? _gains;
  String? _rainPath, _windPath;
  bool _disposed = false;
  Future<void> _pending = Future<void>.value();
  Future<void>? _stormPending;

  Object? get lastFailure =>
      _rain.lastFailure ?? _wind.lastFailure ?? _storm.lastFailure;
  Map<String, Object?> get diagnostics => {
    'rainPlaying': _rain.isPlaying,
    'windPlaying': _wind.isPlaying,
    'rainGain': _gains?.$1,
    'windGain': _gains?.$2,
    'thunderPlaying': _storm.isPlaying,
    'thunderCount': _storm.playedCount,
    'lastThunderSeconds': _storm.lastPlayedAtSeconds,
    'lastThunderVariant': _storm.lastVariant,
    'failure': lastFailure?.toString(),
  };

  static FlameCinematicAudioDriver _assetDriver() =>
      RuntimeWeatherLoopDriver(_nativeDriver());

  static FlameCinematicAudioDriver _nativeDriver() =>
      FlameAudioCinematicRuntimeDriver(
        playerFactory: () => AudioPlayer()..audioCache = AudioCache(prefix: ''),
        sourceFactory: AssetSource.new,
      );

  Future<void> update(
    SpatialWeatherSettings settings, {
    bool indoors = false,
    double seconds = 0,
  }) {
    if (_disposed) return _pending;
    final audible =
        settings.active &&
        settings.soundEnabled &&
        (!indoors || settings.indoors);
    final rainLevel = switch (settings.kind) {
      SpatialWeatherKind.drizzle => .25,
      SpatialWeatherKind.rain => .65,
      SpatialWeatherKind.downpour => .9,
      SpatialWeatherKind.storm || SpatialWeatherKind.tempest => 1.0,
      SpatialWeatherKind.sleet => .65,
      _ => 0.0,
    };
    const envelope = .65;
    final rawGains = (
      audible
          ? rainLevel * settings.intensity * settings.rainVolume * envelope
          : 0.0,
      audible
          ? (settings.windStrength / 2 +
                        (settings.kind == SpatialWeatherKind.tempest
                            ? .6
                            : settings.kind == SpatialWeatherKind.storm
                            ? .35
                            : settings.kind == SpatialWeatherKind.blizzard ||
                                  settings.kind == SpatialWeatherKind.windy
                            ? .3
                            : 0))
                    .clamp(0.0, 1.0) *
                settings.intensity *
                settings.windVolume *
                envelope
          : 0.0,
    );
    final severe =
        settings.kind == SpatialWeatherKind.storm ||
        settings.kind == SpatialWeatherKind.tempest;
    final rainPath =
        '$_prefix${severe || settings.kind == SpatialWeatherKind.downpour ? 'storm-rain' : 'rain'}-loop.wav';
    final windPath =
        '$_prefix${severe || settings.kind == SpatialWeatherKind.blizzard || settings.kind == SpatialWeatherKind.windy || settings.kind == SpatialWeatherKind.sandstorm ? 'storm-wind' : 'wind'}-loop.wav';
    final rain = projectAudio?.resolve(
      ProjectSoundCue.weatherRain,
      builtinPath: rainPath,
    );
    final wind = projectAudio?.resolve(
      ProjectSoundCue.weatherWind,
      builtinPath: windPath,
    );
    final next = (
      rawGains.$1 * (projectAudio == null ? 1 : rain?.gain ?? 0),
      rawGains.$2 * (projectAudio == null ? 1 : wind?.gain ?? 0),
    );
    final selectedRainPath = projectAudio == null ? rainPath : rain?.path;
    final selectedWindPath = projectAudio == null ? windPath : wind?.path;
    final storm = _storm.update(settings, seconds: seconds, indoors: indoors);
    final sameStorm = identical(storm, _stormPending);
    _stormPending = storm;
    if (_gains == next &&
        _rainPath == selectedRainPath &&
        _windPath == selectedWindPath) {
      if (sameStorm) return _pending;
      return _pending = Future.wait([_pending, storm]);
    }
    _gains = next;
    _rainPath = selectedRainPath;
    _windPath = selectedWindPath;
    return _pending = Future.wait([
      storm,
      _rain.update(
        route: RuntimeAudioRoute.ambience,
        path: next.$1 > 0 ? selectedRainPath : null,
        volume: next.$1,
      ),
      _wind.update(
        route: RuntimeAudioRoute.ambience,
        path: next.$2 > 0 ? selectedWindPath : null,
        volume: next.$2,
      ),
    ]);
  }

  Future<void> setSuspended(bool suspended) {
    if (_disposed) return _pending;
    return Future.wait([
      _rain.setSuspended(suspended),
      _wind.setSuspended(suspended),
      _storm.setSuspended(suspended),
    ]);
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    return _pending = Future.wait([
      _rain.dispose(),
      _wind.dispose(),
      _storm.dispose(),
    ]);
  }
}
