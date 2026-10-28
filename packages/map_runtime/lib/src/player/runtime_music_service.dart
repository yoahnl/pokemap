import 'dart:async';

import 'package:flutter/foundation.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';
import 'runtime_music_loop_points.dart';

/// Joue LA musique courante du runtime — BETA-BAT-015.
///
/// Le contrat suit la référence : une seule BGM à la fois, quel que soit son
/// propriétaire (carte, rencontre, combat, victoire). La route ne change pas
/// ce qui joue, seulement l'identité mixeur du canal — carte et combat vivent
/// tous deux sur le bus musique.
///
/// Comportements repris de la référence :
/// - rejouer le même fichier ne le redémarre pas (parité `Game_Map#autoplay`
///   entre deux cartes qui partagent leur BGM) ;
/// - un changement de piste fond d'abord l'ancienne sur 250 ms (parité du
///   fondu FMOD de `bgm_play`), puis démarre la nouvelle ;
/// - un chemin absent joue le silence sans jamais casser le flux appelant.
///
/// Les opérations sont sérialisées dans une file unique, comme
/// [RuntimeTitleMusicController] : le dernier état demandé gagne toujours, et
/// aucun fondu périmé ne peut écraser une piste plus récente.
final class RuntimeMusicService {
  RuntimeMusicService({
    FlameCinematicAudioDriver? driver,
    RuntimeAudioMixer? mixer,
    RuntimeAudioFadeDelay? fadeDelay,
    int fadeSteps = 8,
    Duration Function()? clock,
    Timer Function(Duration, void Function())? loopTimerFactory,
  }) : _driver = driver ?? FlameAudioCinematicRuntimeDriver(),
       _mixer = mixer ?? RuntimeAudioMixer(),
       _fadeDelay = fadeDelay ?? Future<void>.delayed,
       _fadeSteps = fadeSteps < 1 ? 1 : fadeSteps,
       _clock = clock ?? _monotonicClock(),
       _loopTimerFactory = loopTimerFactory ?? Timer.new;

  static const Duration fadeOutDuration = Duration(milliseconds: 250);

  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final RuntimeAudioFadeDelay _fadeDelay;
  final int _fadeSteps;
  final Duration Function() _clock;
  final Timer Function(Duration, void Function()) _loopTimerFactory;
  final Map<Object, Duration> _musicEffects = {};
  final Object _suspensionOwner = Object();

  Future<void> _pending = Future<void>.value();
  Object? _handle;
  Object? _pausedHandle;
  StreamSubscription<void>? _loopSubscription;
  Timer? _loopReturnTimer;
  Duration? _loopReturnDelay;
  Duration? _loopDueAt;
  void Function()? _loopReturnAction;
  int _loopGeneration = 0;
  bool _loopRestartPending = false;
  int _interruptionGeneration = 0;
  double _interruptionEnvelope = 1;
  String? _playingPath;
  double _playingSourceVolume = 0.8;
  String? _desiredPath;
  RuntimeAudioRoute _desiredRoute = RuntimeAudioRoute.overworld;
  double _desiredVolume = 0.8;
  bool _desiredImmediateStop = false;
  bool _disposed = false;

  Object? lastFailure;

  bool get isPlaying => _handle != null;
  bool get _isPaused => _handle != null && identical(_handle, _pausedHandle);

  @visibleForTesting
  Duration? get debugLoopReturnDelay => _loopReturnDelay;

  @visibleForTesting
  String? get playingPath => _playingPath;

  Future<void> update({
    required RuntimeAudioRoute route,
    required String? path,
    double volume = 0.8,
    bool immediateStop = false,
  }) {
    if (_disposed) return Future<void>.value();
    _desiredPath = path;
    _desiredRoute = route;
    _desiredVolume = volume.clamp(0.0, 1.0);
    _desiredImmediateStop = immediateStop;
    return _enqueue(_applyDesiredState);
  }

  void beginMusicEffect({
    required Object owner,
    required Duration fadeOut,
    required Duration fadeIn,
  }) {
    if (_disposed || _musicEffects.containsKey(owner)) return;
    if (fadeOut < Duration.zero || fadeIn < Duration.zero) {
      throw ArgumentError('Music effect fade durations must be nonnegative.');
    }
    if (_driver is! FlameCinematicAudioPausableDriver) {
      throw StateError('Music effect interruption requires a pausable driver.');
    }
    _musicEffects[owner] = fadeIn;
    final generation = ++_interruptionGeneration;
    if (_isPaused) return;
    unawaited(_fadeInterruption(0, fadeOut, generation, pauseAtEnd: true));
  }

  Future<void> endMusicEffect(Object owner) {
    final fadeIn = _musicEffects.remove(owner);
    if (_disposed || fadeIn == null || _musicEffects.isNotEmpty) {
      return Future<void>.value();
    }
    final generation = ++_interruptionGeneration;
    return _resumeInterruption(fadeIn, generation);
  }

