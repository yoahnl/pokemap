import 'dart:async';
import 'package:map_core/map_core_domain.dart';

class PresentationPreviewTransport {
  final Set<void Function()> _listeners = {};
  final _evaluator = const PresentationCinematicEvaluator();
  final _watch = Stopwatch();
  PresentationPlaybackClock _clock = PresentationPlaybackClock(durationUs: 0);
  Timer? _timer;
  int _lastElapsed = 0;
  bool _disposed = false;
  PresentationCinematicAsset? asset;
  PresentationFrame? frame;
  int frameEvaluations = 0;
  int mediaEpoch = 0;

  int get timeUs => _clock.playheadUs;
  int get durationUs => _clock.durationUs;
  bool get playing => _clock.narrativeClockRunning;
  bool get loop => _clock.loop;
  PresentationPlaybackStatus get status => _clock.status;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void install(PresentationCinematicAsset value, {bool preserveTime = false}) {
    if (_disposed) return;
    final previousTime = preserveTime ? timeUs : 0;
    _cancelTimer();
    _clock.dispose();
    asset = value;
    _clock = PresentationPlaybackClock(
      durationUs: value.durationUs,
      initialPlayheadUs: previousTime,
    );
    mediaEpoch++;
    _publish();
  }

  void clear() {
    if (_disposed) return;
    _cancelTimer();
    _clock.dispose();
    _clock = PresentationPlaybackClock(durationUs: 0);
    asset = null;
    frame = null;
    mediaEpoch++;
    _notify();
  }

  void seek(int value) {
    if (_disposed) return;
    _cancelTimer();
    _clock.pause();
    _clock.seekTo(value.clamp(0, durationUs));
    mediaEpoch++;
    _publish();
  }

  void play() {
    if (_disposed || playing || asset == null) return;
    final token = _clock.play();
    if (token == null) return;
    _lastElapsed = 0;
    _watch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final elapsed = _watch.elapsedMicroseconds;
      final delta = elapsed - _lastElapsed;
      _lastElapsed = elapsed;
      if (_clock.advanceBy(delta, token: token)) _publish();
      if (!playing) _cancelTimer();
    });
    _publish();
  }

  void advance(int deltaUs) {
    if (_disposed) return;
    if (_clock.advanceBy(deltaUs, token: _clock.token)) _publish();
    if (!playing) _cancelTimer();
  }

  void pause() {
    if (_disposed) return;
    _cancelTimer();
    _clock.pause();
    _notify();
  }

  void stop() {
    if (_disposed) return;
    _cancelTimer();
    _clock.stop();
    mediaEpoch++;
    _publish();
  }

  void stepForward() => seek(timeUs + _clock.frameStepUs);
  void stepBackward() => seek(timeUs - _clock.frameStepUs);
  void setLoop(bool value) {
    if (_disposed) return;
    _clock.setLoop(value);
    _notify();
  }

  void _publish() {
    final current = asset;
    frame = current == null
        ? null
        : _evaluator.evaluate(current, timeUs: timeUs);
    if (current != null) frameEvaluations++;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    for (final listener in _listeners.toList()) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _watch.stop();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimer();
    _clock.dispose();
    _listeners.clear();
  }
}
