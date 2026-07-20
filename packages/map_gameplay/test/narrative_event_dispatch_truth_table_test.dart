import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _fingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('legacyOnly and v2Only expose their closed fallback decisions', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final planner = NarrativeEventDispatchPlanner();

    final legacy = planner.plan(
      authority: _prepare(_registry(EventSystemMode.legacyOnly), source),
      gameState: const GameState(saveId: 'save'),
    );
    final v2NoMatch = planner.plan(
      authority: _prepare(_registry(EventSystemMode.v2Only), source),
      gameState: const GameState(saveId: 'save'),
    );
    final v2Handled = planner.plan(
      authority: _prepare(
        _registry(EventSystemMode.v2Only, records: [_record(_eventA, source)]),
        source,
      ),
      gameState: const GameState(saveId: 'save'),
    );

    expect(legacy, isA<NarrativeEventDispatchNoMatch>());
    expect(legacy.legacyFallbackAllowed, isTrue);
    expect(v2NoMatch, isA<NarrativeEventDispatchNoMatch>());
    expect(v2NoMatch.legacyFallbackAllowed, isFalse);
    expect(v2Handled, isA<NarrativeEventDispatchHandled>());
    expect(v2Handled.legacyFallbackAllowed, isFalse);
  });

  test('unclaimed dualRead falls back only when no candidate is eligible', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final empty = _registry(EventSystemMode.dualRead);
    final configured = _registry(
      EventSystemMode.dualRead,
      records: [_record(_eventA, source)],
    );
    final planner = NarrativeEventDispatchPlanner();

    final noMatch = planner.plan(
      authority: _prepare(
        empty,
        source,
        claimIndex: buildValidatedLegacyClaimIndex(empty),
      ),
      gameState: const GameState(saveId: 'save'),
    );
    final handled = planner.plan(
      authority: _prepare(
        configured,
        source,
        claimIndex: buildValidatedLegacyClaimIndex(configured),
      ),
      gameState: const GameState(saveId: 'save'),
    );

    expect(noMatch, isA<NarrativeEventDispatchNoMatch>());
    expect(noMatch.legacyFallbackAllowed, isTrue);
    expect(handled, isA<NarrativeEventDispatchHandled>());
  });

  test('valid claim blocks fallback and may select a non-target candidate', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final provenance = LegacySourceRef.mapEvent('map', 'legacy');
    final claim = _claim(source, provenance, [_eventA]);
    final ineligible = _registry(
      EventSystemMode.dualRead,
      records: [_record(_eventA, source, enabled: false)],
      claims: [claim],
    );
    final nonTarget = _registry(
      EventSystemMode.dualRead,
      records: [
        _record(_eventA, source, enabled: false),
        _record(_eventB, source, priority: 10),
      ],
      claims: [claim],
    );
    final planner = NarrativeEventDispatchPlanner();

    final claimed = planner.plan(
      authority: _prepare(
        ineligible,
        source,
        provenance: provenance,
        claimIndex: _runtimeIndex(ineligible, source, provenance),
      ),
      gameState: const GameState(saveId: 'save'),
    );
    final handled = planner.plan(
      authority: _prepare(
        nonTarget,
        source,
        provenance: provenance,
        claimIndex: _runtimeIndex(nonTarget, source, provenance),
      ),
      gameState: const GameState(saveId: 'save'),
    );

    expect(claimed, isA<NarrativeEventDispatchClaimedButIneligible>());
    expect(claimed.legacyFallbackAllowed, isFalse);
    expect(claimed.reasons,
        contains(NarrativeEventDispatchReason.claimTargetsIneligible));
    expect((handled as NarrativeEventDispatchHandled).eventId, _eventB);
  });

  test('valid claim blocks fallback when its oneShot target is consumed', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final provenance = LegacySourceRef.mapEvent('map', 'legacy');
    final claim = _claim(source, provenance, [_eventA]);
    final registry = _registry(
      EventSystemMode.dualRead,
      records: [_record(_eventA, source)],
      claims: [claim],
    );

    final decision = NarrativeEventDispatchPlanner().plan(
      authority: _prepare(
        registry,
        source,
        provenance: provenance,
        claimIndex: _runtimeIndex(registry, source, provenance),
      ),
      gameState: GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: {_eventA},
        ),
      ),
    );

    expect(decision, isA<NarrativeEventDispatchClaimedButIneligible>());
    expect(decision.legacyFallbackAllowed, isFalse);
    expect(
      decision.reasons,
      orderedEquals([
        NarrativeEventDispatchReason.eventConsumed,
        NarrativeEventDispatchReason.claimTargetsIneligible,
        NarrativeEventDispatchReason.noEligibleCandidate,
      ]),
    );
  });

  test('local claim tombstone blocks only that occurrence', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final provenance = LegacySourceRef.mapEvent('map', 'legacy');
    final claim = _claim(source, provenance, [_eventA]);
    final registry = _registry(EventSystemMode.dualRead, claims: [claim]);

    final decision = NarrativeEventDispatchPlanner().plan(
      authority: _prepare(
        registry,
        source,
        provenance: provenance,
        claimIndex: _runtimeIndex(registry, source, provenance),
      ),
      gameState: const GameState(saveId: 'save'),
    );

    expect(decision, isA<NarrativeEventDispatchClaimedButIneligible>());
    expect(decision.reasons,
        contains(NarrativeEventDispatchReason.claimTombstone));
  });

  test('Event Builder simulation returns the same winner as gameplay planner',
      () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final registry = _registry(
      EventSystemMode.v2Only,
      records: [
        _record(_eventA, source, priority: 2),
        _record(_eventB, source, priority: 8),
      ],
    );
    final authority = _prepare(registry, source);
    final gameplayDecision = NarrativeEventDispatchPlanner().plan(
      authority: authority,
      gameState: const GameState(saveId: 'save'),
    ) as NarrativeEventDispatchHandled;
    final simulation = authority.simulate(
      gameState: const GameState(saveId: 'preview'),
      targetEventId: _eventA,
    );

    expect(gameplayDecision.eventId, _eventB);
    expect(simulation.handledEventId, gameplayDecision.eventId);
    expect(
        simulation.candidates
            .singleWhere((candidate) => candidate.selected)
            .eventId,
        gameplayDecision.eventId);
  });
}

NarrativeEventDispatchAuthorityReady _prepare(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source, {
  LegacySourceRef? provenance,
  ValidatedLegacyClaimIndex? claimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence:
        NarrativeEventOccurrence(source: source, provenance: provenance),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: claimIndex,
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  ) as NarrativeEventDispatchAuthorityReady;
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  String id,
  NarrativeEventSourceRef source, {
  bool enabled = true,
  int priority = 0,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene_$id',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: priority,
      order: 0,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
  List<String> targetIds,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _fingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: targetIds,
    migrationReceiptId: 'receipt',
  );
}

ValidatedLegacyClaimIndex _runtimeIndex(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  return buildRuntimeValidatedLegacyClaimIndex(
    registry,
    runtimeEvidence: LegacyClaimRuntimeEvidence(
      entries: [
        LegacyClaimRuntimeEvidenceEntry(
          provenance: provenance,
          source: source,
          sourceFingerprint: _fingerprint,
        ),
      ],
    ),
  );
}
