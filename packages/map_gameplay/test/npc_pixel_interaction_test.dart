import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final facing in Direction.values) {
    test('interaction reaches NPC after an off-grid blocked step $facing', () {
      final world = _world(facing);
      final blocked =
          stepGameplayWorld(world, MoveIntent(facing, pixelsPerStep: 32));
      expect(blocked, isA<Blocked>());
      expect((blocked as Blocked).entityBumpContact?.entityId, 'npc');
      final result = stepGameplayWorld(blocked.world, const InteractIntent());
      expect(result, isA<NpcInteracted>());
      expect((result as NpcInteracted).entity.id, 'npc');
      expect(
          result.world.player.playerPositionPx, world.player.playerPositionPx);
    });
  }

  test('an absent NPC cannot be reached through pixel contact', () {
    final world =
        _world(Direction.east).withNpcMapPresencePredicate((_, __) => false);
    expect(stepGameplayWorld(world, const InteractIntent()),
        isA<NothingToInteract>());
  });

  test('physical interaction cannot cross a narrow authored obstacle', () {
    final world = _world(Direction.east, barrier: true);
    expect(
        world.worldStaticObstaclesCollidePixelRect(
            const PixelRect(leftPx: 180, topPx: 220, widthPx: 1, heightPx: 1)),
        true);
    final bump = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 32)) as Blocked;
    expect(bump.entityBumpContact, isNull);
    expect(stepGameplayWorld(world, const InteractIntent()),
        isA<NothingToInteract>());
  });

  test('an NPC beyond a single cell of physical reach is not selected', () {
    final world = _world(Direction.east);
    final position = PixelPosition(
        leftPx: world.player.playerPositionPx.leftPx - 64,
        topPx: world.player.playerPositionPx.topPx);
    final distant = _at(world, position, Direction.east);
    expect(stepGameplayWorld(distant, const InteractIntent()),
        isA<NothingToInteract>());
  });

  test('an authored action in the facing cell keeps its priority', () {
    final original = _world(Direction.east);
    final next =
        GridPos(x: original.player.pos.x + 1, y: original.player.pos.y);
    final map = original.map.copyWith(placedElements: [
      MapPlacedElement(
          id: 'action',
          layerId: 'objects',
          elementId: 'block',
          pos: next,
          applyCollision: false,
          behaviors: const [
            MapPlacedElementBehavior(
                trigger: MapPlacedElementTriggerType.onAction,
                effect: MapPlacedElementEffect(
                    type: MapPlacedElementEffectType.showMessage,
                    message: 'Terminal'))
          ])
    ]);
    final world = GameplayWorldState.initial(
            map: map,
            playerPos: original.player.pos,
            tileWidth: 32,
            tileHeight: 32)
        .withPlayer(original.player);
    expect(stepGameplayWorld(world, const InteractIntent()),
        isA<PlacedElementInteracted>());
  });
}

GameplayWorldState _at(
    GameplayWorldState world, PixelPosition position, Direction facing) {
  final rect =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: position, spriteWidthPx: 64, spriteHeightPx: 64);
  final pos = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
      playerCollisionRectPx: rect,
      tileWidthPx: 32,
      tileHeightPx: 32,
      mapWidthCells: world.map.size.width,
      mapHeightCells: world.map.size.height);
  return world.withPlayer(world.player.copyWith(
      pos: pos,
      playerPositionPx: position,
      playerSpriteWidthPx: 64,
      playerSpriteHeightPx: 64,
      facing: facing));
}

GameplayWorldState _world(Direction facing, {bool barrier = false}) {
  final (centerX, bottomY) = switch (facing) {
    Direction.north => (208, 265),
    Direction.south => (208, 183),
    Direction.east => (159, 224),
    Direction.west => (257, 224),
  };
  final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 16, height: 16),
      layers: const [
        MapLayer.object(id: 'objects', name: 'Objects')
      ],
      entities: const [
        MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 6, y: 6),
            npc: MapEntityNpcData(characterId: 'person'))
      ],
      placedElements: [
        if (barrier)
          const MapPlacedElement(
              id: 'barrier',
              layerId: 'objects',
              elementId: 'block',
              pos: GridPos(x: 5, y: 6),
              pixelOffset: PixelOffset(x: 20, y: 0),
              pixelSize: PixelSize(width: 2, height: 32),
              applyCollision: true,
              properties: {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
              })
      ]);
  final project = ProjectManifest(
      name: 'Project',
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
            id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
      ],
      elements: [
        ProjectElementEntry(
            id: 'block',
            name: 'Barrier',
            tilesetId: 'tiles',
            categoryId: 'objects',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
            ],
            collisionProfile: ElementCollisionProfile(
                collisionMask: ElementCollisionPixelMask(
                    widthPx: 32,
                    heightPx: 32,
                    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                        widthPx: 32,
                        heightPx: 32,
                        solidPixels: List<bool>.filled(1024, true)))))
      ]);
  final world = GameplayWorldState.initial(
      map: map,
      project: project,
      playerPos: const GridPos(x: 0, y: 0),
      tileWidth: 32,
      tileHeight: 32);
  return _at(
      world, PixelPosition(leftPx: centerX - 32, topPx: bottomY - 64), facing);
}
