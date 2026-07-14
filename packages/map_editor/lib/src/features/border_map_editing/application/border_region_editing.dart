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

/// Paints or erases every cardinally-connected cell crossed by one drag jump.
///
/// Pointer events can skip several grid cells. Walking both axes one cell at a
/// time keeps the transient region connected instead of leaving diagonal or
/// high-speed holes.
BorderRegionGeometry editBorderRegionSegment(
  BorderRegionGeometry source,
  GridPos from,
  GridPos to, {
  required bool filled,
}) {
  _requireInside(source, from);
  _requireInside(source, to);

  final cells = List<bool>.from(source.cells);
  var changed = false;
  var x = from.x;
  var y = from.y;

  void writeCurrent() {
    final index = y * source.width + x;
    if (cells[index] == filled) return;
    cells[index] = filled;
    changed = true;
  }

  writeCurrent();
  while (x != to.x || y != to.y) {
    if (x != to.x) {
      x += x < to.x ? 1 : -1;
      writeCurrent();
    }
    if (y != to.y) {
      y += y < to.y ? 1 : -1;
      writeCurrent();
    }
  }

  if (!changed) return source;
  return BorderRegionGeometry(
    width: source.width,
    height: source.height,
    cells: cells,
  );
}

void _requireInside(BorderRegionGeometry source, GridPos pos) {
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= source.width ||
      pos.y >= source.height) {
    throw RangeError('Border region cell is outside the map: $pos');
  }
}
