import 'dart:math' as math;

import 'package:map_core/map_core.dart';

({double intensity, double width, double height, double lean})
spatialFlameMotion(
  double seconds, {
  required double phase,
  required double flicker,
}) {
  final t = seconds + phase;
  final wave =
      math.sin(t * 3.7) * .5 +
      math.sin(t * 7.1 + .8) * .3 +
      math.sin(t * 1.9 + 2) * .2;
  return (
    intensity: 1 + wave * flicker,
    width: 1 - wave * .1,
    height: 1 + wave * .12,
    lean: math.sin(t * 2.3) * .06 + math.sin(t * 5.1) * .025,
  );
}

double spatialFlamePhase(double x, double y, double z) =>
    (x * 12.9898 + y * 4.1414 + z * 78.233) % 19;

final class SpatialLightProximityState {
  ModelLightProximity? _rule;
  bool _inside = false;
  double _strength = 1;
  double? _elapsed;
  double sample({
    required ModelLightProximity? rule,
    required double distanceSquared,
    required double elapsedSeconds,
  }) {
    if (rule == null) {
      _rule = null;
      _elapsed = elapsedSeconds;
      return _strength = 1;
    }
    if (_rule != rule || _elapsed == null || elapsedSeconds < _elapsed!) {
      _rule = rule;
      _inside = distanceSquared < rule.exitDistance * rule.exitDistance;
      _elapsed = elapsedSeconds;
      return _strength =
          (_inside == (rule.mode == ModelLightProximityMode.near)) ? 1 : 0;
    }
    if (distanceSquared <= rule.enterDistance * rule.enterDistance)
      _inside = true;
    if (distanceSquared >= rule.exitDistance * rule.exitDistance)
      _inside = false;
    final target = _inside == (rule.mode == ModelLightProximityMode.near)
        ? 1.0
        : 0.0;
    final amount =
        (elapsedSeconds - _elapsed!).clamp(0.0, 1.0) / rule.fadeSeconds;
    _elapsed = elapsedSeconds;
    return _strength = target > _strength
        ? (_strength + amount).clamp(0.0, target)
        : (_strength - amount).clamp(target, 1.0);
  }
}
