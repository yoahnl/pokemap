import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('runtime movement collision regression', () {
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
        project: const ProjectManifest(
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
        project: const ProjectManifest(
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
