import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';

abstract final class SurfGameplayCapabilities {
  static const capabilityId = 'gameplay.surf@1';

  static const animationStates = {
    CharacterAnimationState.surfIdle,
    CharacterAnimationState.surf,
    CharacterAnimationState.surfEnter,
    CharacterAnimationState.surfExit,
  };

  static bool requiresCapability(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) =>
      project.settings.surf != null ||
      project.characters.any(
        (character) => character.animations.any(
          (animation) => animationStates.contains(animation.state),
        ),
      ) ||
      maps.any(
        (map) =>
            map.spatialScene != null &&
            map.gameplayZones.any(
              (zone) =>
                  zone.kind == GameplayZoneKind.movement &&
                  (zone.movement?.requiredMode == MovementMode.surf ||
                      zone.movement?.allowedModes.contains(MovementMode.surf) ==
                          true),
            ),
      );
}
