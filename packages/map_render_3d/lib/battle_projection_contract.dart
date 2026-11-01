import 'dart:math' as math;
import 'dart:ui';

typedef BattleProjectionCoordinates = ({double x, double y, double z});

abstract final class BattleProjectionContract {
  static const near = .01;
  static const far = 1000.0;
  static const directionEpsilon = 1e-10;

  static bool containsDepth(double depth) =>
      depth.isFinite && depth > near && depth < far;

  static double viewDepth({
    required BattleProjectionCoordinates point,
    required BattleProjectionCoordinates eye,
    required BattleProjectionCoordinates aim,
  }) {
    final x = aim.x - eye.x;
    final y = aim.y - eye.y;
    final z = aim.z - eye.z;
    final inverseLength = 1 / math.sqrt(x * x + y * y + z * z);
    return (point.x - eye.x) * (x * inverseLength) +
        (point.y - eye.y) * (y * inverseLength) +
        (point.z - eye.z) * (z * inverseLength);
  }

  static bool isValidFrame(Size size, double focal, Offset center) =>
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0 &&
      focal.isFinite &&
      focal > 0 &&
      (focal / size.width).isFinite &&
      focal / size.width > 0 &&
      (focal / size.height).isFinite &&
      focal / size.height > 0 &&
      center.dx.isFinite &&
      center.dy.isFinite;

  static bool isValidDirection(double x, double y, double z) {
    if (!x.isFinite || !y.isFinite || !z.isFinite) return false;
    final lengthSquared = x * x + y * y + z * z;
    final horizontalSquared = x * x + z * z;
    return lengthSquared.isFinite &&
        lengthSquared > directionEpsilon * directionEpsilon &&
        math.sqrt(horizontalSquared / lengthSquared) > directionEpsilon;
  }
}
