import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('a transported follower retains its whole trail and resumes at the dock', () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1);
    trail.translate(4, 2, groundY: 3);
    expect(trail.position!.x, 5);
    expect(trail.position!.z, 3);
    expect(trail.position!.groundY, 3);
    trail.observe(mapId: 'room', individualId: 'one', x: 6.5, z: 3, y: 3, groundY: 3);
    expect(trail.position!.x, 5.5);
    expect(trail.individualId, 'one');
  });
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

  test('a dynamic blocker preserves the follower and resumes continuously', () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1);
    final before = trail.position!;
    trail.observe(
        mapId: 'room',
        individualId: 'one',
        x: 3,
        z: 1,
        canTraverse: (fromX, fromZ, toX, toZ) => false);
    expect(trail.position, same(before));
    expect(trail.moving, isFalse);
    var previousX = trail.position!.x;
    for (var i = 0; i < 10; i++) {
      trail.observe(mapId: 'room', individualId: 'one', x: 3, z: 1, dt: .05);
      expect(trail.position!.x - previousX, inInclusiveRange(0, .250001));
      previousX = trail.position!.x;
    }
    expect(trail.position!.x, 2);
  });
  test('blocked turns recover along retained segments without jumping corners',
      () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1);
    trail.observe(
        mapId: 'room',
        individualId: 'one',
        x: 3,
        z: 1,
        canTraverse: (_, __, ___, ____) => false);
    trail.observe(
        mapId: 'room',
        individualId: 'one',
        x: 3,
        z: 2,
        canTraverse: (_, __, ___, ____) => false);
    var previous = trail.position!;
    for (var i = 0; i < 12; i++) {
      trail.observe(mapId: 'room', individualId: 'one', x: 3, z: 2, dt: .05);
      final current = trail.position!;
      expect((current.x - previous.x).abs() + (current.z - previous.z).abs(),
          lessThanOrEqualTo(.250001));
      expect(current.z, 1);
      previous = current;
    }
    expect(trail.position!.x, 3);
  });

  test('capture and restore preserve identity pose and animation independently',
      () {
    final trail = PartyCompanionTrail();
    trail.observe(mapId: 'room', individualId: 'one', x: 1, z: 1);
    trail.observe(mapId: 'room', individualId: 'one', x: 2, z: 1, dt: .05);
    final snapshot = trail.capture();
    trail.observe(mapId: 'room', individualId: 'one', x: 3, z: 1, dt: .05);
    expect(snapshot.position!.x, 1);
    trail.restore(snapshot);
    expect(trail.position!.x, 1);
    expect(trail.mapId, 'room');
    expect(trail.individualId, 'one');
    expect(trail.animationSeconds, snapshot.animationSeconds);
    trail.observe(mapId: 'room', individualId: 'one', x: 2.1, z: 1, dt: .05);
    expect(trail.position!.x, closeTo(1.1, .000001));
  });
}
