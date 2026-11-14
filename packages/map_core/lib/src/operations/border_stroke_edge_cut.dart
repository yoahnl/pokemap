import '../models/border_geometry.dart';
import '../models/geometry.dart';
import 'border_linear_lattice.dart';

BorderStrokeGeometry cutBorderStrokeEdges(
  BorderStrokeGeometry geometry,
  bool Function(GridPos a, GridPos b) cut,
) {
  final used = {
    for (final stroke in geometry.strokes) borderStrokeAuthoredIdV1(stroke.id),
  };
  final output = <BorderStroke>[];
  var changed = false;
  for (final stroke in geometry.strokes) {
    final points = stroke.points;
    final edges = stroke.closed ? points.length : points.length - 1;
    final cuts = [
      for (var i = 0; i < edges; i++)
        if (cut(points[i], points[(i + 1) % points.length])) i,
    ];
    if (cuts.isEmpty) {
      output.add(stroke);
      continue;
    }
    changed = true;
    final runs = <({int start, List<GridPos> points})>[];
    final first = stroke.closed ? cuts.first + 1 : 0;
    var current = <GridPos>[points[first % points.length]];
    var start = first % points.length;
    for (var step = 0; step < (stroke.closed ? edges : edges - first); step++) {
      final index = (first + step) % points.length;
      final next = (index + 1) % points.length;
      if (cuts.contains(index)) {
        runs.add((start: start, points: current));
        current = [points[next]];
        start = next;
      } else {
        current.add(points[next]);
      }
    }
    runs.add((start: start, points: current));
    final authored = borderStrokeAuthoredIdV1(stroke.id);
    var kept = 0;
    for (final run in runs) {
      if (run.points.length < 2) continue;
      kept++;
      var id = authored;
      if (kept > 1) {
        var suffix = kept;
        while (used.contains('${authored}__fragment_$suffix')) {
          suffix++;
        }
        id = '${authored}__fragment_$suffix';
        used.add(id);
      }
      output.add(
        buildBorderTraversalPreservedFragmentV1(
          sourceStroke: stroke,
          authoredStrokeId: id,
          sourceStartIndex: run.start,
          orderedPoints: run.points,
        ),
      );
    }
  }
  if (!changed) return geometry;
  return BorderStrokeGeometry(strokes: output, alignment: geometry.alignment);
}
