import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _mapSize = GridSize(width: 9, height: 8);
const _sourceFootprint = GridSize(width: 3, height: 2);
const _origin = GridPos(x: 3, y: 2);
const _tileWidth = 4;
const _tileHeight = 3;

void main() {
  group('placed element quarter-turn gameplay geometry', () {
    test('uses exact destination footprints for every behavior trigger', () {
      const expectedSizes = <int, GridSize>{
        0: GridSize(width: 3, height: 2),
        1: GridSize(width: 2, height: 3),
        2: GridSize(width: 3, height: 2),
        3: GridSize(width: 2, height: 3),
      };

      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final instance = _placedElement(
          quarterTurns: quarterTurns,
          behaviors: _allBehaviorTriggers,
        );
        final world = _world(
          instance: instance,
          element: _element(),
        );
        final footprint = _rectCells(
          origin: _origin,
          size: expectedSizes[quarterTurns]!,
        );
        final nearRing = _cardinalRing(footprint);
        for (var y = 0; y < _mapSize.height; y++) {
          for (var x = 0; x < _mapSize.width; x++) {
            final cell = GridPos(x: x, y: y);
            final footprintActivations = <Object?>[
              world.placedElementBehaviorOnActionAt(x, y),
              world.placedElementBehaviorOnEnterAt(x, y),
              world.placedElementBehaviorOnExitAt(x, y),
              world.placedElementBehaviorOnBumpAt(x, y),
            ];
            for (final activation in footprintActivations) {
              expect(
                activation,
                footprint.contains(cell) ? isNotNull : isNull,
                reason: 'q$quarterTurns footprint behavior at ($x, $y)',
              );
            }
            expect(
              world.placedElementBehaviorOnNearAt(x, y),
              nearRing.contains(cell) ? isNotNull : isNull,
              reason: 'q$quarterTurns onNear ring at ($x, $y)',
            );
          }
        }
      }
    });

    test('rotates asymmetric legacy collision cells from source coordinates',
        () {
      final expectedLocalCells = <int, Set<GridPos>>{
        0: <GridPos>{
          const GridPos(x: 0, y: 0),
          const GridPos(x: 2, y: 0),
          const GridPos(x: 1, y: 1),
        },
        1: <GridPos>{
          const GridPos(x: 1, y: 0),
          const GridPos(x: 1, y: 2),
          const GridPos(x: 0, y: 1),
        },
        2: <GridPos>{
          const GridPos(x: 2, y: 1),
          const GridPos(x: 0, y: 1),
          const GridPos(x: 1, y: 0),
        },
        3: <GridPos>{
          const GridPos(x: 0, y: 2),
          const GridPos(x: 0, y: 0),
          const GridPos(x: 1, y: 1),
        },
      };
      const sourceCollisionCells = <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 1, y: 1),
      ];

      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final world = _world(
          instance: _placedElement(
            quarterTurns: quarterTurns,
            applyCollision: true,
          ),
          element: _element(
            collisionProfile: const ElementCollisionProfile(
              cells: sourceCollisionCells,
            ),
          ),
        );

        for (var localY = 0; localY < 3; localY++) {
          for (var localX = 0; localX < 3; localX++) {
            final local = GridPos(x: localX, y: localY);
            expect(
              world.isBlocked(_origin.x + localX, _origin.y + localY),
              expectedLocalCells[quarterTurns]!.contains(local),
              reason: 'q$quarterTurns collision cell $local',
            );
          }
        }
      }
    });

    test('samples asymmetric pixel masks into rotated world bitmap dimensions',
        () {
      final solidSourcePixels = <GridPos>{
        const GridPos(x: 0, y: 0),
        const GridPos(x: 11, y: 0),
        const GridPos(x: 2, y: 2),
        const GridPos(x: 7, y: 4),
        const GridPos(x: 10, y: 5),
      };
      final mask = _pixelMask(solidSourcePixels);
      final element = _element(
        collisionProfile: ElementCollisionProfile(
          collisionMask: mask,
          cells: const <GridPos>[],
        ),
      );

      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final instance = _placedElement(
          quarterTurns: quarterTurns,
          applyCollision: true,
        );
        final gridTransform = resolveMapPlacedElementFootprint(
          instance: instance,
          element: element,
        );
        final destinationPixelSize = GridSize(
          width: gridTransform.destinationSize.width * _tileWidth,
          height: gridTransform.destinationSize.height * _tileHeight,
        );
        final pixelTransform = QuarterTurnPixelTransform(
          sourcePixelSize: GridSize(
            width: mask.widthPx,
            height: mask.heightPx,
          ),
          destinationPixelSize: destinationPixelSize,
          quarterTurns: quarterTurns,
        );
        final world = _world(
          instance: instance,
          element: element,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
        );
        final worldLeft = _origin.x * _tileWidth;
        final worldTop = _origin.y * _tileHeight;

        for (var y = 0; y < destinationPixelSize.height; y++) {
          for (var x = 0; x < destinationPixelSize.width; x++) {
            final source = pixelTransform.destinationPixelToSourcePixel(
              GridPos(x: x, y: y),
            );
            expect(
              _pixelIsBlocked(world, worldLeft + x, worldTop + y),
              solidSourcePixels.contains(source),
              reason: 'q$quarterTurns destination pixel ($x, $y) '
                  'sampling source $source',
            );
          }
        }

        // The rotated mask owns only the destination bounding box. These
        // sentinels catch an implementation that stamps unrotated mask extents.
        expect(
          _pixelIsBlocked(
            world,
            worldLeft + destinationPixelSize.width,
            worldTop,
          ),
          isFalse,
          reason: 'q$quarterTurns right destination bound',
        );
        expect(
          _pixelIsBlocked(
            world,
            worldLeft,
            worldTop + destinationPixelSize.height,
          ),
          isFalse,
          reason: 'q$quarterTurns bottom destination bound',
        );
      }
    });

    test('q0 preserves raw legacy mask dimensions without resampling', () {
      final mask = ElementCollisionPixelMask(
        widthPx: 2,
        heightPx: 1,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 2,
          heightPx: 1,
          solidPixels: const <bool>[false, true],
        ),
      );
      final world = _world(
        instance: _placedElement(
          quarterTurns: 0,
          applyCollision: true,
        ),
        element: _element(
          collisionProfile: ElementCollisionProfile(
            collisionMask: mask,
            cells: const <GridPos>[],
          ),
        ),
      );
      final worldLeft = _origin.x * _tileWidth;
      final worldTop = _origin.y * _tileHeight;

      expect(_pixelIsBlocked(world, worldLeft, worldTop), isFalse);
      expect(_pixelIsBlocked(world, worldLeft + 1, worldTop), isTrue);
      expect(_pixelIsBlocked(world, worldLeft + 2, worldTop), isFalse);
      expect(_pixelIsBlocked(world, worldLeft + 1, worldTop + 1), isFalse);
    });

    test('clips a mostly offscreen rotated mask before sampling', () {
      final mask = ElementCollisionPixelMask(
        widthPx: 1,
        heightPx: 1,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 1,
          heightPx: 1,
          solidPixels: const <bool>[true],
        ),
      );

      late GameplayWorldState world;
      expect(
        () => world = _world(
          instance: _placedElement(
            quarterTurns: 1,
            applyCollision: true,
          ),
          element: _element(
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 50000000,
                  height: 1,
                ),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
              cells: const <GridPos>[],
            ),
          ),
        ),
        returnsNormally,
      );

      final worldLeft = _origin.x * _tileWidth;
      final worldTop = _origin.y * _tileHeight;
      expect(_pixelIsBlocked(world, worldLeft, worldTop), isTrue);
      expect(_pixelIsBlocked(world, worldLeft + 3, worldTop + 17), isTrue);
      expect(_pixelIsBlocked(world, worldLeft + 4, worldTop), isFalse);
      expect(_pixelIsBlocked(world, worldLeft, worldTop - 1), isFalse);
    });

    test('skips rotated masks whose pixel extent is not web-representable', () {
      final mask = ElementCollisionPixelMask(
        widthPx: 1,
        heightPx: 1,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 1,
          heightPx: 1,
          solidPixels: const <bool>[true],
        ),
      );

      late GameplayWorldState world;
      expect(
        () => world = _world(
          instance: _placedElement(
            quarterTurns: 2,
            applyCollision: true,
          ),
          element: _element(
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 2251799813685248,
                  height: 1,
                ),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
              cells: const <GridPos>[],
            ),
          ),
        ),
        returnsNormally,
      );
      expect(
        _pixelIsBlocked(
          world,
          _origin.x * _tileWidth,
          _origin.y * _tileHeight,
        ),
        isFalse,
      );
    });

    test('q0 ignores resolved legacy masks with non-positive dimensions', () {
      const invalidMasks = <ElementCollisionPixelMask>[
        ElementCollisionPixelMask(widthPx: 0, heightPx: 6),
        ElementCollisionPixelMask(widthPx: 12, heightPx: 0),
      ];

      for (final mask in invalidMasks) {
        late GameplayWorldState world;
        expect(
          () => world = _world(
            instance: _placedElement(
              quarterTurns: 0,
              applyCollision: true,
            ),
            element: _element(
              collisionProfile: ElementCollisionProfile(
                collisionMask: mask,
                cells: const <GridPos>[],
              ),
            ),
          ),
          returnsNormally,
          reason: '${mask.widthPx}x${mask.heightPx} legacy mask',
        );
        expect(
          _pixelIsBlocked(
            world,
            _origin.x * _tileWidth,
            _origin.y * _tileHeight,
          ),
          isFalse,
        );
      }
    });

    test('trigger scopes use the rotated destination bounds', () {
      const oncePerEnter = MapPlacedElementBehavior(
        id: 'enter_once',
        trigger: MapPlacedElementTriggerType.onEnter,
        triggerScope: MapPlacedElementTriggerScope.oncePerEnter,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'enter',
        ),
      );
      final enterWorld = _world(
        instance: _placedElement(
          quarterTurns: 1,
          behaviors: const <MapPlacedElementBehavior>[oncePerEnter],
        ),
        element: _element(),
        playerPos: const GridPos(x: 5, y: 3),
        playerFacing: Direction.west,
      );

      // (5,3) belongs only to the old 3x2 source bounds; (4,3) belongs to the
      // rotated 2x3 destination. oncePerEnter must therefore see a fresh entry.
      final enterResult = stepGameplayWorld(
        enterWorld,
        const MoveIntent(Direction.west, pixelsPerStep: _tileWidth),
      );
      expect(enterResult, isA<PlacedElementInteracted>());
      expect(
        (enterResult as PlacedElementInteracted).trigger,
        MapPlacedElementTriggerType.onEnter,
      );

      const facingOnlyNear = MapPlacedElementBehavior(
        id: 'near_facing',
        trigger: MapPlacedElementTriggerType.onNear,
        triggerScope: MapPlacedElementTriggerScope.facingOnly,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'near',
        ),
      );
      final nearInstance = _placedElement(
        quarterTurns: 1,
        behaviors: const <MapPlacedElementBehavior>[facingOnlyNear],
      );
      final nearWorld = _world(
        instance: nearInstance,
        element: _element(),
        playerPos: const GridPos(x: 6, y: 4),
        playerFacing: Direction.west,
      );

      // After the move, (5,4) is near the destination and facing west reaches
      // its bottom-right cell (4,4), which is outside the old source bounds.
      final nearResult = stepGameplayWorld(
        nearWorld,
        const MoveIntent(Direction.west, pixelsPerStep: _tileWidth),
      );
      expect(nearResult, isA<PlacedElementInteracted>());
      expect(
        (nearResult as PlacedElementInteracted).trigger,
        MapPlacedElementTriggerType.onNear,
      );
      expect(
        nearWorld.isFacingPlacedElement(
          playerPos: const GridPos(x: 5, y: 4),
          facing: Direction.west,
          element: nearInstance,
        ),
        isTrue,
      );
    });

    test('animation settings do not change rotated footprint orientation', () {
      final staticWorld = _world(
        instance: _placedElement(
          quarterTurns: 1,
          behaviors: _allBehaviorTriggers,
        ),
        element: _element(),
      );
      final animatedWorld = _world(
        instance: _placedElement(
          quarterTurns: 1,
          animation: const MapPlacedElementAnimation(
            enabled: true,
            mode: MapPlacedElementAnimationMode.pingPong,
            autoplay: true,
            speed: 1.5,
            randomStart: true,
          ),
          behaviors: _allBehaviorTriggers,
        ),
        element: _element(),
      );

      for (var y = 0; y < _mapSize.height; y++) {
        for (var x = 0; x < _mapSize.width; x++) {
          expect(
            animatedWorld.placedElementBehaviorOnActionAt(x, y) != null,
            staticWorld.placedElementBehaviorOnActionAt(x, y) != null,
            reason: 'animated footprint at ($x, $y)',
          );
        }
      }
    });

    test('missing project context or element preserves legacy 1x1 for any turn',
        () {
      const behavior = MapPlacedElementBehavior(
        id: 'legacy_action',
        trigger: MapPlacedElementTriggerType.onAction,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'legacy',
        ),
      );
      final instance = _placedElement(
        quarterTurns: 99,
        applyCollision: true,
        behaviors: const <MapPlacedElementBehavior>[behavior],
      );
      final projects = <ProjectManifest?>[
        null,
        _project(elements: const <ProjectElementEntry>[]),
      ];

      for (final project in projects) {
        final world = GameplayWorldState.initial(
          map: _map(instance),
          playerPos: const GridPos(x: 0, y: 0),
          project: project,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
        );

        expect(
          world.placedElementBehaviorOnActionAt(_origin.x, _origin.y),
          isNotNull,
        );
        expect(
          world.placedElementBehaviorOnActionAt(_origin.x + 1, _origin.y),
          isNull,
        );
        expect(
          world.placedElementBehaviorOnActionAt(_origin.x, _origin.y + 1),
          isNull,
        );
        expect(
          world.isFacingPlacedElement(
            playerPos: GridPos(x: _origin.x - 1, y: _origin.y),
            facing: Direction.east,
            element: instance,
          ),
          isTrue,
        );
      }
    });
  });
}

