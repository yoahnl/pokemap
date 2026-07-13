import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C4 migration planner', () {
    test('returns an empty plan without consuming IDs or clock values', () {
      final ids = _InjectedIds.forbidden();
      var clockCalls = 0;
      final plan = NarrativeEventMigrationPlanner(
        ids: ids,
        clock: () {
          clockCalls++;
          throw StateError('clock must stay unused');
        },
      ).plan(_input());

      expect(plan.status, NarrativeEventMigrationPlanStatus.empty);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(ids.calls, 0);
      expect(clockCalls, 0);
    });

    test('blocks an orphan registry claim instead of returning empty', () {
      final provenance = LegacySourceRef.mapEvent('map_orphan', 'legacy_a');
      final source = NarrativeEventSourceRef.mapEnter('map_orphan');
      const eventId = 'evt_018f0000-0000-7000-8000-000000000001';
      const receiptId = 'evmr_018f0000-0000-7000-8000-000000000002';
      final member = LegacySourceClaimMember(
        provenance: provenance,
        sourceFingerprint: _hash('a'),
      );
      final cohortId = computeLegacySourceCohortId(source, [provenance]);
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: eventId,
              name: 'Orphan target',
              source: source,
              conditions: const [],
              sceneId: 'scene_a',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: false,
          ),
        ],
        legacyClaims: [
          LegacySourceClaim(
            cohortId: cohortId,
            source: source,
            members: [member],
            cohortFingerprint: computeLegacySourceCohortFingerprint(
              cohortId,
              [member],
            ),
            targetEventIds: const [eventId],
            migrationReceiptId: receiptId,
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(project: _project(eventRegistry: registry)),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim),
      );
      expect(ids.calls, 0);
    });

    test('blocks an orphan receipt instead of returning empty', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final prepared = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(existingReceipt: prepared.receiptProposal),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('plans a simple AUTO_SAFE project with complete claim and receipt',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final ids = _InjectedIds(
        eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
      );
      final input = _input(mapProjections: [projection]);
      final projectBefore = jsonEncode(input.project.toJson());
      final projectionBefore = jsonEncode(projection.toJson());

      final plan = _planner(ids).plan(input);

      expect(plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(plan.recordsProposed, hasLength(1));
      expect(plan.draftsProposed, isEmpty);
      expect(plan.claimsProposed, hasLength(1));
      expect(plan.cohorts.single.complete, isTrue);
      expect(plan.cohorts.single.claimStatus,
          NarrativeEventMigrationCohortClaimStatus.proposed);
      expect(plan.claimsProposed.single.members, hasLength(1));
      expect(plan.claimsProposed.single.targetEventIds,
          [plan.recordsProposed.single.id]);
      expect(plan.mappings.pageMappings.single.status,
          NarrativeEventPageMappingStatus.mapped);
      expect(plan.receiptProposal, isNotNull);
      expect(plan.receiptProposal!.isProposal, isTrue);
      expect(plan.receiptProposal!.targetClaims, plan.claimsProposed);
      expect(plan.receiptProposal!.snapshot.mapHashes, contains('map_a'));
      expect(
        plan.receiptProposal!.schemaVersion,
        NarrativeEventMigrationReceipt.currentSchemaVersion,
      );
      expect(
        plan.receiptProposal!.sourceChoices.single.kind,
        NarrativeEventMigrationSourceChoiceKind.confirmCandidate,
      );
      expect(
        plan.autoSafeItems.single.choiceKind,
        NarrativeEventMigrationSourceChoiceKind.confirmCandidate,
      );
      expect(plan.canApply, isTrue);
      expect(plan.pointOfNoReturn.reached, isFalse);
      expect(jsonEncode(input.project.toJson()), projectBefore);
      expect(jsonEncode(projection.toJson()), projectionBefore);
    });

    test('requires every MapEvent target Scene to exist and be buildable', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final maps = _mapsForProjections([projection], const []);
      final validScene = _sceneForMapTarget('scene_a');
      final projects = [
        _project(mapIds: const ['map_a']),
        _project(
          mapIds: const ['map_a'],
          scenes: [validScene, validScene],
        ).copyWith(scenes: [validScene, validScene]),
        _project(
          mapIds: const ['map_a'],
          scenes: [_unbuildableScene('scene_a')],
        ),
      ];

      for (final project in projects) {
        final ids = _InjectedIds.forbidden();
        final plan = _planner(ids).plan(
          _input(
            project: project,
            maps: maps,
            mapProjections: [projection],
            currentSnapshot: _snapshot(
              [projection],
              project: project,
              maps: maps,
            ),
          ),
        );

        expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
        expect(
          plan.diagnostics.map((diagnostic) => diagnostic.path),
          contains('scenes.scene_a'),
        );
        expect(ids.calls, 0);
      }
    });

    test('requires an explicit MapEvent lifecycle before proposing a claim',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final ids = _InjectedIds.standardTwo();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices.empty(),
        ),
      );

      expect(
        plan.status,
        NarrativeEventMigrationPlanStatus.assistanceRequired,
      );
      expect(plan.draftsProposed, hasLength(1));
      expect(plan.draftsProposed.single.draftOrNull!.reusePolicy, isNull);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(plan.canApply, isFalse);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.lifecycleChoiceRequired,
        ),
      );
    });

    test('does not let a MapEvent lifecycle choice rename the source event',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final originalChoice = _defaultChoices([projection]).sourceChoices.single;
      final originalTarget = originalChoice.targets.single;
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [
              NarrativeEventMigrationSourceChoice.confirmCandidate(
                provenance: projection.provenance,
                source: originalChoice.source,
                targets: [
                  NarrativeEventMigrationTargetProposal(
                    name: 'Silent rename',
                    legacyPageIndex: originalTarget.legacyPageIndex,
                    conditions: originalTarget.conditions,
                    sceneId: originalTarget.sceneId,
                    reusePolicy: originalTarget.reusePolicy,
                    priority: originalTarget.priority,
                    order: originalTarget.order,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
        ),
      );
      expect(ids.calls, 0);
    });

    test('rejects a candidate confirmation outside the projection inventory',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_hint'),
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'f',
      );
      final choice = NarrativeEventMigrationSourceChoice.confirmCandidate(
        provenance: projection.provenance,
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_other'),
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Assisted event',
            legacyPageIndex: 0,
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.receiptProposal, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
        ),
      );
      expect(ids.calls, 0);
    });

    test('keeps classification buckets and proposes only an assisted draft',
        () {
      final projections = [
        _projection(
          mapId: 'map_auto',
          legacyEventId: 'auto',
          source:
              NarrativeEventSourceRef.entityInteract('map_auto', 'npc_auto'),
          sceneId: 'scene_auto',
          fingerprintCharacter: 'a',
        ),
        _projection(
          mapId: 'map_assisted',
          legacyEventId: 'assisted',
          source: NarrativeEventSourceRef.entityInteract(
            'map_assisted',
            'npc_assisted',
          ),
          sceneId: 'scene_assisted',
          classification: LegacyMigrationClassification.assisted,
          confirmed: false,
          fingerprintCharacter: 'b',
        ),
        _projection(
          mapId: 'map_blocked',
          legacyEventId: 'blocked',
          source: NarrativeEventSourceRef.entityInteract(
            'map_blocked',
            'npc_blocked',
          ),
          sceneId: 'scene_blocked',
          classification: LegacyMigrationClassification.blocked,
          fingerprintCharacter: 'c',
        ),
        _projection(
          mapId: 'map_unsupported',
          legacyEventId: 'unsupported',
          source: NarrativeEventSourceRef.entityInteract(
            'map_unsupported',
            'npc_unsupported',
          ),
          sceneId: 'scene_unsupported',
          classification: LegacyMigrationClassification.unsupported,
          fingerprintCharacter: 'd',
        ),
        _projection(
          mapId: 'map_legacy_only',
          legacyEventId: 'legacy_only',
          source: NarrativeEventSourceRef.triggerEnter(
            'map_legacy_only',
            'trigger_legacy_only',
          ),
          sceneId: 'scene_legacy_only',
          classification: LegacyMigrationClassification.legacyOnly,
          fingerprintCharacter: '8',
        ),
      ];
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(_input(mapProjections: projections));

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.autoSafeItems, hasLength(1));
      expect(plan.assistedItems, hasLength(1));
      expect(plan.blockedItems, hasLength(1));
      expect(plan.unsupportedItems, hasLength(1));
      expect(plan.legacyOnlyItems, hasLength(1));
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(plan.canApply, isFalse);
      expect(ids.calls, 0);
    });

    test('keeps every multi-page mapping and refuses a partial claim', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'pages',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.blocked,
        fingerprintCharacter: 'e',
        pages: [
          LegacyMapEventPageProjection(
            pageIndex: 0,
            pageNumber: 30,
            condition: null,
            script: null,
            spriteId: null,
            message: null,
            sceneId: 'scene_a',
            isHidden: false,
            isDisabled: false,
            metadata: {},
          ),
          LegacyMapEventPageProjection(
            pageIndex: 1,
            pageNumber: 20,
            condition: null,
            script: null,
            spriteId: null,
            message: null,
            sceneId: 'scene_b',
            isHidden: true,
            isDisabled: false,
            metadata: {'future': 'kept'},
          ),
        ],
      );

      final plan = _planner(_InjectedIds.forbidden()).plan(
        _input(mapProjections: [projection]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.mappings.pageMappings, hasLength(2));
      expect(
        plan.mappings.pageMappings.map((mapping) => mapping.pageNumber),
        [30, 20],
      );
      expect(
        plan.mappings.pageMappings.every(
          (mapping) =>
              mapping.status == NarrativeEventPageMappingStatus.preservedLegacy,
        ),
        isTrue,
      );
      expect(plan.claimsProposed, isEmpty);
    });

    test('validates an explicit ASSISTED reassignment against D0-B context',
        () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_confirmed');
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_hint'),
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'f',
      );
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: source,
        reason: 'Le PNJ confirmé remplace le candidat legacy ambigu.',
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Confirmed event',
            legacyPageIndex: 0,
            conditions: [NarrativeEventCondition.fact('fact_a', true)],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 2,
            order: 3,
          ),
        ],
      );
      final ids = _InjectedIds.standardTwo();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(plan.assistedItems.single.choiceApplied, isTrue);
      expect(
        plan.assistedItems.single.choiceKind,
        NarrativeEventMigrationSourceChoiceKind.explicitReassignment,
      );
      expect(
        plan.assistedItems.single.reassignmentReason,
        'Le PNJ confirmé remplace le candidat legacy ambigu.',
      );
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.explicitReassignmentValidated,
        ),
      );
      expect(plan.recordsProposed, hasLength(1));
      expect(plan.claimsProposed, hasLength(1));
      expect(plan.receiptProposal, isNotNull);
      expect(ids.calls, 2);
    });

    test('plans an AUTO_SAFE Scenario source with its proven lifecycle', () {
      final source = NarrativeEventSourceRef.mapEnter('map_a');
      final provenance =
          LegacySourceRef.scenarioSourceNode('scenario_a', 'source_a');
      final projection = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: source,
        fingerprintCharacter: 'a',
      );
      final ids = _InjectedIds.standardTwo();

      final plan = _planner(ids).plan(
        _input(scenarioProjections: [projection]),
      );

      expect(
        plan.status,
        NarrativeEventMigrationPlanStatus.ready,
        reason:
            plan.diagnostics.map((diagnostic) => diagnostic.toJson()).join(),
      );
      expect(plan.recordsProposed.single.definitionOrNull!.source, source);
      expect(
        plan.recordsProposed.single.definitionOrNull!.reusePolicy,
        NarrativeEventReusePolicy.oneShot,
      );
      expect(plan.claimsProposed.single.members.single.provenance, provenance);
    });

    test('rejects forged Scenario projection content before allocation', () {
      final canonical = _scenarioProjection(
        scenarioId: 'scenario_forged',
        nodeId: 'source',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: 'f',
      );
      final forged = LegacyScenarioSourceProjection(
        scenarioId: canonical.scenarioId,
        nodeId: canonical.nodeId,
        provenance: canonical.provenance,
        source: NarrativeEventSourceRef.mapEnter('map_b'),
        sceneCandidateId: canonical.sceneCandidateId,
        lifecycleEvidence: canonical.lifecycleEvidence,
        reusePolicyCandidate: canonical.reusePolicyCandidate,
        graphComplexity: canonical.graphComplexity,
        classification: canonical.classification,
        claimStatus: canonical.claimStatus,
        existingClaim: canonical.existingClaim,
        sourceFingerprint: canonical.sourceFingerprint,
        actions: canonical.actions,
        conditions: canonical.conditions,
        preservedScenarioJson: canonical.preservedScenarioJson,
        diagnostics: canonical.diagnostics,
        manualActions: canonical.manualActions,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(scenarioProjections: [forged]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.canApply, isFalse);
      expect(plan.receiptProposal, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.projectionEvidenceMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('revalidates the current Scene proof for AUTO_SAFE Scenario sources',
        () {
      final projection = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: 'a',
      );
      final scenarios = _scenariosForProjections([projection]);
      final maps = _mapsForProjections(const [], [projection]);
      final invalidProjects = [
        _project(
          mapIds: const ['map_a'],
          scenarios: scenarios,
        ),
        _project(
          mapIds: const ['map_a'],
          scenarios: scenarios,
          scenes: [
            _sceneForScenario(
              'scenario_a',
              dialogueId: 'changed_dialogue',
            ),
          ],
        ),
      ];

      for (final project in invalidProjects) {
        final ids = _InjectedIds.forbidden();
        final plan = _planner(ids).plan(
          _input(
            project: project,
            maps: maps,
            scenarioProjections: [projection],
            currentSnapshot: _snapshot(
              const [],
              scenarioProjections: [projection],
              project: project,
              maps: maps,
            ),
          ),
        );

        expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
        expect(
          plan.diagnostics.map((diagnostic) => diagnostic.path),
          contains('scenes.scene_scenario_a'),
        );
        expect(ids.calls, 0);
      }
    });

    test('rejects duplicate Scenario IDs before source inventory matching', () {
      final projection = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: 'a',
      );
      final scenario = _scenariosForProjections([projection]).single;
      final maps = _mapsForProjections(const [], [projection]);
      final project = _project(
        mapIds: const ['map_a'],
        scenarios: [scenario, scenario],
        scenes: _scenesForProjections([projection]),
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          scenarioProjections: [projection],
          currentSnapshot: _snapshot(
            const [],
            scenarioProjections: [projection],
            project: project,
            maps: maps,
          ),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('project.scenarios.scenario_a'),
      );
      expect(ids.calls, 0);
    });

    test('blocks a qualified Scenario source absent from the outcome catalog',
        () {
      final qualifiedSource = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer_scene',
          outcomeId: 'victory',
        ),
      );
      final projection = _scenarioProjection(
        scenarioId: 'scenario_outcome',
        nodeId: 'source',
        source: qualifiedSource,
        fingerprintCharacter: 'b',
      );
      expect(
        projection.classification,
        LegacyMigrationClassification.assisted,
      );
      expect(projection.source, isNull);
      final validTarget = NarrativeEventMigrationTargetProposal(
        name: 'Scenario scenario_outcome',
        conditions: const [],
        sceneId: 'scene_scenario_outcome',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      );
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: qualifiedSource,
        targets: [validTarget],
        reason: 'Le résultat legacy est qualifié par la scène productrice.',
      );
      final ids = _InjectedIds.forbidden();
      final plan = _planner(ids).plan(
        _input(
          scenarioProjections: [projection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [choice],
          ),
        ),
      );
      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.receiptProposal, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.sourceUnavailable,
        ),
      );
      expect(ids.calls, 0);
    });

    test('accepts and replays an explicit Scenario producer reassignment', () {
      final legacyHint = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'legacy_hint',
          outcomeId: 'victory',
        ),
      );
      final reassignedSource = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer_confirmed',
          outcomeId: 'victory',
        ),
      );
      final projection = _scenarioProjection(
        scenarioId: 'scenario_reassigned',
        nodeId: 'source',
        source: legacyHint,
        fingerprintCharacter: 'c',
      );
      expect(
        projection.classification,
        LegacyMigrationClassification.assisted,
      );
      final target = NarrativeEventMigrationTargetProposal(
        name: 'Scenario scenario_reassigned',
        conditions: const [],
        sceneId: 'scene_scenario_reassigned',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      );
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: reassignedSource,
        targets: [target],
        reason: 'Le producteur exact a été confirmé dans le projet.',
      );
      final scenarios = _scenariosForProjections([projection]);
      final scenes = [
        _sceneForScenario('scenario_reassigned'),
        _outcomeProducerScene('producer_confirmed', 'victory'),
      ];
      final project = _project(scenarios: scenarios, scenes: scenes);
      final choices = NarrativeEventMigrationChoices(sourceChoices: [choice]);
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(
          project: project,
          scenarioProjections: [projection],
          choices: choices,
        ),
      );

      expect(
        first.status,
        NarrativeEventMigrationPlanStatus.ready,
        reason:
            first.diagnostics.map((diagnostic) => diagnostic.toJson()).join(),
      );
      expect(first.canApply, isTrue);
      expect(
        first.recordsProposed.single.definitionOrNull!.source,
        reassignedSource,
      );
      expect(first.items.single.choiceApplied, isTrue);
      expect(
        first.items.single.choiceKind,
        NarrativeEventMigrationSourceChoiceKind.explicitReassignment,
      );

      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final replayProject = project.copyWith(eventRegistry: registry);
      final replayIds = _InjectedIds.forbidden();
      final replay = _planner(replayIds).plan(
        _input(
          project: replayProject,
          scenarioProjections: [projection],
          choices: NarrativeEventMigrationChoices.empty(),
          currentSnapshot: _snapshot(
            const [],
            scenarioProjections: [projection],
            project: replayProject,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(
        replay.status,
        NarrativeEventMigrationPlanStatus.alreadyPrepared,
      );
      expect(replay.items.single.source, reassignedSource);
      expect(replay.items.single.choiceApplied, isTrue);
      expect(replayIds.calls, 0);
    });

    test('rejects reassignment of an AUTO_SAFE Scenario before allocation', () {
      final source = NarrativeEventSourceRef.mapEnter('map_a');
      final projection = _scenarioProjection(
        scenarioId: 'scenario_auto_reassigned',
        nodeId: 'source',
        source: source,
        fingerprintCharacter: 'd',
      );
      expect(
        projection.classification,
        LegacyMigrationClassification.autoSafe,
      );
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Changed semantics',
            conditions: const [],
            sceneId: 'scene_scenario_auto_reassigned',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 9,
            order: 9,
          ),
        ],
        reason: 'This override must not weaken AUTO_SAFE evidence.',
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          scenarioProjections: [projection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.receiptProposal, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
        ),
      );
      expect(ids.calls, 0);
    });

    test('is idempotent with an exact existing registry and receipt', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(
        _InjectedIds(
          eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
          receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
        ),
      ).plan(_input(mapProjections: [projection]));
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final secondInput = _input(
        project: project,
        mapProjections: [projection],
        choices: NarrativeEventMigrationChoices.empty(),
        currentSnapshot: _snapshot(
          [projection],
          project: project,
        ),
        existingReceipt: first.receiptProposal,
      );
      final forbiddenIds = _InjectedIds.forbidden();

      final second = _planner(forbiddenIds).plan(secondInput);

      expect(second.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(second.recordsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(second.cohorts.single.claimStatus,
          NarrativeEventMigrationCohortClaimStatus.existing);
      expect(
        second.receiptProposal!.toJson(),
        first.receiptProposal!.toJson(),
      );
      expect(
        second.autoSafeItems.single.choiceKind,
        NarrativeEventMigrationSourceChoiceKind.confirmCandidate,
      );
      expect(second.autoSafeItems.single.choiceApplied, isTrue);
      expect(forbiddenIds.calls, 0);
    });

    test('restores distinct per-provenance targets from an exact receipt', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_shared');
      final firstProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '1',
      );
      final secondProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_b',
        source: source,
        sceneId: 'scene_b',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '2',
      );
      final choices = NarrativeEventMigrationChoices(
        sourceChoices: [
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: firstProjection.provenance,
            source: source,
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: 'First target',
                legacyPageIndex: 0,
                conditions: const [],
                sceneId: 'scene_a',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
            ],
          ),
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: secondProjection.provenance,
            source: source,
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: 'Second target',
                legacyPageIndex: 0,
                conditions: const [],
                sceneId: 'scene_b',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
            ],
          ),
        ],
      );
      final initialInput = _input(
        mapProjections: [firstProjection, secondProjection],
        choices: choices,
      );
      final first = _planner(
        _InjectedIds(
          eventIds: const [
            'evt_018f0000-0000-7000-8000-000000000001',
            'evt_018f0000-0000-7000-8000-000000000002',
          ],
          receiptIds: const [
            'evmr_018f0000-0000-7000-8000-000000000003',
          ],
        ),
      ).plan(initialInput);
      expect(first.status, NarrativeEventMigrationPlanStatus.ready);
      expect(first.recordsProposed, hasLength(2));
      final claim = first.claimsProposed.single;
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: [claim],
      );
      final project = initialInput.project.copyWith(eventRegistry: registry);
      final claimedProjections = [
        _projection(
          mapId: 'map_a',
          legacyEventId: 'legacy_a',
          source: source,
          sceneId: 'scene_a',
          classification: LegacyMigrationClassification.assisted,
          confirmed: false,
          fingerprintCharacter: '1',
          existingClaim: claim,
        ),
        _projection(
          mapId: 'map_a',
          legacyEventId: 'legacy_b',
          source: source,
          sceneId: 'scene_b',
          classification: LegacyMigrationClassification.assisted,
          confirmed: false,
          fingerprintCharacter: '2',
          existingClaim: claim,
        ),
      ];
      final ids = _InjectedIds.forbidden();

      final replay = _planner(ids).plan(
        _input(
          project: project,
          maps: initialInput.maps,
          mapProjections: claimedProjections,
          choices: NarrativeEventMigrationChoices.empty(),
          currentSnapshot: _snapshot(
            claimedProjections,
            project: project,
            maps: initialInput.maps,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(replay.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(
        replay.mappings.idMappings.map((mapping) => mapping.targetEventIds),
        first.mappings.idMappings.map((mapping) => mapping.targetEventIds),
      );
      expect(ids.calls, 0);

      final legacyReceiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>
        ..['schemaVersion'] = NarrativeEventMigrationReceipt.legacySchemaVersion
        ..remove('sourceChoices');
      final legacyReceipt = NarrativeEventMigrationReceipt.fromJson(
        legacyReceiptJson,
      );
      final legacyReplay = _planner(_InjectedIds.forbidden()).plan(
        _input(
          project: project,
          maps: initialInput.maps,
          mapProjections: claimedProjections,
          choices: NarrativeEventMigrationChoices.empty(),
          currentSnapshot: _snapshot(
            claimedProjections,
            project: project,
            maps: initialInput.maps,
          ),
          existingReceipt: legacyReceipt,
        ),
      );
      expect(legacyReplay.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(legacyReplay.receiptProposal, isNull);

      final missingChoiceReceiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>
        ..['sourceChoices'] = <Object?>[];
      final missingChoiceReplay = _planner(_InjectedIds.forbidden()).plan(
        _input(
          project: project,
          maps: initialInput.maps,
          mapProjections: claimedProjections,
          choices: NarrativeEventMigrationChoices.empty(),
          currentSnapshot: _snapshot(
            claimedProjections,
            project: project,
            maps: initialInput.maps,
          ),
          existingReceipt: NarrativeEventMigrationReceipt.fromJson(
            missingChoiceReceiptJson,
          ),
        ),
      );
      expect(
        missingChoiceReplay.status,
        NarrativeEventMigrationPlanStatus.blocked,
      );
      expect(missingChoiceReplay.receiptProposal, isNull);
    });

    test('blocks incremental cohorts until receipt history is modelled', () {
      final existingProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [existingProjection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
        existingClaim: first.claimsProposed.single,
      );
      final newProjection = _projection(
        mapId: 'map_b',
        legacyEventId: 'legacy_b',
        source: NarrativeEventSourceRef.entityInteract('map_b', 'npc_b'),
        sceneId: 'scene_b',
        fingerprintCharacter: '2',
      );
      final projections = [claimedProjection, newProjection];
      final maps = _mapsForProjections(projections, const []);
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a', 'map_b'],
        sceneIds: const ['scene_a', 'scene_b'],
      );
      final snapshot = _snapshot(
        projections,
        project: project,
        maps: maps,
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      ) as Map<String, dynamic>;
      receiptJson['snapshot'] = snapshot.toJson();
      (receiptJson['writePreconditions'] as Map<String, dynamic>)['snapshot'] =
          snapshot.toJson();
      receiptJson['expectedManifestHashAfter'] = snapshot.manifestHash;
      receiptJson['expectedRegistryHashAfter'] = _jsonHash(registry.toJson());
      final receipt = NarrativeEventMigrationReceipt.fromJson(receiptJson);
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          mapProjections: projections,
          currentSnapshot: snapshot,
          existingReceipt: receipt,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes
              .incrementalReceiptHistoryRequired,
        ),
      );
      expect(plan.recordsProposed, isEmpty);
      expect(ids.calls, 0);
    });

    test('rejects an enabled target as an existing prepared proposal', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final prepared = first.recordsProposed.single;
      final enabledRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        prepared.definitionOrNull!,
        enabled: true,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [enabledRecord],
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final forbiddenIds = _InjectedIds.forbidden();

      final second = _planner(forbiddenIds).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(
        second.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim),
      );
      expect(forbiddenIds.calls, 0);
    });

    test('does not prepare a receipt for an unproven Scenario outcome', () {
      final source = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer_scene',
          outcomeId: 'victory',
        ),
      );
      final projection = _scenarioProjection(
        scenarioId: 'scenario_outcome',
        nodeId: 'source',
        source: source,
        fingerprintCharacter: 'b',
      );
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: source,
        reason: 'Le résultat legacy est qualifié par cette scène.',
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Scenario scenario_outcome',
            conditions: const [],
            sceneId: 'scene_scenario_outcome',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();
      final plan = _planner(ids).plan(
        _input(
          scenarioProjections: [projection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
        ),
      );
      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('keeps deduplicated cohort targets idempotent', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_shared');
      final projections = [
        _projection(
          mapId: 'map_a',
          legacyEventId: 'shared_b',
          source: source,
          sceneId: 'scene_shared',
          fingerprintCharacter: '1',
          title: 'Legacy shared',
        ),
        _projection(
          mapId: 'map_a',
          legacyEventId: 'shared',
          source: source,
          sceneId: 'scene_shared',
          fingerprintCharacter: '2',
          title: 'Legacy shared',
        ),
      ];
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: projections),
      );
      expect(first.recordsProposed, hasLength(1));
      expect(first.claimsProposed.single.members, hasLength(2));
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_shared'],
      );
      final claimedProjections = [
        _projection(
          mapId: 'map_a',
          legacyEventId: 'shared_b',
          source: source,
          sceneId: 'scene_shared',
          fingerprintCharacter: '1',
          title: 'Legacy shared',
          existingClaim: first.claimsProposed.single,
        ),
        _projection(
          mapId: 'map_a',
          legacyEventId: 'shared',
          source: source,
          sceneId: 'scene_shared',
          fingerprintCharacter: '2',
          title: 'Legacy shared',
          existingClaim: first.claimsProposed.single,
        ),
      ];
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: claimedProjections,
          currentSnapshot: _snapshot(
            claimedProjections,
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(second.recordsProposed, isEmpty);
      expect(
        second.receiptProposal!.toJson(),
        first.receiptProposal!.toJson(),
      );
      expect(ids.calls, 0);
    });

    test('rejects an existing claim when its exact receipt is absent', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
        existingClaim: first.claimsProposed.single,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(second.receiptProposal, isNull);
      expect(
        second.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('rejects a receipt when an applied target record was changed', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final original = first.recordsProposed.single.definitionOrNull!;
      final changedRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: original.id,
          name: 'Changed after preparation',
          source: original.source,
          conditions: original.conditions,
          sceneId: original.sceneId,
          reusePolicy: original.reusePolicy,
          priority: original.priority,
          order: original.order,
        ),
        enabled: false,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [changedRecord],
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
        existingClaim: first.claimsProposed.single,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects a receipt whose reference mappings were changed', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>;
      final mappings = receiptJson['mappings']! as Map<String, dynamic>;
      mappings['ids'] = <Object?>[];
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(receiptJson),
        throwsArgumentError,
      );
    });

    test('rejects a receipt whose backup plan differs from the input', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>;
      final backupPlan = receiptJson['backupPlan']! as Map<String, dynamic>;
      final destinations =
          backupPlan['futureDestinations']! as Map<String, dynamic>;
      destinations['manifest'] = 'backups/phase-c/other-project.json';
      final changedReceipt = NarrativeEventMigrationReceipt.fromJson(
        receiptJson,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: changedReceipt,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects a committed receipt as a Phase C prepared proposal', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>;
      receiptJson['isProposal'] = false;
      receiptJson['lifecycle'] = {
        'status': 'committed',
        'preparedAt': '2026-07-11T10:00:00.000Z',
        'committedAt': '2026-07-11T10:01:00.000Z',
      };
      final pointOfNoReturn =
          receiptJson['pointOfNoReturn']! as Map<String, dynamic>;
      pointOfNoReturn['reached'] = true;
      final committedReceipt = NarrativeEventMigrationReceipt.fromJson(
        receiptJson,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: committedReceipt,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects changed lifecycle choices for an existing exact claim', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final reusableTarget =
          _defaultChoices([projection]).sourceChoices.single.targets.single;
      final changedChoice =
          NarrativeEventMigrationSourceChoice.confirmCandidate(
        provenance: projection.provenance,
        source: projection.confirmedSource!,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: reusableTarget.name,
            legacyPageIndex: reusableTarget.legacyPageIndex,
            conditions: reusableTarget.conditions,
            sceneId: reusableTarget.sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: reusableTarget.priority,
            order: reusableTarget.order,
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [changedChoice],
          ),
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(second.receiptProposal, isNull);
      expect(second.items.single.choiceApplied, isFalse);
      expect(ids.calls, 0);
    });

    test('does not recreate an ASSISTED draft once its exact claim exists', () {
      final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
      final initialProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'b',
      );
      final initialChoice =
          NarrativeEventMigrationSourceChoice.confirmCandidate(
        provenance: initialProjection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Assisted event',
            legacyPageIndex: 0,
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
        ],
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(
          mapProjections: [initialProjection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [initialChoice],
          ),
        ),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'b',
        existingClaim: first.claimsProposed.single,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(second.recordsProposed, isEmpty);
      expect(second.draftsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(ids.calls, 0);
    });

    test('blocks an existing partial cohort instead of hiding a sibling', () {
      final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
      final first = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: source,
        sceneId: 'scene_a',
        fingerprintCharacter: '2',
      );
      final sibling = _projection(
        mapId: 'map_b',
        legacyEventId: 'legacy_b',
        source: source,
        sceneId: 'scene_a',
        fingerprintCharacter: '3',
      );
      final record = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: 'evt_018f0000-0000-7000-8000-000000000001',
          name: 'Existing',
          source: source,
          conditions: const [],
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: false,
      );
      final member = LegacySourceClaimMember(
        provenance: first.provenance,
        sourceFingerprint: first.sourceFingerprint,
      );
      final cohortId = computeLegacySourceCohortId(source, [first.provenance]);
      final partialClaim = LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint:
            computeLegacySourceCohortFingerprint(cohortId, [member]),
        targetEventIds: [record.id],
        migrationReceiptId: 'evmr_existing',
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [record],
        legacyClaims: [partialClaim],
      );

      final plan = _planner(_InjectedIds.forbidden()).plan(
        _input(
          project: _project(
            eventRegistry: registry,
            mapIds: const ['map_a', 'map_b'],
            sceneIds: const ['scene_a'],
          ),
          mapProjections: [first, sibling],
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.claimsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.partialClaim),
      );
    });

    test('rejects duplicate target signatures in an existing claim', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '3',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final originalRecord = first.recordsProposed.single;
      final original = originalRecord.definitionOrNull!;
      const duplicateId = 'evt_018f0000-0000-7000-8000-000000000003';
      final duplicateRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: duplicateId,
          name: original.name,
          source: original.source,
          conditions: original.conditions,
          sceneId: original.sceneId,
          reusePolicy: original.reusePolicy,
          priority: original.priority,
          order: original.order,
        ),
        enabled: false,
      );
      final originalClaim = first.claimsProposed.single;
      final duplicateClaim = LegacySourceClaim(
        cohortId: originalClaim.cohortId,
        source: originalClaim.source,
        members: originalClaim.members,
        cohortFingerprint: originalClaim.cohortFingerprint,
        targetEventIds: [originalRecord.id, duplicateId],
        migrationReceiptId: originalClaim.migrationReceiptId,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [originalRecord, duplicateRecord],
        legacyClaims: [duplicateClaim],
      );
      final assistedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: original.source,
        sceneId: original.sceneId,
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '3',
        existingClaim: duplicateClaim,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: _project(
            eventRegistry: registry,
            mapIds: const ['map_a'],
            sceneIds: const ['scene_a'],
          ),
          mapProjections: [assistedProjection],
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.partialClaim),
      );
      expect(ids.calls, 0);
    });

    test('keeps an invalid or tombstone claim fail-closed', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'tombstone',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'c',
        claimStatus: LegacyProjectionClaimStatus.invalid,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(mapProjections: [projection]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(ids.calls, 0);
    });

    test('blocks stale revision and source hashes before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final current = _snapshot([projection], revision: 'revision-current');
      final expected = _snapshot([projection], revision: 'revision-old');
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          currentSnapshot: current,
          expectedSnapshot: expected,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.staleRevision),
      );
      expect(ids.calls, 0);
    });

    test('blocks a stale source fingerprint before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final current = NarrativeEventMigrationSnapshot(
        projectRevisionToken: 'revision-1',
        manifestHash: _jsonHash(
          _project(
            mapIds: const ['map_a'],
            sceneIds: const ['scene_a'],
          ).toJson(),
        ),
        corpusHash: _jsonHash(const {'version': 'C1-v0'}),
        referenceCatalogHash: _jsonHash(
          NarrativeEventReferenceCatalog.empty().toJson(),
        ),
        mapHashes: {
          'map_a': _jsonHash(
            _mapsForProjections([projection], const []).single.toJson(),
          ),
        },
        legacySourceHashes: {
          legacyMigrationSourceSnapshotKey(projection.provenance): _hash('5'),
        },
        saveHashes: const {},
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          currentSnapshot: current,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch),
      );
      expect(ids.calls, 0);
    });

    test('requires every concerned map hash before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final current = NarrativeEventMigrationSnapshot(
        projectRevisionToken: 'revision-1',
        manifestHash: _jsonHash(
          _project(
            mapIds: const ['map_a'],
            sceneIds: const ['scene_a'],
          ).toJson(),
        ),
        corpusHash: _jsonHash(const {'version': 'C1-v0'}),
        referenceCatalogHash: _jsonHash(
          NarrativeEventReferenceCatalog.empty().toJson(),
        ),
        mapHashes: const {},
        legacySourceHashes: {
          legacyMigrationSourceSnapshotKey(projection.provenance):
              projection.sourceFingerprint,
        },
        saveHashes: const {},
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          currentSnapshot: current,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch),
      );
      expect(ids.calls, 0);
    });

    test('blocks a changed read-only map before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final originalMap = _mapsForProjections([projection], const []).single;
      final changedMap = originalMap.copyWith(name: 'Changed map');
      final snapshot = _snapshot(
        [projection],
        maps: [originalMap],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          maps: [changedMap],
          mapProjections: [projection],
          currentSnapshot: snapshot,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch),
      );
      expect(ids.calls, 0);
    });

    test('blocks when a characterized source projection is omitted', () {
      final included = _projection(
        mapId: 'map_a',
        legacyEventId: 'included',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final omitted = _projection(
        mapId: 'map_b',
        legacyEventId: 'omitted',
        source: NarrativeEventSourceRef.entityInteract('map_b', 'npc_b'),
        sceneId: 'scene_b',
        fingerprintCharacter: '5',
      );
      final completeMaps = _mapsForProjections([included, omitted], const []);
      final incompleteSnapshot = _snapshot(
        [included],
        maps: completeMaps,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          maps: completeMaps,
          mapProjections: [included],
          currentSnapshot: incompleteSnapshot,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('blocks when a Scenario source-node projection is omitted', () {
      final included = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: '6',
      );
      final omitted = _scenarioProjection(
        scenarioId: 'scenario_b',
        nodeId: 'source_b',
        source: NarrativeEventSourceRef.mapEnter('map_b'),
        fingerprintCharacter: '7',
      );
      final project = _project(
        mapIds: const ['map_a', 'map_b'],
        scenarios: _scenariosForProjections([included, omitted]),
        scenes: _scenesForProjections([included, omitted]),
      );
      final maps = _mapsForProjections(const [], [included, omitted]);
      final incompleteSnapshot = _snapshot(
        const [],
        scenarioProjections: [included],
        project: project,
        maps: maps,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          scenarioProjections: [included],
          currentSnapshot: incompleteSnapshot,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('blocks when manifest and supplied map inventories diverge', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '8',
      );
      final maps = _mapsForProjections([projection], const []);
      final projectWithoutMap = _project(sceneIds: const ['scene_a']);
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: projectWithoutMap,
          maps: maps,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: projectWithoutMap,
            maps: maps,
          ),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('project.maps'),
      );
      expect(ids.calls, 0);
    });

    test('blocks stale reference and save evidence before consuming IDs', () {
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'missing',
        candidateProvenances: const [],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
          saveSnapshots: const [
            {'saveId': 'save_a', 'consumedEventIds': []},
          ],
          currentSnapshot: _snapshot(const []),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code ==
                  NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
            )
            .map((diagnostic) => diagnostic.path),
        containsAll(['referenceCatalogHash', 'saveHashes']),
      );
      expect(ids.calls, 0);
    });

    test('blocks a reference omitted from the characterized corpus catalog',
        () {
      const corpus = {
        'version': 'C1-v0',
        'references': [
          {
            'kind': 'GameState.consumedEventIds',
            'path': 'gameStates.save_a.consumedEventIds[0]',
            'rawId': 'legacy_a',
            'candidates': <String>[],
          },
        ],
      };
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(characterizedCorpus: corpus),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('characterizedCorpus.references'),
      );
      expect(ids.calls, 0);
    });

    test('blocks a catalog that truncates characterized provenances', () {
      const path = 'gameStates.save_a.consumedEventIds[0]';
      const corpus = {
        'version': 'C1-v0',
        'references': [
          {
            'kind': 'GameState.consumedEventIds',
            'path': path,
            'rawId': 'legacy_a',
            'candidates': ['map_a:legacy_a', 'map_b:legacy_a'],
          },
        ],
      };
      final references = NarrativeEventReferenceCatalog(
        progression: [
          LegacyEventReference(
            kind: LegacyEventReferenceKind.consumedEventState,
            path: path,
            legacyEventId: 'legacy_a',
            candidateProvenances: [
              LegacySourceRef.mapEvent('map_a', 'legacy_a'),
            ],
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          references: references,
          characterizedCorpus: corpus,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('characterizedCorpus.references'),
      );
      expect(ids.calls, 0);
    });

    test('blocks a consumed save entry omitted from the reference catalog', () {
      const saves = [
        {
          'saveId': 'save_a',
          'consumedEventIds': ['legacy_a'],
        },
      ];
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          saveSnapshots: saves,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('gameStates.save_a.consumedEventIds[0]'),
      );
      expect(ids.calls, 0);
    });

    test('rejects unused source and reference choices without consuming IDs',
        () {
      final orphan = LegacySourceRef.mapEvent('map_a', 'orphan');
      final ids = _InjectedIds.forbidden();
      final choices = NarrativeEventMigrationChoices(
        sourceChoices: [
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: orphan,
            source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: 'Orphan',
                conditions: const [],
                sceneId: 'scene_a',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
            ],
          ),
        ],
        referenceChoices: [
          NarrativeEventReferenceResolutionChoice(
            path: 'missing.reference.path',
            decision: NarrativeEventReferenceCollisionDecision.cancel,
          ),
        ],
      );

      final plan = _planner(ids).plan(
        _input(choices: choices),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.unusedChoice),
      );
      expect(ids.calls, 0);
    });

    test('preserves unknown JSON and keeps the plan blocked', () {
      final unknown = NarrativeEventUnknownLegacyData(
        path: 'maps.map_a.events.legacy_a.futureField',
        value: {
          'nested': [1, true, 'kept'],
        },
      );
      final plan = _planner(_InjectedIds.forbidden()).plan(
        _input(unknownLegacyData: [unknown]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.unknownLegacyData.single.toJson(), unknown.toJson());
      final nested = plan.unknownLegacyData.single.value as Map;
      expect(() => nested['lost'] = true, throwsUnsupportedError);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.unknownLegacyData),
      );
    });

    test('requires an explicit consumedEventIds collision resolution', () {
      final first = _projection(
        mapId: 'map_a',
        legacyEventId: 'shared',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '5',
      );
      final second = _projection(
        mapId: 'map_b',
        legacyEventId: 'shared',
        source: NarrativeEventSourceRef.entityInteract('map_b', 'npc_b'),
        sceneId: 'scene_b',
        fingerprintCharacter: '6',
      );
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'shared',
        candidateProvenances: [first.provenance, second.provenance],
      );
      final idsA = _InjectedIds.forbidden();
      final blocked = _planner(idsA).plan(
        _input(
          mapProjections: [first, second],
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
        ),
      );
      expect(blocked.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        blocked.mappings.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.requiresChoice,
      );
      expect(blocked.recordsProposed, isEmpty);
      expect(blocked.receiptProposal, isNull);
      expect(idsA.calls, 0);

      final idsB = _InjectedIds.standardThree();
      final resolved = _planner(idsB).plan(
        _input(
          mapProjections: [first, second],
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
          choices: _choicesWithReferences(
            [first, second],
            referenceChoices: [
              NarrativeEventReferenceResolutionChoice(
                path: reference.path,
                decision:
                    NarrativeEventReferenceCollisionDecision.consumeAllTargets,
              ),
            ],
          ),
        ),
      );
      expect(resolved.status, NarrativeEventMigrationPlanStatus.ready);
      expect(
        resolved.mappings.progressionMappings.single.targetEventIds,
        hasLength(2),
      );
    });

    test('selects future fan-out targets by stable pre-allocation keys', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_confirmed');
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'fan_out',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '8',
      );
      final sourceChoice = NarrativeEventMigrationSourceChoice.confirmCandidate(
        provenance: projection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Target A',
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          NarrativeEventMigrationTargetProposal(
            name: 'Target B',
            conditions: const [],
            sceneId: 'scene_b',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 1,
          ),
        ],
      );
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'fan_out',
        candidateProvenances: [projection.provenance],
      );
      final references = NarrativeEventReferenceCatalog(
        progression: [reference],
      );
      final blockedIds = _InjectedIds.forbidden();

      final blocked = _planner(blockedIds).plan(
        _input(
          mapProjections: [projection],
          references: references,
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [sourceChoice],
          ),
        ),
      );

      final availableKeys =
          blocked.mappings.progressionMappings.single.availableTargetKeys;
      expect(blocked.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(availableKeys, hasLength(2));
      expect(blocked.recordsProposed, isEmpty);
      expect(blockedIds.calls, 0);

      final resolved = _planner(_InjectedIds.standardThree()).plan(
        _input(
          mapProjections: [projection],
          references: references,
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [sourceChoice],
            referenceChoices: [
              NarrativeEventReferenceResolutionChoice(
                path: reference.path,
                decision:
                    NarrativeEventReferenceCollisionDecision.selectedTargets,
                selectedTargetKeys: [availableKeys.first],
              ),
            ],
          ),
        ),
      );

      expect(resolved.status, NarrativeEventMigrationPlanStatus.ready);
      expect(resolved.recordsProposed, hasLength(2));
      expect(
        resolved.mappings.progressionMappings.single.targetEventIds,
        hasLength(1),
      );

      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: resolved.recordsProposed,
        legacyClaims: resolved.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a', 'scene_b'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'fan_out',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '8',
        existingClaim: resolved.claimsProposed.single,
      );
      final replayIds = _InjectedIds.forbidden();
      final replay = _planner(replayIds).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          references: references,
          choices: NarrativeEventMigrationChoices.empty(),
          existingReceipt: resolved.receiptProposal,
        ),
      );

      expect(replay.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(
        canonicalizeNarrativeEventJson(replay.mappings.toJson()),
        canonicalizeNarrativeEventJson(resolved.mappings.toJson()),
      );
      expect(replayIds.calls, 0);
    });

    test('is deterministic for identical inputs, IDs, choices, and clock', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '7',
      );
      final input = _input(mapProjections: [projection]);
      final first = _planner(_InjectedIds.standardTwo()).plan(input);
      final second = _planner(_InjectedIds.standardTwo()).plan(input);

      expect(
        canonicalizeNarrativeEventJson(first.toJson()),
        canonicalizeNarrativeEventJson(second.toJson()),
      );
    });
  });
}

