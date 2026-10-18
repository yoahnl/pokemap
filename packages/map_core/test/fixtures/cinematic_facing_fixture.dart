import 'package:map_core/map_core.dart';

CinematicAsset facingCinematic({
  String? facingMode = 'preserve',
  String direction = 'left',
  double destinationX = 12,
  double destinationY = 8,
  bool manual = false,
  bool secondMove = false,
}) => CinematicAsset(
  id: 'facing-scene',
  title: 'Facing fixture',
  mapId: 'room',
  requiredActors: [CinematicActorRef(actorId: 'actor')],
  movementTargets: [
    CinematicMovementTargetRef(targetId: 'destination', label: 'Destination'),
  ],
  stageContext: CinematicStageContext(
    actorBindings: [
      CinematicActorBinding(
        actorId: 'actor',
        kind: CinematicActorBindingKind.player,
      ),
    ],
    initialPlacements: [
      CinematicActorInitialPlacement(
        actorId: 'actor',
        kind: CinematicActorInitialPlacementKind.stagePoint,
        stagePointId: 'start',
      ),
    ],
    stagePoints: [
      CinematicStagePoint(id: 'start', label: 'Start', x: 8, y: 8),
      CinematicStagePoint(id: 'corner', label: 'Corner', x: 12, y: 8),
      CinematicStagePoint(
        id: 'destination',
        label: 'Destination',
        x: destinationX,
        y: destinationY,
      ),
    ],
    movementTargetBindings: [
      CinematicMovementTargetBinding(
        targetId: 'destination',
        kind: CinematicMovementTargetBindingKind.stagePoint,
        sourceId: 'destination',
      ),
    ],
    manualPaths: manual
        ? [
            CinematicManualPath(
              id: 'path',
              label: 'Route',
              ownerActorMoveStepId: 'move',
              waypointStagePointIds: ['corner'],
            ),
          ]
        : [],
  ),
  timeline: CinematicTimeline(
    steps: [
      facingStep('face', direction),
      CinematicTimelineStep(
        id: 'move',
        kind: CinematicTimelineStepKind.actorMove,
        actorId: 'actor',
        targetId: 'destination',
        durationMs: 1000,
        metadata: {
          'authoring.kind': 'basicBlock',
          'authoring.source': 'cinematic-builder-v0',
          'authoring.block': 'actorMove',
          'actor.movementMode': 'walk',
          'actor.pathMode': manual ? 'manual' : 'direct',
          'actor.facingMode': ?facingMode,
        },
      ),
      if (secondMove) ...[
        facingStep('face-next', 'up'),
        CinematicTimelineStep(
          id: 'move-next',
          kind: CinematicTimelineStepKind.actorMove,
          actorId: 'actor',
          targetId: 'destination',
          durationMs: 1000,
          metadata: {
            'authoring.kind': 'basicBlock',
            'authoring.source': 'cinematic-builder-v0',
            'authoring.block': 'actorMove',
            'actor.movementMode': 'run',
            'actor.pathMode': 'direct',
            'actor.facingMode': 'preserve',
          },
        ),
      ],
    ],
  ),
);

CinematicTimelineStep facingStep(String id, String direction) =>
    CinematicTimelineStep(
      id: id,
      kind: CinematicTimelineStepKind.actorFace,
      actorId: 'actor',
      metadata: {
        'authoring.kind': 'basicBlock',
        'authoring.source': 'cinematic-builder-v0',
        'authoring.block': 'actorFace',
        'actor.direction': direction,
      },
    );

ProjectManifest facingProject(CinematicAsset asset) => ProjectManifest(
  name: 'Facing project',
  maps: [
    ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
  ],
  tilesets: [],
  cinematics: [asset],
);
