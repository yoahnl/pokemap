import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase D D0-B migration contextual integrity', () {
    test('1. blocks a missing source without consuming IDs or clock', () {
      final projection = _projection(
        legacyEventId: 'legacy_missing',
        candidate: _entitySource('missing_npc'),
      );
      final result = _run(
        projections: [projection],
        map: _map(projections: [projection]),
        project: _project(),
        choices: [_confirmation(projection)],
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationSourceMissing'));
    });

    test('2. blocks an existing source reserved for the map system', () {
      final source = _entitySource('spawn_player');
      final projection = _projection(
        legacyEventId: 'legacy_spawn',
        candidate: source,
      );
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [_entity('spawn_player', MapEntityKind.spawn)],
        ),
        project: _project(),
        choices: [_confirmation(projection)],
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationSourceUnavailable'));
    });

    test('blocks an ambiguous source as a diagnostic instead of throwing', () {
      final projection = _baseProjection('legacy_ambiguous_source');
      final duplicate = _entity('npc_a', MapEntityKind.npc);
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [duplicate, duplicate],
        ),
        project: _project(),
        choices: [_confirmation(projection)],
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationSourceAmbiguous'));
      final impact = NarrativeEventMigrationPlanner.previewImpact(
        input: result.input,
        plan: result.plan,
      );
      expect(impact.collisionCount, 1);
      expect(impact.retirement.migrationBlockerCount, greaterThan(0));
    });

    test('3. rejects confirmCandidate outside projection candidates', () {
      final projection = _projection(
        legacyEventId: 'legacy_candidate',
        candidate: _entitySource('npc_a'),
      );
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [
            _entity('npc_a', MapEntityKind.npc),
            _entity('npc_b', MapEntityKind.npc),
          ],
        ),
        project: _project(),
        choices: [
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: projection.provenance,
            source: _entitySource('npc_b'),
            targets: [_target()],
          ),
        ],
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('choiceContradictsProjection'));
      expect(result.plan.items.single.choiceApplied, isFalse);
    });

    test('4. accepts and preserves an explicit real reassignment', () {
      final projection = _projection(
        legacyEventId: 'legacy_reassigned',
        candidate: _entitySource('npc_hint'),
      );
      const reason = 'Le PNJ confirmé remplace le repère legacy ambigu.';
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: _entitySource('npc_confirmed'),
        targets: [_target()],
        reason: reason,
      );
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [
            _entity('npc_hint', MapEntityKind.npc),
            _entity('npc_confirmed', MapEntityKind.npc),
          ],
        ),
        project: _project(),
        choices: [choice],
      );

      expect(result.plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(result.plan.canApply, isTrue);
      expect(result.plan.items.single.choiceApplied, isTrue);
      expect(result.plan.items.single.reassignmentReason, reason);
      expect(
        result.plan.receiptProposal!.sourceChoices.single.reassignmentReason,
        reason,
      );
      expect(
        _codes(result.plan),
        contains('explicitReassignmentValidated'),
      );
    });

    test('5. blocks an explicit reassignment to a missing source', () {
      final projection = _projection(
        legacyEventId: 'legacy_bad_reassignment',
        candidate: _entitySource('npc_hint'),
      );
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [_entity('npc_hint', MapEntityKind.npc)],
        ),
        project: _project(),
        choices: [
          NarrativeEventMigrationSourceChoice.explicitReassignment(
            provenance: projection.provenance,
            source: _entitySource('missing_npc'),
            targets: [_target()],
            reason: 'La cible a été choisie manuellement.',
          ),
        ],
      );

      _expectPreflightBlock(result);
      expect(result.plan.items.single.choiceApplied, isFalse);
    });

    test('6. blocks a missing Fact', () {
      final projection = _baseProjection('legacy_fact_missing');
      final result = _runBase(
        projection,
        target: _target(
          conditions: [NarrativeEventCondition.fact('fact_missing', true)],
        ),
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationFactMissing'));
    });

    test('7. blocks a duplicated Fact identity', () {
      final projection = _baseProjection('legacy_fact_duplicate');
      final fact = NarrativeFactDefinition(id: 'fact_a', label: 'Fact A');
      final result = _runBase(
        projection,
        target: _target(
          conditions: [NarrativeEventCondition.fact('fact_a', true)],
        ),
        project: _project(facts: [fact, fact]),
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationFactAmbiguous'));
    });

    test('8. blocks a dangling narrativeEventConsumed reference', () {
      final projection = _baseProjection('legacy_event_missing');
      final result = _runBase(
        projection,
        target: _target(
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(
              'evt_018f0000-0000-7000-8000-000000000099',
              true,
            ),
          ],
        ),
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationEventMissing'));
    });

    test('9. accepts a valid preallocated Event in the atomic plan closure',
        () {
      const reservedId = 'evt_018f0000-0000-7000-8000-000000000099';
      final first = _projection(
        legacyEventId: 'legacy_a',
        candidate: _entitySource('npc_a'),
      );
      final second = _projection(
        legacyEventId: 'legacy_b',
        candidate: _entitySource('npc_b'),
      );
      final firstTarget = _target(
        name: 'Event A',
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(reservedId, true),
        ],
      );
      final secondTarget = _target(name: 'Event B', order: 1);
      final reserved = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: reservedId,
          name: secondTarget.name,
          source: _entitySource('npc_b'),
          conditions: secondTarget.conditions,
          sceneId: secondTarget.sceneId!,
          reusePolicy: secondTarget.reusePolicy!,
          priority: secondTarget.priority,
          order: secondTarget.order,
        ),
        enabled: false,
      );
      final result = _run(
        projections: [first, second],
        map: _map(
          projections: [first, second],
          entities: [
            _entity('npc_a', MapEntityKind.npc),
            _entity('npc_b', MapEntityKind.npc),
          ],
        ),
        project: _project(),
        choices: [
          _confirmation(first, target: firstTarget),
          _confirmation(second, target: secondTarget),
        ],
        proposedRecords: [reserved],
      );

      expect(result.plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(result.plan.recordsProposed, hasLength(2));
      expect(
        result.plan.recordsProposed.map((record) => record.id),
        contains(reservedId),
      );
      expect(
        result.plan.receiptProposal!.targetRecords.map((record) => record.id),
        contains(reservedId),
      );
      expect(result.plan.receiptProposal!.targetClaims, hasLength(2));
      expect(
        _decodeState(
          decodeNarrativeEventMigrationReceiptStrict(
            utf8.encode(jsonEncode(result.plan.receiptProposal!.toJson())),
          ),
        ),
        'decoded',
      );
    });

    test('10. blocks a missing or duplicated Scene', () {
      final projection = _baseProjection('legacy_scene');
      for (final scenes in [
        const <SceneAsset>[],
        [_actionScene(), _actionScene()],
      ]) {
        final result = _runBase(
          projection,
          project: _project(scenes: scenes),
        );
        _expectPreflightBlock(result);
      }
    });

    test('11. blocks an outcome whose producer is missing', () {
      final projection = _baseProjection('legacy_missing_producer');
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_missing',
        outcomeId: 'victory',
      );
      final result = _runBase(
        projection,
        choice: NarrativeEventMigrationSourceChoice.explicitReassignment(
          provenance: projection.provenance,
          source: NarrativeEventSourceRef.outcomeReceived(outcome),
          targets: [_target()],
          reason: 'Le résultat a été qualifié manuellement.',
        ),
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationSourceUnavailable'));
    });

    test('12. resolves the same outcome ID by its exact producer', () {
      final sourceB = NarrativeEventSourceRef.outcomeReceived(
        _sceneOutcomeRef('producer_b', 'shared'),
      );
      final projection = _projection(
        legacyEventId: 'legacy_outcome',
        candidate: _entitySource('npc_hint'),
      );
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: projection.provenance,
        source: sourceB,
        targets: [_target()],
        reason: 'Le producteur exact est la Scene B.',
      );
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [_entity('npc_hint', MapEntityKind.npc)],
        ),
        project: _project(
          scenes: [
            _actionScene(),
            _outcomeScene('producer_a', 'shared'),
            _outcomeScene('producer_b', 'shared'),
          ],
        ),
        choices: [choice],
      );

      expect(result.plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(
        result.plan.recordsProposed.single.definitionOrNull!.source,
        sourceB,
      );
    });

    test('12b. blocks an outcome from a Scene with a missing map event', () {
      final projection = _projection(
        legacyEventId: 'legacy_invalid_outcome_producer',
        candidate: _entitySource('npc_hint'),
      );
      final outcomeSource = NarrativeEventSourceRef.outcomeReceived(
        _sceneOutcomeRef('producer_invalid_map_event', 'victory'),
      );
      final result = _run(
        projections: [projection],
        map: _map(
          projections: [projection],
          entities: [_entity('npc_hint', MapEntityKind.npc)],
        ),
        project: _project(
          scenes: [
            _actionScene(),
            _outcomeSceneWithConsequence(
              'producer_invalid_map_event',
              'victory',
              SceneConsequence.markEventConsumed(
                mapId: 'map_a',
                eventId: 'event_absent',
              ),
            ),
          ],
        ),
        choices: [
          NarrativeEventMigrationSourceChoice.explicitReassignment(
            provenance: projection.provenance,
            source: outcomeSource,
            targets: [_target()],
            reason: 'Le producteur exact a été choisi manuellement.',
          ),
        ],
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationSourceUnavailable'));
    });

    test('13. fails closed when the project catalog is absent', () {
      final projection = _baseProjection('legacy_no_catalog');
      final result = _runBase(projection, includeCatalog: false);

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('validationCatalogMissing'));
    });

    test('enforces strong ready and canApply invariants in the public type',
        () {
      final projection = _baseProjection('legacy_strong_ready');
      final project = _project();
      final valid = _runBase(projection, project: project).plan;
      expect(valid.canApply, isTrue);

      expect(
        () => NarrativeEventMigrationPlan(
          status: NarrativeEventMigrationPlanStatus.ready,
          recordsProposed: valid.recordsProposed,
          claimsProposed: valid.claimsProposed,
          cohorts: valid.cohorts,
          items: valid.items,
          mappings: valid.mappings,
          diagnostics: valid.diagnostics,
          writePreconditions: valid.writePreconditions,
          backupPlan: valid.backupPlan,
          receiptProposal: valid.receiptProposal,
          rollbackPlan: valid.rollbackPlan,
          pointOfNoReturn: valid.pointOfNoReturn,
          unknownLegacyData: valid.unknownLegacyData,
        ),
        throwsArgumentError,
      );

      expect(
        () => NarrativeEventMigrationPlan(
          status: NarrativeEventMigrationPlanStatus.ready,
          recordsProposed: valid.recordsProposed,
          claimsProposed: valid.claimsProposed,
          cohorts: valid.cohorts,
          items: valid.items,
          mappings: valid.mappings,
          diagnostics: [
            ...valid.diagnostics,
            LegacyMigrationDiagnostic(
              code: 'forcedError',
              severity: LegacyMigrationDiagnosticSeverity.error,
              message: 'A ready plan cannot retain an error.',
              path: 'test',
            ),
          ],
          writePreconditions: valid.writePreconditions,
          backupPlan: valid.backupPlan,
          receiptProposal: valid.receiptProposal,
          rollbackPlan: valid.rollbackPlan,
          pointOfNoReturn: valid.pointOfNoReturn,
          unknownLegacyData: valid.unknownLegacyData,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventMigrationPlan(
          status: NarrativeEventMigrationPlanStatus.ready,
          recordsProposed: valid.recordsProposed,
          claimsProposed: valid.claimsProposed,
          cohorts: const [],
          items: valid.items,
          mappings: valid.mappings,
          diagnostics: valid.diagnostics,
          writePreconditions: valid.writePreconditions,
          backupPlan: valid.backupPlan,
          receiptProposal: valid.receiptProposal,
          rollbackPlan: valid.rollbackPlan,
          pointOfNoReturn: valid.pointOfNoReturn,
          unknownLegacyData: valid.unknownLegacyData,
        ),
        throwsArgumentError,
      );
    });

    test('blocks a projection error before consuming IDs or clock', () {
      final projection = _projection(
        legacyEventId: 'legacy_projection_error',
        candidate: _entitySource('npc_a'),
        diagnostics: [
          LegacyMigrationDiagnostic(
            code: 'legacyProjectionError',
            severity: LegacyMigrationDiagnosticSeverity.error,
            message: 'The legacy projection is not trustworthy.',
            path: 'maps.map_a.events.legacy_projection_error',
          ),
        ],
      );
      final result = _runBase(projection);

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('legacyProjectionError'));
    });

    test('blocks forged MapEvent projection evidence before allocation', () {
      final canonical = _baseProjection('legacy_forged_projection');
      final forgedSource = _entitySource('npc_forged');
      final forged = LegacyMapEventProjection(
        provenance: canonical.provenance,
        classification: canonical.classification,
        claimStatus: canonical.claimStatus,
        existingClaim: canonical.existingClaim,
        sourceFingerprint: canonical.sourceFingerprint,
        sourceCandidates: [
          LegacyMapEventSourceCandidate(
            source: forgedSource,
            evidence: LegacyMapEventSourceEvidenceKind.exactUniqueFootprint,
            confirmed: false,
            reason: 'Candidate injecté par un appelant non canonique.',
          ),
        ],
        pages: canonical.pages,
        preservedEventJson: canonical.preservedEventJson,
        unconvertibleDataPaths: canonical.unconvertibleDataPaths,
        linkedReferences: canonical.linkedReferences,
        diagnostics: canonical.diagnostics,
        manualActions: canonical.manualActions,
      );
      final result = _run(
        projections: [forged],
        map: _map(
          projections: [forged],
          entities: [
            _entity('npc_a', MapEntityKind.npc),
            _entity('npc_forged', MapEntityKind.npc),
          ],
        ),
        project: _project(),
        choices: [
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: forged.provenance,
            source: forgedSource,
            targets: [_target()],
          ),
        ],
      );

      _expectPreflightBlock(result);
      expect(
        _codes(result.plan),
        contains(
          NarrativeEventMigrationDiagnosticCodes.projectionEvidenceMismatch,
        ),
      );
    });

    test('blocks forged preserved MapEvent fields before allocation', () {
      final canonical = _baseProjection('legacy_forged_title');
      final forgedJson = Map<String, Object?>.of(canonical.preservedEventJson)
        ..['title'] = 'Titre injecté';
      final forged = LegacyMapEventProjection(
        provenance: canonical.provenance,
        classification: canonical.classification,
        claimStatus: canonical.claimStatus,
        existingClaim: canonical.existingClaim,
        sourceFingerprint: canonical.sourceFingerprint,
        sourceCandidates: canonical.sourceCandidates,
        pages: canonical.pages,
        preservedEventJson: forgedJson,
        unconvertibleDataPaths: canonical.unconvertibleDataPaths,
        linkedReferences: canonical.linkedReferences,
        diagnostics: canonical.diagnostics,
        manualActions: canonical.manualActions,
      );
      final result = _run(
        projections: [forged],
        map: _baseMap(canonical),
        project: _project(),
        choices: [
          NarrativeEventMigrationSourceChoice.confirmCandidate(
            provenance: forged.provenance,
            source: forged.sourceCandidates.single.source,
            targets: [_target(name: 'Titre injecté')],
          ),
        ],
      );

      _expectPreflightBlock(result);
      expect(
        _codes(result.plan),
        contains(
          NarrativeEventMigrationDiagnosticCodes.projectionEvidenceMismatch,
        ),
      );
    });

    for (final field in const ['position.x', 'position.y', 'pageNumber']) {
      test('blocks lossy numeric coercion in preserved $field', () {
        final canonical = _baseProjection('legacy_forged_number_$field');
        final forgedJson = jsonDecode(
          jsonEncode(canonical.preservedEventJson),
        ) as Map<String, dynamic>;
        switch (field) {
          case 'position.x':
            (forgedJson['position'] as Map<String, dynamic>)['x'] = 1.9;
          case 'position.y':
            (forgedJson['position'] as Map<String, dynamic>)['y'] = 1.9;
          case 'pageNumber':
            ((forgedJson['pages'] as List<dynamic>).single
                as Map<String, dynamic>)['pageNumber'] = 1.9;
        }
        final forged = LegacyMapEventProjection(
          provenance: canonical.provenance,
          classification: canonical.classification,
          claimStatus: canonical.claimStatus,
          existingClaim: canonical.existingClaim,
          sourceFingerprint: canonical.sourceFingerprint,
          sourceCandidates: canonical.sourceCandidates,
          pages: canonical.pages,
          preservedEventJson: forgedJson,
          unconvertibleDataPaths: canonical.unconvertibleDataPaths,
          linkedReferences: canonical.linkedReferences,
          diagnostics: canonical.diagnostics,
          manualActions: canonical.manualActions,
        );
        final result = _run(
          projections: [forged],
          map: _baseMap(canonical),
          project: _project(),
          choices: [
            NarrativeEventMigrationSourceChoice.confirmCandidate(
              provenance: forged.provenance,
              source: forged.sourceCandidates.single.source,
              targets: [_target()],
            ),
          ],
        );

        _expectPreflightBlock(result);
        expect(
          _codes(result.plan),
          contains(
            NarrativeEventMigrationDiagnosticCodes.projectionEvidenceMismatch,
          ),
        );
      });
    }

    test('14. classifies a receipt unknown field as unsupported', () {
      final receipt = _readyReceipt();
      final raw =
          jsonDecode(jsonEncode(receipt.toJson())) as Map<String, dynamic>;
      raw['futureField'] = true;

      final decoded = decodeNarrativeEventMigrationReceiptStrict(
        utf8.encode(jsonEncode(raw)),
      );

      expect(_decodeState(decoded), 'unsupported');
      expect(decoded.receiptOrNull, isNull);
    });

    test('15. classifies a duplicate nested receipt key as invalid', () {
      final encoded = jsonEncode(_readyReceipt().toJson());
      final duplicate = encoded.replaceFirst(
        '"lifecycle":{',
        '"lifecycle":{"status":"prepared",',
      );

      final decoded = decodeNarrativeEventMigrationReceiptStrict(
        utf8.encode(duplicate),
      );

      expect(_decodeState(decoded), 'invalid');
      expect(decoded.receiptOrNull, isNull);
    });

    test('rejects duplicate receipt bytes before consuming IDs or clock', () {
      final encoded = jsonEncode(_readyReceipt().toJson());
      final duplicate = encoded.replaceFirst(
        '"lifecycle":{',
        '"lifecycle":{"status":"prepared",',
      );
      final projection = _baseProjection('legacy_duplicate_receipt_bytes');
      final result = _runBase(
        projection,
        existingReceiptJsonBytes: utf8.encode(duplicate),
      );

      _expectPreflightBlock(result);
      expect(
        _codes(result.plan),
        contains(
            NarrativeEventMigrationDiagnosticCodes.receiptStrictDecodeFailed),
      );
    });

    test('16. an ASSISTED choice cannot invent a Fact or source', () {
      final projection = _baseProjection('legacy_invention');
      final inventedFact = _runBase(
        projection,
        target: _target(
          conditions: [NarrativeEventCondition.fact('invented_fact', true)],
        ),
      );
      final inventedSource = _runBase(
        projection,
        choice: NarrativeEventMigrationSourceChoice.explicitReassignment(
          provenance: projection.provenance,
          source: _entitySource('invented_npc'),
          targets: [_target()],
          reason: 'Choix humain à vérifier contre le projet.',
        ),
      );

      for (final result in [inventedFact, inventedSource]) {
        _expectPreflightBlock(result);
        expect(result.plan.items.single.choiceApplied, isFalse);
      }
    });

    test('binds the validation catalog to the exact current snapshot', () {
      final projection = _baseProjection('legacy_foreign_catalog');
      final map = _baseMap(projection);
      final project = _project();
      final foreignProject = ProjectManifest(
        name: 'Foreign project',
        maps: project.maps,
        tilesets: const [],
        scenes: project.scenes,
      );
      final foreignCatalog = buildNarrativeEventProjectCatalog(
        project: foreignProject,
        maps: [map],
        legacyProjections: [projection],
      );
      final result = _run(
        projections: [projection],
        map: map,
        project: project,
        choices: [_confirmation(projection)],
        catalogOverride: foreignCatalog,
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('validationCatalogMismatch'));
    });

    test('blocks a proposed record outside the atomic target closure', () {
      const externalId = 'evt_018f0000-0000-7000-8000-000000000098';
      final projection = _baseProjection('legacy_external_proposal');
      final external = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: externalId,
          name: 'External proposal',
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          conditions: const [],
          sceneId: 'scene_action',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: 9,
          order: 9,
        ),
        enabled: false,
      );
      final result = _runBase(
        projection,
        proposedRecords: [external],
      );

      _expectPreflightBlock(result);
      expect(_codes(result.plan), contains('migrationEventUnavailable'));
    });

    test('previews claims choices references loss risks and legacy activity',
        () {
      final projection = _baseProjection('legacy_impact');
      final result = _runBase(projection);

      final impact = NarrativeEventMigrationPlanner.previewImpact(
        input: result.input,
        plan: result.plan,
      );

      expect(impact.claimCount, 1);
      expect(impact.confirmedChoiceCount, 1);
      expect(impact.referenceCount, 0);
      expect(impact.collisionCount, 0);
      expect(impact.lossRiskCount, 0);
      expect(impact.legacyRuntimeActive, isTrue);
      expect(impact.retirement.readyToRemoveLegacyPath, isFalse);
      expect(
        impact.retirement.remainingCriteria,
        containsAll(<NarrativeEventLegacyRetirementCriterion>{
          NarrativeEventLegacyRetirementCriterion.v2OnlyMode,
          NarrativeEventLegacyRetirementCriterion.noLegacyMapEvents,
        }),
      );
    });

    test('legacy retirement is ready only for a clean v2Only project', () {
      final result = _run(
        projections: const [],
        map: const MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 8),
        ),
        project: _project(
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: const [],
            legacyClaims: const [],
          ),
        ),
        choices: const [],
      );

      final impact = NarrativeEventMigrationPlanner.previewImpact(
        input: result.input,
        plan: result.plan,
      );

      expect(impact.legacyRuntimeActive, isFalse);
      expect(impact.retirement.readyToRemoveLegacyPath, isTrue);
      expect(impact.retirement.remainingCriteria, isEmpty);
    });

    test('preview counts preserved unknown data as a blocked loss risk', () {
      final projection = _baseProjection('legacy_unknown_impact');
      final result = _runBase(
        projection,
        unknownLegacyData: [
          NarrativeEventUnknownLegacyData(
            path: 'maps.map_a.events.legacy_unknown_impact.futureField',
            value: {'future': true},
          ),
        ],
      );

      final impact = NarrativeEventMigrationPlanner.previewImpact(
        input: result.input,
        plan: result.plan,
      );

      expect(impact.lossRiskCount, greaterThanOrEqualTo(1));
      expect(
        impact.retirement.remainingCriteria,
        contains(
          NarrativeEventLegacyRetirementCriterion.noMigrationBlockers,
        ),
      );
    });
  });
}

