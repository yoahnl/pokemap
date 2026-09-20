import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';

({CharacterAnimationState state, int elapsedMs}) cinematicActorAnimation(
  CinematicAsset asset,
  CinematicPreviewTransport transport,
  String actorId,
  bool moving,
) {
  final pose = transport.frame?.actorPoseById(actorId);
  final step = asset.timeline.steps
      .where((s) => s.id == pose?.activeStepId)
      .firstOrNull;
  final item = transport.plan?.timelineItems
      .where((s) => s.stepId == step?.id)
      .firstOrNull;
  return (
    state: !moving
        ? CharacterAnimationState.idle
        : step != null &&
              cinematicTimelineActorMovementModeOf(step) ==
                  CinematicTimelineActorMovementMode.run
        ? CharacterAnimationState.run
        : CharacterAnimationState.walk,
    elapsedMs: moving && item != null ? transport.timeMs - item.startMs : 0,
  );
}
