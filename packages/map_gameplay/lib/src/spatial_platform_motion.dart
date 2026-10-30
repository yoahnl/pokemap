import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class SpatialPlatformMotion {
  SpatialPlatformMotion(
      {required this.definition,
      required this.route,
      required this.sourceOffset,
      required MovingPlatformMotion motion}) {
    if (motion == MovingPlatformMotion.rotateClockwise ||
        !definition.routes.contains(route)) {
      throw const FormatException('Spatial route platforms do not rotate.');
    }
    waypoints = motion == MovingPlatformMotion.forward
        ? route.waypoints
        : route.waypoints.reversed.toList();
    final start = waypoints.first;
    if ((start.x - sourceOffset.x).abs() > 1e-6 ||
        (start.z - sourceOffset.z).abs() > 1e-6) {
      throw const FormatException(
          'A platform must start at the route departure dock.');
    }
    targetOffset = waypoints.last;
    var distance = 0.0;
    for (var i = 1; i < waypoints.length; i++) {
      distance += _distance(waypoints[i - 1], waypoints[i]);
    }
    length = distance;
  }
  final SpatialPlatformDefinition definition;
  final SpatialPlatformRoute route;
  final SpatialPlatformStop sourceOffset;
  late final SpatialPlatformStop targetOffset;
  late final List<SpatialPlatformStop> waypoints;
  late final double length;
  double _progress = 0;
  bool _blocked = false, _finished = false;
  bool returning = false;
  bool get complete => _finished;
  String get outcome => _blocked ? 'blocked' : 'moved';
  SpatialPlatformStop get offset {
    if (_progress == 0) {
      return sourceOffset;
    }
    if (_progress == 1) {
      return targetOffset;
    }
    var remaining = length * _progress;
    for (var i = 1; i < waypoints.length; i++) {
      final a = waypoints[i - 1], b = waypoints[i];
      final segment = _distance(a, b);
      if (remaining <= segment) {
        return SpatialPlatformStop(
            x: a.x + (b.x - a.x) * remaining / segment,
            z: a.z + (b.z - a.z) * remaining / segment);
      }
      remaining -= segment;
    }
    return targetOffset;
  }

  void advance(double seconds,
      {bool paused = false,
      required bool Function(double x, double z) canOccupy}) {
    if (!seconds.isFinite || seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds');
    }
    if (paused || _finished) {
      return;
    }
    final amount = seconds * 1000 / definition.durationMs;
    if (returning) {
      _progress = math.max(0, _progress - amount);
      _finished = _progress <= 1e-9;
      if (_finished) _progress = 0;
      return;
    }
    final source = _progress;
    final target = math.min(1.0, source + amount);
    final steps = math.max(1, ((target - source) * length * 16).ceil());
    for (var step = 1; step <= steps; step++) {
      final previous = _progress;
      _progress = source + (target - source) * step / steps;
      final point = offset;
      if (!canOccupy(point.x, point.z)) {
        _progress = previous;
        returning = _blocked = true;
        if (_progress == 0) _finished = true;
        return;
      }
    }
    if (_progress >= 1 - 1e-9) {
      _progress = 1;
      _finished = true;
    }
  }

  void cancel() {
    _progress = 0;
    _blocked = _finished = true;
  }

  static double _distance(SpatialPlatformStop a, SpatialPlatformStop b) =>
      math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.z - a.z, 2));
}
