import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('E2 source authoring', () {
    test('revalidates an unchanged source before returning no-op', () {
      final missingSource =
          NarrativeEventSourceRef.entityInteract('map_a', 'missing');
      final record = draftRecord(source: missingSource);
      final registry = registryWithRecords([record]);
      final result = replaceNarrativeEventSource(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: missingSource,
      );

      expect(result.rejectionCode, 'sourceMissing');
      expect(result.nextRegistry, isNull);
    });

    test('rejects a non-canonical projected source through the typed result',
        () {
      final source = NarrativeEventSourceRef.entityInteract('map_a', '\ufdd0');
      final record = draftRecord();
      final registry = registryWithRecords([record]);
      final result = selectNarrativeEventSource(
        context: authoringContext(
          registry: registry,
          catalog: authoringCatalog(
            spatialOptions: [spatialOption(source)],
            events: [
              NarrativeEventProjectEventEntry(
                record: record,
                proposed: false,
                inDependencyCycle: false,
                contextuallyValid: false,
              ),
            ],
          ),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: source,
      );

      expect(result.rejectionCode, 'invalidProjectedRegistry');
      expect(result.nextRegistry, isNull);
    });

    test('selects and replaces every source kind while preserving properties',
        () {
      final conditions = [NarrativeEventCondition.fact('fact_a', true)];
      for (final source in [
        entitySource,
        triggerSource,
        mapSource,
        outcomeSource,
      ]) {
        final original = draftRecord(
          name: 'Event',
          conditions: conditions,
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: -4,
          order: 8,
        );
        final registry = registryWithRecords([original]);
        final result = selectNarrativeEventSource(
          context: authoringContext(registry: registry),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          source: source,
        );
        final next = result.nextRecord?.draftOrNull;

        expect(result.status, NarrativeEventAuthoringStatus.applied);
        expect(next?.id, eventIdA);
        expect(next?.name, 'Event');
        expect(next?.source, source);
        expect(next?.conditions, conditions);
        expect(next?.sceneId, 'scene_a');
        expect(next?.reusePolicy, NarrativeEventReusePolicy.reusable);
        expect(next?.priority, -4);
        expect(next?.order, 8);
        expect(registry.records.single, original);
      }
    });

    test('supports explicit cross-kind replacement and exact outcome identity',
        () {
      final original = configuredRecord(
        source: triggerSource,
        priority: 3,
        order: 7,
      );
      final registry = registryWithRecords([original]);
      final result = replaceNarrativeEventSource(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: outcomeSource,
      );
      final next = result.nextRecord?.definitionOrNull;

      expect(result.mutation, NarrativeEventAuthoringMutation.replaceSource);
      expect(next?.source, outcomeSource);
      final encoded = next?.source.toJson();
      expect(
        encoded,
        {
          'kind': 'outcomeReceived',
          'outcome': {
            'producerKind': 'scene',
            'producerId': 'scene_a',
            'outcomeId': 'win',
          },
        },
      );
      expect(next?.priority, 3);
      expect(next?.order, 7);
    });

    test('same source is a truthful no-op with no revision or undo', () {
      final original = draftRecord(source: entitySource);
      final registry = registryWithRecords([original]);
      final result = selectNarrativeEventSource(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: entitySource,
      );

      expect(result.status, NarrativeEventAuthoringStatus.noOp);
      expect(result.nextRegistry, isNull);
      expect(result.conceptualNextRevision, isNull);
      expect(result.undoable, isFalse);
      expect(result.impactPreview?.physicalSourceDeleted, isFalse);
    });

    test('keeps select and replace intentions explicit', () {
      final selected = draftRecord(source: entitySource);
      final selectAgain = selectNarrativeEventSource(
        context: authoringContext(
          registry: registryWithRecords([selected]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: triggerSource,
      );
      final empty = draftRecord();
      final replaceMissing = replaceNarrativeEventSource(
        context: authoringContext(registry: registryWithRecords([empty])),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: entitySource,
      );

      expect(selectAgain.rejectionCode, 'sourceAlreadySelected');
      expect(replaceMissing.rejectionCode, 'sourceNotSelected');
    });

    test('same source on an enabled event remains a no-op', () {
      final enabled = configuredRecord(source: entitySource, enabled: true);
      final result = replaceNarrativeEventSource(
        context: authoringContext(registry: registryWithRecords([enabled])),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: entitySource,
      );

      expect(result.status, NarrativeEventAuthoringStatus.noOp);
      expect(result.nextRegistry, isNull);
      expect(result.undoable, isFalse);
    });

    test('rejects missing unavailable ambiguous stale and enabled changes', () {
      final unavailable = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'blocked',
      );
      final ambiguous = NarrativeEventSourceRef.triggerEnter(
        'map_a',
        'duplicate',
      );
      final options = [
        spatialOption(
          unavailable,
          availability:
              NarrativeSpatialEventSourceAvailability.visibleButUnavailable,
        ),
        spatialOption(ambiguous),
        spatialOption(ambiguous),
      ];
      final record = configuredRecord(enabled: false);
      final registry = registryWithRecords([record]);
      final catalog = authoringCatalog(
        spatialOptions: options,
        events: [
          NarrativeEventProjectEventEntry(
            record: record,
            proposed: false,
            inDependencyCycle: false,
            contextuallyValid: false,
          ),
        ],
      );
      final context = authoringContext(registry: registry, catalog: catalog);
      final missing = replaceNarrativeEventSource(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: NarrativeEventSourceRef.mapEnter('missing'),
      );
      final blocked = replaceNarrativeEventSource(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: unavailable,
      );
      final duplicate = replaceNarrativeEventSource(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: ambiguous,
      );
      final stale = replaceNarrativeEventSource(
        context: context,
        expectedRevision: 'sha256:stale',
        eventId: eventIdA,
        source: ambiguous,
      );
      final enabledRecord = configuredRecord(enabled: true);
      final enabled = replaceNarrativeEventSource(
        context: authoringContext(
          registry: registryWithRecords([enabledRecord]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: triggerSource,
      );

      expect(missing.rejectionCode, 'sourceMissing');
      expect(blocked.rejectionCode, 'sourceUnavailable');
      expect(duplicate.rejectionCode, 'sourceAmbiguous');
      expect(stale.status, NarrativeEventAuthoringStatus.staleRevision);
      expect(enabled.rejectionCode, 'mustDisableFirst');
    });

    test('blocks select replace and remove on an incomplete catalog', () {
      NarrativeEventAuthoringContext blockedContext(
        NarrativeEventRecord record,
      ) {
        return authoringContext(
          registry: registryWithRecords([record]),
          catalog: authoringCatalog(
            events: [
              NarrativeEventProjectEventEntry(
                record: record,
                proposed: false,
                inDependencyCycle: false,
                contextuallyValid: record.definitionOrNull != null,
              ),
            ],
            diagnostics: [
              NarrativeEventProjectDiagnostic(
                code: 'projectIncomplete',
                severity: NarrativeEventProjectDiagnosticSeverity.error,
                message: 'Projet incomplet',
                path: 'maps',
              ),
            ],
          ),
        );
      }

      final empty = draftRecord();
      final selected = draftRecord(source: entitySource);
      final select = selectNarrativeEventSource(
        context: blockedContext(empty),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: entitySource,
      );
      final replace = replaceNarrativeEventSource(
        context: blockedContext(selected),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: triggerSource,
      );
      final remove = removeNarrativeEventSource(
        context: blockedContext(selected),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(select.rejectionCode, 'catalogBlocked');
      expect(replace.rejectionCode, 'catalogBlocked');
      expect(remove.rejectionCode, 'catalogBlocked');
    });

    test('removes source from draft and preserves every other property', () {
      final conditions = [NarrativeEventCondition.fact('fact_a', false)];
      final original = draftRecord(
        source: entitySource,
        conditions: conditions,
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: -2,
        order: 9,
      );
      final registry = registryWithRecords([original]);
      final result = removeNarrativeEventSource(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      final next = result.nextRecord?.draftOrNull;

      expect(next?.source, isNull);
      expect(next?.conditions, conditions);
      expect(next?.sceneId, 'scene_a');
      expect(next?.reusePolicy, NarrativeEventReusePolicy.oneShot);
      expect(next?.priority, -2);
      expect(next?.order, 9);
      expect(result.impactPreview?.structuralUnpublish, isFalse);
    });

    test('removes configured disabled source by explicit structural unpublish',
        () {
      final original = configuredRecord(
        source: mapSource,
        conditions: [NarrativeEventCondition.fact('fact_a', true)],
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 5,
        order: 6,
      );
      final registry = registryWithRecords([original]);
      final result = removeNarrativeEventSource(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      final draft = result.nextRecord?.draftOrNull;

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(draft, isNotNull);
      expect(draft?.source, isNull);
      expect(draft?.name, original.definitionOrNull?.name);
      expect(draft?.conditions, original.definitionOrNull?.conditions);
      expect(draft?.sceneId, original.definitionOrNull?.sceneId);
      expect(draft?.reusePolicy, original.definitionOrNull?.reusePolicy);
      expect(draft?.priority, original.definitionOrNull?.priority);
      expect(draft?.order, original.definitionOrNull?.order);
      expect(result.impactPreview?.structuralUnpublish, isTrue);
      expect(result.impactPreview?.physicalSourceDeleted, isFalse);
    });

    test('rejects removal from enabled and no-ops when draft has no source',
        () {
      final enabled = configuredRecord(enabled: true);
      final enabledResult = removeNarrativeEventSource(
        context: authoringContext(registry: registryWithRecords([enabled])),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      final empty = draftRecord();
      final noOp = removeNarrativeEventSource(
        context: authoringContext(registry: registryWithRecords([empty])),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(enabledResult.rejectionCode, 'mustDisableFirst');
      expect(noOp.status, NarrativeEventAuthoringStatus.noOp);
      expect(noOp.nextRegistry, isNull);
    });

    test('keeps a broken source until an explicit replace or remove action',
        () {
      final broken = NarrativeEventSourceRef.entityInteract(
        'map_missing',
        'npc_missing',
      );
      final original = configuredRecord(source: broken);
      final registry = registryWithRecords([original]);
      final context = authoringContext(
        registry: registry,
        catalog: authoringCatalog(
          events: [
            NarrativeEventProjectEventEntry(
              record: original,
              proposed: false,
              inDependencyCycle: false,
              contextuallyValid: false,
            ),
          ],
          diagnostics: [
            NarrativeEventProjectDiagnostic(
              code: 'narrativeEventSourceMissing',
              severity: NarrativeEventProjectDiagnosticSeverity.error,
              message: 'Source absente',
              path: 'eventRegistry.records.$eventIdA.source',
            ),
          ],
        ),
      );

      expect(context.registryOrNull?.records.single, original);
      final replaced = replaceNarrativeEventSource(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: entitySource,
      );

      expect(original.definitionOrNull?.source, broken);
      expect(replaced.status, NarrativeEventAuthoringStatus.applied);
      expect(replaced.nextRecord?.definitionOrNull?.source, entitySource);
      expect(replaced.impactPreview?.currentSourceSentence,
          contains('npc_missing'));
      expect(replaced.impactPreview?.currentNavigation, isNull);
      expect(
        replaced.impactPreview?.currentOrigin,
        NarrativeEventSourceAuthoringOrigin.unresolvedReference,
      );
    });

    test('impact preview describes both sources and never deletes map data',
        () {
      final original = draftRecord(source: entitySource);
      final result = replaceNarrativeEventSource(
        context: authoringContext(
          registry: registryWithRecords([original]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: outcomeSource,
      );
      final impact = result.impactPreview;

      expect(impact?.currentSourceSentence, isNotEmpty);
      expect(impact?.nextSourceSentence, contains('scene_a'));
      expect(impact?.currentMapId, 'map_a');
      expect(impact?.nextMapId, isNull);
      expect(
        impact?.currentOrigin,
        NarrativeEventSourceAuthoringOrigin.canonicalSpatial,
      );
      expect(
        impact?.nextOrigin,
        NarrativeEventSourceAuthoringOrigin.sceneOutcome,
      );
      expect(
        impact?.currentNavigation?.kind,
        NarrativeEditorDestinationKind.focusEntity,
      );
      expect(
        impact?.nextNavigation?.kind,
        NarrativeEditorDestinationKind.openOutcomeProducer,
      );
      expect(impact?.diagnosticsLikelyToChange, isNotEmpty);
      expect(impact?.physicalSourceDeleted, isFalse);
    });

    test('preserves registry schema mode claims and record order', () {
      final first = draftRecord(id: eventIdA, source: entitySource);
      final second = draftRecord(id: eventIdB, source: mapSource);
      final registry = registryWithRecords(
        [first, second],
        mode: EventSystemMode.v2Only,
      );
      final result = replaceNarrativeEventSource(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: triggerSource,
      );

      expect(result.nextRegistry?.schemaVersion, registry.schemaVersion);
      expect(result.nextRegistry?.mode, registry.mode);
      expect(result.nextRegistry?.legacyClaims, registry.legacyClaims);
      expect(result.nextRegistry?.records.map((record) => record.id), [
        eventIdA,
        eventIdB,
      ]);
      expect(result.nextRegistry?.records[1], second);
    });

    test('keeps claimed sources pinned in dualRead and allows exact repair',
        () {
      final claim = authoringClaim(source: entitySource);
      final pinned = configuredRecord(source: entitySource);
      final pinnedRegistry = registryWithRecords(
        [pinned],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final replace = replaceNarrativeEventSource(
        context: authoringContext(registry: pinnedRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: triggerSource,
      );
      final remove = removeNarrativeEventSource(
        context: authoringContext(registry: pinnedRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      final broken = configuredRecord(
        source: NarrativeEventSourceRef.entityInteract(
          'map_missing',
          'npc_missing',
        ),
      );
      final repaired = replaceNarrativeEventSource(
        context: authoringContext(
          registry: registryWithRecords(
            [broken],
            mode: EventSystemMode.dualRead,
            claims: [claim],
          ),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        source: entitySource,
      );

      expect(replace.rejectionCode, 'sourceClaimPinned');
      expect(remove.rejectionCode, 'sourceClaimPinned');
      expect(repaired.status, NarrativeEventAuthoringStatus.applied);
      expect(repaired.nextRegistry?.legacyClaims, [claim]);
    });
  });
}
