import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('an initial owner permits one nonthrough move out of its contact', () {
    final fixture = _fixture(tileSize: 32);
    final world = fixture.world;
    final before = world.map.toJson();
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    expect(_move(fixture, ownerId: null), isNull);
    final plan = _move(fixture);
    expect(plan, isNotNull);
    expect(plan!.from, const GridPos(x: 13, y: 25));
    expect(plan.to, const GridPos(x: 13, y: 26));
    expect(plan.toPositionPx.topPx - plan.fromPositionPx.topPx, 32);
    expect(world.map.toJson(), before);
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
  });

  for (final direction in EntityFacing.values) {
    test('owner exemption keeps a one cell move exact $direction', () {
      final fixture = _fixture();
      final plan = _move(fixture, direction: direction)!;
      final delta = direction.asDirection;
      expect(plan.to, GridPos(x: 13 + delta.dx, y: 25 + delta.dy));
      expect(plan.toPositionPx.leftPx - plan.fromPositionPx.leftPx, delta.dx * 16);
      expect(plan.toPositionPx.topPx - plan.fromPositionPx.topPx, delta.dy * 16);
      expect(fixture.world.player.pos, plan.from);
    });
  }

  test('a larger visual envelope with contact in B is eligible', () {
    final fixture = _fixture(
      owner: _owner(
        size: const GridSize(width: 2, height: 2),
        properties: const {
          'collision.width': '1',
          'collision.height': '1',
          'collision.offsetX': '0',
          'collision.offsetY': '0',
        },
      ),
    );
    expect(_move(fixture), isNotNull);
  });

  test('the exemption retains player pixel offset and dimensions', () {
    var fixture = _fixture();
    final player = fixture.world.player;
    fixture = (
      world: fixture.world.withPlayer(player.copyWith(
        playerPositionPx: PixelPosition(
          leftPx: player.playerPositionPx.leftPx + 2,
          topPx: player.playerPositionPx.topPx - 1,
        ),
      )),
      project: fixture.project,
    );
    final plan = _move(fixture)!;
    expect(plan.toPositionPx.leftPx, fixture.world.player.playerPositionPx.leftPx);
    expect(plan.toPositionPx.topPx,
        fixture.world.player.playerPositionPx.topPx + 16);
    expect(plan.playerState!.playerSpriteWidthPx, player.playerSpriteWidthPx);
    expect(plan.playerState!.playerSpriteHeightPx, player.playerSpriteHeightPx);
  });

  for (final reverse in [false, true]) {
    test('a second occupant in B is retained in order $reverse', () {
      final fixture = _fixture(extra: [_owner(id: 'other')], reverse: reverse);
      expect(_move(fixture), isNull);
    });
  }

  for (final npcPredicate in [true, false]) {
    test('an unrelated absence predicate is preserved npc=$npcPredicate', () {
      var fixture = _fixture(extra: [_owner(id: 'hidden')]);
      final world = npcPredicate
          ? fixture.world.withNpcMapPresencePredicate(
              (_, entity) => entity.id != 'hidden',
            )
          : fixture.world.withMapEntityPresencePredicate(
              (_, entity) => entity.id != 'hidden',
            );
      fixture = (world: world, project: fixture.project);
      expect(_move(fixture), isNotNull);
      expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    });

    test('the owner must be present npc=$npcPredicate', () {
      var fixture = _fixture();
      final world = npcPredicate
          ? fixture.world.withNpcMapPresencePredicate((_, __) => false)
          : fixture.world.withMapEntityPresencePredicate((_, __) => false);
      fixture = (world: world, project: fixture.project);
      expect(() => _move(fixture), throwsStateError);
    });
  }

  test('another destination NPC remains blocking', () {
    final fixture = _fixture(extra: [
      _owner(id: 'other', pos: const GridPos(x: 13, y: 26)),
    ]);
    expect(_move(fixture), isNull);
  });

  test('a blocking non NPC remains blocking in B', () {
    final fixture = _fixture(extra: const [
      MapEntity(
          id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 13, y: 25)),
    ]);
    expect(_move(fixture), isNull);
  });

  for (final pixel in [
    const GridPos(x: 214, y: 412),
    const GridPos(x: 214, y: 420),
    const GridPos(x: 214, y: 428),
  ]) {
    test('a fine static mask is retained at $pixel', () {
      expect(_move(_fixture(pixel: pixel)), isNull);
    });
  }

  for (final cell in [
    const GridPos(x: 13, y: 25),
    const GridPos(x: 13, y: 26),
  ]) {
    test('a solid terrain tile remains blocking at $cell', () {
      expect(_move(_fixture(solidCell: cell)), isNull);
    });

    test('an anonymous dynamic cell remains blocking at $cell', () {
      expect(_move(_fixture(), dynamicBlockedCells: [cell]), isNull);
    });

    test('an anonymous character reservation remains blocking at $cell', () {
      expect(
        _move(_fixture(), characterReservations: [
          PixelRect(
              leftPx: cell.x * 16,
              topPx: cell.y * 16,
              widthPx: 16,
              heightPx: 16),
        ]),
        isNull,
      );
    });
  }

  test('water still requires the player movement mode', () {
    final fixture = _fixture(water: true);
    expect(_move(fixture), isNull);
    expect(
      _move((
        world: fixture.world.withPlayer(
          fixture.world.player.copyWith(movementMode: MovementMode.surf),
        ),
        project: fixture.project,
      )),
      isNotNull,
    );
  });

  test('bounds remain closed at the destination', () {
    expect(
      _move(_fixture(cell: const GridPos(x: 13, y: 0)),
          direction: EntityFacing.north),
      isNull,
    );
  });

  test('a final footprint still touching the owner is not admitted', () {
    var fixture = _fixture();
    final player = fixture.world.player;
    fixture = (
      world: fixture.world.withPlayer(player.copyWith(
        playerPositionPx: PixelPosition(
          leftPx: player.playerPositionPx.leftPx - 7,
          topPx: player.playerPositionPx.topPx,
        ),
      )),
      project: fixture.project,
    );
    expect(_move(fixture, direction: EntityFacing.east), isNull);
  });

  test('the exemption is not retained by the resulting world', () {
    final fixture = _fixture();
    final plan = _move(fixture)!;
    final moved = fixture.world.withPlayer(plan.playerState!);
    expect(
      _move((world: moved, project: fixture.project),
          ownerId: null, direction: EntityFacing.north),
      isNull,
    );
    expect(fixture.world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
  });

  for (final id in ['', ' ', ' door', 'door ', 'unknown']) {
    test('an invalid owner identity is an error "$id"', () {
      expect(() => _move(_fixture(), ownerId: id), throwsStateError);
    });
  }

  test('a duplicate owner identity is an error', () {
    expect(() => _move(_fixture(extra: [_owner()])), throwsStateError);
  });

  test('an owner context is required only with the option', () {
    final fixture = _fixture();
    expect(() => _move(fixture, includeProject: false), throwsStateError);
    expect(_move(fixture, includeProject: false, ownerId: null), isNull);
  });

  test('an unknown or ambiguous map context is an error', () {
    final fixture = _fixture();
    for (final maps in [
      <ProjectMapEntry>[],
      [...fixture.project.maps, ...fixture.project.maps],
    ]) {
      expect(
        () => _move(fixture, project: fixture.project.copyWith(maps: maps)),
        throwsStateError,
      );
    }
  });

  test('unknown and ambiguous owner Characters are errors', () {
    final fixture = _fixture();
    for (final characters in [
      <ProjectCharacterEntry>[],
      [...fixture.project.characters, ...fixture.project.characters],
    ]) {
      expect(
        () => _move(fixture,
            project: fixture.project.copyWith(characters: characters)),
        throwsStateError,
      );
    }
  });

  test('a non NPC owner is an error', () {
    final fixture = _fixture(owner: const MapEntity(
      id: 'door',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 13, y: 25),
    ));
    expect(() => _move(fixture), throwsStateError);
  });

  test('a contact larger than one cell is not eligible', () {
    expect(
      () => _move(_fixture(owner: _owner(
        size: const GridSize(width: 2, height: 1),
      ))),
      throwsStateError,
    );
  });

  test('an offset contact cannot substitute for the authored owner anchor', () {
    final fixture = _fixture(owner: _owner(
      pos: const GridPos(x: 12, y: 25),
      size: const GridSize(width: 2, height: 1),
      properties: const {
        'collision.width': '1',
        'collision.height': '1',
        'collision.offsetX': '1',
      },
    ));
    expect(() => _move(fixture), throwsStateError);
  });

  test('a contact outside B is rejected even with authored anchor B', () {
    expect(
      () => _move(_fixture(owner: _owner(
        size: const GridSize(width: 1, height: 2),
      ))),
      throwsStateError,
    );
  });

  test('the player must initially overlap the physical owner', () {
    var fixture = _fixture();
    final player = fixture.world.player;
    fixture = (
      world: fixture.world.withPlayer(player.copyWith(
        playerPositionPx: PixelPosition(
          leftPx: player.playerPositionPx.leftPx,
          topPx: player.playerPositionPx.topPx - 10,
        ),
      )),
      project: fixture.project,
    );
    expect(() => _move(fixture), throwsStateError);
  });

  test('through and NPC target cannot combine with the exemption', () {
    final fixture = _fixture();
    expect(() => _move(fixture, through: true), throwsStateError);
    expect(
      () => _move(fixture,
          target: SceneActorTarget.entity(mapId: 'map', entityId: 'door')),
      throwsStateError,
    );
  });
}

