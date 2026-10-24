import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
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
