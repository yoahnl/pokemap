import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/collision_generation/element_ground_blocking_analyzer.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_collision_params.dart';

void main() {
  group('ElementGroundBlockingAnalyzer', () {
    const analyzer = ElementGroundBlockingAnalyzer();

    test('sprite entièrement transparent => aucune cellule bloquante', () {
      final bd = ByteData(4 * 4 * 4);
      final cells = analyzer.computeBlockingCells(
        bytesData: bd,
        imageWidth: 4,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: 4,
        srcHeight: 4,
        cellCountX: 2,
        cellCountY: 2,
        cellPixelWidth: 2,
        cellPixelHeight: 2,
        padding: const WarpTriggerPadding(),
        params: PlacedElementCollisionGenerationParams.defaults,
      );
      expect(cells, isEmpty);
    });

    test('masse opaque uniquement dans le haut du sprite => pas de blocage', () {
      final w = 4;
      final h = 4;
      final bd = ByteData(w * h * 4);
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 4; x++) {
          bd.setUint8((y * w + x) * 4 + 3, 255);
        }
      }
      final cells = analyzer.computeBlockingCells(
        bytesData: bd,
        imageWidth: w,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: w,
        srcHeight: h,
        cellCountX: 2,
        cellCountY: 2,
        cellPixelWidth: 2,
        cellPixelHeight: 2,
        padding: const WarpTriggerPadding(),
        params: PlacedElementCollisionGenerationParams.defaults,
      );
      expect(cells, isEmpty);
    });

    test('base basse opaque (tronc) => cellules du bas bloquantes', () {
      final w = 4;
      final h = 4;
      final bd = ByteData(w * h * 4);
      for (var y = 2; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          bd.setUint8((y * w + x) * 4 + 3, 255);
        }
      }
      final cells = analyzer.computeBlockingCells(
        bytesData: bd,
        imageWidth: w,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: w,
        srcHeight: h,
        cellCountX: 2,
        cellCountY: 2,
        cellPixelWidth: 2,
        cellPixelHeight: 2,
        padding: const WarpTriggerPadding(),
        params: PlacedElementCollisionGenerationParams.defaults,
      );
      expect(cells, isNotEmpty);
      expect(cells.every((c) => c.y >= 1), isTrue);
    });

    test(
        'opaque uniquement dans la moitié haute d’une cellule : pas de blocage',
        () {
      final w = 2;
      final h = 2;
      final bd = ByteData(w * h * 4);
      bd.setUint8(3, 255);
      final cells = analyzer.computeBlockingCells(
        bytesData: bd,
        imageWidth: w,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: w,
        srcHeight: h,
        cellCountX: 1,
        cellCountY: 1,
        cellPixelWidth: 2,
        cellPixelHeight: 2,
        padding: const WarpTriggerPadding(),
        params: const PlacedElementCollisionGenerationParams(
          spriteGameplayBandBottomFraction: 1.0,
          cellGroundFootprintFraction: 0.5,
          minimumOpaqueRatioInGroundSample: 0,
        ),
      );
      expect(cells, isEmpty);
    });

    test('lit / meuble : base pleine, ratio mini respecté', () {
      final w = 4;
      final h = 2;
      final bd = ByteData(w * h * 4);
      for (var y = 1; y < 2; y++) {
        for (var x = 0; x < 4; x++) {
          bd.setUint8((y * w + x) * 4 + 3, 255);
        }
      }
      final cells = analyzer.computeBlockingCells(
        bytesData: bd,
        imageWidth: w,
        srcLeft: 0,
        srcTop: 0,
        srcWidth: w,
        srcHeight: h,
        cellCountX: 2,
        cellCountY: 1,
        cellPixelWidth: 2,
        cellPixelHeight: 2,
        padding: const WarpTriggerPadding(),
        params: PlacedElementCollisionGenerationParams.defaults,
      );
      expect(cells.length, greaterThanOrEqualTo(1));
    });
  });
}
