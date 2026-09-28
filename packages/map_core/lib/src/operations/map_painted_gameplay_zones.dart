import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import 'map_gameplay_zones.dart';

MapData paintEncounterZoneCells(
  MapData map, {
  required String zoneId,
  required Iterable<GridPos> cells,
  required bool erase,
}) {
  final zone = findGameplayZoneById(map, zoneId);
  if (zone == null || zone.kind != GameplayZoneKind.encounter) {
    throw ValidationException('Encounter zone not found: $zoneId');
  }
  final covered = <GridPos>{
    if (zone.cellMask case final mask?)
      for (final cell in mask)
        GridPos(x: zone.area.pos.x + cell.x, y: zone.area.pos.y + cell.y)
    else
      for (
        var y = zone.area.pos.y;
        y < zone.area.pos.y + zone.area.size.height;
        y++
      )
        for (
          var x = zone.area.pos.x;
          x < zone.area.pos.x + zone.area.size.width;
          x++
        )
          GridPos(x: x, y: y),
  };
  for (final cell in cells) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= map.size.width ||
        cell.y >= map.size.height) {
      throw ValidationException('Encounter cell outside map: $cell');
    }
    if (erase) {
      covered.remove(cell);
    } else {
      covered.add(cell);
    }
  }
  if (covered.isEmpty) {
    throw const ValidationException(
      'Encounter zone cannot be empty; delete the zone explicitly.',
    );
  }
  final area = paintedEncounterBounds(covered);
  return updateGameplayZoneOnMap(
    map,
    zoneId: zoneId,
    area: area,
    cellMask: paintedEncounterMask(covered, area),
  );
}

MapRect paintedEncounterBounds(Iterable<GridPos> cells) {
  final positions = cells.toList(growable: false);
  if (positions.isEmpty) {
    throw const ValidationException('Encounter zone cannot be empty.');
  }
  var left = positions.first.x;
  var top = positions.first.y;
  var right = left;
  var bottom = top;
  for (final cell in positions.skip(1)) {
    if (cell.x < left) left = cell.x;
    if (cell.y < top) top = cell.y;
    if (cell.x > right) right = cell.x;
    if (cell.y > bottom) bottom = cell.y;
  }
  return MapRect(
    pos: GridPos(x: left, y: top),
    size: GridSize(width: right - left + 1, height: bottom - top + 1),
  );
}

List<GridPos> paintedEncounterMask(Iterable<GridPos> cells, MapRect area) {
  final sorted = cells
      .map((cell) => GridPos(x: cell.x - area.pos.x, y: cell.y - area.pos.y))
      .toSet()
      .toList();
  sorted.sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
  return sorted;
}
