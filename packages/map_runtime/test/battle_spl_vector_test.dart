import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_vector.dart';

void main() {
  test('places Surf ring particles using the BW2 ten-angle source table', () {
    final positions = [
      for (var index = 0; index < 10; index++)
        BattleSplVectorMath.uniformCircleBorder(
          index: index, count: 10, radius: 8832, axis: 'y',
        ),
    ];
    expect(positions, [
      (x: -8832, y: 0, z: 0),
      (x: -7150, y: 0, z: -5186),
      (x: -2732, y: 0, z: -8399),
      (x: 2719, y: 0, z: -8403),
      (x: 7141, y: 0, z: -5197),
      (x: 8832, y: 0, z: 0),
      (x: 7150, y: 0, z: 5186),
      (x: 2732, y: 0, z: 8399),
      (x: -2719, y: 0, z: 8403),
      (x: -7142, y: 0, z: 5197),
    ]);
  });

  test(
    'generates the BW2 circle border from two samples in each axis plane',
    () {
      for (final entry in {
        'x': (x: 0, y: -2417, z: 3307),
        'y': (x: -2417, y: 0, z: -3307),
        'z': (x: -3307, y: -2417, z: 0),
      }.entries) {
        final random = BattleSplRandom(seed: 0);
        expect(
          BattleSplVectorMath.circleBorder(
            random,
            radius: 4096,
            axis: entry.key,
          ),
          entry.value,
        );
        expect(random.state, 0x13c434e2);
      }
      final zero = BattleSplRandom(seed: 0);
      expect(BattleSplVectorMath.circleBorder(zero, radius: 0, axis: 'y'), (
        x: 0,
        y: 0,
        z: 0,
      ));
      expect(zero.state, 0x13c434e2);
      expect(
        () => BattleSplVectorMath.circleBorder(zero, radius: -1, axis: 'y'),
        throwsFormatException,
      );
      expect(
        () => BattleSplVectorMath.circleBorder(zero, radius: 1, axis: 'other'),
        throwsFormatException,
      );
    },
  );

  test(
    'mirrors the BW2 hemisphere sample around the selected emission axis',
    () {
      final x = BattleSplRandom(seed: 0);
      expect(
        BattleSplVectorMath.hemisphereSurface(x, radius: 4096, axis: 'x'),
        (x: 3262, y: 2383, z: -676),
      );
      expect(x.state, 0xfa6515fd);
      final z = BattleSplRandom(seed: 0);
      expect(
        BattleSplVectorMath.hemisphereSurface(z, radius: 4096, axis: 'z'),
        (x: -3262, y: -2383, z: 676),
      );
      expect(z.state, 0xfa6515fd);
      final zero = BattleSplRandom(seed: 0);
      expect(
        BattleSplVectorMath.hemisphereSurface(zero, radius: 0, axis: 'x'),
        (x: 0, y: 0, z: 0),
      );
      expect(zero.state, 0xfa6515fd);
      expect(
        () =>
            BattleSplVectorMath.hemisphereSurface(zero, radius: -1, axis: 'x'),
        throwsFormatException,
      );
      expect(
        () => BattleSplVectorMath.hemisphereSurface(
          zero,
          radius: 0,
          axis: 'arbitrary',
        ),
        throwsFormatException,
      );
    },
  );

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
