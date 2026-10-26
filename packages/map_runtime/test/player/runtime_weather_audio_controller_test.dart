import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_music_service.dart';
import 'package:map_runtime/src/player/runtime_weather_audio_controller.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test('rain and wind stay independent of music and unchanged frames do no audio work', () async {
    final mixer = RuntimeAudioMixer();
    final rain = _Driver();
    final wind = _Driver();
    final musicDriver = _Driver();
    final music = RuntimeMusicService(mixer: mixer, driver: musicDriver);
    await music.update(route: RuntimeAudioRoute.overworld, path: 'map.wav');
    var index = 0;
    final weather = RuntimeWeatherAudioController(
      mixer: mixer,
      driverFactory: () => index++ == 0 ? rain : wind,
    );
    final settings = SpatialWeatherSettings(
      enabled: true,
      soundEnabled: true,
      kind: SpatialWeatherKind.rain,
    );
    await weather.update(settings);
    expect(rain.plays, hasLength(1));
    expect(wind.plays, hasLength(1));
    final calls = rain.volumeChanges + wind.volumeChanges;
    for (var frame = 0; frame < 300; frame++) {
      await weather.update(settings.copyWith());
    }
    expect(rain.volumeChanges + wind.volumeChanges, calls);
    final before = rain.volume;
    await weather.update(settings.copyWith(intensity: 1));
    expect(rain.volume, greaterThan(before));
    expect(rain.plays, hasLength(1));
    await mixer.transitionTo(const RuntimeAudioMix(effectsVolume: .25));
    expect(rain.volume, lessThan(before));
    expect(musicDriver.volume, .8);
    await weather.setSuspended(true);
    expect(rain.paused, isTrue);
    await weather.setSuspended(false);
    expect(rain.paused, isFalse);
    await weather.update(settings, indoors: true);
    expect(rain.stops, 1);
    expect(wind.stops, 1);
    expect(music.isPlaying, isTrue);
    await weather.dispose();
    await music.dispose();
  });
  test('a pending start cannot survive a stop or disposal', () async {
    final gate = Completer<void>();
    final drivers = <_Driver>[];
    final weather = RuntimeWeatherAudioController(
      mixer: RuntimeAudioMixer(),
      driverFactory: () {
        final driver = _Driver()..startGate = gate.future;
        drivers.add(driver);
        return driver;
      },
    );
    final settings = SpatialWeatherSettings(enabled: true, soundEnabled: true);
    final playing = weather.update(settings);
    await Future<void>.delayed(Duration.zero);
    final stopping = weather.update(settings.copyWith(enabled: false));
    final disposed = weather.dispose();
    gate.complete();
    await Future.wait([playing, stopping, disposed]);
    expect(
      drivers.every((driver) => driver.plays.length == driver.stops),
      isTrue,
    );
    final calls = drivers.fold<int>(
      0,
      (total, driver) => total + driver.plays.length,
    );
    await weather.update(settings);
    expect(
      drivers.fold<int>(0, (total, driver) => total + driver.plays.length),
      calls,
    );
  });
  test(
    'a suspended controller starts muted and resumes the same loops',
    () async {
      final drivers = <_Driver>[];
      final weather = RuntimeWeatherAudioController(
        mixer: RuntimeAudioMixer(),
        driverFactory: () {
          final driver = _Driver();
          drivers.add(driver);
          return driver;
        },
      );
      await weather.setSuspended(true);
      await weather.update(
        SpatialWeatherSettings(enabled: true, soundEnabled: true),
      );
      expect(
        drivers.every((driver) => driver.paused && driver.volume == 0),
        isTrue,
      );
      await weather.setSuspended(false);
      expect(
        drivers.every(
          (driver) =>
              !driver.paused && driver.volume > 0 && driver.plays.length == 1,
        ),
        isTrue,
      );
      await weather.dispose();
    },
  );
  test('legacy weather and zero volume do not create audio players', () async {
    final drivers = <_Driver>[];
    final weather = RuntimeWeatherAudioController(
      mixer: RuntimeAudioMixer(),
      driverFactory: () {
        final driver = _Driver();
        drivers.add(driver);
        return driver;
      },
    );
    final settings = SpatialWeatherSettings(
      enabled: true,
      kind: SpatialWeatherKind.storm,
    );
    await weather.update(settings);
    expect(drivers.expand((driver) => driver.plays), isEmpty);
    await weather.update(
      settings.copyWith(soundEnabled: true, rainVolume: 0, windVolume: 0),
    );
    expect(drivers.expand((driver) => driver.plays), isEmpty);
    await weather.dispose();
    await weather.update(settings.copyWith(soundEnabled: true));
    expect(drivers.expand((driver) => driver.plays), isEmpty);
  });
}

final class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  final plays = <String>[];
  Future<void>? startGate;
  double volume = 0;
  int volumeChanges = 0, stops = 0;
  bool paused = false;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    expect(loop, isTrue);
    plays.add(path);
    this.volume = volume;
    await startGate;
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    this.volume = volume;
    volumeChanges++;
  }

  @override
  Future<void> stop(Object handle) async {
    stops++;
  }

  @override
  Future<void> pause(Object handle) async {
    paused = true;
  }

  @override
  Future<void> resume(Object handle) async {
    paused = false;
  }
}
