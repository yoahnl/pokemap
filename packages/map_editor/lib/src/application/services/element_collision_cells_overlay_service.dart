import 'package:map_core/map_core.dart';

/// Applies explicit authoring overrides on top of an automatic base shape.
///
/// Final collision truth:
/// `final = (base + manualAdded) - manualRemoved`
class ElementCollisionCellsOverlayService {
  const ElementCollisionCellsOverlayService();

  List<GridPos> apply({
    required List<GridPos> baseCells,
    List<GridPos> manualAddedCells = const <GridPos>[],
    List<GridPos> manualRemovedCells = const <GridPos>[],
  }) {
    final merged = <String, GridPos>{
      for (final cell in _normalize(baseCells)) _key(cell): cell,
    };

    for (final cell in _normalize(manualAddedCells)) {
      merged[_key(cell)] = cell;
    }

    for (final cell in _normalize(manualRemovedCells)) {
      merged.remove(_key(cell));
    }

    final out = merged.values.toList(growable: false);
    out.sort(_compareCells);
    return out;
  }

  List<GridPos> normalize(List<GridPos> cells) => _normalize(cells);

  int compareCells(GridPos a, GridPos b) => _compareCells(a, b);

  List<GridPos> _normalize(List<GridPos> cells) {
    final unique = <String, GridPos>{};
    for (final cell in cells) {
      unique[_key(cell)] = GridPos(x: cell.x, y: cell.y);
    }
    final out = unique.values.toList(growable: false);
    out.sort(_compareCells);
    return out;
  }

  String _key(GridPos cell) => '${cell.x}:${cell.y}';

  int _compareCells(GridPos a, GridPos b) {
    final yCompare = a.y.compareTo(b.y);
    if (yCompare != 0) {
      return yCompare;
    }
    return a.x.compareTo(b.x);
  }
}
