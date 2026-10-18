import 'dart:math' as math;

({double x, double y, int segment}) sampleCinematicRoute(
  List<({double x, double y})> points,
  double progress, {
  double coordinateWidth = 1,
  double coordinateHeight = 1,
}) {
  if (points.isEmpty) throw ArgumentError.value(points, 'points');
  final lengths = <double>[
    for (var i = 1; i < points.length; i++)
      math.sqrt(
        math.pow((points[i].x - points[i - 1].x) / coordinateWidth, 2) +
            math.pow((points[i].y - points[i - 1].y) / coordinateHeight, 2),
      ),
  ];
  var remaining =
      lengths.fold<double>(0, (a, b) => a + b) * progress.clamp(0.0, 1.0);
  for (var i = 0; i < lengths.length; i++) {
    final length = lengths[i];
    if (length == 0) continue;
    if (remaining <= length || i == lengths.length - 1) {
      final t = (remaining / length).clamp(0.0, 1.0);
      return (
        x: points[i].x + (points[i + 1].x - points[i].x) * t,
        y: points[i].y + (points[i + 1].y - points[i].y) * t,
        segment: i,
      );
    }
    remaining -= length;
  }
  return (x: points.last.x, y: points.last.y, segment: -1);
}

({double x, double y, double liftCells}) sampleCinematicJump({
  required ({double x, double y}) start,
  required ({double x, double y}) end,
  required double progress,
  required double heightCells,
}) {
  if (!start.x.isFinite ||
      !start.y.isFinite ||
      !end.x.isFinite ||
      !end.y.isFinite ||
      !progress.isFinite ||
      !heightCells.isFinite ||
      heightCells <= 0 ||
      heightCells > 4) {
    throw ArgumentError(
      'Jump coordinates, progress and height must be finite and height must be in (0, 4].',
    );
  }
  final t = progress.clamp(0.0, 1.0);
  if (t == 0) return (x: start.x, y: start.y, liftCells: 0);
  if (t == 1) return (x: end.x, y: end.y, liftCells: 0);
  return (
    x: start.x + (end.x - start.x) * t,
    y: start.y + (end.y - start.y) * t,
    liftCells: 4 * heightCells * t * (1 - t),
  );
}