_RunResult _runBase(
  LegacyMapEventProjection projection, {
  NarrativeEventMigrationTargetProposal? target,
  NarrativeEventMigrationSourceChoice? choice,
  ProjectManifest? project,
  bool includeCatalog = true,
  List<NarrativeEventRecord> proposedRecords = const [],
  List<NarrativeEventUnknownLegacyData> unknownLegacyData = const [],
  List<int>? existingReceiptJsonBytes,
}) {
  final resolvedChoice = choice ??
      _confirmation(
        projection,
        target: target ?? _target(),
      );
  return _run(
    projections: [projection],
    map: _baseMap(projection),
    project: project ?? _project(),
    choices: [resolvedChoice],
    includeCatalog: includeCatalog,
    proposedRecords: proposedRecords,
    unknownLegacyData: unknownLegacyData,
    existingReceiptJsonBytes: existingReceiptJsonBytes,
  );
}

_RunResult _run({
  required List<LegacyMapEventProjection> projections,
  required MapData map,
  required ProjectManifest project,
  required List<NarrativeEventMigrationSourceChoice> choices,
  bool includeCatalog = true,
  List<NarrativeEventRecord> proposedRecords = const [],
  List<NarrativeEventUnknownLegacyData> unknownLegacyData = const [],
  NarrativeEventProjectCatalog? catalogOverride,
  List<int>? existingReceiptJsonBytes,
}) {
  const corpus = <String, Object?>{'version': 'D0-B-v0'};
  final migrationChoices = NarrativeEventMigrationChoices(
    sourceChoices: choices,
  );
  final referencedOutcomes = _outcomesFrom([
    for (final projection in projections)
      for (final candidate in projection.sourceCandidates) candidate.source,
    for (final choice in choices) choice.source,
  ]);
  final catalog = includeCatalog
      ? catalogOverride ??
          buildNarrativeEventProjectCatalog(
            project: project,
            maps: [map],
            legacyProjections: projections,
            referencedOutcomes: referencedOutcomes,
            proposedRecords: proposedRecords,
          )
      : null;
  final snapshot = NarrativeEventMigrationSnapshot(
    projectRevisionToken: 'revision-d0-b',
    manifestHash: _jsonHash(project.toJson()),
    corpusHash: _jsonHash(corpus),
    referenceCatalogHash: _jsonHash(
      NarrativeEventReferenceCatalog.empty().toJson(),
    ),
    mapHashes: {map.id: _jsonHash(map.toJson())},
    legacySourceHashes: {
      for (final projection in projections)
        legacyMigrationSourceSnapshotKey(projection.provenance):
            projection.sourceFingerprint,
    },
    saveHashes: const {},
  );
  final ids = _CountingIds();
  var clockCalls = 0;
  final planner = NarrativeEventMigrationPlanner(
    ids: ids,
    clock: () {
      clockCalls++;
      return DateTime.utc(2026, 7, 13, 10);
    },
  );
  final input = NarrativeEventMigrationPlannerInput(
    project: project,
    maps: [map],
    mapEventProjections: projections,
    scenarioProjections: const [],
    references: NarrativeEventReferenceCatalog.empty(),
    currentSnapshot: snapshot,
    choices: migrationChoices,
    characterizedCorpus: corpus,
    saveSnapshots: const [],
    unknownLegacyData: unknownLegacyData,
    backupPlan: NarrativeEventMigrationBackupPlan(
      futureDestinations: const {
        'manifest': 'backups/phase-d/project.json',
        'receipt': 'backups/phase-d/receipt.json',
      },
    ),
    existingReceiptJsonBytes: existingReceiptJsonBytes,
    validationCatalog: catalog,
  );
  final plan = planner.plan(input);
  return _RunResult(
    plan: plan,
    input: input,
    ids: ids,
    clockCalls: clockCalls,
  );
}

