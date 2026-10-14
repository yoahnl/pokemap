import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _source() => {
  'kind': 'triggerBump',
  'mapId': 'map',
  'triggerId': 'zone',
};

void main() {
  test('contact references reject wrong types geometry ambiguity and 3D', () {
    final project = _project(_registry());
    final good = _map();
    for (final (p, m, id) in <(ProjectManifest, MapData, String)>[
      (project.copyWith(maps: []), good, 'owner'),
      (
        project.copyWith(maps: [...project.maps, ...project.maps]),
        good,
        'owner',
      ),
      (project, good.copyWith(triggers: []), 'owner'),
      (project, good.copyWith(triggers: [_owner, _owner]), 'owner'),
      (project, good, 'missing'),
      (project, good, ' owner'),
      for (final type in TriggerType.values.where(
        (type) => type != TriggerType.event,
      ))
        (
          project,
          good.copyWith(triggers: [_owner.copyWith(type: type)]),
          'owner',
        ),
      (
        project,
        good.copyWith(
          triggers: [
            _owner.copyWith(
              area: const MapRect(
                pos: GridPos(x: -1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
        ),
        'owner',
      ),
      (
        project,
        good.copyWith(
          triggers: [
            _owner.copyWith(
              area: const MapRect(
                pos: GridPos(x: 3, y: 1),
                size: GridSize(width: 2, height: 1),
              ),
            ),
          ],
        ),
        'owner',
      ),
      (
        project.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
        good,
        'owner',
      ),
      (project, good.copyWith(version: ProjectVersion.v9), 'owner'),
      (
        project,
        good.copyWith(spatialScene: MapSpatialScene(width: 4, depth: 4)),
        'owner',
      ),
    ]) {
      expect(
        isNarrativeTriggerBumpSourceAvailable(
          project: p,
          map: m,
          triggerId: id,
        ),
        isFalse,
        reason: '$id ${m.toJson()}',
      );
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: p,
        maps: [m],
      );
      expect(
        catalog.options.where(
          (option) =>
              option.source?.kind == NarrativeEventSourceKind.triggerBump &&
              option.source?.toJson()['triggerId'] == id &&
              option.selectable,
        ),
        isEmpty,
      );
    }
  });

  test('contact dispatch calls its own required callback', () {
    final source = NarrativeEventSourceRef.triggerBump('map', 'owner');
    expect(
      source.when<String>(
        triggerBump: (map, id) => '$map/$id',
        entityInteract: (_, _) => fail('interaction'),
        entityBump: (_, _) => fail('entity contact'),
        entityAutorun: (_, _) => fail('trigger contact'),
        modelInteract: (_, _) => fail('3D'),
        triggerEnter: (_, _) => fail('entry'),
        mapEnter: (_) => fail('map entry'),
        outcomeReceived: (_) => fail('outcome'),
      ),
      'map/owner',
    );
    expect(
      () => Function.apply(source.when<String>, [], {
        #entityInteract: (String _, String _) => '',
        #entityBump: (String _, String _) => '',
        #entityAutorun: (String _, String _) => '',
        #modelInteract: (String _, String _) => '',
        #triggerEnter: (String _, String _) => '',
        #mapEnter: (String _) => '',
        #outcomeReceived: (NarrativeOutcomeRef _) => '',
      }),
      throwsA(isA<NoSuchMethodError>()),
    );
  });

  test('trigger contact has its exact kind and does not become zone entry', () {
    final source = NarrativeEventSourceRef.fromJson(_source());
    expect(source.kind.name, 'triggerBump');
    expect(source.toJson(), _source());
    expect(NarrativeEventSourceRef.fromJson(source.toJson()), source);
    expect(source, isNot(NarrativeEventSourceRef.triggerEnter('map', 'zone')));
    expect(source, isNot(NarrativeEventSourceRef.entityBump('map', 'zone')));
  });

  test('valid event trigger has a distinct selectable contact source', () {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 5, height: 5),
      triggers: [
        MapTrigger(
          id: 'zone',
          name: 'Door',
          type: TriggerType.event,
          area: const MapRect(
            pos: GridPos(x: 2, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );
    final project = ProjectManifest(
      name: 'P',
      maps: [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: [],
    );
    expect(
      isNarrativeTriggerBumpSourceAvailable(
        project: project,
        map: map,
        triggerId: 'zone',
      ),
      isTrue,
    );
    final catalog = buildNarrativeSpatialEventSourceCatalog(
      project: project,
      maps: [map],
    );
    final option = catalog
        .optionsForSource(NarrativeEventSourceRef.triggerBump('map', 'zone'))
        .single;
    expect(option.selectable, isTrue);
    expect(option.sourceTypeLabel, 'Contact de zone');
    expect(option.legacyProvenances, isEmpty);
  });

  test(
    'trigger contact rejects aliases partial identities and unrelated fields',
    () {
      for (final wire in [
        {..._source(), 'kind': 'trigger_bump'},
        {'kind': 'triggerBump', 'mapId': 'map'},
        {..._source(), 'triggerId': null},
        {..._source(), 'triggerId': ''},
        {..._source(), 'mapId': ' map'},
        {..._source(), 'entityId': 'npc'},
        {..._source(), 'direction': 'south'},
      ]) {
        expect(
          () => NarrativeEventSourceRef.fromJson(wire),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'real authority dispatches a trigger contact independently of trigger entry',
    () {
      final decision = _ready(
        _registry(),
      ).plan(gameState: const GameState(saveId: 'save'));
      expect(decision, isA<NarrativeEventDispatchHandled>());
      expect((decision as NarrativeEventDispatchHandled).eventId, _id);
    },
  );

  test('an unmatched trigger contact never authorizes legacy fallback', () {
    for (final mode in [EventSystemMode.legacyOnly, EventSystemMode.dualRead]) {
      final decision = _ready(
        _registry(mode: mode, record: false),
      ).plan(gameState: const GameState(saveId: 'save'));
      expect(decision, isA<NarrativeEventDispatchNoMatch>());
      expect(decision.legacyFallbackAllowed, isFalse);
    }
  });

  test(
    'a legacy candidate cannot manufacture an trigger contact correspondence',
    () {
      expect(
        () => LegacyMapEventSourceCandidate(
          source: NarrativeEventSourceRef.triggerBump('map', 'owner'),
          evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
          confirmed: true,
          reason: 'No native alias',
        ),
        throwsArgumentError,
      );
    },
  );

  test('native trigger contact options cannot acquire a legacy provenance', () {
    final registry = _registry();
    final option =
        buildNarrativeEventProjectCatalog(
              project: _project(registry),
              maps: [_map()],
            ).spatialSources
            .optionsForSource(
              NarrativeEventSourceRef.triggerBump('map', 'owner'),
            )
            .single;
    expect(
      () => option.withLegacyProvenance(LegacySourceRef.mapEvent('map', 'old')),
      throwsArgumentError,
    );
  });

  test(
    'a logical contact reference alone is not physical reachability proof',
    () {
      final registry = _registry();
      final report = solveNarrativeSymbolicReachability(
        _project(registry),
        maps: [_map()],
      );
      expect(report.reachableSceneIds, contains('hello'));
      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
    },
  );
}

const _id = 'evt_019abcde-0000-7000-8000-000000000001';
const _owner = MapTrigger(
  id: 'owner',
  name: 'Door',
  type: TriggerType.event,
  area: MapRect(pos: GridPos(x: 1, y: 1), size: GridSize(width: 1, height: 1)),
);
MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  triggers: const [_owner],
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
          name: 'Contact owner',
          source: NarrativeEventSourceRef.triggerBump('map', 'owner'),
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
      source: NarrativeEventSourceRef.triggerBump('map', 'owner'),
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
