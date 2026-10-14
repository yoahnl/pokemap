import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/border_jump_fixture.dart';

void main() {
  for (final direction in Direction.values) {
    test('a refused solid move reports the trigger frontier $direction', () {
      final world = _terrainWorld(direction);
      final result = stepGameplayWorld(
        world,
        MoveIntent(direction, pixelsPerStep: 16),
      );
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.solid);
      expect(blocked.entityBumpContact, isNull);
      expect(blocked.world.player.pos, world.player.pos);
      expect(
        blocked.world.player.playerPositionPx,
        world.player.playerPositionPx,
      );
      expect(blocked.triggerBumpContacts, hasLength(1));
      final contact = blocked.triggerBumpContacts.single;
      expect(contact.mapId, 'map');
      expect(contact.triggerId, 'exit');
      expect(contact.direction, direction);
      expect(contact.attemptedPixelsPerStep, 16);
      expect(contact.playerPos, world.player.pos);
      expect(contact.playerPositionPx, world.player.playerPositionPx);
      expect(contact.playerSpriteWidthPx, world.player.playerSpriteWidthPx);
      expect(contact.playerSpriteHeightPx, world.player.playerSpriteHeightPx);
      expect(contact.triggerArea, world.map.triggers.single.area);
      expect(
        resolvePlayerTriggerBumpContacts(
          blocked.world,
          direction,
          attemptedPixelsPerStep: 16,
        ).map((value) => value.triggerId),
        ['exit'],
      );
    });
  }

  test('a passable area remains a movement and not a trigger bump', () {
    final world = _terrainWorld(Direction.south, solid: false);
    expect(
      stepGameplayWorld(
        world,
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ),
      isA<Moved>(),
    );
    expect(
      resolvePlayerTriggerBumpContacts(
        _face(world, Direction.south),
        Direction.south,
        attemptedPixelsPerStep: 16,
      ),
      isEmpty,
    );
  });

  test(
    'the north contact uses the first ceiling pixel rather than the feet cell',
    () {
      final world = _terrainWorld(Direction.north);
      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.north, pixelsPerStep: 16),
      ) as Blocked;
      final contact = result.triggerBumpContacts.single;
      expect(
        contact.blockedPlayerCollisionRectPx.topPx,
        (contact.triggerArea.pos.y + 1) * world.tileHeightPx - 1,
      );
      expect(result.world.player.pos, const GridPos(x: 3, y: 3));
    },
  );

  test('a placed static pixel can provide the actual trigger frontier', () {
    final pixels = List<bool>.filled(256, false)..[8 * 16] = true;
    final project = ProjectManifest(
      name: 'Pixel obstacle',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'tiles',
          name: 'Tiles',
          relativePath: 'tiles.png',
        ),
      ],
      elements: [
        ProjectElementEntry(
          id: 'mask',
          name: 'Mask',
          tilesetId: 'tiles',
          categoryId: 'obstacle',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16),
            ),
          ],
          collisionProfile: ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
              widthPx: 16,
              heightPx: 16,
              dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                widthPx: 16,
                heightPx: 16,
                solidPixels: pixels,
              ),
            ),
          ),
        ),
      ],
    );
    final map = _terrainWorld(Direction.east, solid: false).map.copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'mask',
          layerId: 'objects',
          elementId: 'mask',
          pos: GridPos(x: 4, y: 3),
          applyCollision: true,
        ),
      ],
    );
    final world = GameplayWorldState.initial(
      map: map,
      project: project,
      playerPos: const GridPos(x: 3, y: 3),
    );
    final result = stepGameplayWorld(
      world,
      const MoveIntent(Direction.east, pixelsPerStep: 16),
    ) as Blocked;
    expect(result.triggerBumpContacts, hasLength(1));
    expect(result.triggerBumpContacts.single.triggerId, 'exit');
  });

  test(
    'absent NPCs keep the terrain contact and do not alter world presence',
    () {
      final original = _terrainWorld(
        Direction.south,
        entities: const [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 4),
            npc: MapEntityNpcData(characterId: 'known'),
            properties: {'collision.width': '1', 'collision.height': '1'},
          ),
        ],
      );
      final world = original.withNpcMapPresencePredicate((_, __) => false);
      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ) as Blocked;
      expect(result.triggerBumpContacts, hasLength(1));
      expect(
        world.npcMapPresencePredicate!('map', world.map.entities.single),
        isFalse,
      );
      expect(original.npcMapPresencePredicate, isNull);
      expect(world.map.entities, original.map.entities);
    },
  );

  test('a spatial or v9 map never emits native 2D trigger contact', () {
    final original = _terrainWorld(Direction.south);
    for (final map in [
      original.map.copyWith(version: ProjectVersion.v9),
      original.map.copyWith(spatialScene: MapSpatialScene(width: 8, depth: 8)),
    ]) {
      final result = stepGameplayWorld(
        _rebuild(original, map),
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ) as Blocked;
      expect(result.triggerBumpContacts, isEmpty);
    }
  });

  for (final mode in [
    'away',
    'inside',
    'custom',
    'duplicate',
    'blank',
    'outside',
  ]) {
    test('trigger contact refuses $mode references or areas', () {
      final trigger = _terrainWorld(Direction.south).map.triggers.single;
      final candidates = switch (mode) {
        'away' => [
          trigger.copyWith(
            area: const MapRect(
              pos: GridPos(x: 5, y: 4),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
        'inside' => [
          trigger.copyWith(
            area: const MapRect(
              pos: GridPos(x: 3, y: 3),
              size: GridSize(width: 1, height: 2),
            ),
          ),
        ],
        'custom' => [trigger.copyWith(type: TriggerType.custom)],
        'duplicate' => [trigger, trigger],
        'blank' => [trigger.copyWith(id: ' exit ')],
        _ => [
          trigger.copyWith(
            area: const MapRect(
              pos: GridPos(x: 3, y: 4),
              size: GridSize(width: 1, height: 5),
            ),
          ),
        ],
      };
      final result = stepGameplayWorld(
        _terrainWorld(Direction.south, triggers: candidates),
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ) as Blocked;
      expect(result.triggerBumpContacts, isEmpty);
    });
  }

  test('contacts are copied immutable and sorted by trigger identity', () {
    final trigger = _terrainWorld(Direction.south).map.triggers.single;
    final result = stepGameplayWorld(
      _terrainWorld(
        Direction.south,
        triggers: [
          trigger.copyWith(id: 'z'),
          trigger.copyWith(id: 'a'),
        ],
      ),
      const MoveIntent(Direction.south, pixelsPerStep: 16),
    ) as Blocked;
    expect(result.triggerBumpContacts.map((contact) => contact.triggerId), [
      'a',
      'z',
    ]);
    expect(() => result.triggerBumpContacts.clear(), throwsUnsupportedError);
    final input = result.triggerBumpContacts.toList();
    final copy = Blocked(result.world, triggerBumpContacts: input);
    input.clear();
    expect(copy.triggerBumpContacts, hasLength(2));
  });

  test('revalidation requires the same facing and physical frontier', () {
    final first = stepGameplayWorld(
      _terrainWorld(Direction.south),
      const MoveIntent(Direction.south, pixelsPerStep: 16),
    ) as Blocked;
    final world = first.world;
    expect(
      resolvePlayerTriggerBumpContacts(
        world,
        Direction.south,
        attemptedPixelsPerStep: 16,
      ),
      hasLength(1),
    );
    expect(
      resolvePlayerTriggerBumpContacts(
        _face(world, Direction.north),
        Direction.south,
        attemptedPixelsPerStep: 16,
      ),
      isEmpty,
    );
    final moved = _rebuild(world, world.map.copyWith(layers: []));
    expect(
      resolvePlayerTriggerBumpContacts(
        moved,
        Direction.south,
        attemptedPixelsPerStep: 16,
      ),
      isEmpty,
    );
    final changed = _rebuild(world, world.map.copyWith(triggers: []));
    expect(
      resolvePlayerTriggerBumpContacts(
        changed,
        Direction.south,
        attemptedPixelsPerStep: 16,
      ),
      isEmpty,
    );
  });

  test('invalid distances and zero movement have no trigger contacts', () {
    final world = _face(_terrainWorld(Direction.south), Direction.south);
    for (final distance in [-1, 0, 17, 32]) {
      expect(
        resolvePlayerTriggerBumpContacts(
          world,
          Direction.south,
          attemptedPixelsPerStep: distance,
        ),
        isEmpty,
      );
    }
    expect(
      (stepGameplayWorld(
        world,
        const MoveIntent(Direction.south, pixelsPerStep: 0),
      ) as Blocked).triggerBumpContacts,
      isEmpty,
    );
  });

  test('out-of-bounds movement cannot produce a trigger contact', () {
    final original = _terrainWorld(Direction.south);
    final world = GameplayWorldState.initial(
      map: original.map,
      playerPos: const GridPos(x: 3, y: 7),
    );
    final result = stepGameplayWorld(
      world,
      const MoveIntent(Direction.south, pixelsPerStep: 16),
    ) as Blocked;
    expect(result.reason, GameplayMovementBlockReason.outOfBounds);
    expect(result.triggerBumpContacts, isEmpty);
  });

  test('water blocks and water-solid mixtures do not emit terrain bumps', () {
    final original = _terrainWorld(Direction.south);
    final water = _rebuild(
      original,
      original.map.copyWith(
        gameplayZones: [
          const MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
              pos: GridPos(x: 3, y: 4),
              size: GridSize(width: 1, height: 1),
            ),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ],
      ),
    );
    for (final mode in [MovementMode.walk, MovementMode.surf]) {
      final result = stepGameplayWorld(
        water.withPlayer(water.player.copyWith(movementMode: mode)),
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ) as Blocked;
      expect(result.triggerBumpContacts, isEmpty);
    }
  });

  test(
    'an active bump warp consumes the refusal before trigger collection',
    () {
      final world = _terrainWorld(
        Direction.south,
        warps: const [
          MapWarp(
            id: 'portal',
            pos: GridPos(x: 3, y: 4),
            targetMapId: 'other',
            targetPos: GridPos(x: 1, y: 1),
            triggerMode: MapWarpTriggerMode.onBump,
          ),
        ],
      );
      expect(
        stepGameplayWorld(
          world,
          const MoveIntent(Direction.south, pixelsPerStep: 16),
        ),
        isA<WarpTriggered>(),
      );
      expect(
        resolvePlayerTriggerBumpContacts(
          _face(world, Direction.south),
          Direction.south,
          attemptedPixelsPerStep: 16,
        ),
        isEmpty,
      );
    },
  );

  test('a scene-only arrival does not intercept the terrain trigger', () {
    final world = _terrainWorld(
      Direction.south,
      warps: const [
        MapWarp(
          id: 'arrival',
          pos: GridPos(x: 3, y: 4),
          targetMapId: 'map',
          targetPos: GridPos(x: 3, y: 4),
          triggerMode: MapWarpTriggerMode.sceneOnly,
        ),
      ],
    );
    expect(
      (stepGameplayWorld(
        world,
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ) as Blocked).triggerBumpContacts,
      hasLength(1),
    );
  });

  test('a directed jump never becomes a trigger bump', () {
    final fixture = BorderJumpFixture();
    final map = fixture.map.copyWith(
      triggers: [
        MapTrigger(
          id: 'ledge',
          type: TriggerType.event,
          area: MapRect(
            pos: fixture.carrier,
            size: const GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );
    final world = fixture.world(direction: Direction.south, mapOverride: map);
    expect(
      stepGameplayWorld(world, const MoveIntent(Direction.south)),
      isA<Jumped>(),
    );
    expect(
      resolvePlayerTriggerBumpContacts(
        _face(world, Direction.south),
        Direction.south,
        attemptedPixelsPerStep: 32,
      ),
      isEmpty,
    );
  });

  test('a blocking NPC takes precedence before and with the terrain', () {
    for (final solid in [false, true]) {
      final world = _terrainWorld(
        Direction.south,
        solid: solid,
        entities: const [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 4),
            npc: MapEntityNpcData(characterId: 'known'),
            properties: {'collision.width': '1', 'collision.height': '1'},
          ),
        ],
      );
      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.south, pixelsPerStep: 16),
      ) as Blocked;
      expect(result.triggerBumpContacts, isEmpty);
      if (!solid) expect(result.entityBumpContact, isNotNull);
    }
  });

  test('a logical nonblocking exit does not mask its terrain frontier', () {
    final world = _terrainWorld(
      Direction.south,
      entities: const [
        MapEntity(
          id: 'logical-exit',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 3, y: 4),
          blocksMovement: false,
        ),
      ],
    );
    final result = stepGameplayWorld(
      world,
      const MoveIntent(Direction.south, pixelsPerStep: 16),
    ) as Blocked;
    expect(result.entityBumpContact, isNull);
    expect(result.triggerBumpContacts, hasLength(1));
  });

  for (final shift in [0, 1, -1]) {
    test(
      'a reservation at frontier offset $shift keeps the first obstacle',
      () {
        final world = _terrainWorld(Direction.south);
        final result = stepGameplayWorld(
          world,
          const MoveIntent(Direction.south, pixelsPerStep: 16),
          characterReservations: [
            PixelRect(leftPx: 56, topPx: 64 + shift, widthPx: 1, heightPx: 1),
          ],
        ) as Blocked;
        expect(result.triggerBumpContacts, shift > 0 ? hasLength(1) : isEmpty);
      },
    );
  }
}

