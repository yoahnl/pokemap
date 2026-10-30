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
  bool _recovering = false;

  String? get mapId => _mapId;
  String? get individualId => _individualId;

  PartyCompanionTrail capture() => PartyCompanionTrail()..restore(this);

  void translate(double x, double z, {required double groundY}) {
    if (![x, z, groundY].every((value) => value.isFinite)) throw const FormatException('Invalid companion transport.');
    PartyCompanionTrailPoint moved(PartyCompanionTrailPoint point) => PartyCompanionTrailPoint(point.x + x, point.z + z, y: groundY, groundY: groundY, traversalSpeed: point.traversalSpeed);
    final points = _points.map(moved).toList();
    _points..clear()..addAll(points);
    if (position != null) position = moved(position!);
    moving = false;
  }

  void regroup(double x, double z, {required double groundY}) {
    if (![x, z, groundY].every((value) => value.isFinite)) throw const FormatException('Invalid companion regroup.');
    final point = PartyCompanionTrailPoint(x, z, y: groundY, groundY: groundY);
    _points..clear()..add(point);
    position = point;
    _distance = 0;
    _followingDistance = 1;
    _recovering = false;
    moving = false;
  }

  void restore(PartyCompanionTrail snapshot) {
    if (identical(snapshot, this)) return;
    _points
      ..clear()
      ..addAll(snapshot._points);
    _mapId = snapshot._mapId;
    _individualId = snapshot._individualId;
    _distance = snapshot._distance;
    _followingDistance = snapshot._followingDistance;
    position = snapshot.position;
    moving = snapshot.moving;
    animationSeconds = snapshot.animationSeconds;
    facingX = snapshot.facingX;
    facingZ = snapshot.facingZ;
    _recovering = snapshot._recovering;
  }

  void clear() {
    _points.clear();
    _distance = 0;
    _followingDistance = 1;
    position = null;
    moving = false;
    animationSeconds = 0;
    _mapId = null;
    _individualId = null;
    _recovering = false;
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
    if (paused) {
      moving = false;
      return;
    }
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
    } else if (last.airborne != airborne ||
        last.y != y || last.groundY != groundY) {
      _points[_points.length - 1] = PartyCompanionTrailPoint(x, z,
          y: y,
          groundY: groundY,
          airborne: airborne,
          traversalSpeed: traversalSpeed);
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
    var remainingTravel = _recovering
        ? traversalSpeed * (dt.isFinite && dt > 0 ? dt.clamp(0.0, .05) : 0)
        : double.infinity;
    while (_distance > _followingDistance &&
        _points.length > 1 &&
        remainingTravel > 0) {
      final first = _points.first, next = _points[1];
      final segment = _length(first, next);
      if (_distance - segment >= _followingDistance - 1e-9 &&
          segment <= remainingTravel + 1e-9) {
        if (!traverse(first, next)) {
          blocked = true;
          break;
        }
        _points.removeAt(0);
        _distance = math.max(0, _distance - segment);
        remainingTravel = math.max(0, remainingTravel - segment);
      } else {
        final advance =
            math.min(_distance - _followingDistance, remainingTravel);
        final portion = advance / segment;
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
        _distance -= advance;
        remainingTravel -= advance;
      }
    }
    if (_distance >= _followingDistance) {
      final target = _points.first;
      if (traverse(target, target)) {
        position = target;
      } else {
        blocked = true;
      }
    }
    if (blocked) {
      _recovering = true;
    } else if (_distance <= _followingDistance + .000001) {
      _recovering = false;
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
