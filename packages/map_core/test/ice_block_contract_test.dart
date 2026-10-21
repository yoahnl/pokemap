import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('a contact-pushed ice block has no field ability requirement', () {
    final data = {'kind': 'iceBlock', 'resetPolicy': 'mapInstance'};
    final obstacle = MapEntityFieldObstacleData.fromJson(data);

    expect(obstacle.ability, isNull);
    expect(obstacle.toJson(), data);
    final entity = MapEntity.fromJson({
      ...const MapEntity(
        id: 'ice',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 3, y: 2),
      ).toJson(),
      'fieldObstacle': data,
    });
    expect(entity.fieldObstacle, obstacle);
    expect(entity.toJson()['fieldObstacle'], data);
  });
}
