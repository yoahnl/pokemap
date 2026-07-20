import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _eventC = 'evt_019abcde-0000-7000-8000-000000000003';
const _fingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('preparation', () {
    test('blocks invalid and unsupported registry results', () {
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.mapEnter('map'),
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts(const []);

      final invalid = NarrativeEventDispatchAuthority.prepare(
        registryResult: decodeNarrativeEventRegistry({'schemaVersion': 1}),
        occurrence: occurrence,
        factResolver: resolver,
      );
      final unsupported = NarrativeEventDispatchAuthority.prepare(
        registryResult: decodeNarrativeEventRegistry({
          'schemaVersion': 2,
          'mode': 'v2Only',
          'records': <Object?>[],
          'legacyClaims': <Object?>[],
        }),
        occurrence: occurrence,
        factResolver: resolver,
      );

      expect(invalid, isA<NarrativeEventDispatchAuthorityBlocked>());
      expect(
        (invalid as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
      );
      expect(unsupported, isA<NarrativeEventDispatchAuthorityBlocked>());
      expect(
        (unsupported as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason.unsupportedRegistry,
      );
    });

    test('dualRead requires a runtime-ready index', () {
      final registry = _registry(mode: EventSystemMode.dualRead);
      final result = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        projectCatalog: f1ProjectCatalogForRegistry(registry),
      );

      expect(result, isA<NarrativeEventDispatchAuthorityBlocked>());
      expect(
        (result as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason.dualReadClaimIndexRequired,
      );
    });

    test('Event V2 requires a matching non-blocked project catalog', () {
      final registry = _registry(
        mode: EventSystemMode.v2Only,
        records: [_record(_eventA)],
      );
      final withoutCatalog = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
      );
      final mismatched = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        projectCatalog: f1ProjectCatalogForRegistry(
          _registry(mode: EventSystemMode.v2Only),
        ),
      );
      final blockedCatalog = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        projectCatalog: f1ProjectCatalogForRegistry(
          registry,
          diagnostics: [
            NarrativeEventProjectDiagnostic(
              code: 'runtimeCatalogBlocked',
              severity: NarrativeEventProjectDiagnosticSeverity.error,
              message: 'blocked',
              path: 'catalog',
            ),
          ],
        ),
      );

      expect(
        (withoutCatalog as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason.projectCatalogRequired,
      );
      expect(
        (mismatched as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason
            .projectCatalogSnapshotMismatch,
      );
      expect(
        (blockedCatalog as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason.projectCatalogBlocked,
      );
    });

    test('global claim conflicts block dualRead preparation', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        mode: EventSystemMode.dualRead,
        records: [_record(_eventA, source: source)],
        claims: [claim, claim],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: _evidence(source, provenance),
      );

      final result = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(source: source),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        legacyClaimIndex: index,
        projectCatalog: f1ProjectCatalogForRegistry(registry),
      );

      expect(index.canRunDualRead, isFalse);
      expect(result, isA<NarrativeEventDispatchAuthorityBlocked>());
      expect(
        (result as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason.dualReadRuntimeNotReady,
      );
    });

    test('local tombstone remains ready and blocks only its source', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: _evidence(source, provenance),
      );

      final result = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: source,
          provenance: provenance,
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        legacyClaimIndex: index,
        projectCatalog: f1ProjectCatalogForRegistry(registry),
      );

      expect(index.canRunDualRead, isTrue);
      expect(result, isA<NarrativeEventDispatchAuthorityReady>());
      final decision = (result as NarrativeEventDispatchAuthorityReady).plan(
        gameState: const GameState(saveId: 'save'),
      );
      expect(decision, isA<NarrativeEventDispatchClaimedButIneligible>());
      expect(decision.legacyFallbackAllowed, isFalse);
      expect(
        decision.reasons,
        contains(NarrativeEventDispatchReason.claimTombstone),
      );
    });

    test('source and provenance mismatch becomes a typed block', () {
      final claimedSource = NarrativeEventSourceRef.mapEnter('map_a');
      final occurrenceSource = NarrativeEventSourceRef.mapEnter('map_b');
      final provenance = LegacySourceRef.mapEvent('map_a', 'legacy');
      final claim = _claim(
        source: claimedSource,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        mode: EventSystemMode.dualRead,
        records: [_record(_eventA, source: claimedSource)],
        claims: [claim],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: _evidence(claimedSource, provenance),
      );

      final result = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: occurrenceSource,
          provenance: provenance,
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        legacyClaimIndex: index,
        projectCatalog: f1ProjectCatalogForRegistry(registry),
      );

      expect(result, isA<NarrativeEventDispatchAuthorityBlocked>());
      expect(
        (result as NarrativeEventDispatchAuthorityBlocked).reason,
        NarrativeEventDispatchAuthorityBlockReason
            .claimSourceProvenanceMismatch,
      );
    });
  });

  group('truth table and eligibility', () {
    test('legacyOnly always yields fallback noMatch without claims', () {
      final ready = _prepare(
        _registry(
          mode: EventSystemMode.legacyOnly,
          records: [_record(_eventA)],
        ),
      );

      final decision = ready.plan(
        gameState: const GameState(saveId: 'save'),
      );

      expect(decision, isA<NarrativeEventDispatchNoMatch>());
      expect(decision.mode, EventSystemMode.legacyOnly);
      expect(decision.legacyFallbackAllowed, isTrue);
    });

    test('v2Only handles an eligible event and never allows fallback', () {
      final ready = _prepare(
        _registry(
          mode: EventSystemMode.v2Only,
          records: [_record(_eventA)],
        ),
      );

      final decision = ready.plan(
        gameState: const GameState(saveId: 'save'),
      );

      expect(decision, isA<NarrativeEventDispatchHandled>());
      expect((decision as NarrativeEventDispatchHandled).eventId, _eventA);
      expect(decision.legacyFallbackAllowed, isFalse);
    });

    test('applies Narrative Event World Rules before selecting a candidate',
        () {
      final registry = _registry(
        mode: EventSystemMode.v2Only,
        records: [_record(_eventA)],
      );
      final baseProject = ProjectManifest(
        name: 'World Rule dispatch',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate',
            defaultValue: true,
          ),
        ],
        eventRegistry: registry,
      );
      WorldRuleDefinition rule(
        String id,
        WorldRuleEffectKind effect,
        int priority,
      ) =>
          WorldRuleDefinition(
            id: id,
            label: id,
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_gate',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.narrativeEvent,
              mapId: '',
              eventId: _eventA,
            ),
            effect: WorldRuleEffect(kind: effect),
            priority: priority,
          );
      final disabled = _prepare(
        registry,
        project: baseProject.copyWith(
          worldRules: [
            rule('world_rule_disable', WorldRuleEffectKind.eventDisabled, 10),
          ],
        ),
      ).plan(gameState: const GameState(saveId: 'disabled'));
      final reenabled = _prepare(
        registry,
        project: baseProject.copyWith(
          worldRules: [
            rule('world_rule_disable', WorldRuleEffectKind.eventDisabled, 10),
            rule('world_rule_enable', WorldRuleEffectKind.eventEnabled, 20),
          ],
        ),
      ).plan(gameState: const GameState(saveId: 'enabled'));
      final hidden = _prepare(
        registry,
        project: baseProject.copyWith(
          worldRules: [
            rule('world_rule_hide', WorldRuleEffectKind.eventHidden, 10),
          ],
        ),
      ).plan(gameState: const GameState(saveId: 'hidden'));

      expect(disabled, isA<NarrativeEventDispatchNoMatch>());
      expect(
        disabled.reasons,
        contains(NarrativeEventDispatchReason.worldRuleDisabled),
      );
      expect(reenabled, isA<NarrativeEventDispatchHandled>());
      expect(hidden, isA<NarrativeEventDispatchNoMatch>());
      expect(
        hidden.reasons,
        contains(NarrativeEventDispatchReason.worldRuleHidden),
      );
    });

    test('unavailable runtime Scene makes the candidate ineligible', () {
      final registry = _registry(
        mode: EventSystemMode.v2Only,
        records: [_record(_eventA)],
      );
      final prepared = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        projectCatalog: f1ProjectCatalogForRegistry(
          registry,
          unavailableSceneIds: {'scene_$_eventA'},
        ),
      ) as NarrativeEventDispatchAuthorityReady;

      final decision = prepared.plan(
        gameState: const GameState(saveId: 'save'),
      );

      expect(decision, isA<NarrativeEventDispatchNoMatch>());
      expect(decision.legacyFallbackAllowed, isFalse);
      expect(
        decision.reasons,
        contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable),
      );
    });

    test('unclaimed dualRead allows fallback only when no candidate wins', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final empty = _registry(mode: EventSystemMode.dualRead);
      final emptyReady = _prepare(
        empty,
        claimIndex: buildValidatedLegacyClaimIndex(empty),
      );
      final configured = _registry(
        mode: EventSystemMode.dualRead,
        records: [_record(_eventA, source: source)],
      );
      final configuredReady = _prepare(
        configured,
        claimIndex: buildValidatedLegacyClaimIndex(configured),
      );

      final noMatch = emptyReady.plan(
        gameState: const GameState(saveId: 'save'),
      );
      final handled = configuredReady.plan(
        gameState: const GameState(saveId: 'save'),
      );

      expect(noMatch, isA<NarrativeEventDispatchNoMatch>());
      expect(noMatch.legacyFallbackAllowed, isTrue);
      expect(handled, isA<NarrativeEventDispatchHandled>());
      expect(handled.legacyFallbackAllowed, isFalse);
    });

    test('valid claim may select a non-target event from the same source', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        mode: EventSystemMode.dualRead,
        records: [
          _record(_eventA, source: source, enabled: false),
          _record(_eventB, source: source, priority: 100),
        ],
        claims: [claim],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: _evidence(source, provenance),
      );
      final ready = _prepare(
        registry,
        provenance: provenance,
        claimIndex: index,
      );

      final decision = ready.plan(
        gameState: const GameState(saveId: 'save'),
      );

      expect(decision, isA<NarrativeEventDispatchHandled>());
      expect((decision as NarrativeEventDispatchHandled).eventId, _eventB);
    });

    test('valid claim with no eligible candidate blocks fallback', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        mode: EventSystemMode.dualRead,
        records: [_record(_eventA, source: source, enabled: false)],
        claims: [claim],
      );
      final ready = _prepare(
        registry,
        provenance: provenance,
        claimIndex: buildRuntimeValidatedLegacyClaimIndex(
          registry,
          runtimeEvidence: _evidence(source, provenance),
        ),
      );

      final decision = ready.plan(
        gameState: const GameState(saveId: 'save'),
      );

      expect(decision, isA<NarrativeEventDispatchClaimedButIneligible>());
      expect(decision.legacyFallbackAllowed, isFalse);
      expect(
        decision.reasons,
        contains(NarrativeEventDispatchReason.claimTargetsIneligible),
      );
    });

    test('uses canonical Fact values and narrative progress namespace', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final facts = [
        NarrativeFactDefinition(
          id: 'fact_default_true',
          label: 'Default true',
          defaultValue: true,
        ),
      ];
      final records = [
        _record(
          _eventA,
          source: source,
          conditions: [
            NarrativeEventCondition.fact('fact_default_true', false),
            NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
          ],
        ),
        _record(
          _eventB,
          source: NarrativeEventSourceRef.mapEnter('other_map'),
        ),
      ];
      final ready = _prepare(
        _registry(mode: EventSystemMode.v2Only, records: records),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(facts),
      );
      final progress = NarrativeEventProgress(
        consumedNarrativeEventIds: const {_eventB},
      );

      final handled = ready.plan(
        gameState: GameState(
          saveId: 'save',
          consumedEventIds: const {_eventA},
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: const {'fact_default_true': false},
          ),
          narrativeEventProgress: progress,
        ),
      );
      final blockedByFact = ready.plan(
        gameState: GameState(
          saveId: 'save',
          consumedEventIds: const {_eventB},
          narrativeEventProgress: progress,
        ),
      );

      expect(handled, isA<NarrativeEventDispatchHandled>());
      expect(blockedByFact, isA<NarrativeEventDispatchNoMatch>());
      expect(
        blockedByFact.reasons,
        contains(NarrativeEventDispatchReason.factConditionFalse),
      );
    });

    test('oneShot consumed is ineligible while reusable remains eligible', () {
      final progress = NarrativeEventProgress(
        consumedNarrativeEventIds: const {_eventA, _eventB},
      );
      final ready = _prepare(
        _registry(
          mode: EventSystemMode.v2Only,
          records: [
            _record(_eventA, priority: 100),
            _record(
              _eventB,
              reusePolicy: NarrativeEventReusePolicy.reusable,
            ),
          ],
        ),
      );

      final decision = ready.plan(
        gameState: GameState(
          saveId: 'save',
          narrativeEventProgress: progress,
        ),
      );

      expect(decision, isA<NarrativeEventDispatchHandled>());
      expect((decision as NarrativeEventDispatchHandled).eventId, _eventB);
    });

    test('orders by priority desc order asc and event ID lexical', () {
      final records = [
        _record(_eventC, priority: 5, order: 0),
        _record(_eventB, priority: 10, order: 1),
        _record(_eventA, priority: 10, order: 1),
      ];
      final ready = _prepare(
        _registry(mode: EventSystemMode.v2Only, records: records),
      );

      final decisions = List.generate(
        5,
        (_) => ready.plan(gameState: const GameState(saveId: 'save')),
      );

      expect(
        decisions.cast<NarrativeEventDispatchHandled>().map((d) => d.eventId),
        everyElement(_eventA),
      );
      expect(records.map((record) => record.id), [_eventC, _eventB, _eventA]);
    });

    test('draft disabled and in-flight records do not dispatch', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final ready = _prepare(
        _registry(
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: _eventA,
                name: 'draft',
                source: source,
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
            _record(_eventB, source: source, enabled: false),
            _record(_eventC, source: source),
          ],
        ),
      );

      final decision = ready.plan(
        gameState: const GameState(saveId: 'save'),
        inFlightNarrativeEventIds: const {_eventC},
      );

      expect(decision, isA<NarrativeEventDispatchNoMatch>());
      expect(decision.reasons, contains(NarrativeEventDispatchReason.draft));
      expect(
        decision.reasons,
        contains(NarrativeEventDispatchReason.disabled),
      );
      expect(
        decision.reasons,
        contains(NarrativeEventDispatchReason.eventInFlight),
      );
    });

    test('simulation shares dispatch ordering and explains every AND leaf', () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final facts = [
        NarrativeFactDefinition(
          id: 'fact_open',
          label: 'Port ouvert',
        ),
        NarrativeFactDefinition(
          id: 'fact_blocked',
          label: 'Port bloqué',
        ),
      ];
      final registry = _registry(
        mode: EventSystemMode.v2Only,
        records: [
          _record(
            _eventB,
            source: source,
            priority: 20,
            conditions: [
              NarrativeEventCondition.fact('fact_blocked', true),
            ],
          ),
          _record(
            _eventA,
            source: source,
            priority: 10,
            conditions: [
              NarrativeEventCondition.fact('fact_open', true),
              NarrativeEventCondition.narrativeEventConsumed(_eventC, false),
            ],
          ),
          _record(
            _eventC,
            source: NarrativeEventSourceRef.mapEnter('other'),
          ),
        ],
      );
      final report = simulateNarrativeEventDispatch(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        projectCatalog: f1ProjectCatalogForRegistry(registry),
        facts: facts,
        input: NarrativeEventSimulationInput(
          targetEventId: _eventA,
          source: source,
          factValues: const {
            'fact_open': true,
            'fact_blocked': false,
          },
        ),
      );

      expect(report.status, NarrativeEventSimulationStatus.handled);
      expect(report.handledEventId, _eventA);
      expect(report.candidates.map((candidate) => candidate.eventId),
          [_eventB, _eventA]);
      expect(report.candidates.first.reasons,
          [NarrativeEventSimulationReason.factConditionFalse]);
      final target = report.targetCandidate!;
      expect(target.selected, isTrue);
      expect(target.conditions, hasLength(2));
      expect(target.conditions.every((condition) => condition.passed), isTrue);
      expect(target.priority, 10);
      expect(target.order, 0);
    });

    test('simulation exposes draft disabled source missing and consumed states',
        () {
      final source = NarrativeEventSourceRef.mapEnter('map');
      final draftWithoutSource = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: _eventA,
          name: 'À compléter',
          conditions: const [],
          priority: 0,
          order: 0,
        ),
      );
      final missingSourceRegistry = _registry(
        mode: EventSystemMode.v2Only,
        records: [draftWithoutSource],
      );
      final missing = simulateNarrativeEventDispatch(
        registryResult:
            EventRegistryDecodeResult.decoded(missingSourceRegistry),
        projectCatalog: f1ProjectCatalogForRegistry(missingSourceRegistry),
        facts: const [],
        input: NarrativeEventSimulationInput(targetEventId: _eventA),
      );

      final disabledRegistry = _registry(
        mode: EventSystemMode.v2Only,
        records: [_record(_eventA, source: source, enabled: false)],
      );
      final disabled = simulateNarrativeEventDispatch(
        registryResult: EventRegistryDecodeResult.decoded(disabledRegistry),
        projectCatalog: f1ProjectCatalogForRegistry(disabledRegistry),
        facts: const [],
        input: NarrativeEventSimulationInput(
          targetEventId: _eventA,
          source: source,
        ),
      );

      final consumedRegistry = _registry(
        mode: EventSystemMode.v2Only,
        records: [_record(_eventA, source: source)],
      );
      final consumed = simulateNarrativeEventDispatch(
        registryResult: EventRegistryDecodeResult.decoded(consumedRegistry),
        projectCatalog: f1ProjectCatalogForRegistry(consumedRegistry),
        facts: const [],
        input: NarrativeEventSimulationInput(
          targetEventId: _eventA,
          source: source,
          consumedNarrativeEventIds: const {_eventA},
        ),
      );

      expect(missing.status, NarrativeEventSimulationStatus.sourceMissing);
      expect(
          missing.targetCandidate!.reasons,
          containsAll([
            NarrativeEventSimulationReason.draft,
            NarrativeEventSimulationReason.sourceMissing,
          ]));
      expect(disabled.status, NarrativeEventSimulationStatus.noMatch);
      expect(disabled.targetCandidate!.reasons,
          [NarrativeEventSimulationReason.disabled]);
      expect(consumed.status, NarrativeEventSimulationStatus.noMatch);
      expect(consumed.targetCandidate!.reasons,
          [NarrativeEventSimulationReason.eventConsumed]);
    });

    test('evaluates any and not through the production dispatch authority', () {
      final falseFact = NarrativeEventCondition.fact('fact_false', true);
      final trueFact = NarrativeEventCondition.fact('fact_true', true);
      final anyRegistry = _registry(
        mode: EventSystemMode.v2Only,
        records: [
          _record(
            _eventA,
            conditions: [falseFact, trueFact],
            conditionExpression: NarrativeEventConditionExpression.any([
              NarrativeEventConditionExpression.leaf(falseFact),
              NarrativeEventConditionExpression.leaf(trueFact),
            ]),
          ),
        ],
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_false', label: 'False'),
        NarrativeFactDefinition(id: 'fact_true', label: 'True'),
      ]);
      final anyReady = _prepare(anyRegistry, factResolver: resolver);
      final state = GameState(
        saveId: 'save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_false': false, 'fact_true': true},
        ),
      );

      expect(anyReady.plan(gameState: state),
          isA<NarrativeEventDispatchHandled>());

      final notRegistry = _registry(
        mode: EventSystemMode.v2Only,
        records: [
          _record(
            _eventA,
            conditions: [trueFact],
            conditionExpression: NarrativeEventConditionExpression.not(
              NarrativeEventConditionExpression.leaf(trueFact),
            ),
          ),
        ],
      );
      final notReady = _prepare(notRegistry, factResolver: resolver);
      expect(notReady.plan(gameState: state),
          isA<NarrativeEventDispatchNoMatch>());
    });

    test('map re-entry reset is persisted, qualified and idempotent', () {
      final registry = _registry(
        mode: EventSystemMode.v2Only,
        records: [
          _record(
            _eventA,
            resetPolicy: const NarrativeEventResetPolicy.onMapReentry(),
          ),
        ],
      );
      final ready = _prepare(registry);
      final consumed = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventA},
          activeNarrativeMapId: 'other_map',
          visitedNarrativeMapIds: const {'map', 'other_map'},
        ),
      );

      final restored = ready.applyMapActivationReset(
        gameState: consumed,
        activationId: 'restore-1',
        mapId: 'map',
        resetEligible: false,
      );
      expect(restored.narrativeEventProgress.consumedNarrativeEventIds,
          contains(_eventA));

      final outside = restored.copyWith(
        narrativeEventProgress: restored.narrativeEventProgress.copyWith(
          activeNarrativeMapId: 'other_map',
        ),
      );
      final reentered = ready.applyMapActivationReset(
        gameState: outside,
        activationId: 'warp-2',
        mapId: 'map',
        resetEligible: true,
      );
      expect(reentered.narrativeEventProgress.consumedNarrativeEventIds,
          isNot(contains(_eventA)));
      expect(
        ready.applyMapActivationReset(
          gameState: reentered,
          activationId: 'warp-2',
          mapId: 'map',
          resetEligible: true,
        ),
        reentered,
      );
    });

    test('outcome reset uses the fully qualified producer identity once', () {
      final sceneOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'producer',
        outcomeId: 'completed',
      );
      final registry = _registry(
        mode: EventSystemMode.v2Only,
        records: [
          _record(
            _eventA,
            resetPolicy:
                NarrativeEventResetPolicy.onOutcomeReceived(sceneOutcome),
          ),
        ],
      );
      final ready = _prepare(registry);
      final state = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventA},
        ),
      );
      final collision = ready.applyOutcomeReset(
        gameState: state,
        deliveryId: 'delivery-battle',
        outcome: NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: 'producer',
          outcomeId: 'completed',
        ),
      );
      expect(collision.narrativeEventProgress.consumedNarrativeEventIds,
          contains(_eventA));

      final reset = ready.applyOutcomeReset(
        gameState: collision,
        deliveryId: 'delivery-scene',
        outcome: sceneOutcome,
      );
      expect(reset.narrativeEventProgress.consumedNarrativeEventIds,
          isNot(contains(_eventA)));
      expect(
        ready.applyOutcomeReset(
          gameState: reset,
          deliveryId: 'delivery-scene',
          outcome: sceneOutcome,
        ),
        reset,
      );
    });
  });
}

