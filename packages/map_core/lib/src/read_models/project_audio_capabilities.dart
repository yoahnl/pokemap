import '../models/project_manifest.dart';
import '../models/project_audio_settings.dart';

abstract final class ProjectAudioCapabilities {
  static const capabilityId = 'audio.project-sfx@1';
  static const extendedCapabilityId = 'audio.project-sfx@2';

  static const extendedCues = {
    ProjectSoundCue.fieldFly, ProjectSoundCue.fieldStrength,
    ProjectSoundCue.fieldFlash, ProjectSoundCue.fieldRockSmash,
    ProjectSoundCue.fieldWaterfall, ProjectSoundCue.fieldWhirlpool,
    ProjectSoundCue.fieldDive, ProjectSoundCue.fieldRockClimb,
    ProjectSoundCue.fieldDefog,
  };

  static bool requiresCapability(ProjectManifest project) =>
      project.settings.audio?.cues.isNotEmpty ?? false;

  static bool requiresExtendedCapability(ProjectManifest project) =>
      project.settings.audio?.cues.keys.any(extendedCues.contains) ?? false;
}
