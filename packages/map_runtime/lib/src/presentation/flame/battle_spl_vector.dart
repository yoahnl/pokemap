import 'dart:math' as math;

import 'battle_spl_particle_motion.dart';
import 'battle_spl_random.dart';

abstract final class BattleSplVectorMath {
  static BattleSplVector randomUnitVector(BattleSplRandom random) => normalize((
    x: random.fixedPoint(bits: 24),
    y: random.fixedPoint(bits: 24),
    z: random.fixedPoint(bits: 24),
  ));

  static BattleSplVector sphereSurface(
    BattleSplRandom random, {
    required int radius,
  }) {
    if (radius < 0 || radius > 2147483647) {
      throw const FormatException('Invalid SPL sphere radius');
    }
    final unit = randomUnitVector(random);
    int scale(int component) {
      final product = component * radius + 2048;
      return product >= 0 ? product ~/ 4096 : -((-product + 4095) ~/ 4096);
    }

    return (x: scale(unit.x), y: scale(unit.y), z: scale(unit.z));
  }

  static BattleSplVector hemisphereSurface(
    BattleSplRandom random, {
    required int radius,
    required String axis,
  }) {
    if (radius < 0 || radius > 2147483647 || !{'x', 'y', 'z'}.contains(axis)) {
      throw const FormatException('Invalid SPL hemisphere');
    }
    final sample = randomUnitVector(random);
    final component = switch (axis) {
      'x' => sample.x,
      'y' => sample.y,
      _ => sample.z,
    };
    final sign = component <= 0 ? -1 : 1;
    int scale(int value) {
      final product = value * sign * radius + 2048;
      return product >= 0 ? product ~/ 4096 : -((-product + 4095) ~/ 4096);
    }

    return (x: scale(sample.x), y: scale(sample.y), z: scale(sample.z));
  }

  static BattleSplVector circleBorder(
    BattleSplRandom random, {
    required int radius,
    required String axis,
  }) {
    if (radius < 0 || radius > 2147483647 || !{'x', 'y', 'z'}.contains(axis)) {
      throw const FormatException('Invalid SPL circle');
    }
    final sample = normalize((
      x: random.fixedPoint(bits: 24),
      y: random.fixedPoint(bits: 24),
      z: 0,
    ));
    int scale(int value) {
      final product = value * radius + 2048;
      return product >= 0 ? product ~/ 4096 : -((-product + 4095) ~/ 4096);
    }

    final x = scale(sample.x);
    final y = scale(sample.y);
    return switch (axis) {
      'x' => (x: 0, y: -y, z: x),
      'y' => (x: -y, y: 0, z: -x),
      _ => (x: -x, y: -y, z: 0),
    };
  }

  static BattleSplVector uniformCircleBorder({
    required int index,
    required int count,
    required int radius,
    required String axis,
  }) {
    if (count < 1 || count > 64 || index < 0 || index >= count ||
        radius < 0 || radius > 2147483647 || !{'x', 'y', 'z'}.contains(axis)) {
      throw const FormatException('Invalid SPL uniform circle');
    }
    final angleIndex = ((index * 65536 ~/ count) & 65535) >> 4;
    final angle = angleIndex * 2 * math.pi / 4096;
    final sine = (math.sin(angle) * 4096).round();
    final cosine = (math.cos(angle) * 4096).round();
    final x = (sine * radius + 2048) >> 12;
    final y = (cosine * radius + 2048) >> 12;
    return switch (axis) {
      'x' => (x: 0, y: -y, z: x),
      'y' => (x: -y, y: 0, z: -x),
      _ => (x: -x, y: -y, z: 0),
    };
  }

  static BattleSplVector normalize(BattleSplVector vector) {
    if (!_valid(vector.x) || !_valid(vector.y) || !_valid(vector.z)) {
      throw const FormatException('SPL vector sample exceeds 24 bits');
    }
    final x = BigInt.from(vector.x);
    final y = BigInt.from(vector.y);
    final z = BigInt.from(vector.z);
    final squared = x * x + y * y + z * z;
    if (squared == BigInt.zero) {
      throw const FormatException('Cannot normalize a zero SPL vector');
    }
    final divisor = (BigInt.one << 56) ~/ squared;
    final length = _integerSquareRoot(squared << 2);
    final multiplier = divisor * length;
    final rounding = BigInt.one << 44;
    int normalized(BigInt component) =>
        ((multiplier * component + rounding) >> 45).toInt();
    return (x: normalized(x), y: normalized(y), z: normalized(z));
  }

  static bool _valid(int value) => value >= -8388608 && value <= 8388607;

  static BigInt _integerSquareRoot(BigInt value) {
    if (value < BigInt.two) return value;
    var current = BigInt.one << ((value.bitLength + 1) ~/ 2);
    while (true) {
      final next = (current + value ~/ current) >> 1;
      if (next >= current) return current;
      current = next;
    }
  }
}
