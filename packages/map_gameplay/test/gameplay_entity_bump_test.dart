import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final direction in Direction.values) {
    test('a refused pixel move records the physical NPC contact $direction',
        () {
      final world = _contactWorld(direction);
      final result = stepGameplayWorld(
        world,
        MoveIntent(direction, pixelsPerStep: 1),
      );
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.solid);
      expect(blocked.entityBumpContact, isNotNull);
      final contact = blocked.entityBumpContact!;
      expect(contact.mapId, world.map.id);
      expect(contact.entityId, 'npc');
      expect(contact.direction, direction);
      expect(contact.attemptedPixelsPerStep, 1);
      expect(contact.playerPos, world.player.pos);
      expect(contact.playerPositionPx.leftPx,
          world.player.playerPositionPx.leftPx);
      expect(
          contact.playerPositionPx.topPx, world.player.playerPositionPx.topPx);
      expect(contact.entityPos, world.map.entities.single.pos);
      expect(contact.playerSpriteWidthPx, world.player.playerSpriteWidthPx);
      expect(contact.playerSpriteHeightPx, world.player.playerSpriteHeightPx);
      expect(blocked.world.player.playerPositionPx.leftPx,
          world.player.playerPositionPx.leftPx);
      expect(blocked.world.player.playerPositionPx.topPx,
          world.player.playerPositionPx.topPx);
    });
  }

  test('a refused normal tile move north reports the first NPC collision', () {
    final world = GameplayWorldState.initial(
      map: const MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 6, height: 6),
          entities: [
            MapEntity(
                id: 'npc',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2, y: 1),
                npc: MapEntityNpcData(characterId: 'character'),
                properties: {'collision.width': '1', 'collision.height': '1'}),
          ]),
      playerPos: const GridPos(x: 2, y: 2),
    );
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.north, pixelsPerStep: 16)) as Blocked;
    expect(result.reason, GameplayMovementBlockReason.solid);
    expect(result.world.player.playerPositionPx.leftPx,
        world.player.playerPositionPx.leftPx);
    expect(result.world.player.playerPositionPx.topPx,
        world.player.playerPositionPx.topPx);
    expect(result.entityBumpContact, isNotNull);
  });

  for (final direction in Direction.values) {
    test('the first collision of an atomic grid step is an NPC $direction', () {
      final world = _gridWorld(direction);
      final result =
          stepGameplayWorld(world, MoveIntent(direction, pixelsPerStep: 16))
              as Blocked;
      expect(result.entityBumpContact?.entityId, 'npc');
      expect(result.entityBumpContact?.attemptedPixelsPerStep, 16);
      expect(result.world.player.playerPositionPx.leftPx,
          world.player.playerPositionPx.leftPx);
      expect(result.world.player.playerPositionPx.topPx,
          world.player.playerPositionPx.topPx);
      expect(
          resolvePlayerEntityBumpContact(world, direction,
                  attemptedPixelsPerStep: 16)
              ?.entityId,
          'npc');
    });
  }

  for (final sample in [('earlier', 39), ('simultaneous', 31), ('later', 30)]) {
    test(
        'a fine obstacle ${sample.$1} than the owner preserves first collision',
        () {
      final world = _withMask(
          _gridWorld(Direction.north), PixelPoint(xPx: 35, yPx: sample.$2));
      final result = stepGameplayWorld(
              world, const MoveIntent(Direction.north, pixelsPerStep: 16))
          as Blocked;
      if (sample.$1 == 'later') {
        expect(result.entityBumpContact?.entityId, 'npc');
      } else {
        expect(result.entityBumpContact, isNull);
      }
    });
  }

  for (final sample in [('earlier', 39), ('simultaneous', 31), ('later', 30)]) {
    test(
        'an anonymous reservation ${sample.$1} than the owner remains anonymous',
        () {
      final world = _gridWorld(Direction.north);
      final result = stepGameplayWorld(
          world, const MoveIntent(Direction.north, pixelsPerStep: 16),
          characterReservations: [
            PixelRect(leftPx: 35, topPx: sample.$2, widthPx: 1, heightPx: 1)
          ]) as Blocked;
      if (sample.$1 == 'later') {
        expect(result.entityBumpContact?.entityId, 'npc');
      } else {
        expect(result.entityBumpContact, isNull);
      }
    });
  }

  test('zero-area anonymous reservations retain ordinary interval semantics',
      () {
    final world = _contactWorld(Direction.east);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 1),
        characterReservations: const [
          PixelRect(leftPx: 48, topPx: 44, widthPx: 0, heightPx: 0)
        ]) as Blocked;
    expect(result.entityBumpContact, isNull);
  });

  test('requested contact distance cannot exceed one cell', () {
    final world = _contactWorld(Direction.east);
    for (final step in [-1, 0, 17, 32]) {
      expect(
          resolvePlayerEntityBumpContact(world, Direction.east,
              attemptedPixelsPerStep: step),
          isNull);
    }
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 32)) as Blocked;
    expect(result.entityBumpContact, isNull);
  });

  test('the public collector revalidates the same one pixel contact', () {
    final world = _contactWorld(Direction.east);
    expect(resolvePlayerEntityBumpContact(world, Direction.east), isNotNull);
  });

  test('a zero movement has no bump metadata', () {
    final result = stepGameplayWorld(
      _contactWorld(Direction.east),
      const MoveIntent(Direction.east, pixelsPerStep: 0),
    );
    expect(result, isA<Blocked>());
    expect((result as Blocked).entityBumpContact, isNull);
  });

  test('atomic attempts and smaller pixel moves keep the actual pose', () {
    var world = _contactWorld(Direction.east);
    world = world.withPlayer(world.player.copyWith(
      playerPositionPx: PixelPosition(
        leftPx: world.player.playerPositionPx.leftPx - 2,
        topPx: world.player.playerPositionPx.topPx,
      ),
    ));
    final distant = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 16)) as Blocked;
    expect(distant.entityBumpContact?.entityId, 'npc');
    expect(distant.entityBumpContact?.attemptedPixelsPerStep, 16);
    expect(distant.world.player.playerPositionPx.leftPx,
        world.player.playerPositionPx.leftPx);
    for (var i = 0; i < 2; i++) {
      final moved = stepGameplayWorld(
          world, const MoveIntent(Direction.east, pixelsPerStep: 1));
      expect(moved, isA<Moved>());
      world = moved.world;
    }
    final contact = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 1)) as Blocked;
    expect(contact.entityBumpContact?.entityId, 'npc');
  });

  for (final mode in [
    'npc-absent',
    'entity-absent',
    'nonblocking',
    'sign',
    'duplicate-id',
    'two-owners',
    'wide-other',
    'other-sign'
  ]) {
    test('contact stays closed for $mode', () {
      final original = _contactWorld(Direction.east);
      final owner = original.map.entities.single;
      final entities = switch (mode) {
        'nonblocking' => [owner.copyWith(blocksMovement: false)],
        'sign' => [owner.copyWith(kind: MapEntityKind.sign)],
        'duplicate-id' => [owner, owner.copyWith(blocksMovement: false)],
        'two-owners' => [owner, owner.copyWith(id: 'other')],
        'wide-other' => [
            owner,
            owner.copyWith(
                id: 'other',
                pos: const GridPos(x: 2, y: 2),
                size: const GridSize(width: 2, height: 1))
          ],
        'other-sign' => [
            owner,
            owner.copyWith(id: 'other', kind: MapEntityKind.sign)
          ],
        _ => [owner],
      };
      var world = _rebuild(original, original.map.copyWith(entities: entities));
      if (mode == 'npc-absent') {
        world = world.withNpcMapPresencePredicate((_, __) => false);
      }
      if (mode == 'entity-absent') {
        world = world.withMapEntityPresencePredicate((_, __) => false);
      }
      expect(resolvePlayerEntityBumpContact(world, Direction.east), isNull);
      final result = stepGameplayWorld(
          world, const MoveIntent(Direction.east, pixelsPerStep: 1));
      if (result is Blocked) expect(result.entityBumpContact, isNull);
    });
  }

  test('an unrelated absent NPC does not erase the real owner', () {
    final original = _contactWorld(Direction.east);
    final owner = original.map.entities.single;
    final world = _rebuild(
        original,
        original.map.copyWith(entities: [
          owner,
          owner.copyWith(id: 'other'),
        ])).withNpcMapPresencePredicate((_, entity) => entity.id == 'npc');
    expect(
        resolvePlayerEntityBumpContact(world, Direction.east)?.entityId, 'npc');
  });

  test('an anonymous reservation at the attempted contact is never ignored',
      () {
    final world = _contactWorld(Direction.east);
    final reservation = resolveEntityCollisionRectPx(world.map.entities.single,
        tileWidthPx: 16, tileHeightPx: 16);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 1),
        characterReservations: [reservation]) as Blocked;
    expect(result.entityBumpContact, isNull);
    expect(
        resolvePlayerEntityBumpContact(world, Direction.east,
            characterReservations: [reservation]),
        isNull);
  });

  test('a distant reservation does not erase the real contact', () {
    final world = _contactWorld(Direction.east);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 1),
        characterReservations: const [
          PixelRect(leftPx: 0, topPx: 0, widthPx: 1, heightPx: 1)
        ]) as Blocked;
    expect(result.entityBumpContact?.entityId, 'npc');
  });

  test('terrain stays blocking when the candidate NPC is ignored', () {
    final original = _contactWorld(Direction.east);
    final collisions = List<bool>.filled(36, false)..[2 * 6 + 3] = true;
    final world = _rebuild(
        original,
        original.map.copyWith(layers: [
          MapLayer.collision(
              id: 'collision', name: 'Collision', collisions: collisions),
        ]));
    expect(resolvePlayerEntityBumpContact(world, Direction.east), isNull);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 1)) as Blocked;
    expect(result.reason, GameplayMovementBlockReason.solid);
    expect(result.entityBumpContact, isNull);
  });

  test('a fine placed mask is not mistaken for its overlapping NPC', () {
    final original = _contactWorld(Direction.east);
    final pixels = List<bool>.filled(256, false)..[8 * 16] = true;
    final project =
        ProjectManifest(name: 'Project', maps: const [], tilesets: const [
      ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
    ], elements: [
      ProjectElementEntry(
          id: 'mask',
          name: 'Mask',
          tilesetId: 'tiles',
          categoryId: 'obstacle',
          frames: const [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16))
          ],
          collisionProfile: ElementCollisionProfile(
              collisionMask: ElementCollisionPixelMask(
                  widthPx: 16,
                  heightPx: 16,
                  dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                      widthPx: 16, heightPx: 16, solidPixels: pixels))))
    ]);
    final map = original.map.copyWith(placedElements: const [
      MapPlacedElement(
          id: 'mask',
          layerId: 'objects',
          elementId: 'mask',
          pos: GridPos(x: 3, y: 2),
          applyCollision: true)
    ]);
    final world = _rebuild(original, map, project: project);
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 1)) as Blocked;
    expect(result.entityBumpContact, isNull);
  });

  test('water reason and bounds never become an entity bump', () {
    final original = _contactWorld(Direction.east);
    final water = _rebuild(
        original,
        original.map.copyWith(gameplayZones: const [
          MapGameplayZone(
              id: 'water',
              kind: GameplayZoneKind.movement,
              area: MapRect(
                  pos: GridPos(x: 3, y: 2),
                  size: GridSize(width: 1, height: 1)),
              movement: MovementZonePayload(requiredMode: MovementMode.surf)),
        ]));
    final blocked = stepGameplayWorld(
        water, const MoveIntent(Direction.east, pixelsPerStep: 1)) as Blocked;
    expect(blocked.reason, GameplayMovementBlockReason.waterRequiresSurf);
    expect(blocked.entityBumpContact, isNull);
    expect(resolvePlayerEntityBumpContact(water, Direction.east), isNull);
    final surf = water
        .withPlayer(water.player.copyWith(movementMode: MovementMode.surf));
    expect(
        resolvePlayerEntityBumpContact(surf, Direction.east)?.entityId, 'npc');
    final edge = GameplayWorldState.initial(
        map: original.map, playerPos: const GridPos(x: 5, y: 2));
    final outside = stepGameplayWorld(
        edge, const MoveIntent(Direction.east, pixelsPerStep: 1)) as Blocked;
    expect(outside.reason, GameplayMovementBlockReason.outOfBounds);
    expect(outside.entityBumpContact, isNull);
  });

  test('an initially overlapping pose and incoherent grid are not new contacts',
      () {
    final world = _contactWorld(Direction.east);
    final overlapping = world.withPlayer(world.player.copyWith(
        playerPositionPx: PixelPosition(
            leftPx: world.player.playerPositionPx.leftPx + 1,
            topPx: world.player.playerPositionPx.topPx)));
    expect(resolvePlayerEntityBumpContact(overlapping, Direction.east), isNull);
    expect(
        resolvePlayerEntityBumpContact(
            world.withPlayer(
                world.player.copyWith(pos: const GridPos(x: 0, y: 0))),
            Direction.east),
        isNull);
  });

  test('world query default is unchanged and ignoring does not mutate presence',
      () {
    final world = _contactWorld(Direction.east);
    final attempted = PixelRect(
        leftPx: world.player.playerCollisionRectPx.leftPx + 1,
        topPx: world.player.playerCollisionRectPx.topPx,
        widthPx: 12,
        heightPx: 8);
    expect(
        world.worldStaticObstaclesCollidePixelRect(attempted,
            playerContact: true),
        isTrue);
    expect(
        world.worldStaticObstaclesCollidePixelRect(attempted,
            playerContact: true, ignoredEntityId: 'npc'),
        isFalse);
    expect(
        world.worldStaticObstaclesCollidePixelRect(attempted,
            playerContact: true, ignoredEntityId: 'missing'),
        isTrue);
    expect(
        world.worldStaticObstaclesCollidePixelRect(attempted,
            playerContact: true),
        isTrue);
    expect(world.map.entities.single.id, 'npc');
  });

  test('an ignored NPC ID cannot ignore a sign', () {
    final original = _contactWorld(Direction.east);
    final world = _rebuild(
        original,
        original.map.copyWith(entities: [
          original.map.entities.single.copyWith(kind: MapEntityKind.sign),
        ]));
    final attempted = PixelRect(
        leftPx: world.player.playerCollisionRectPx.leftPx + 1,
        topPx: world.player.playerCollisionRectPx.topPx,
        widthPx: 12,
        heightPx: 8);
    expect(
        world.worldStaticObstaclesCollidePixelRect(attempted,
            playerContact: true, ignoredEntityId: 'npc'),
        isTrue);
  });

  test('general canonical NPC contact sizes are preserved in the snapshot', () {
    final original = _contactWorld(Direction.east);
    final owner = original.map.entities.single.copyWith(
      size: const GridSize(width: 2, height: 2),
      properties: const {'collision.width': '2', 'collision.height': '2'},
    );
    final world = _rebuild(original, original.map.copyWith(entities: [owner]));
    final contact = resolvePlayerEntityBumpContact(world, Direction.east)!;
    expect(contact.entityPos, owner.pos);
    expect(contact.entityCollisionRectPx.widthPx, 32);
    expect(contact.entityCollisionRectPx.heightPx, 32);
  });

  test('changed presence cannot manufacture contact outside the world cache',
      () {
    var present = false;
    final original = _contactWorld(Direction.east);
    final world = original.withNpcMapPresencePredicate((_, __) => present);
    present = true;
    expect(resolvePlayerEntityBumpContact(world, Direction.east), isNull);
  });

  test('bump Warp keeps priority over the NPC contact', () {
    final original = _contactWorld(Direction.east);
    final world = _rebuild(
        original,
        original.map.copyWith(warps: const [
          MapWarp(
              id: 'warp',
              pos: GridPos(x: 3, y: 2),
              targetMapId: 'target',
              targetPos: GridPos(x: 0, y: 0),
              triggerMode: MapWarpTriggerMode.onBump),
        ]));
    expect(
        stepGameplayWorld(
            world, const MoveIntent(Direction.east, pixelsPerStep: 1)),
        isA<WarpTriggered>());
  });

  test('placed bump behavior keeps priority over the NPC contact', () {
    final original = _contactWorld(Direction.east);
    final world = _rebuild(
        original,
        original.map.copyWith(placedElements: const [
          MapPlacedElement(
              id: 'placed',
              layerId: 'objects',
              elementId: 'element',
              pos: GridPos(x: 3, y: 2),
              applyCollision: false,
              behaviors: [
                MapPlacedElementBehavior(
                    trigger: MapPlacedElementTriggerType.onBump,
                    effect: MapPlacedElementEffect(
                        type: MapPlacedElementEffectType.showMessage,
                        message: 'Message')),
              ]),
        ]));
    expect(
        stepGameplayWorld(
            world, const MoveIntent(Direction.east, pixelsPerStep: 1)),
        isA<PlacedElementInteracted>());
  });

  test('interaction does not become a bump', () {
    expect(
      stepGameplayWorld(_contactWorld(Direction.east), const InteractIntent()),
      isA<NpcInteracted>(),
    );
  });
}

