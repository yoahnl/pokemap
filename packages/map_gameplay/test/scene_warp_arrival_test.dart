import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('ordinary arrival keeps a blocking door solid', () {
    expect(_allowed(_world()), isFalse);
  });

  test('explicit owner permits arrival exactly at its anchor without mutation',
      () {
    final world = _world();
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    expect(_allowed(world, owner: 'door'), isTrue);
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    expect(world.entityAt(2, 2)?.id, 'door');
    expect(world.npcMapPresencePredicate, isNull);
  });

  test('a second NPC at the arrival still blocks', () {
    expect(_allowed(_world(extra: [_npc('other')]), owner: 'door'), isFalse);
  });

  test('an existing NPC absence predicate is retained', () {
    final world = _world(extra: [_npc('other')])
        .withNpcMapPresencePredicate((_, entity) => entity.id != 'other');
    expect(_allowed(world, owner: 'door'), isTrue);
    expect(world.entityAt(2, 2)?.id, 'door');
  });

  test('a blocking non NPC is retained', () {
    final obstruction = MapEntity(
      id: 'obstruction',
      kind: MapEntityKind.sign,
      pos: const GridPos(x: 2, y: 2),
      size: const GridSize(width: 1, height: 1),
    );
    expect(_allowed(_world(extra: [obstruction]), owner: 'door'), isFalse);
  });

  test('a fine collision mask inside the feet remains blocking', () {
    final world = _world(maskPixel: const GridPos(x: 34, y: 44));
    expect(
        world
            .withNpcMapPresencePredicate((_, __) => false)
            .isCellCenterBlockedLegacyForGridIndexedSystems(2, 2),
        isFalse);
    expect(_allowed(world, owner: 'door'), isFalse);
  });

  test('solid collision tiles remain blocking', () {
    expect(_allowed(_world(solidTile: true), owner: 'door'), isFalse);
  });

  test('water still requires surf even for the explicit owner', () {
    final world = _world(water: true);
    expect(_allowed(world, owner: 'door'), isFalse);
    expect(
        _allowed(
            world.withPlayer(
                world.player.copyWith(movementMode: MovementMode.surf)),
            owner: 'door'),
        isTrue);
  });

  test('a player footprint outside map bounds is never admitted', () {
    final world = _world();
    final shifted = world.withPlayer(world.player.copyWith(
      playerPositionPx: const PixelPosition(leftPx: -20, topPx: -20),
    ));
    expect(_allowed(shifted, owner: 'door'), isFalse);
  });

  test('an incoherent pixel anchor is rejected', () {
    final world = _world();
    final shifted = world.withPlayer(world.player.copyWith(
      playerPositionPx: PixelPosition(
          leftPx: world.player.playerPositionPx.leftPx + 16,
          topPx: world.player.playerPositionPx.topPx),
    ));
    expect(() => _allowed(shifted, owner: 'door'), throwsStateError);
  });

  test('owner exemption applies only at the exact declared anchor', () {
    final world = _world(playerPos: const GridPos(x: 3, y: 2));
    expect(() => _allowed(world, owner: 'door'), throwsStateError);
  });

  test('missing and duplicate owners are rejected', () {
    expect(() => _allowed(_world(), owner: 'unknown'), throwsStateError);
    expect(() => _allowed(_world(extra: [_npc('door')]), owner: 'door'),
        throwsStateError);
  });

  test('owner must be an NPC with one declared Character', () {
    final wrongKind =
        _npc('door').copyWith(kind: MapEntityKind.sign, npc: null);
    expect(() => _allowed(_world(door: wrongKind), owner: 'door'),
        throwsStateError);
    final unknownCharacter = _npc('door')
        .copyWith(npc: const MapEntityNpcData(characterId: 'unknown'));
    expect(() => _allowed(_world(door: unknownCharacter), owner: 'door'),
        throwsStateError);
  });

  for (final owner in ['', ' ', ' door', 'door ']) {
    test('owner identity must be canonical: "$owner"', () {
      expect(() => _allowed(_world(), owner: owner), throwsStateError);
    });
  }
}

bool _allowed(GameplayWorldState world, {String? owner}) =>
    isSceneWarpArrivalAllowed(
        world: world,
        project: _project(),
        arrivalCollisionOwnerEntityId: owner);

MapEntity _npc(String id) => MapEntity(
      id: id,
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 2, y: 2),
      size: const GridSize(width: 1, height: 1),
      npc: const MapEntityNpcData(characterId: 'character'),
    );

ProjectManifest _project({GridPos? maskPixel}) {
  final mask = List<bool>.filled(16 * 16, false);
  if (maskPixel != null) {
    mask[(maskPixel.y % 16) * 16 + maskPixel.x % 16] = true;
  }
  return ProjectManifest(name: 'Arrival', maps: const [], tilesets: const [
    ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png'),
  ], characters: const [
    ProjectCharacterEntry(
        id: 'character', name: 'Door', tilesetId: 'tiles', frameHeight: 1),
  ], elements: [
    ProjectElementEntry(
      id: 'fine',
      name: 'Fine',
      tilesetId: 'tiles',
      categoryId: 'test',
      frames: const [
        TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16)),
      ],
      collisionProfile: ElementCollisionProfile(
          collisionMask: ElementCollisionPixelMask(
              widthPx: 16,
              heightPx: 16,
              dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                  widthPx: 16, heightPx: 16, solidPixels: mask))),
    ),
  ]);
}

GameplayWorldState _world(
    {MapEntity? door,
    List<MapEntity> extra = const [],
    GridPos? maskPixel,
    bool water = false,
    bool solidTile = false,
    GridPos playerPos = const GridPos(x: 2, y: 2)}) {
  final solids = List<bool>.filled(36, false);
  if (solidTile) solids[2 * 6 + 2] = true;
  final map = MapData(
    id: 'map',
    name: 'Arrival',
    size: const GridSize(width: 6, height: 6),
    layers: [
      MapLayer.collision(id: 'collision', name: 'Collision', collisions: solids)
    ],
    entities: [door ?? _npc('door'), ...extra],
    placedElements: maskPixel == null
        ? const []
        : [
            MapPlacedElement(
                id: 'fine',
                layerId: 'objects',
                elementId: 'fine',
                pos: GridPos(x: maskPixel.x ~/ 16, y: maskPixel.y ~/ 16),
                applyCollision: true),
          ],
    gameplayZones: water
        ? const [
            MapGameplayZone(
                id: 'water',
                kind: GameplayZoneKind.movement,
                area: MapRect(
                    pos: GridPos(x: 2, y: 2),
                    size: GridSize(width: 1, height: 1)),
                movement: MovementZonePayload(requiredMode: MovementMode.surf)),
          ]
        : const [],
  );
  return GameplayWorldState.initial(
      map: map, project: _project(maskPixel: maskPixel), playerPos: playerPos);
}
