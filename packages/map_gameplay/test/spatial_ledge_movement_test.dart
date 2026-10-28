import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapSpatialScene ledgeScene({bool blocked = false, bool reverse = false}) =>
    MapSpatialScene(
      width: 8,
      depth: 8,
      navigation: SpatialNavigationProfile.fromJson({
        'spawn': {'x': 3.5, 'z': reverse ? 4.5 : 2.5},
        'allowDiagonalMovement': false,
        'ramps': [],
        'blockedAreas': [
          if (blocked) {'x': 3.0, 'z': 4.0, 'width': 1.0, 'depth': 1.0},
        ],
        'ledges': [
          {
            'id': 'drop',
            'x': 3,
            'z': 2,
            'direction': 'south',
            'distance': 2,
            'durationMs': 400,
            'height': .65
          },
        ],
      }),
    );

void main() {
  test('jump advances the character animation clock and pause freezes it', () {
    final player = SpatialMovementController(scene: ledgeScene(), models: []);
    player.setInput(x: 0, z: 1);
    player.update(.025);
    final started = player.animationSeconds;
    player.update(.05);
    expect(player.animationSeconds, closeTo(started + .05, .000001));
    player.setPaused(true);
    final paused = player.animationSeconds;
    player.update(.05);
    expect(player.animationSeconds, paused);
  });
  test(
      'jump reserves the landing against autonomous actors and freezes when paused',
      () {
    final player = SpatialMovementController(scene: ledgeScene(), models: []);
    player.setInput(x: 0, z: 1);
    player.update(.05);
    expect(player.isJumping, isTrue);
    expect(player.isPositionTraversable, isFalse);
    expect(player.canTraverseActor(4.5, 4.5, 3.5, 4.5, collideWithPlayer: true),
        isFalse);
    final position = player.spatialPosition;
    player.setPaused(true);
    player.update(.05);
    expect(player.spatialPosition, position);
    player.setPaused(false);
    for (var i = 0; i < 8; i++) {
      player.update(.05);
    }
    expect(player.z, 4.5);
    expect(player.isJumping, isFalse);
    expect(player.reservedLanding, isNull);
  });
  for (final direction in SpatialRampDirection.values) {
    test(
        'native jump traverses a ${direction.name} ledge and preserves the landing',
        () {
      final ledge = SpatialLedge(id: 'drop', x: 3, z: 3, direction: direction);
      final scene = MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(
              spawn: SpatialSpawn(x: 3.5, z: 3.5), ledges: [ledge]));
      final player = SpatialMovementController(scene: scene, models: []);
      player.setInput(x: ledge.dx, z: ledge.dz);
      for (var i = 0; i < 9; i++) {
        player.update(.05);
      }
      expect(player.x, ledge.landingX + .5);
      expect(player.z, ledge.landingZ + .5);
      expect(player.y, 0);
    });
  }

  test('walking into a directional ledge jumps to its landing with an arc', () {
    final player = SpatialMovementController(scene: ledgeScene(), models: []);
    player.setInput(x: 0, z: 1);
    for (var i = 0; i < 5; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(3));
    expect(player.y, greaterThan(.4));
    player.setInput(x: 1, z: 0);
    for (var i = 0; i < 5; i++) {
      player.update(.05);
    }
    expect(player.z, 4.5);
    expect(player.x, 3.5);
    expect(player.y, 0);
  });

  test('a blocked landing never starts a jump or walks onto the ledge', () {
    final player =
        SpatialMovementController(scene: ledgeScene(blocked: true), models: []);
    player.setInput(x: 0, z: 1);
    for (var i = 0; i < 25; i++) {
      player.update(.05);
    }
    expect(player.z, lessThan(3));
    expect(player.y, 0);
  });

  test('reverse movement cannot cross a ledge even on flat terrain', () {
    final player =
        SpatialMovementController(scene: ledgeScene(reverse: true), models: []);
    player.setInput(x: 0, z: -1);
    for (var i = 0; i < 30; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(3.9));
  });
}