  Future<void> setSuspended(bool suspended) async {
    if (_disposed) return;
    if (!suspended) {
      await endMusicEffect(_suspensionOwner);
      return;
    }
    beginMusicEffect(
      owner: _suspensionOwner,
      fadeOut: Duration.zero,
      fadeIn: Duration.zero,
    );
    await _pending;
    final handle = _handle;
    if (handle != null && _musicEffects.containsKey(_suspensionOwner)) {
      await _enqueue(() async {
        if (identical(_handle, handle) &&
            _musicEffects.containsKey(_suspensionOwner))
          await _pauseCurrentHandle(handle);
      });
    }
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    _desiredPath = null;
    _musicEffects.clear();
    _interruptionGeneration += 1;
    return _enqueue(() => _stop(fade: false));
  }

  Future<void> _applyDesiredState() async {
    final path = _desiredPath;
    if (_disposed || path == null) {
      await _stop(fade: !_desiredImmediateStop);
      return;
    }
    if (_handle != null && _playingPath == path) {
      try {
        _playingSourceVolume = _desiredVolume;
        await _applyCurrentVolume(_handle!);
        lastFailure = null;
      } on Object catch (error) {
        lastFailure = error;
        await _stop(fade: false);
      }
      return;
    }
    await _stop(fade: true);
    if (_disposed || _desiredPath != path) return;
    Object? startedHandle;
    try {
      final loopPoints = readRuntimeMusicLoopPoints(path);
      final loopDriver = _driver;
      final usesIntroLoop =
          loopPoints != null &&
          loopDriver is FlameCinematicAudioLoopDriver &&
          loopPoints.start > Duration.zero;
      _interruptionEnvelope = _musicEffects.isEmpty ? 1 : 0;
      final handle = await _driver.play(
        path,
        volume: _mixer.volumeFor(
          _desiredRoute,
          sourceVolume: _desiredVolume * _interruptionEnvelope,
        ),
        loop: !usesIntroLoop,
      );
      startedHandle = handle;
      if (_disposed || _desiredPath != path) {
        await _driver.stop(handle);
        return;
      }
      _handle = handle;
      _playingPath = path;
      _playingSourceVolume = _desiredVolume;
      _interruptionEnvelope = _musicEffects.isEmpty ? 1 : 0;
      await _mixer.register(
        channel: handle,
        route: _desiredRoute,
        sourceVolume: _playingSourceVolume * _interruptionEnvelope,
        setVolume: (volume) => _driver.setVolume(handle, volume),
        applyImmediately: false,
      );
      if (usesIntroLoop) {
        final looping = loopDriver as FlameCinematicAudioLoopDriver;
        _scheduleLoopReturn(
          driver: looping,
          handle: handle,
          points: loopPoints,
          firstPass: true,
        );
        _loopSubscription = looping.onComplete(handle).listen((_) {
          _requestLoopRestart(looping, handle, loopPoints);
        });
      }
      if (_musicEffects.isNotEmpty) {
        await _applyCurrentVolume(handle);
        await _pauseCurrentHandle(handle);
      }
      lastFailure = null;
    } on Object catch (error) {
      lastFailure = error;
      if (startedHandle != null && identical(_handle, startedHandle)) {
        await _stop(fade: false);
      } else {
        _handle = null;
        _playingPath = null;
      }
    }
  }

  Future<void> _applyCurrentVolume(Object handle) => _mixer.updateSourceVolume(
    handle,
    _playingSourceVolume * _interruptionEnvelope,
  );

  bool _validInterruption(Object handle, int generation) =>
      !_disposed &&
      generation == _interruptionGeneration &&
      identical(_handle, handle);

  Future<void> _fadeInterruption(
    double target,
    Duration duration,
    int generation, {
    bool pauseAtEnd = false,
  }) async {
    final handle = _handle;
    if (handle == null) {
      if (!_disposed && generation == _interruptionGeneration) {
        _interruptionEnvelope = target;
      }
      return;
    }
    final from = _interruptionEnvelope;
    final steps = duration <= Duration.zero ? 1 : _fadeSteps;
    final step = Duration(
      microseconds: (duration.inMicroseconds / steps).ceil(),
    );
    try {
      for (var index = 1; index <= steps; index += 1) {
        if (duration > Duration.zero) await _fadeDelay(step);
        if (!_validInterruption(handle, generation)) return;
        await _enqueue(() async {
          if (!_validInterruption(handle, generation)) return;
          _interruptionEnvelope = from + (target - from) * index / steps;
          await _applyCurrentVolume(handle);
        });
      }
      if (pauseAtEnd) {
        await _enqueue(() async {
          if (!_validInterruption(handle, generation) ||
              _musicEffects.isEmpty) {
            return;
          }
          await _pauseCurrentHandle(handle);
        });
      }
    } on Object catch (error) {
      lastFailure = error;
    }
  }

