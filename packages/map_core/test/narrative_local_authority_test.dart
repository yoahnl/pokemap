import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

void main() {
  final source = NarrativeEventSourceRef.entityInteract('map', 'npc');
  final local = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: 'evt_019abcde-9000-7000-8000-000000000001',
      name: 'Conversation',
      source: source,
      conditions: [],
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: true,
    activeInLegacyMode: true,
  );
  final legacy = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: 'evt_019abcde-9000-7000-8000-000000000002',
      name: 'Ancien record dormant',
      source: source,
      conditions: [],
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 100,
      order: 0,
    ),
    enabled: true,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: [local, legacy],
    legacyClaims: [],
  );

  NarrativeEventDispatchDecision plan(
    NarrativeEventSourceRef occurrence, {
    Set<String> consumed = const {},
  }) {
    final authority = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(registry),
      occurrence: NarrativeEventOccurrence(source: occurrence),
      factResolver: NarrativeFactRuntimeResolver.fromFacts([]),
      projectCatalog: f1ProjectCatalogForRegistry(registry),
    );
    expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
    return (authority as NarrativeEventDispatchAuthorityReady).plan(
      gameState: GameState(
        saveId: 'test',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: consumed,
        ),
      ),
    );
  }

  test('opt-in survives wire roundtrip and rejects malformed values', () {
    expect(NarrativeEventRegistry.fromJson(registry.toJson()), registry);
    expect(
      NarrativeEventRecord.fromJson(legacy.toJson()).activeInLegacyMode,
      isFalse,
    );
    expect(
      () => NarrativeEventRecord.fromJson({
        ...local.toJson(),
        'activeInLegacyMode': 'yes',
      }),
      throwsA(anything),
    );
  });
  test(
    'local source uses canonical authority without enabling dormant records',
    () {
      final decision = plan(source);
      expect(decision, isA<NarrativeEventDispatchHandled>());
      expect((decision as NarrativeEventDispatchHandled).eventId, local.id);
      expect(decision.mode, EventSystemMode.legacyOnly);
    },
  );
  test(
    'consumed local source cannot fall through and run a second authority',
    () {
      final decision = plan(source, consumed: {local.id});
      expect(decision, isA<NarrativeEventDispatchNoMatch>());
      expect(
        (decision as NarrativeEventDispatchNoMatch).legacyFallbackAllowed,
        isFalse,
      );
    },
  );
  test('unclaimed sources keep their previous legacy authority', () {
    final decision = plan(
      NarrativeEventSourceRef.entityInteract('map', 'another'),
    );
    expect(decision, isA<NarrativeEventDispatchNoMatch>());
    expect(
      (decision as NarrativeEventDispatchNoMatch).legacyFallbackAllowed,
      isTrue,
    );
  });
}