const _allBehaviorTriggers = <MapPlacedElementBehavior>[
  MapPlacedElementBehavior(
    id: 'action',
    trigger: MapPlacedElementTriggerType.onAction,
    effect: MapPlacedElementEffect(
      type: MapPlacedElementEffectType.showMessage,
      message: 'action',
    ),
  ),
  MapPlacedElementBehavior(
    id: 'enter',
    trigger: MapPlacedElementTriggerType.onEnter,
    effect: MapPlacedElementEffect(
      type: MapPlacedElementEffectType.showMessage,
      message: 'enter',
    ),
  ),
  MapPlacedElementBehavior(
    id: 'exit',
    trigger: MapPlacedElementTriggerType.onExit,
    effect: MapPlacedElementEffect(
      type: MapPlacedElementEffectType.showMessage,
      message: 'exit',
    ),
  ),
  MapPlacedElementBehavior(
    id: 'bump',
    trigger: MapPlacedElementTriggerType.onBump,
    effect: MapPlacedElementEffect(
      type: MapPlacedElementEffectType.showMessage,
      message: 'bump',
    ),
  ),
  MapPlacedElementBehavior(
    id: 'near',
    trigger: MapPlacedElementTriggerType.onNear,
    effect: MapPlacedElementEffect(
      type: MapPlacedElementEffectType.showMessage,
      message: 'near',
    ),
  ),
];

