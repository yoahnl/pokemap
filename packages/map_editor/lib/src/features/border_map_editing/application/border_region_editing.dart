import 'package:map_core/map_core.dart';

/// Returns one immutable organic-region draft with [pos] painted or erased.
BorderRegionGeometry editBorderRegionCell(
  BorderRegionGeometry source,
  GridPos pos, {
  required bool filled,
}) {
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= source.width ||
      pos.y >= source.height) {
    throw RangeError('Border region cell is outside the map: $pos');
  }
  final index = pos.y * source.width + pos.x;
  if (source.cells[index] == filled) return source;
  final cells = List<bool>.from(source.cells);
  cells[index] = filled;
  return BorderRegionGeometry(
    width: source.width,
    height: source.height,
    cells: cells,
  );
}
