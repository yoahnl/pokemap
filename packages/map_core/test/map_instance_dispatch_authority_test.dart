import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _offEvent = 'evt_019abcde-0000-7000-8000-000000000101';
const _onEvent = 'evt_019abcde-0000-7000-8000-000000000102';
const _door = MapEntity(
  id: 'door',
  kind: MapEntityKind.sign,
  pos: GridPos(x: 1, y: 1),
);

void main() {
  test('builder simulation uses retained instance authority and real owners', () {
    final registry = _registry();
    final catalog = buildNarrativeEventProjectCatalog(
      project: _project(registry),
      maps: [_map()],
    );
    NarrativeEventSimulationReport simulate(MapInstanceWorldState state,
            {List<MapData>? maps}) =>
        simulateNarrativeEventDispatch(
          registryResult: EventRegistryDecodeResult.decoded(registry),
          projectCatalog: catalog,
          facts: const [],
          maps: maps ?? [_map()],
          input: NarrativeEventSimulationInput(
            targetEventId: _onEvent,
            mapInstanceWorldState: state,
          ),
        );
    final state = _state().mapInstanceWorldState;
    final scope = state.instanceRef('map')!;
    final on = state.setEventBoolean(scope, 'door', 'A', true);
    expect(simulate(state).handledEventId, _offEvent);
    expect(simulate(on).handledEventId, _onEvent);
    expect(simulate(MapInstanceWorldState.fromJson(on.toJson())).handledEventId,
        _onEvent);
    expect(simulate(const MapInstanceWorldState.empty()).handledEventId, isNull);
    expect(simulate(on, maps: [_map(entities: [])]).handledEventId, isNull);
    expect(simulate(on).targetCandidate!.conditions.single.instanceId,
        scope.instanceId);
    expect(state.eventBoolean(scope, 'door', 'A'), isFalse);
  });

  test('logical pages select the instance boolean rather than a Fact', () {
    final authority = _authority();
    final off = _state();
    expect(
      (authority.plan(gameState: off) as NarrativeEventDispatchHandled).eventId,
      _offEvent,
    );
    final scope = off.mapInstanceWorldState.instanceRef('map')!;
    final on = off.copyWith(
      mapInstanceWorldState: off.mapInstanceWorldState.setEventBoolean(
        scope,
        'door',
        'A',
        true,
      ),
    );
    expect(
      (authority.plan(gameState: on) as NarrativeEventDispatchHandled).eventId,
      _onEvent,
    );
    expect(on.narrativeFactRuntimeState, off.narrativeFactRuntimeState);
    final report = authority.simulate(gameState: on, targetEventId: _onEvent);
    expect(
      report.targetCandidate!.conditions.single.kind.name,
      'mapEventInstanceBoolean',
    );
    expect(report.targetCandidate!.conditions.single.targetId, 'door');
    expect(report.targetCandidate!.conditions.single.actualValue, isTrue);
  });

  test('save restore keeps a page flag in the same logical instance', () {
    final before = _state();
    final scope = before.mapInstanceWorldState.instanceRef('map')!;
    final on = before.copyWith(
      mapInstanceWorldState: before.mapInstanceWorldState.setEventBoolean(
        scope,
        'door',
        'A',
        true,
      ),
    );
    final restored = gameStateFromSaveData(saveDataFromGameState(on));
    expect(restored.mapInstanceWorldState.instanceRef('map'), scope);
    expect(
      (_authority().plan(gameState: restored) as NarrativeEventDispatchHandled)
          .eventId,
      _onEvent,
    );
  });

  test('replacement instance starts with its own false page flag', () {
    final before = _state();
    final scope = before.mapInstanceWorldState.instanceRef('map')!;
    final on = before.copyWith(
      mapInstanceWorldState: before.mapInstanceWorldState.setEventBoolean(
        scope,
        'door',
        'A',
        true,
      ),
    );
    final replaced = on.copyWith(
      mapInstanceWorldState: MapInstanceWorldState(
        instancesByMapId: {
          'map': MapInstanceRuntimeState(instanceId: 'replacement'),
        },
      ),
    );
    expect(
      (_authority().plan(gameState: replaced) as NarrativeEventDispatchHandled)
          .eventId,
      _offEvent,
    );
    expect(
      () => replaced.mapInstanceWorldState.eventBoolean(scope, 'door', 'A'),
      throwsStateError,
    );
  });

  test('page keys and owners remain independent within one instance', () {
    final before = _state();
    final scope = before.mapInstanceWorldState.instanceRef('map')!;
    final other = before.copyWith(
      mapInstanceWorldState: before.mapInstanceWorldState
          .setEventBoolean(scope, 'door', 'B', true)
          .setEventBoolean(scope, 'other', 'A', true),
    );
    expect(
      (_authority().plan(gameState: other) as NarrativeEventDispatchHandled)
          .eventId,
      _offEvent,
    );
  });

  test('missing runtime instance is unavailable even for expected false', () {
    final authority = _authority();
    final result = authority.plan(gameState: GameState(saveId: 'qa'));
    expect(result, isA<NarrativeEventDispatchNoMatch>());
    expect(
      result.reasons,
      contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable),
    );
    final trace = authority
        .simulate(
          gameState: GameState(saveId: 'qa'),
          targetEventId: _offEvent,
        )
        .targetCandidate!
        .conditions
        .single;
    expect(trace.actualValue, isNull);
    expect(trace.passed, isFalse);
  });

  test('NOT cannot turn an unavailable runtime instance into eligibility', () {
    final authority = _authority(not: true);
    final result = authority.plan(gameState: GameState(saveId: 'qa'));
    expect(result, isA<NarrativeEventDispatchNoMatch>());
    expect(
      result.reasons,
      contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable),
    );
  });

  for (final entities in <List<MapEntity>>[
    [],
    [_door, _door],
  ]) {
    test('page owner cardinality is validated ${entities.length}', () {
      final project = _project(_registry());
      final catalog = buildNarrativeEventProjectCatalog(
        project: project,
        maps: [_map(entities: entities)],
      );
      expect(catalog.hasBlockingDiagnostics, isTrue);
      expect(
        catalog.diagnostics.any(
          (d) => d.code.startsWith('narrativeEventMapInstance'),
        ),
        isTrue,
      );
    });
  }

  test(
    'canonical authoring validates the native boolean owner rather than an Event page',
    () {
      final registry = _registry(enabled: false);
      final catalog = buildNarrativeEventProjectCatalog(
        project: _project(registry),
        maps: [_map()],
      );
      final context = NarrativeEventAuthoringContext(
        registryState: EventRegistryDecodeResult.decoded(registry),
        revision: 'qa',
        catalog: catalog,
        sourceIndex: buildNarrativeEventSourceIndex(registry.records),
        manifestHash: catalog.manifestHash,
        mapHashes: catalog.mapHashes,
      );
      final accepted = setNarrativeEventConditions(
        context: context,
        expectedRevision: 'qa',
        eventId: _offEvent,
        conditions: [
          NarrativeEventCondition.mapEventInstanceBoolean(
            mapId: 'map',
            eventId: 'door',
            key: 'B',
            expectedValue: false,
          ),
        ],
      );
      expect(accepted.status, NarrativeEventAuthoringStatus.applied);
      final rejected = setNarrativeEventConditions(
        context: context,
        expectedRevision: 'qa',
        eventId: _offEvent,
        conditions: [
          NarrativeEventCondition.mapEventInstanceBoolean(
            mapId: 'map',
            eventId: _offEvent,
            key: 'A',
            expectedValue: false,
          ),
        ],
      );
      expect(rejected.status, NarrativeEventAuthoringStatus.rejected);
    },
  );

  test(
    'project analysis reports unknown instance lifetime without inventing a Fact',
    () {
      final project = _project(_registry());
      final report = validateNarrativeProject(project, maps: [_map()]);
      expect(
        report.symbolicReachability!.verdict,
        NarrativeSymbolicVerdict.indeterminate,
      );
      expect(
        report.symbolicReachability!.issues.any(
          (i) => i.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isTrue,
      );
      expect(
        report.diagnostics.any((d) => d.code == 'requiredFactNeverProduced'),
        isFalse,
      );
    },
  );

  test(
    'runtime does not trust a catalog when the physical owner disappears',
    () {
      final result = _authority(
        runtimeMaps: [_map(entities: [])],
      ).plan(gameState: _state());
      expect(result, isA<NarrativeEventDispatchNoMatch>());
      expect(
        result.reasons,
        contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable),
      );
    },
  );

  test('runtime does not borrow an owner from a different map', () {
    final result = _authority(
      runtimeMaps: [_map(id: 'other')],
    ).plan(gameState: _state());
    expect(result, isA<NarrativeEventDispatchNoMatch>());
    expect(
      result.reasons,
      contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable),
    );
  });
}

