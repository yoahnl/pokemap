import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_geometry.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  test('projects the captured node with the independently located camera', () {
    final camera = <int>[
      3952,
      -239,
      1047,
      0,
      0,
      3992,
      913,
      0,
      -1074,
      -881,
      3853,
      0,
      -14393,
      -9335,
      -81470,
      4096,
    ].map((v) => v / 4096).toList();
    final projection = <int>[
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
    ].map((v) => v / 4096).toList();
    final combined = List<double>.generate(16, (i) {
      final row = i ~/ 4;
      final column = i % 4;
      var value = 0.0;
      for (var k = 0; k < 4; k++) {
        value += camera[row * 4 + k] * projection[k * 4 + column];
      }
      return value;
    });
    final anchor = gen5McssProjectAnchor([
      1229 / 4096,
      1638 / 4096,
      -10,
    ], combined);
    const node = Gen5ActiveNode(
      record: Gen5NmcrRecord(14, -5, -16, 0),
      localFrame: Gen5NitroFrame(
        targetIndex: 18,
        duration: 6,
        marker: 0,
        transformType: 1,
        rotation: 60075,
        scaleX: 4096,
        scaleY: 4096,
        translateX: -4,
        translateY: -8,
      ),
      parentFrame: Gen5NitroFrame(
        targetIndex: 2,
        duration: 138,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
    );
    const quad = Gen5McssQuad(-1024, 1024, 32768, 32768, 1015808, 0);
    final corners = gen5McssOrthoCorners(
      node,
      quad,
      spriteScaleX: 16,
      spriteScaleY: 16,
    );
    const capturedClip = [
      (-735, 1244),
      (-607, 946),
      (-386, 1118),
      (-514, 1416),
    ];
    for (var i = 0; i < corners.length; i++) {
      expect(anchor.x + corners[i].x, closeTo(capturedClip[i].$1 / 32, 0.45));
      expect(
        anchor.y + corners[i].y,
        closeTo(capturedClip[i].$2 * 96 / 4096, 0.45),
      );
    }
  });
}
