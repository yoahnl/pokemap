import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const pickup = MapEntity(
  id: 'pickup',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 3, y: 3),
);

MapData map({SpatialSpawn? spawn}) => MapData(
      id: 'forest',
      name: 'Forest',
      size: const GridSize(width: 8, height: 8),
      entities: const [pickup],
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        navigation: SpatialNavigationProfile(
            spawn: spawn ?? SpatialSpawn(x: 1.5, z: 3.5)),
      ),
    );

void walk(SpatialMovementController movement, int count) {
  movement.setInput(x: 1, z: 0);
  for (var i = 0; i < count; i++) {
    movement.update(.05);
  }
}

void main() {
  test('a hidden logical entity stops blocking on the next movement update',
      () {
    var present = true;
    final movement = SpatialMovementController.fromMap(
      map: map(),
      models: const [],
      entityPresencePredicate: (entity) => present,
    );
    walk(movement, 30);
    expect(movement.x, lessThan(3));
    expect(movement.moving, isFalse);
    present = false;
    walk(movement, 10);
    expect(movement.x, greaterThan(3.5));
  });

  test('restored arrival on an absent entity uses the supplied presence rule',
      () {
    final source = map(spawn: SpatialSpawn(x: 3.5, z: 3.5));
    expect(
      () => SpatialMovementController.fromMap(map: source, models: const []),
      throwsStateError,
    );
    final movement = SpatialMovementController.fromMap(
      map: source,
      models: const [],
      spatialArrival: PlayerSpatialPosition(x: 3.5, z: 3.5),
      entityPresencePredicate: (entity) => false,
    );
    expect(movement.spatialPosition, PlayerSpatialPosition(x: 3.5, z: 3.5));
  });

  test('changing presence predicates preserves input and terrain collision',
      () {
    final source = map();
    final blocked = CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: [
        for (var z = 0; z < 8; z++)
          for (var x = 0; x < 8; x++) x == 5,
      ],
    );
    final movement = SpatialMovementController.fromMap(
      map: source.copyWith(layers: [blocked]),
      models: const [],
    );
    walk(movement, 30);
    final epoch = movement.inputEpoch;
    movement.setEntityPresencePredicate((entity) => false);
    for (var i = 0; i < 30; i++) {
      movement.update(.05);
    }
    expect(movement.x, greaterThan(3.5));
    expect(movement.x, lessThan(5));
    expect(movement.inputEpoch, epoch);
    expect(movement.moving, isFalse);
  });
}