NarrativeEventMigrationPlanner _planner(_InjectedIds ids) {
  return NarrativeEventMigrationPlanner(
    ids: ids,
    clock: () => DateTime.utc(2026, 7, 11, 10),
  );
}

NarrativeEventMigrationPlannerInput _input({
  ProjectManifest? project,
  List<MapData>? maps,
  List<LegacyMapEventProjection> mapProjections = const [],
  List<LegacyScenarioSourceProjection> scenarioProjections = const [],
  NarrativeEventReferenceCatalog? references,
  NarrativeEventMigrationChoices? choices,
  NarrativeEventMigrationSnapshot? currentSnapshot,
  NarrativeEventMigrationSnapshot? expectedSnapshot,
  NarrativeEventMigrationReceipt? existingReceipt,
  List<NarrativeEventUnknownLegacyData> unknownLegacyData = const [],
  Map<String, Object?>? characterizedCorpus,
  List<Map<String, Object?>> saveSnapshots = const [],
  NarrativeEventProjectCatalog? validationCatalog,
  bool includeValidationCatalog = true,
  List<NarrativeEventRecord> validationProposedRecords = const [],
}) {
  final referenceCatalog = references ?? NarrativeEventReferenceCatalog.empty();
  final resolvedCorpus =
      characterizedCorpus ?? _characterizedCorpusFor(referenceCatalog);
  final resolvedChoices = choices ?? _defaultChoices(mapProjections);
  final resolvedMaps = maps ??
      _mapsForProjections(
        mapProjections,
        scenarioProjections,
        choices: resolvedChoices,
      );
  final resolvedProject = project ??
      _project(
        mapIds: [for (final map in resolvedMaps) map.id],
        scenarios: _scenariosForProjections(scenarioProjections),
        scenes: _projectScenesForProjections(
          mapProjections,
          scenarioProjections,
          choices: resolvedChoices,
        ),
        facts: _factsForChoices(resolvedChoices),
      );
  final resolvedValidationCatalog = includeValidationCatalog
      ? validationCatalog ??
          buildNarrativeEventProjectCatalog(
            project: resolvedProject,
            maps: resolvedMaps,
            legacyProjections: mapProjections,
            referencedOutcomes: _referencedOutcomes(
              mapProjections,
              scenarioProjections,
              resolvedChoices,
            ),
            proposedRecords: validationProposedRecords,
          )
      : null;
  return NarrativeEventMigrationPlannerInput(
    project: resolvedProject,
    maps: resolvedMaps,
    mapEventProjections: mapProjections,
    scenarioProjections: scenarioProjections,
    references: referenceCatalog,
    currentSnapshot: currentSnapshot ??
        _snapshot(
          mapProjections,
          scenarioProjections: scenarioProjections,
          characterizedCorpus: resolvedCorpus,
          references: referenceCatalog,
          saveSnapshots: saveSnapshots,
          project: resolvedProject,
          maps: resolvedMaps,
        ),
    expectedSnapshot: expectedSnapshot,
    choices: resolvedChoices,
    characterizedCorpus: resolvedCorpus,
    saveSnapshots: saveSnapshots,
    unknownLegacyData: unknownLegacyData,
    backupPlan: NarrativeEventMigrationBackupPlan(
      futureDestinations: const {
        'manifest': 'backups/phase-c/project.json',
        'receipt': 'backups/phase-c/receipt.json',
      },
    ),
    existingReceiptJsonBytes: existingReceipt == null
        ? null
        : utf8.encode(jsonEncode(existingReceipt.toJson())),
    validationCatalog: resolvedValidationCatalog,
  );
}

