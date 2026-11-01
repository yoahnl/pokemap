import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_geometry.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  test(
    'captured nodes form one coherent pose relative to an inferred anchor',
    () {
      const offsets = [
        (-5, -16),
        (2, -11),
        (7, -15),
        (2, -11),
        (0, -26),
        (-5, -16),
        (5, -4),
        (6, -7),
        (-2, -5),
      ];
      const translations = [
        (-4, -8),
        (-15, -30),
        (-3, -8),
        (-3, -8),
        (-3, -8),
        (-4, -8),
        (-2, -8),
        (-3, -8),
        (-3, -8),
      ];
      const rotations = [60075, 5461, 60075, 0, 182, 60075, 0, 3640, 0];
      const data = <(int, Gen5McssQuad, List<(int, int)>)>[
        (
          0,
          Gen5McssQuad(-1024, 1024, 32768, 32768, 1015808, 0),
          [(-735, 1244), (-607, 946), (-386, 1118), (-514, 1416)],
        ),
        (
          1,
          Gen5McssQuad(-2816, 2048, 65536, 65536, 229376, 98304),
          [(-866, 2447), (-1122, 1851), (-679, 1507), (-423, 2103)],
        ),
        (
          2,
          Gen5McssQuad(-1024, 2560, 32768, 65536, 32768, 262144),
          [(-416, 1425), (-160, 829), (62, 1001), (-195, 1597)],
        ),
        (
          3,
          Gen5McssQuad(-3072, 2816, 98304, 98304, 131072, 98304),
          [(-688, 1440), (-688, 408), (80, 408), (80, 1440)],
        ),
        (
          4,
          Gen5McssQuad(-3072, 2304, 98304, 65536, 0, 0),
          [(-748, 2007), (-757, 1319), (11, 1301), (19, 1989)],
        ),
        (
          4,
          Gen5McssQuad(-3840, 3072, 131072, 98304, 360448, 0),
          [(-842, 2138), (-855, 1106), (168, 1083), (181, 2114)],
        ),
        (
          5,
          Gen5McssQuad(-1536, 2560, 32768, 65536, 0, 262144),
          [(-887, 1425), (-631, 829), (-409, 1001), (-666, 1597)],
        ),
        (
          6,
          Gen5McssQuad(-1792, 1792, 65536, 65536, 294912, 0),
          [(-400, 967), (-400, 279), (112, 279), (112, 967)],
        ),
        (
          7,
          Gen5McssQuad(-1024, 2304, 65536, 65536, 131072, 196608),
          [(-199, 1217), (-374, 570), (107, 335), (282, 982)],
        ),
        (
          8,
          Gen5McssQuad(-2560, 1792, 65536, 65536, 229376, 0),
          [(-752, 1010), (-752, 322), (-240, 322), (-240, 1010)],
        ),
      ];
      const parent = Gen5NitroFrame(
        targetIndex: 2,
        duration: 138,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      );
      double? anchorX;
      double? anchorY;
      for (final (i, quad, clip) in data) {
        final node = Gen5ActiveNode(
          record: Gen5NmcrRecord(0, offsets[i].$1, offsets[i].$2, 0),
          localFrame: Gen5NitroFrame(
            targetIndex: 0,
            duration: 6,
            marker: 0,
            transformType: 1,
            rotation: rotations[i],
            scaleX: 4096,
            scaleY: 4096,
            translateX: translations[i].$1,
            translateY: translations[i].$2,
          ),
          parentFrame: parent,
        );
        final corners = gen5McssOrthoCorners(
          node,
          quad,
          spriteScaleX: 16,
          spriteScaleY: 16,
        );
        for (var j = 0; j < corners.length; j++) {
          final gpuX = clip[j].$1 / 32;
          final gpuY = clip[j].$2 * 96 / 4096;
          anchorX ??= gpuX - corners[j].x;
          anchorY ??= gpuY - corners[j].y;
          expect(corners[j].x + anchorX, closeTo(gpuX, 0.24));
          expect(corners[j].y + anchorY, closeTo(gpuY, 0.24));
        }
      }
    },
  );
}
