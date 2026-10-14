import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_world_tone_controller.dart';

void main() {
  SceneWorldToneValue tone(
    double red, {
    double green = 0,
    double blue = 0,
    double gray = 0,
  }) => SceneWorldToneValue(red: red, green: green, blue: blue, gray: gray);

  test('a new controller starts neutral and has no transition', () {
    final controller = SceneWorldToneController();
    expect(controller.value, SceneWorldToneValue.neutral);
    expect(controller.isTransitioning, isFalse);
  });

  test('all four channels interpolate without awaiting the transition', () {
    final controller = SceneWorldToneController();
    final target = tone(-200, green: 100, blue: 80, gray: 240);
    controller.setTone(target, durationSeconds: 2);
    expect(controller.value, SceneWorldToneValue.neutral);
    expect(controller.isTransitioning, isTrue);
    controller.advance(.5);
    expect(controller.value, tone(-50, green: 25, blue: 20, gray: 60));
    controller.advance(1.5);
    expect(controller.value, target);
    expect(controller.isTransitioning, isFalse);
    controller.advance(10);
    expect(controller.value, target);
  });

  test('zero duration changes tone immediately', () {
    final controller = SceneWorldToneController();
    final target = tone(255, green: -255, blue: 40, gray: 255);
    controller.setTone(target, durationSeconds: 0);
    expect(controller.value, target);
    expect(controller.isTransitioning, isFalse);
  });

  test('retargeting interpolates from the value currently displayed', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(200), durationSeconds: 2);
    controller.advance(.5);
    controller.setTone(tone(-150), durationSeconds: 1);
    expect(controller.value, tone(50));
    controller.advance(.5);
    expect(controller.value, tone(-50));
    controller.advance(.5);
    expect(controller.value, tone(-150));
  });

  test(
    'restoring a checkpoint continues its original clock at the current time',
    () {
      final controller = SceneWorldToneController();
      controller.setTone(tone(200), durationSeconds: 2);
      controller.advance(.5);
      final checkpoint = controller.captureCheckpoint();
      controller.setTone(tone(-200), durationSeconds: .25);
      controller.advance(.75);
      controller.restoreCheckpoint(checkpoint);
      expect(controller.value, tone(125));
      expect(controller.isTransitioning, isTrue);
      controller.advance(.75);
      expect(controller.value, tone(200));
      expect(controller.isTransitioning, isFalse);
    },
  );

  test('an old transition restored after its end stays at its target', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(200), durationSeconds: 1);
    final checkpoint = controller.captureCheckpoint();
    controller.setTone(tone(-100), durationSeconds: 0);
    controller.advance(2);
    controller.restoreCheckpoint(checkpoint);
    expect(controller.value, tone(200));
    expect(controller.isTransitioning, isFalse);
  });

  test('a settled checkpoint restores its value without starting a clock', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(60), durationSeconds: 0);
    final checkpoint = controller.captureCheckpoint();
    controller.setTone(tone(-60), durationSeconds: 1);
    controller.advance(3);
    controller.restoreCheckpoint(checkpoint);
    expect(controller.value, tone(60));
    expect(controller.isTransitioning, isFalse);
  });

  test(
    'nested lexical checkpoints each retain their original transition time',
    () {
      final controller = SceneWorldToneController();
      controller.setTone(tone(200), durationSeconds: 4);
      final outer = controller.captureCheckpoint();
      controller.advance(1);
      controller.setTone(tone(-50), durationSeconds: 2);
      final inner = controller.captureCheckpoint();
      controller.advance(1);
      controller.setTone(tone(255), durationSeconds: 0);
      controller.restoreCheckpoint(inner);
      expect(controller.value, tone(0));
      controller.restoreCheckpoint(outer);
      expect(controller.value, tone(100));
    },
  );

  test('reset is neutral and rejects checkpoints from the former session', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(200), durationSeconds: 1);
    final checkpoint = controller.captureCheckpoint();
    controller.advance(.5);
    controller.reset();
    expect(controller.value, SceneWorldToneValue.neutral);
    expect(controller.isTransitioning, isFalse);
    expect(() => controller.restoreCheckpoint(checkpoint), throwsStateError);
    controller.setTone(tone(-60), durationSeconds: 1);
    controller.advance(.5);
    expect(controller.value, tone(-30));
  });

  test('checkpoint ownership cannot cross controllers', () {
    final first = SceneWorldToneController();
    final second = SceneWorldToneController();
    expect(
      () => second.restoreCheckpoint(first.captureCheckpoint()),
      throwsStateError,
    );
    expect(second.value, SceneWorldToneValue.neutral);
  });

  test('disposal resets tone and closes all mutations', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(200), durationSeconds: 0);
    final checkpoint = controller.captureCheckpoint();
    controller.dispose();
    controller.dispose();
    expect(controller.value, SceneWorldToneValue.neutral);
    expect(controller.isTransitioning, isFalse);
    expect(() => controller.advance(.1), throwsStateError);
    expect(
      () => controller.setTone(tone(1), durationSeconds: 0),
      throwsStateError,
    );
    expect(controller.captureCheckpoint, throwsStateError);
    expect(() => controller.restoreCheckpoint(checkpoint), throwsStateError);
    expect(controller.reset, throwsStateError);
  });

  test('invalid duration or time cannot mutate a pending transition', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(200), durationSeconds: 2);
    controller.advance(.5);
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(() => controller.advance(invalid), throwsArgumentError);
      expect(
        () => controller.setTone(tone(-50), durationSeconds: invalid),
        throwsArgumentError,
      );
      expect(controller.value, tone(50));
    }
    controller.advance(0);
    expect(controller.value, tone(50));
    controller.advance(.5);
    expect(controller.value, tone(100));
  });

  test('finite channel limits are enforced without clamping invalid input', () {
    for (final channel in ['red', 'green', 'blue', 'gray']) {
      final range = channel == 'gray' ? [0.0, 255.0] : [-255.0, 255.0];
      for (final invalid in [
        range.first - .001,
        range.last + .001,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => SceneWorldToneValue(
            red: channel == 'red' ? invalid : 0,
            green: channel == 'green' ? invalid : 0,
            blue: channel == 'blue' ? invalid : 0,
            gray: channel == 'gray' ? invalid : 0,
          ),
          throwsArgumentError,
          reason: '$channel=$invalid',
        );
      }
    }
  });

  test('time overflow is rejected without losing the current value', () {
    final controller = SceneWorldToneController();
    controller.setTone(tone(2), durationSeconds: 0);
    controller.advance(double.maxFinite);
    expect(() => controller.advance(double.maxFinite), throwsArgumentError);
    expect(controller.value, tone(2));
  });
}