Map<String, Object?> _characterizedCorpusFor(
  NarrativeEventReferenceCatalog references,
) {
  return {
    'version': 'C1-v0',
    if (!references.isEmpty)
      'references': [
        for (final reference in references.all)
          {
            'kind': switch (reference.kind) {
              LegacyEventReferenceKind.consumedEventState =>
                'GameState.consumedEventIds',
              LegacyEventReferenceKind.scriptCondition => 'ScriptCondition',
              LegacyEventReferenceKind.worldRuleSource =>
                'WorldRuleDefinition.source',
              LegacyEventReferenceKind.worldRuleTarget =>
                'WorldRuleDefinition.target',
              LegacyEventReferenceKind.sceneConsequence => 'SceneConsequence',
              LegacyEventReferenceKind.scenarioNodeBinding =>
                'ScenarioNodeBinding',
              LegacyEventReferenceKind.scriptCommand => 'ScriptCommand',
              LegacyEventReferenceKind.metadata => 'metadata',
              LegacyEventReferenceKind.validatorDiagnostic =>
                'EventSceneLinkDiagnostic',
            },
            'path': reference.path,
            'rawId': reference.legacyEventId,
            if (reference.mapId != null) 'mapId': reference.mapId,
            'candidates': [
              for (final provenance in reference.candidateProvenances)
                provenance.when(
                  mapEvent: (mapId, eventId) => '$mapId:$eventId',
                  scenarioSourceNode: (scenarioId, nodeId) =>
                      'scenarioSourceNode:$scenarioId:$nodeId',
                ),
            ]..sort(),
          },
      ],
  };
}

