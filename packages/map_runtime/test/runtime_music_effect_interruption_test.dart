import 'dart:async';
import 'dart:io';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_music_service.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test(
    'ME begins without waiting and pauses only the current BGM handle',
    () async {
      final driver = _Driver();
      final fades = _Fades();
      final service = _service(driver, fades: fades);
      await service.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
        volume: .64,
      );
      final handle = driver.lastHandle;
      final owner = Object();

      service.beginMusicEffect(
        owner: owner,
        fadeOut: const Duration(milliseconds: 200),
        fadeIn: const Duration(milliseconds: 1000),
      );
      await _flush();
      expect(fades.delays, [const Duration(milliseconds: 100)]);
      expect(driver.paused, isEmpty);
      await fades.advance();
      expect(driver.volumes[handle], closeTo(.32, 1e-12));
      await fades.advance();
      expect(driver.volumes[handle], 0);
      expect(driver.paused, [handle]);
      expect(driver.stopped, isEmpty);

      final ending = service.endMusicEffect(owner);
      await _flush();
      expect(driver.resumed, [handle]);
      await fades.advance();
      expect(driver.volumes[handle], closeTo(.32, 1e-12));
      await fades.advance();
      await ending;
      expect(driver.volumes[handle], closeTo(.64, 1e-12));
      expect(driver.played, hasLength(1));
      expect(fades.delays, [
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 500),
      ]);
      await service.dispose();
    },
  );

  test(
    'same path and mixer changes retain the BGM interruption envelope',
    () async {
      final driver = _Driver();
      final fades = _Fades();
      final mixer = RuntimeAudioMixer();
      final service = _service(driver, fades: fades, mixer: mixer);
      await service.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
        volume: .64,
      );
      final handle = driver.lastHandle;
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: const Duration(milliseconds: 200),
        fadeIn: Duration.zero,
      );
      await _flush();
      await fades.advance();
      await service.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
        volume: .5,
      );
      expect(driver.volumes[handle], closeTo(.25, 1e-12));
      await mixer.transitionTo(
        const RuntimeAudioMix(masterVolume: .5, musicVolume: .6),
      );
      expect(driver.volumes[handle], closeTo(.075, 1e-12));
      await fades.advance();
      expect(driver.volumes[handle], 0);
      await service.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
        volume: .5,
      );
      expect(driver.volumes[handle], 0);
      await service.endMusicEffect(owner);
      expect(driver.volumes[handle], closeTo(.15, 1e-12));
      await service.dispose();
    },
  );

  test(
    'overlapping ME owners release the BGM only after the last completion',
    () async {
      final driver = _Driver();
      final service = _service(driver);
      await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final handle = driver.lastHandle;
      final first = Object();
      final second = Object();
      service.beginMusicEffect(
        owner: first,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      service.beginMusicEffect(
        owner: second,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await _flush();
      expect(driver.paused, [handle]);
      await service.endMusicEffect(first);
      await service.endMusicEffect(first);
      expect(driver.resumed, isEmpty);
      expect(driver.volumes[handle], 0);
      await service.endMusicEffect(second);
      expect(driver.resumed, [handle]);
      expect(driver.volumes[handle], closeTo(.8, 1e-12));
      await service.dispose();
    },
  );

  test(
    'an early ME end cancels stale fade steps before they can pause BGM',
    () async {
      final driver = _Driver();
      final fades = _Fades();
      final service = _service(driver, fades: fades);
      await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final handle = driver.lastHandle;
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: const Duration(milliseconds: 200),
        fadeIn: Duration.zero,
      );
      await _flush();
      await service.endMusicEffect(owner);
      await fades.advance();
      expect(driver.paused, isEmpty);
      expect(driver.volumes[handle], .8);
      await service.dispose();
    },
  );

  test(
    'track changes during ME never resume the replaced BGM handle',
    () async {
      final driver = _Driver();
      final service = _service(driver);
      await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final oldHandle = driver.lastHandle;
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await _flush();
      await service.update(
        route: RuntimeAudioRoute.battle,
        path: 'battle.ogg',
        volume: .6,
      );
      final newHandle = driver.lastHandle;
      expect(driver.stopped, [oldHandle]);
      expect(driver.paused, [oldHandle, newHandle]);
      expect(driver.volumes[newHandle], 0);
      driver.complete(oldHandle);
      await _flush();
      await service.endMusicEffect(owner);
      expect(driver.resumed, [newHandle]);
      expect(driver.volumes[newHandle], .6);
      await service.dispose();
    },
  );

  test('dispose invalidates delayed fades and ME completions', () async {
    final driver = _Driver();
    final fades = _Fades();
    final service = _service(driver, fades: fades);
    await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
    final handle = driver.lastHandle;
    final owner = Object();
    service.beginMusicEffect(
      owner: owner,
      fadeOut: const Duration(milliseconds: 200),
      fadeIn: const Duration(milliseconds: 1000),
    );
    await _flush();
    await service.dispose();
    await service.endMusicEffect(owner);
    await fades.advance();
    expect(driver.stopped, [handle]);
    expect(driver.paused, isEmpty);
    expect(driver.resumed, isEmpty);
    expect(service.isPlaying, isFalse);
  });

  test(
    'loop deadline freezes at pause and resumes with exactly the remainder',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'original-me-loop-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final track = File('${directory.path}/original.ogg')
        ..writeAsBytesSync(_ogg());
      final driver = _Driver();
      final timers = <_Timer>[];
      var now = Duration.zero;
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
        fadeDelay: (_) async {},
        clock: () => now,
        loopTimerFactory: (delay, callback) {
          final timer = _Timer(delay, callback);
          timers.add(timer);
          return timer;
        },
      );
      await service.update(
        route: RuntimeAudioRoute.overworld,
        path: track.path,
      );
      final handle = driver.lastHandle;
      now = const Duration(seconds: 2);
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await _flush();
      expect(timers.single.delay, const Duration(seconds: 5));
      expect(timers.first.isActive, isFalse);
      expect(service.debugLoopReturnDelay, const Duration(seconds: 3));
      now = const Duration(seconds: 22);
      timers.first.callback();
      driver.complete(handle);
      await _flush();
      expect(driver.seeks, isEmpty);
      await service.endMusicEffect(owner);
      expect(timers.last.delay, const Duration(seconds: 3));
      timers.last.fire();
      await _flush();
      expect(driver.seeks, [(handle, const Duration(seconds: 1))]);
      expect(timers.last.delay, const Duration(seconds: 4));
      await service.dispose();
    },
  );

  test('a new ME supersedes an unfinished BGM fade-in', () async {
    final driver = _Driver();
    final fades = _Fades();
    final service = _service(driver, fades: fades);
    await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
    final handle = driver.lastHandle;
    final first = Object();
    final second = Object();
    service.beginMusicEffect(
      owner: first,
      fadeOut: Duration.zero,
      fadeIn: const Duration(milliseconds: 1000),
    );
    await _flush();
    final ending = service.endMusicEffect(first);
    await _flush();
    expect(driver.resumed, [handle]);
    service.beginMusicEffect(
      owner: second,
      fadeOut: Duration.zero,
      fadeIn: Duration.zero,
    );
    await _flush();
    await fades.advance();
    await ending;
    expect(driver.volumes[handle], 0);
    expect(driver.paused, [handle, handle]);
    await service.endMusicEffect(second);
    expect(driver.resumed, [handle, handle]);
    expect(driver.volumes[handle], .8);
    await service.dispose();
  });

  test(
    'completion during pending pause resumes exactly once after that pause',
    () async {
      final driver = _Driver()..pauseGate = Completer<void>();
      final service = _service(driver);
      await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final handle = driver.lastHandle;
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await _flush();
      final ending = service.endMusicEffect(owner);
      await _flush();
      expect(driver.paused, [handle]);
      expect(driver.resumed, isEmpty);
      driver.pauseGate!.complete();
      await ending;
      expect(driver.resumed, [handle]);
      expect(driver.volumes[handle], .8);
      await service.dispose();
    },
  );

  test('a new ME during pending resume keeps BGM silent and paused', () async {
    final driver = _Driver();
    final service = _service(driver);
    await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
    final handle = driver.lastHandle;
    final first = Object();
    final second = Object();
    service.beginMusicEffect(
      owner: first,
      fadeOut: Duration.zero,
      fadeIn: Duration.zero,
    );
    await _flush();
    driver.resumeGate = Completer<void>();
    final firstEnding = service.endMusicEffect(first);
    await _flush();
    expect(driver.resumed, [handle]);
    service.beginMusicEffect(
      owner: second,
      fadeOut: Duration.zero,
      fadeIn: Duration.zero,
    );
    driver.resumeGate!.complete();
    await firstEnding;
    await _flush();
    expect(driver.volumes[handle], 0);
    expect(driver.paused, [handle, handle]);
    driver.resumeGate = null;
    await service.endMusicEffect(second);
    expect(driver.resumed, [handle, handle]);
    expect(driver.volumes[handle], .8);
    expect(driver.played, ['map.ogg']);
    await service.dispose();
  });

  test(
    'a new ME ending during pending resume leaves one fresh fade-in',
    () async {
      final driver = _Driver();
      final service = _service(driver);
      await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final handle = driver.lastHandle;
      final first = Object();
      final second = Object();
      service.beginMusicEffect(
        owner: first,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await _flush();
      driver.resumeGate = Completer<void>();
      final firstEnding = service.endMusicEffect(first);
      await _flush();
      service.beginMusicEffect(
        owner: second,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      final secondEnding = service.endMusicEffect(second);
      driver.resumeGate!.complete();
      await Future.wait([firstEnding, secondEnding]);
      expect(driver.volumes[handle], .8);
      expect(driver.paused, [handle]);
      expect(driver.resumed, [handle]);
      expect(driver.played, ['map.ogg']);
      await service.dispose();
    },
  );

  test(
    'dispose during pending resume cannot revive the retained BGM',
    () async {
      final driver = _Driver();
      final service = _service(driver);
      await service.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final handle = driver.lastHandle;
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await _flush();
      driver.resumeGate = Completer<void>();
      final ending = service.endMusicEffect(owner);
      await _flush();
      final closing = service.dispose();
      driver.resumeGate!.complete();
      await Future.wait([ending, closing]);
      expect(driver.stopped, [handle]);
      expect(driver.volumes[handle], 0);
      expect(service.isPlaying, isFalse);
    },
  );

  test(
    'a BGM handle that arrives after disposal is stopped without registration',
    () async {
      final driver = _Driver()..playGate = Completer<Object>();
      final mixer = RuntimeAudioMixer();
      final service = _service(driver, mixer: mixer);
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      final starting = service.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
      );
      await _flush();
      final handle = driver.lastHandle;
      final closing = service.dispose();
      driver.playGate!.complete(handle);
      await Future.wait([starting, closing]);
      await service.endMusicEffect(owner);
      await mixer.transitionTo(const RuntimeAudioMix(masterVolume: .4));
      expect(driver.stopped, [handle]);
      expect(driver.paused, isEmpty);
      expect(driver.resumed, isEmpty);
      expect(driver.volumes[handle], 0);
      expect(service.isPlaying, isFalse);
    },
  );

  test(
    'native driver delegates pause and resume to the same AudioPlayer',
    () async {
      final player = _AudioPlayer();
      final driver = FlameAudioCinematicRuntimeDriver();
      await driver.pause(player);
      await driver.resume(player);
      expect(player.operations, ['pause', 'resume']);
    },
  );

  test(
    'BGM requested after ME began starts silent and remains paused',
    () async {
      final driver = _Driver();
      final service = _service(driver);
      final owner = Object();
      service.beginMusicEffect(
        owner: owner,
        fadeOut: Duration.zero,
        fadeIn: Duration.zero,
      );
      await service.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
        volume: .64,
      );
      final handle = driver.lastHandle;
      expect(driver.initialVolumes, [0]);
      expect(driver.paused, [handle]);
      await service.endMusicEffect(owner);
      expect(driver.resumed, [handle]);
      expect(driver.volumes[handle], .64);
      await service.dispose();
    },
  );
}