GameplayWorldState _contactWorld(Direction direction) {
  final owner = MapEntity(
    id: 'npc',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 2 + direction.dx, y: 2 + direction.dy),
    npc: const MapEntityNpcData(characterId: 'character'),
    properties: const {'collision.width': '1', 'collision.height': '1'},
  );
  var world = GameplayWorldState.initial(
    map: MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 6, height: 6),
      entities: [owner],
    ),
    playerPos: const GridPos(x: 2, y: 2),
  );
  final rect = resolveEntityCollisionRectPx(
    owner,
    tileWidthPx: world.tileWidthPx,
    tileHeightPx: world.tileHeightPx,
  );
  final contact = world.playerCharacterContactRect(
    world.player.playerCollisionRectPx,
  );
  final shift = switch (direction) {
    Direction.east => rect.leftPx - contact.leftPx - contact.widthPx,
    Direction.west => rect.leftPx + rect.widthPx - contact.leftPx,
    Direction.south => rect.topPx - contact.topPx - contact.heightPx,
    Direction.north => rect.topPx + rect.heightPx - contact.topPx,
  };
  world = world.withPlayer(world.player.copyWith(
    facing: direction,
    playerPositionPx: PixelPosition(
      leftPx: world.player.playerPositionPx.leftPx +
          (direction.dx == 0 ? 0 : shift),
      topPx:
          world.player.playerPositionPx.topPx + (direction.dy == 0 ? 0 : shift),
    ),
  ));
  return world;
}

