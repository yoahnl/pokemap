import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_feedback.dart';

final class ProjectPlayerFeedbackPort implements PlayerFeedbackPort {
  const ProjectPlayerFeedbackPort({required this.audio, this.haptics});
  final RuntimeProjectAudioController? Function() audio;
  final Future<void> Function(PlayerFeedbackHaptic)? haptics;

  @override
  Future<void> playSound(PlayerFeedbackSound sound, double volume) async {
    final controller = audio();
    if (controller == null || !volume.isFinite || volume <= 0) return;
    final mix = controller.mixer.mix;
    final bus = mix.masterVolume * mix.effectsVolume;
    if (bus <= 0) return;
    final cue = switch (sound) {
      PlayerFeedbackSound.select => ProjectSoundCue.uiSelect,
      PlayerFeedbackSound.confirm => ProjectSoundCue.uiConfirm,
      PlayerFeedbackSound.cancel => ProjectSoundCue.uiCancel,
      PlayerFeedbackSound.dialogue => ProjectSoundCue.dialogueAdvance,
      PlayerFeedbackSound.notification => ProjectSoundCue.notification,
      PlayerFeedbackSound.error => ProjectSoundCue.uiError,
      PlayerFeedbackSound.battleImpact || PlayerFeedbackSound.victory => null,
    };
    if (cue != null) {
      await controller.play(cue, sourceGain: (volume / bus).clamp(0, 1));
    }
  }

  @override
  Future<void> performHaptic(PlayerFeedbackHaptic haptic) async {
    await haptics?.call(haptic);
  }
}
