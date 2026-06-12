import 'package:map_core/map_core.dart';

/// Builds the actor display model used by the preview overlay during local
/// editor playback.
///
/// V1-112 deliberately keeps movement calculation in `map_core`: this adapter
/// only reads `CinematicPreviewPlaybackFrame.actorPoses` and copies those
/// positions into the existing actor display model consumed by the overlay.
CinematicActorDisplayPreviewModel?
    buildCinematicPreviewPlaybackActorOverlayModel({
  required CinematicActorDisplayPreviewModel? displayModel,
  required CinematicPreviewPlaybackFrame? playbackFrame,
}) {
  if (displayModel == null || playbackFrame == null) {
    return displayModel;
  }

  final actors = <CinematicActorDisplayPreviewActor>[];
  for (final actor in displayModel.actors) {
    final pose = playbackFrame.actorPoseById(actor.actorId);
    if (pose == null || !pose.hasPosition) {
      actors.add(actor);
      continue;
    }

    // The existing actor overlay is tile-anchored and consumes integer display
    // positions. We still consume the playback pose as the source of truth, but
    // project it into the current overlay contract instead of introducing a
    // second renderer in this lot.
    actors.add(
      CinematicActorDisplayPreviewActor(
        actorId: actor.actorId,
        label: actor.label,
        role: actor.role,
        bindingStatus: actor.bindingStatus,
        bindingKind: actor.bindingKind,
        bindingSourceId: actor.bindingSourceId,
        bindingSourceLabel: actor.bindingSourceLabel,
        position: CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: actor.position.sourceKind,
          x: pose.x!.round(),
          y: pose.y!.round(),
          sourceId: actor.position.sourceId,
          sourceLabel: actor.position.sourceLabel,
        ),
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

  return CinematicActorDisplayPreviewModel(
    status: displayModel.status,
    summary: displayModel.summary,
    actors: actors,
    diagnostics: displayModel.diagnostics,
  );
}
