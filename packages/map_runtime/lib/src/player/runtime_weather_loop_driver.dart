import 'dart:async';
import 'dart:math' as math;

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';

final class RuntimeWeatherLoopDriver
    implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  RuntimeWeatherLoopDriver(
    this.driver, {
    this.duration = const Duration(microseconds: 15350023),
    this.overlap = const Duration(milliseconds: 1500),
    Duration Function()? clock,
    Timer Function(Duration, void Function(Timer))? timerFactory,
  }) : clock = clock ?? (Stopwatch()..start()).elapsedDuration,
       timerFactory = timerFactory ?? Timer.periodic {
    if (overlap <= Duration.zero || overlap * 2 >= duration) {
      throw ArgumentError('Weather overlap must fit within its source.');
    }
  }

  final FlameCinematicAudioDriver driver;
  final Duration duration, overlap;
  final Duration Function() clock;
  final Timer Function(Duration, void Function(Timer)) timerFactory;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final voice = await driver.play(path, volume: volume, loop: false);
    if (!loop) return voice;
    final state = _WeatherLoop(path, volume, voice, clock());
    state.timer = timerFactory(const Duration(milliseconds: 50), (_) {
      if (state.stopped || state.pausedAt != null || state.busy) return;
      state.busy = true;
      state.pending = state.pending
          .then((_) => _tick(state))
          .catchError((Object error) {
            state.failure = error;
          })
          .whenComplete(() => state.busy = false);
    });
    return state;
  }

  Future<void> _tick(_WeatherLoop state) async {
    if (state.stopped || state.pausedAt != null) return;
    final elapsed = clock() - state.started;
    if (state.incoming == null && elapsed >= duration - overlap) {
      final voice = await driver.play(state.path, volume: 0, loop: false);
      state.incoming = voice;
      state.crossfadeStarted = clock();
      if (state.stopped) return;
      if (state.pausedAt != null) {
        await (driver as FlameCinematicAudioPausableDriver).pause(voice);
        return;
      }
    }
    if (state.incoming == null) return;
    final progress =
        ((clock() - state.crossfadeStarted!).inMicroseconds /
                overlap.inMicroseconds)
            .clamp(0.0, 1.0);
    state.progress = progress;
    await _volumes(state);
    if (progress >= 1 && !state.stopped) {
      await driver.stop(state.current);
      state.current = state.incoming!;
      state.incoming = null;
      state.started = state.crossfadeStarted!;
      state.crossfadeStarted = null;
      state.progress = 0;
    }
  }

  Future<void> _volumes(_WeatherLoop state) async {
    await driver.setVolume(
      state.current,
      state.volume *
          (state.incoming == null ? 1 : math.cos(state.progress * math.pi / 2)),
    );
    final incoming = state.incoming;
    if (incoming != null) {
      await driver.setVolume(
        incoming,
        state.volume * math.sin(state.progress * math.pi / 2),
      );
    }
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    if (handle is! _WeatherLoop) return driver.setVolume(handle, volume);
    handle.volume = volume;
    await handle.pending;
    if (handle.failure != null) {
      Error.throwWithStackTrace(handle.failure!, StackTrace.current);
    }
    if (!handle.stopped) await _volumes(handle);
  }

  @override
  Future<void> stop(Object handle) async {
    if (handle is! _WeatherLoop) return driver.stop(handle);
    if (handle.stopped) return;
    handle.stopped = true;
    handle.timer?.cancel();
    await handle.pending;
    final incoming = handle.incoming;
    await Future.wait([
      driver.stop(handle.current),
      if (incoming != null) driver.stop(incoming),
    ]);
  }

  @override
  Future<void> pause(Object handle) async {
    final pausable = driver as FlameCinematicAudioPausableDriver;
    if (handle is! _WeatherLoop) return pausable.pause(handle);
    if (handle.stopped || handle.pausedAt != null) return;
    handle.pausedAt = clock();
    await handle.pending;
    await pausable.pause(handle.current);
    if (handle.incoming != null) await pausable.pause(handle.incoming!);
  }

  @override
  Future<void> resume(Object handle) async {
    final pausable = driver as FlameCinematicAudioPausableDriver;
    if (handle is! _WeatherLoop) return pausable.resume(handle);
    final paused = handle.pausedAt;
    if (handle.stopped || paused == null) return;
    await pausable.resume(handle.current);
    if (handle.incoming != null) await pausable.resume(handle.incoming!);
    final delay = clock() - paused;
    handle.started += delay;
    if (handle.crossfadeStarted != null) {
      handle.crossfadeStarted = handle.crossfadeStarted! + delay;
    }
    handle.pausedAt = null;
  }
}

final class _WeatherLoop {
  _WeatherLoop(this.path, this.volume, this.current, this.started);
  final String path;
  double volume, progress = 0;
  Object current;
  Object? incoming, failure;
  Duration started;
  Duration? crossfadeStarted, pausedAt;
  Timer? timer;
  bool stopped = false, busy = false;
  Future<void> pending = Future.value();
}

extension on Stopwatch {
  Duration elapsedDuration() => elapsed;
}
