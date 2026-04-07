import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/collision_generation/element_ground_blocking_mask_analyzer.dart';
import 'package:map_editor/src/application/collision_generation/element_visual_occupancy_analyzer.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_collision_params.dart';

void main() {
  group('ElementGroundBlockingMaskAnalyzer', () {
    const analyzer = ElementGroundBlockingMaskAnalyzer();

    test('hauteur haute visible seulement => masque gameplay vide', () {
      const width = 4;
      const height = 4;
      final result = analyzer.analyze(
        occupancy: const ElementVisualOccupancyMask(
          widthPx: width,
          heightPx: height,
          visiblePixels: <bool>[
            true, true, true, true,
            true, true, true, true,
            false, false, false, false,
            false, false, false, false,
          ],
        ),
        tileWidth: 2,
        tileHeight: 2,
        cellCountX: 2,
        cellCountY: 2,
        params: PlacedElementCollisionGenerationParams.defaults,
      );
      expect(result.solidPixels.any((v) => v), isFalse);
    });

    test('base visible => masque gameplay actif en bas', () {
      const width = 4;
      const height = 4;
      final visible = List<bool>.filled(width * height, false);
      for (var y = 2; y < 4; y++) {
        for (var x = 0; x < width; x++) {
          visible[y * width + x] = true;
        }
      }
      final result = analyzer.analyze(
        occupancy: ElementVisualOccupancyMask(
          widthPx: width,
          heightPx: height,
          visiblePixels: visible,
        ),
        tileWidth: 2,
        tileHeight: 2,
        cellCountX: 2,
        cellCountY: 2,
        params: PlacedElementCollisionGenerationParams.defaults,
      );
      expect(result.solidPixels.any((v) => v), isTrue);
      // Une partie du haut reste non solide.
      expect(result.solidPixels[0], isFalse);
    });
  });
}