LegacyMapEventProjection _baseProjection(String legacyEventId) => _projection(
      legacyEventId: legacyEventId,
      candidate: _entitySource('npc_a'),
    );

MapData _baseMap(LegacyMapEventProjection projection) => _map(
      projections: [projection],
      entities: [_entity('npc_a', MapEntityKind.npc)],
    );

NarrativeEventMigrationReceipt _readyReceipt() {
  final projection = _baseProjection('legacy_receipt');
  final result = _runBase(projection);
  expect(result.plan.status, NarrativeEventMigrationPlanStatus.ready);
  return result.plan.receiptProposal!;
}

void _expectPreflightBlock(_RunResult result) {
  expect(result.plan.status, NarrativeEventMigrationPlanStatus.blocked);
  expect(result.plan.canApply, isFalse);
  expect(result.plan.receiptProposal, isNull);
  expect(result.ids.calls, 0);
  expect(result.clockCalls, 0);
}

Set<String> _codes(NarrativeEventMigrationPlan plan) =>
    plan.diagnostics.map((diagnostic) => diagnostic.code).toSet();

String _decodeState(NarrativeEventMigrationReceiptDecodeResult result) {
  return result.when(
    decoded: (_) => 'decoded',
    unsupported: (_, __, ___) => 'unsupported',
    invalid: (_, __, ___) => 'invalid',
  );
}

