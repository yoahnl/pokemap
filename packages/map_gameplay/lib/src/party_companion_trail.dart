import 'dart:math' as math;

final class PartyCompanionTrailPoint {
  const PartyCompanionTrailPoint(this.x, this.z);
  final double x;
  final double z;
}

final class PartyCompanionTrail {
  final _points = <PartyCompanionTrailPoint>[];
  String? _mapId, _individualId;
  double _distance = 0;
  PartyCompanionTrailPoint? position;
  bool moving = false;
  double animationSeconds = 0;
  double facingX = 0, facingZ = 1;

  void clear() {
    _points.clear();
    _distance = 0;
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
      bool paused = false,
      double dt = 0,
      bool Function(double fromX, double fromZ, double toX, double toZ)?
          canTraverse}) {
    if (paused) return;
    if (!x.isFinite || !z.isFinite || individualId.isEmpty) {
      clear();
      return;
    }
    if (_mapId != mapId || _individualId != individualId || _points.isEmpty) {
      clear();
      _mapId = mapId;
      _individualId = individualId;
      _points.add(PartyCompanionTrailPoint(x, z));
      return;
    }
    final previous = position;
    final last = _points.last;
    final distance = _length(last, PartyCompanionTrailPoint(x, z));
    if (distance > 2) {
      clear();
      observe(mapId: mapId, individualId: individualId, x: x, z: z);
      return;
    }
    if (distance > 0) {
      _points.add(PartyCompanionTrailPoint(x, z));
      _distance += distance;
    }
    bool traverse(PartyCompanionTrailPoint from, PartyCompanionTrailPoint to) =>
        canTraverse?.call(from.x, from.z, to.x, to.z) ?? true;
    var blocked = false;
    while (_distance > 1 && _points.length > 1) {
      final first = _points.first, next = _points[1];
      final segment = _length(first, next);
      if (_distance - segment >= 1) {
        if (!traverse(first, next)) {
          blocked = true;
          break;
        }
        _points.removeAt(0);
        _distance -= segment;
      } else {
        final portion = (_distance - 1) / segment;
        final target = PartyCompanionTrailPoint(
            first.x + (next.x - first.x) * portion,
            first.z + (next.z - first.z) * portion);
        if (!traverse(first, target)) {
          blocked = true;
          break;
        }
        _points[0] = target;
        _distance = 1;
      }
    }
    if (_distance >= 1 && !blocked) {
      final target = _points.first;
      blocked = !traverse(target, target);
      if (!blocked) position = target;
    }
    if (blocked) {
      clear();
      observe(mapId: mapId, individualId: individualId, x: x, z: z);
      return;
    }
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
