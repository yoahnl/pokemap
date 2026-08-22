import 'dart:async';

import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two BETA-SYS-004 criteria that had no implementation at all.
///
/// The ticket lists six acceptance criteria; four were satisfied by existing
/// code and two were quietly skipped. "Fades annulables sans double player" had
/// nothing behind it — only VISUAL fades existed, and `transitionTo` applied a
/// mix instantly, so there was nothing to cancel. "SFX fréquents utilisent un
/// pool" had zero occurrences of any pool in the repository.
///
/// Both are now real, and both are tested for the property that matters rather
/// than for their happy path: a cancelled fade must not land a stale value on
/// top of a newer target, and a pool must actually stop allocating.
void main() {
  group('a mix fade ramps and is cancellable', () {
    test('no fade keeps the instantaneous behaviour callers rely on', () async {
      final probe = _VolumeProbe();
      final mixer = RuntimeAudioMixer(fadeDelay: probe.delay);
      await mixer.register(
        channel: 'music',
        route: RuntimeAudioRoute.title,
        setVolume: probe.set,
      );
      probe.clear();

      await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0.5));

      expect(
        probe.volumes,
        <double>[0.5],
        reason: 'a zero-duration transition must still be one write, or every '
            'existing caller changes behaviour',
      );
      expect(mixer.isFading, isFalse);
    });

    test('a fade writes the intermediate volumes, not a jump', () async {
      final probe = _VolumeProbe();
      final mixer = RuntimeAudioMixer(fadeDelay: probe.delay, fadeSteps: 4);
      await mixer.register(
        channel: 'music',
        route: RuntimeAudioRoute.title,
        setVolume: probe.set,
      );
      probe.clear();

      final fading = mixer.transitionTo(
        const RuntimeAudioMix(masterVolume: 0),
        fade: const Duration(milliseconds: 400),
      );
      await probe.releaseAll();
      await fading;

      expect(probe.volumes, <double>[0.75, 0.5, 0.25, 0.0]);
      expect(
        mixer.mix.masterVolume,
        0,
        reason: 'a completed fade settles exactly on its target',
      );
      expect(mixer.isFading, isFalse);
    });

    test('the next transition supersedes a fade in flight', () async {
      final probe = _VolumeProbe();
      final mixer = RuntimeAudioMixer(fadeDelay: probe.delay, fadeSteps: 4);
      await mixer.register(
        channel: 'music',
        route: RuntimeAudioRoute.title,
        setVolume: probe.set,
      );
      probe.clear();

      // Start a long fade to silence, let one step land, then cut to full.
      final fading = mixer.transitionTo(
        const RuntimeAudioMix(masterVolume: 0),
        fade: const Duration(milliseconds: 400),
      );
      await probe.releaseOneStep();
      await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 1));
      await probe.releaseAll();
      await fading;

      expect(
        mixer.mix.masterVolume,
        1,
        reason: 'the superseded ramp must not land a stale step on top of the '
            'newer target — that is the double-player bug',
      );
      expect(
        probe.volumes.last,
        1,
        reason: 'the LAST write wins, and it is the new target',
      );
      expect(
        probe.volumes.where((volume) => volume < 0.75).length,
        0,
        reason: 'the cancelled ramp stopped writing immediately rather than '
            'continuing towards silence',
      );
    });

    test('cancelFade stops where it got to instead of jumping', () async {
      final probe = _VolumeProbe();
      final mixer = RuntimeAudioMixer(fadeDelay: probe.delay, fadeSteps: 4);
      await mixer.register(
        channel: 'music',
        route: RuntimeAudioRoute.title,
        setVolume: probe.set,
      );
      probe.clear();

      final fading = mixer.transitionTo(
        const RuntimeAudioMix(masterVolume: 0),
        fade: const Duration(milliseconds: 400),
      );
      await probe.releaseOneStep();
      mixer.cancelFade();
      await probe.releaseAll();
      await fading;

      expect(
        mixer.mix.masterVolume,
        0.75,
        reason: 'a cancel that jumped to the target would be indistinguishable '
            'from having no fade at all',
      );
      expect(mixer.isFading, isFalse);
      expect(probe.volumes, <double>[0.75]);
    });

    test('two fades in a row never overlap', () async {
      final probe = _VolumeProbe();
      final mixer = RuntimeAudioMixer(fadeDelay: probe.delay, fadeSteps: 4);
      await mixer.register(
        channel: 'music',
        route: RuntimeAudioRoute.title,
        setVolume: probe.set,
      );
      probe.clear();

      final first = mixer.transitionTo(
        const RuntimeAudioMix(masterVolume: 0),
        fade: const Duration(milliseconds: 400),
      );
      await probe.releaseOneStep();
      final second = mixer.transitionTo(
        const RuntimeAudioMix(masterVolume: 0.5),
        fade: const Duration(milliseconds: 400),
      );
      await probe.releaseAll();
      await first;
      await second;

      // From 0.75 (where the first ramp got to) down to 0.5 in four steps.
      expect(probe.volumes, <double>[0.75, 0.6875, 0.625, 0.5625, 0.5]);
      expect(mixer.mix.masterVolume, 0.5);
    });
  });

  group('frequent sound effects come out of a pool', () {
    test('replaying one source stops allocating players', () async {
      final driver = _RecordingDriver();
      final pool = RuntimeSfxPool(driver: driver, voicesPerSource: 2);
      final source = Uri.parse('file:///sfx/blip.ogg');

      for (var shot = 0; shot < 20; shot += 1) {
        final handle = await pool.play(
          source,
          volume: 1,
          loop: false,
          position: Duration.zero,
        );
        await pool.stop(handle);
      }

      expect(
        pool.allocatedVoiceCount,
        1,
        reason: 'twenty shots of the same sound, played and released one at a '
            'time, need exactly one player',
      );
      expect(
        driver.disposed,
        isEmpty,
        reason: 'a released voice is kept, not torn down — that is the whole '
            'point',
      );
    });

    test('concurrent shots allocate up to the cap and no further', () async {
      final driver = _RecordingDriver();
      final pool = RuntimeSfxPool(driver: driver, voicesPerSource: 3);
      final source = Uri.parse('file:///sfx/step.ogg');

      final handles = <Object>[];
      for (var shot = 0; shot < 10; shot += 1) {
        handles.add(
          await pool.play(
            source,
            volume: 1,
            loop: false,
            position: Duration.zero,
          ),
        );
      }

      expect(pool.allocatedVoiceCount, 3);
      expect(
        handles.toSet().length,
        3,
        reason: 'past the cap the oldest voice is stolen, so the same three '
            'handles keep coming back',
      );
      expect(pool.busyVoiceCount(source), 3);
    });

    test('different sources do not share voices', () async {
      final driver = _RecordingDriver();
      final pool = RuntimeSfxPool(driver: driver, voicesPerSource: 2);
      final blip = Uri.parse('file:///sfx/blip.ogg');
      final step = Uri.parse('file:///sfx/step.ogg');

      final first = await pool.play(
        blip,
        volume: 1,
        loop: false,
        position: Duration.zero,
      );
      await pool.stop(first);
      final second = await pool.play(
        step,
        volume: 1,
        loop: false,
        position: Duration.zero,
      );

      expect(
        second,
        isNot(first),
        reason: 'reusing a blip voice to play a footstep would play the wrong '
            'sound',
      );
      expect(pool.allocatedVoiceCount, 2);
      expect(pool.idleVoiceCount(blip), 1);
    });

    test('a loop is never pooled', () async {
      final driver = _RecordingDriver();
      final pool = RuntimeSfxPool(driver: driver, voicesPerSource: 2);
      final music = Uri.parse('file:///music/bed.ogg');

      final handle = await pool.play(
        music,
        volume: 1,
        loop: true,
        position: Duration.zero,
      );
      await pool.stop(handle);

      expect(
        driver.disposed,
        <Object>[handle],
        reason: 'a loop holds its voice for its whole life, so pooling it '
            'would make it reusable while still playing',
      );
      expect(pool.idleVoiceCount(music), 0);
    });

    test('dispose releases the voices the pool was holding', () async {
      final driver = _RecordingDriver();
      final pool = RuntimeSfxPool(driver: driver, voicesPerSource: 2);
      final source = Uri.parse('file:///sfx/blip.ogg');

      final busy = await pool.play(
        source,
        volume: 1,
        loop: false,
        position: Duration.zero,
      );
      final released = await pool.play(
        source,
        volume: 1,
        loop: false,
        position: Duration.zero,
      );
      await pool.stop(released);

      await pool.dispose();

      expect(
        driver.disposed.toSet(),
        <Object>{busy, released},
        reason: 'a pool that kept its idle voices on dispose would be a leak '
            'with a nicer name',
      );
      expect(
        () => pool.play(
          source,
          volume: 1,
          loop: false,
          position: Duration.zero,
        ),
        throwsStateError,
      );
    });

    test('dispose is idempotent', () async {
      final driver = _RecordingDriver();
      final pool = RuntimeSfxPool(driver: driver);
      final handle = await pool.play(
        Uri.parse('file:///sfx/blip.ogg'),
        volume: 1,
        loop: false,
        position: Duration.zero,
      );
      await pool.stop(handle);

      await pool.dispose();
      await pool.dispose();

      expect(driver.disposed, <Object>[handle]);
    });
  });
}

/// Records every volume the mixer writes and hands out the fade steps on
/// demand, so a ramp is inspected step by step instead of raced against a
/// clock.
/// Records every volume the mixer writes and hands out the fade steps on
/// demand, so a ramp is inspected step by step instead of raced against a
/// clock.
final class _VolumeProbe {
  final List<double> volumes = <double>[];
  final List<Completer<void>> _pending = <Completer<void>>[];

  Future<void> set(double volume) async => volumes.add(volume);

  Future<void> delay(Duration duration) {
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void clear() => volumes.clear();

  Future<void> releaseOneStep() async {
    if (_pending.isEmpty) return;
    _pending.removeAt(0).complete();
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> releaseAll() async {
    var guard = 0;
    while (_pending.isNotEmpty && guard < 64) {
      _pending.removeAt(0).complete();
      await Future<void>.delayed(Duration.zero);
      guard += 1;
    }
  }
}

final class _RecordingDriver implements RuntimePresentationAudioDriver {
  final List<Object> disposed = <Object>[];
  var _next = 0;

  @override
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
  }) async =>
      'voice-${_next++}';

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> resume(Object handle) async {}

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async => disposed.add(handle);
}
