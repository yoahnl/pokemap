import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C4 reference mapping', () {
    final provenanceA = LegacySourceRef.mapEvent('map_a', 'shared');
    final provenanceB = LegacySourceRef.mapEvent('map_b', 'shared');
    final targets = <LegacySourceRef, List<String>>{
      provenanceA: const ['evt_018f0000-0000-7000-8000-000000000001'],
      provenanceB: const ['evt_018f0000-0000-7000-8000-000000000002'],
    };

    test('rejects reference kinds placed in the wrong catalog domain', () {
      final worldRule = _reference(
        kind: LegacyEventReferenceKind.worldRuleSource,
        path: 'worldRules.rule_a.source',
        candidates: [provenanceA],
      );

      expect(
        () => NarrativeEventReferenceCatalog(progression: [worldRule]),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventReferenceCatalog(worldRules: [worldRule]),
        returnsNormally,
      );
    });

    test('blocks ambiguous consumedEventIds until an explicit choice exists',
        () {
      final reference = _reference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        candidates: [provenanceA, provenanceB],
      );

      final unresolved = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
      );
      expect(unresolved.hasBlockingMappings, isTrue);
      expect(
        unresolved.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.requiresChoice,
      );
      expect(unresolved.progressionMappings.single.targetEventIds, isEmpty);

      final consumeAll = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision:
                NarrativeEventReferenceCollisionDecision.consumeAllTargets,
          ),
        ],
      );
      expect(consumeAll.hasBlockingMappings, isFalse);
      expect(
        consumeAll.progressionMappings.single.targetEventIds,
        [
          'evt_018f0000-0000-7000-8000-000000000001',
          'evt_018f0000-0000-7000-8000-000000000002',
        ],
      );

      final selected = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision: NarrativeEventReferenceCollisionDecision.selectedTargets,
            selectedTargetEventIds: const [
              'evt_018f0000-0000-7000-8000-000000000002',
            ],
          ),
        ],
      );
      expect(
        selected.progressionMappings.single.targetEventIds,
        ['evt_018f0000-0000-7000-8000-000000000002'],
      );

      final cancelled = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision: NarrativeEventReferenceCollisionDecision.cancel,
          ),
        ],
      );
      expect(
        cancelled.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.cancelled,
      );

      final duplicateChoice = NarrativeEventReferenceResolutionChoice(
        path: reference.path,
        decision: NarrativeEventReferenceCollisionDecision.consumeAllTargets,
      );
      expect(
        () => buildNarrativeEventReferenceMappings(
          targetEventIdsByProvenance: targets,
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
          choices: [duplicateChoice, duplicateChoice],
        ),
        throwsArgumentError,
      );
    });

    test('requires a choice before one provenance fans out to many Events', () {
      final reference = _reference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[1]',
        candidates: [provenanceA],
      );
      final fanOutTargets = <LegacySourceRef, List<String>>{
        provenanceA: const [
          'evt_018f0000-0000-7000-8000-000000000001',
          'evt_018f0000-0000-7000-8000-000000000003',
        ],
      };

      final unresolved = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: fanOutTargets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
      );
      expect(
        unresolved.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.requiresChoice,
      );

      final explicit = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: fanOutTargets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision:
                NarrativeEventReferenceCollisionDecision.consumeAllTargets,
          ),
        ],
      );
      expect(
        explicit.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.mapped,
      );
      expect(explicit.progressionMappings.single.targetEventIds, hasLength(2));
    });

    test('maps condition, World Rule, consequence, and save references', () {
      LegacyEventReference unique(LegacyEventReferenceKind kind, String path) {
        return _reference(kind: kind, path: path, candidates: [provenanceA]);
      }

      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          conditions: [
            unique(
              LegacyEventReferenceKind.scriptCondition,
              'maps.map_a.events.shared.pages[0].condition',
            ),
          ],
          worldRules: [
            unique(
              LegacyEventReferenceKind.worldRuleSource,
              'worldRules.rule_a.source',
            ),
          ],
          consequences: [
            unique(
              LegacyEventReferenceKind.sceneConsequence,
              'scenes.scene_a.consequences[0]',
            ),
          ],
          saves: [
            unique(
              LegacyEventReferenceKind.consumedEventState,
              'saves.save_a.consumedEventIds[0]',
            ),
          ],
        ),
      );

      for (final mapping in [
        mappings.conditionMappings.single,
        mappings.worldRuleMappings.single,
        mappings.consequenceMappings.single,
        mappings.saveMappings.single,
      ]) {
        expect(mapping.status, NarrativeEventReferenceMappingStatus.mapped);
        expect(
          mapping.targetEventIds,
          ['evt_018f0000-0000-7000-8000-000000000001'],
        );
      }
    });

    test('preserves unknown progression and save IDs as tombstones', () {
      final unknownSave = _reference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'saves.save_a.consumedEventIds[0]',
        candidates: const [],
      );
      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(saves: [unknownSave]),
      );

      expect(mappings.hasBlockingMappings, isFalse);
      expect(
        mappings.saveMappings.single.status,
        NarrativeEventReferenceMappingStatus.preservedTombstone,
      );
      expect(mappings.saveMappings.single.legacyEventId, 'shared');
    });

    test('keeps ID, page, and reference mappings deeply immutable', () {
      final ids = NarrativeEventIdMapping(
        provenance: provenanceA,
        legacyId: 'shared',
        targetEventIds: targets[provenanceA]!,
      );
      final page = NarrativeEventPageMapping(
        provenance: provenanceA,
        pageIndex: 0,
        pageNumber: 1,
        status: NarrativeEventPageMappingStatus.preservedLegacy,
        preservedPageJson: {
          'metadata': {
            'future': ['kept'],
          },
        },
      );
      final mappings = NarrativeEventReferenceMappings(
        idMappings: [ids],
        pageMappings: [page],
      );

      expect(
        () => mappings.idMappings.add(ids),
        throwsUnsupportedError,
      );
      expect(
        () => page.preservedPageJson['new'] = true,
        throwsUnsupportedError,
      );
      final metadata = page.preservedPageJson['metadata']! as Map;
      expect(() => metadata['future'] = const [], throwsUnsupportedError);
      final future = metadata['future']! as List;
      expect(() => future.add('lost'), throwsUnsupportedError);

      final roundTrip = NarrativeEventReferenceMappings.fromJson(
        mappings.toJson(),
      );
      expect(roundTrip.toJson(), mappings.toJson());
    });
  });
}

LegacyEventReference _reference({
  required LegacyEventReferenceKind kind,
  required String path,
  required List<LegacySourceRef> candidates,
}) {
  return LegacyEventReference(
    kind: kind,
    path: path,
    legacyEventId: 'shared',
    candidateProvenances: candidates,
  );
}
