import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_field_obstacle_burst.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bounded local debris pauses, expires, clears on map change and releases its textures', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final burst = SpatialFieldObstacleBurst(budget);
    await burst.prepare();
    await burst.prepare();
    expect(budget.residentBytes, 512);
    for (final ability in [FieldAbility.cut, FieldAbility.rockSmash]) {
      burst.start(ability, mapId: 'field', x: 2, y: 1, z: 3);
      final initial = burst.frames(0, mapId: 'field');
      expect(initial, hasLength(8));
      final paused = burst.frames(.6, mapId: 'field', paused: true);
      expect(paused.values.first.x, initial.values.first.x);
      expect(
        burst.frames(.3, mapId: 'field').values.any((frame) => frame.x != 2),
        isTrue,
      );
      expect(burst.frames(.3, mapId: 'field'), isEmpty);
      burst.start(ability, mapId: 'field', x: 2, y: 1, z: 3);
      expect(burst.frames(0, mapId: 'room'), isEmpty);
      expect(burst.frames(0, mapId: 'field'), isEmpty);
    }
    burst.dispose();
    expect(budget.residentBytes, 0);
    expect(burst.frames(0, mapId: 'field'), isEmpty);
  });
}
