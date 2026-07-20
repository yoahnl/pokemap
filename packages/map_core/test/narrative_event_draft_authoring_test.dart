import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('E1 draft creation', () {
    test('creates project-level draft from an absent registry', () {
      final result = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: authoringRevision,
        name: '  Nouvel événement  ',
        idGenerator: deterministicGenerator(),
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.previousRegistry, isNull);
      expect(result.nextRegistry?.schemaVersion, 1);
      expect(result.nextRegistry?.mode, EventSystemMode.legacyOnly);
      expect(result.nextRegistry?.legacyClaims, isEmpty);
      expect(result.nextRegistry?.records, hasLength(1));
      final draft = result.nextRecord?.draftOrNull;
      expect(draft?.id, eventIdA);
      expect(draft?.name, 'Nouvel événement');
      expect(draft?.source, isNull);
      expect(draft?.conditions, isEmpty);
      expect(draft?.sceneId, isNull);
      expect(draft?.reusePolicy, isNull);
      expect(draft?.priority, 0);
      expect(draft?.order, 0);
      expect(result.conceptualNextRevision, startsWith('sha256:'));
      expect(result.nextRecord?.definitionOrNull, isNull);
    });

    test('accepts each selectable source kind without copying geometry', () {
      for (final source in [
        entitySource,
        triggerSource,
        mapSource,
        outcomeSource,
      ]) {
        final result = createNarrativeEventDraft(
          context: authoringContext(),
          expectedRevision: authoringRevision,
          name: 'Event',
          initialSource: source,
          idGenerator: deterministicGenerator(),
        );

        expect(result.status, NarrativeEventAuthoringStatus.applied);
        expect(result.nextRecord?.draftOrNull?.source, source);
        final json = result.nextRecord?.draftOrNull?.toJson();
        expect(_containsKeyDeep(json, 'position'), isFalse);
        expect(_containsKeyDeep(json, 'layer'), isFalse);
        expect(_containsKeyDeep(json, 'bounds'), isFalse);
        expect(_containsKeyDeep(json, 'geometry'), isFalse);
        expect(result.humanReason, isNot(contains('NarrativeEvent')));
      }
    });

    test('preserves registry fields and existing record order', () {
      final first = draftRecord(id: eventIdA, order: 4);
      final second = draftRecord(id: eventIdB, order: 9);
      final registry = registryWithRecords(
        [first, second],
        mode: EventSystemMode.dualRead,
      );
      final result = createNarrativeEventDraft(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        name: 'Third',
        idGenerator: deterministicGenerator(eventIdC),
      );

      expect(result.nextRegistry?.schemaVersion, registry.schemaVersion);
      expect(result.nextRegistry?.mode, registry.mode);
      expect(result.nextRegistry?.legacyClaims, registry.legacyClaims);
      expect(result.nextRegistry?.records.take(2), [first, second]);
      expect(result.nextRecord?.draftOrNull?.order, 10);
      expect(registry.records, [first, second]);
    });

    test('preserves non-empty claims exactly', () {
      final existing = configuredRecord(source: entitySource);
      final claim = authoringClaim();
      final registry = registryWithRecords(
        [existing],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final result = createNarrativeEventDraft(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        name: 'Second',
        idGenerator: deterministicGenerator(eventIdB),
      );

      expect(result.nextRegistry?.legacyClaims, [claim]);
      expect(result.nextRegistry?.mode, EventSystemMode.dualRead);
    });

    test('rejects stale revision and catalog before consuming an ID', () {
      var generated = 0;
      final generator = NarrativeEventIdGenerator(rawUuidFactory: () {
        generated++;
        return eventIdA.substring(4);
      });
      final staleRevision = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: 'sha256:stale',
        name: 'Event',
        idGenerator: generator,
      );
      final staleCatalog = createNarrativeEventDraft(
        context: authoringContext(manifestHash: 'different'),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: generator,
      );

      expect(staleRevision.status, NarrativeEventAuthoringStatus.staleRevision);
      expect(staleCatalog.rejectionCode, 'staleCatalog');
      expect(generated, 0);
    });

    test('rejects missing unavailable and ambiguous sources before ID use', () {
      final missing = NarrativeEventSourceRef.mapEnter('missing');
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
      var generated = 0;
      final generator = NarrativeEventIdGenerator(rawUuidFactory: () {
        generated++;
        return eventIdA.substring(4);
      });
      final context = authoringContext(
        catalog: authoringCatalog(spatialOptions: options),
      );

      final results = [
        createNarrativeEventDraft(
          context: context,
          expectedRevision: authoringRevision,
          name: 'Missing',
          initialSource: missing,
          idGenerator: generator,
        ),
        createNarrativeEventDraft(
          context: context,
          expectedRevision: authoringRevision,
          name: 'Unavailable',
          initialSource: unavailable,
          idGenerator: generator,
        ),
        createNarrativeEventDraft(
          context: context,
          expectedRevision: authoringRevision,
          name: 'Ambiguous',
          initialSource: ambiguous,
          idGenerator: generator,
        ),
      ];

      expect(
        results.map((result) => result.rejectionCode),
        ['sourceMissing', 'sourceUnavailable', 'sourceAmbiguous'],
      );
      expect(generated, 0);
    });

    test('rejects empty name and maximum order without consuming an ID', () {
      var generated = 0;
      final generator = NarrativeEventIdGenerator(rawUuidFactory: () {
        generated++;
        return eventIdB.substring(4);
      });
      final emptyName = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: authoringRevision,
        name: '   ',
        idGenerator: generator,
      );
      final overflow = createNarrativeEventDraft(
        context: authoringContext(
          registry: registryWithRecords([
            draftRecord(order: narrativeEventMaximumAuthoringOrder),
          ]),
        ),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: generator,
      );

      expect(emptyName.rejectionCode, 'emptyName');
      expect(overflow.rejectionCode, 'orderOverflow');
      expect(overflow.humanReason, isNot(contains('authoring')));
      expect(generated, 0);
    });

    test('rejects invalid name encoding and blocked catalog before ID use', () {
      var generated = 0;
      final generator = NarrativeEventIdGenerator(rawUuidFactory: () {
        generated++;
        return eventIdA.substring(4);
      });
      final invalidName = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: authoringRevision,
        name: String.fromCharCode(0xd800),
        idGenerator: generator,
      );
      final blockedCatalog = createNarrativeEventDraft(
        context: authoringContext(
          catalog: authoringCatalog(
            diagnostics: [
              NarrativeEventProjectDiagnostic(
                code: 'projectIncomplete',
                severity: NarrativeEventProjectDiagnosticSeverity.error,
                message: 'Projet incomplet',
                path: 'maps',
              ),
            ],
          ),
        ),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: generator,
      );

      expect(invalidName.rejectionCode, 'invalidNameEncoding');
      expect(blockedCatalog.rejectionCode, 'catalogBlocked');
      expect(generated, 0);
    });

    test('reports generator exhaustion without creating a registry', () {
      final existing = draftRecord(id: eventIdA);
      final result = createNarrativeEventDraft(
        context: authoringContext(
          registry: registryWithRecords([existing]),
        ),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: deterministicGenerator(eventIdA),
      );

      expect(result.rejectionCode, 'idGenerationFailed');
      expect(result.nextRegistry, isNull);
      expect(result.humanReason, isNot(contains('StateError')));
    });

    test('keeps deterministic results with equivalent injected generators', () {
      final first = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: deterministicGenerator(),
      );
      final second = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: deterministicGenerator(),
      );

      expect(first.nextRegistry, second.nextRegistry);
      expect(first.conceptualNextRevision, second.conceptualNextRevision);
    });

    test('keeps unsupported and invalid registries read-only', () {
      final unsupported = createNarrativeEventDraft(
        context: authoringContext(
          registryState: EventRegistryDecodeResult.unsupported(
            const {'schemaVersion': 2},
            const ['Version future'],
          ),
        ),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: deterministicGenerator(),
      );
      final invalid = createNarrativeEventDraft(
        context: authoringContext(
          registryState: EventRegistryDecodeResult.invalid(
            const {'records': null},
            const ['Registry invalide'],
          ),
        ),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: deterministicGenerator(),
      );

      expect(
        unsupported.status,
        NarrativeEventAuthoringStatus.unsupportedRegistry,
      );
      expect(invalid.status, NarrativeEventAuthoringStatus.invalidRegistry);
    });

    test('uses generator collision policy across all records', () {
      final registry = registryWithRecords([draftRecord(id: eventIdA)]);
      final values = [eventIdA.substring(4), eventIdB.substring(4)];
      final generator = NarrativeEventIdGenerator(
        rawUuidFactory: () => values.removeAt(0),
      );
      final result = createNarrativeEventDraft(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        name: 'Event',
        idGenerator: generator,
      );

      expect(result.eventId, eventIdB);
    });

    test('created draft is absent from the enabled source index', () {
      final result = createNarrativeEventDraft(
        context: authoringContext(),
        expectedRevision: authoringRevision,
        name: 'Event',
        initialSource: entitySource,
        idGenerator: deterministicGenerator(),
      );
      final index = buildNarrativeEventSourceIndex(
        result.nextRegistry!.records,
      );

      expect(index.index.containsSource(entitySource), isFalse);
      expect(index.conflicts, isEmpty);
    });

    test('duplicates an incomplete draft without publishing it implicitly', () {
      final original = draftRecord(name: 'À terminer', order: 6);
      final registry = registryWithRecords([original]);

      final result = duplicateNarrativeEvent(
        context: authoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        idGenerator: deterministicGenerator(eventIdB),
      );

      expect(result.nextRecord!.draftOrNull!.source, isNull);
      expect(result.nextRecord!.draftOrNull!.sceneId, isNull);
      expect(result.nextRecord!.draftOrNull!.reusePolicy, isNull);
      expect(result.nextRecord!.draftOrNull!.order, 7);
      expect(result.nextRecord!.definitionOrNull, isNull);
    });
  });
}

bool _containsKeyDeep(Object? value, String key) {
  if (value is Map) {
    if (value.containsKey(key)) return true;
    return value.values.any((item) => _containsKeyDeep(item, key));
  }
  if (value is List) {
    return value.any((item) => _containsKeyDeep(item, key));
  }
  return false;
}