GameplayWorldState _world({
  required MapPlacedElement instance,
  required ProjectElementEntry element,
  GridPos playerPos = const GridPos(x: 0, y: 0),
  Direction playerFacing = Direction.south,
  int tileWidth = _tileWidth,
  int tileHeight = _tileHeight,
}) {
  return GameplayWorldState.initial(
    map: _map(instance),
    playerPos: playerPos,
    playerFacing: playerFacing,
    project: _project(elements: <ProjectElementEntry>[element]),
    tileWidth: tileWidth,
    tileHeight: tileHeight,
  );
}

MapData _map(MapPlacedElement instance) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: _mapSize,
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tiles: List<int>.filled(
          _mapSize.width * _mapSize.height,
          0,
          growable: false,
        ),
      ),
    ],
    placedElements: <MapPlacedElement>[instance],
  );
}

MapPlacedElement _placedElement({
  required int quarterTurns,
  bool applyCollision = false,
  MapPlacedElementAnimation? animation,
  List<MapPlacedElementBehavior> behaviors = const <MapPlacedElementBehavior>[],
}) {
  return MapPlacedElement(
    id: 'rotated',
    layerId: 'ground',
    elementId: 'asymmetric',
    pos: _origin,
    quarterTurns: quarterTurns,
    applyCollision: applyCollision,
    animation: animation,
    behaviors: behaviors,
  );
}

