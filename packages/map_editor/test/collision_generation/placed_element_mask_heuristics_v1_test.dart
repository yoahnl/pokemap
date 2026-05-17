import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_mask_heuristics_v1.dart';

void main() {
  group('PlacedElementMaskHeuristicsV1', () {
    test('removes sparse bottom shadow rows from collision only', () {
      final visual = List<bool>.filled(4 * 4, false);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 4; x++) {
          visual[_idx(x, y)] = true;
        }
      }
      visual[_idx(0, 3)] = true;

      final derived = PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(
        visualOpaque: visual,
        widthPx: 4,
        heightPx: 4,
      );

      expect(derived.collision[_idx(0, 3)], isFalse);
      expect(derived.collision.where((solid) => solid), hasLength(12));
      expect(derived.occlusion[_idx(0, 0)], isTrue);
      expect(derived.occlusion[_idx(0, 1)], isFalse);
    });

    test('empty visual occupancy creates no collision or occlusion', () {
      final derived = PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(
        visualOpaque: List<bool>.filled(9, false),
        widthPx: 3,
        heightPx: 3,
      );

      expect(derived.collision.any((solid) => solid), isFalse);
      expect(derived.occlusion.any((solid) => solid), isFalse);
    });
  });
}

int _idx(int x, int y) => y * 4 + x;