NarrativeEventMigrationSourceChoice _confirmation(
  LegacyMapEventProjection projection, {
  NarrativeEventMigrationTargetProposal? target,
}) {
  return NarrativeEventMigrationSourceChoice.confirmCandidate(
    provenance: projection.provenance,
    source: projection.sourceCandidates.single.source,
    targets: [target ?? _target()],
  );
}

NarrativeEventMigrationTargetProposal _target({
  String name = 'Migrated Event',
  List<NarrativeEventCondition> conditions = const [],
  String sceneId = 'scene_action',
  int order = 0,
}) {
  return NarrativeEventMigrationTargetProposal(
    name: name,
    legacyPageIndex: 0,
    conditions: conditions,
    sceneId: sceneId,
    reusePolicy: NarrativeEventReusePolicy.reusable,
    priority: 0,
    order: order,
  );
}

LegacyMapEventProjection _projection({
  required String legacyEventId,
  required NarrativeEventSourceRef candidate,
  List<LegacyMigrationDiagnostic> diagnostics = const [],
}) {
  final entityId = candidate.when(
    entityInteract: (_, entityId) => entityId,
    triggerEnter: (_, __) => throw StateError('Expected an entity source.'),
    mapEnter: (_) => throw StateError('Expected an entity source.'),
    outcomeReceived: (_) => throw StateError('Expected an entity source.'),
  );
  final position = _positionForEntityId(entityId);
  final event = MapEventDefinition(
    id: legacyEventId,
    title: 'Legacy $legacyEventId',
    pages: const [
      MapEventPage(
        pageNumber: 1,
        sceneTarget: MapEventSceneTarget(sceneId: 'scene_action'),
      ),
    ],
    position: EventPosition(
      layerId: 'events',
      x: position.x,
      y: position.y,
    ),
    type: MapEventType.object,
  );
  final canonical = projectLegacyMapEventReadOnly(
    mapId: 'map_a',
    map: MapData(
      id: 'map_a',
      name: 'Map A',
      size: const GridSize(width: 8, height: 8),
      layers: const [MapLayer.object(id: 'events', name: 'Events')],
      events: [event],
      entities: [_entity(entityId, MapEntityKind.npc)],
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
  if (diagnostics.isEmpty) return canonical;
  return LegacyMapEventProjection(
    provenance: canonical.provenance,
    classification: canonical.classification,
    claimStatus: canonical.claimStatus,
    existingClaim: canonical.existingClaim,
    sourceFingerprint: canonical.sourceFingerprint,
    sourceCandidates: canonical.sourceCandidates,
    pages: canonical.pages,
    preservedEventJson: canonical.preservedEventJson,
    unconvertibleDataPaths: canonical.unconvertibleDataPaths,
    linkedReferences: canonical.linkedReferences,
    diagnostics: [...canonical.diagnostics, ...diagnostics],
    manualActions: canonical.manualActions,
  );
}

MapData _map({
  required List<LegacyMapEventProjection> projections,
  List<MapEntity> entities = const [],
}) {
  return MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    events: [
      for (final projection in projections)
        MapEventDefinition.fromJson(
          Map<String, dynamic>.from(projection.preservedEventJson),
        ),
    ],
    entities: entities,
  );
}

MapEntity _entity(String id, MapEntityKind kind) => MapEntity(
      id: id,
      name: id,
      kind: kind,
      pos: _positionForEntityId(id),
    );

GridPos _positionForEntityId(String id) {
  final slot = id.codeUnits.fold<int>(0, (sum, value) => sum + value) % 7;
  return GridPos(x: slot, y: slot ~/ 4);
}

NarrativeEventSourceRef _entitySource(String entityId) =>
    NarrativeEventSourceRef.entityInteract('map_a', entityId);

ProjectManifest _project({
  List<SceneAsset>? scenes,
  List<NarrativeFactDefinition> facts = const [],
  NarrativeEventRegistry? eventRegistry,
}) {
  return ProjectManifest(
    name: 'D0-B project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: const [],
    scenes: scenes ?? [_actionScene()],
    facts: facts,
    eventRegistry: eventRegistry,
  );
}

SceneAsset _actionScene() => _scene('scene_action');

SceneAsset _scene(String id) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
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
    );

