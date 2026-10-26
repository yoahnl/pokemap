import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/player/runtime_weather_loop_driver.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test('stopping during a delayed overlap start releases both voices', () {
    fakeAsync((async) {
      final audio = _Driver();
      final driver = RuntimeWeatherLoopDriver(
        audio,
        clock: () => async.elapsed,
      );
      Object? handle;
      driver
          .play('rain', volume: .5, loop: true)
          .then((value) => handle = value);
      async.flushMicrotasks();
      final gate = Completer<void>();
      audio.gate = gate.future;
      async.elapse(const Duration(seconds: 14));
      async.flushMicrotasks();
      expect(audio.voices.length, 2);
      var stopped = false;
      driver.stop(handle!).then((_) => stopped = true);
      async.flushMicrotasks();
      expect(stopped, isFalse);
      gate.complete();
      async.flushMicrotasks();
      expect(stopped, isTrue);
      expect(audio.voices, isEmpty);
      expect(async.periodicTimerCount, 0);
    });
  });
  test('weather overlaps before source completion with at most two voices', () {
    fakeAsync((async) {
      final audio = _Driver();
      final driver = RuntimeWeatherLoopDriver(
        audio,
        clock: () => async.elapsed,
      );
      Object? handle;
      driver
          .play('rain', volume: .8, loop: true)
          .then((value) => handle = value);
      async.flushMicrotasks();
      for (var i = 0; i < 1200; i++) {
        async.elapse(const Duration(milliseconds: 50));
        async.flushMicrotasks();
        expect(audio.voices.length, inInclusiveRange(1, 2));
        expect(
          audio.voices.values.fold<double>(
            0,
            (sum, value) => sum + value * value,
          ),
          closeTo(.64, .00001),
        );
      }
      expect(audio.plays, greaterThanOrEqualTo(5));
      expect(audio.nativeLoops, everyElement(isFalse));
      driver.stop(handle!);
      async.flushMicrotasks();
      expect(audio.voices, isEmpty);
      expect(async.periodicTimerCount, 0);
    });
  });
  test('pause freezes overlap and resume preserves the same voices', () {
    fakeAsync((async) {
      final audio = _Driver();
      final driver = RuntimeWeatherLoopDriver(
        audio,
        clock: () => async.elapsed,
      );
      Object? handle;
      driver
          .play('wind', volume: .6, loop: true)
          .then((value) => handle = value);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 14));
      async.flushMicrotasks();
      driver.pause(handle!);
      async.flushMicrotasks();
      final starts = audio.plays;
      async.elapse(const Duration(minutes: 1));
      expect(audio.plays, starts);
      expect(audio.paused, containsAll(audio.voices.keys));
      driver.resume(handle!);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(audio.paused, isEmpty);
      driver.setVolume(handle!, 0);
      async.flushMicrotasks();
      expect(audio.voices.values, everyElement(0));
      driver.stop(handle!);
      async.flushMicrotasks();
      expect(audio.voices, isEmpty);
      expect(async.periodicTimerCount, 0);
    });
  });
}

final class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  final voices = <Object, double>{};
  final paused = <Object>{};
  final nativeLoops = <bool>[];
  int plays = 0;
  Future<void>? gate;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final handle = Object();
    plays++;
    nativeLoops.add(loop);
    voices[handle] = volume;
    await gate;
    return handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async =>
      voices[handle] = volume;
  @override
  Future<void> stop(Object handle) async {
    voices.remove(handle);
    paused.remove(handle);
  }

  @override
  Future<void> pause(Object handle) async => paused.add(handle);
  @override
  Future<void> resume(Object handle) async => paused.remove(handle);
}
