import 'dart:math' as math;
import 'dart:ui';

import 'package:map_render_3d/battle_projection_contract.dart';

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
  bool get isFinite => x.isFinite && y.isFinite && z.isFinite;
  double get length => math.sqrt(dot(this));
  BattleCameraPoint get normalized => this * (1 / length);
  double distanceTo(BattleCameraPoint other) => (this - other).length;
}

typedef BattleProjectedPoint = ({Offset position, double depth});
typedef BattleProjectedBillboard = ({Offset position, double scale});

enum BattleCameraEasing {
  legacyTwoSlope,
  linear,
  easeOut;

  double transform(double time) => switch (this) {
    legacyTwoSlope => time < .5 ? time * 4 / 3 : (time + .5) * 2 / 3,
    linear => time,
    easeOut => 1 - (1 - time) * (1 - time),
  };
}

final class BattlePerspectiveCamera {
  BattlePerspectiveCamera({required Rect viewport}) : _viewport = viewport {
    if (!_isValidViewport(viewport)) {
      throw ArgumentError.value(viewport, 'viewport');
    }
  }

  static const homeEye = BattleCameraPoint(6.7, 6.7, 17.3);
  static const homeAim = BattleCameraPoint(0, 2.6, 0);
  Rect _viewport;
  Rect get viewport => _viewport;
  set viewport(Rect value) {
    if (_isValidViewport(value)) _viewport = value;
  }

  BattleCameraPoint _overviewEye = homeEye;
  BattleCameraPoint _overviewAim = homeAim;
  BattleCameraPoint _eye = homeEye;
  BattleCameraPoint _aim = homeAim;
  BattleCameraPoint get eye => _eye;
  set eye(BattleCameraPoint value) {
    _requireValidPose(value, _aim);
    _eye = value;
  }

  BattleCameraPoint get aim => _aim;
  set aim(BattleCameraPoint value) {
    _requireValidPose(_eye, value);
    _aim = value;
  }

  BattleCameraPoint _startEye = homeEye;
  BattleCameraPoint _startAim = homeAim;
  BattleCameraPoint _goalEye = homeEye;
  BattleCameraPoint _goalAim = homeAim;
  double _elapsed = 0;
  double _duration = 0;
  double _segmentStartProgress = 0;
  ({Offset foot, Rect viewport, bool playerSide, double strength})?
  _focusIntent;
  BattleCameraEasing _easing = BattleCameraEasing.legacyTwoSlope;

  static double _focalFor(Rect viewport) => math.min(
    viewport.width * 1.5,
    viewport.height / (2 * math.tan(13 * math.pi / 180)),
  );

  static bool _isValidViewport(Rect value) =>
      value.left.isFinite &&
      value.top.isFinite &&
      value.right.isFinite &&
      value.bottom.isFinite &&
      BattleProjectionContract.isValidFrame(
        value.size,
        _focalFor(value),
        Offset(value.center.dx, value.top + value.height * .55),
      );

  static bool _isValidPose(BattleCameraPoint eye, BattleCameraPoint aim) {
    final direction = aim - eye;
    return eye.isFinite &&
        aim.isFinite &&
        BattleProjectionContract.isValidDirection(
          direction.x,
          direction.y,
          direction.z,
        );
  }

  static void _requireValidPose(BattleCameraPoint eye, BattleCameraPoint aim) {
    if (!_isValidPose(eye, aim)) {
      throw ArgumentError('Battle camera requires a finite nonvertical view.');
    }
  }

  double get focal => _focalFor(viewport);
  bool get isMoving => _duration > 0 && _elapsed < _duration;
  bool get isHome =>
      eye.distanceTo(_overviewEye) < .00001 &&
      aim.distanceTo(_overviewAim) < .00001;
  bool get _isNeutral =>
      eye.distanceTo(homeEye) < .00001 && aim.distanceTo(homeAim) < .00001;

  ({BattleCameraPoint forward, BattleCameraPoint right, BattleCameraPoint up})
  _basis(BattleCameraPoint eye, BattleCameraPoint aim) {
    final forward = (aim - eye).normalized;
    final right = forward.cross(const BattleCameraPoint(0, 1, 0)).normalized;
    return (forward: forward, right: right, up: right.cross(forward));
  }

