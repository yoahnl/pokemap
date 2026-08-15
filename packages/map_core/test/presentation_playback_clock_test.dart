import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationPlaybackClock', () {
    test('play, pause, resume and stop keep monotonic narrative time', () {
      final clock = PresentationPlaybackClock(durationUs: 4_000_000);

      final firstRun = clock.play();
      expect(firstRun, isNotNull);
      expect(clock.advanceBy(750_000, token: firstRun!), isTrue);
      expect(clock.playheadUs, 750_000);

      clock.pause();
      expect(clock.status, PresentationPlaybackStatus.paused);
      expect(clock.mediaClockPolicy, PresentationMediaClockPolicy.paused);
      expect(clock.advanceBy(500_000, token: firstRun), isFalse);
      expect(clock.playheadUs, 750_000);

      final resumedRun = clock.resume();
      expect(resumedRun, isNot(firstRun));
      expect(clock.advanceBy(250_000, token: resumedRun!), isTrue);
      expect(clock.playheadUs, 1_000_000);

      clock.stop();
      expect(clock.status, PresentationPlaybackStatus.ready);
      expect(clock.playheadUs, 0);
      expect(clock.advanceBy(500_000, token: resumedRun), isFalse);
    });

    test('completion and loop share the same bounded timebase', () {
      final clock = PresentationPlaybackClock(durationUs: 1_000_000);

      final firstRun = clock.play()!;
      clock.advanceBy(1_250_000, token: firstRun);

      expect(clock.playheadUs, 1_000_000);
      expect(clock.status, PresentationPlaybackStatus.completed);

      clock.setLoop(true);
      final loopRun = clock.play()!;
      clock.advanceBy(2_250_000, token: loopRun);

      expect(clock.playheadUs, 250_000);
      expect(clock.status, PresentationPlaybackStatus.playing);
    });

    test(
      'seek and frame steps are deterministic and never mutate a document',
      () {
        final clock = PresentationPlaybackClock(
          durationUs: 2_000_000,
          frameStepUs: 40_000,
        );

        clock.seekTo(1_990_000);
        clock.stepForward();
        expect(clock.playheadUs, 2_000_000);
        expect(clock.status, PresentationPlaybackStatus.paused);

        clock.stepBackward();
        expect(clock.playheadUs, 1_960_000);

        clock.seekTo(8_000_000);
        expect(clock.playheadUs, 2_000_000);

        final restartedRun = clock.resume();
        expect(restartedRun, isNotNull);
        expect(clock.playheadUs, 0);
      },
    );

    test('interaction hold freezes narrative while ambience continues', () {
      final clock = PresentationPlaybackClock(durationUs: 4_000_000);
      final run = clock.play()!;
      clock.advanceBy(500_000, token: run);

      clock.holdForInteraction();

      expect(clock.status, PresentationPlaybackStatus.interactionHold);
      expect(clock.narrativeClockRunning, isFalse);
      expect(
        clock.mediaClockPolicy,
        PresentationMediaClockPolicy.continueAmbient,
      );
      expect(clock.advanceBy(500_000, token: run), isFalse);
      expect(clock.playheadUs, 500_000);

      final resumedRun = clock.resume();
      clock.advanceBy(250_000, token: resumedRun!);
      expect(clock.playheadUs, 750_000);
    });

    test('loading, error and disposal reject incoherent commands', () {
      final clock = PresentationPlaybackClock(
        durationUs: 4_000_000,
        initialStatus: PresentationPlaybackStatus.loading,
      );

      expect(clock.play(), isNull);
      clock.seekTo(2_000_000);
      expect(clock.playheadUs, 0);

      clock.setError();
      expect(clock.play(), isNull);

      clock.setReady();
      final run = clock.play();
      expect(run, isNotNull);

      clock.dispose();
      expect(clock.status, PresentationPlaybackStatus.disposed);
      expect(clock.advanceBy(500_000, token: run!), isFalse);
      expect(clock.play(), isNull);
    });

    test(
      'a duration change clamps the current preview without rewinding it',
      () {
        final clock = PresentationPlaybackClock(
          durationUs: 4_000_000,
          initialPlayheadUs: 3_000_000,
        );

        clock.configureDuration(2_000_000);

        expect(clock.durationUs, 2_000_000);
        expect(clock.playheadUs, 2_000_000);
        expect(clock.status, PresentationPlaybackStatus.completed);
      },
    );
  });
}
