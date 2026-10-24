import 'dart:math' as math;

final class PartyCompanionTrailPoint {
  const PartyCompanionTrailPoint(this.x, this.z,
      {this.y = 0,
      this.groundY = 0,
      this.airborne = false,
      this.traversalSpeed = 5});
  final double x;
  final double z;
  final double y, groundY;
  final bool airborne;
  final double traversalSpeed;
}

final class PartyCompanionTrail {
  final _points = <PartyCompanionTrailPoint>[];
  String? _mapId, _individualId;
  double _distance = 0;
  double _followingDistance = 1;
  PartyCompanionTrailPoint? position;
  bool moving = false;
  double animationSeconds = 0;
  double facingX = 0, facingZ = 1;

  void clear() {
    _points.clear();
    _distance = 0;
    _followingDistance = 1;
    position = null;
    moving = false;
    animationSeconds = 0;
    _mapId = null;
    _individualId = null;
  }

  void observe(
      {required String mapId,
      required String individualId,
      required double x,
      required double z,
      double y = 0,
      double groundY = 0,
      bool airborne = false,
      double traversalSpeed = 5,
      bool paused = false,
      double dt = 0,
      bool Function(double fromX, double fromZ, double toX, double toZ)?
          canTraverse}) {
    if (paused) return;
    if (!x.isFinite ||
        !z.isFinite ||
        !y.isFinite ||
        !groundY.isFinite ||
        !traversalSpeed.isFinite ||
        traversalSpeed <= 0 ||
        individualId.isEmpty) {
      clear();
      return;
    }
    if (_mapId != mapId || _individualId != individualId || _points.isEmpty) {
      clear();
      _mapId = mapId;
      _individualId = individualId;
      _points.add(PartyCompanionTrailPoint(x, z,
          y: y,
          groundY: groundY,
          airborne: airborne,
          traversalSpeed: traversalSpeed));
      return;
    }
    final previous = position;
    final last = _points.last;
    final distance = _length(
        last,
        PartyCompanionTrailPoint(x, z,
            y: y,
            groundY: groundY,
            airborne: airborne,
            traversalSpeed: traversalSpeed));
    if (distance > 2) {
      clear();
      observe(
          mapId: mapId,
          individualId: individualId,
          x: x,
          z: z,
          y: y,
          groundY: groundY,
          airborne: airborne,
          traversalSpeed: traversalSpeed);
      return;
    }
    if (distance > 0) {
      _points.add(PartyCompanionTrailPoint(x, z,
          y: y,
          groundY: groundY,
          airborne: airborne,
          traversalSpeed: traversalSpeed));
      _distance += distance;
    }
    bool traverse(PartyCompanionTrailPoint from, PartyCompanionTrailPoint to) =>
        (from.airborne || to.airborne) ||
        (canTraverse?.call(from.x, from.z, to.x, to.z) ?? true);
    var blocked = false;
    if (position?.airborne ?? false) {
      final elapsed = dt.isFinite && dt > 0 ? dt.clamp(0.0, .05) : 0.0;
      _followingDistance =
          math.max(0, _followingDistance - position!.traversalSpeed * elapsed);
    }
    while (_distance > _followingDistance && _points.length > 1) {
      final first = _points.first, next = _points[1];
      final segment = _length(first, next);
      if (_distance - segment >= _followingDistance) {
        if (!traverse(first, next)) {
          blocked = true;
          break;
        }
        _points.removeAt(0);
        _distance -= segment;
      } else {
        final portion = (_distance - _followingDistance) / segment;
        final target = PartyCompanionTrailPoint(
            first.x + (next.x - first.x) * portion,
            first.z + (next.z - first.z) * portion,
            y: first.y + (next.y - first.y) * portion,
            groundY: first.groundY + (next.groundY - first.groundY) * portion,
            airborne: first.airborne || next.airborne,
            traversalSpeed:
                first.airborne ? first.traversalSpeed : next.traversalSpeed);
        if (!traverse(first, target)) {
          blocked = true;
          break;
        }
        _points[0] = target;
        _distance = _followingDistance;
      }
    }
    if (_distance >= _followingDistance && !blocked) {
      final target = _points.first;
      blocked = !traverse(target, target);
      if (!blocked) position = target;
    }
    if (blocked) {
      clear();
      observe(
          mapId: mapId,
          individualId: individualId,
          x: x,
          z: z,
          y: y,
          groundY: groundY,
          airborne: airborne,
          traversalSpeed: traversalSpeed);
      return;
    }
    if (position != null && !position!.airborne) _followingDistance = 1;
    moving = previous != null &&
        position != null &&
        _length(previous, position!) > 0;
    if (moving) {
      facingX = position!.x - previous!.x;
      facingZ = position!.z - previous.z;
    }
    if (position != null && dt.isFinite && dt > 0) animationSeconds += dt;
  }

  double _length(PartyCompanionTrailPoint a, PartyCompanionTrailPoint b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.z - b.z, 2));
}
