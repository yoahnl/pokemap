import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('stationary landing records the grounded state after subpixel movement', () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'field', individualId: 'lead', x: 3.5, z: 2.5);
    for (var i = 1; i <= 32; i++) {
      trail.observe(
        mapId: 'field', individualId: 'lead', x: 3.5, z: 2.5 + i / 16,
        airborne: true, y: i == 32 ? .000000001 : .5, dt: 1 / 60,
      );
    }
    for (var i = 0; i < 60; i++) {
      trail.observe(mapId: 'field', individualId: 'lead', x: 3.5, z: 4.5, dt: 1 / 60);
    }
    expect(trail.position!.airborne, isFalse);
    expect(trail.position!.y, 0);
  });
  for (final direction in SpatialRampDirection.values) {
    test('companion resumes after a real ${direction.name} ledge traversal',
        () {
      final ledge = SpatialLedge(
        id: 'drop',
        x: 4,
        z: 4,
        direction: direction,
        distance: 2,
        durationMs: 400,
        height: .65,
      );
      final movement = SpatialMovementController(
        scene: MapSpatialScene(
          width: 12,
          depth: 12,
          navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 4.5 - ledge.dx, z: 4.5 - ledge.dz),
            ledges: [ledge],
          ),
        ),
        models: [],
      );
      final trail = PartyCompanionTrail();
      void observe() => trail.observe(
            mapId: 'field',
            individualId: 'lead',
            x: movement.x,
            z: movement.z,
            y: movement.y,
            groundY: movement.groundY,
            airborne: movement.isJumping,
            traversalSpeed: movement.jumpSpeed,
            dt: .025,
            canTraverse: (ax, az, bx, bz) =>
                movement.canTraverseActor(ax, az, bx, bz),
          );
      observe();
      movement.setInput(x: ledge.dx, z: ledge.dz);
      var jumped = false;
      for (var i = 0; i < 60; i++) {
        movement.update(.025);
        observe();
        jumped |= movement.isJumping;
      }
      expect(jumped, isTrue);
      expect(trail.position, isNotNull);
      expect(trail.position!.airborne, isFalse);
      expect(trail.position!.x, closeTo(movement.x, .000001));
      expect(trail.position!.z, closeTo(movement.z, .000001));
      movement.setInput(x: ledge.dx, z: ledge.dz);
      for (var i = 0; i < 20; i++) {
        movement.update(.025);
        observe();
      }
      final distance = (movement.x - trail.position!.x).abs() +
          (movement.z - trail.position!.z).abs();
      expect(distance, closeTo(1, .000001));
    });
  }
  test('companion finishes its jump when the hero stops at the landing', () {
    final trail = PartyCompanionTrail();
    void observe(double z, {bool airborne = false, double y = 0}) =>
        trail.observe(
            mapId: 'map',
            individualId: 'lead',
            x: 3.5,
            z: z,
            y: y,
            airborne: airborne,
            dt: .025,
            canTraverse: (ax, az, bx, bz) => !(bz > 3 && bz < 4));
    observe(2.5);
    for (var i = 0; i < 16; i++) {
      observe(2.5 + i / 8, airborne: true, y: .5);
    }
    observe(4.5);
    for (var i = 0; i < 20; i++) {
      observe(4.5);
    }
    expect(trail.position, isNotNull);
    expect(trail.position!.z, 4.5);
    expect(trail.position!.y, 0);
    expect(trail.position!.airborne, isFalse);
  });

  test('companion follows a recorded airborne arc across a blocked ledge', () {
    final trail = PartyCompanionTrail();
    for (var i = 0; i <= 40; i++) {
      trail.observe(
          mapId: 'map',
          individualId: 'lead',
          x: 3.5,
          z: 2.5 + i / 16,
          y: i >= 8 && i <= 24 ? .5 : 0,
          airborne: i >= 8 && i <= 24,
          dt: .025,
          canTraverse: (ax, az, bx, bz) => !(bz > 3 && bz < 4));
      if (i == 24) {
        expect(trail.position, isNotNull);
        expect(trail.position!.y, greaterThan(0));
      }
    }
    expect(trail.position!.z, greaterThan(3));
  });
}
