import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final basis = prepareNarrativeEventProjectCatalog(
    project: _project,
    maps: [_map],
  );

  for (final (label, registry) in [
    ('the prepared registry', _registry([_meeting])),
    ('a policy change', _registry([_meeting.reusable()])),
    ('an identifier no variant reads', _registry([_meeting, _draft(_free)])),
    ('an empty registry', _registry(const [])),
    ('no registry', null),
  ]) {
    test('a fitting basis builds the full catalog for $label', () {
      expect(basis.fits(registry), isTrue);
      final reused = basis.catalog(registry);
      final full = buildNarrativeEventProjectCatalog(
        project: _project.copyWith(eventRegistry: registry),
        maps: [_map],
      );
      expect(_semantics(reused), _semantics(full));
      expect(reused.manifestHash, full.manifestHash);
      expect(reused.mapHashes, full.mapHashes);
    });
  }

  for (final (label, registry) in [
    (
      'an identifier a page condition reads',
      _registry([_meeting, _draft(_watched)]),
    ),
    ('a parallel owner', _registry([_meeting, _parallel])),
    (
      'an outcome source',
      _registry([
        _meeting,
        _draft(
          _free,
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene',
              outcomeId: 'missing',
            ),
          ),
        ),
      ]),
    ),
  ]) {
    test('the basis refuses $label', () {
      expect(basis.fits(registry), isFalse);
      expect(() => basis.catalog(registry), throwsStateError);
    });
  }

  test('a parallel owner changes what the basis judged', () {
    final full = buildNarrativeEventProjectCatalog(
      project: _project.copyWith(
        eventRegistry: _registry([_meeting, _parallel]),
      ),
      maps: [_map],
    );
    final scene = full.scenes.singleWhere((entry) => entry.scene.id == 'scene');
    expect(scene.buildable, isFalse);
    expect(
      basis.catalog(_registry([_meeting])).scenes.single.buildable,
      isTrue,
    );
  });

  group('a context bound to its catalog', () {
    late int manifestReads;
    late int mapReads;
    late NarrativeEventAuthoringContext context;
    final registry = _registry([_meeting]);

    setUp(() {
      manifestReads = 0;
      mapReads = 0;
      final built = basis.catalog(registry, deferFingerprints: true);
      context = NarrativeEventAuthoringContext.ofCatalog(
        registryState: EventRegistryDecodeResult.decoded(registry),
        revision: 'working',
        catalog: NarrativeEventProjectCatalog.withDeferredFingerprints(
          manifestHash: () {
            manifestReads++;
            return built.manifestHash;
          },
          mapHashes: () {
            mapReads++;
            return built.mapHashes;
          },
          spatialSources: built.spatialSources,
          outcomeSources: built.outcomeSources,
          scenes: built.scenes,
          facts: built.facts,
          events: built.events,
          diagnostics: built.diagnostics,
          nativeMapIds: built.nativeMapIds,
          nativeMaps: built.nativeMaps,
        ),
        sourceIndex: buildNarrativeEventSourceIndex(registry.records),
      );
    });

    test('authors without fingerprinting the manifest', () {
      expect(context.inspect('working'), isNull);
      final result = renameNarrativeEvent(
        context: context,
        expectedRevision: 'working',
        eventId: _meeting.id,
        name: 'Rencontre',
      );
      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord?.definitionOrNull?.name, 'Rencontre');
      expect([manifestReads, mapReads], [0, 0]);
      expect(context.manifestHash, isNotEmpty);
      expect([manifestReads, mapReads], [1, 0]);
    });

    test('still rejects a stale revision', () {
      expect(
        context.inspect('previous')?.status,
        NarrativeEventAuthoringStatus.staleRevision,
      );
    });

    test('still rejects a registry its catalog does not describe', () {
      final other = _registry([_meeting.reusable()]);
      final stale = NarrativeEventAuthoringContext.ofCatalog(
        registryState: EventRegistryDecodeResult.decoded(other),
        revision: 'working',
        catalog: context.catalog,
        sourceIndex: buildNarrativeEventSourceIndex(other.records),
      );
      expect(stale.inspect('working')?.code, 'staleCatalog');
    });
  });

  test('registry fingerprints follow content, not the instance', () {
    final first = narrativeEventRegistryFingerprint(_registry([_meeting]));
    expect(narrativeEventRegistryFingerprint(_registry([_meeting])), first);
    expect(
      narrativeEventRegistryFingerprint(_registry([_meeting.reusable()])),
      isNot(first),
    );
  });
}

const _free = 'evt_00000000-0000-7000-8000-000000000002';
const _watched = 'evt_00000000-0000-7000-8000-000000000009';

final _meeting = NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-000000000001',
    name: 'Meeting',
    source: NarrativeEventSourceRef.mapEnter('map'),
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 0,
  ),
  enabled: false,
);

final _parallel = NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-000000000003',
    name: 'Background',
    source: NarrativeEventSourceRef.mapEnter('map'),
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.reusable,
    priority: 0,
    order: 1,
    parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 100),
  ),
  enabled: false,
);

NarrativeEventRecord _draft(String id, {NarrativeEventSourceRef? source}) =>
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: 'Draft',
        source: source,
        conditions: const [],
        priority: 0,
        order: 0,
      ),
    );

extension on NarrativeEventRecord {
  NarrativeEventRecord reusable() =>
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: definitionOrNull!.id,
          name: definitionOrNull!.name,
          source: definitionOrNull!.source,
          conditions: definitionOrNull!.conditions,
          sceneId: definitionOrNull!.sceneId,
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: definitionOrNull!.priority,
          order: definitionOrNull!.order,
        ),
        enabled: false,
      );
}

NarrativeEventRegistry _registry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: records,
      legacyClaims: const [],
    );

final _map = MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 8, height: 8),
  entities: [
    MapEntity(
      id: 'watcher',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 2, y: 2),
      npc: const MapEntityNpcData(characterId: 'hero'),
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'after',
            condition: NarrativeEventConditionExpression.all([
              NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.narrativeEventConsumed(_watched, true),
              ),
            ]),
            characterId: 'hero',
            blocksMovement: true,
          ),
        ],
      ),
    ),
  ],
);

final _project = ProjectManifest(
  name: 'Catalog basis',
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const [],
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  characters: const [
    ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'actors'),
  ],
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(),
          ),
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
  eventRegistry: _registry([_meeting]),
);

Map<String, Object?> _semantics(NarrativeEventProjectCatalog catalog) => {
  'scenes': [for (final value in catalog.scenes) value.toDebugJson()],
  'events': [for (final value in catalog.events) value.toDebugJson()],
  'facts': [for (final value in catalog.facts) value.toDebugJson()],
  'diagnostics': [for (final value in catalog.diagnostics) value.toDebugJson()],
  'spatial': catalog.spatialSources.toDebugJson(),
  'outcomes': catalog.outcomeSources.toDebugJson(),
};
