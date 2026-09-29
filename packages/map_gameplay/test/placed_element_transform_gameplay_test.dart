import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/collision/world_collision_storage.dart';
import 'package:test/test.dart';

const _instance = MapPlacedElement(
  id: 'placed',
  layerId: 'decor',
  elementId: 'object',
  pos: GridPos(x: 2, y: 2),
  properties: {pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored},
);

void main() {
  test('rectangle stamping clips before allocating across chunk boundaries',
      () {
    final builder = WorldCollisionStorageBuilder(
        widthCells: 5,
        heightCells: 4,
        tileWidthPx: 16,
        tileHeightPx: 32,
        tileCollisionCells: const [],
        placedElementCollisionCells: const []);
    builder.stampRect(const PixelRect(
        leftPx: 9007199254740000,
        topPx: 0,
        widthPx: 9007199254740000,
        heightPx: 1));
    expect(builder.build().allocatedPixelMaskChunkCount, 0);
    builder.stampRect(
        const PixelRect(leftPx: -2, topPx: 31, widthPx: 36, heightPx: 3));
    final storage = builder.build();
    expect(storage.allocatedPixelMaskChunkCount, 4);
    for (var y = 0; y < 128; y++) {
      for (var x = 0; x < 80; x++) {
        expect(
            storage.collidesPixelRect(
                PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1),
                isDynamicCellBlocked: (_) => false),
            x < 34 && y >= 31 && y < 34);
      }
    }
  });

  test('side approach bumps the moved wall and leaves its old position free',
      () {
    final instance = _instance.copyWith(
        pos: const GridPos(x: 1, y: 2),
        pixelOffset: const PixelOffset(x: 15, y: 0),
        pixelSize: const PixelSize(width: 2, height: 32),
        behaviors: const [
          MapPlacedElementBehavior(
              trigger: MapPlacedElementTriggerType.onBump,
              effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'wall'))
        ]);
    final element = _element(const ElementCollisionProfile(
        cells: [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)]));
    final world =
        _world(instance, element, playerPos: const GridPos(x: 0, y: 2));
    final approach = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 16));
    expect(approach, isA<Moved>());
    final contact = stepGameplayWorld(
        approach.world, const MoveIntent(Direction.east, pixelsPerStep: 16));
    expect(contact, isA<PlacedElementInteracted>());
    expect((contact as PlacedElementInteracted).trigger,
        MapPlacedElementTriggerType.onBump);
    expect(contact.element.id, instance.id);
  });

  for (var q = 0; q < 4; q++) {
    test('translation preserves every native mask pixel at rotation $q', () {
      final pixels = List<bool>.generate(11 * 7, (i) => i % 7 == 0 || i == 45);
      final element = _element(ElementCollisionProfile(
          collisionMask: ElementCollisionPixelMask(
              widthPx: 11,
              heightPx: 7,
              dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                  widthPx: 11, heightPx: 7, solidPixels: pixels))));
      final native = _world(_instance.copyWith(quarterTurns: q), element);
      final shifted = _world(
          _instance.copyWith(
              quarterTurns: q, pixelOffset: const PixelOffset(x: 5, y: 9)),
          element);
      final nativeSize = GridSize(
          width: q == 0 ? 11 : (q.isEven ? 32 : 16),
          height: q == 0 ? 7 : (q.isEven ? 32 : 64));
      final sampling = QuarterTurnPixelTransform(
          sourcePixelSize: const GridSize(width: 11, height: 7),
          destinationPixelSize: nativeSize,
          quarterTurns: q);
      for (var y = 1; y < 200; y++) {
        for (var x = 1; x < 110; x++) {
          var expected = false;
          if (x >= 32 && x < 32 + nativeSize.width &&
              y >= 64 && y < 64 + nativeSize.height) {
            final source = sampling.destinationPixelToSourcePixel(
                GridPos(x: x - 32, y: y - 64));
            expected = pixels[source.y * 11 + source.x];
          }
          expect(_blocked(native, x, y), expected);
          expect(_blocked(shifted, x + 5, y + 9), expected,
              reason: 'q$q ($x,$y)');
        }
      }
    });
  }

  test('downscaling retains a one pixel wall', () {
    final pixels = List<bool>.generate(32 * 32, (i) => i % 32 == 1);
    final element = _element(ElementCollisionProfile(
        collisionMask: ElementCollisionPixelMask(
            widthPx: 32,
            heightPx: 32,
            dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                widthPx: 32, heightPx: 32, solidPixels: pixels))));
    final world = _world(
        _instance.copyWith(pixelSize: const PixelSize(width: 1, height: 3)),
        element);
    expect(_blocked(world, 32, 64), isTrue);
    expect(_blocked(world, 32, 66), isTrue);
    expect(_blocked(world, 33, 64), isFalse);
    expect(_blocked(world, 32, 67), isFalse);
  });

  test('resized cell profiles release the old spot and respect applyCollision',
      () {
    final element =
        _element(const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]));
    final instance = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 8, y: 4),
        pixelSize: const PixelSize(width: 64, height: 16));
    final world = _world(instance, element);
    expect(_blocked(world, 32, 64), isFalse);
    expect(_blocked(world, 40, 68), isTrue);
    expect(_blocked(world, 71, 83), isTrue);
    expect(_blocked(world, 72, 68), isFalse);
    expect(_blocked(world, 40, 84), isFalse);
    expect(
        _blocked(
            _world(instance.copyWith(applyCollision: false), element), 40, 68),
        isFalse);
  });

  test('all behavior queries use the moved resized half-open coverage', () {
    final instance = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 15, y: 31),
        pixelSize: const PixelSize(width: 2, height: 2),
        behaviors: [
          for (final trigger in MapPlacedElementTriggerType.values)
            MapPlacedElementBehavior(
                trigger: trigger,
                effect: const MapPlacedElementEffect(
                    type: MapPlacedElementEffectType.showMessage,
                    message: 'hi'))
        ]);
    final world = _world(instance, _element(null));
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final covered = x >= 2 && x < 4 && y >= 2 && y < 4;
        for (final hit in [
          world.placedElementBehaviorOnActionAt(x, y),
          world.placedElementBehaviorOnEnterAt(x, y),
          world.placedElementBehaviorOnExitAt(x, y),
          world.placedElementBehaviorOnBumpAt(x, y)
        ]) {
          expect(hit != null, covered, reason: '($x,$y)');
        }
        final near = ((x == 1 || x == 4) && y >= 2 && y < 4) ||
            ((y == 1 || y == 4) && x >= 2 && x < 4);
        expect(world.placedElementBehaviorOnNearAt(x, y) != null, near);
      }
    }
    expect(
        world.isFacingPlacedElement(
            playerPos: const GridPos(x: 4, y: 3),
            facing: Direction.west,
            element: instance),
        isTrue);
  });

  test('transformed malformed masks never fall back to cells', () {
    final world = _world(
        _instance.copyWith(pixelOffset: const PixelOffset(x: 1, y: 1)),
        _element(const ElementCollisionProfile(
            cells: [GridPos(x: 0, y: 0)],
            collisionMask: ElementCollisionPixelMask(
                widthPx: 32, heightPx: 32, dataBase64: 'AA=='))));
    expect(_blocked(world, 33, 65), isFalse);
  });

  test('transform keeps behavior priority and independent warp destination',
      () {
    const warp = MapWarp(
        id: 'door',
        pos: GridPos(x: 2, y: 2),
        targetMapId: 'interior',
        targetPos: GridPos(x: 7, y: 6));
    const behavior = MapPlacedElementBehavior(
        trigger: MapPlacedElementTriggerType.onAction,
        effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage, message: 'first'));
    final first = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 15, y: 31),
        pixelSize: const PixelSize(width: 2, height: 2),
        behaviors: const [behavior]);
    final world = GameplayWorldState.initial(
        map: MapData(
            id: 'map',
            name: 'Map',
            size: const GridSize(width: 8, height: 8),
            warps: const [
              warp
            ],
            placedElements: [
              first,
              first.copyWith(id: 'second', visualOrder: 100)
            ]),
        project: ProjectManifest(
            name: 'Project',
            maps: const [],
            tilesets: const [],
            elements: [_element(null)]),
        tileWidth: 16,
        tileHeight: 32,
        playerPos: const GridPos(x: 4, y: 3),
        playerFacing: Direction.west);
    final result = stepGameplayWorld(world, const InteractIntent());
    expect(result, isA<PlacedElementInteracted>());
    expect((result as PlacedElementInteracted).element.id, first.id);
    expect(world.warpAt(2, 2), warp);
    expect(world.warpAt(3, 3), isNull);
    expect(world.warpAt(2, 2)!.targetPos, const GridPos(x: 7, y: 6));
    expect(world.map.placedElements.map((e) => e.id), ['placed', 'second']);
  });
}

ProjectElementEntry _element(ElementCollisionProfile? profile) =>
    ProjectElementEntry(
      id: 'object',
      name: 'Object',
      tilesetId: 'ts',
      categoryId: 'decor',
      frames: const [
        TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1))
      ],
      collisionProfile: profile,
    );

GameplayWorldState _world(
  MapPlacedElement instance,
  ProjectElementEntry element, {
  GridPos playerPos = const GridPos(x: 0, y: 0),
}) =>
    GameplayWorldState.initial(
      tileWidth: 16,
      tileHeight: 32,
      map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 8, height: 8),
          placedElements: [instance]),
      project: ProjectManifest(
          name: 'Project',
          maps: const [],
          tilesets: const [],
          elements: [element],
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 32)),
      playerPos: playerPos,
    );

bool _blocked(GameplayWorldState world, int x, int y) =>
    world.worldStaticObstaclesCollidePixelRect(
        PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1));
