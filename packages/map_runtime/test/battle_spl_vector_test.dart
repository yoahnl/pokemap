import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_vector.dart';

void main() {
  test('normalizes source vectors with fixed-point rounding', () {
    expect(BattleSplVectorMath.normalize((x: 4096, y: 0, z: 0)), (
      x: 4096,
      y: 0,
      z: 0,
    ));
    expect(BattleSplVectorMath.normalize((x: -4096, y: 0, z: 0)), (
      x: -4096,
      y: 0,
      z: 0,
    ));
    expect(BattleSplVectorMath.normalize((x: 3, y: 4, z: 0)), (
      x: 2458,
      y: 3277,
      z: 0,
    ));
    expect(BattleSplVectorMath.normalize((x: -3, y: 4, z: -5)), (
      x: -1720,
      y: 2294,
      z: -2867,
    ));
    expect(BattleSplVectorMath.normalize((x: 8388607, y: -8388608, z: 0)), (
      x: 2896,
      y: -2896,
      z: 0,
    ));
  });

  test('consumes three signed samples for a deterministic unit vector', () {
    final random = BattleSplRandom(seed: 0);
    expect(BattleSplVectorMath.randomUnitVector(random), (
      x: 3262,
      y: 2383,
      z: -676,
    ));
    expect(random.state, 0xfa6515fd);
  });

  test('places an emission on a source-sized spherical surface', () {
    final random = BattleSplRandom(seed: 0);
    expect(BattleSplVectorMath.sphereSurface(random, radius: 7004), (
      x: 5578,
      y: 4075,
      z: -1156,
    ));
    expect(random.state, 0xfa6515fd);
    final zero = BattleSplRandom(seed: 0);
    expect(BattleSplVectorMath.sphereSurface(zero, radius: 0), (
      x: 0,
      y: 0,
      z: 0,
    ));
    expect(zero.state, 0xfa6515fd);
    expect(
      () => BattleSplVectorMath.sphereSurface(zero, radius: -1),
      throwsFormatException,
    );
  });

  test('rejects zero vectors and samples outside the supported range', () {
    expect(
      () => BattleSplVectorMath.normalize((x: 0, y: 0, z: 0)),
      throwsFormatException,
    );
    expect(
      () => BattleSplVectorMath.normalize((x: 8388608, y: 0, z: 0)),
      throwsFormatException,
    );
  });
}