ActorRouteMotionPlan? _move(
  ({GameplayWorldState world, ProjectManifest project}) fixture, {
  String? ownerId = 'door',
  EntityFacing direction = EntityFacing.south,
  SceneActorTarget? target,
  bool through = false,
  ProjectManifest? project,
  bool includeProject = true,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) =>
    planActorRouteMove(
      world: fixture.world,
      target: target ?? SceneActorTarget.player(mapId: 'map'),
      direction: direction,
      through: through,
      initialCollisionOwnerEntityId: ownerId,
      project: includeProject ? project ?? fixture.project : null,
      dynamicBlockedCells: dynamicBlockedCells,
      characterReservations: characterReservations,
    );

MapEntity _owner({
  String id = 'door',
  GridPos pos = const GridPos(x: 13, y: 25),
  GridSize size = const GridSize(width: 1, height: 1),
  Map<String, String> properties = const {},
}) =>
    MapEntity(
      id: id,
      kind: MapEntityKind.npc,
      pos: pos,
      size: size,
      npc: const MapEntityNpcData(characterId: 'character'),
      properties: properties,
    );

({GameplayWorldState world, ProjectManifest project}) _fixture({
  int tileSize = 16,
  GridPos cell = const GridPos(x: 13, y: 25),
  MapEntity? owner,
  List<MapEntity> extra = const [],
  bool reverse = false,
  GridPos? pixel,
  GridPos? solidCell,
  bool water = false,
}) {
  final mask = List<bool>.filled(tileSize * tileSize, false);
  if (pixel != null) {
    mask[(pixel.y % tileSize) * tileSize + pixel.x % tileSize] = true;
  }
  final project = ProjectManifest(
    name: 'Egress',
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
    ],
    settings: ProjectSettings(tileWidth: tileSize, tileHeight: tileSize),
    tilesets: const [
      ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png'),
    ],
    characters: const [
      ProjectCharacterEntry(
          id: 'character', name: 'Door', tilesetId: 'tiles', frameHeight: 1),
    ],
    elements: [
      ProjectElementEntry(
        id: 'fine',
        name: 'Fine',
        tilesetId: 'tiles',
        categoryId: 'test',
        frames: [
          TilesetVisualFrame(
              source: TilesetSourceRect(
                  x: 0, y: 0, width: tileSize, height: tileSize)),
        ],
        collisionProfile: ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
                widthPx: tileSize,
                heightPx: tileSize,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: tileSize,
                    heightPx: tileSize,
                    solidPixels: mask))),
      ),
    ],
  );
  final solids = List<bool>.filled(30 * 85, false);
  if (solidCell != null) solids[solidCell.y * 30 + solidCell.x] = true;
  final entities = [owner ?? _owner(pos: cell), ...extra];
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 30, height: 85),
    layers: [
      MapLayer.collision(id: 'collision', name: 'Collision', collisions: solids),
    ],
    entities: reverse ? entities.reversed.toList() : entities,
    placedElements: pixel == null
        ? const []
        : [
            MapPlacedElement(
                id: 'fine',
                layerId: 'objects',
                elementId: 'fine',
                pos: GridPos(x: pixel.x ~/ tileSize, y: pixel.y ~/ tileSize),
                applyCollision: true),
          ],
    gameplayZones: water
        ? const [
            MapGameplayZone(
                id: 'water',
                kind: GameplayZoneKind.movement,
                area: MapRect(
                    pos: GridPos(x: 13, y: 26),
                    size: GridSize(width: 1, height: 1)),
                movement: MovementZonePayload(requiredMode: MovementMode.surf)),
          ]
        : const [],
  );
  return (
    world: GameplayWorldState.initial(
      map: map,
      project: project,
      playerPos: cell,
      tileWidth: tileSize,
      tileHeight: tileSize,
    ),
    project: project,
  );
}
