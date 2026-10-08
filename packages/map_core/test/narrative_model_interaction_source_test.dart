import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('native decor appears in the shared source picker and navigation', () {
    final model = ProjectModel3dEntry(
      id: 'door-model',
      name: 'Porte NB2',
      sourceAssetId: 'nb2-door',
      relativePath: 'assets/models3d/door-model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 2,
      ),
    );
    final map = MapData(
      id: 'village',
      name: 'Village',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'door',
            modelId: model.id,
            position: Model3dVector3(x: 3.5, y: 0, z: 4.5),
          ),
        ],
      ),
    );
    final project = ProjectManifest(
      name: 'Valbois',
      maps: [
        const ProjectMapEntry(
          id: 'village',
          name: 'Village',
          relativePath: 'maps/village.json',
        ),
      ],
      tilesets: const [],
      models3d: [model],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    );
    final catalog = buildNarrativeSpatialEventSourceCatalog(
      project: project,
      maps: [map],
    );
    final option = catalog.options.singleWhere(
      (value) => value.ownerId == 'door',
    );
    expect(
      option.source,
      NarrativeEventSourceRef.modelInteract('village', 'door'),
    );
    expect(
      option.availability,
      NarrativeSpatialEventSourceAvailability.selectable,
    );
    expect(
      option.ownerKind,
      NarrativeSpatialEventSourceOwnerKind.modelInstance,
    );
    expect(option.geometry.bounds!.pos, const GridPos(x: 3, y: 4));
    final missing = buildNarrativeSpatialEventSourceCatalog(
      project: project.copyWith(models3d: []),
      maps: [map],
    );
    expect(
      missing.options
          .singleWhere((value) => value.ownerId == 'door')
          .availability,
      NarrativeSpatialEventSourceAvailability.visibleButUnavailable,
    );
    final state = const SpatialWorldState.empty().setModelState(
      'village',
      'door',
      SpatialModelRuntimeState(
        modelId: model.id,
        animationIndex: null,
        normalizedTime: 0,
        blocksMovement: false,
      ),
    );
    validateSpatialWorldState(state: state, project: project, maps: [map]);
    expect(
      () => validateSpatialWorldState(
        state: state,
        project: project.copyWith(models3d: []),
        maps: [map],
      ),
      throwsFormatException,
    );
    expect(
      () => validateSpatialWorldState(
        state: state,
        project: project.copyWith(settings: const ProjectSettings()),
        maps: [map],
      ),
      throwsFormatException,
    );
    expect(
      () => validateSpatialWorldState(
        state: state.setActorState(
          'village',
          'absent',
          SpatialActorRuntimeState(x: 1.5, z: 1.5, facing: EntityFacing.north),
        ),
        project: project,
        maps: [map],
      ),
      throwsFormatException,
    );
  });

  test('a model interaction has its own typed identity and wire fields', () {
    final source = NarrativeEventSourceRef.modelInteract('village', 'door');
    expect(source.kind, NarrativeEventSourceKind.modelInteract);
    expect(source.toJson(), {
      'kind': 'modelInteract',
      'mapId': 'village',
      'instanceId': 'door',
    });
    expect(NarrativeEventSourceRef.fromJson(source.toJson()), source);
    expect(
      source,
      isNot(NarrativeEventSourceRef.entityInteract('village', 'door')),
    );
  });

  test('a model source rejects entity identifiers and mixed variants', () {
    for (final json in [
      {'kind': 'modelInteract', 'mapId': 'village', 'entityId': 'door'},
      {
        'kind': 'modelInteract',
        'mapId': 'village',
        'instanceId': 'door',
        'entityId': 'door',
      },
      {'kind': 'modelInteract', 'mapId': 'village', 'instanceId': 4},
    ]) {
      expect(
        () => NarrativeEventSourceRef.fromJson(json),
        throwsFormatException,
      );
    }
  });
}
