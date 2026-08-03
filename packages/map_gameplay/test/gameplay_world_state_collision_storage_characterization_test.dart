import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/collision/world_collision_storage.dart';
import 'package:map_gameplay/src/gameplay_world_state.dart'
    show GameplayWorldStateCollisionStorageDiagnostics;
import 'package:test/test.dart';

void main() {
  group('GameplayWorldState collision storage', () {
    test('allocates no world-pixel chunks without an element mask', () {
      final collisions = List<bool>.filled(256 * 256, false);
      collisions[10 * 256 + 10] = true;
      final map = MapData(
        id: 'large-map',
        name: 'Large map',
        size: const GridSize(width: 256, height: 256),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: collisions,
          ),
        ],
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
            npc: MapEntityNpcData(),
            blocksMovement: true,
          ),
        ],
      );

      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
      );

      expect(world.debugAllocatedPixelMaskChunkCount, 0);
      expect(world.debugAllocatedPixelMaskWordCount, 0);
      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(10, 10), isTrue);
      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(2, 2), isTrue);
    });

    test('shares static storage when a dynamic entity moves', () {
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'entity-map',
          name: 'Entity map',
          size: const GridSize(width: 256, height: 256),
          entities: const <MapEntity>[
            MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 2),
              npc: MapEntityNpcData(),
              blocksMovement: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );
      final staticStorage = world.debugStaticCollisionStorageToken;

      final withPlayer = world.withPlayer(
        world.player.copyWith(facing: Direction.east),
      );
      final withNpcVisibility =
          world.withNpcMapPresencePredicate((_, __) => true);
      final withWorldRules =
          world.withMapEntityPresencePredicate((_, __) => true);

      final moved = world.withEntityPosition(
        'npc',
        const GridPos(x: 200, y: 200),
      );

      expect(
        identical(moved.debugStaticCollisionStorageToken, staticStorage),
        isTrue,
      );
      expect(
        identical(withPlayer.debugStaticCollisionStorageToken, staticStorage),
        isTrue,
      );
      expect(
        identical(
          withNpcVisibility.debugStaticCollisionStorageToken,
          staticStorage,
        ),
        isTrue,
      );
      expect(
        identical(
            withWorldRules.debugStaticCollisionStorageToken, staticStorage),
        isTrue,
      );
      expect(
          moved.isCellCenterBlockedLegacyForGridIndexedSystems(2, 2), isFalse);
      expect(moved.isCellCenterBlockedLegacyForGridIndexedSystems(200, 200),
          isTrue);
    });

    test('allocates packed chunks only where a collision mask has solid bits',
        () {
      final pixels = List<bool>.filled(16 * 16, false)..[15 * 16] = true;
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: pixels,
        ),
      );
      final project = ProjectManifest(
        name: 'Mask project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tiles',
            name: 'Tiles',
            relativePath: 'tiles.png',
          ),
        ],
        elementCategories: const <ProjectElementCategory>[
          ProjectElementCategory(id: 'props', name: 'Props'),
        ],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'masked',
            name: 'Masked',
            tilesetId: 'tiles',
            categoryId: 'props',
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
            ),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'mask-map',
          name: 'Mask map',
          size: const GridSize(width: 64, height: 64),
          placedElements: const <MapPlacedElement>[
            MapPlacedElement(
              id: 'masked-1',
              elementId: 'masked',
              layerId: 'objects',
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );

      expect(world.debugAllocatedPixelMaskChunkCount, 1);
      expect(world.debugAllocatedPixelMaskWordCount, 32);
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 16,
            topPx: 31,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 17,
            topPx: 31,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isFalse,
      );
    });

    test('keeps out-of-world pixels blocking', () {
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'bounds-map',
          name: 'Bounds map',
          size: const GridSize(width: 4, height: 4),
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );

      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: -1,
            topPx: 0,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
    });

    test('packs solid pixels across every 31/32 chunk boundary', () {
      final pixels = List<bool>.filled(64 * 64, false);
      for (final point in const <(int, int)>[
        (31, 31),
        (32, 31),
        (31, 32),
        (32, 32),
      ]) {
        pixels[point.$2 * 64 + point.$1] = true;
      }
      final storage = _buildMaskStorage(
        worldSize: const GridSize(width: 4, height: 4),
        maskSize: const GridSize(width: 64, height: 64),
        pixels: pixels,
      );

      expect(storage.allocatedPixelMaskChunkCount, 4);
      for (final point in const <(int, int)>[
        (31, 31),
        (32, 31),
        (31, 32),
        (32, 32),
      ]) {
        expect(_isBlocked(storage, point.$1, point.$2), isTrue);
      }
      expect(_isBlocked(storage, 30, 31), isFalse);
      expect(_isBlocked(storage, 33, 32), isFalse);
    });

    test('empty and fully clipped masks allocate no chunks', () {
      final empty = _buildMaskStorage(
        worldSize: const GridSize(width: 4, height: 4),
        maskSize: const GridSize(width: 64, height: 64),
        pixels: List<bool>.filled(64 * 64, false),
      );
      final clipped = _buildMaskStorage(
        worldSize: const GridSize(width: 4, height: 4),
        maskSize: const GridSize(width: 1, height: 1),
        pixels: const <bool>[true],
        leftPx: 80,
        topPx: 80,
      );

      expect(empty.allocatedPixelMaskChunkCount, 0);
      expect(clipped.allocatedPixelMaskChunkCount, 0);
      expect(
        empty.collidesPixelRect(
          const PixelRect(leftPx: 0, topPx: 0, widthPx: 0, heightPx: 0),
          isDynamicCellBlocked: (_) => false,
        ),
        isFalse,
      );
    });

    test('copies mutable cell inputs before sharing immutable storage', () {
      final tileCells = List<bool>.filled(4, false);
      final placedCells = List<bool>.filled(4, false);
      final builder = WorldCollisionStorageBuilder(
        widthCells: 2,
        heightCells: 2,
        tileWidthPx: 16,
        tileHeightPx: 16,
        tileCollisionCells: tileCells,
        placedElementCollisionCells: placedCells,
      );
      final storage = builder.build();

      tileCells[0] = true;
      placedCells[1] = true;

      expect(_isBlocked(storage, 8, 8), isFalse);
      expect(_isBlocked(storage, 24, 8), isFalse);
    });
  });
}

WorldCollisionStorage _buildMaskStorage({
  required GridSize worldSize,
  required GridSize maskSize,
  required List<bool> pixels,
  int leftPx = 0,
  int topPx = 0,
}) {
  final builder = WorldCollisionStorageBuilder(
    widthCells: worldSize.width,
    heightCells: worldSize.height,
    tileWidthPx: 16,
    tileHeightPx: 16,
    tileCollisionCells: List<bool>.filled(
      worldSize.width * worldSize.height,
      false,
    ),
    placedElementCollisionCells: List<bool>.filled(
      worldSize.width * worldSize.height,
      false,
    ),
  );
  final mask = ElementCollisionPixelMask(
    widthPx: maskSize.width,
    heightPx: maskSize.height,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: maskSize.width,
      heightPx: maskSize.height,
      solidPixels: pixels,
    ),
  );
  builder.stampPackedMask(
    leftPx: leftPx,
    topPx: topPx,
    mask: mask,
    transform: QuarterTurnPixelTransform(
      sourcePixelSize: maskSize,
      destinationPixelSize: maskSize,
      quarterTurns: 0,
    ),
  );
  return builder.build();
}

bool _isBlocked(WorldCollisionStorage storage, int x, int y) {
  return storage.collidesPixelRect(
    PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1),
    isDynamicCellBlocked: (_) => false,
  );
}
