import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

CinematicAsset spatialTrainerSpotCinematic(
  String mapId,
  SpatialTrainerSpot spot,
) {
  final distance = math.sqrt(
    math.pow(spot.targetX - spot.origin.x, 2) +
        math.pow(spot.targetZ - spot.origin.z, 2),
  );
  return CinematicAsset(
    id: 'runtime-trainer-spot',
    title: 'Trainer approach',
    mapId: mapId,
    requiredActors: [
      CinematicActorRef(actorId: 'trainer'),
      CinematicActorRef(actorId: 'player'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(targetId: 'contact', label: 'Contact'),
    ],
    stageContext: CinematicStageContext(
      actorBindings: [
        CinematicActorBinding(
          actorId: 'trainer',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: spot.entity.id,
        ),
        CinematicActorBinding(
          actorId: 'player',
          kind: CinematicActorBindingKind.player,
        ),
      ],
      stagePoints: [
        CinematicStagePoint(
          id: 'contact-point',
          label: 'Contact',
          x: spot.targetX,
          y: spot.targetZ,
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'contact',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'contact-point',
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'notice',
          kind: CinematicTimelineStepKind.actorEmote,
          actorId: 'trainer',
          durationMs: 500,
          metadata: const {'actor.emoteId': 'exclamation'},
        ),
        if (distance > .001)
          CinematicTimelineStep(
            id: 'approach',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'trainer',
            targetId: 'contact',
            durationMs: math.max(1, (distance / 3 * 1000).round()),
            metadata: const {
              'actor.movementMode': 'walk',
              'actor.pathMode': 'direct',
              'actor.facingMode': 'preserve',
            },
          ),
        CinematicTimelineStep(
          id: 'face',
          kind: CinematicTimelineStepKind.actorFace,
          actorId: 'player',
          durationMs: 100,
          metadata: {
            'actor.direction': switch (spot.playerFacing) {
              EntityFacing.north => 'up',
              EntityFacing.south => 'down',
              EntityFacing.east => 'right',
              EntityFacing.west => 'left',
            },
          },
        ),
      ],
    ),
  );
}
