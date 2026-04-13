import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/collision_generation/element_visual_occupancy_analyzer.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_collision_params.dart';

void main() {
  group('ElementVisualOccupancyAnalyzer', () {
    const analyzer = ElementVisualOccupancyAnalyzer();

    test('pixels transparents => occupation vide', () {
      final bd = ByteData(4 * 4 * 4);
      final occupancy = analyzer.analyze(
        bytesData: bd,
        imageWidth: 4,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: 4,
        srcHeight: 4,
        padding: const WarpTriggerPadding(),
        alphaThreshold: kCollisionAlphaOpaqueThreshold,
      );
      expect(occupancy.visiblePixels.any((v) => v), isFalse);
    });

    test('padding rogne bien la zone d’occupation', () {
      final w = 4;
      final h = 4;
      final bd = ByteData(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          bd.setUint8((y * w + x) * 4 + 3, 255);
        }
      }
      final occupancy = analyzer.analyze(
        bytesData: bd,
        imageWidth: w,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: w,
        srcHeight: h,
        padding: const WarpTriggerPadding(left: 1, right: 1, top: 1, bottom: 1),
        alphaThreshold: kCollisionAlphaOpaqueThreshold,
      );
      expect(occupancy.visiblePixels[0], isFalse);
      expect(occupancy.visiblePixels[1 * w + 1], isTrue);
    });
  });
}
