import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final playerTarget = SceneActorTarget.player(mapId: 'map');
  final npcTarget = SceneActorTarget.entity(mapId: 'map', entityId: 'actor');

  for (final direction in EntityFacing.values) {
    test('player moves exactly one cell $direction without changing the world',
        () {
      final world = _world();
      final plan = planActorRouteMove(
        world: world,
        target: playerTarget,
        direction: direction,
        through: false,
      )!;
      final d = direction.asDirection;
      expect(plan.from, const GridPos(x: 2, y: 2));
      expect(plan.to, GridPos(x: 2 + d.dx, y: 2 + d.dy));
      expect(plan.toPositionPx.leftPx - plan.fromPositionPx.leftPx, d.dx * 16);
      expect(plan.toPositionPx.topPx - plan.fromPositionPx.topPx, d.dy * 16);
      expect(plan.playerState!.pos, plan.to);
      expect(plan.playerState!.facing, d);
      expect(world.player.pos, plan.from);
    });
    test('NPC moves exactly one cell $direction and ignores only itself', () {
      final world = _world(entities: [_npc()]);
      final plan = planActorRouteMove(
        world: world,
        target: npcTarget,
        direction: direction,
        through: false,
      )!;
      final d = direction.asDirection;
      expect(plan.from, const GridPos(x: 2, y: 2));
      expect(plan.to, GridPos(x: 2 + d.dx, y: 2 + d.dy));
      expect(plan.playerState, isNull);
      expect(world.map.entities.single.pos, plan.from);
    });
  }

  test('player retains its current pixel offset and sprite dimensions', () {
    var world = _world();
    final player = GameplayPlayerState.fromGridSpawn(
      cell: const GridPos(x: 2, y: 2),
      facing: Direction.north,
      tileWidthPx: 16,
      tileHeightPx: 16,
      mapWidthCells: 6,
      mapHeightCells: 6,
      spriteWidthPx: 40,
      spriteHeightPx: 48,
    );
    world = world.withPlayer(player.copyWith(
      playerPositionPx: PixelPosition(
        leftPx: player.playerPositionPx.leftPx + 3,
        topPx: player.playerPositionPx.topPx - 2,
      ),
    ));
    final plan = planActorRouteMove(
      world: world,
      target: playerTarget,
      direction: EntityFacing.east,
      through: false,
    )!;
    expect(plan.toPositionPx.leftPx, world.player.playerPositionPx.leftPx + 16);
    expect(plan.toPositionPx.topPx, world.player.playerPositionPx.topPx);
    expect(plan.playerState!.playerSpriteWidthPx, 40);
    expect(plan.playerState!.playerSpriteHeightPx, 48);
    expect(plan.to, const GridPos(x: 3, y: 2));
  });

  test('a free target cell centre does not admit a blocked player footprint',
      () {
    final world = _world(pixel: const GridPos(x: 52, y: 44));
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(3, 2), isFalse);
    expect(
        planActorRouteMove(
          world: world,
          target: playerTarget,
          direction: EntityFacing.east,
          through: false,
        ),
        isNull);
  });

  test(
      'player cannot tunnel through a pixel absent from both endpoint footprints',
      () {
    final world = _world(pixel: const GridPos(x: 47, y: 44));
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
    expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(leftPx: 50, topPx: 40, widthPx: 12, heightPx: 8),
          playerContact: true,
        ),
        isFalse);
    expect(
        planActorRouteMove(
          world: world,
          target: playerTarget,
          direction: EntityFacing.east,
          through: false,
        ),
        isNull);
  });

  test('NPC cannot tunnel through a fine mask', () {
    final world =
        _world(entities: [_npc()], pixel: const GridPos(x: 47, y: 44));
    expect(
        planActorRouteMove(
          world: world,
          target: npcTarget,
          direction: EntityFacing.east,
          through: false,
        ),
        isNull);
  });

  for (final reverse in [false, true]) {
    test('another overlapping NPC remains blocking in order $reverse', () {
      final actors = [_npc(), _npc(id: 'other')];
      final world =
          _world(entities: reverse ? actors.reversed.toList() : actors);
      expect(
          planActorRouteMove(
            world: world,
            target: npcTarget,
            direction: EntityFacing.east,
            through: false,
          ),
          isNull);
    });
  }

  test('a large NPC can overlap its own previous footprint', () {
    final world = _world(entities: [
      _npc(
        size: const GridSize(width: 2, height: 2),
        properties: const {'collision.width': '2', 'collision.height': '1'},
      )
    ]);
    expect(
        planActorRouteMove(
          world: world,
          target: npcTarget,
          direction: EntityFacing.east,
          through: false,
        ),
        isNotNull);
  });

  test('NPC movement respects the player contact footprint', () {
    final world =
        _world(entities: [_npc()], playerCell: const GridPos(x: 3, y: 2));
    expect(
        planActorRouteMove(
          world: world,
          target: npcTarget,
          direction: EntityFacing.east,
          through: false,
        ),
        isNull);
  });

  for (final npc in [false, true]) {
    test('dynamic cells and reservations obstruct ${npc ? 'NPC' : 'player'}',
        () {
      final world = _world(entities: npc ? [_npc()] : []);
      final target = npc ? npcTarget : playerTarget;
      expect(
          planActorRouteMove(
            world: world,
            target: target,
            direction: EntityFacing.east,
            through: false,
            dynamicBlockedCells: const [GridPos(x: 3, y: 2)],
          ),
          isNull);
      expect(
          planActorRouteMove(
            world: world,
            target: target,
            direction: EntityFacing.east,
            through: false,
            characterReservations: const [
              PixelRect(leftPx: 47, topPx: 44, widthPx: 1, heightPx: 1),
            ],
          ),
          isNull);
    });
    test(
        'through skips local obstacles without modifying ${npc ? 'NPC' : 'player'}',
        () {
      final world = _world(
          entities: npc ? [_npc(), _npc(id: 'other')] : [],
          pixel: const GridPos(x: 52, y: 44),
          water: true);
      final mapBefore = world.map.toJson();
      final plan = planActorRouteMove(
        world: world,
        target: npc ? npcTarget : playerTarget,
        direction: EntityFacing.east,
        through: true,
        dynamicBlockedCells: const [GridPos(x: 3, y: 2)],
        characterReservations: const [
          PixelRect(leftPx: 47, topPx: 44, widthPx: 16, heightPx: 16),
        ],
      );
      expect(plan, isNotNull);
      expect(world.map.toJson(), mapBefore);
      expect(world.player.pos,
          npc ? const GridPos(x: 0, y: 0) : const GridPos(x: 2, y: 2));
    });
    test(
        'through still refuses an out-of-bounds ${npc ? 'NPC' : 'player'} footprint',
        () {
      final world = _world(
          entities: npc ? [_npc(pos: const GridPos(x: 5, y: 2))] : [],
          playerCell: const GridPos(x: 5, y: 2));
      expect(
          planActorRouteMove(
            world: world,
            target: npc ? npcTarget : playerTarget,
            direction: EntityFacing.east,
            through: true,
          ),
          isNull);
    });
  }

  test('walking player refuses water while surf permits it', () {
    final world = _world(water: true);
    expect(
        planActorRouteMove(
            world: world,
            target: playerTarget,
            direction: EntityFacing.east,
            through: false),
        isNull);
    expect(
        planActorRouteMove(
            world: world.withPlayer(
                world.player.copyWith(movementMode: MovementMode.surf)),
            target: playerTarget,
            direction: EntityFacing.east,
            through: false),
        isNotNull);
  });

  test(
      'through keeps a whole footprint in bounds even with an in-bounds anchor',
      () {
    var world = _world(playerCell: const GridPos(x: 4, y: 2));
    world = world.withPlayer(world.player.copyWith(
        playerPositionPx: PixelPosition(
      leftPx: world.player.playerPositionPx.leftPx + 7,
      topPx: world.player.playerPositionPx.topPx,
    )));
    expect(
        planActorRouteMove(
            world: world,
            target: playerTarget,
            direction: EntityFacing.east,
            through: true),
        isNull);
  });

  test('through can enter and leave an obstacle without leaking to later steps',
      () {
    final initial = _world(pixel: const GridPos(x: 52, y: 44));
    final into = planActorRouteMove(
        world: initial,
        target: playerTarget,
        direction: EntityFacing.east,
        through: true)!;
    final occupied = initial.withPlayer(into.playerState!);
    expect(occupied.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    expect(
        planActorRouteMove(
            world: occupied,
            target: playerTarget,
            direction: EntityFacing.west,
            through: false),
        isNull);
    final away = planActorRouteMove(
        world: occupied,
        target: playerTarget,
        direction: EntityFacing.west,
        through: true)!;
    final returned = occupied.withPlayer(away.playerState!);
    expect(
        planActorRouteMove(
            world: returned,
            target: playerTarget,
            direction: EntityFacing.east,
            through: false),
        isNull);
    expect(returned.player.pos, initial.player.pos);
  });

  test(
      'a normal forced move produces a plan without triggering an arrival warp',
      () {
    final base = _world();
    final world = GameplayWorldState.initial(
        map: base.map.copyWith(warps: const [
          MapWarp(
              id: 'warp',
              pos: GridPos(x: 3, y: 2),
              targetMapId: 'other',
              targetPos: GridPos(x: 1, y: 1)),
        ]),
        playerPos: base.player.pos);
    expect(
        planActorRouteMove(
                world: world,
                target: playerTarget,
                direction: EntityFacing.east,
                through: false)!
            .to,
        const GridPos(x: 3, y: 2));
    expect(world.player.pos, base.player.pos);
  });

  test('NPC refuses water without through', () {
    expect(
        planActorRouteMove(
            world: _world(entities: [_npc()], water: true),
            target: npcTarget,
            direction: EntityFacing.east,
            through: false),
        isNull);
  });

  test('unknown, ambiguous and non-NPC targets are errors', () {
    final targets = [
      _world(),
      _world(entities: [_npc(), _npc()]),
      _world(entities: [
        const MapEntity(
            id: 'actor', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 2))
      ]),
    ];
    for (final world in targets) {
      expect(
          () => planActorRouteMove(
              world: world,
              target: npcTarget,
              direction: EntityFacing.east,
              through: true),
          throwsStateError);
    }
  });

  test('a target in another map is an error', () {
    expect(
        () => planActorRouteMove(
            world: _world(),
            target: SceneActorTarget.player(mapId: 'other'),
            direction: EntityFacing.east,
            through: true),
        throwsStateError);
  });

  test('an absent NPC is an error and unrelated absent blockers stay absent',
      () {
    final hidden = _world(entities: [_npc()])
        .withNpcMapPresencePredicate((_, entity) => false);
    expect(
        () => planActorRouteMove(
            world: hidden,
            target: npcTarget,
            direction: EntityFacing.east,
            through: true),
        throwsStateError);
    final world = _world(entities: [_npc(), _npc(id: 'hidden')])
        .withMapEntityPresencePredicate((_, entity) => entity.id != 'hidden');
    expect(
        planActorRouteMove(
            world: world,
            target: npcTarget,
            direction: EntityFacing.east,
            through: false),
        isNotNull);
  });

  test('a target whose initial physical pose is outside the map is an error',
      () {
    final world = _world().withPlayer(_world().player.copyWith(
        playerPositionPx: const PixelPosition(leftPx: -100, topPx: 0)));
    expect(
        () => planActorRouteMove(
            world: world,
            target: playerTarget,
            direction: EntityFacing.east,
            through: true),
        throwsStateError);
  });

  test('an incoherent player grid projection is an error', () {
    final base = _world();
    final world =
        base.withPlayer(base.player.copyWith(pos: const GridPos(x: 1, y: 2)));
    expect(
        () => planActorRouteMove(
            world: world,
            target: playerTarget,
            direction: EntityFacing.east,
            through: true),
        throwsStateError);
  });

  test('a large NPC cannot move its footprint outside the map with through',
      () {
    final world = _world(entities: [
      _npc(
          pos: const GridPos(x: 4, y: 2),
          size: const GridSize(width: 2, height: 2),
          properties: const {'collision.width': '2', 'collision.height': '1'})
    ]);
    expect(
        planActorRouteMove(
            world: world,
            target: npcTarget,
            direction: EntityFacing.east,
            through: true),
        isNull);
  });
}