GameplayWorldState _face(GameplayWorldState world, Direction direction) =>
    world.withPlayer(world.player.copyWith(facing: direction));

GameplayWorldState _rebuild(GameplayWorldState original, MapData map) =>
    GameplayWorldState.initial(
      map: map,
      playerPos: original.player.pos,
      tileWidth: original.tileWidthPx,
      tileHeight: original.tileHeightPx,
    ).withPlayer(original.player);

GameplayWorldState _terrainWorld(
  Direction direction, {
  bool solid = true,
  List<MapTrigger>? triggers,
  List<MapEntity> entities = const [],
  List<MapWarp> warps = const [],
}) {
  final target = GridPos(x: 3 + direction.dx, y: 3 + direction.dy);
  final collisions = List<bool>.filled(64, false);
  if (solid) collisions[target.y * 8 + target.x] = true;
  return GameplayWorldState.initial(
    map: MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      layers: [
        MapLayer.collision(id: 'solid', name: 'Solid', collisions: collisions),
      ],
      entities: entities,
      warps: warps,
      triggers:
          triggers ??
          [
            MapTrigger(
              id: 'exit',
              type: TriggerType.event,
              area: MapRect(
                pos: target,
                size: const GridSize(width: 1, height: 1),
              ),
            ),
          ],
    ),
    playerPos: const GridPos(x: 3, y: 3),
  );
}
