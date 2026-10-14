import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _bumpId = 'evt_019abcde-0000-7000-8000-000000000001';
const _interactId = 'evt_019abcde-0000-7000-8000-000000000002';
const _npc = MapEntity(
  id: 'door',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(characterId: 'actor'),
);
MapData _map([MapEntity npc = _npc]) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  entities: [npc],
);
NarrativeEventRecord _record(String id, NarrativeEventSourceRef source) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: id,
        source: source,
        conditions: const [],
        sceneId: 'hello',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );
ProjectManifest _project(NarrativeEventRegistry registry) => ProjectManifest(
  name: 'Native contact',
  tilesets: const [],
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  characters: const [
    ProjectCharacterEntry(
      id: 'actor',
      name: 'Actor',
      tilesetId: 'qa',
      frameHeight: 1,
    ),
  ],
  eventRegistry: registry,
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
NarrativeEventDispatchAuthorityReady _ready(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final project = _project(registry);
  final preparation = NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(source: source),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    projectCatalog: buildNarrativeEventProjectCatalog(
      project: project,
      maps: [_map()],
    ),
    project: project,
    maps: [_map()],
  );
  expect(preparation, isA<NarrativeEventDispatchAuthorityReady>());
  return preparation as NarrativeEventDispatchAuthorityReady;
}

void main() {
  test('symbolic reachability keeps physical bump input indeterminate', () {
    final registry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        _record(_bumpId, NarrativeEventSourceRef.entityBump('map', 'door')),
      ],
      legacyClaims: const [],
    );
    final report = solveNarrativeSymbolicReachability(
      _project(registry),
      maps: [_map()],
    );
    expect(report.reachableSceneIds, contains('hello'));
    expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
  });

  test(
    'symbolic reachability never invents a bump for an incompatible NPC',
    () {
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          _record(_bumpId, NarrativeEventSourceRef.entityBump('map', 'door')),
        ],
        legacyClaims: const [],
      );
      for (final entity in [
        _npc.copyWith(blocksMovement: false),
        _npc.copyWith(npc: null),
        _npc.copyWith(npc: const MapEntityNpcData(characterId: 'missing')),
      ]) {
        final report = solveNarrativeSymbolicReachability(
          _project(registry),
          maps: [_map(entity)],
        );
        expect(report.reachableSceneIds, isNot(contains('hello')));
      }
    },
  );
  test(
    'source index and real authority keep bump and interaction candidates independent',
    () {
      final bump = NarrativeEventSourceRef.entityBump('map', 'door');
      final interact = NarrativeEventSourceRef.entityInteract('map', 'door');
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [_record(_bumpId, bump), _record(_interactId, interact)],
        legacyClaims: const [],
      );
      final index = buildNarrativeEventSourceIndex(registry.records);
      expect(index.hasConflicts, isFalse);
      expect(index.index.recordsFor(bump).single.id, _bumpId);
      expect(index.index.recordsFor(interact).single.id, _interactId);
      final bumpDecision = _ready(
        registry,
        bump,
      ).plan(gameState: const GameState(saveId: 'save'));
      final interactDecision = _ready(
        registry,
        interact,
      ).plan(gameState: const GameState(saveId: 'save'));
      expect((bumpDecision as NarrativeEventDispatchHandled).eventId, _bumpId);
      expect(
        (interactDecision as NarrativeEventDispatchHandled).eventId,
        _interactId,
      );
    },
  );

  test('an unmatched bump never authorizes a legacy interaction fallback', () {
    final registry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    );
    final bump = _ready(
      registry,
      NarrativeEventSourceRef.entityBump('map', 'door'),
    ).plan(gameState: const GameState(saveId: 'save'));
    expect(bump, isA<NarrativeEventDispatchNoMatch>());
    expect(bump.legacyFallbackAllowed, isFalse);
    final interact = _ready(
      registry,
      NarrativeEventSourceRef.entityInteract('map', 'door'),
    ).plan(gameState: const GameState(saveId: 'save'));
    expect(interact.legacyFallbackAllowed, isTrue);
  });

  test(
    'dependency index marks an existing incompatible bump owner unavailable',
    () {
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          _record(_bumpId, NarrativeEventSourceRef.entityBump('map', 'door')),
        ],
        legacyClaims: const [],
      );
      for (final entity in [
        _npc.copyWith(blocksMovement: false),
        _npc.copyWith(kind: MapEntityKind.sign),
        _npc.copyWith(npc: null),
        _npc.copyWith(npc: const MapEntityNpcData(characterId: 'missing')),
      ]) {
        final usage =
            buildNarrativeDependencyIndex(
              project: _project(registry),
              maps: [_map(entity)],
            ).usages.singleWhere(
              (usage) => usage.path.endsWith('.source.entityId'),
            );
        expect(usage.resolution, NarrativeDependencyResolution.unavailable);
      }
    },
  );

  test('legacy map source candidates cannot invent an entity bump mapping', () {
    expect(
      () => LegacyMapEventSourceCandidate(
        source: NarrativeEventSourceRef.entityBump('map', 'door'),
        evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
        confirmed: true,
        reason: 'Invalid legacy bump',
      ),
      throwsArgumentError,
    );
  });

  test('native bump options cannot acquire legacy provenance', () {
    final project = _project(
      NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
    );
    final catalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: [_map()],
    );
    final option = catalog.spatialSources
        .optionsForSource(NarrativeEventSourceRef.entityBump('map', 'door'))
        .single;
    expect(
      () => option.withLegacyProvenance(
        LegacySourceRef.mapEvent('map', 'old-door'),
      ),
      throwsArgumentError,
    );
  });
}
