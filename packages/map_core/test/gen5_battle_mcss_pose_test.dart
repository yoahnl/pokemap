import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_pose.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  Gen5NitroFrame frame(int index) => Gen5NitroFrame(
    targetIndex: index,
    duration: 1,
    marker: 0,
    transformType: 0,
    rotation: 0,
    scaleX: 4096,
    scaleY: 4096,
    translateX: 0,
    translateY: 0,
  );

  Gen5ActiveNode node(int index) => Gen5ActiveNode(
    record: const Gen5NmcrRecord(0, 3, 4, 0),
    localFrame: frame(index),
    parentFrame: frame(0),
  );

  test(
    'retains both quads and their active node without imposing draw order',
    () {
      const first = Gen5McssQuad(1, 2, 3, 4, 5, 6);
      const second = Gen5McssQuad(7, 8, 9, 10, 11, 12);
      final active = node(0);
      final resolved = resolveGen5McssNodes(
        [active],
        [const Gen5McssCell(first, second)],
      );
      expect(resolved.single.node, same(active));
      expect(resolved.single.cell.primary, same(first));
      expect(resolved.single.cell.secondary, same(second));
    },
  );

  test('rejects an active cell outside the MCSS bank', () {
    expect(() => resolveGen5McssNodes([node(1)], []), throwsFormatException);
  });
}
