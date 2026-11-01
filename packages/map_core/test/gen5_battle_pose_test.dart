import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/ncer.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';
import '../../../tools/gen5_battle_sprite/pose.dart';

void main() {
  Gen5NitroFrame frame(int target, {int x = 0, int y = 0, int rotation = 0}) =>
      Gen5NitroFrame(
        targetIndex: target,
        duration: 1,
        marker: 0,
        transformType: 1,
        rotation: rotation,
        scaleX: 4096,
        scaleY: 4096,
        translateX: x,
        translateY: y,
      );

  test('composes timeline, record and part transforms in order', () {
    final cells = [
      Gen5NcerCell(0, [const Gen5NcerObject(2, 3, 0)]),
    ];
    final animations = [
      Gen5NitroSequence(
        loopStart: 0,
        playbackType: 2,
        format: 1,
        frames: [frame(0, x: 1, y: 2)],
      ),
    ];
    final maps = [
      const Gen5NmcrMap(1, [Gen5NmcrRecord(0, 10, 20, 0)]),
    ];
    final parent = Gen5NitroSequence(
      loopStart: 0,
      playbackType: 2,
      format: 1,
      frames: [frame(0, x: 4, y: 5)],
    );
    final pose = resolveGen5Pose(
      cells: cells,
      animations: animations,
      maps: maps,
      timeline: parent,
      tick: 0,
    );
    final corner = pose.single.transform(0, 0);
    expect(corner.x, closeTo(18, 0.0001));
    expect(corner.y, closeTo(29, 0.0001));
  });

  test('rejects invalid cross references instead of dropping parts', () {
    final parent = Gen5NitroSequence(
      loopStart: 0,
      playbackType: 2,
      format: 1,
      frames: [frame(1)],
    );
    expect(
      () => resolveGen5Pose(
        cells: [],
        animations: [],
        maps: [],
        timeline: parent,
        tick: 0,
      ),
      throwsFormatException,
    );
  });

  test('applies child rotation before parent translation', () {
    final cells = [
      Gen5NcerCell(0, [const Gen5NcerObject(0, 1, 0)]),
    ];
    final animations = [
      Gen5NitroSequence(
        loopStart: 0,
        playbackType: 2,
        format: 1,
        frames: [frame(0, rotation: 16384)],
      ),
    ];
    final parent = Gen5NitroSequence(
      loopStart: 0,
      playbackType: 2,
      format: 1,
      frames: [frame(0, x: 5, y: 7)],
    );
    final pose = resolveGen5Pose(
      cells: cells,
      animations: animations,
      maps: [
        const Gen5NmcrMap(1, [Gen5NmcrRecord(0, 10, 20, 0)]),
      ],
      timeline: parent,
      tick: 0,
    );
    final corner = pose.single.transform(0, 0);
    expect(corner.x, closeTo(15, 0.0001));
    expect(corner.y, closeTo(28, 0.0001));
  });

  test('rejects zero scales until their meaning is validated', () {
    const zeroScale = Gen5NitroFrame(
      targetIndex: 0,
      duration: 1,
      marker: 0,
      transformType: 1,
      rotation: 0,
      scaleX: 0,
      scaleY: 4096,
      translateX: 0,
      translateY: 0,
    );
    final parent = Gen5NitroSequence(
      loopStart: 0,
      playbackType: 2,
      format: 1,
      frames: [zeroScale],
    );
    expect(
      () => resolveGen5Pose(
        cells: [],
        animations: [],
        maps: [const Gen5NmcrMap(0, [])],
        timeline: parent,
        tick: 0,
      ),
      throwsFormatException,
    );
  });

  test('does not guess reset-node timing after playback starts', () {
    final cells = [
      Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 0)]),
    ];
    final animations = [
      Gen5NitroSequence(
        loopStart: 0,
        playbackType: 2,
        format: 1,
        frames: [frame(0)],
      ),
    ];
    final timeline = Gen5NitroSequence(
      loopStart: 0,
      playbackType: 2,
      format: 1,
      frames: [frame(0)],
    );
    expect(
      () => resolveGen5Pose(
        cells: cells,
        animations: animations,
        maps: [
          const Gen5NmcrMap(1, [Gen5NmcrRecord(0, 0, 0, 0)]),
        ],
        timeline: timeline,
        tick: 1,
      ),
      throwsFormatException,
    );
  });

  test('rejects initial state requiring unsupported shared controllers', () {
    final cells = [
      Gen5NcerCell(0, [const Gen5NcerObject(0, 0, 0)]),
    ];
    final animations = [
      Gen5NitroSequence(
        loopStart: 0,
        playbackType: 2,
        format: 1,
        frames: [frame(0)],
      ),
    ];
    final timeline = Gen5NitroSequence(
      loopStart: 0,
      playbackType: 2,
      format: 1,
      frames: [frame(0)],
    );
    final map = Gen5NmcrMap(1, [
      const Gen5NmcrRecord(0, 0, 0, 0),
      const Gen5NmcrRecord(0, 4, 0, 0),
    ]);
    expect(
      () => resolveGen5Pose(
        cells: cells,
        animations: animations,
        maps: [map],
        timeline: timeline,
        tick: 0,
      ),
      throwsFormatException,
    );
  });

  test('does not guess a nonzero initial loop frame', () {
    final timeline = Gen5NitroSequence(
      loopStart: 1,
      playbackType: 2,
      format: 1,
      frames: [frame(0), frame(0)],
    );
    expect(
      () => resolveGen5Pose(
        cells: [],
        animations: [],
        maps: [const Gen5NmcrMap(0, [])],
        timeline: timeline,
        tick: 0,
      ),
      throwsFormatException,
    );
  });
}
