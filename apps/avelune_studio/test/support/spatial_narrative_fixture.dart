import 'dart:typed_data';

import 'package:avelune_studio/presentation/features/cinematics/cinematic_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

ProjectManifest spatialNarrativeProject() => workspaceProject.copyWith(
  version: ProjectVersion.v9,
  settings: const ProjectSettings(
    dimension: ProjectDimension.threeD,
    defaultPlayerCharacterId: 'guide',
  ),
  characters: [
    ProjectCharacterEntry(
      id: 'guide',
      name: 'Guide',
      tilesetId: 'atlas',
      frameWidth: 2,
      frameHeight: 2,
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: direction,
            frames: [
              const CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
          ),
      ],
    ),
  ],
  models3d: [
    ProjectModel3dEntry(
      id: 'door',
      name: 'Porte NB2',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: .2),
        ),
        meshCount: 1,
        triangleCount: 4,
        animations: [
          Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: .12),
        ],
      ),
    ),
  ],
);

MapData spatialNarrativeMap() => MapData(
  id: 'a',
  name: 'Clairière',
  version: ProjectVersion.v9,
  size: const GridSize(width: 20, height: 16),
  spatialScene: MapSpatialScene(
    width: 20,
    depth: 16,
    heightLevels: List.generate(320, (index) => index ~/ 20 == 9 ? 1 : 0),
    instances: [
      SpatialModelInstance(
        id: 'door-a',
        modelId: 'door',
        position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
      ),
      SpatialModelInstance(
        id: 'door-b',
        modelId: 'door',
        position: Model3dVector3(x: 8.5, y: 0, z: 3.5),
      ),
    ],
  ),
  entities: [
    const MapEntity(
      id: 'chief',
      name: 'Guide',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 13, y: 7),
      size: GridSize(width: 1, height: 1),
      npc: MapEntityNpcData(characterId: 'guide'),
    ),
  ],
);

CinematicAsset spatialNarrativeCinematic() => CinematicAsset(
  id: 'walk',
  title: 'Le chemin du guide',
  mapId: 'a',
  requiredActors: [
    CinematicActorRef(actorId: 'hero', label: 'Voyageur'),
    CinematicActorRef(actorId: 'chief', label: 'Guide'),
  ],
  movementTargets: [
    CinematicMovementTargetRef(targetId: 'arrival', label: 'Arrivée'),
  ],
  stageContext: CinematicStageContext(
    backdropMode: CinematicStageBackdropMode.projectMap,
    actorBindings: [
      CinematicActorBinding(
        actorId: 'hero',
        kind: CinematicActorBindingKind.player,
      ),
      CinematicActorBinding(
        actorId: 'chief',
        kind: CinematicActorBindingKind.mapEntity,
        mapEntityId: 'chief',
      ),
    ],
    initialPlacements: [
      CinematicActorInitialPlacement(
        actorId: 'hero',
        kind: CinematicActorInitialPlacementKind.stagePoint,
        stagePointId: 'start',
      ),
      CinematicActorInitialPlacement(
        actorId: 'chief',
        kind: CinematicActorInitialPlacementKind.fromMapEntity,
      ),
    ],
    stagePoints: [
      CinematicStagePoint(id: 'start', label: 'Départ', x: 8.5, y: 9.5),
      CinematicStagePoint(id: 'end', label: 'Arrivée', x: 13.5, y: 9.5),
    ],
    movementTargetBindings: [
      CinematicMovementTargetBinding(
        targetId: 'arrival',
        kind: CinematicMovementTargetBindingKind.stagePoint,
        sourceId: 'end',
      ),
    ],
    manualPaths: [
      CinematicManualPath(
        id: 'route',
        label: 'Sentier',
        ownerActorMoveStepId: 'move',
        waypointStagePointIds: ['start'],
      ),
    ],
  ),
  timeline: CinematicTimeline(
    steps: [
      CinematicTimelineStep(
        id: 'move',
        kind: CinematicTimelineStepKind.actorMove,
        actorId: 'hero',
        targetId: 'arrival',
        durationMs: 1200,
      ),
    ],
  ),
);

class SpatialNarrativeVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals, CinematicSpatialWorkspaceVisuals {
  int previewsDisposed = 0;
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
  @override
  Future<CinematicSpatialPreview> cinematicSpatialPreview(
    MapData map,
    CinematicActorDisplayPreviewModel actors,
  ) async => CinematicSpatialPreview(
    (asset, plan, frame, timeMs) => {},
    () => previewsDisposed++,
  );
}
