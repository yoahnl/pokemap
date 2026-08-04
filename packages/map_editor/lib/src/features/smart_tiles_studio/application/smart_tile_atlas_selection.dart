import 'package:map_core/map_core.dart';

enum SmartTileAtlasSelectionMode {
  singleCell,
  rectangle,
}

/// Builds one canonical atlas crop from two inclusive grid cells.
///
/// Endpoint order does not matter. Both cells must belong to the configured
/// atlas grid so an authoring gesture can never persist an out-of-image crop.
SmartTileFrameRef selectSmartTileAtlasFrame({
  required String atlasId,
  required GridPos start,
  required GridPos end,
  required int columns,
  required int rows,
}) {
  if (columns <= 0 || rows <= 0) {
    throw ArgumentError('Atlas grid dimensions must be positive.');
  }
  for (final entry in <({String name, GridPos cell})>[
    (name: 'start', cell: start),
    (name: 'end', cell: end),
  ]) {
    if (entry.cell.x < 0 ||
        entry.cell.y < 0 ||
        entry.cell.x >= columns ||
        entry.cell.y >= rows) {
      throw RangeError(
        '${entry.name} atlas cell is outside the configured grid.',
      );
    }
  }
  final left = start.x < end.x ? start.x : end.x;
  final right = start.x > end.x ? start.x : end.x;
  final top = start.y < end.y ? start.y : end.y;
  final bottom = start.y > end.y ? start.y : end.y;
  return SmartTileFrameRef(
    atlasId: atlasId,
    column: left,
    row: top,
    columnSpan: right - left + 1,
    rowSpan: bottom - top + 1,
  );
}
