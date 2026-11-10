import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

class AtlasSelectionController {
  AtlasSelectionController({required this.source, this.singleCell = false});

  ProjectRegularAtlasTilesetSource source;
  bool singleCell;
  GridPos? _origin, _lastCell;

  void update({
    required ProjectRegularAtlasTilesetSource source,
    required bool singleCell,
  }) {
    if (this.source != source || this.singleCell != singleCell) end();
    this.source = source;
    this.singleCell = singleCell;
  }

  GridPos? cell(double x, double y) {
    final atlas = source;
    if (atlas.tileWidth <= 0 ||
        atlas.tileHeight <= 0 ||
        atlas.spacingX < 0 ||
        atlas.spacingY < 0) {
      return null;
    }
    x -= atlas.marginX;
    y -= atlas.marginY;
    if (x < 0 || y < 0) return null;
    final column = (x / (atlas.tileWidth + atlas.spacingX)).floor();
    final row = (y / (atlas.tileHeight + atlas.spacingY)).floor();
    if (column >= atlas.columns ||
        row >= atlas.rows ||
        x % (atlas.tileWidth + atlas.spacingX) >= atlas.tileWidth ||
        y % (atlas.tileHeight + atlas.spacingY) >= atlas.tileHeight) {
      return null;
    }
    return GridPos(x: column, y: row);
  }

  TilesetSourceRect? select(double x, double y, {bool begin = false}) {
    final current = cell(x, y);
    if (begin) {
      _origin = current;
      _lastCell = null;
    }
    final origin = _origin;
    if (current == null ||
        origin == null ||
        (singleCell && current == _lastCell)) {
      return null;
    }
    _lastCell = current;
    return TilesetSourceRect(
      x: singleCell ? current.x : math.min(origin.x, current.x),
      y: singleCell ? current.y : math.min(origin.y, current.y),
      width: singleCell ? 1 : (origin.x - current.x).abs() + 1,
      height: singleCell ? 1 : (origin.y - current.y).abs() + 1,
    );
  }

  void end() {
    _origin = null;
    _lastCell = null;
  }
}
