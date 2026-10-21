import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('authored routes accept every unique known conditional character', () {
    final entity = _entity(['first', 'second', null]);
    final project = _project();
    expect(isSceneActorEntityReferenceAvailable(project, entity), isTrue);
    expect(
      isSceneActorInitialCollisionOwnerReferenceAvailable(project, entity),
      isTrue,
    );
    final scene = _scene();
    final diagnostics = diagnoseSceneAgainstProject(
      scene,
      project,
      mapsById: {'room': _map(entity)},
    );
    expect(
      diagnostics.hasErrors,
      isFalse,
      reason: '${diagnostics.diagnostics.map((d) => d.code).toList()}',
    );
    expect(buildSceneRuntimePlan(scene).canBuild, isTrue);
  });

  test(
    'unknown conditional character cannot borrow a valid base character',
    () {
      final entity = _entity([
        'first',
        'missing',
      ]).copyWith(npc: const MapEntityNpcData(characterId: 'first'));
      expect(isSceneActorEntityReferenceAvailable(_project(), entity), isFalse);
      expect(
        diagnoseSceneAgainstProject(
          _scene(),
          _project(),
          mapsById: {'room': _map(entity)},
        ).diagnostics.any(
          (d) => d.code == SceneDiagnosticCode.commandInvalidActorTarget,
        ),
        isTrue,
      );
    },
  );

  test('ambiguous conditional characters are refused', () {
    expect(
      isSceneActorEntityReferenceAvailable(
        _project(duplicate: true),
        _entity(['first']),
      ),
      isFalse,
    );
  });

  test('blank-only variants cannot declare a movable actor', () {
    expect(
      isSceneActorEntityReferenceAvailable(_project(), _entity([null])),
      isFalse,
    );
  });

  test('non NPC owners and missing NPC payloads remain refused', () {
    final entity = _entity(['first']);
    expect(
      isSceneActorEntityReferenceAvailable(
        _project(),
        entity.copyWith(kind: MapEntityKind.item),
      ),
      isFalse,
    );
    expect(
      isSceneActorEntityReferenceAvailable(
        _project(),
        entity.copyWith(npc: null, presentation: null),
      ),
      isFalse,
    );
  });

  test('an authored blank base may acquire its NPC payload from a variant', () {
    final entity = _entity([
      'first',
      null,
    ]).copyWith(kind: MapEntityKind.custom, npc: null);
    expect(isSceneActorEntityReferenceAvailable(_project(), entity), isTrue);
    expect(
      diagnoseSceneAgainstProject(
        _scene(),
        _project(),
        mapsById: {'room': _map(entity)},
      ).hasErrors,
      isFalse,
    );
  });

  test('current absence never changes authoring reference availability', () {
    final entity = _entity(['first', 'second', null]);
    final project = _project();
    final map = _map(entity);
    for (final (phase, character) in [(0, 'first'), (1, 'second'), (2, null)]) {
      final state = GameState(
        saveId: 'variant-test',
        currentMapId: 'room',
        playerPosition: const GridPos(x: 0, y: 0),
        narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
          valuesByFactId: {'phase': NarrativeValue.integer(phase)},
        ),
      );
      expect(
        resolveMapEntityPresentation(
          project: project,
          gameState: state,
          map: map,
          entity: entity,
        )?.characterId,
        character,
      );
      expect(isSceneActorEntityReferenceAvailable(project, entity), isTrue);
    }
  });

  test('initial collision owner still checks the contact footprint', () {
    final entity = _entity([
      'first',
    ]).copyWith(size: const GridSize(width: 2, height: 1));
    expect(isSceneActorEntityReferenceAvailable(_project(), entity), isTrue);
    expect(
      isSceneActorInitialCollisionOwnerReferenceAvailable(_project(), entity),
      isFalse,
    );
  });

  test('a wide conditional page cannot borrow a one cell initial owner', () {
    final entity = _entity(['first']).copyWith(
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'wide',
            condition: NarrativeEventConditionExpression.all(const []),
            characterId: 'first',
            blocksMovement: true,
            size: const GridSize(width: 2, height: 1),
          ),
        ],
      ),
    );
    expect(isSceneActorEntityReferenceAvailable(_project(), entity), isTrue);
    expect(
      isSceneActorInitialCollisionOwnerReferenceAvailable(_project(), entity),
      isFalse,
    );
  });
}

MapEntity _entity(List<String?> characters) => MapEntity(
  id: 'actor',
  name: 'Conditional actor',
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 2, y: 2),
  npc: const MapEntityNpcData(),
  presentation: MapEntityPresentation(
    variants: [
      for (final (index, character) in characters.indexed)
        MapEntityPresentationVariant(
          id: 'phase_$index',
          condition: NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.factValue(
              'phase',
              operator: NarrativeFactOperator.equals,
              expectedValue: NarrativeValue.integer(index),
            ),
          ),
          characterId: character,
          blocksMovement: character != null,
        ),
    ],
  ),
);

MapData _map(MapEntity entity) => MapData(
  id: 'room',
  name: 'Room',
  size: const GridSize(width: 5, height: 5),
  entities: [entity],
);

ProjectManifest _project({bool duplicate = false}) => ProjectManifest(
  name: 'Conditional actor references',
  maps: const [
    ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'room.json'),
  ],
  tilesets: const [],
  characters: [
    const ProjectCharacterEntry(id: 'first', name: 'First', tilesetId: 'sheet'),
    const ProjectCharacterEntry(
      id: 'second',
      name: 'Second',
      tilesetId: 'sheet',
    ),
    if (duplicate)
      const ProjectCharacterEntry(
        id: 'first',
        name: 'Duplicate',
        tilesetId: 'sheet',
      ),
  ],
  facts: [
    NarrativeFactDefinition(
      id: 'phase',
      label: 'Phase',
      initialValue: NarrativeValue.integer(0),
    ),
  ],
);

SceneAsset _scene() => SceneAsset(
  id: 'conditional_route',
  name: 'Conditional route',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'route',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.entity(mapId: 'room', entityId: 'actor'),
            steps: [SceneActorRouteStep.face(direction: EntityFacing.north)],
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_route',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'route',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: 'route_$port',
          fromNodeId: 'route',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);
