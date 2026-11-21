import 'package:flutter/scheduler.dart';

final class SpatialExplorationClock {
  SpatialExplorationClock(this._advance);

  final void Function(double dt) _advance;
  late final Ticker _ticker = Ticker(_tick);
  Duration _previous = Duration.zero;
  bool presented = false;

  set enabled(bool value) {
    if (value == _ticker.isActive) return;
    if (value) {
      _ticker.start();
    } else {
      _ticker.stop();
      _previous = Duration.zero;
    }
  }

  void _tick(Duration elapsed) {
    final delta = elapsed - _previous;
    _previous = elapsed;
    if (presented) {
      _advance(delta.inMicroseconds / Duration.microsecondsPerSecond);
    }
  }

  void dispose() => _ticker.dispose();
}
