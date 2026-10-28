import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_project_audio_controller.dart';

import '../support/project_audio_test_driver.dart';

import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_brazier_audio_controller.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test(
    'custom fire follows the existing ambience lifecycle and binding gain',
    () async {
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(masterVolume: .5, effectsVolume: .4),
      );
      final driver = ProjectAudioTestDriver();
      final projectAudio = RuntimeProjectAudioController(
        mixer: mixer,
        driver: ProjectAudioTestDriver(),
        settings: ProjectAudioSettings(
          cues: {
            ProjectSoundCue.fireCrackle: const ProjectSoundBinding(
              source: ProjectSoundSource.custom,
              mediaId: 'fire',
              gain: .5,
            ),
          },
        ),
        resolveMedia: (_) => const RuntimeProjectAudioFile(
          path: '/project/fire.ogg',
          mimeType: 'audio/ogg',
        ),
      );
      final fire = RuntimeBrazierAudioController(
        mixer: mixer,
        driver: driver,
        projectAudio: projectAudio,
      );
      await fire.update(.4);
      expect(driver.paths, ['/project/fire.ogg']);
      expect(driver.volumes[1], closeTo(.04, .00001));
      for (var i = 0; i < 2000; i++) await fire.update(.4);
      expect(driver.paths, hasLength(1));
      await fire.setSuspended(true);
      expect(driver.paused, {1});
      await fire.setSuspended(false);
      expect(driver.paused, isEmpty);
      await fire.update(0);
      expect(driver.stopped, {1});
      await fire.dispose();
      await projectAudio.dispose();
    },
  );
  test(
    'one ambience voice follows audible flames and releases on day or disposal',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer();
      var musicGain = .8;
      await mixer.register(
        channel: 'music-proof',
        route: RuntimeAudioRoute.overworld,
        sourceVolume: .8,
        setVolume: (value) async => musicGain = value,
      );
      final audio = RuntimeBrazierAudioController(mixer: mixer, driver: driver);
      await audio.update(.65);
      expect(driver.starts, 1);
      for (var i = 0; i < 30; i++) {
        await audio.update(.65);
      }
      expect(driver.starts, 1);
      expect(musicGain, .8);
      await audio.setSuspended(true);
      expect(driver.pauses, 1);
      await audio.setSuspended(false);
      expect(driver.resumes, 1);
      await audio.update(0);
      expect(driver.stops, 1);
      await audio.update(.4);
      expect(driver.starts, 2);
      await audio.dispose();
      expect(driver.stops, 2);
      expect(audio.lastFailure, isNull);
      expect(musicGain, .8);
    },
  );
}

class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  int starts = 0, stops = 0, pauses = 0, resumes = 0;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    starts++;
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double value) async {}
  @override
  Future<void> stop(Object handle) async {
    stops++;
  }

  @override
  Future<void> pause(Object handle) async {
    pauses++;
  }

  @override
  Future<void> resume(Object handle) async {
    resumes++;
  }
}