NarrativeEventCondition _condition(bool expected) =>
    NarrativeEventCondition.mapEventInstanceBoolean(
      mapId: 'map',
      eventId: 'door',
      key: 'A',
      expectedValue: expected,
    );

NarrativeEventRegistry _registry({bool not = false, bool enabled = true}) => NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  legacyClaims: [],
  records: [
    for (final page in [(true, _onEvent, 2), (false, _offEvent, 1)])
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: page.$2,
          name: page.$2,
          source: NarrativeEventSourceRef.mapEnter('map'),
          conditions: [_condition(page.$1)],
          conditionExpression: not
              ? NarrativeEventConditionExpression.not(
                  NarrativeEventConditionExpression.leaf(_condition(page.$1)),
                )
              : null,
          sceneId: 'scene',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: page.$3,
          order: 0,
        ),
        enabled: enabled,
      ),
  ],
);

NarrativeEventDispatchAuthorityReady _authority({
  bool not = false,
  List<MapData>? runtimeMaps,
}) {
  final registry = _registry(not: not);
  final project = _project(registry);
  final catalog = buildNarrativeEventProjectCatalog(
    project: project,
    maps: [_map()],
  );
  expect(catalog.hasBlockingDiagnostics, isFalse);
  return NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        projectCatalog: catalog,
        project: project,
        maps: runtimeMaps ?? [_map()],
      )
      as NarrativeEventDispatchAuthorityReady;
}

GameState _state() => GameState(
  saveId: 'qa',
  mapInstanceWorldState: MapInstanceWorldState(
    instancesByMapId: {
      'map': MapInstanceRuntimeState(instanceId: 'instance-1'),
    },
  ),
);

MapData _map({String id = 'map', List<MapEntity>? entities}) => MapData(
  version: ProjectVersion.v8,
  id: id,
  name: id,
  size: const GridSize(width: 3, height: 3),
  entities: entities ?? [_door],
);

ProjectManifest _project(NarrativeEventRegistry registry) => ProjectManifest(
  version: ProjectVersion.v8,
  tilesets: [],
  name: 'QA',
  eventRegistry: registry,
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    ),
  ],
);
