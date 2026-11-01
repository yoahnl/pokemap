import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/timeline.dart';

void main() {
  Gen5NitroSequence sequence(int mode, {int loopStart = 1}) =>
      Gen5NitroSequence(
        loopStart: loopStart,
        playbackType: mode,
        format: 0,
        frames: [1, 2, 1].indexed
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

  test('forward playback holds or loops from loop start', () {
    expect(
      List.generate(
        8,
        (tick) => gen5FrameAtTick(sequence(1), tick).targetIndex,
      ),
      [0, 1, 1, 2, 2, 2, 2, 2],
    );
    expect(
      List.generate(
        8,
        (tick) => gen5FrameAtTick(sequence(2), tick).targetIndex,
      ),
      [0, 1, 1, 2, 1, 1, 2, 1],
    );
  });

  test('ping-pong respects the reverse pass and loop start', () {
    expect(
      List.generate(
        10,
        (tick) => gen5FrameAtTick(sequence(3), tick).targetIndex,
      ),
      [0, 1, 1, 2, 1, 1, 0, 0, 0, 0],
    );
    expect(
      List.generate(
        10,
        (tick) => gen5FrameAtTick(sequence(4), tick).targetIndex,
      ),
      [0, 1, 1, 2, 1, 1, 1, 1, 2, 1],
    );
  });

  test('negative time starts at the first frame', () {
    expect(gen5FrameAtTick(sequence(2), -5).targetIndex, 0);
  });

  test('multi-cell playback follows its own forward-only semantics', () {
    final original = sequence(3);
    final timeline = Gen5NitroSequence(
      loopStart: original.loopStart,
      playbackType: original.playbackType,
      format: original.format,
      frames: original.frames,
      isMultiCellTimeline: true,
    );
    expect(
      List.generate(8, (tick) => gen5FrameAtTick(timeline, tick).targetIndex),
      [0, 1, 1, 2, 2, 2, 2, 2],
    );
  });
}
