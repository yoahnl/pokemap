import 'package:map_core/map_core.dart';

/// Builds the actor display model used by the preview overlay during local
/// editor playback.
///
/// Movement calculation stays in `map_core`: this adapter only reads
/// `CinematicPreviewPlaybackFrame.actorPoses` and exposes sub-tile playback
/// coordinates to the overlay without recalculating or snapping them.
final class CinematicActorPlaybackOverlayPose {
  const CinematicActorPlaybackOverlayPose({
    required this.actorId,
    required this.x,
    required this.y,
  });

  final String actorId;
  final double x;
  final double y;
}

final class CinematicActorPlaybackOverlayModel {
  CinematicActorPlaybackOverlayModel({
    required this.displayModel,
    required Map<String, CinematicActorPlaybackOverlayPose> poseOverrides,
  }) : poseOverrides =
            Map<String, CinematicActorPlaybackOverlayPose>.unmodifiable(
          poseOverrides,
        );

  final CinematicActorDisplayPreviewModel displayModel;
  final Map<String, CinematicActorPlaybackOverlayPose> poseOverrides;
}

CinematicActorPlaybackOverlayModel?
    buildCinematicPreviewPlaybackActorOverlayModel({
  required CinematicActorDisplayPreviewModel? displayModel,
  required CinematicPreviewPlaybackFrame? playbackFrame,
}) {
  if (displayModel == null || playbackFrame == null) {
    return null;
  }

  final actors = <CinematicActorDisplayPreviewActor>[];
  final poseOverrides = <String, CinematicActorPlaybackOverlayPose>{};
  for (final actor in displayModel.actors) {
    final pose = playbackFrame.actorPoseById(actor.actorId);
    if (pose == null) {
      actors.add(actor);
      continue;
    }
    if (pose.hasPosition) {
      poseOverrides[actor.actorId] = CinematicActorPlaybackOverlayPose(
        actorId: actor.actorId,
        x: pose.x!,
        y: pose.y!,
      );
    }

    actors.add(
      CinematicActorDisplayPreviewActor(
        actorId: actor.actorId,
        label: actor.label,
        role: actor.role,
        bindingStatus: actor.bindingStatus,
        bindingKind: actor.bindingKind,
        bindingSourceId: actor.bindingSourceId,
        bindingSourceLabel: actor.bindingSourceLabel,
        position: actor.position,
        appearance: actor.appearance,
        direction: pose.facing == CinematicActorPreviewDirection.unknown
            ? actor.direction
            : pose.facing,
        directionSource: pose.facing == CinematicActorPreviewDirection.unknown
            ? actor.directionSource
            : CinematicActorPreviewDirectionSource.actorFace,
        renderHint: actor.renderHint,
        diagnostics: actor.diagnostics,
      ),
    );
  }

  return CinematicActorPlaybackOverlayModel(
    displayModel: CinematicActorDisplayPreviewModel(
      status: displayModel.status,
      summary: displayModel.summary,
      actors: actors,
      diagnostics: displayModel.diagnostics,
    ),
    poseOverrides: poseOverrides,
  );
}
