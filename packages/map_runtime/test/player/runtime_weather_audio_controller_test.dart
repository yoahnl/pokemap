import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_project_audio_controller.dart';
import 'package:map_runtime/src/player/runtime_music_service.dart';
import 'package:map_runtime/src/player/runtime_weather_audio_controller.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test(
    'custom rain and thunder share the mixer while silent wind owns no voice',
    () async {
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(masterVolume: .5, effectsVolume: .4),
      );
      final drivers = <_Driver>[];
      final projectAudio = RuntimeProjectAudioController(
        mixer: mixer,
        driver: _Driver(),
        settings: ProjectAudioSettings(
          cues: {
            ProjectSoundCue.weatherRain: const ProjectSoundBinding(
              source: ProjectSoundSource.custom,
              mediaId: 'rain',
              gain: .5,
            ),
            ProjectSoundCue.weatherWind: const ProjectSoundBinding(
              source: ProjectSoundSource.silent,
            ),
            ProjectSoundCue.weatherThunder: const ProjectSoundBinding(
              source: ProjectSoundSource.custom,
              mediaId: 'thunder',
              gain: .25,
            ),
          },
        ),
        resolveMedia: (id) => RuntimeProjectAudioFile(
          path: '/project/$id.ogg',
          mimeType: 'audio/ogg',
        ),
      );
      final weather = RuntimeWeatherAudioController(
        mixer: mixer,
        projectAudio: projectAudio,
        driverFactory: () {
          final driver = _Driver();
          drivers.add(driver);
          return driver;
        },
      );
      final settings = SpatialWeatherSettings(
        enabled: true,
        soundEnabled: true,
        lightning: true,
        kind: SpatialWeatherKind.storm,
        intensity: 1,
      );
      final event = spatialStormEventAt(0);
      await weather.update(settings, seconds: event.strikeSeconds);
      expect(drivers[0].plays, ['/project/rain.ogg']);
      expect(drivers[0].volume, closeTo(.5 * .4 * .65 * settings.rainVolume * .5, .00001));
      expect(drivers[1].plays, isEmpty);
      await weather.update(settings, seconds: event.thunderSeconds + .01);
      expect(drivers[2].plays, ['/project/thunder.ogg']);
      expect(
        drivers[2].volume,
        closeTo(.5 * .4 * event.strength * .25, .00001),
      );
      await weather.setSuspended(true);
      await weather.setSuspended(false);
      expect(
        drivers[2].volume,
        closeTo(.5 * .4 * event.strength * .25, .00001),
      );
      final calls = drivers[0].volumeChanges;
      for (var i = 0; i < 2000; i++)
        await weather.update(settings, seconds: event.thunderSeconds + .02);
      expect(drivers[0].volumeChanges, calls);
      await weather.dispose();
      await projectAudio.dispose();
      expect(drivers[0].stops, 1);
      expect(drivers[2].stops, 1);
    },
  );
  test(
    'thunder uses the shared strike timeline once and stops for indoor weather',
    () async {
      final drivers = <_Driver>[];
      final mixer = RuntimeAudioMixer();
      var musicVolume = .8;
      await mixer.register(
        channel: 'music-proof',
        route: RuntimeAudioRoute.overworld,
        sourceVolume: .8,
        setVolume: (value) async => musicVolume = value,
      );
      final weather = RuntimeWeatherAudioController(
        mixer: mixer,
        driverFactory: () {
          final driver = _Driver();
          drivers.add(driver);
          return driver;
        },
      );
      final settings = SpatialWeatherSettings(
        enabled: true,
        soundEnabled: true,
        lightning: true,
        kind: SpatialWeatherKind.storm,
      );
      final strike = spatialStormEventAt(0);
      await weather.update(settings, seconds: strike.strikeSeconds - .1);
      await weather.update(settings, seconds: strike.thunderSeconds - .01);
      expect(drivers[2].plays, isEmpty);
      await weather.update(settings, seconds: strike.thunderSeconds + .01);
      expect(drivers[2].plays.single, contains('thunder-'));
      expect(drivers[2].loops, [false]);
      expect(musicVolume, .8);
      for (var i = 0; i < 60; i++) {
        await weather.update(
          settings,
          seconds: strike.thunderSeconds + .02 + i / 60,
        );
      }
      expect(drivers[2].plays, hasLength(1));
      await weather.setSuspended(true);
      expect(drivers[2].paused, isTrue);
      await weather.setSuspended(false);
      expect(drivers[2].paused, isFalse);
      await weather.update(
        settings,
        seconds: strike.thunderSeconds + 2,
        indoors: true,
      );
      expect(drivers[2].stops, 1);
      expect(musicVolume, .8);
      await weather.dispose();
    },
  );
  test('a delayed thunder start is cancelled by disabling weather', () async {
    final gate = Completer<void>();
    final drivers = <_Driver>[];
    final weather = RuntimeWeatherAudioController(
      mixer: RuntimeAudioMixer(),
      driverFactory: () {
        final driver = _Driver();
        if (drivers.length == 2) driver.startGate = gate.future;
        drivers.add(driver);
        return driver;
      },
    );
    final settings = SpatialWeatherSettings(
      enabled: true,
      soundEnabled: true,
      lightning: true,
      kind: SpatialWeatherKind.storm,
    );
    final event = spatialStormEventAt(0);
    await weather.update(settings, seconds: event.strikeSeconds);
    final starting = weather.update(
      settings,
      seconds: event.thunderSeconds + .01,
    );
    await Future<void>.delayed(Duration.zero);
    expect(drivers[2].plays, hasLength(1));
    final stopping = weather.update(
      settings.copyWith(enabled: false),
      seconds: event.thunderSeconds + .02,
    );
    gate.complete();
    await Future.wait([starting, stopping]);
    expect(drivers[2].stops, 1);
    expect(weather.diagnostics['thunderPlaying'], isFalse);
    await weather.dispose();
  });
  test(
    'late frames do not replay thunder and effects mute reaches thunder',
    () async {
      final mixer = RuntimeAudioMixer();
      final drivers = <_Driver>[];
      final weather = RuntimeWeatherAudioController(
        mixer: mixer,
        driverFactory: () {
          final driver = _Driver();
          drivers.add(driver);
          return driver;
        },
      );
      final settings = SpatialWeatherSettings(
        enabled: true,
        soundEnabled: true,
        lightning: true,
        kind: SpatialWeatherKind.hail,
      );
      final first = spatialStormEventAt(0);
      await weather.update(settings, seconds: first.strikeSeconds);
      await weather.update(settings, seconds: first.thunderSeconds + 2);
      expect(drivers[2].plays, isEmpty);
      final second = spatialStormEventAt(65);
      await weather.update(settings, seconds: second.strikeSeconds);
      await weather.update(settings, seconds: second.thunderSeconds + .01);
      expect(drivers[2].plays, hasLength(1));
      expect(drivers[2].volume, greaterThan(0));
      await mixer.transitionTo(const RuntimeAudioMix(effectsVolume: 0));
      expect(drivers[2].volume, 0);
      await weather.dispose();
      expect(drivers[2].stops, 1);
    },
  );
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
        drivers
            .where((driver) => driver.plays.isNotEmpty)
            .every((driver) => driver.paused && driver.volume == 0),
        isTrue,
      );
      await weather.setSuspended(false);
      expect(
        drivers
            .where((driver) => driver.plays.isNotEmpty)
            .every(
              (driver) =>
                  !driver.paused &&
                  driver.volume > 0 &&
                  driver.plays.length == 1,
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
    implements
        FlameCinematicAudioDriver,
        FlameCinematicAudioPausableDriver,
        FlameCinematicAudioLoopDriver {
  @override
  Stream<void> onComplete(Object handle) => const Stream.empty();
  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
  final plays = <String>[];
  final loops = <bool>[];
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
    loops.add(loop);
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