SceneAsset _outcomeScene(String id, String outcomeId) => SceneAsset(
      id: id,
      name: id,
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

SceneAsset _outcomeSceneWithConsequence(
  String id,
  String outcomeId,
  SceneConsequence consequence,
) =>
    SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'action',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(consequence),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: outcomeId),
          ),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_action',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'action',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_action_end',
            fromNodeId: 'action',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
      declaredOutcomes: [SceneOutcome(id: outcomeId, label: outcomeId)],
    );

NarrativeOutcomeRef _sceneOutcomeRef(String sceneId, String outcomeId) =>
    NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: sceneId,
      outcomeId: outcomeId,
    );

List<NarrativeOutcomeRef> _outcomesFrom(
  Iterable<NarrativeEventSourceRef> sources,
) {
  final byKey = <String, NarrativeOutcomeRef>{};
  for (final source in sources) {
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

String _jsonHash(Object? value) => 'sha256:${narrativeEventCanonicalSha256(
      jsonDecode(jsonEncode(value)),
    )}';

final class _RunResult {
  const _RunResult({
    required this.plan,
    required this.input,
    required this.ids,
    required this.clockCalls,
  });

  final NarrativeEventMigrationPlan plan;
  final NarrativeEventMigrationPlannerInput input;
  final _CountingIds ids;
  final int clockCalls;
}

final class _CountingIds implements NarrativeEventMigrationIdSource {
  int calls = 0;
  int _eventSequence = 1;
  int _receiptSequence = 1;

  @override
  String nextEventId() {
    calls++;
    final suffix = (_eventSequence++).toString().padLeft(12, '0');
    return 'evt_018f0000-0000-7000-8000-$suffix';
  }

  @override
  String nextReceiptId() {
    calls++;
    final suffix = (_receiptSequence++).toString().padLeft(12, '0');
    return 'evmr_018f0000-0000-7000-8000-$suffix';
  }
}
