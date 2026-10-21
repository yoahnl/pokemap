import 'dart:async';

import 'runtime_audio_mixer.dart';

typedef RuntimeSceneMusicSelection = ({
  RuntimeAudioRoute route,
  String? path,
  double volume,
});

typedef RuntimeSceneMusicTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

final class RuntimeSceneMusicController {
  RuntimeSceneMusicController({
    required this.owner,
    required this.isOwnerCurrent,
    required this.captureBaseline,
    required this.onChanged,
    RuntimeSceneMusicTimerFactory? timerFactory,
    this.fadeSteps = 12,
  }) : _timerFactory = timerFactory ?? Timer.new {
    if (fadeSteps < 1 || fadeSteps > 120) {
      throw RangeError.range(fadeSteps, 1, 120, 'fadeSteps');
    }
  }

  final Object owner;
  final int fadeSteps;
  final bool Function(Object owner) isOwnerCurrent;
  final RuntimeSceneMusicSelection Function() captureBaseline;
  final Future<void> Function() onChanged;
  final RuntimeSceneMusicTimerFactory _timerFactory;
  RuntimeSceneMusicSelection? _selection;
  RuntimeSceneMusicSelection? _baseline;
  Timer? _fadeTimer;
  int _generation = 0;
  bool _closed = false;
  Object? lastFailure;
  Object? _transactionFailure;
  Future<void>? _pendingFadeChange;

  Object? get transactionFailure => _transactionFailure;

  bool get isCurrent => !_closed && isOwnerCurrent(owner);
  RuntimeSceneMusicSelection? get selection => _closed ? null : _selection;

  Future<bool> play({required String path, required double volume}) async {
    if (!isCurrent) return false;
    if (path.trim().isEmpty || !volume.isFinite || volume < 0 || volume > 1) {
      throw ArgumentError(
        'Scene music requires a path and finite volume 0..1.',
      );
    }
    final previous = _selection;
    final previousBaseline = _baseline;
    _cancelFade();
    _baseline ??= captureBaseline();
    _selection = (
      route: RuntimeAudioRoute.cinematicMusic,
      path: path,
      volume: volume,
    );
    final generation = _generation;
    try {
      await onChanged();
      lastFailure = null;
      return isCurrent && generation == _generation;
    } catch (error) {
      if (isCurrent && generation == _generation) {
        _selection = previous;
        _baseline = previousBaseline;
        await _restoreAfterFailure(error);
      }
      rethrow;
    }
  }

  Future<bool> restore() async {
    if (!isCurrent) return false;
    _cancelFade();
    final baseline = _baseline;
    if (baseline == null) return true;
    final previous = _selection;
    _selection = baseline;
    _baseline = null;
    final generation = _generation;
    try {
      await onChanged();
      lastFailure = null;
      return isCurrent && generation == _generation;
    } catch (error) {
      if (isCurrent && generation == _generation) {
        _selection = previous;
        _baseline = baseline;
        await _restoreAfterFailure(error);
      }
      rethrow;
    }
  }

  Future<bool> fadeOut({required Duration duration}) async {
    if (!isCurrent) return false;
    if (duration < Duration.zero || duration > const Duration(seconds: 60)) {
      throw RangeError('Scene music fade must be within 0..60000ms.');
    }
    _cancelFade();
    _baseline ??= captureBaseline();
    _selection ??= _baseline;
    final generation = _generation;
    final start = _selection!;
    if (duration == Duration.zero) {
      _selection = (route: start.route, path: start.path, volume: 0.0);
      try {
        await onChanged();
        return isCurrent && generation == _generation;
      } catch (error) {
        if (isCurrent && generation == _generation) {
          _selection = start;
          await _restoreAfterFailure(error);
        }
        rethrow;
      }
    }
    final stepUs = (duration.inMicroseconds / fadeSteps).ceil();
    void schedule(int step) {
      _fadeTimer = _timerFactory(Duration(microseconds: stepUs), () {
        _fadeTimer = null;
        if (!isCurrent || generation != _generation) return;
        _selection = (
          route: start.route,
          path: start.path,
          volume: start.volume * (1 - step / fadeSteps),
        );
        final change = () async {
          try {
            await onChanged();
            if (isCurrent && generation == _generation && step < fadeSteps) {
              schedule(step + 1);
            }
          } catch (error) {
            lastFailure = error;
            _transactionFailure ??= error;
            if (isCurrent && generation == _generation) {
              _cancelFade();
              _selection = start;
              await _restoreAfterFailure(error);
            }
          }
        }();
        _pendingFadeChange = change;
        unawaited(
          change.whenComplete(() {
            if (identical(_pendingFadeChange, change)) {
              _pendingFadeChange = null;
            }
          }),
        );
      });
    }

    schedule(1);
    return true;
  }

  Future<void> close() async {
    if (_closed) return;
    final publish = isCurrent;
    _cancelFade();
    _closed = true;
    _selection = null;
    _baseline = null;
    await _pendingFadeChange;
    if (publish && isOwnerCurrent(owner)) {
      try {
        await onChanged();
      } catch (error) {
        lastFailure = error;
        _transactionFailure ??= error;
      }
    }
  }

  Future<void> _restoreAfterFailure(Object error) async {
    lastFailure = error;
    _transactionFailure ??= error;
    try {
      await onChanged();
    } catch (_) {
      lastFailure = error;
    }
  }

  void _cancelFade() {
    _generation++;
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }
}
