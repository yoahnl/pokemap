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

    test('pixelMask is used as source-of-truth when provided', () {
      final maskPixels = List<bool>.filled(16 * 16, false);
      // Active uniquement le quadrant bas-gauche du tile 16x16.
      for (var y = 8; y < 16; y++) {
        for (var x = 0; x < 8; x++) {
          maskPixels[y * 16 + x] = true;
        }
      }
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: maskPixels,
        ),
      );
      final project = ProjectManifest(
        name: 'project',
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'cat', name: 'cat'),
        ],
        elements: [
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
            collisionProfile: ElementCollisionProfile(
              pixelMask: mask,
              // On met volontairement `cells` vide: le test valide que le
              // gameplay dérive bien la collision depuis le masque.
              cells: const <GridPos>[],
            ),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 1, y: 1),
        project: project,
      );
      expect(world.isBlocked(1, 1), isTrue);
    });

    test('pixelMask ignore le haut décoratif pour le blocage déplacement', () {
      final maskPixels = List<bool>.filled(16 * 16, false);
      // Pixels opaques uniquement sur la ligne haute.
      for (var x = 0; x < 16; x++) {
        maskPixels[x] = true; // y=0
      }
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: maskPixels,
        ),
      );
      final project = ProjectManifest(
        name: 'project',
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'cat', name: 'cat'),
        ],
        elements: [
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
            collisionProfile: const ElementCollisionProfile(
              // `cells` volontairement bloquante: doit être ignorée car un
              // `pixelMask` valide existe.
              cells: [GridPos(x: 0, y: 0)],
            ).copyWith(pixelMask: mask),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );
      expect(world.isBlocked(1, 1), isFalse);
      expect(
        world.movementBlockReasonAt(
          x: 1,
          y: 1,
          movementMode: MovementMode.walk,
        ),
        isNull,
      );
      expect(world.isPixelBlocked(16 + 3, 16 + 0), isTrue);
      expect(world.isPixelBlocked(16 + 3, 16 + 14), isFalse);
    });
  });
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
