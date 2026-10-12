import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/materialized_border_collision_fixture.dart';

void main() {
  test(
      'materialized Border blocks only its fine source mask without duplicates',
      () {
    final fixture = MaterializedBorderCollisionFixture(profile: _fineProfile());
    final world = _world(fixture);
    final placement = fixture.feature.materialization!.placements.single;
    expect(fixture.map.placedElements, isEmpty);
    expect(
        _blocked(world, placement.topLeftWorldPx.x + 3,
            placement.topLeftWorldPx.y + 47),
        isTrue);
    expect(
        _blocked(world, placement.topLeftWorldPx.x + 2,
            placement.topLeftWorldPx.y + 47),
        isFalse);
    expect(
        _blocked(world, placement.topLeftWorldPx.x + 3,
            placement.topLeftWorldPx.y + 46),
        isFalse);
    expect(world.map, same(fixture.map));
  });

  for (var q = 0; q < 4; q++) {
    for (final flip in [false, true]) {
      test(
          'Border native mask follows source flip then rotation $q, flip $flip and offset',
          () {
        final fixture = MaterializedBorderCollisionFixture(
          profile: _fineProfile(),
          transform: BorderSpriteTransform(quarterTurns: q, flipX: flip),
          offset: const BorderPixelOffset(x: 5, y: 7),
        );
        final world = _world(fixture);
        final p = fixture.feature.materialization!.placements.single;
        expect(p.transform.quarterTurns, q);
        expect(p.transform.flipX, flip);
        final expected = <(int, int)>{};
        for (var y = 47; y < 51; y++) {
          for (var x = 3; x < 6; x++) {
            final fx = flip ? 31 - x : x;
            final (rx, ry) = switch (q) {
              0 => (fx, y),
              1 => (63 - y, fx),
              2 => (31 - fx, 63 - y),
              _ => (y, 31 - fx),
            };
            expected.add((p.topLeftWorldPx.x + rx, p.topLeftWorldPx.y + ry));
          }
        }
        for (var y = 20; y < 230; y++) {
          for (var x = 20; x < 200; x++) {
            expect(_blocked(world, x, y), expected.contains((x, y)),
                reason: '$q/$flip at $x,$y');
          }
        }
      });
    }
  }

  test(
      'Border cell profiles and delete/suppress/reload keep physics tied to art',
      () {
    final fixture = MaterializedBorderCollisionFixture(
        profile: const ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]));
    final p = fixture.feature.materialization!.placements.single;
    final world = _world(fixture);
    expect(
        _blocked(world, p.topLeftWorldPx.x, p.topLeftWorldPx.y + 32), isTrue);
    expect(
        _blocked(world, p.topLeftWorldPx.x, p.topLeftWorldPx.y + 31), isFalse);
    final restoredMap = MapData.fromJson(
        jsonDecode(jsonEncode(fixture.map.toJson())) as Map<String, dynamic>);
    final restoredProject = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(fixture.project.toJson()))
            as Map<String, dynamic>);
    expect(
        _blocked(_world(fixture, map: restoredMap, project: restoredProject),
            p.topLeftWorldPx.x, p.topLeftWorldPx.y + 32),
        isTrue);
    final removed = fixture.map.copyWith(layers: const []);
    expect(
        _blocked(_world(fixture, map: removed), p.topLeftWorldPx.x,
            p.topLeftWorldPx.y + 32),
        isFalse);
    final suppressed = MaterializedBorderCollisionFixture(
        profile: _fineProfile(), suppressed: true, segments: 2);
    expect(suppressed.feature.materialization!.placements, hasLength(1));
    expect(
        _blocked(_world(suppressed), p.topLeftWorldPx.x + 3,
            p.topLeftWorldPx.y + 47),
        isFalse);
  });

  test('a visual-only Border stays passable', () {
    final fixture = MaterializedBorderCollisionFixture();
    final p = fixture.feature.materialization!.placements.single;
    expect(
        _blocked(
            _world(fixture), p.topLeftWorldPx.x + 3, p.topLeftWorldPx.y + 47),
        isFalse);
  });

  test('real movement cannot cross the Border and removal restores passage',
      () {
    final fixture = MaterializedBorderCollisionFixture(
      profile: const ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]),
    );
    GameplayWorldState start(MapData map) => GameplayWorldState.initial(
          map: map,
          project: fixture.project,
          playerPos: const GridPos(x: 1, y: 4),
          tileWidth: 32,
          tileHeight: 32,
        );
    final blocked = stepGameplayWorld(start(fixture.map),
        const MoveIntent(Direction.east, pixelsPerStep: 32));
    expect(blocked, isA<Blocked>());
    expect((blocked as Blocked).reason, GameplayMovementBlockReason.solid);
    final released = stepGameplayWorld(
        start(fixture.map.copyWith(layers: const [])),
        const MoveIntent(Direction.east, pixelsPerStep: 32));
    expect(released, isA<Moved>());
  });

  test(
      'mismatched source frame and malformed masks cannot mount partial physics',
      () {
    final fixture = MaterializedBorderCollisionFixture(profile: _fineProfile());
    final element = fixture.project.elements.single;
    final wrongSize = element.copyWith(frames: const [
      TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1)),
    ]);
    expect(
        () => _world(fixture,
            project: fixture.project.copyWith(elements: [wrongSize])),
        throwsA(isA<ValidationException>()));
    final malformed = element.copyWith(
        collisionProfile: const ElementCollisionProfile(
      collisionMask: ElementCollisionPixelMask(
          widthPx: 32, heightPx: 64, dataBase64: 'AA=='),
    ));
    expect(
        () => _world(fixture,
            project: fixture.project.copyWith(elements: [malformed])),
        throwsA(isA<FormatException>()));
  });

  test(
      'missing source, stale feature and altered output fail before collision mount',
      () {
    final fixture = MaterializedBorderCollisionFixture(profile: _fineProfile());
    expect(
        () => _world(fixture,
            project: fixture.project.copyWith(elements: const [])),
        throwsA(isA<ValidationException>()));
    final encoded = encodeBorderFeatureJson(fixture.feature, formatVersion: 3);
    final changedSeed = Map<String, Object?>.from(encoded)..['seed'] = '1';
    final stale = decodeBorderFeatureJson(changedSeed, formatVersion: 3);
    expect(() => _world(fixture, map: fixture.withFeature(stale)),
        throwsA(isA<ValidationException>()));
    final altered = jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>;
    final materialization = altered['materialization'] as Map<String, dynamic>;
    final moved =
        (materialization['placements'] as List).first as Map<String, dynamic>;
    (moved['topLeftWorldPx'] as Map<String, dynamic>)['x'] += 1;
    (moved['opaqueWorldBoundsPx'] as Map<String, dynamic>)['x'] += 1;
    final tampered = decodeBorderFeatureJson(altered, formatVersion: 3);
    expect(() => _world(fixture, map: fixture.withFeature(tampered)),
        throwsA(isA<ValidationException>()));
  });
}

ElementCollisionProfile _fineProfile() => ElementCollisionProfile(
      collisionMask: ElementCollisionPixelMask(
        widthPx: 32,
        heightPx: 64,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 32,
          heightPx: 64,
          solidPixels: List<bool>.generate(
              32 * 64,
              (i) =>
                  i % 32 >= 3 && i % 32 < 6 && i ~/ 32 >= 47 && i ~/ 32 < 51),
        ),
      ),
    );

GameplayWorldState _world(MaterializedBorderCollisionFixture fixture,
        {MapData? map, ProjectManifest? project}) =>
    GameplayWorldState.initial(
      map: map ?? fixture.map,
      project: project ?? fixture.project,
      playerPos: const GridPos(x: 0, y: 0),
      tileWidth: 32,
      tileHeight: 32,
    );

bool _blocked(GameplayWorldState world, int x, int y) =>
    world.worldStaticObstaclesCollidePixelRect(
        PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1));