NarrativeEventDispatchAuthorityReady _prepare(
  NarrativeEventRegistry registry, {
  LegacySourceRef? provenance,
  ValidatedLegacyClaimIndex? claimIndex,
  NarrativeFactRuntimeResolver? factResolver,
  ProjectManifest? project,
}) {
  final result = NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(
      source: NarrativeEventSourceRef.mapEnter('map'),
      provenance: provenance,
    ),
    factResolver:
        factResolver ?? NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: claimIndex,
    projectCatalog: f1ProjectCatalogForRegistry(registry),
    project: project,
  );
  expect(result, isA<NarrativeEventDispatchAuthorityReady>());
  return result as NarrativeEventDispatchAuthorityReady;
}

NarrativeEventRegistry _registry({
  required EventSystemMode mode,
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
  String id, {
  NarrativeEventSourceRef? source,
  List<NarrativeEventCondition> conditions = const [],
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
  NarrativeEventConditionExpression? conditionExpression,
  NarrativeEventResetPolicy resetPolicy =
      const NarrativeEventResetPolicy.never(),
  int priority = 0,
  int order = 0,
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source ?? NarrativeEventSourceRef.mapEnter('map'),
      conditions: conditions,
      conditionExpression: conditionExpression,
      sceneId: 'scene_$id',
      reusePolicy: reusePolicy,
      priority: priority,
      order: order,
      resetPolicy: resetPolicy,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  required List<String> targetIds,
}) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _fingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: targetIds,
    migrationReceiptId: 'receipt',
  );
}

LegacyClaimRuntimeEvidence _evidence(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  return LegacyClaimRuntimeEvidence(
    entries: [
      LegacyClaimRuntimeEvidenceEntry(
        provenance: provenance,
        source: source,
        sourceFingerprint: _fingerprint,
      ),
    ],
  );
}