NarrativeEventMigrationChoices _defaultChoices(
  List<LegacyMapEventProjection> projections,
) {
  return NarrativeEventMigrationChoices(
    sourceChoices: [
      for (final projection in projections)
        if (projection.classification ==
                LegacyMigrationClassification.autoSafe &&
            projection.confirmedSource != null &&
            projection.pages.length == 1 &&
            projection.pages.single.sceneId != null)
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: projection.provenance,
            source: projection.confirmedSource!,
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: _mapEventFromProjection(projection).title,
                legacyPageIndex: projection.pages.single.pageIndex,
                conditions: const [],
                sceneId: projection.pages.single.sceneId,
                reusePolicy: NarrativeEventReusePolicy.reusable,
                priority: 0,
                order: projection.pages.single.pageIndex,
              ),
            ],
          ),
    ],
  );
}

NarrativeEventMigrationChoices _choicesWithReferences(
  List<LegacyMapEventProjection> projections, {
  required List<NarrativeEventReferenceResolutionChoice> referenceChoices,
}) {
  final sourceChoices = _defaultChoices(projections).sourceChoices;
  return NarrativeEventMigrationChoices(
    sourceChoices: sourceChoices,
    referenceChoices: referenceChoices,
  );
}

ProjectManifest _project({
  NarrativeEventRegistry? eventRegistry,
  List<String> mapIds = const [],
  List<String> sceneIds = const [],
  List<ScenarioAsset> scenarios = const [],
  List<SceneAsset> scenes = const [],
  List<NarrativeFactDefinition> facts = const [],
}) {
  final scenesById = <String, SceneAsset>{
    for (final sceneId in sceneIds) sceneId: _sceneForMapTarget(sceneId),
    for (final scene in scenes) scene.id: scene,
  };
  final sortedSceneIds = scenesById.keys.toList()..sort();
  final dialogueIds = <String>{};
  for (final scene in scenesById.values) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneYarnDialoguePayload) {
        dialogueIds.add(payload.dialogueId);
      }
    }
  }
  final sortedDialogueIds = dialogueIds.toList()..sort();
  return ProjectManifest(
    name: 'Phase C4',
    maps: [
      for (final mapId in mapIds)
        ProjectMapEntry(
          id: mapId,
          name: 'Map $mapId',
          relativePath: 'maps/$mapId.json',
        ),
    ],
    tilesets: const [],
    scenarios: scenarios,
    scenes: [for (final sceneId in sortedSceneIds) scenesById[sceneId]!],
    dialogues: [
      for (final dialogueId in sortedDialogueIds)
        ProjectDialogueEntry(
          id: dialogueId,
          name: 'Dialogue $dialogueId',
          relativePath: 'dialogues/$dialogueId.yarn',
        ),
    ],
    facts: facts,
    eventRegistry: eventRegistry,
  );
}

