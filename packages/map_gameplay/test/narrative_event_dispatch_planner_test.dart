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
