import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('follows actual turns one cell behind without cutting corners', () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1.5);
    expect(trail.position!.x, 1.5);
    expect(trail.position!.z, 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 2);
    expect(trail.position!.x, 2);
    expect(trail.position!.z, 1);
  });

  test('map and lead changes reset transient trail and pause preserves it', () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1);
    expect(trail.position, isNotNull);
    trail.observe(mapId: 'room', individualId: 'one', x: 3, z: 1, paused: true);
    expect(trail.position!.x, 1);
    trail.observe(mapId: 'next', individualId: 'one', x: 4, z: 4);
    expect(trail.position, isNull);
    trail.observe(mapId: 'next', individualId: 'one', x: 5, z: 4);
    trail.observe(mapId: 'next', individualId: 'two', x: 5, z: 4);
    expect(trail.position, isNull);
  });

  test(
      'a dynamic blocker hides the follower and cannot tunnel or snap across it',
      () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1);
    trail.observe(
        mapId: 'room',
        individualId: 'one',
        x: 3,
        z: 1,
        canTraverse: (fromX, fromZ, toX, toZ) => false);
    expect(trail.position, isNull);
    trail.observe(mapId: 'room', individualId: 'one', x: 3.5, z: 1);
    expect(trail.position, isNull);
    trail.observe(mapId: 'room', individualId: 'one', x: 4, z: 1);
    expect(trail.position!.x, 3);
  });
}
