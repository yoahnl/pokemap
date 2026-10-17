import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/moving_platform_fixture.dart';

SmartTileLayer terrain({SmartTileUsage usage = SmartTileUsage.terrain}) =>
    MapLayer.smartTile(
      id: 'magma',
      name: 'Magma',
      presetId: 'lava',
      usage: usage,
      materialPalette: const ['', 'lava'],
      field: SmartTileField.cell(
        semanticCells: [for (var i = 0; i < 100; i++) i == 99 ? 0 : 1],
      ),
    ) as SmartTileLayer;

void main() {
  test('frame collision reuse is invalidated when the project catalog changes',
      () {
    final fixture = MovingPlatformFixture(smartTerrain: true);
    final definition = MovingPlatformDefinition.fromJson({
      ...fixture.definition.toJson(),
      'terrainCellsByLayer': {
        'magma': [
          {'x': 2, 'y': 2},
          {'x': 3, 'y': 2},
        ],
      },
    });
    final map = fixture.map.copyWith(
      movingPlatforms: [definition],
      layers: [
        ...fixture.map.layers,
        MovingPlatformFixture.terrain('independent', blockedIndex: 77),
      ],
    );
    final before = fixture.world(map: map);
    final atlas = fixture.project.tilesets.single;
    final updatedProject = fixture.project.copyWith(tilesets: [
      atlas.copyWith(
        source: const ProjectRegularAtlasTilesetSource(
          assetId: 'tiles',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
          tileProperties: [VisualTileProperty(tileId: 0, passable: true)],
        ),
      ),
    ]);
    expect(before.isBlocked(7, 7), true);
    final result = moveGameplayPlatform(
      world: before,
      project: updatedProject,
      worldState: fixture.state,
      platformId: 'bridge',
      motion: MovingPlatformMotion.forward,
    );
    expect(result.outcome, MovingPlatformMoveOutcome.moved);
    expect(result.finalWorld.isBlocked(7, 7), false);
    expect(before.isBlocked(7, 7), true);
  });

  test('motion frames preserve fixed collisions and match a fresh world', () {
    final fixture = MovingPlatformFixture(
      smartTerrain: true,
      preciseTerrain: true,
    );
    final map = fixture.map.copyWith(layers: [
      ...fixture.map.layers,
      MapLayer.collision(
        id: 'wall',
        name: 'Wall',
        collisions: [for (var i = 0; i < 100; i++) i == 77],
      ),
    ]);
    final original = fixture.world(map: map);
    final result = moveGameplayPlatform(
      world: original,
      project: fixture.project,
      worldState: fixture.state,
      platformId: 'bridge',
      motion: MovingPlatformMotion.forward,
    );
    expect(result.outcome, MovingPlatformMoveOutcome.moved);
    for (final frame in [
      result.frames.first,
      result.frames[result.frames.length ~/ 2],
      result.frames.last,
    ]) {
      final fresh = GameplayWorldState.initial(
        map: frame.world.map,
        project: fixture.project,
        movingPlatformWorldState: frame.worldState,
        playerPos: frame.world.player.pos,
        tileWidth: 32,
        tileHeight: 32,
      ).withPlayer(frame.world.player);
      for (var y = 0; y < 320; y += 7) {
        for (var x = 0; x < 320; x += 7) {
          final pixel = PixelRect(
            leftPx: x,
            topPx: y,
            widthPx: 1,
            heightPx: 1,
          );
          expect(frame.world.worldStaticObstaclesCollidePixelRect(pixel),
              fresh.worldStaticObstaclesCollidePixelRect(pixel));
        }
      }
    }
    expect(original.isBlocked(3, 2), true);
    expect(result.finalWorld.isBlocked(3, 2), false);
    expect(original.isBlocked(2, 2), false);
    expect(result.finalWorld.isBlocked(2, 2), true);
  });

  test('explicit terrain cells retain subcell boundaries on the source lattice',
      () {
    final fixture = MovingPlatformFixture(smartTerrain: true);
    final raw = fixture.definition.toJson()
      ..['lattice'] = {
        'widthPx': 32,
        'heightPx': 24,
        'originLeftPx': 0,
        'originTopPx': 0,
        'cellOffsetLeftPx': 0,
        'cellOffsetTopPx': 0,
      }
      ..['terrainCellsByLayer'] = {
        'magma': [
          {'x': 3, 'y': 3},
        ],
      };
    final map = fixture.map.copyWith(
      movingPlatforms: [MovingPlatformDefinition.fromJson(raw)],
    );
    final world = fixture.world(map: map);
    for (final (x, y, blocked) in [
      (100, 71, false),
      (100, 72, true),
      (100, 95, true),
      (100, 96, false),
      (127, 80, true),
      (128, 80, false),
    ]) {
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1),
        ),
        blocked,
        reason: 'pixel $x,$y',
      );
    }
    expect(
      MovingPlatformDefinition.fromJson(map.movingPlatforms.single.toJson()),
      map.movingPlatforms.single,
    );
  });

  test('precise terrain support cannot remove an independent wall', () {
    final fixture = MovingPlatformFixture(smartTerrain: true);
    final raw = fixture.definition.toJson()
      ..['terrainCellsByLayer'] = {
        'magma': [
          {'x': 2, 'y': 2},
        ],
      };
    final map = fixture.map.copyWith(
      movingPlatforms: [MovingPlatformDefinition.fromJson(raw)],
    );
    expect(fixture.world(map: map).isBlocked(2, 2), false);
    final wall = map.copyWith(layers: [
      ...map.layers,
      MapLayer.collision(
        id: 'wall',
        name: 'Wall',
        collisions: [for (var i = 0; i < 100; i++) i == 22],
      ),
    ]);
    expect(fixture.world(map: wall).isBlocked(2, 2), true);
  });

  test('terrain geometry must be bounded, nominated and shared consistently', () {
    final fixture = MovingPlatformFixture(smartTerrain: true);
    final raw = fixture.definition.toJson()
      ..['terrainCellsByLayer'] = {
        'magma': [
          {'x': 2, 'y': 2},
        ],
      };
    final definition = MovingPlatformDefinition.fromJson(raw);
    expect(() => definition.terrainCellsByLayer['magma']!.clear(),
        throwsUnsupportedError);
    expect(() => definition.terrainCellsByLayer.clear(), throwsUnsupportedError);
    expect(
      () => MovingPlatformDefinition.fromJson({
        ...raw,
        'terrainCellsByLayer': {
          'not-nominated': [
            {'x': 2, 'y': 2},
          ],
        },
      }),
      throwsFormatException,
    );
    final outside = MovingPlatformDefinition.fromJson({
      ...raw,
      'terrainCellsByLayer': {
        'magma': [
          {'x': 10, 'y': 2},
        ],
      },
    });
    expect(
      () => fixture.world(
        map: fixture.map.copyWith(movingPlatforms: [outside]),
      ),
      throwsFormatException,
    );
    final other = MovingPlatformDefinition.fromJson({
      ...raw,
      'id': 'other',
      'placedElementId': 'other-art',
      'terrainCellsByLayer': {
        'magma': [
          {'x': 3, 'y': 2},
        ],
      },
    });
    expect(
      () => fixture.world(
        map: fixture.map.copyWith(
          movingPlatforms: [definition, other],
          placedElements: [
            ...fixture.map.placedElements,
            fixture.map.placedElements.single.copyWith(id: 'other-art'),
          ],
        ),
      ),
      throwsFormatException,
    );
  });

  for (final usage in [SmartTileUsage.terrain, SmartTileUsage.path]) {
    test('$usage support blocks occupied ground only outside the platform', () {
      final fixture = MovingPlatformFixture();
      final map = fixture.map.copyWith(layers: [terrain(usage: usage)]);
      final world = fixture.world(map: map);
      expect(world.isBlocked(2, 2), false);
      expect(world.isBlocked(3, 2), true);
      expect(world.isBlocked(9, 9), false);
      final pose = fixture.state.withPlatform(
        mapId: 'gym',
        platformId: 'bridge',
        pose: MovingPlatformPose(leftPx: 65, topPx: 64, quarterTurns: 0),
      );
      final shifted = fixture.world(map: map, state: pose);
      for (final entry in {64: true, 65: false, 96: false, 97: true}.entries) {
        expect(
          shifted.worldStaticObstaclesCollidePixelRect(
            PixelRect(leftPx: entry.key, topPx: 70, widthPx: 1, heightPx: 1),
          ),
          entry.value,
        );
      }
    });
  }

  for (var rotation = 0; rotation < 4; rotation++) {
    test('Smart Tile platform carries, saves and returns at rotation $rotation',
        () {
      final fixture = MovingPlatformFixture(quarterTurns: rotation);
      final map = fixture.map.copyWith(layers: [terrain()]);
      final world = fixture.world(map: map);
      final moved = moveGameplayPlatform(
        world: world,
        project: fixture.project,
        worldState: fixture.state,
        platformId: 'bridge',
        motion: MovingPlatformMotion.forward,
      );
      expect(moved.outcome, MovingPlatformMoveOutcome.moved);
      expect(moved.finalWorld.map.layers, map.layers);
      final restored = MovingPlatformWorldState.fromJson(
        moved.finalWorldState.toJson(),
      );
      validateGameplayMovingPlatformWorldState(
        project: fixture.project,
        maps: [map],
        worldState: restored,
      );
      final returned = moveGameplayPlatform(
        world: moved.finalWorld,
        project: fixture.project,
        worldState: restored,
        platformId: 'bridge',
        motion: MovingPlatformMotion.backward,
      );
      expect(returned.outcome, MovingPlatformMoveOutcome.moved);
      expect(returned.finalWorldState, fixture.state);
      expect(returned.finalWorld.player.playerPositionPx.leftPx,
          world.player.playerPositionPx.leftPx);
      expect(returned.finalWorld.player.playerPositionPx.topPx,
          world.player.playerPositionPx.topPx);
    });
  }

  test('Smart Tile support preserves independent walls and rolls back travel',
      () {
    final fixture = MovingPlatformFixture(distance: 3);
    final map = fixture.map.copyWith(layers: [
      terrain(),
      MapLayer.collision(
        id: 'wall',
        name: 'Wall',
        collisions: [for (var i = 0; i < 100; i++) i == 24],
      ),
    ]);
    final before = fixture.world(map: map);
    final result = moveGameplayPlatform(
      world: before,
      project: fixture.project,
      worldState: fixture.state,
      platformId: 'bridge',
      motion: MovingPlatformMotion.forward,
    );
    expect(result.outcome, MovingPlatformMoveOutcome.blocked);
    expect(result.frames.where((frame) => !frame.returning).length, 32);
    expect(result.frames.where((frame) => frame.returning).length, 32);
    expect(result.finalWorldState, fixture.state);
    expect(identical(result.finalWorld, before), true);
    final overlapping = map.copyWith(layers: [
      terrain(),
      MapLayer.collision(
        id: 'wall',
        name: 'Wall',
        collisions: [for (var i = 0; i < 100; i++) i == 22],
      ),
    ]);
    expect(fixture.world(map: overlapping).isBlocked(2, 2), true);
    expect(
      () => validateGameplayMovingPlatformWorldState(
        project: fixture.project,
        maps: [overlapping],
        worldState: fixture.state,
      ),
      throwsFormatException,
    );
  });

  test('unnominated Smart Tile ground retains its ordinary passability', () {
    final fixture = MovingPlatformFixture();
    final ordinary = fixture.map.copyWith(
      layers: [terrain()],
      movingPlatforms: const [],
    );
    final world = GameplayWorldState.initial(
      map: ordinary,
      project: fixture.project,
      playerPos: const GridPos(x: 2, y: 2),
      tileWidth: 32,
      tileHeight: 32,
    );
    expect(world.isBlocked(3, 2), false);
  });

  test('a named empty material is not a supportable ground obstacle', () {
    final fixture = MovingPlatformFixture(smartTerrain: true);
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: [
          ...fixture.project.smartTileCatalog.materials,
          const ProjectSmartTileMaterial(
            id: 'empty-ground',
            name: 'Empty ground',
            connectionGroupId: 'empty',
            isEmpty: true,
          ),
        ],
      ),
    );
    final map = fixture.map.copyWith(layers: [
      terrain().copyWith(materialPalette: const ['', 'empty-ground']),
    ]);
    final world = GameplayWorldState.initial(
      map: map,
      project: project,
      movingPlatformWorldState: fixture.state,
      playerPos: const GridPos(x: 2, y: 2),
      tileWidth: 32,
      tileHeight: 32,
    );
    expect(world.isBlocked(3, 2), false);
  });

  test('motion cannot ignore another platform terrain nomination', () {
    final fixture = MovingPlatformFixture();
    final ownJson = fixture.definition.toJson();
    for (final variant in ownJson['variants'] as List) {
      for (final key in ['clearanceCells', 'forwardClearanceCells']) {
        variant[key] = [
          {'x': 0, 'y': 0},
          {'x': 1, 'y': 0},
        ];
      }
    }
    final otherJson = fixture.definition.toJson()
      ..['id'] = 'other'
      ..['placedElementId'] = 'other-art'
      ..['terrainLayerIds'] = ['other-ground']
      ..['initialPose'] = {
        'leftPx': 192,
        'topPx': 192,
        'quarterTurns': 0,
      };
    final map = fixture.map.copyWith(
      movingPlatforms: [
        MovingPlatformDefinition.fromJson(ownJson),
        MovingPlatformDefinition.fromJson(otherJson),
      ],
      layers: [
        terrain(),
        terrain().copyWith(
          id: 'other-ground',
          field: SmartTileField.cell(
            semanticCells: [for (var i = 0; i < 100; i++) i == 24 ? 1 : 0],
          ),
        ),
      ],
      placedElements: [
        ...fixture.map.placedElements,
        fixture.map.placedElements.single.copyWith(id: 'other-art'),
      ],
    );
    final world = fixture.world(map: map);
    final result = moveGameplayPlatform(
      world: world,
      project: fixture.project,
      worldState: fixture.state,
      platformId: 'bridge',
      motion: MovingPlatformMotion.forward,
    );
    expect(result.outcome, MovingPlatformMoveOutcome.blocked);
    expect(result.finalWorldState.platform('gym', 'bridge'),
        fixture.state.platform('gym', 'bridge'));
  });
}
