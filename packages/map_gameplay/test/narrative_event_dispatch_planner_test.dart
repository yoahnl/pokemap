import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';

void main() {
  test('plans all four occurrence kinds through prepared authority', () {
    final outcome = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene_intro',
      outcomeId: 'complete',
    );
    final sources = <NarrativeEventSourceRef>[
      NarrativeEventSourceRef.entityInteract('map', 'npc'),
      NarrativeEventSourceRef.triggerEnter('map', 'trigger'),
      NarrativeEventSourceRef.mapEnter('map'),
      NarrativeEventSourceRef.outcomeReceived(outcome),
    ];
    final planner = NarrativeEventDispatchPlanner();

    for (final source in sources) {
      final decision = planner.plan(
        authority: _prepare(source, [_record(_eventA, source)]),
        gameState: const GameState(saveId: 'save'),
      );

      expect(decision, isA<NarrativeEventDispatchHandled>());
      expect(decision.source, source);
      expect((decision as NarrativeEventDispatchHandled).eventId, _eventA);
    }
  });

  test(
      'autorun planning re-evaluates the local instance flag without consuming it',
      () {
    final prepared = _autorunAuthority();
    final source = prepared.source;
    final planner = NarrativeEventDispatchPlanner();
    final initial = _autorunState();
    final first = planner.plan(authority: prepared.authority, gameState: initial);
    final repeated =
        planner.plan(authority: prepared.authority, gameState: initial);

    expect(first, isA<NarrativeEventDispatchHandled>());
    expect(repeated, isA<NarrativeEventDispatchHandled>());
    expect(first.source, source);
    expect(source.kind.name, 'entityAutorun');
    expect(source, isNot(NarrativeEventSourceRef.mapEnter('map')));
    expect(source, isNot(NarrativeEventSourceRef.entityInteract('map', 'owner')));
    final scope = initial.mapInstanceWorldState.instanceRef('map')!;
    final closed = initial.copyWith(
      mapInstanceWorldState:
          initial.mapInstanceWorldState.setEventBoolean(scope, 'owner', 'A', true),
    );
    final ineligible =
        planner.plan(authority: prepared.authority, gameState: closed);

    expect(ineligible, isA<NarrativeEventDispatchNoMatch>());
    expect(
      ineligible.reasons,
      contains(NarrativeEventDispatchReason.mapEventInstanceBooleanConditionFalse),
    );
    expect(
      planner.plan(authority: prepared.authority, gameState: initial),
      isA<NarrativeEventDispatchHandled>(),
    );
    expect(initial.mapInstanceWorldState.eventBoolean(scope, 'owner', 'A'),
        isFalse);
    expect(initial.narrativeEventProgress.consumedNarrativeEventIds, isEmpty);
  });

  test('autorun planner respects in-flight and missing logical instance guards',
      () {
    final prepared = _autorunAuthority();
    final planner = NarrativeEventDispatchPlanner();
    final inFlight = planner.plan(
      authority: prepared.authority,
      gameState: _autorunState(),
      inFlightNarrativeEventIds: {_eventA},
    );

    expect(inFlight, isA<NarrativeEventDispatchNoMatch>());
    expect(inFlight.reasons, contains(NarrativeEventDispatchReason.eventInFlight));
    expect(inFlight.legacyFallbackAllowed, isFalse);
    final missing = planner.plan(
      authority: prepared.authority,
      gameState: const GameState(saveId: 'save'),
    );

    expect(missing, isA<NarrativeEventDispatchNoMatch>());
    expect(missing.reasons,
        contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable));
    expect(missing.legacyFallbackAllowed, isFalse);
  });

  test('forwards an immutable in-flight snapshot without mutating inputs', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final input = <String>{_eventA};
    final authority = _prepare(source, [_record(_eventA, source)]);

    final decision = NarrativeEventDispatchPlanner().plan(
      authority: authority,
      gameState: const GameState(saveId: 'save'),
      inFlightNarrativeEventIds: input,
    );

    expect(decision, isA<NarrativeEventDispatchNoMatch>());
    expect(
        decision.reasons, contains(NarrativeEventDispatchReason.eventInFlight));
    expect(input, {_eventA});
    expect(() => decision.reasons.add(NarrativeEventDispatchReason.disabled),
        throwsUnsupportedError);
  });
}

NarrativeEventDispatchAuthorityReady _prepare(
  NarrativeEventSourceRef source,
  List<NarrativeEventRecord> records,
) {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: records,
    legacyClaims: const [],
  );
  final result = NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(source: source),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  );
  return result as NarrativeEventDispatchAuthorityReady;
}

NarrativeEventRecord _record(
  String id,
  NarrativeEventSourceRef source,
) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene_$id',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

GameState _autorunState() => GameState(
      saveId: 'save',
      currentMapId: 'map',
      mapInstanceWorldState: MapInstanceWorldState(
        instancesByMapId: {
          'map': MapInstanceRuntimeState(instanceId: 'map-instance'),
        },
      ),
    );

({NarrativeEventDispatchAuthorityReady authority, NarrativeEventSourceRef source})
    _autorunAuthority() {
  final source = NarrativeEventSourceRef.fromJson({
    'kind': 'entityAutorun',
    'mapId': 'map',
    'entityId': 'owner',
  });
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventA,
      name: 'Automatic local owner',
      source: source,
      sceneId: 'scene',
      conditions: [
        NarrativeEventCondition.mapEventInstanceBoolean(
          mapId: 'map',
          eventId: 'owner',
          key: 'A',
          expectedValue: false,
        ),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [record],
    legacyClaims: const [],
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    entities: const [
      MapEntity(
        id: 'owner',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 2),
        blocksMovement: false,
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'Native autorun',
    eventRegistry: registry,
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
    ],
    tilesets: const [],
    scenes: [
      SceneAsset.fromJson({
        'id': 'scene',
        'name': 'Scene',
        'graph': {
          'startNodeId': 'start',
          'nodes': [
            {'id': 'start', 'kind': 'start'},
            {'id': 'end', 'kind': 'end'},
          ],
          'edges': [
            {
              'id': 'completed',
              'fromNodeId': 'start',
              'fromPortId': 'completed',
              'toNodeId': 'end',
              'kind': 'default',
            },
          ],
        },
      }),
    ],
  );
  final authority = NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(source: source),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    projectCatalog:
        buildNarrativeEventProjectCatalog(project: project, maps: [map]),
    project: project,
    maps: [map],
  );
  expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
  return (
    authority: authority as NarrativeEventDispatchAuthorityReady,
    source: source,
  );
}
