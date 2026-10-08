import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

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

abstract interface class CinematicSpatialWorkspaceVisuals {
  Future<CinematicSpatialPreview> cinematicSpatialPreview(
    MapData map,
    CinematicActorDisplayPreviewModel actors,
  );
}

final class CinematicSpatialPreview {
  const CinematicSpatialPreview(this.frames, this.dispose);
  final Map<String, SpatialActorVisual> Function(
    CinematicAsset asset,
    CinematicPreviewPlaybackPlan? plan,
    CinematicPreviewPlaybackFrame? frame,
    int timeMs,
  ) frames;
  final VoidCallback dispose;
}