  Future<void> _resumeInterruption(Duration fadeIn, int generation) async {
    try {
      await _enqueue(() async {
        final handle = _handle;
        if (handle == null || !_validInterruption(handle, generation)) return;
        if (_isPaused) {
          await (_driver as FlameCinematicAudioPausableDriver).resume(handle);
          if (_disposed || !identical(_handle, handle)) return;
          _pausedHandle = null;
          if (_musicEffects.isNotEmpty) {
            _interruptionEnvelope = 0;
            await _applyCurrentVolume(handle);
            await _pauseCurrentHandle(handle);
            return;
          }
          _resumeLoopReturn();
        }
      });
      if (_disposed || generation != _interruptionGeneration) return;
      await _fadeInterruption(1, fadeIn, generation);
    } on Object catch (error) {
      lastFailure = error;
    }
  }

  Future<void> _pauseCurrentHandle(Object handle) async {
    if (!identical(_handle, handle) || _isPaused) return;
    _suspendLoopReturn();
    try {
      await (_driver as FlameCinematicAudioPausableDriver).pause(handle);
      _pausedHandle = handle;
    } on Object {
      _resumeLoopReturn();
      rethrow;
    }
  }

  void _scheduleLoopReturn({
    required FlameCinematicAudioLoopDriver driver,
    required Object handle,
    required RuntimeMusicLoopPoints points,
    required bool firstPass,
  }) {
    final remaining = firstPass ? points.end : points.end - points.start;
    _loopReturnDelay = remaining;
    _loopReturnAction = () {
      _requestLoopRestart(driver, handle, points);
    };
    _armLoopReturn(remaining);
  }

  void _requestLoopRestart(
    FlameCinematicAudioLoopDriver driver,
    Object handle,
    RuntimeMusicLoopPoints points,
  ) {
    if (_disposed ||
        !identical(_handle, handle) ||
        _isPaused ||
        _loopRestartPending) {
      return;
    }
    final generation = _loopGeneration;
    _loopRestartPending = true;
    unawaited(_enqueue(() async {
      try {
        if (generation != _loopGeneration) return;
        await _restartLoop(driver, handle, points);
      } finally {
        _loopRestartPending = false;
      }
    }));
  }

  Future<void> _restartLoop(
    FlameCinematicAudioLoopDriver driver,
    Object handle,
    RuntimeMusicLoopPoints points,
  ) async {
    if (!identical(_handle, handle) || _isPaused || _disposed) return;
    try {
      await driver.seekAndResume(handle, points.start);
      if (!identical(_handle, handle) || _isPaused || _disposed) return;
      _scheduleLoopReturn(
        driver: driver,
        handle: handle,
        points: points,
        firstPass: false,
      );
    } on Object catch (error) {
      lastFailure = error;
    }
  }

  void _armLoopReturn(Duration remaining) {
    _loopReturnTimer?.cancel();
    final generation = ++_loopGeneration;
    _loopReturnDelay = remaining;
    _loopDueAt = _clock() + remaining;
    _loopReturnTimer = _loopTimerFactory(remaining, () {
      if (_disposed || generation != _loopGeneration || _isPaused) return;
      _loopReturnTimer = null;
      _loopDueAt = null;
      _loopReturnAction?.call();
    });
  }

  void _suspendLoopReturn() {
    final dueAt = _loopDueAt;
    if (dueAt != null) {
      final remaining = dueAt - _clock();
      _loopReturnDelay = remaining < Duration.zero ? Duration.zero : remaining;
    }
    _loopReturnTimer?.cancel();
    _loopReturnTimer = null;
    _loopDueAt = null;
    _loopGeneration += 1;
  }

  void _resumeLoopReturn() {
    final remaining = _loopReturnDelay;
    if (_loopReturnAction != null && remaining != null) {
      _armLoopReturn(remaining);
    }
  }

  Future<void> _stop({required bool fade}) async {
    final handle = _handle;
    final fromVolume = _playingSourceVolume * _interruptionEnvelope;
    _interruptionGeneration += 1;
    unawaited(_loopSubscription?.cancel());
    _loopSubscription = null;
    _suspendLoopReturn();
    _loopReturnDelay = null;
    _loopReturnAction = null;
    _handle = null;
    _pausedHandle = null;
    _playingPath = null;
    _interruptionEnvelope = _musicEffects.isEmpty ? 1 : 0;
    if (handle == null) return;
    if (fade && fromVolume > 0) {
      final step = Duration(
        microseconds: (fadeOutDuration.inMicroseconds / _fadeSteps).ceil(),
      );
      for (var index = 1; index <= _fadeSteps; index += 1) {
        await _fadeDelay(step);
        try {
          await _mixer.updateSourceVolume(
            handle,
            fromVolume * (1 - index / _fadeSteps),
          );
        } on Object catch (error) {
          lastFailure = error;
          break;
        }
      }
    }
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

Duration Function() _monotonicClock() {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
}
