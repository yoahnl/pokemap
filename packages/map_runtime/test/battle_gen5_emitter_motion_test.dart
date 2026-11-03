import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_emitter_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';

BattleGen5EmitterMotion _motion({
  BattleSplVector from = (x: 0, y: 0, z: 0),
  BattleSplVector to = (x: 65536, y: 0, z: 0),
  int motionType = 1,
  int motionFramesFx32 = 0x1e000,
  int offsetYFx32 = 0x2000,
  int heightFx32 = 0x800,
  int turnsFx32 = 0x5000,
}) => BattleGen5EmitterMotion(
  from: from,
  to: to,
  motionType: motionType,
  motionFramesFx32: motionFramesFx32,
  offsetYFx32: offsetYFx32,
  heightFx32: heightFx32,
  turnsFx32: turnsFx32,
);

void main() {
  test('field-origin projectile travels from its source point to the defender', () {
    final endpoints = gen5SourceFieldMotionEndpoints({
      'fromX': 0, 'fromY': 0x2000, 'fromZ': 0,
      'to': 'EFFVM_EMIT_DEFENDER',
    });
    final motion = _motion(from: endpoints.from, to: endpoints.to,
        motionFramesFx32: 20 * 4096, offsetYFx32: 0x2000, heightFx32: 0);
    expect(motion.position, (x: endpoints.from.x,
        y: endpoints.from.y + 0x2000, z: endpoints.from.z + 0x500));
    for (var i = 0; i < 20; i++) {
      motion.advance();
    }
    expect(motion.position.x, closeTo(endpoints.to.x, 256));
    expect(motion.position.y, closeTo(endpoints.to.y + 0x2000, 256));
    expect(motion.position.z, closeTo(endpoints.to.z + 0x500, 256));
  });

  test('types 5 and 6 oscillate on separate axes while moving forward', () {
    final vertical = _motion(motionType: 5, motionFramesFx32: 0x4000,
        heightFx32: 4096, turnsFx32: 4096);
    final lateral = _motion(motionType: 6, motionFramesFx32: 0x4000,
        heightFx32: 4096, turnsFx32: 4096);
    final ys = <int>[];
    final zs = <int>[];
    for (var i = 0; i < 4; i++) {
      final a = vertical.advance();
      final b = lateral.advance();
      expect(a.x, b.x);
      expect(a.z, 1280);
      expect(b.y, 8192);
      ys.add(a.y - 8192);
      zs.add(b.z - 1280);
    }
    expect(ys, [4096, 0, -4096, 0]);
    expect(zs, [4096, 0, -4096, 0]);
    expect(vertical.isComplete, isTrue);
    expect(lateral.isComplete, isTrue);
  });

  test('type 6 rotates its lateral wave with the travel direction', () {
    final motion = _motion(from: (x: 0, y: 0, z: 0),
        to: (x: 0, y: 0, z: 65536), motionType: 6,
        motionFramesFx32: 0x4000, heightFx32: 4096, turnsFx32: 4096);
    final first = motion.advance();
    expect(first.x, lessThan(-4000));
    expect(first.y, 8192);
    for (var i = 0; i < 3; i++) { motion.advance(); }
    expect(motion.position.x.abs(), lessThan(32));
  });

  test('type 1 follows the source half-sine samples in 30 fx32 frames', () {
    final motion = _motion();
    final expected = {
      0: (x: 0, y: 8192, z: 1280),
      1: (x: 176, y: 8192, z: 1280),
      7: (x: 8384, y: 8192, z: 1280),
      15: (x: 32720, y: 8192, z: 1280),
      22: (x: 54664, y: 8192, z: 1280),
      30: (x: 65536, y: 8192, z: 1280),
    };
    expect(motion.position, expected[0]);
    expect(motion.isComplete, isFalse);
    for (var tick = 1; tick <= 30; tick++) {
      final position = motion.advance();
      if (expected.containsKey(tick)) {
        expect(position, expected[tick], reason: 'tick $tick');
      }
    }
    expect(motion.isComplete, isTrue);
    expect(motion.advance(), expected[30]);
  });

  test(
    'source rotation works in three dimensions without screen projection',
    () {
      final motion = _motion(
        from: (x: -4096, y: 0, z: 8192),
        to: (x: 12288, y: 2048, z: -8192),
      );
      final expected = {
        0: (x: -4096, y: 8192, z: 9472),
        1: (x: -4053, y: 8197, z: 9428),
        7: (x: -2002, y: 8453, z: 7374),
        15: (x: 4077, y: 9212, z: 1286),
        22: (x: 9559, y: 9897, z: -4203),
        30: (x: 12275, y: 10236, z: -6923),
      };
      expect(motion.position, expected[0]);
      for (var tick = 1; tick <= 30; tick++) {
        final position = motion.advance();
        if (expected.containsKey(tick)) {
          expect(position, expected[tick], reason: 'tick $tick');
        }
      }
    },
  );

  test(
    'duration uses fx32, including its fractional part for the angle step',
    () {
      final whole = _motion(motionFramesFx32: 0x1000);
      final fractional = _motion(motionFramesFx32: 0x1800);
      final wholeEnd = whole.advance();
      final fractionalEnd = fractional.advance();
      expect(whole.isComplete, isTrue);
      expect(fractional.isComplete, isTrue);
      expect(wholeEnd.x, 65536);
      expect(fractionalEnd.x, lessThan(wholeEnd.x));
      expect(fractionalEnd.x, greaterThan(32768));
    },
  );

  test('height and turns do not change the type 1 trajectory', () {
    final a = _motion(heightFx32: 0, turnsFx32: 0);
    final b = _motion(heightFx32: 0x7fffffff, turnsFx32: -0x80000000);
    for (var tick = 0; tick < 30; tick++) {
      expect(a.advance(), b.advance());
    }
  });

  test('type 2 follows the Acid arc using source fx32 values', () {
    final motion = _motion(motionType: 2, heightFx32: 0x399a);
    final expected = {
      0: (x: 0, y: 8192, z: 1280),
      1: (x: 176, y: 9726, z: 1280),
      7: (x: 8384, y: 18045, z: 1280),
      15: (x: 32720, y: 22938, z: 1280),
      22: (x: 54664, y: 19165, z: 1280),
      30: (x: 65536, y: 8214, z: 1280),
    };
    expect(motion.position, expected[0]);
    for (var tick = 1; tick <= 30; tick++) {
      final position = motion.advance();
      if (expected.containsKey(tick)) {
        expect(position, expected[tick], reason: 'tick $tick');
      }
    }
    expect(motion.isComplete, isTrue);
    expect(motion.advance(), expected[30]);
  });

  test('type 2 rotates both arc coordinates in three dimensions', () {
    final motion = _motion(
      from: (x: -4096, y: 0, z: 8192),
      to: (x: 12288, y: 2048, z: -8192),
      motionType: 2,
      heightFx32: 0x399a,
    );
    final expected = {
      1: (x: -4188, y: 9724, z: 9484),
      7: (x: -2868, y: 18260, z: 7732),
      15: (x: 2781, y: 23890, z: 1823),
      22: (x: 8595, y: 20819, z: -3804),
      30: (x: 12273, y: 10258, z: -6922),
    };
    for (var tick = 1; tick <= 30; tick++) {
      final position = motion.advance();
      if (expected.containsKey(tick)) {
        expect(position, expected[tick], reason: 'tick $tick');
      }
    }
  });

  test('type 2 applies signed height and ignores turns', () {
    final zero = _motion(motionType: 2, heightFx32: 0, turnsFx32: 0);
    final positive = _motion(motionType: 2, heightFx32: 0x1000);
    final differentTurns = _motion(
      motionType: 2,
      heightFx32: 0x1000,
      turnsFx32: -0x80000000,
    );
    final negative = _motion(
      motionType: 2,
      heightFx32: -0x1000,
      turnsFx32: -0x80000000,
    );
    for (var tick = 0; tick < 15; tick++) {
      zero.advance();
      positive.advance();
      expect(differentTurns.advance(), positive.position);
      negative.advance();
    }
    expect(positive.position.x, zero.position.x);
    expect(negative.position.x, zero.position.x);
    expect(positive.position.y - zero.position.y, 4096);
    expect(negative.position.y - zero.position.y, -4096);
  });

  test('type 2 with zero height keeps the type 1 trajectory', () {
    final linear = _motion(
      from: (x: -4096, y: 0, z: 8192),
      to: (x: 12288, y: 2048, z: -8192),
    );
    final arc = _motion(
      from: (x: -4096, y: 0, z: 8192),
      to: (x: 12288, y: 2048, z: -8192),
      motionType: 2,
      heightFx32: 0,
    );
    for (var tick = 0; tick < 30; tick++) {
      expect(arc.advance(), linear.advance());
    }
  });

  test('inactive callback and cancellation preserve the current position', () {
    final motion = _motion();
    final initial = motion.position;
    expect(motion.advance(active: false), initial);
    final current = motion.advance();
    expect(current, isNot(initial));
    motion.cancel();
    expect(motion.isCancelled, isTrue);
    expect(motion.isComplete, isTrue);
    expect(motion.advance(), current);
  });

  test('unsupported motion modes, ranges and zero direction are rejected', () {
    expect(() => _motion(motionType: 3), throwsFormatException);
    expect(() => _motion(motionFramesFx32: 0xfff), throwsFormatException);
    expect(() => _motion(motionFramesFx32: 0x80000000), throwsFormatException);
    expect(() => _motion(offsetYFx32: 0x80000000), throwsFormatException);
    expect(() => _motion(to: (x: 0, y: 0, z: 0)), throwsFormatException);
    expect(() => _motion(to: (x: 0x800000, y: 0, z: 0)), throwsFormatException);
    expect(
      () => _motion(
        from: (x: 0, y: 0x80000000, z: 0),
        to: (x: 65536, y: 0x80000000, z: 0),
        offsetYFx32: -0x7fffffff,
      ),
      throwsFormatException,
    );
  });

  test('zero duration keeps the emitter at its source position', () {
    final motion = _motion(motionFramesFx32: 0);
    expect(motion.isComplete, isTrue);
    expect(motion.position, (x: 0, y: 0x2000, z: 0x500));
    expect(motion.advance(), motion.position);
  });
}
