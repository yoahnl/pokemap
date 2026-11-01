import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_motion_policy.dart';

void main() {
  test('defaults preserve normal speed, motion and effect intensity', () {
    final policy = BattleMotionPolicy();

    expect(policy.playbackSpeed, 1);
    expect(policy.reducedMotion, isFalse);
    expect(policy.effectIntensity, 1);
  });

  test('playback speed, reduced motion and intensity are independent', () {
    for (final speed in [0.25, 1.0, 2.0, 10.0]) {
      for (final reducedMotion in [false, true]) {
        for (final intensity in [0.0, 0.35, 1.0]) {
          final policy = BattleMotionPolicy(
            playbackSpeed: speed,
            reducedMotion: reducedMotion,
            effectIntensity: intensity,
          );

          expect(policy.playbackSpeed, speed);
          expect(policy.reducedMotion, reducedMotion);
          expect(policy.effectIntensity, intensity);
        }
      }
    }
  });

  test('fast playback keeps normal motion by default', () {
    final policy = BattleMotionPolicy(playbackSpeed: 2);

    expect(policy.reducedMotion, isFalse);
    expect(policy.effectIntensity, 1);
  });

  test('reduced motion does not accelerate playback or dim effects', () {
    final policy = BattleMotionPolicy(reducedMotion: true);

    expect(policy.playbackSpeed, 1);
    expect(policy.effectIntensity, 1);
  });

  test('accepts finite positive playback speed boundaries', () {
    for (final speed in [double.minPositive, double.maxFinite]) {
      expect(BattleMotionPolicy(playbackSpeed: speed).playbackSpeed, speed);
    }
  });

  test('rejects zero, negative and nonfinite playback speeds', () {
    for (final speed in [
      0.0,
      -0.0,
      -0.5,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => BattleMotionPolicy(playbackSpeed: speed),
        throwsArgumentError,
        reason: 'playback speed $speed must be finite and positive',
      );
    }
  });

  test('rejects out-of-range and nonfinite effect intensities', () {
    for (final intensity in [
      -0.01,
      1.01,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => BattleMotionPolicy(effectIntensity: intensity),
        throwsArgumentError,
        reason: 'effect intensity $intensity must be finite and within [0, 1]',
      );
    }
  });

  test('legacy nonpositive scales preserve the old fallback to one', () {
    for (final scale in [-double.maxFinite, -0.5, -0.0, 0.0]) {
      final policy = BattleMotionPolicy.legacy(scale);

      expect(policy.playbackSpeed, 1);
      expect(policy.reducedMotion, isFalse);
      expect(policy.effectIntensity, 1);
    }
  });

  test('legacy positive scales preserve speed and reduction above one', () {
    for (final scale in [
      double.minPositive,
      0.5,
      1.0,
      1.00001,
      2.0,
      double.maxFinite,
    ]) {
      final policy = BattleMotionPolicy.legacy(scale);

      expect(policy.playbackSpeed, scale);
      expect(policy.reducedMotion, scale > 1);
      expect(policy.effectIntensity, 1);
    }
  });

  test('legacy rejects nonfinite scales instead of hiding invalid input', () {
    for (final scale in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => BattleMotionPolicy.legacy(scale),
        throwsArgumentError,
        reason: 'legacy scale $scale must be finite',
      );
    }
  });
}
