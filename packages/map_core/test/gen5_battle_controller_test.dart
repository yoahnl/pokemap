import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/controller.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';

void main() {
  Gen5NitroSequence sequence(
    List<int> durations, {
    int start = 0,
    int mode = 2,
  }) => Gen5NitroSequence(
    loopStart: start,
    playbackType: mode,
    format: 0,
    frames: durations.indexed
        .map(
          (entry) => Gen5NitroFrame(
            targetIndex: entry.$1,
            duration: entry.$2,
            marker: 0,
            transformType: 0,
            rotation: 0,
            scaleX: 4096,
            scaleY: 4096,
            translateX: 0,
            translateY: 0,
          ),
        )
        .toList(),
  );

  test('bind starts at loopStart and forward loop returns there', () {
    final controller = Gen5SequenceController(sequence([2, 1, 2], start: 1));
    expect(controller.frame.targetIndex, 1);
    controller.advance();
    expect(controller.frame.targetIndex, 2);
    controller.advance();
    controller.advance();
    expect(controller.frame.targetIndex, 1);
  });

  test('reverse playback keeps the end frame for the return turn', () {
    final controller = Gen5SequenceController(sequence([1, 1, 1], mode: 4));
    final frames = [controller.frame.targetIndex];
    for (var i = 0; i < 6; i++) {
      controller.advance();
      frames.add(controller.frame.targetIndex);
    }
    expect(frames, [0, 1, 2, 2, 1, 0, 0]);
  });

  test('skips zero duration frames and rejects empty durations', () {
    final controller = Gen5SequenceController(sequence([0, 2, 0]));
    expect(controller.frame.targetIndex, 1);
    expect(
      () => Gen5SequenceController(sequence([0, 0])),
      throwsFormatException,
    );
  });

  test('a terminal zero duration frame leaves the last visible frame', () {
    final controller = Gen5SequenceController(sequence([1, 0], mode: 1));
    controller.advance();
    expect(controller.isActive, isFalse);
    expect(controller.frame.targetIndex, 0);
  });
}
