import 'dart:math' as math;
import 'dart:ui';

final class BattleCameraPoint {
  const BattleCameraPoint(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  BattleCameraPoint operator +(BattleCameraPoint other) =>
      BattleCameraPoint(x + other.x, y + other.y, z + other.z);
  BattleCameraPoint operator -(BattleCameraPoint other) =>
      BattleCameraPoint(x - other.x, y - other.y, z - other.z);
  BattleCameraPoint operator *(double value) =>
      BattleCameraPoint(x * value, y * value, z * value);
  double dot(BattleCameraPoint other) =>
      x * other.x + y * other.y + z * other.z;
  BattleCameraPoint cross(BattleCameraPoint other) => BattleCameraPoint(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );
  double get length => math.sqrt(dot(this));
  BattleCameraPoint get normalized => this * (1 / length);
  double distanceTo(BattleCameraPoint other) => (this - other).length;
}

typedef BattleProjectedPoint = ({Offset position, double depth});
typedef BattleProjectedBillboard = ({Offset position, double scale});

final class BattlePerspectiveCamera {
  BattlePerspectiveCamera({required this.viewport});

  static const homeEye = BattleCameraPoint(6.7, 6.7, 17.3);
  static const homeAim = BattleCameraPoint(0, 2.6, 0);
  Rect viewport;
  BattleCameraPoint eye = homeEye;
  BattleCameraPoint aim = homeAim;
  BattleCameraPoint _startEye = homeEye;
  BattleCameraPoint _startAim = homeAim;
  BattleCameraPoint _goalEye = homeEye;
  BattleCameraPoint _goalAim = homeAim;
  double _elapsed = 0;
  double _duration = 0;

  double get focal => math.min(
    viewport.width * 1.5,
    viewport.height / (2 * math.tan(13 * math.pi / 180)),
  );
  bool get isMoving => _duration > 0 && _elapsed < _duration;
  bool get isHome =>
      eye.distanceTo(homeEye) < .00001 && aim.distanceTo(homeAim) < .00001;

  ({BattleCameraPoint forward, BattleCameraPoint right, BattleCameraPoint up})
  _basis(BattleCameraPoint eye, BattleCameraPoint aim) {
    final forward = (aim - eye).normalized;
    final right = forward.cross(const BattleCameraPoint(0, 1, 0)).normalized;
    return (forward: forward, right: right, up: right.cross(forward));
  }

  BattleProjectedPoint _project(
    BattleCameraPoint point,
    BattleCameraPoint eye,
    BattleCameraPoint aim,
  ) {
    final axes = _basis(eye, aim);
    final delta = point - eye;
    final depth = math.max(.2, delta.dot(axes.forward));
    return (
      position: Offset(
        viewport.center.dx + delta.dot(axes.right) * focal / depth,
        viewport.top +
            viewport.height * .55 -
            delta.dot(axes.up) * focal / depth,
      ),
      depth: depth,
    );
  }

  BattleProjectedPoint project(BattleCameraPoint point) =>
      _project(point, eye, aim);

  double get groundHorizonY {
    final axes = _basis(eye, aim);
    return viewport.top + viewport.height * .55 +
        focal * axes.forward.y / math.max(.001, axes.up.y);
  }

  BattleCameraPoint groundAt(Offset screen) {
    final axes = _basis(homeEye, homeAim);
    final ray =
        axes.forward +
        axes.right * ((screen.dx - viewport.center.dx) / focal) +
        axes.up * ((viewport.top + viewport.height * .55 - screen.dy) / focal);
    final distance = -homeEye.y / math.min(-.0001, ray.y);
    return homeEye + ray * distance;
  }

  BattleProjectedBillboard billboardAt(Offset homeFoot) {
    if (isHome) return (position: homeFoot, scale: 1);
    final point = groundAt(homeFoot);
    final home = _project(point, homeEye, homeAim);
    final current = project(point);
    return (
      position: current.position,
      scale: home.depth / current.depth,
    );
  }