MapEntity _npc(
        {String id = 'actor',
        GridPos pos = const GridPos(x: 2, y: 2),
        GridSize size = const GridSize(width: 1, height: 1),
        Map<String, String> properties = const {}}) =>
    MapEntity(
        id: id,
        kind: MapEntityKind.npc,
        pos: pos,
        size: size,
        npc: const MapEntityNpcData(),
        properties: properties);

GameplayWorldState _world(
    {List<MapEntity> entities = const [],
    GridPos? playerCell,
    GridPos? pixel,
    bool water = false}) {
  final mask = List<bool>.filled(16 * 16, false);
  if (pixel != null) mask[(pixel.y % 16) * 16 + pixel.x % 16] = true;
  final project =
      ProjectManifest(name: 'Test', maps: const [], tilesets: const [
    ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
  ], elements: [
    ProjectElementEntry(
        id: 'fine',
        name: 'Fine',
        tilesetId: 'tiles',
        categoryId: 'test',
        frames: const [
          TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16))
        ],
        collisionProfile: ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
                widthPx: 16,
                heightPx: 16,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 16, heightPx: 16, solidPixels: mask))))
  ]);
  final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 6, height: 6),
      layers: const [],
      entities: entities,
      placedElements: pixel == null
          ? const []
          : [
              MapPlacedElement(
                  id: 'fine',
                  layerId: 'objects',
                  elementId: 'fine',
                  pos: GridPos(x: pixel.x ~/ 16, y: pixel.y ~/ 16),
                  applyCollision: true)
            ],
      gameplayZones: water
          ? const [
              MapGameplayZone(
                  id: 'water',
                  kind: GameplayZoneKind.movement,
                  area: MapRect(
                      pos: GridPos(x: 3, y: 2),
                      size: GridSize(width: 1, height: 1)),
                  movement:
                      MovementZonePayload(requiredMode: MovementMode.surf))
            ]
          : const []);
  return GameplayWorldState.initial(
      map: map,
      project: project,
      playerPos: playerCell ??
          (entities.isEmpty
              ? const GridPos(x: 2, y: 2)
              : const GridPos(x: 0, y: 0)));
}
