import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_motion_playback.dart';

void main() {
  test('plays swing and scale together, holds pause until released and restores on finish', () {
    final a = _Target();
    final b = _Target();
    var completed = 0;
    var failed = 0;
    final playback = BattleGen5MotionPlayback(
      bindings: {'user': a.binding, 'target': b.binding},
      swings: [
        const BattleGen5MotionSpec(
          target: 'user',
          channel: 'position',
          x: 4096,
          y: 0,
          frames: 4,
          wait: 1,
          count: 1,
        ),
        const BattleGen5MotionSpec(
          target: 'target',
          channel: 'scale',
          x: 1229,
          y: -1229,
          frames: 2,
          wait: 1,
          count: 1,
        ),
      ],
      pausedTargets: {'target'},
      pixelsPerUnit: 5,
      onComplete: () => completed++,
      onFailure: () => failed++,
    );
    playback.start();
    expect(b.paused, isTrue);
    playback.advance(1 / 60);
    expect(a.pose.offsetX, closeTo(1.25, .0001));
    expect(b.pose.scaleX, closeTo(1 + 615 / 4096, .0001));
    expect(b.pose.scaleY, closeTo(1 - 614 / 4096, .0001));
    playback.advance(14 / 60);
    expect(completed, 1);
    expect(failed, 0);
    expect(a.pose, BattleGen5MotionPose.neutral);
    expect(b.pose, BattleGen5MotionPose.neutral);
    expect(b.paused, isTrue);
    playback.dispose();
    expect(b.paused, isFalse);
  });

  test(
    'cancellation and ownership conflicts release every claimed resource',
    () {
      final a = _Target();
      final b = _Target()..accept = false;
      var failed = 0;
      final playback = BattleGen5MotionPlayback(
        bindings: {'user': a.binding, 'target': b.binding},
        swings: [
          const BattleGen5MotionSpec(
            target: 'user',
            channel: 'position',
            x: 4096,
            y: 0,
            frames: 4,
            wait: 1,
            count: 1,
          ),
          const BattleGen5MotionSpec(
            target: 'target',
            channel: 'scale',
            x: 1229,
            y: 0,
            frames: 2,
            wait: 1,
            count: 1,
          ),
        ],
        pausedTargets: {'target'},
        pixelsPerUnit: 5,
        onComplete: () {},
        onFailure: () => failed++,
      );
      playback.start();
      playback.advance(1 / 60);
      expect(failed, 1);
      expect(a.pose, BattleGen5MotionPose.neutral);
      expect(b.paused, isFalse);
      playback.dispose();
      expect(failed, 1);
    },
  );

  test('mirrors position on the opposite side but not scale', () {
    final target = _Target();
    final playback = BattleGen5MotionPlayback(
      bindings: {'target': target.binding},
      swings: [
        const BattleGen5MotionSpec(
          target: 'target',
          channel: 'position',
          x: 4096,
          y: 0,
          frames: 4,
          wait: 1,
          count: 1,
          mirrorX: true,
        ),
      ],
      pausedTargets: {},
      pixelsPerUnit: 5,
      onComplete: () {},
      onFailure: () {},
    );
    playback.start();
    playback.advance(1 / 60);
    expect(target.pose.offsetX, closeTo(-1.25, .0001));
    playback.dispose();
    expect(target.pose, BattleGen5MotionPose.neutral);
  });

  test('releases a paused sprite if the effect never completes', () {
    final target = _Target();
    var failed = 0;
    final playback = BattleGen5MotionPlayback(
      bindings: {'target': target.binding},
      swings: [
        const BattleGen5MotionSpec(
          target: 'target',
          channel: 'scale',
          x: 100,
          y: 0,
          frames: 1,
          wait: 0,
          count: 1,
        ),
      ],
      pausedTargets: {'target'},
      pixelsPerUnit: 5,
      onComplete: () {},
      onFailure: () => failed++,
    );
    playback.start();
    playback.advance(2 / 60);
    expect(target.paused, isTrue);
    playback.advance(30);
    expect(failed, 1);
    expect(target.paused, isFalse);
  });

  test(
    'rejects scale oscillations whose rounded steps cross the safe range',
    () {
      final target = _Target();
      for (final value in [-4095, 28672]) {
        expect(
          () => BattleGen5MotionPlayback(
            bindings: {'target': target.binding},
            swings: [
              BattleGen5MotionSpec(
                target: 'target',
                channel: 'scale',
                x: value,
                y: 0,
                frames: 600,
                wait: 0,
                count: 1,
              ),
            ],
            pausedTargets: {},
            pixelsPerUnit: 5,
            onComplete: () {},
            onFailure: () {},
          ),
          throwsFormatException,
        );
      }
    },
  );
}

final class _Target {
  BattleGen5MotionPose pose = BattleGen5MotionPose.neutral;
  bool paused = false;
  bool accept = true;
  late final binding = BattleGen5MotionBinding(
    apply: (value) {
      if (!accept) return false;
      pose = value;
      return true;
    },
    clear: () => pose = BattleGen5MotionPose.neutral,
    pause: () => paused = true,
    resume: () => paused = false,
  );
}