  ({BattleCameraPoint position, double width, double height}) billboardWorldGeometry(Offset homeFoot, Rect neutralSpriteRect) {
    final ground = groundAt(homeFoot);
    final unit = _project(ground, homeEye, homeAim).depth / focal;
    final axes = _basis(eye, aim);
    final offset = neutralSpriteRect.bottomCenter - homeFoot;
    return (
      position: ground + axes.right * (offset.dx * unit) - axes.up * (offset.dy * unit),
      width: neutralSpriteRect.width * unit,
      height: neutralSpriteRect.height * unit,
    );
  }

  Path groundEllipse(Offset homeCenter, Size size) {
    final path = Path();
    for (var i = 0; i < 40; i++) {
      final angle = i * math.pi * 2 / 40;
      final home =
          homeCenter +
          Offset(
            math.cos(angle) * size.width / 2,
            math.sin(angle) * size.height / 2,
          );
      final point = isHome ? home : project(groundAt(home)).position;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Offset get backdropOffset {
    final direction = aim - eye;
    final homeDirection = homeAim - homeEye;
    final yaw =
        math.atan2(direction.x, -direction.z) -
        math.atan2(homeDirection.x, -homeDirection.z);
    final pitch =
        math.atan2(
          direction.y,
          math.sqrt(direction.x * direction.x + direction.z * direction.z),
        ) -
        math.atan2(
          homeDirection.y,
          math.sqrt(
            homeDirection.x * homeDirection.x +
                homeDirection.z * homeDirection.z,
          ),
        );
    final delta = eye - homeEye;
    final axes = _basis(homeEye, homeAim);
    return Offset(
      (-math.tan(yaw) * focal * .8 - delta.dot(axes.right) * focal / 60).clamp(
        -viewport.width * .1,
        viewport.width * .1,
      ),
      (math.tan(pitch) * focal * .5 + delta.dot(axes.up) * focal / 60).clamp(
        -viewport.height * .1,
        viewport.height * .1,
      ),
    );
  }

  void focus(
    Offset homeFoot, {
    required bool playerSide,
    required double durationSeconds,
    double strength = 1,
  }) {
    final source = groundAt(homeFoot);
    final targetAim = BattleCameraPoint(
      source.x,
      playerSide ? 1.85 : 2.85,
      source.z,
    );
    final direction = (homeEye - homeAim).normalized;
    final homeDepth = _project(source, homeEye, homeAim).depth;
    final distance = math.max(
      .2,
      homeDepth / 1.08 - (targetAim - source).dot(direction),
    );
    final targetEye = targetAim + direction * distance;
    moveTo(
      eye: homeEye + (targetEye - homeEye) * strength,
      aim: homeAim + (targetAim - homeAim) * strength,
      durationSeconds: durationSeconds,
    );
  }

  void moveTo({
    required BattleCameraPoint eye,
    required BattleCameraPoint aim,
    required double durationSeconds,
  }) {
    if (_goalEye.distanceTo(eye) < .00001 &&
        _goalAim.distanceTo(aim) < .00001 &&
        isMoving) {
      return;
    }
    _startEye = this.eye;
    _startAim = this.aim;
    _goalEye = eye;
    _goalAim = aim;
    _elapsed = 0;
    _duration = math.max(0, durationSeconds);
    if (_duration == 0) {
      this.eye = eye;
      this.aim = aim;
    }
  }

  void reset({required double durationSeconds}) =>
      moveTo(eye: homeEye, aim: homeAim, durationSeconds: durationSeconds);

  void update(double dt) {
    if (!isMoving || !dt.isFinite || dt <= 0) return;
    _elapsed = math.min(_duration, _elapsed + dt);
    if (_duration - _elapsed < .000001) _elapsed = _duration;
    final time = _elapsed / _duration;
    final progress = time < .5 ? time * 4 / 3 : (time + .5) * 2 / 3;
    eye = _startEye + (_goalEye - _startEye) * progress;
    aim = _startAim + (_goalAim - _startAim) * progress;
    if (!isMoving) {
      eye = _goalEye;
      aim = _goalAim;
    }
  }
}
