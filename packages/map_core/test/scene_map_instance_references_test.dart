import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _owner = MapEntity(
  id: 'door',
  kind: MapEntityKind.sign,
  pos: GridPos(x: 1, y: 1),
);

void main() {
  for (final source in [
    SceneConditionSource.playerAtEntityAnchor(
      mapId: 'map',
      entityId: 'door',
      label: 'Door position',
    ),
    SceneConditionSource.mapEventInstanceBoolean(
      mapId: 'map',
      eventId: 'door',
      key: 'A',
      label: 'Door instance flag',
    ),
  ]) {
    test(
      '${source.sourceKind.name} uses native map and entity dependencies',
      () {
        final scene = _scene(SceneConditionPayload(conditionSource: source));
        final project = _project(scene);
        expect(
          diagnoseSceneAgainstProject(
            scene,
            project,
            mapsById: {'map': _map()},
          ).hasErrors,
          isFalse,
        );
        final uses = buildNarrativeDependencyIndex(
          project: project,
          maps: [_map()],
        ).usages.where((u) => u.path.contains('conditionSource'));
        expect(uses, hasLength(2));
        expect(
          uses.every(
            (u) => u.resolution == NarrativeDependencyResolution.resolved,
          ),
          isTrue,
        );
        expect(uses.map((u) => u.target.sourceKind), contains('entity'));
        expect(
          uses.any((u) => u.target.kind == NarrativeDependencyTargetKind.fact),
          isFalse,
        );
      },
    );

    for (final entities in <List<MapEntity>>[
      [],
      [_owner, _owner],
    ]) {
      test(
        '${source.sourceKind.name} rejects owner cardinality ${entities.length}',
        () {
          final scene = _scene(SceneConditionPayload(conditionSource: source));
          final result = diagnoseSceneAgainstProject(
            scene,
            _project(scene),
            mapsById: {'map': _map(entities: entities)},
          );
          expect(result.hasErrors, isTrue);
        },
      );
    }

    test('${source.sourceKind.name} rejects a map alias', () {
      final scene = _scene(SceneConditionPayload(conditionSource: source));
      expect(
        diagnoseSceneAgainstProject(
          scene,
          _project(scene),
          mapsById: {'map': _map(id: 'other')},
        ).hasErrors,
        isTrue,
      );
    });
  }

  test(
    'instance setter accepts logical signs but tracks native owner refs',
    () {
      final consequence = SceneConsequence.setMapEventInstanceBoolean(
        mapId: 'map',
        eventId: 'door',
        key: 'A',
        value: true,
      );
      final scene = _scene(SceneActionPayload.consequence(consequence));
      final project = _project(scene);
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': _map()},
        ).hasErrors,
        isFalse,
      );
      final uses = buildNarrativeDependencyIndex(
        project: project,
        maps: [_map()],
      ).usages.where((u) => u.path.contains('.consequence.'));
      expect(uses, hasLength(2));
      expect(
        uses.every(
          (u) => u.resolution == NarrativeDependencyResolution.resolved,
        ),
        isTrue,
      );
      final descriptor = NarrativeCommandCatalog.canonical().byId(
        'setMapEventInstanceBoolean',
      );
      expect(descriptor, isNotNull);
      expect(descriptor!.isPersistent, isTrue);
      expect(descriptor.isPublishable, isFalse);
      expect(descriptor.parameters.map((p) => p.id), [
        'mapId',
        'eventId',
        'key',
        'value',
      ]);
    },
  );

  test('instance setter refuses an undeclared owner', () {
    final scene = _scene(
      SceneActionPayload.consequence(
        SceneConsequence.setMapEventInstanceBoolean(
          mapId: 'map',
          eventId: 'missing',
          key: 'A',
          value: true,
        ),
      ),
    );
    expect(
      diagnoseSceneAgainstProject(
        scene,
        _project(scene),
        mapsById: {'map': _map()},
      ).hasErrors,
      isTrue,
    );
  });

  test(
    'setter payload rejects malformed booleans instead of silently using false',
    () {
      for (final value in ['true', 'false']) {
        final payload =
            buildScenePayloadForNarrativeCommand(
                  commandId: 'setMapEventInstanceBoolean',
                  parameters: {
                    'mapId': 'map',
                    'eventId': 'door',
                    'key': 'A',
                    'value': value,
                  },
                )
                as SceneActionPayload;
        expect(
          (payload.consequence as SceneSetMapEventInstanceBooleanConsequence)
              .value,
          value == 'true',
        );
      }
      for (final value in ['', 'False', '1', ' true ']) {
        expect(
          () => buildScenePayloadForNarrativeCommand(
            commandId: 'setMapEventInstanceBoolean',
            parameters: {
              'mapId': 'map',
              'eventId': 'door',
              'key': 'A',
              'value': value,
            },
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'instance setter remains explicitly indeterminate in symbolic analysis',
    () {
      final scene = _scene(
        SceneActionPayload.consequence(
          SceneConsequence.setMapEventInstanceBoolean(
            mapId: 'map',
            eventId: 'door',
            key: 'A',
            value: true,
          ),
        ),
      );
      final result = solveNarrativeSceneSymbolically(scene);
      expect(result.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        result.issues.any(
          (i) => i.code == NarrativeSymbolicIssueCode.unsupportedCommand,
        ),
        isTrue,
      );
      expect(
        result.terminalStates.every(
          (state) => !state.factValues.containsKey('door'),
        ),
        isTrue,
      );
    },
  );

  for (final invalid in [
    'missing',
    'duplicate',
    'offAnchor',
    'ghost',
    'badCharacter',
  ]) {
    test('arrival collision owner blocks $invalid before execution', () {
      final npc = _owner.copyWith(
        kind: MapEntityKind.npc,
        npc: MapEntityNpcData(
          characterId: invalid == 'badCharacter' ? 'missing' : 'character',
        ),
      );
      final entities = switch (invalid) {
        'missing' => <MapEntity>[],
        'duplicate' => [npc, npc],
        'offAnchor' => [npc.copyWith(pos: const GridPos(x: 2, y: 1))],
        'ghost' => [npc.copyWith(npc: null)],
        _ => [npc],
      };
      final scene = _scene(
        SceneActionPayload.interactive(
          SceneInteractiveCommand.warp(
            destinationMapId: 'map',
            warpId: 'entry',
            arrivalCollisionOwnerEntityId: 'door',
          ),
        ),
      );
      final map = _map(entities: entities);
      final project = _project(scene).copyWith(
        characters: [
          const ProjectCharacterEntry(
            id: 'character',
            name: 'Character',
            tilesetId: 'sheet',
          ),
        ],
      );
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': map},
        ).hasErrors,
        isTrue,
      );
      final use = buildNarrativeDependencyIndex(project: project, maps: [map])
          .usages
          .singleWhere(
            (u) => u.path.endsWith('.arrivalCollisionOwnerEntityId'),
          );
      expect(use.resolution, isNot(NarrativeDependencyResolution.resolved));
    });
  }

  test(
    'arrival collision owner accepts a real NPC exactly at the arrival anchor',
    () {
      final scene = _scene(
        SceneActionPayload.interactive(
          SceneInteractiveCommand.warp(
            destinationMapId: 'map',
            warpId: 'entry',
            arrivalCollisionOwnerEntityId: 'door',
          ),
        ),
      );
      final map = _map(
        entities: [
          _owner.copyWith(
            kind: MapEntityKind.npc,
            npc: const MapEntityNpcData(characterId: 'character'),
          ),
        ],
      );
      final project = _project(scene).copyWith(
        characters: [
          const ProjectCharacterEntry(
            id: 'character',
            name: 'Character',
            tilesetId: 'sheet',
          ),
        ],
      );
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': map},
        ).hasErrors,
        isFalse,
      );
      expect(
        buildNarrativeDependencyIndex(project: project, maps: [map]).usages
            .singleWhere(
              (u) => u.path.endsWith('.arrivalCollisionOwnerEntityId'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
    },
  );

  test(
    'arrival collision owner refuses a sign and tracks its native entity',
    () {
      final scene = _scene(
        SceneActionPayload.interactive(
          SceneInteractiveCommand.warp(
            destinationMapId: 'map',
            warpId: 'entry',
            arrivalCollisionOwnerEntityId: 'door',
          ),
        ),
      );
      final project = _project(scene);
      expect(
        diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': _map()},
        ).hasErrors,
        isTrue,
      );
      final uses = buildNarrativeDependencyIndex(
        project: project,
        maps: [_map()],
      ).usages.where((u) => u.path.endsWith('.arrivalCollisionOwnerEntityId'));
      expect(uses, hasLength(1));
      expect(uses.single.target.sourceKind, 'entity');
    },
  );
}

SceneAsset _scene(SceneNodePayload payload) {
  final condition = payload is SceneConditionPayload;
  return SceneAsset(
    id: 'scene',
    name: 'Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'test',
          kind: condition ? SceneNodeKind.condition : SceneNodeKind.action,
          payload: payload,
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'test',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port
            in condition
                ? ['true', 'false']
                : payload is SceneActionPayload &&
                      payload.interactiveCommand != null
                ? ['completed', 'blocked']
                : ['completed'])
          SceneEdge(
            id: port,
            fromNodeId: 'test',
            fromPortId: port,
            toNodeId: 'end',
            kind: condition
                ? (port == 'true'
                      ? SceneEdgeKind.conditionTrue
                      : SceneEdgeKind.conditionFalse)
                : SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}

MapData _map({String id = 'map', List<MapEntity>? entities}) => MapData(
  version: ProjectVersion.v8,
  id: id,
  name: id,
  size: const GridSize(width: 3, height: 3),
  entities: entities ?? [_owner],
  warps: const [
    MapWarp(
      id: 'entry',
      pos: GridPos(x: 1, y: 1),
      targetMapId: 'map',
      targetPos: GridPos(x: 1, y: 1),
    ),
  ],
);

ProjectManifest _project(SceneAsset scene) => ProjectManifest(
  version: ProjectVersion.v8,
  tilesets: [],
  name: 'QA',
  scenes: [scene],
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
);