  BattleProjectedPoint? _tryProject(
    BattleCameraPoint point,
    BattleCameraPoint eye,
    BattleCameraPoint aim,
  ) {
    if (!point.isFinite) return null;
    final axes = _basis(eye, aim);
    final delta = point - eye;
    final depth = BattleProjectionContract.viewDepth(
      point: (x: point.x, y: point.y, z: point.z),
      eye: (x: eye.x, y: eye.y, z: eye.z),
      aim: (x: aim.x, y: aim.y, z: aim.z),
    );
    if (!BattleProjectionContract.containsDepth(depth)) return null;
    final position = Offset(
      viewport.center.dx + delta.dot(axes.right) * focal / depth,
      viewport.top + viewport.height * .55 - delta.dot(axes.up) * focal / depth,
    );
    if (!position.dx.isFinite || !position.dy.isFinite) return null;
    return (position: position, depth: depth);
  }

  BattleProjectedPoint _project(
    BattleCameraPoint point,
    BattleCameraPoint eye,
    BattleCameraPoint aim,
  ) =>
      _tryProject(point, eye, aim) ??
      (throw StateError('Battle point is outside the camera depth domain.'));

  BattleProjectedPoint? tryProject(BattleCameraPoint point) =>
      _tryProject(point, eye, aim);

  BattleProjectedPoint project(BattleCameraPoint point) =>
      _project(point, eye, aim);

  double get groundHorizonY {
    final axes = _basis(eye, aim);
    return viewport.top +
        viewport.height * .55 +
        focal * axes.forward.y / axes.up.y;
  }

  BattleCameraPoint? tryGroundAt(Offset screen) {
    if (!screen.dx.isFinite || !screen.dy.isFinite) return null;
    final axes = _basis(homeEye, homeAim);
    final ray =
        axes.forward +
        axes.right * ((screen.dx - viewport.center.dx) / focal) +
        axes.up * ((viewport.top + viewport.height * .55 - screen.dy) / focal);
    if (!ray.isFinite || ray.y >= -BattleProjectionContract.directionEpsilon) {
      return null;
    }
    final distance = -homeEye.y / ray.y;
    if (!distance.isFinite || distance <= 0) return null;
    final point = homeEye + ray * distance;
    return point.isFinite ? point : null;
  }

  BattleCameraPoint groundAt(Offset screen) =>
      tryGroundAt(screen) ??
      (throw StateError('Screen ray does not intersect the ground in front.'));

  BattleProjectedBillboard? tryBillboardAt(Offset homeFoot) {
    final point = tryGroundAt(homeFoot);
    if (point == null) return null;
    final home = _tryProject(point, homeEye, homeAim);
    final current = tryProject(point);
    if (home == null || current == null) return null;
    if (_isNeutral) return (position: homeFoot, scale: 1);
    return (position: current.position, scale: home.depth / current.depth);
  }

  BattleProjectedBillboard billboardAt(Offset homeFoot) =>
      tryBillboardAt(homeFoot) ??
      (throw StateError('Billboard is outside the camera depth domain.'));

  ({BattleCameraPoint position, double width, double height})?
  tryBillboardWorldGeometry(Offset homeFoot, Rect neutralSpriteRect) {
    if (!neutralSpriteRect.left.isFinite ||
        !neutralSpriteRect.top.isFinite ||
        !neutralSpriteRect.right.isFinite ||
        !neutralSpriteRect.bottom.isFinite ||
        neutralSpriteRect.isEmpty) {
      return null;
    }
    final ground = tryGroundAt(homeFoot);
    if (ground == null) return null;
    final home = _tryProject(ground, homeEye, homeAim);
    if (home == null || tryProject(ground) == null) return null;
    final unit = home.depth / focal;
    final axes = _basis(eye, aim);
    final offset = neutralSpriteRect.bottomCenter - homeFoot;
    final position =
        ground + axes.right * (offset.dx * unit) - axes.up * (offset.dy * unit);
    final width = neutralSpriteRect.width * unit;
    final height = neutralSpriteRect.height * unit;
    if (!position.isFinite || !width.isFinite || !height.isFinite) return null;
    return (position: position, width: width, height: height);
  }

  ({BattleCameraPoint position, double width, double height})
  billboardWorldGeometry(Offset homeFoot, Rect neutralSpriteRect) =>
      tryBillboardWorldGeometry(homeFoot, neutralSpriteRect) ??
      (throw StateError('Billboard geometry is outside the camera domain.'));

