import 'package:meta/meta.dart';

import '../exceptions/map_exceptions.dart';

@immutable
final class BorderGroundPoint {
  BorderGroundPoint({required this.x, required this.z}) {
    if (!x.isFinite || !z.isFinite) {
      throw const ValidationException(
        'Ground footprint coordinates must be finite',
      );
    }
  }

  final double x, z;

  @override
  bool operator ==(Object other) =>
      other is BorderGroundPoint && x == other.x && z == other.z;

  @override
  int get hashCode => Object.hash(x, z);
}

@immutable
final class BorderGroundFootprint {
  BorderGroundFootprint({required List<BorderGroundPoint> points})
    : points = List.unmodifiable(points),
      _extent = _groundFootprintExtent(points) {
    if (points.length < 3 || points.length > 16) {
      throw const ValidationException(
        'Ground footprints require 3 to 16 convex vertices',
      );
    }
    var orientation = 0.0;
    for (var index = 0; index < points.length; index++) {
      final a = points[index], b = points[(index + 1) % points.length];
      if (a == b) {
        throw const ValidationException(
          'Ground footprint vertices must be distinct',
        );
      }
      for (var other = 0; other < points.length; other++) {
        if (other == index || other == (index + 1) % points.length) continue;
        final c = points[other];
        final cross =
            ((b.x - a.x) / _extent) * ((c.z - a.z) / _extent) -
            ((b.z - a.z) / _extent) * ((c.x - a.x) / _extent);
        if (cross.abs() <= 1e-10 ||
            (orientation != 0 && orientation * cross < 0)) {
          throw const ValidationException(
            'Ground footprints must be strictly convex and non-degenerate',
          );
        }
        orientation = cross.sign;
      }
    }
  }

  final List<BorderGroundPoint> points;
  final double _extent;

  bool contains(double x, double z) {
    var orientation = 0.0;
    for (var index = 0; index < points.length; index++) {
      final a = points[index], b = points[(index + 1) % points.length];
      final cross =
          ((b.x - a.x) / _extent) * ((z - a.z) / _extent) -
          ((b.z - a.z) / _extent) * ((x - a.x) / _extent);
      if (cross.abs() <= 1e-10) continue;
      if (orientation != 0 && orientation * cross < 0) return false;
      orientation = cross.sign;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is BorderGroundFootprint &&
      points.length == other.points.length &&
      Iterable<int>.generate(
        points.length,
      ).every((index) => points[index] == other.points[index]);

  @override
  int get hashCode => Object.hashAll(points);
}

double _groundFootprintExtent(List<BorderGroundPoint> points) {
  if (points.isEmpty) return 0;
  var left = points.first.x, right = left;
  var top = points.first.z, bottom = top;
  for (final point in points.skip(1)) {
    if (point.x < left) left = point.x;
    if (point.x > right) right = point.x;
    if (point.z < top) top = point.z;
    if (point.z > bottom) bottom = point.z;
  }
  final extent = right - left > bottom - top ? right - left : bottom - top;
  if (!extent.isFinite || extent <= 0) {
    throw const ValidationException(
      'Ground footprints must have a finite non-zero extent',
    );
  }
  return extent;
}

List<BorderGroundFootprint> validatedBorderGroundFootprints(
  List<BorderGroundFootprint> footprints,
  String? modelId,
) {
  if (footprints.length > 8 || (footprints.isNotEmpty && modelId == null)) {
    throw const ValidationException(
      'At most 8 ground footprints require a spatial model source',
    );
  }
  return List.unmodifiable(footprints);
}
