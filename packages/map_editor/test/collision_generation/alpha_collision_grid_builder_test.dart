import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/collision_generation/alpha_collision_grid_builder.dart';
import 'package:map_editor/src/application/collision_generation/alpha_collision_params.dart';

void main() {
  group('AlphaCollisionGridBuilder', () {
    test('cellule entièrement transparente => pas de collision', () {
      final w = 4;
      final h = 2;
      final bd = ByteData(w * h * 4);
      const builder = AlphaCollisionGridBuilder();
      final cells = builder.buildCells(
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
        params: AlphaCollisionGenerationParams.defaults,
      );
      expect(cells, isEmpty);
    });

    test('cellule avec au moins un pixel opaque => collision', () {
      final w = 4;
      final h = 2;
      final bd = ByteData(w * h * 4);
      bd.setUint8(3, 255); // pixel (0,0) opaque
      const builder = AlphaCollisionGridBuilder();
      final cells = builder.buildCells(
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
        params: AlphaCollisionGenerationParams.defaults,
      );
      expect(cells, [const GridPos(x: 0, y: 0)]);
    });

    test('alpha sous le seuil => traité comme transparent', () {
      final w = 2;
      final h = 2;
      final bd = ByteData(w * h * 4);
      bd.setUint8(3, 10); // < 24
      const builder = AlphaCollisionGridBuilder();
      final cells = builder.buildCells(
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
        params: AlphaCollisionGenerationParams(
          alphaThreshold: 24,
          minimumOpaquePixelRatioPerCell: 0,
        ),
      );
      expect(cells, isEmpty);
    });

    test('sprite partiellement transparent : seules les cellules avec matière', () {
      final w = 4;
      final h = 2;
      final bd = ByteData(w * h * 4);
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 2; x++) {
          final i = (y * w + x) * 4;
          bd.setUint8(i + 3, 255);
        }
      }
      const builder = AlphaCollisionGridBuilder();
      final cells = builder.buildCells(
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
        params: AlphaCollisionGenerationParams.defaults,
      );
      expect(cells.length, 1);
      expect(cells.first.x, 0);
    });
  });
}
