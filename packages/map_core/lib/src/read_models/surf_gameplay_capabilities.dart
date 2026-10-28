import '../models/enums.dart';
import '../models/project_manifest.dart';

abstract final class SurfGameplayCapabilities {
  static const capabilityId = 'gameplay.surf@1';

  static const animationStates = {
    CharacterAnimationState.surfIdle,
    CharacterAnimationState.surf,
    CharacterAnimationState.surfEnter,
    CharacterAnimationState.surfExit,
  };

  static bool requiresCapability(ProjectManifest project) =>
      project.settings.surf != null ||
      project.characters.any(
        (character) => character.animations.any(
          (animation) => animationStates.contains(animation.state),
        ),
      );
}
