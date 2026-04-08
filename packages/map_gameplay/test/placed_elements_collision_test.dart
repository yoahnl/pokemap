import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('GameplayWorldState placed element collisions', () {
    test('applyCollision=true blocks movement cell', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 1, y: 1),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      expect(world.isBlocked(1, 1), isTrue);
    });

    test('applyCollision=false does not block movement cell', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: false,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      expect(world.isBlocked(1, 1), isFalse);
    });

    test('unknown element id does not block', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'missing',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      expect(world.isBlocked(1, 1), isFalse);
    });

    test('missing collision profile does not block', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: false,
        ),
      );

      expect(world.isBlocked(1, 1), isFalse);
    });

    test('one GridPos blocks one full world cell and nothing sub-tile exists',
        () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      // Gameplay exposes collision strictly at integer cell coordinates.
      // There is no API for partial-cell collision queries because the runtime
      // cache itself is a List<bool> indexed by whole map cells.
      expect(world.isBlocked(1, 1), isTrue);
      expect(world.isBlocked(0, 1), isFalse);
      expect(world.isBlocked(1, 0), isFalse);
      expect(world.isBlocked(2, 1), isFalse);
      expect(world.isBlocked(1, 2), isFalse);
    });

    test(
        'legacy broken manual profile is migrated before gameplay reads placed element cells',
        () {
      final manifest = ProjectManifest.fromJson(
        migrateProjectManifestJson(_legacyBrokenProjectJson()),
      );
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'house::3::2',
              layerId: 'tile',
              elementId: 'petite_maison_toit_bleu',
              pos: GridPos(x: 3, y: 2),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: manifest,
      );

      // Roof area remains passable.
      expect(world.isBlocked(3, 2), isFalse);
      expect(world.isBlocked(8, 4), isFalse);

      // Base/body area blocks exactly where the authored silhouette lives.
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
    });

    test('gameplay collision uses the placed element id only', () {
      final project = ProjectManifest.fromJson(
        migrateProjectManifestJson(_legacyBrokenProjectJson()),
      ).copyWith(
        elements: [
          ...ProjectManifest.fromJson(
            migrateProjectManifestJson(_legacyBrokenProjectJson()),
          ).elements,
          ProjectElementEntry(
            id: 'other_house',
            name: 'Other house',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
            collisionProfile: const ElementCollisionProfile(
              cells: [GridPos(x: 0, y: 0)],
            ),
          ),
        ],
      );

      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'house::3::2',
              layerId: 'tile',
              elementId: 'petite_maison_toit_bleu',
              pos: GridPos(x: 3, y: 2),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );

      expect(world.isBlocked(3, 2), isFalse);
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(0, 0), isFalse);
    });

    test(
        'roof-like coarse cell set blocks the exact whole world cells it names',
        () {
      const roofCells = <GridPos>[
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 3, y: 0),
        GridPos(x: 4, y: 0),
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 3, y: 1),
        GridPos(x: 4, y: 1),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 4, y: 2),
      ];

      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'roof::3::4',
              layerId: 'tile',
              elementId: 'roof_house',
              pos: GridPos(x: 3, y: 4),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: ProjectManifest(
          name: 'project',
          maps: const [],
          tilesets: const [
            ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'cat', name: 'cat'),
          ],
          elements: const [
            ProjectElementEntry(
              id: 'roof_house',
              name: 'Roof House',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 6, height: 7),
                ),
              ],
              collisionProfile: ElementCollisionProfile(cells: roofCells),
            ),
          ],
        ),
      );

      // World-space blocking is the direct translation of GridPos to whole
      // world cells. The slope cannot survive beyond this lattice.
      expect(world.isBlocked(4, 4), isTrue);
      expect(world.isBlocked(5, 4), isTrue);
      expect(world.isBlocked(6, 4), isTrue);
      expect(world.isBlocked(7, 4), isTrue);
      expect(world.isBlocked(3, 4), isFalse);
      expect(world.isBlocked(8, 4), isFalse);
      expect(world.isBlocked(4, 3), isFalse);
      expect(world.isBlocked(4, 7), isFalse);
    });
  });
}

Map<String, dynamic> _legacyBrokenProjectJson() {
  return <String, dynamic>{
    'name': 'Legacy',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'ts',
        'name': 'ts',
        'relativePath': 'ts.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'cat', 'name': 'cat'},
    ],
    'settings': <String, dynamic>{
      'tileWidth': 16,
      'tileHeight': 16,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'ts',
        'categoryId': 'cat',
        'frames': <dynamic>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': 6,
              'height': 7,
            },
          },
        ],
        'presetKind': 'building',
        'collisionProfile': <String, dynamic>{
          'source': 'manual',
          'padding': const <String, dynamic>{
            'top': 0,
            'right': 0,
            'bottom': 0,
            'left': 0,
          },
          'shapeCells': <dynamic>[],
          'cells': <dynamic>[
            for (var y = 0; y < 7; y++)
              for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
          ],
          'manualAddedCells': const <Map<String, dynamic>>[
            {'x': 0, 'y': 3},
            {'x': 1, 'y': 3},
            {'x': 2, 'y': 3},
            {'x': 3, 'y': 3},
            {'x': 4, 'y': 3},
            {'x': 5, 'y': 3},
            {'x': 1, 'y': 4},
            {'x': 2, 'y': 4},
            {'x': 3, 'y': 4},
            {'x': 4, 'y': 4},
            {'x': 1, 'y': 5},
            {'x': 2, 'y': 5},
            {'x': 3, 'y': 5},
            {'x': 4, 'y': 5},
          ],
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

MapData _baseMap({
  required bool applyCollision,
  required String elementId,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'tile::1::1',
        layerId: 'tile',
        elementId: elementId,
        pos: const GridPos(x: 1, y: 1),
        applyCollision: applyCollision,
      ),
    ],
  );
}

ProjectManifest _project({
  required bool includeElement,
  required bool includeCollisionProfile,
}) {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'cat'),
    ],
    elements: includeElement
        ? [
            ProjectElementEntry(
              id: 'tree',
              name: 'Tree',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: includeCollisionProfile
                  ? const ElementCollisionProfile(
                      cells: [GridPos(x: 0, y: 0)],
                    )
                  : null,
            ),
          ]
        : const [],
  );
}
