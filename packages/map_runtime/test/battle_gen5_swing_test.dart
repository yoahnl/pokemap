import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_swing.dart';

void main() {
  test('shakes on both sides before returning to its starting angle', () {
    final swing = BattleGen5Swing(
      startX: 0,
      startY: 0,
      deltaX: 0xaaaa00,
      deltaY: 0,
      frames: 2,
      wait: 0,
      count: 1,
      shake: true,
      maxDelta: 0x10000000,
    );
    final values = [for (var i = 0; i < 8; i++) swing.advance()];
    expect(values.map((value) => value.x), [
      0x555500,
      0xaaaa00,
      0x555500,
      0,
      -0x555500,
      -0xaaaa00,
      -0x555500,
      0,
    ]);
    expect(values.take(7).map((value) => value.done), everyElement(isFalse));
    expect(values.last.done, isTrue);
  });

  test(
    'oscillates in fixed-point steps with a wait and returns to its origin',
    () {
      final swing = BattleGen5Swing(
        startX: 100,
        startY: -100,
        deltaX: 4096,
        deltaY: 0,
        frames: 4,
        wait: 1,
        count: 1,
      );
      final values = <int>[];
      final done = <bool>[];
      for (var i = 0; i < 15; i++) {
        final result = swing.advance();
        values.add(result.x);
        done.add(result.done);
        expect(result.y, -100);
      }
      expect(values, [
        1124,
        1124,
        2148,
        2148,
        3172,
        3172,
        4196,
        4196,
        3172,
        3172,
        2148,
        2148,
        1124,
        1124,
        100,
      ]);
      expect(done.take(14), everyElement(isFalse));
      expect(done.last, isTrue);
      expect(swing.advance(), (x: 100, y: -100, done: true));
    },
  );

  test('mirrors horizontal position without mirroring vertical motion', () {
    final swing = BattleGen5Swing(
      startX: 0,
      startY: 0,
      deltaX: 4096,
      deltaY: -2048,
      frames: 2,
      wait: 0,
      count: 1,
      mirrorX: true,
    );
    expect(swing.advance(), (x: -2048, y: -1024, done: false));
    expect(swing.advance(), (x: -4096, y: -2048, done: false));
    expect(swing.advance(), (x: -2048, y: -1024, done: false));
    expect(swing.advance(), (x: 0, y: 0, done: true));
  });

  test('completes repeated cycles without drifting from the origin', () {
    final swing = BattleGen5Swing(
      startX: 1,
      startY: 3,
      deltaX: 1229,
      deltaY: -1229,
      frames: 2,
      wait: 1,
      count: 2,
    );
    var result = swing.advance();
    for (var i = 1; i < 15; i++) {
      result = swing.advance();
    }
    expect(result, (x: 1, y: 3, done: true));
  });

  test('rounds fixed-point division like the original for positive and negative halves', () {
    final swing = BattleGen5Swing(
      startX: 0,
      startY: 0,
      deltaX: 1229,
      deltaY: -1229,
      frames: 2,
      wait: 0,
      count: 1,
    );
    expect(swing.advance(), (x: 615, y: -614, done: false));
    expect(swing.advance(), (x: 1230, y: -1228, done: false));
    swing.advance();
    expect(swing.advance(), (x: 0, y: 0, done: true));
    final mirrored = BattleGen5Swing(
      startX: 0,
      startY: 0,
      deltaX: 1229,
      deltaY: 0,
      frames: 2,
      wait: 0,
      count: 1,
      mirrorX: true,
    );
    expect(mirrored.advance().x, -615);
  });

  test('rejects inputs that cannot form a bounded oscillation', () {
    for (final values in [
      (0, 0, 1),
      (1, -1, 1),
      (1, 0, 0),
      (601, 0, 1),
      (1, 601, 1),
      (1, 0, 33),
    ]) {
      expect(
        () => BattleGen5Swing(
          startX: 0,
          startY: 0,
          deltaX: 1,
          deltaY: 1,
          frames: values.$1,
          wait: values.$2,
          count: values.$3,
        ),
        throwsFormatException,
      );
    }
  });
}
