import '../models/project_manifest.dart';

abstract final class ProjectAudioCapabilities {
  static const capabilityId = 'audio.project-sfx@1';

  static bool requiresCapability(ProjectManifest project) =>
      project.settings.audio?.cues.isNotEmpty ?? false;
}
