import 'package:map_core/map_core_domain.dart';

final class MapEncounterCellStroke {
  MapEncounterCellStroke(this.size, this.erase, GridPos origin) {
    paint(origin);
  }

  final GridSize size;
  final bool erase;
  final Set<GridPos> _cells = {};
  GridPos? _last;

  List<GridPos> get cells => _cells.toList(growable: false);

  void paint(GridPos position) {
    final previous = _last;
    _last = position;
    if (previous == null) {
      _add(position);
      return;
    }
    var x = previous.x;
    var y = previous.y;
    final dx = (position.x - x).abs();
    final dy = (position.y - y).abs();
    final stepX = x < position.x ? 1 : -1;
    final stepY = y < position.y ? 1 : -1;
    var error = dx - dy;
    while (true) {
      _add(GridPos(x: x, y: y));
      if (x == position.x && y == position.y) break;
      final twice = 2 * error;
      if (twice > -dy) {
        error -= dy;
        x += stepX;
      }
      if (twice < dx) {
        error += dx;
        y += stepY;
      }
    }
  }

  void _add(GridPos cell) {
    if (cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < size.width &&
        cell.y < size.height) {
      _cells.add(cell);
    }
  }
}
