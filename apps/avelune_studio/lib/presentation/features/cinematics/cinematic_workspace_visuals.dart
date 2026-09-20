import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

abstract interface class CinematicMediaWorkspaceVisuals {
  CinematicMediaPlaybackPort createCinematicMedia(ProjectManifest project);
}

abstract interface class CinematicWorkspaceVisuals {
  Widget cinematicActor(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
    CharacterAnimationState animationState = CharacterAnimationState.idle,
    int elapsedMs = 0,
    CharacterCustomAnimationClip? customAnimation,
  });
}
