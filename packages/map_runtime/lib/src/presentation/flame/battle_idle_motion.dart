import 'dart:math' as math;

final class BattleIdleMotion {
  BattleIdleMotion({required this.periodSeconds, this.direction = 1})
    : assert(periodSeconds > 0);

  final double periodSeconds;
  final double direction;
  double _elapsed = 0;
  double get offsetRatio =>
      math.sin(_elapsed * math.pi * 2 / periodSeconds) * direction;

  double advance(double dt, {required bool waiting}) {
    if (waiting && dt.isFinite && dt > 0) {
      _elapsed = (_elapsed + dt) % periodSeconds;
    }
    return offsetRatio;
  }
}