GameplayWorldState _rebuild(GameplayWorldState original, MapData map,
        {ProjectManifest? project}) =>
    GameplayWorldState.initial(
      map: map,
      playerPos: original.player.pos,
      project: project,
      tileWidth: original.tileWidthPx,
      tileHeight: original.tileHeightPx,
    ).withPlayer(original.player);

GameplayWorldState _gridWorld(Direction direction) =>
    GameplayWorldState.initial(
      map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 6, height: 6),
          entities: [
            MapEntity(
                id: 'npc',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2 + direction.dx, y: 2 + direction.dy),
                npc: const MapEntityNpcData(characterId: 'character'),
                properties: const {
                  'collision.width': '1',
                  'collision.height': '1'
                })
          ]),
      playerPos: const GridPos(x: 2, y: 2),
    );

GameplayWorldState _withMask(GameplayWorldState original, PixelPoint pixel) {
  final pixels = List<bool>.filled(256, false)
    ..[(pixel.yPx % 16) * 16 + pixel.xPx % 16] = true;
  final project =
      ProjectManifest(name: 'Project', maps: const [], tilesets: const [
    ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
  ], elements: [
    ProjectElementEntry(
        id: 'mask',
        name: 'Mask',
        tilesetId: 'tiles',
        categoryId: 'obstacle',
        frames: const [
          TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16))
        ],
        collisionProfile: ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
                widthPx: 16,
                heightPx: 16,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 16, heightPx: 16, solidPixels: pixels))))
  ]);
  return _rebuild(
      original,
      original.map.copyWith(placedElements: [
        MapPlacedElement(
            id: 'mask',
            layerId: 'objects',
            elementId: 'mask',
            pos: GridPos(x: pixel.xPx ~/ 16, y: pixel.yPx ~/ 16),
            applyCollision: true),
      ]),
      project: project);
}