  Path groundEllipse(Offset homeCenter, Size size) {
    final path = Path();
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return path;
    }
    for (var i = 0; i < 40; i++) {
      final angle = i * math.pi * 2 / 40;
      final home =
          homeCenter +
          Offset(
            math.cos(angle) * size.width / 2,
            math.sin(angle) * size.height / 2,
          );
      final ground = tryGroundAt(home);
      if (ground == null) return Path();
      final projected = tryProject(ground);
      if (projected == null) return Path();
      final point = _isNeutral ? home : projected.position;
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

  ({BattleCameraPoint eye, BattleCameraPoint aim}) idealFocusPose(
    Offset homeFoot, {
    required bool playerSide,
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
    return (
      eye: homeEye + (targetEye - homeEye) * strength,
      aim: homeAim + (targetAim - homeAim) * strength,
    );
  }

  void focus(
    Offset homeFoot, {
    required bool playerSide,
    required double durationSeconds,
    double strength = 1,
    ({BattleCameraPoint eye, BattleCameraPoint aim})? resolvedPose,
  }) {
    if (!strength.isFinite) throw ArgumentError.value(strength, 'strength');
    final pose =
        resolvedPose ??
        idealFocusPose(homeFoot, playerSide: playerSide, strength: strength);
    moveTo(eye: pose.eye, aim: pose.aim, durationSeconds: durationSeconds);
    _focusIntent = (
      foot: homeFoot,
      viewport: viewport,
      playerSide: playerSide,
      strength: strength,
    );
  }

  void reflowFocus(
    Offset homeFoot, {
    ({BattleCameraPoint eye, BattleCameraPoint aim})? resolvedPose,
  }) {
    final intent = _focusIntent;
    if (intent == null ||
        resolvedPose == null &&
            intent.foot == homeFoot &&
            intent.viewport == viewport) {
      return;
    }
    if (tryGroundAt(homeFoot) == null) {
      cancel();
      return;
    }
    final pose =
        resolvedPose ??
        idealFocusPose(
          homeFoot,
          playerSide: intent.playerSide,
          strength: intent.strength,
        );
    _requireValidPose(pose.eye, pose.aim);
    _retarget(pose);
    _focusIntent = (
      foot: homeFoot,
      viewport: viewport,
      playerSide: intent.playerSide,
      strength: intent.strength,
    );
  }

  void moveTo({
    required BattleCameraPoint eye,
    required BattleCameraPoint aim,
    required double durationSeconds,
    BattleCameraEasing easing = BattleCameraEasing.legacyTwoSlope,
  }) {
    _requireValidPose(eye, aim);
    if (!durationSeconds.isFinite) {
      throw ArgumentError.value(durationSeconds, 'durationSeconds');
    }
    _focusIntent = null;
    _segmentStartProgress = 0;
    _startEye = this.eye;
    _startAim = this.aim;
    _goalEye = eye;
    _goalAim = aim;
    _elapsed = 0;
    _easing = easing;
    _duration = math.max(0, durationSeconds);
    if (_duration == 0) {
      _eye = eye;
      _aim = aim;
    }
  }

  void reflowOverview(({BattleCameraPoint eye, BattleCameraPoint aim}) pose) {
    _requireValidPose(pose.eye, pose.aim);
    final held =
        _focusIntent == null &&
        !isMoving &&
        eye.distanceTo(_overviewEye) < .00001 &&
        aim.distanceTo(_overviewAim) < .00001;
    final returning =
        _focusIntent == null &&
        isMoving &&
        _goalEye.distanceTo(_overviewEye) < .00001 &&
        _goalAim.distanceTo(_overviewAim) < .00001;
    _overviewEye = pose.eye;
    _overviewAim = pose.aim;
    if (held) {
      _eye = pose.eye;
      _aim = pose.aim;
    } else if (returning) {
      _retarget(pose);
    }
  }

  void _retarget(({BattleCameraPoint eye, BattleCameraPoint aim}) pose) {
    _goalEye = pose.eye;
    _goalAim = pose.aim;
    if (isMoving) {
      _startEye = eye;
      _startAim = aim;
      _segmentStartProgress = _easing.transform(_elapsed / _duration);
    } else {
      _eye = pose.eye;
      _aim = pose.aim;
    }
  }

  void reset({required double durationSeconds}) => moveTo(
    eye: _overviewEye,
    aim: _overviewAim,
    durationSeconds: durationSeconds,
  );

  void cancel() => reset(durationSeconds: 0);

  void update(double dt) {
    if (!isMoving || !dt.isFinite || dt <= 0) return;
    _elapsed = math.min(_duration, _elapsed + dt);
    if (_duration - _elapsed < .000001) _elapsed = _duration;
    final time = _elapsed / _duration;
    final progress =
        ((_easing.transform(time) - _segmentStartProgress) /
                (1 - _segmentStartProgress))
            .clamp(0.0, 1.0);
    final nextEye = _startEye + (_goalEye - _startEye) * progress;
    final nextAim = _startAim + (_goalAim - _startAim) * progress;
    if (!_isValidPose(nextEye, nextAim)) {
      _goalEye = _eye;
      _goalAim = _aim;
      _duration = 0;
      return;
    }
    _eye = nextEye;
    _aim = nextAim;
    if (!isMoving) {
      _eye = _goalEye;
      _aim = _goalAim;
    }
  }
}
