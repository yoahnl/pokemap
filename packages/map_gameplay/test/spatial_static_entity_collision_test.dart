import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final kind in [MapEntityKind.sign, MapEntityKind.custom, MapEntityKind.item]) {
    test('${kind.name} collision occupies its authored cell without half-cell shift', () {
      final entity = MapEntity(id: 'obstacle', kind: kind, pos: const GridPos(x: 3, y: 3), blocksMovement: true);
      final movement = SpatialMovementController(scene: MapSpatialScene(width: 8, depth: 8, navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 1.5))), models: [], entities: [entity]);
      expect(movement.canTraverseActor(2.5, 2.5, 4.5, 2.5), isTrue);
      expect(movement.canTraverseActor(2.5, 3.5, 4.5, 3.5), isFalse);
      expect(movement.canTraverseActor(2.5, 4.5, 4.5, 4.5), isTrue);
    });
  }
}
