import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('terrainPresetSubtileOffsetsForMapCell', () {
    test('1x1 block always maps to origin', () {
      expect(
        terrainPresetSubtileOffsetsForMapCell(
          42,
          -7,
          frameWidthTiles: 1,
          frameHeightTiles: 1,
        ),
        (0, 0),
      );
    });

    test('tessellates in row-major order for a 2x2 block', () {
      expect(
        terrainPresetSubtileOffsetsForMapCell(0, 0, frameWidthTiles: 2, frameHeightTiles: 2),
        (0, 0),
      );
      expect(
        terrainPresetSubtileOffsetsForMapCell(1, 0, frameWidthTiles: 2, frameHeightTiles: 2),
        (1, 0),
      );
      expect(
        terrainPresetSubtileOffsetsForMapCell(0, 1, frameWidthTiles: 2, frameHeightTiles: 2),
        (0, 1),
      );
      expect(
        terrainPresetSubtileOffsetsForMapCell(1, 1, frameWidthTiles: 2, frameHeightTiles: 2),
        (1, 1),
      );
      expect(
        terrainPresetSubtileOffsetsForMapCell(2, 0, frameWidthTiles: 2, frameHeightTiles: 2),
        (0, 0),
      );
      expect(
        terrainPresetSubtileOffsetsForMapCell(2, 2, frameWidthTiles: 2, frameHeightTiles: 2),
        (0, 0),
      );
    });

    test('handles negative map coordinates', () {
      expect(
        terrainPresetSubtileOffsetsForMapCell(-1, 0, frameWidthTiles: 2, frameHeightTiles: 1),
        (1, 0),
      );
      expect(
        terrainPresetSubtileOffsetsForMapCell(0, -1, frameWidthTiles: 1, frameHeightTiles: 3),
        (0, 2),
      );
    });

    test('non-positive extents clamp to 1', () {
      expect(
        terrainPresetSubtileOffsetsForMapCell(5, 9, frameWidthTiles: 0, frameHeightTiles: -2),
        (0, 0),
      );
    });
  });
}
