import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

final class MapReliefStroke {
  MapReliefStroke({
    required this.source,
    required this.origin,
    required this.level,
    required this.rectangle,
  }) {
    paint(origin);
  }

  final MapData source;
  final GridPos origin;
  final int level;
  final bool rectangle;
  final cells = <GridPos>{};
  GridPos? _previous;

  double get targetHeight => level * source.spatialScene!.levelHeight;

  void paint(GridPos cell) {
    final scene = source.spatialScene!;
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= scene.width ||
        cell.y >= scene.depth) {
      _previous = null;
      return;
    }
    if (rectangle) {
      cells
        ..clear()
        ..addAll([
          for (
            var y = math.min(origin.y, cell.y);
            y <= math.max(origin.y, cell.y);
            y++
          )
            for (
              var x = math.min(origin.x, cell.x);
              x <= math.max(origin.x, cell.x);
              x++
            )
              GridPos(x: x, y: y),
        ]);
      return;
    }
    final previous = _previous ?? cell;
    final steps = math.max(
      (cell.x - previous.x).abs(),
      (cell.y - previous.y).abs(),
    );
    for (var step = 0; step <= steps; step++) {
      final t = steps == 0 ? 0.0 : step / steps;
      cells.add(
        GridPos(
          x: (previous.x + (cell.x - previous.x) * t).round(),
          y: (previous.y + (cell.y - previous.y) * t).round(),
        ),
      );
    }
    _previous = cell;
  }

  Set<GridPos> get contour => {
    for (final cell in cells)
      if (const [(1, 0), (-1, 0), (0, 1), (0, -1)].any(
        (d) => !cells.contains(GridPos(x: cell.x + d.$1, y: cell.y + d.$2)),
      ))
        cell,
  };
}