NarrativeEventMigrationSnapshot _snapshot(
  List<LegacyMapEventProjection> projections, {
  List<LegacyScenarioSourceProjection> scenarioProjections = const [],
  String revision = 'revision-1',
  ProjectManifest? project,
  List<MapData>? maps,
  Map<String, Object?> characterizedCorpus = const {'version': 'C1-v0'},
  NarrativeEventReferenceCatalog? references,
  List<Map<String, Object?>> saveSnapshots = const [],
}) {
  final referenceCatalog = references ?? NarrativeEventReferenceCatalog.empty();
  final resolvedMaps = maps ??
      _mapsForProjections(
        projections,
        scenarioProjections,
      );
  return NarrativeEventMigrationSnapshot(
    projectRevisionToken: revision,
    manifestHash: _jsonHash(
      (project ??
              _project(
                mapIds: [for (final map in resolvedMaps) map.id],
                scenarios: _scenariosForProjections(scenarioProjections),
                scenes: _projectScenesForProjections(
                  projections,
                  scenarioProjections,
                ),
              ))
          .toJson(),
    ),
    corpusHash: _jsonHash(characterizedCorpus),
    referenceCatalogHash: _jsonHash(referenceCatalog.toJson()),
    mapHashes: {
      for (final map in resolvedMaps) map.id: _jsonHash(map.toJson()),
    },
    legacySourceHashes: {
      for (final projection in projections)
        legacyMigrationSourceSnapshotKey(projection.provenance):
            projection.sourceFingerprint,
      for (final projection in scenarioProjections)
        legacyMigrationSourceSnapshotKey(projection.provenance):
            projection.sourceFingerprint,
    },
    saveHashes: _saveHashes(saveSnapshots),
  );
}

