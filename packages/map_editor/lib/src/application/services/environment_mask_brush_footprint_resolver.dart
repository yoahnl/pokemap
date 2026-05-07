import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

const Set<int> kEnvironmentMaskBrushFootprintSizes = {1, 3, 5, 7};

final class EnvironmentMaskBrushFootprint {
  const EnvironmentMaskBrushFootprint({
    required this.mapSize,
    required this.center,
    required this.brushSize,
    required this.cells,
  });

  final GridSize mapSize;
  final GridPos center;
  final int brushSize;
  final List<GridPos> cells;

  bool get isEmpty => cells.isEmpty;
}

EnvironmentMaskBrushFootprint resolveEnvironmentMaskBrushFootprint({
  required GridSize mapSize,
  required GridPos center,
  required int brushSize,
}) {
  if (!kEnvironmentMaskBrushFootprintSizes.contains(brushSize)) {
    throw EditorValidationException(
      'Environment mask brush size must be one of 1, 3, 5 or 7: $brushSize',
    );
  }

  if (mapSize.width <= 0 ||
      mapSize.height <= 0 ||
      center.x < 0 ||
      center.y < 0 ||
      center.x >= mapSize.width ||
      center.y >= mapSize.height) {
    return EnvironmentMaskBrushFootprint(
      mapSize: mapSize,
      center: center,
      brushSize: brushSize,
      cells: const [],
    );
  }

  final radius = (brushSize - 1) ~/ 2;
  final minX = (center.x - radius).clamp(0, mapSize.width - 1);
  final maxX = (center.x + radius).clamp(0, mapSize.width - 1);
  final minY = (center.y - radius).clamp(0, mapSize.height - 1);
  final maxY = (center.y + radius).clamp(0, mapSize.height - 1);

  final cells = <GridPos>[];
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      cells.add(GridPos(x: x, y: y));
    }
  }

  return EnvironmentMaskBrushFootprint(
    mapSize: mapSize,
    center: center,
    brushSize: brushSize,
    cells: List<GridPos>.unmodifiable(cells),
  );
}
