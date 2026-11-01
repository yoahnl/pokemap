import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/envelope.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/ncer.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  Gen5NitroFrame frame(int index, {int x = 0, int rotation = 0}) =>
      Gen5NitroFrame(
        targetIndex: index,
        duration: 1,
        marker: 0,
        transformType: 1,
        rotation: rotation,
        scaleX: 4096,
        scaleY: 4096,
        translateX: x,
        translateY: 0,
      );
  Gen5NitroSequence sequence(List<Gen5NitroFrame> frames) => Gen5NitroSequence(
    loopStart: 0,
    playbackType: 2,
    format: 1,
    frames: frames,
  );

  test('covers every combination of parent and child poses', () {
    final envelope = gen5AnimationEnvelope(
      cells: [
        Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 0)]),
      ],
      animations: [
        sequence([frame(0), frame(0, x: 4)]),
      ],
      maps: [
        const Gen5NmcrMap(1, [Gen5NmcrRecord(0, 0, 0, 0)]),
      ],
      timeline: sequence([frame(0), frame(0, x: 20)]),
    );
    expect(envelope.left, 0);
    expect(envelope.top, 0);
    expect(envelope.right, 32);
    expect(envelope.bottom, 8);
  });

  test('bounds rotated corners and rejects excessive work', () {
    final cells = [
      Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 0)]),
    ];
    final animations = [
      sequence([frame(0, rotation: 16384)]),
    ];
    final maps = [
      const Gen5NmcrMap(1, [Gen5NmcrRecord(0, 0, 0, 0)]),
    ];
    final timeline = sequence([frame(0)]);
    final envelope = gen5AnimationEnvelope(
      cells: cells,
      animations: animations,
      maps: maps,
      timeline: timeline,
    );
    expect(envelope.left, closeTo(-8, 1e-10));
    expect(envelope.right, closeTo(0, 1e-10));
    expect(envelope.bottom, closeTo(8, 1e-10));
    expect(
      () => gen5AnimationEnvelope(
        cells: cells,
        animations: animations,
        maps: maps,
        timeline: timeline,
        maxWork: 0,
      ),
      throwsFormatException,
    );
  });
}
