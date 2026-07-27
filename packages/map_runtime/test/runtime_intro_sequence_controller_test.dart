import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('plays normally, pauses for lifecycle, and can be skipped', () {
    final controller = RuntimeIntroSequenceController();

    controller.start(
      hasVideo: true,
      hasPoster: true,
      reducedMotion: false,
      reducedMotionBehavior: RuntimeIntroReducedMotionBehavior.poster,
      allowReplay: true,
    );
    expect(controller.phase, RuntimeIntroPhase.playing);

    controller.pauseForLifecycle();
    expect(controller.phase, RuntimeIntroPhase.paused);

    controller.resumeAfterLifecycle();
    expect(controller.phase, RuntimeIntroPhase.playing);

    controller.skip();
    expect(controller.phase, RuntimeIntroPhase.completed);
  });

  test('reduced motion shows a poster or skips without trapping the player',
      () {
    final poster = RuntimeIntroSequenceController()
      ..start(
        hasVideo: true,
        hasPoster: true,
        reducedMotion: true,
        reducedMotionBehavior: RuntimeIntroReducedMotionBehavior.poster,
        allowReplay: false,
      );
    expect(poster.phase, RuntimeIntroPhase.poster);
    poster.continueFromPoster();
    expect(poster.phase, RuntimeIntroPhase.completed);

    final skip = RuntimeIntroSequenceController()
      ..start(
        hasVideo: true,
        hasPoster: true,
        reducedMotion: true,
        reducedMotionBehavior: RuntimeIntroReducedMotionBehavior.skip,
        allowReplay: false,
      );
    expect(skip.phase, RuntimeIntroPhase.completed);
  });

  test('decoder failure falls back to poster then title', () {
    final controller = RuntimeIntroSequenceController()
      ..start(
        hasVideo: true,
        hasPoster: true,
        reducedMotion: false,
        reducedMotionBehavior: RuntimeIntroReducedMotionBehavior.poster,
        allowReplay: true,
      );

    controller.playbackFailed('decoder unavailable');
    expect(controller.phase, RuntimeIntroPhase.poster);
    expect(controller.failureReason, 'decoder unavailable');

    controller.continueFromPoster();
    expect(controller.phase, RuntimeIntroPhase.completed);
  });

  test('missing poster and replay policy always retain a path to title', () {
    final controller = RuntimeIntroSequenceController()
      ..start(
        hasVideo: true,
        hasPoster: false,
        reducedMotion: false,
        reducedMotionBehavior: RuntimeIntroReducedMotionBehavior.poster,
        allowReplay: false,
      );

    controller.playbackFailed('corrupt media');
    expect(controller.phase, RuntimeIntroPhase.completed);
    expect(controller.replay(), isFalse);
    expect(controller.phase, RuntimeIntroPhase.completed);
  });
}
