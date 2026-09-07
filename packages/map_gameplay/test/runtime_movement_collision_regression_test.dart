import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('runtime movement collision regression', () {
    for (final (direction, spawn, vertical) in const [
      (Direction.east, GridPos(x: 1, y: 2), true),
      (Direction.west, GridPos(x: 2, y: 2), true),
      (Direction.north, GridPos(x: 2, y: 2), false),
      (Direction.south, GridPos(x: 2, y: 1), false),
    ]) {
      test('a 32px step cannot skip a fine asset mask going $direction', () {
        final world = _worldWithThinAsset(spawn: spawn, vertical: vertical);

        final result = stepGameplayWorld(
          world,
          MoveIntent(direction, pixelsPerStep: 32),
        );

        expect(result, isA<Blocked>());
        expect(result.world.player.playerPositionPx,
            world.player.playerPositionPx);
      });
    }

    test('contact with a fine door threshold triggers its bump behavior', () {
      final world = _worldWithThinAsset(
        spawn: const GridPos(x: 1, y: 2),
        vertical: true,
        behavior: const MapPlacedElementBehavior(
          enabled: true,
          trigger: MapPlacedElementTriggerType.onBump,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.traverseWarp,
            targetMapId: 'inside',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ),
      );

      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east, pixelsPerStep: 32),
      );

      expect(result, isA<PlacedElementInteracted>());
      final interacted = result as PlacedElementInteracted;
      expect(interacted.trigger, MapPlacedElementTriggerType.onBump);
      expect(interacted.element.id, 'thin_asset');
      expect(interacted.world.player.pos, world.player.pos);
    });

    test('a 32px step beside the fine asset remains free', () {
      final world = _worldWithThinAsset(
        spawn: const GridPos(x: 1, y: 1),
        vertical: true,
      );

      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east, pixelsPerStep: 32),
      );

      expect(result, isA<Moved>());
      expect(result.world.player.pos, const GridPos(x: 2, y: 1));
    });

    test('collision cell blocks the player', () {
      final world = GameplayWorldState.initial(
        map: const MapData(
          id: 'collision_map',
          name: 'Collision Map',
          size: GridSize(width: 3, height: 1),
          layers: <MapLayer>[
            MapLayer.collision(
              id: 'collision',
              name: 'Collision',
              collisions: <bool>[false, true, false],
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('blocking entity blocks the player', () {
      final world = GameplayWorldState.initial(
        map: const MapData(
          id: 'entity_map',
          name: 'Entity Map',
          size: GridSize(width: 3, height: 1),
          entities: <MapEntity>[
            MapEntity(
              id: 'blocking_npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 0),
              blocksMovement: true,
              npc: MapEntityNpcData(),
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('placed element collision blocks the player', () {
      final world = GameplayWorldState.initial(
        map: const MapData(
          id: 'placed_map',
          name: 'Placed Map',
          size: GridSize(width: 3, height: 1),
          placedElements: <MapPlacedElement>[
            MapPlacedElement(
              id: 'rock_1',
              layerId: 'objects',
              elementId: 'rock',
              pos: GridPos(x: 1, y: 0),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: ProjectManifest(
          name: 'Placed Collision Project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'terrain',
              name: 'Terrain',
              relativePath: 'tilesets/terrain.png',
            ),
          ],
          elementCategories: <ProjectElementCategory>[
            ProjectElementCategory(id: 'obstacles', name: 'Obstacles'),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'rock',
              name: 'Rock',
              tilesetId: 'terrain',
              categoryId: 'obstacles',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: ElementCollisionProfile(
                cells: <GridPos>[GridPos(x: 0, y: 0)],
              ),
            ),
          ],
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('legacy placed element collision lookups stay cheap', () {
      const mapWidth = 120;
      const mapHeight = 80;
      final placedElements = <MapPlacedElement>[
        for (var i = 0; i < 5000; i++)
          MapPlacedElement(
            id: 'rock_$i',
            layerId: 'objects',
            elementId: 'rock',
            pos: GridPos(
              x: i % mapWidth,
              y: (i ~/ mapWidth) % mapHeight,
            ),
            applyCollision: true,
          ),
      ];
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'perf_map',
          name: 'Perf Map',
          size: const GridSize(width: mapWidth, height: mapHeight),
          placedElements: placedElements,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: ProjectManifest(
          name: 'Perf Project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'terrain',
              name: 'Terrain',
              relativePath: 'tilesets/terrain.png',
            ),
          ],
          elementCategories: <ProjectElementCategory>[
            ProjectElementCategory(id: 'obstacles', name: 'Obstacles'),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'rock',
              name: 'Rock',
              tilesetId: 'terrain',
              categoryId: 'obstacles',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: ElementCollisionProfile(
                cells: <GridPos>[GridPos(x: 0, y: 0)],
              ),
            ),
          ],
        ),
      );

      final stopwatch = Stopwatch()..start();
      var blocked = 0;
      for (var i = 0; i < 20000; i++) {
        final x = i % mapWidth;
        final y = (i ~/ mapWidth) % mapHeight;
        if (world.isBlocked(x, y)) {
          blocked += 1;
        }
      }
      stopwatch.stop();

      expect(blocked, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(1200));
    });
  });
}

GameplayWorldState _worldWithThinAsset({
  required GridPos spawn,
  required bool vertical,
  MapPlacedElementBehavior? behavior,
}) {
  final mask = ElementCollisionPixelMask(
    widthPx: 32,
    heightPx: 32,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 32,
      heightPx: 32,
      solidPixels: List<bool>.generate(
        32 * 32,
        (index) => vertical ? index % 32 == 0 : index ~/ 32 == 16,
      ),
    ),
  );
  return GameplayWorldState.initial(
    map: MapData(
      id: 'fine_collision',
      name: 'Fine Collision',
      size: const GridSize(width: 5, height: 5),
      placedElements: [
        MapPlacedElement(
          id: 'thin_asset',
          layerId: 'objects',
          elementId: 'threshold',
          pos: const GridPos(x: 2, y: 2),
          applyCollision: true,
          behaviors: [if (behavior != null) behavior],
        ),
      ],
    ),
    playerPos: spawn,
    tileWidth: 32,
    tileHeight: 32,
    project: ProjectManifest(
      name: 'Fine Collision Project',
      maps: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'terrain',
          name: 'Terrain',
          relativePath: 'tilesets/terrain.png',
        ),
      ],
      elements: [
        ProjectElementEntry(
          id: 'threshold',
          name: 'Threshold',
          tilesetId: 'terrain',
          categoryId: 'obstacles',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
          collisionProfile: ElementCollisionProfile(collisionMask: mask),
        ),
      ],
    ),
  );
}
