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
