import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

SpatialPlatformDefinition platform() => SpatialPlatformDefinition(
        id: 'ride',
        name: 'Ride',
        instanceId: 'deck',
        x: 1,
        z: 1,
        width: 2,
        depth: 2,
        height: 3,
        durationMs: 1000,
        routes: [
          SpatialPlatformRoute(id: 'default', waypoints: [
            SpatialPlatformStop(x: 0, z: 0),
            SpatialPlatformStop(x: 1, z: 1),
            SpatialPlatformStop(x: 3, z: 1),
            SpatialPlatformStop(x: 4, z: 0)
          ]),
          SpatialPlatformRoute(id: 'switch', conditions: [
            SpatialPlatformCondition(factId: 'switch', value: true)
          ], waypoints: [
            SpatialPlatformStop(x: 0, z: 0),
            SpatialPlatformStop(x: 0, z: 4)
          ]),
        ]);

void main() {
  test(
      'mobile support collision checks the whole deck at its height without treating its edge as a terrain step',
      () {
    final scene = MapSpatialScene(
        width: 10,
        depth: 10,
        heightLevels: [for (var i = 0; i < 100; i++) i % 10 < 4 ? 0 : 1],
        navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: .5, z: .5),
            blockedAreas: [
              SpatialBlockedArea(x: 7, z: 2, width: 1, depth: 1)
            ]));
    final movement = SpatialMovementController(scene: scene, models: []);
    final deck = platform();
    movement.terrainHeightOverride = (x, z) => deck.contains(x, z) ? 3 : null;
    expect(movement.canOccupyPlatform(deck, 0, 0), isTrue);
    expect(movement.canOccupyPlatform(deck, 2, 1), isTrue);
    expect(movement.canOccupyPlatform(deck, 5, 1), isFalse);
    expect(movement.canOccupyPlatform(deck, 9, 0), isFalse);
  });
  test(
      'route facts select a stable stop and movement is independent of cadence',
      () {
    final definition = platform();
    expect(definition.selectRoute((_) => true).id, 'switch');
    for (final cadence in [30, 60, 120]) {
      final motion = SpatialPlatformMotion(
          definition: definition,
          route: definition.selectRoute((_) => false),
          sourceOffset: SpatialPlatformStop(x: 0, z: 0),
          motion: MovingPlatformMotion.forward);
      motion.advance(.2, paused: true, canOccupy: (x, z) => true);
      expect(motion.offset.x, 0);
      for (var i = 0; i < cadence + 1; i++)
        motion.advance(1 / cadence, canOccupy: (x, z) => true);
      expect(motion.complete, isTrue);
      expect(motion.outcome, 'moved');
      expect(motion.offset.x, 4);
      final backward = SpatialPlatformMotion(
          definition: definition,
          route: definition.routes.first,
          sourceOffset: motion.offset,
          motion: MovingPlatformMotion.backward);
      backward.advance(1, canOccupy: (x, z) => true);
      expect(backward.offset.x, 0);
    }
  });

  test(
      'swept collision rolls back to exact source and cancellation never keeps partial pose',
      () {
    final definition = platform();
    final motion = SpatialPlatformMotion(
        definition: definition,
        route: definition.routes.first,
        sourceOffset: SpatialPlatformStop(x: 0, z: 0),
        motion: MovingPlatformMotion.forward);
    motion.advance(.9, canOccupy: (x, _) => x < 2);
    expect(motion.returning, isTrue);
    expect(motion.offset.x, lessThan(2));
    motion.advance(1, canOccupy: (x, z) => true);
    expect(motion.complete, isTrue);
    expect(motion.offset.x, 0);
    expect(motion.outcome, 'blocked');
    final cancelled = SpatialPlatformMotion(
        definition: definition,
        route: definition.routes.first,
        sourceOffset: SpatialPlatformStop(x: 0, z: 0),
        motion: MovingPlatformMotion.forward);
    cancelled.advance(.3, canOccupy: (x, z) => true);
    cancelled.cancel();
    expect(cancelled.offset.x, 0);
    expect(cancelled.outcome, 'blocked');
    expect(
        () => SpatialPlatformMotion(
            definition: definition,
            route: definition.routes.first,
            sourceOffset: SpatialPlatformStop(x: 1, z: 0),
            motion: MovingPlatformMotion.forward),
        throwsFormatException);
  });
}
