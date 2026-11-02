import '../models/project_manifest.dart';

abstract final class CharacterAnimationCanvasCapabilities {
  static const capabilityId = 'character.animation-canvas@1';

  static bool requiresCapability(ProjectManifest project) =>
      project.characters.any(
        (character) =>
            character.animations.any(
              (clip) => clip.presentationReferenceHeightPx != null,
            ) ||
            character.customAnimations.any(
              (clip) => clip.presentationReferenceHeightPx != null,
            ),
      );
}
