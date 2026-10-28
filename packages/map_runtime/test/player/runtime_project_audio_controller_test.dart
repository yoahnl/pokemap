import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_project_audio_controller.dart';

import '../support/project_audio_test_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('initial source gain includes effects ducking before native playback starts', () async {
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(masterVolume: .5, effectsVolume: .4),
    );
    await mixer.setDucking(
      owner: 'silent-cinematic',
      bus: RuntimeAudioBus.effects,
      gain: 0,
    );
    final driver = ProjectAudioTestDriver();
    final audio = RuntimeProjectAudioController(mixer: mixer, driver: driver);
    await audio.play(ProjectSoundCue.overworldJump);
    expect(driver.startingVolumes, [0]);
    expect(driver.volumes[1], 0);
    await audio.dispose();
  });
  test('every declared cue has a packaged builtin source', () async {
    expect(
      RuntimeProjectAudioController.builtinPaths.keys.toSet(),
      ProjectSoundCue.values.toSet(),
    );
    for (final path
        in RuntimeProjectAudioController.builtinPaths.values.toSet()) {
      expect(
        (await rootBundle.load(path)).lengthInBytes,
        greaterThan(0),
        reason: path,
      );
    }
  });
  test(
    'backend teardown errors do not strand the remaining owned channels',
    () async {
      final driver = ProjectAudioTestDriver();
      final audio = RuntimeProjectAudioController(
        mixer: RuntimeAudioMixer(),
        driver: driver,
      );
      await audio.play(ProjectSoundCue.overworldJump);
      await audio.play(ProjectSoundCue.overworldJump);
      driver.failStop = true;
      await audio.stopAll();
      expect(driver.stopped, {1, 2});
      expect(audio.lastFailure, isA<StateError>());
      expect(audio.isPlaying(ProjectSoundCue.overworldJump), isFalse);
      driver.failStop = false;
      expect(await audio.play(ProjectSoundCue.overworldJump), isTrue);
      await audio.dispose();
      expect(driver.stopped, {1, 2, 3});
    },
  );
  test(
    'suspending during native startup rejects and releases its late voice',
    () async {
      final driver = ProjectAudioTestDriver()..gate = Completer<void>();
      final audio = RuntimeProjectAudioController(
        mixer: RuntimeAudioMixer(),
        driver: driver,
      );
      final playing = audio.play(ProjectSoundCue.overworldJump);
      await Future<void>.delayed(Duration.zero);
      final suspended = audio.setSuspended(true);
      driver.gate!.complete();
      expect(await playing, isFalse);
      await suspended;
      expect(driver.stopped, {1});
      expect(audio.isPlaying(ProjectSoundCue.overworldJump), isFalse);
      await audio.dispose();
    },
  );
  test(
    'a failed voice replay releases its native handle and can recover',
    () async {
      final driver = ProjectAudioTestDriver();
      final audio = RuntimeProjectAudioController(
        mixer: RuntimeAudioMixer(),
        driver: driver,
        voicesPerCue: 1,
      );
      expect(await audio.play(ProjectSoundCue.overworldJump), isTrue);
      driver.complete(1);
      driver.failReplay = true;
      expect(await audio.play(ProjectSoundCue.overworldJump), isFalse);
      expect(audio.lastFailure, isA<StateError>());
      expect(driver.stopped, {1});
      expect(await audio.play(ProjectSoundCue.overworldJump), isTrue);
      expect(driver.paths, hasLength(2));
      await audio.dispose();
      expect(driver.stopped, {1, 2});
    },
  );
  test('mixes source gain once and replays completed voices through the existing driver', () async {
    final driver = ProjectAudioTestDriver();
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(masterVolume: .5, effectsVolume: .4),
    );
    final audio = RuntimeProjectAudioController(
      mixer: mixer,
      driver: driver,
      settings: ProjectAudioSettings(
        cues: {
          ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
            source: ProjectSoundSource.custom,
            mediaId: 'confirm',
            gain: .5,
          ),
        },
      ),
      resolveMedia: (_) => const RuntimeProjectAudioFile(
        path: '/project/confirm.wav',
        mimeType: 'audio/wav',
      ),
    );
    expect(await audio.play(ProjectSoundCue.uiConfirm, sourceGain: .5), isTrue);
    expect(driver.volumes.values.single, closeTo(.05, .00001));
    driver.complete(1);
    expect(await audio.play(ProjectSoundCue.uiConfirm, sourceGain: .5), isTrue);
    expect(driver.paths, hasLength(1));
    expect(driver.replays, 1);
    await mixer.transitionTo(
      const RuntimeAudioMix(masterVolume: .5, effectsVolume: .2),
    );
    expect(driver.volumes.values.single, closeTo(.025, .00001));
    await audio.dispose();
  });
  test(
    'bounds voices, suspends playback and releases every owned channel',
    () async {
      final driver = ProjectAudioTestDriver();
      final audio = RuntimeProjectAudioController(
        mixer: RuntimeAudioMixer(),
        driver: driver,
        voicesPerCue: 2,
        settings: ProjectAudioSettings(
          cues: {
            ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
              source: ProjectSoundSource.builtin,
            ),
          },
        ),
      );
      await audio.play(ProjectSoundCue.uiConfirm);
      await audio.play(ProjectSoundCue.uiConfirm);
      expect(await audio.play(ProjectSoundCue.uiConfirm), isFalse);
      expect(driver.paths, hasLength(2));
      await audio.setSuspended(true);
      expect(driver.paused, {1, 2});
      expect(await audio.play(ProjectSoundCue.uiConfirm), isFalse);
      await audio.setSuspended(false);
      expect(driver.paused, isEmpty);
      await audio.dispose();
      expect(driver.stopped, {1, 2});
    },
  );
  test('silent, duplicate and missing custom sources never fall back to an unrelated sound', () async {
    final driver = ProjectAudioTestDriver();
    final audio = RuntimeProjectAudioController(
      mixer: RuntimeAudioMixer(),
      driver: driver,
      settings: ProjectAudioSettings(
        cues: {
          ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
            source: ProjectSoundSource.custom,
            mediaId: 'missing',
          ),
          ProjectSoundCue.uiSelect: const ProjectSoundBinding(
            source: ProjectSoundSource.builtin,
          ),
        },
      ),
    );
    expect(await audio.play(ProjectSoundCue.uiConfirm), isFalse);
    expect(audio.lastFailure, isNotNull);
    expect(await audio.play(ProjectSoundCue.uiCancel), isFalse);
    expect(await audio.play(ProjectSoundCue.uiSelect, eventId: 'one'), isTrue);
    expect(await audio.play(ProjectSoundCue.uiSelect, eventId: 'one'), isFalse);
    expect(driver.paths, hasLength(1));
    await audio.dispose();
  });
  test(
    'reports completion and invalidates queued preview playback on stop',
    () async {
      final driver = ProjectAudioTestDriver();
      var changes = 0;
      final audio = RuntimeProjectAudioController(
        mixer: RuntimeAudioMixer(),
        driver: driver,
        onPlaybackChanged: () => changes++,
      );
      expect(await audio.play(ProjectSoundCue.overworldJump), isTrue);
      expect(audio.isPlaying(ProjectSoundCue.overworldJump), isTrue);
      driver.complete(1);
      expect(audio.isPlaying(ProjectSoundCue.overworldJump), isFalse);
      expect(changes, 2);
      final queued = audio.play(ProjectSoundCue.overworldJump);
      await audio.stopAll();
      expect(await queued, isFalse);
      expect(audio.isPlaying(ProjectSoundCue.overworldJump), isFalse);
      expect(driver.paths, hasLength(1));
      await audio.dispose();
    },
  );
  test('stopping a preview rejects its late native handle', () async {
    final driver = ProjectAudioTestDriver()..gate = Completer<void>();
    final audio = RuntimeProjectAudioController(
      mixer: RuntimeAudioMixer(),
      driver: driver,
    );
    final playing = audio.play(ProjectSoundCue.overworldJump);
    await Future<void>.delayed(Duration.zero);
    final stopping = audio.stopAll();
    driver.gate!.complete();
    expect(await playing, isFalse);
    await stopping;
    expect(driver.stopped, {1});
    expect(audio.isPlaying(ProjectSoundCue.overworldJump), isFalse);
    await audio.dispose();
  });
  test(
    'disposal rejects a playback that completes after its owner closes',
    () async {
      final driver = ProjectAudioTestDriver()..gate = Completer<void>();
      final audio = RuntimeProjectAudioController(
        mixer: RuntimeAudioMixer(),
        driver: driver,
      );
      final playing = audio.play(ProjectSoundCue.overworldJump);
      await Future<void>.delayed(Duration.zero);
      final closing = audio.dispose();
      driver.gate!.complete();
      expect(await playing, isFalse);
      await closing;
      expect(driver.stopped, {1});
    },
  );
}