List<MapData> _mapsForProjections(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections, {
  NarrativeEventMigrationChoices? choices,
}) {
  final ids = _concernedMapIds(mapProjections, scenarioProjections).toList()
    ..sort();
  return [
    for (final id in ids)
      _mapData(
        id,
        events: [
          for (final projection in mapProjections)
            if (_mapIdOf(projection.provenance) == id)
              _mapEventFromProjection(projection),
        ],
        entities: _entitiesForSources(
          id,
          mapProjections,
          scenarioProjections,
          choices: choices,
        ),
        triggers: _triggersForSources(
          id,
          mapProjections,
          scenarioProjections,
          choices: choices,
        ),
      ),
  ];
}

List<MapEntity> _entitiesForSources(
  String mapId,
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections, {
  NarrativeEventMigrationChoices? choices,
}) {
  final ids = <String>{};
  final positions = <String, GridPos>{};
  for (final projection in mapProjections) {
    final event = _mapEventFromProjection(projection);
    for (final candidate in projection.sourceCandidates) {
      candidate.source.when<void>(
        entityInteract: (sourceMapId, entityId) {
          if (sourceMapId != mapId) return;
          ids.add(entityId);
          positions.putIfAbsent(
            entityId,
            () => GridPos(x: event.position.x, y: event.position.y),
          );
        },
        triggerEnter: (_, __) {},
        mapEnter: (_) {},
        outcomeReceived: (_) {},
      );
    }
  }
  for (final source in _projectionSources(
    mapProjections,
    scenarioProjections,
    choices: choices,
  )) {
    source.when<void>(
      entityInteract: (sourceMapId, entityId) {
        if (sourceMapId == mapId) ids.add(entityId);
      },
      triggerEnter: (_, __) {},
      mapEnter: (_) {},
      outcomeReceived: (_) {},
    );
  }
  final sorted = ids.toList()..sort();
  return [
    for (var index = 0; index < sorted.length; index++)
      MapEntity(
        id: sorted[index],
        name: 'Entity ${sorted[index]}',
        kind: MapEntityKind.npc,
        pos: positions[sorted[index]] ?? GridPos(x: index % 7, y: index ~/ 7),
      ),
  ];
}

