import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('MapRect emits nested JSON objects without relying on jsonEncode', () {
    const rect = MapRect(pos: GridPos(x: 2, y: 3), size: GridSize(width: 4, height: 5));
    expect(rect.toJson(), {'pos': {'x': 2, 'y': 3}, 'size': {'width': 4, 'height': 5}});
    expect(MapRect.fromJson(rect.toJson()), rect);
  });
}