RuntimeMusicService _service(
  _Driver driver, {
  _Fades? fades,
  RuntimeAudioMixer? mixer,
}) => RuntimeMusicService(
  driver: driver,
  mixer: mixer ?? RuntimeAudioMixer(),
  fadeSteps: 2,
  fadeDelay: fades?.delay ?? (_) async {},
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

final class _Fades {
  final delays = <Duration>[];
  final pending = <Completer<void>>[];
  Future<void> delay(Duration duration) {
    delays.add(duration);
    final result = Completer<void>();
    pending.add(result);
    return result.future;
  }

  Future<void> advance() async {
    pending.removeAt(0).complete();
    await _flush();
  }
}

final class _Driver
    implements
        FlameCinematicAudioDriver,
        FlameCinematicAudioLoopDriver,
        FlameCinematicAudioPausableDriver {
  final played = <String>[];
  final initialVolumes = <double>[];
  final volumes = <Object, double>{};
  final paused = <Object>[];
  final resumed = <Object>[];
  final stopped = <Object>[];
  final seeks = <(Object, Duration)>[];
  final completions = <Object, StreamController<void>>{};
  Completer<void>? pauseGate;
  Completer<void>? resumeGate;
  Completer<Object>? playGate;
  Object get lastHandle => completions.keys.last;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final handle = Object();
    played.add(path);
    initialVolumes.add(volume);
    volumes[handle] = volume;
    completions[handle] = StreamController<void>.broadcast(sync: true);
    return playGate?.future ?? handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async =>
      volumes[handle] = volume;
  @override
  Future<void> pause(Object handle) async {
    paused.add(handle);
    await pauseGate?.future;
  }

  @override
  Future<void> resume(Object handle) async {
    resumed.add(handle);
    await resumeGate?.future;
  }

  @override
  Future<void> stop(Object handle) async => stopped.add(handle);
  @override
  Stream<void> onComplete(Object handle) => completions[handle]!.stream;
  @override
  Future<void> seekAndResume(Object handle, Duration position) async =>
      seeks.add((handle, position));
  void complete(Object handle) => completions[handle]!.add(null);
}

final class _Timer implements Timer {
  _Timer(this.delay, this.callback);
  final Duration delay;
  final void Function() callback;
  bool active = true;
  @override
  bool get isActive => active;
  @override
  int get tick => active ? 0 : 1;
  @override
  void cancel() => active = false;
  void fire() {
    if (!active) return;
    active = false;
    callback();
  }
}

List<int> _ogg() => [
  ...'OggS'.codeUnits,
  0,
  0,
  0,
  0,
  1,
  ...'vorbis'.codeUnits,
  0,
  0,
  0,
  0,
  2,
  232,
  3,
  0,
  0,
  0,
  0,
  0,
  0,
  ...'OggS'.codeUnits,
  3,
  ...'vorbis'.codeUnits,
  ...'LOOPSTART=1000'.codeUnits,
  0,
  ...'LOOPLENGTH=4000'.codeUnits,
  0,
];

final class _AudioPlayer implements AudioPlayer {
  final operations = <String>[];
  @override
  Future<void> pause() async => operations.add('pause');
  @override
  Future<void> resume() async => operations.add('resume');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