ProjectElementEntry _element({
  ElementCollisionProfile? collisionProfile,
  List<TilesetVisualFrame> frames = const <TilesetVisualFrame>[
    TilesetVisualFrame(
      source: TilesetSourceRect(
        x: 0,
        y: 0,
        width: 3,
        height: 2,
      ),
    ),
  ],
}) {
  return ProjectElementEntry(
    id: 'asymmetric',
    name: 'Asymmetric',
    tilesetId: 'tiles',
    categoryId: 'objects',
    frames: frames,
    collisionProfile: collisionProfile,
  );
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
}) {
  return ProjectManifest(
    name: 'project',
    settings: const ProjectSettings(
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
    ),
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'objects', name: 'Objects'),
    ],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ElementCollisionPixelMask _pixelMask(Set<GridPos> solidPixels) {
  final width = _sourceFootprint.width * _tileWidth;
  final height = _sourceFootprint.height * _tileHeight;
  final pixels = List<bool>.filled(width * height, false, growable: false);
  for (final pixel in solidPixels) {
    pixels[pixel.y * width + pixel.x] = true;
  }
  return ElementCollisionPixelMask(
    widthPx: width,
    heightPx: height,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: width,
      heightPx: height,
      solidPixels: pixels,
    ),
  );
}

bool _pixelIsBlocked(GameplayWorldState world, int x, int y) {
  return world.worldStaticObstaclesCollidePixelRect(
    PixelRect(
      leftPx: x,
      topPx: y,
      widthPx: 1,
      heightPx: 1,
    ),
  );
}

Set<GridPos> _rectCells({
  required GridPos origin,
  required GridSize size,
}) {
  return <GridPos>{
    for (var y = 0; y < size.height; y++)
      for (var x = 0; x < size.width; x++)
        GridPos(x: origin.x + x, y: origin.y + y),
  };
}

Set<GridPos> _cardinalRing(Set<GridPos> footprint) {
  final ring = <GridPos>{};
  for (final cell in footprint) {
    ring
      ..add(GridPos(x: cell.x - 1, y: cell.y))
      ..add(GridPos(x: cell.x + 1, y: cell.y))
      ..add(GridPos(x: cell.x, y: cell.y - 1))
      ..add(GridPos(x: cell.x, y: cell.y + 1));
  }
  return ring
    ..removeAll(footprint)
    ..removeWhere(
      (cell) =>
          cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= _mapSize.width ||
          cell.y >= _mapSize.height,
    );
}
