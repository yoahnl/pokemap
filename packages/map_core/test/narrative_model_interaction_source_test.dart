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

  test('orders model and duplicate owner options with exact tie-breaking', () {
    Model3dInspection inspection() => Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3.zero,
        max: Model3dVector3(x: 1, y: 1, z: 1),
      ),
      meshCount: 1,
      triangleCount: 2,
    );
    ProjectModel3dEntry model(String id, String name) => ProjectModel3dEntry(
      id: id,
      name: name,
      sourceAssetId: 'asset-$id',
      relativePath: 'assets/models3d/$id.glb',
      inspection: inspection(),
    );
    SpatialModelInstance instance(
      String id,
      String modelId,
      double x,
      double z,
    ) => SpatialModelInstance(
      id: id,
      modelId: modelId,
      position: Model3dVector3(x: x, y: 0, z: z),
    );
    MapEntity twin(int x, int y) => MapEntity(
      id: 'npc_twin',
      name: 'Jumeau',
      kind: MapEntityKind.npc,
      pos: GridPos(x: x, y: y),
      size: const GridSize(width: 1, height: 1),
    );
    final village = MapData(
      id: 'village',
      name: 'Village',
      size: const GridSize(width: 6, height: 8),
      entities: [twin(5, 1), twin(30, 30), twin(2, 5), twin(2, 1)],
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          instance('oak_east', 'oak-a', 5.5, 1.5),
          instance('oak_far', 'oak-a', 7.5, 2.5),
          instance('lamp', 'twin', 1.5, 1.5),
          instance('bench', 'ghost', 3.5, 3.5),
          instance('oak_south', 'oak-b', 2.5, 6.5),
        ],
      ),
    );
    final annex = MapData(
      id: 'annex',
      name: 'Annexe',
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(
        width: 4,
        depth: 4,
        instances: [instance('statue', 'oak-b', 1.5, 1.5)],
      ),
    );
    final project = ProjectManifest(
      name: 'Valbois',
      maps: const [
        ProjectMapEntry(
          id: 'village',
          name: 'Village',
          relativePath: 'maps/village.json',
        ),
        ProjectMapEntry(
          id: 'annex',
          name: 'Annexe',
          relativePath: 'maps/annex.json',
        ),
      ],
      tilesets: const [],
      models3d: [
        model('oak-a', 'Chêne'),
        model('twin', 'Jumeau A'),
        model('oak-b', 'Chêne'),
        model('twin', 'Jumeau B'),
      ],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    );

    String describe(NarrativeSpatialEventSourceOption option) {
      final bounds = option.geometry.bounds;
      final where = bounds == null
          ? option.geometry.kind.name
          : '${bounds.pos.x},${bounds.pos.y}';
      return '${option.debugTechnicalLabel} | ${option.humanLabel} | '
          '${option.availability.name} | $where | '
          '${option.unavailableReason ?? '-'}';
    }

    final catalog = buildNarrativeSpatialEventSourceCatalog(
      project: project,
      maps: [village, annex],
    );
    final reversed = buildNarrativeSpatialEventSourceCatalog(
      project: project.copyWith(
        maps: project.maps.reversed.toList(),
        models3d: project.models3d.reversed.toList(),
      ),
      maps: [
        annex,
        village.copyWith(entities: village.entities.reversed.toList()),
      ],
    );

    final described = catalog.options.map(describe).toList();
    const duplicate = 'Cet identifiant est utilisé plusieurs fois sur la map.';
    const ambiguous = 'La ressource du décor est introuvable ou ambiguë.';
    expect(described, [
      'map:annex | Entrée sur Annexe | selectable | mapWide | -',
      'annex:statue | Chêne — Décor 3D | selectable | 1,1 | -',
      'map:village | Entrée sur Village | selectable | mapWide | -',
      'entityAutorun:village:npc_twin | Jumeau — Automatique | visibleButUnavailable | 2,1 | $duplicate',
      'entityAutorun:village:npc_twin | Jumeau — Automatique | visibleButUnavailable | 2,5 | $duplicate',
      'entityAutorun:village:npc_twin | Jumeau — Automatique | visibleButUnavailable | 5,1 | $duplicate',
      'entityAutorun:village:npc_twin | Jumeau — Automatique | visibleButUnavailable | unavailable | $duplicate',
      'entityBump:village:npc_twin | Jumeau — Contact du joueur | visibleButUnavailable | 2,1 | $duplicate',
      'entityBump:village:npc_twin | Jumeau — Contact du joueur | visibleButUnavailable | 2,5 | $duplicate',
      'entityBump:village:npc_twin | Jumeau — Contact du joueur | visibleButUnavailable | 5,1 | $duplicate',
      'entity:village:npc_twin | Jumeau — PNJ | visibleButUnavailable | 2,1 | $duplicate',
      'entity:village:npc_twin | Jumeau — PNJ | visibleButUnavailable | 2,5 | $duplicate',
      'entity:village:npc_twin | Jumeau — PNJ | visibleButUnavailable | 5,1 | $duplicate',
      'entityBump:village:npc_twin | Jumeau — Contact du joueur | incompatible | unavailable | $duplicate',
      'entity:village:npc_twin | Jumeau — PNJ | incompatible | unavailable | $duplicate',
      'village:oak_east | Chêne — Décor 3D | selectable | 5,1 | -',
      'village:oak_south | Chêne — Décor 3D | selectable | 2,6 | -',
      'village:oak_far | Chêne — Décor 3D | visibleButUnavailable | unavailable | Ce décor est placé en dehors de la carte.',
      'village:bench | ghost — Décor 3D | visibleButUnavailable | 3,3 | $ambiguous',
      'village:lamp | twin — Décor 3D | visibleButUnavailable | 1,1 | $ambiguous',
    ]);
    expect(reversed.options.map(describe).toList(), described);
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
