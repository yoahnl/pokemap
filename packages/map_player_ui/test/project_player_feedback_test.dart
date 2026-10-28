import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../map_runtime/test/support/project_audio_test_driver.dart';

void main() {
  test(
    'project feedback deduplicates and applies the global volume once',
    () async {
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
              mediaId: 'bell',
              gain: .5,
            ),
          },
        ),
        resolveMedia: (_) => const RuntimeProjectAudioFile(path: '/bell.wav'),
      );
      final controller = PlayerFeedbackController(
        port: ProjectPlayerFeedbackPort(audio: () => audio),
      );
      const event = PlayerFeedbackEvent(
        id: 'confirm:1',
        sound: PlayerFeedbackSound.confirm,
      );
      const preferences = PlayerPreferences(
        masterVolume: .5,
        effectsVolume: .4,
      );
      await controller.handle(event, preferences);
      await controller.handle(event, preferences);
      expect(driver.paths, ['/bell.wav']);
      expect(driver.volumes.values.single, closeTo(.1, .00001));
      await audio.dispose();
    },
  );
  test(
    'legacy unspecified, silent, zero mix and battle effects stay silent',
    () async {
      final driver = ProjectAudioTestDriver();
      final mixer = RuntimeAudioMixer();
      final audio = RuntimeProjectAudioController(mixer: mixer, driver: driver);
      final port = ProjectPlayerFeedbackPort(audio: () => audio);
      await port.playSound(PlayerFeedbackSound.confirm, 1);
      expect(driver.paths, isEmpty);
      audio.settings = ProjectAudioSettings(
        cues: {
          ProjectSoundCue.uiCancel: const ProjectSoundBinding(
            source: ProjectSoundSource.builtin,
          ),
          ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
            source: ProjectSoundSource.silent,
          ),
        },
      );
      await port.playSound(PlayerFeedbackSound.cancel, 1);
      expect(driver.paths, hasLength(1));
      await port.playSound(PlayerFeedbackSound.confirm, 1);
      await port.playSound(PlayerFeedbackSound.battleImpact, 1);
      await port.playSound(PlayerFeedbackSound.victory, 1);
      await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0));
      await port.playSound(PlayerFeedbackSound.cancel, 1);
      await port.playSound(PlayerFeedbackSound.cancel, 0);
      expect(driver.paths, hasLength(1));
      await audio.dispose();
    },
  );
}
