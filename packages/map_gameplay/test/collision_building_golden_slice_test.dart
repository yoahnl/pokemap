import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('building collision golden slice', () {
    test('normalized profile leaves roof cells passable', () {
      final world = _buildingWorld(project: _normalizedBuildingProject());

      expect(world.isBlocked(3, 2), isFalse);
      expect(world.isBlocked(8, 4), isFalse);
    });

    test('normalized profile blocks authored body cells', () {
      final world = _buildingWorld(project: _normalizedBuildingProject());

      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
      expect(world.isBlocked(4, 8), isFalse);
    });

    test('unnormalized legacy profile still over-blocks', () {
      final world = _buildingWorld(project: _legacyBuildingProject());

      expect(world.isBlocked(3, 2), isTrue);
      expect(world.isBlocked(8, 4), isTrue);
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
    });

    test('collisionMask wins over full legacy cells', () {
      final world = _buildingWorld(project: _maskBuildingProject());

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(3, 2),
        isFalse,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 3 * _tileSize + 1,
            topPx: 2 * _tileSize + 1,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isFalse,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 3 * _tileSize + 1,
            topPx: 5 * _tileSize + 1,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
    });

    test('player foot hitbox collides with body but not roof', () {
      final world = _buildingWorld(project: _normalizedBuildingProject());
      final roofHitbox = _playerHitboxInsideWorldCell(
        const GridPos(x: 3, y: 2),
      );
      final bodyHitbox = _playerHitboxInsideWorldCell(
        const GridPos(x: 3, y: 5),
      );

      expect(world.worldStaticObstaclesCollidePixelRect(roofHitbox), isFalse);
      expect(world.worldStaticObstaclesCollidePixelRect(bodyHitbox), isTrue);
      expect(
          roofHitbox.widthPx, PlayerCollisionConventionsV1.playerHitboxWidthPx);
      expect(
        roofHitbox.heightPx,
        PlayerCollisionConventionsV1.playerHitboxHeightPx,
      );
    });
  });
}

GameplayWorldState _buildingWorld({
  required ProjectManifest project,
}) {
  return GameplayWorldState.initial(
    map: _buildingMap(),
    playerPos: const GridPos(x: 0, y: 0),
    project: project,
  );
}

MapData _buildingMap() {
  return MapData(
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
  );
}

ProjectManifest _legacyBuildingProject() {
  return ProjectManifest.fromJson(
    migrateProjectManifestJson(_legacyBuildingProjectJson()),
  );
}

ProjectManifest _normalizedBuildingProject() {
  return _normalizeCollisionProfiles(_legacyBuildingProject());
}

ProjectManifest _maskBuildingProject() {
  final base = _legacyBuildingProject();
  return base.copyWith(
    elements: [
      for (final element in base.elements)
        element.copyWith(
          collisionProfile: ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            collisionMask: _maskFromCells(solidCells: _buildingBlockingCells),
            cells: _legacyFullCells(),
            manualAddedCells: _buildingBlockingCells,
          ),
        ),
    ],
  );
}

ProjectManifest _normalizeCollisionProfiles(ProjectManifest project) {
  final tileSize = project.settings.tileWidth;
  return project.copyWith(
    elements: [
      for (final element in project.elements)
        element.collisionProfile == null
            ? element
            : element.copyWith(
                collisionProfile: normalizeElementCollisionProfile(
                  element.collisionProfile!,
                  tileSize: tileSize,
                ),
              ),
    ],
  );
}

PixelRect _playerHitboxInsideWorldCell(GridPos cell) {
  const insetPx = 2;
  final targetLeft = cell.x * _tileSize + insetPx;
  final targetTop = cell.y * _tileSize + 4;
  return PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: PixelPosition(
      leftPx: targetLeft -
          (PlayerCollisionConventionsV1.defaultSpriteWidthPx -
                  PlayerCollisionConventionsV1.playerHitboxWidthPx) ~/
              2,
      topPx: targetTop -
          PlayerCollisionConventionsV1.defaultSpriteHeightPx +
          PlayerCollisionConventionsV1.playerHitboxHeightPx,
    ),
    spriteWidthPx: PlayerCollisionConventionsV1.defaultSpriteWidthPx,
    spriteHeightPx: PlayerCollisionConventionsV1.defaultSpriteHeightPx,
  );
}

ElementCollisionPixelMask _maskFromCells({
  required List<GridPos> solidCells,
}) {
  final widthPx = _buildingWidthCells * _tileSize;
  final heightPx = _buildingHeightCells * _tileSize;
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final cell in solidCells) {
    for (var y = cell.y * _tileSize; y < (cell.y + 1) * _tileSize; y++) {
      for (var x = cell.x * _tileSize; x < (cell.x + 1) * _tileSize; x++) {
        pixels[y * widthPx + x] = true;
      }
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
}

Map<String, dynamic> _legacyBuildingProjectJson() {
  return <String, dynamic>{
    'name': 'Building Golden Slice',
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
    'settings': const <String, dynamic>{
      'tileWidth': _tileSize,
      'tileHeight': _tileSize,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'ts',
        'categoryId': 'cat',
        'frames': const <Map<String, dynamic>>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': _buildingWidthCells,
              'height': _buildingHeightCells,
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
          'cells': _legacyFullCellsJson(),
          'manualAddedCells': _buildingBlockingCellsJson(),
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

List<GridPos> _legacyFullCells() {
  return [
    for (var y = 0; y < _buildingHeightCells; y++)
      for (var x = 0; x < _buildingWidthCells; x++) GridPos(x: x, y: y),
  ];
}

List<Map<String, dynamic>> _legacyFullCellsJson() {
  return _legacyFullCells()
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

List<Map<String, dynamic>> _buildingBlockingCellsJson() {
  return _buildingBlockingCells
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

const int _tileSize = 16;
const int _buildingWidthCells = 6;
const int _buildingHeightCells = 7;

const List<GridPos> _buildingBlockingCells = [
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
