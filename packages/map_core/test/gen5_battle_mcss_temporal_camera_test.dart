import 'dart:math' as math;

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_geometry.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  test('matches the rendered pose using the previous frame camera', () {
    const previousCamera = [
      3820,
      -319,
      1444,
      0,
      0,
      4000,
      884,
      0,
      -1479,
      -824,
      3730,
      0,
      -289,
      -6096,
      -88283,
      4096,
    ];
    const nextCamera = [
      3820,
      -319,
      1444,
      0,
      0,
      4000,
      884,
      0,
      -1479,
      -824,
      3730,
      0,
      -575,
      -6272,
      -88435,
      4096,
    ];
    const projection = [
      13146,
      0,
      0,
      0,
      0,
      17749,
      0,
      0,
      0,
      0,
      -4112,
      -4096,
      0,
      0,
      -8208,
      0,
    ];
    const parent = Gen5NitroFrame(
      targetIndex: 0,
      duration: 1,
      marker: 0,
      transformType: 0,
      rotation: 0,
      scaleX: 4096,
      scaleY: 4096,
      translateX: 0,
      translateY: 0,
    );
    const pose = <(int, int, int, Gen5McssQuad, List<(int, int)>)>[
      (
        7,
        -15,
        -1820,
        Gen5McssQuad(-1280, 1024, 65536, 32768, 65536, 131072),
        [(2894, 1048), (2916, 1175), (3168, 1130), (3146, 1003)],
      ),
      (
        -5,
        -16,
        0,
        Gen5McssQuad(-1024, 1024, 32768, 32768, 1015808, 0),
        [(2728, 1017), (2728, 1146), (2856, 1146), (2856, 1017)],
      ),
      (
        2,
        -11,
        0,
        Gen5McssQuad(-3072, 2816, 98304, 98304, 294912, 98304),
        [(2712, 985), (2712, 1372), (3096, 1372), (3096, 985)],
      ),
      (
        -5,
        -16,
        -1820,
        Gen5McssQuad(-2560, 1024, 65536, 32768, 0, 131072),
        [(2623, 1046), (2645, 1173), (2897, 1128), (2875, 1002)],
      ),
      (
        0,
        -26,
        0,
        Gen5McssQuad(-3072, 2304, 98304, 65536, 0, 0),
        [(2680, 775), (2680, 1033), (3064, 1033), (3064, 775)],
      ),
      (
        0,
        -26,
        0,
        Gen5McssQuad(-3840, 3072, 131072, 98304, 98304, 0),
        [(2632, 727), (2632, 1114), (3144, 1114), (3144, 727)],
      ),
      (
        5,
        -4,
        0,
        Gen5McssQuad(-1792, 1792, 65536, 65536, 294912, 0),
        [(2840, 1162), (2840, 1420), (3096, 1420), (3096, 1162)],
      ),
      (
        6,
        -7,
        0,
        Gen5McssQuad(-1024, 2304, 65536, 65536, 131072, 196608),
        [(2904, 1081), (2904, 1339), (3160, 1339), (3160, 1081)],
      ),
      (
        -2,
        -5,
        0,
        Gen5McssQuad(-2560, 1792, 65536, 65536, 229376, 0),
        [(2680, 1146), (2680, 1404), (2936, 1404), (2936, 1146)],
      ),
    ];

    double maxError(List<int> camera) {
      final combined = List<double>.generate(16, (i) {
        final row = i ~/ 4;
        final column = i % 4;
        var value = 0.0;
        for (var k = 0; k < 4; k++) {
          value += camera[row * 4 + k] * projection[k * 4 + column] / 16777216;
        }
        return value;
      });
      final anchor = gen5McssProjectAnchor([
        1229 / 4096,
        1638 / 4096,
        -10,
      ], combined);
      var error = 0.0;
      for (final (x, y, rotation, quad, captured) in pose) {
        final node = Gen5ActiveNode(
          record: Gen5NmcrRecord(0, x, y, 0),
          localFrame: Gen5NitroFrame(
            targetIndex: 0,
            duration: 1,
            marker: 0,
            transformType: 1,
            rotation: rotation,
            scaleX: 4096,
            scaleY: 4096,
            translateX: 0,
            translateY: 0,
          ),
          parentFrame: parent,
        );
        final corners = gen5McssOrthoCorners(
          node,
          quad,
          spriteScaleX: 16,
          spriteScaleY: 16,
        );
        for (var i = 0; i < corners.length; i++) {
          error = math.max(
            error,
            (128 + anchor.x + corners[i].x - captured[i].$1 / 16).abs(),
          );
          error = math.max(
            error,
            (96 - anchor.y - corners[i].y - captured[i].$2 / 16).abs(),
          );
        }
      }
      return error;
    }

    expect(maxError(previousCamera), lessThan(0.41));
    expect(maxError(nextCamera), greaterThan(0.8));
  });
}
