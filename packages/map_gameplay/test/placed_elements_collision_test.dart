import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

ElementCollisionPixelMask _solidTileMask16x16() {
  final maskPixels = List<bool>.filled(16 * 16, true);
  return ElementCollisionPixelMask(
    widthPx: 16,
    heightPx: 16,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 16,
      heightPx: 16,
      solidPixels: maskPixels,
    ),
  );
}

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

      expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1), isTrue);
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

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
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

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
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

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
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
              collisionMask: mask,
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
      // Le quadrant bas-gauche est plein : un pixel dedans bloque ; le centre de
      // case (8,8) dans le tile est hors de ce quadrant → pas de blocage au centre.
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: 16 + 4,
            topPx: 16 + 12,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
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
            ).copyWith(collisionMask: mask),
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
      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
      expect(
        world.movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial(
          cellX: 1,
          cellY: 1,
          movementMode: MovementMode.walk,
        ),
        isNull,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: 16 + 3,
            topPx: 16 + 0,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: 16 + 3,
            topPx: 16 + 14,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isFalse,
      );
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
                  ? ElementCollisionProfile(
                      collisionMask: _solidTileMask16x16(),
                      cells: const <GridPos>[],
                    )
                  : null,
            ),
          ]
        : const [],
  );
}