List<MapTrigger> _triggersForSources(
  String mapId,
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections, {
  NarrativeEventMigrationChoices? choices,
}) {
  final ids = <String>{};
  final positions = <String, GridPos>{};
  for (final projection in mapProjections) {
    final event = _mapEventFromProjection(projection);
    for (final candidate in projection.sourceCandidates) {
      candidate.source.when<void>(
        entityInteract: (_, __) {},
        triggerEnter: (sourceMapId, triggerId) {
          if (sourceMapId != mapId) return;
          ids.add(triggerId);
          positions.putIfAbsent(
            triggerId,
            () => GridPos(x: event.position.x, y: event.position.y),
          );
        },
        mapEnter: (_) {},
        outcomeReceived: (_) {},
      );
    }
  }
  for (final source in _projectionSources(
    mapProjections,
    scenarioProjections,
    choices: choices,
  )) {
    source.when<void>(
      entityInteract: (_, __) {},
      triggerEnter: (sourceMapId, triggerId) {
        if (sourceMapId == mapId) ids.add(triggerId);
      },
      mapEnter: (_) {},
      outcomeReceived: (_) {},
    );
  }
  final sorted = ids.toList()..sort();
  return [
    for (var index = 0; index < sorted.length; index++)
      MapTrigger(
        id: sorted[index],
        name: 'Trigger ${sorted[index]}',
        type: TriggerType.event,
        area: MapRect(
          pos: positions[sorted[index]] ?? GridPos(x: index % 7, y: index ~/ 7),
          size: const GridSize(width: 1, height: 1),
        ),
      ),
  ];
}

Iterable<NarrativeEventSourceRef> _projectionSources(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections, {
  NarrativeEventMigrationChoices? choices,
}) sync* {
  for (final projection in mapProjections) {
    for (final candidate in projection.sourceCandidates) {
      yield candidate.source;
    }
  }
  for (final projection in scenarioProjections) {
    final source = projection.source;
    if (source != null) yield source;
  }
  if (choices != null) {
    for (final choice in choices.sourceChoices) {
      yield choice.source;
    }
  }
}

List<NarrativeOutcomeRef> _referencedOutcomes(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections,
  NarrativeEventMigrationChoices choices,
) {
  final byKey = <String, NarrativeOutcomeRef>{};
  for (final source in _projectionSources(
    mapProjections,
    scenarioProjections,
    choices: choices,
  )) {
    source.when<void>(
      entityInteract: (_, __) {},
      triggerEnter: (_, __) {},
      mapEnter: (_) {},
      outcomeReceived: (outcome) {
        byKey[canonicalizeNarrativeEventJson(outcome.toJson())] = outcome;
      },
    );
  }
  final keys = byKey.keys.toList()..sort();
  return [for (final key in keys) byKey[key]!];
}

List<NarrativeFactDefinition> _factsForChoices(
  NarrativeEventMigrationChoices choices,
) {
  final ids = <String>{};
  for (final choice in choices.sourceChoices) {
    for (final target in choice.targets) {
      for (final condition in target.conditions) {
        condition.when<void>(
          fact: (factId, _) => ids.add(factId),
          narrativeEventConsumed: (_, __) {},
        );
      }
    }
  }
  final sorted = ids.toList()..sort();
  return [
    for (final id in sorted) NarrativeFactDefinition(id: id, label: 'Fact $id'),
  ];
}

MapData _mapData(
  String id, {
  String? name,
  List<MapEventDefinition> events = const [],
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: id,
    name: name ?? 'Map $id',
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    events: events,
    entities: entities,
    triggers: triggers,
  );
}

MapEventDefinition _mapEventFromProjection(
  LegacyMapEventProjection projection,
) {
  return MapEventDefinition.fromJson(
    Map<String, dynamic>.from(projection.preservedEventJson),
  );
}

List<ScenarioAsset> _scenariosForProjections(
  List<LegacyScenarioSourceProjection> projections,
) {
  final scenarioIds = {
    for (final projection in projections) projection.scenarioId
  }.toList()
    ..sort();
  return [
    for (final scenarioId in scenarioIds)
      ScenarioAsset.fromJson(
        Map<String, dynamic>.from(
          projections
              .firstWhere(
                (projection) => projection.scenarioId == scenarioId,
              )
              .preservedScenarioJson,
        ),
      ),
  ];
}

List<SceneAsset> _scenesForProjections(
  List<LegacyScenarioSourceProjection> projections,
) {
  final scenarioIds = {
    for (final projection in projections) projection.scenarioId,
  }.toList()
    ..sort();
  return [
    for (final scenarioId in scenarioIds) _sceneForScenario(scenarioId),
  ];
}

List<SceneAsset> _projectScenesForProjections(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections, {
  NarrativeEventMigrationChoices? choices,
}) {
  final scenesById = <String, SceneAsset>{};
  for (final projection in mapProjections) {
    for (final page in projection.pages) {
      final sceneId = page.sceneId;
      if (sceneId != null) {
        scenesById.putIfAbsent(sceneId, () => _sceneForMapTarget(sceneId));
      }
    }
  }
  for (final choice in choices?.sourceChoices ?? const []) {
    for (final target in choice.targets) {
      final sceneId = target.sceneId;
      if (sceneId != null) {
        scenesById.putIfAbsent(sceneId, () => _sceneForMapTarget(sceneId));
      }
    }
  }
  for (final scene in _scenesForProjections(scenarioProjections)) {
    scenesById[scene.id] = scene;
  }
  final ids = scenesById.keys.toList()..sort();
  return [for (final id in ids) scenesById[id]!];
}

ScenarioNode _scenarioNodeForSource(
  String nodeId,
  NarrativeEventSourceRef? source, {
  String? sceneId,
}) {
  final actionKind = source?.when(
        entityInteract: (_, __) => 'sourceEntityInteract',
        triggerEnter: (_, __) => 'sourceTriggerEnter',
        mapEnter: (_) => 'sourceMapEnter',
        outcomeReceived: (_) => 'sourceOutcome',
      ) ??
      'sourceOutcome';
  final binding = source?.when(
        entityInteract: (mapId, entityId) => ScenarioNodeBinding(
          mapId: mapId,
          entityId: entityId,
        ),
        triggerEnter: (mapId, triggerId) => ScenarioNodeBinding(
          mapId: mapId,
          triggerId: triggerId,
        ),
        mapEnter: (mapId) => ScenarioNodeBinding(mapId: mapId),
        outcomeReceived: (outcome) => ScenarioNodeBinding(
          outcomeId: outcome.outcomeId,
        ),
      ) ??
      const ScenarioNodeBinding(outcomeId: 'unqualified');
  return ScenarioNode(
    id: nodeId,
    type: ScenarioNodeType.reference,
    binding: binding,
    payload: ScenarioNodePayload(actionKind: actionKind),
    metadata: {
      if (sceneId != null) 'eventV2.sceneId': sceneId,
    },
  );
}

String? _mapIdOf(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, _) => mapId,
    scenarioSourceNode: (_, __) => null,
  );
}

Set<String> _concernedMapIds(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections,
) {
  final result = <String>{};
  for (final projection in mapProjections) {
    projection.provenance.when(
      mapEvent: (mapId, _) => result.add(mapId),
      scenarioSourceNode: (_, __) {},
    );
    _addSourceMap(result, projection.confirmedSource);
  }
  for (final projection in scenarioProjections) {
    _addSourceMap(result, projection.source);
  }
  return result;
}

