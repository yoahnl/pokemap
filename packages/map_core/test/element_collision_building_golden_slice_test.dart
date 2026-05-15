import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('building collision golden slice', () {
    test(
        'normalizes legacy building profile with full cells and manual silhouette',
        () {
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        cells: _legacyFullCells(),
        manualAddedCells: _buildingBlockingCells,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: _tileSize,
      );

      expect(normalized.cells, _buildingBlockingCells);
      expect(normalized.manualAddedCells, _buildingBlockingCells);
      expect(normalized.shapeCells, isEmpty);
      expect(normalized.manualRemovedCells, isEmpty);
      expect(normalized.collisionMask, isNull);
    });

    test(
        'building normalization preserves visual and occlusion masks without making them collision',
        () {
      final visualMask = _maskFromCells(
        solidCells: const [GridPos(x: 0, y: 0)],
      );
      final occlusionMask = _maskFromCells(
        solidCells: const [GridPos(x: 5, y: 0)],
      );
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        visualMask: visualMask,
        occlusionMask: occlusionMask,
        cells: _legacyFullCells(),
        manualAddedCells: _buildingBlockingCells,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: _tileSize,
      );

      expect(normalized.visualMask, same(visualMask));
      expect(normalized.occlusionMask, same(occlusionMask));
      expect(normalized.collisionMask, isNull);
      expect(normalized.cells, _buildingBlockingCells);
    });

    test('building collisionMask still wins over full legacy cells', () {
      final collisionMask = _maskFromCells(
        solidCells: const [GridPos(x: 2, y: 5)],
      );
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        collisionMask: collisionMask,
        cells: _legacyFullCells(),
        manualAddedCells: _buildingBlockingCells,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: _tileSize,
      );

      expect(normalized.collisionMask, same(collisionMask));
      expect(normalized.cells, const [GridPos(x: 2, y: 5)]);
      expect(normalized.manualAddedCells, _buildingBlockingCells);
    });
  });
}

ElementCollisionPixelMask _maskFromCells({
  required List<GridPos> solidCells,
}) {
  final pixels = List<bool>.filled(
    _buildingWidthCells * _tileSize * _buildingHeightCells * _tileSize,
    false,
  );
  final widthPx = _buildingWidthCells * _tileSize;
  final heightPx = _buildingHeightCells * _tileSize;
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

List<GridPos> _legacyFullCells() {
  return [
    for (var y = 0; y < _buildingHeightCells; y++)
      for (var x = 0; x < _buildingWidthCells; x++) GridPos(x: x, y: y),
  ];
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
