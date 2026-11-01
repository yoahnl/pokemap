import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';

void main() {
  test('advances the original 32-bit generator with wraparound', () {
    final random = BattleSplRandom(seed: 0);
    expect(List.generate(5, (_) => random.next()), [
      0x1b0cb173,
      0x13c434e2,
      0xfa6515fd,
      0x6ec79a34,
      0xa15883b7,
    ]);
    expect(random.state, 0xa15883b7);
    final highSeed = BattleSplRandom(seed: 0xffffffff);
    expect(List.generate(3, (_) => highSeed.next()), [
      0xbc1eba5e,
      0x3c68ad29,
      0x6baa74d0,
    ]);
  });

  test('produces signed fixed-point values with arithmetic shift', () {
    final random = BattleSplRandom(seed: 0);
    expect(random.fixedPoint(bits: 24), 1772721);
    expect(random.fixedPoint(bits: 24), 1295412);
    expect(random.fixedPoint(bits: 24), -367339);
  });

  test('consumes randomness even when variance is zero', () {
    final random = BattleSplRandom(seed: 0);
    expect(random.vary(2969, variance: 0), 2957);
    expect(random.state, 0x1b0cb173);
    expect(random.vary(3276, variance: 51), 3826);
    expect(random.state, 0x13c434e2);
    expect(random.vary(-1, variance: 0), -1);
  });

  test('samples the original signed range and validates inputs', () {
    final random = BattleSplRandom(seed: 0);
    expect(random.range(4096), -3232);
    expect(() => random.fixedPoint(bits: 0), throwsArgumentError);
    expect(() => random.vary(1, variance: 256), throwsArgumentError);
    expect(() => random.range(-1), throwsArgumentError);
    expect(() => BattleSplRandom(seed: -1), throwsFormatException);
    expect(() => BattleSplRandom(seed: 0x100000000), throwsFormatException);
  });
}