void _addSourceMap(Set<String> result, NarrativeEventSourceRef? source) {
  source?.when(
    entityInteract: (mapId, _) => result.add(mapId),
    triggerEnter: (mapId, _) => result.add(mapId),
    mapEnter: result.add,
    outcomeReceived: (_) {},
  );
}

LegacyMapEventProjection _projection({
  required String mapId,
  required String legacyEventId,
  required NarrativeEventSourceRef source,
  required String sceneId,
  required String fingerprintCharacter,
  String? title,
  LegacyMigrationClassification classification =
      LegacyMigrationClassification.autoSafe,
  bool confirmed = true,
  LegacySourceClaim? existingClaim,
  LegacyProjectionClaimStatus? claimStatus,
  List<LegacyMapEventPageProjection>? pages,
}) {
  final resolvedPages = pages ??
      [
        LegacyMapEventPageProjection(
          pageIndex: 0,
          pageNumber: 1,
          condition: null,
          script: null,
          spriteId: null,
          message: null,
          sceneId: sceneId,
          isHidden: false,
          isDisabled: false,
          metadata: const {},
        ),
      ];
  final sourcePosition = _sourceFixturePosition(source);
  final sourceMetadata = source.when(
    entityInteract: (_, entityId) => confirmed
        ? {LegacyMapEventCompatibilityMetadataKeys.entityId: entityId}
        : const <String, String>{},
    triggerEnter: (_, triggerId) => confirmed
        ? {LegacyMapEventCompatibilityMetadataKeys.triggerId: triggerId}
        : const <String, String>{},
    mapEnter: (_) => const <String, String>{},
    outcomeReceived: (_) => const <String, String>{},
  );
  final event = MapEventDefinition(
    id: legacyEventId,
    title: title ?? 'Legacy $legacyEventId',
    pages: [
      for (final page in resolvedPages)
        MapEventPage(
          pageNumber: page.pageNumber,
          condition: page.condition,
          script: page.script,
          spriteId: page.spriteId,
          message: page.message,
          sceneTarget: page.sceneId == null
              ? null
              : MapEventSceneTarget(sceneId: page.sceneId!),
          isHidden: page.isHidden,
          isDisabled: page.isDisabled,
          metadata: page.metadata,
        ),
    ],
    position: EventPosition(
      layerId: 'events',
      x: sourcePosition.x,
      y: sourcePosition.y,
    ),
    type: source.when(
      entityInteract: (_, __) => MapEventType.object,
      triggerEnter: (_, __) => MapEventType.triggerZone,
      mapEnter: (_) => MapEventType.object,
      outcomeReceived: (_) => MapEventType.object,
    ),
    metadata: {
      'testFingerprint': fingerprintCharacter,
      ...sourceMetadata,
    },
  );
  final fixtureEntities = <MapEntity>[];
  final fixtureTriggers = <MapTrigger>[];
  source.when<void>(
    entityInteract: (sourceMapId, entityId) {
      if (sourceMapId == mapId) {
        fixtureEntities.add(
          MapEntity(
            id: entityId,
            name: 'Entity $entityId',
            kind: MapEntityKind.npc,
            pos: sourcePosition,
          ),
        );
      }
    },
    triggerEnter: (sourceMapId, triggerId) {
      if (sourceMapId == mapId) {
        fixtureTriggers.add(
          MapTrigger(
            id: triggerId,
            name: 'Trigger $triggerId',
            type: TriggerType.event,
            area: MapRect(
              pos: sourcePosition,
              size: const GridSize(width: 1, height: 1),
            ),
          ),
        );
      }
    },
    mapEnter: (_) {},
    outcomeReceived: (_) {},
  );
  final canonical = projectLegacyMapEventReadOnly(
    mapId: mapId,
    map: _mapData(
      mapId,
      events: [event],
      entities: fixtureEntities,
      triggers: fixtureTriggers,
    ),
    event: event,
    claimIndex: buildValidatedLegacyClaimIndex(
      NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
    ),
  );
  return LegacyMapEventProjection(
    provenance: canonical.provenance,
    classification: classification,
    claimStatus: claimStatus ??
        (existingClaim == null
            ? LegacyProjectionClaimStatus.absent
            : LegacyProjectionClaimStatus.valid),
    existingClaim: existingClaim,
    sourceFingerprint: canonical.sourceFingerprint,
    sourceCandidates: canonical.sourceCandidates,
    pages: canonical.pages,
    preservedEventJson: canonical.preservedEventJson,
    unconvertibleDataPaths: canonical.unconvertibleDataPaths,
    linkedReferences: canonical.linkedReferences,
    diagnostics: canonical.diagnostics,
    manualActions: canonical.manualActions,
  );
}

GridPos _sourceFixturePosition(NarrativeEventSourceRef source) {
  final token = source.when(
    entityInteract: (_, entityId) => entityId,
    triggerEnter: (_, triggerId) => triggerId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (outcome) =>
        '${outcome.producerKind.name}:${outcome.producerId}:${outcome.outcomeId}',
  );
  final slot = token.codeUnits.fold<int>(0, (sum, value) => sum + value) % 49;
  return GridPos(x: slot % 7, y: slot ~/ 7);
}

LegacyScenarioSourceProjection _scenarioProjection({
  required String scenarioId,
  required String nodeId,
  required NarrativeEventSourceRef source,
  required String fingerprintCharacter,
}) {
  final scene = _sceneForScenario(scenarioId);
  final scenario = ScenarioAsset(
    id: scenarioId,
    name: 'Scenario $scenarioId',
    entryNodeId: nodeId,
    nodes: [
      _scenarioNodeForSource(nodeId, source, sceneId: scene.id),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'dialogue_$scenarioId',
        ),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(
        id: 'edge_source',
        fromNodeId: nodeId,
        toNodeId: 'dialogue',
      ),
      const ScenarioEdge(
        id: 'edge_end',
        fromNodeId: 'dialogue',
        toNodeId: 'end',
      ),
    ],
    metadata: {'testFingerprint': fingerprintCharacter},
  );
  return projectLegacyScenarioSourceReadOnly(
    scenario: scenario,
    node: scenario.nodes.first,
    scenes: [scene],
    claimIndex: buildValidatedLegacyClaimIndex(
      NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
    ),
    lifecycleEvidence: LegacyScenarioLifecycleEvidence.oneShot,
  );
}

SceneAsset _sceneForScenario(
  String scenarioId, {
  String? dialogueId,
}) {
  return SceneAsset.fromJson({
    'id': 'scene_$scenarioId',
    'name': 'Scene $scenarioId',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {
          'id': 'dialogue',
          'kind': 'yarnDialogue',
          'payload': {
            'kind': 'yarnDialogue',
            'dialogueId': dialogueId ?? 'dialogue_$scenarioId',
          },
        },
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge_start',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'dialogue',
          'kind': 'default',
        },
        {
          'id': 'edge_end',
          'fromNodeId': 'dialogue',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

SceneAsset _sceneForMapTarget(String sceneId) {
  return SceneAsset.fromJson({
    'id': sceneId,
    'name': 'Scene $sceneId',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge_end',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

SceneAsset _outcomeProducerScene(String sceneId, String outcomeId) {
  return SceneAsset(
    id: sceneId,
    name: 'Scene $sceneId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: [SceneOutcome(id: outcomeId, label: outcomeId)],
  );
}

SceneAsset _unbuildableScene(String sceneId) {
  return SceneAsset.fromJson({
    'id': sceneId,
    'name': 'Broken $sceneId',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
      ],
      'edges': <Object?>[],
    },
  });
}

String _hash(String character) => 'sha256:${character * 64}';

String _jsonHash(Object? value) => 'sha256:${narrativeEventCanonicalSha256(
      jsonDecode(jsonEncode(value)),
    )}';

Map<String, String> _saveHashes(List<Map<String, Object?>> snapshots) {
  return {
    for (final snapshot in snapshots)
      snapshot['saveId']! as String: _jsonHash(snapshot),
  };
}

final class _InjectedIds implements NarrativeEventMigrationIdSource {
  _InjectedIds({
    required List<String> eventIds,
    required List<String> receiptIds,
  })  : _eventIds = List.of(eventIds),
        _receiptIds = List.of(receiptIds);

  _InjectedIds.forbidden()
      : _eventIds = const [],
        _receiptIds = const [],
        _forbidden = true;

  factory _InjectedIds.standardTwo() => _InjectedIds(
        eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
      );

  factory _InjectedIds.standardThree() => _InjectedIds(
        eventIds: const [
          'evt_018f0000-0000-7000-8000-000000000001',
          'evt_018f0000-0000-7000-8000-000000000002',
        ],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000003'],
      );

  final List<String> _eventIds;
  final List<String> _receiptIds;
  bool _forbidden = false;
  int calls = 0;

  @override
  String nextEventId() {
    calls++;
    if (_forbidden || _eventIds.isEmpty) {
      throw StateError('event ID generation was not expected');
    }
    return _eventIds.removeAt(0);
  }

  @override
  String nextReceiptId() {
    calls++;
    if (_forbidden || _receiptIds.isEmpty) {
      throw StateError('receipt ID generation was not expected');
    }
    return _receiptIds.removeAt(0);
  }
}
