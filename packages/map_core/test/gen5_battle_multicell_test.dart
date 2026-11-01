import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/ncer.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  Gen5NitroFrame frame(int index, int duration) => Gen5NitroFrame(
    targetIndex: index,
    duration: duration,
    marker: 0,
    transformType: 0,
    rotation: 0,
    scaleX: 4096,
    scaleY: 4096,
    translateX: 0,
    translateY: 0,
  );
  Gen5NitroSequence sequence(List<Gen5NitroFrame> frames) => Gen5NitroSequence(
    loopStart: 0,
    playbackType: 2,
    format: 0,
    frames: frames,
  );

  Gen5MultiCellController controller(int nodeMode) => Gen5MultiCellController(
    cells: [
      for (var i = 0; i < 3; i++) Gen5NcerCell(0, [Gen5NcerObject(0, 0, i)]),
    ],
    animations: [
      sequence([frame(0, 1), frame(1, 1), frame(2, 1)]),
    ],
    maps: [
      for (var i = 0; i < 2; i++)
        Gen5NmcrMap(1, [Gen5NmcrRecord(0, 0, 0, nodeMode)]),
    ],
    timeline: sequence([frame(0, 2), frame(1, 2)]),
  );

  test('reset nodes restart on parent frame change', () {
    final c = controller(0);
    final frames = [c.parts.single.object.tileIndex];
    for (var i = 0; i < 3; i++) {
      c.advance();
      frames.add(c.parts.single.object.tileIndex);
    }
    expect(frames, [0, 1, 0, 1]);
  });

  test('continue nodes restore elapsed child time on parent change', () {
    final c = controller(1);
    final frames = [c.parts.single.object.tileIndex];
    for (var i = 0; i < 3; i++) {
      c.advance();
      frames.add(c.parts.single.object.tileIndex);
    }
    expect(frames, [0, 1, 2, 0]);
  });

  test('nodes sharing one slot use the first controller', () {
    final c = Gen5MultiCellController(
      cells: [
        Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 0)]),
        Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 1)]),
      ],
      animations: [
        sequence([frame(0, 2)]),
        sequence([frame(1, 2)]),
      ],
      maps: [
        const Gen5NmcrMap(1, [
          Gen5NmcrRecord(0, 0, 0, 0),
          Gen5NmcrRecord(1, 8, 0, 0),
        ]),
      ],
      timeline: sequence([frame(0, 2)]),
    );
    expect(c.parts.map((p) => p.object.tileIndex), [0, 0]);
  });

  test('ignores unreferenced invalid cells and rejects them when selected', () {
    Gen5MultiCellController build(int animationIndex) =>
        Gen5MultiCellController(
          cells: [
            Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 0)]),
          ],
          animations: [
            sequence([frame(0, 2)]),
            sequence([frame(1, 2)]),
          ],
          maps: [
            Gen5NmcrMap(1, [Gen5NmcrRecord(animationIndex, 0, 0, 0)]),
          ],
          timeline: sequence([frame(0, 2)]),
        );
    expect(build(0).parts, hasLength(1));
    expect(() => build(1).parts, throwsFormatException);
  });
}
