import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _id = 'evt_019abcde-0000-7000-8000-000000000001';
const _owner = MapEntity(
  id: 'owner',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 1, y: 1),
  blocksMovement: false,
);
MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  entities: const [_owner],
);
NarrativeEventRegistry _registry({
  EventSystemMode mode = EventSystemMode.v2Only,
  bool record = true,
}) => NarrativeEventRegistry(
  schemaVersion: 1,
  mode: mode,
  records: [
    if (record)
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _id,
          name: 'Automatic owner',
          source: NarrativeEventSourceRef.entityAutorun('map', 'owner'),
          conditions: const [],
          sceneId: 'hello',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
  ],
  legacyClaims: const [],
);
ProjectManifest _project(NarrativeEventRegistry registry) => ProjectManifest(
  name: 'Autorun authority',
  tilesets: const [],
  eventRegistry: registry,
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  scenes: [
    SceneAsset(
      id: 'hello',
      name: 'Hello',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'done',
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

NarrativeEventDispatchAuthorityReady _ready(NarrativeEventRegistry registry) {
  final project = _project(registry);
  final result = NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(
      source: NarrativeEventSourceRef.entityAutorun('map', 'owner'),
    ),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: buildValidatedLegacyClaimIndex(registry),
    projectCatalog: buildNarrativeEventProjectCatalog(
      project: project,
      maps: [_map()],
    ),
    project: project,
    maps: [_map()],
  );
  expect(result, isA<NarrativeEventDispatchAuthorityReady>());
  return result as NarrativeEventDispatchAuthorityReady;
}

void main() {
  test('real authority dispatches a sprite-free nonblocking logical owner', () {
    final decision = _ready(
      _registry(),
    ).plan(gameState: const GameState(saveId: 'save'));
    expect(decision, isA<NarrativeEventDispatchHandled>());
    expect((decision as NarrativeEventDispatchHandled).eventId, _id);
  });

  test('an unmatched autorun never authorizes legacy fallback', () {
    for (final mode in [EventSystemMode.legacyOnly, EventSystemMode.dualRead]) {
      final decision = _ready(
        _registry(mode: mode, record: false),
      ).plan(gameState: const GameState(saveId: 'save'));
      expect(decision, isA<NarrativeEventDispatchNoMatch>());
      expect(decision.legacyFallbackAllowed, isFalse);
    }
  });

  test('a legacy candidate cannot manufacture an autorun correspondence', () {
    expect(
      () => LegacyMapEventSourceCandidate(
        source: NarrativeEventSourceRef.entityAutorun('map', 'owner'),
        evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
        confirmed: true,
        reason: 'No native alias',
      ),
      throwsArgumentError,
    );
  });

  test('native autorun options cannot acquire a legacy provenance', () {
    final registry = _registry();
    final option =
        buildNarrativeEventProjectCatalog(
              project: _project(registry),
              maps: [_map()],
            ).spatialSources
            .optionsForSource(
              NarrativeEventSourceRef.entityAutorun('map', 'owner'),
            )
            .single;
    expect(
      () => option.withLegacyProvenance(LegacySourceRef.mapEvent('map', 'old')),
      throwsArgumentError,
    );
  });

  test(
    'a valid logical autorun has no invented physical-input uncertainty',
    () {
      final registry = _registry();
      final report = solveNarrativeSymbolicReachability(
        _project(registry),
        maps: [_map()],
      );
      expect(report.reachableSceneIds, contains('hello'));
      expect(report.verdict, NarrativeSymbolicVerdict.pass);
    },
  );
}
