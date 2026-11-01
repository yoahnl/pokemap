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
