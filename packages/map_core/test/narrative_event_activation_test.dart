import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('E3 activation', () {
    test('activates a valid configured disabled Event', () {
      final record = configuredRecord();
      final registry = registryWithRecords([record]);
      final result = activateNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord!.enabledOrNull, isTrue);
      expect(result.nextRecord!.definitionOrNull, record.definitionOrNull);
      expect(registry.records.single.enabledOrNull, isFalse);
    });

    test('rejects an exact active conflict and names the conflicting Event',
        () {
      final candidate = configuredRecord();
      final conflict = configuredRecord(id: eventIdB, enabled: true);
      final registry = registryWithRecords([candidate, conflict]);
      final result = activateNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.rejectionCode, 'exactSourceConflict');
      expect(result.humanReason, contains(eventIdB));
    });

    test(
        'allows same source with different priority or order and other sources',
        () {
      final variants = [
        configuredRecord(id: eventIdB, enabled: true, priority: 1),
        configuredRecord(id: eventIdB, enabled: true, order: 1),
        configuredRecord(id: eventIdB, enabled: true, source: triggerSource),
      ];

      for (final active in variants) {
        final registry = registryWithRecords([configuredRecord(), active]);
        final result = activateNarrativeEvent(
          context: configuredAuthoringContext(registry: registry),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        );
        expect(result.status, NarrativeEventAuthoringStatus.applied);
      }
    });

    test('rejects stale revision stale catalog and stale source index', () {
      final record = configuredRecord();
      final registry = registryWithRecords([record]);
      final context = configuredAuthoringContext(registry: registry);
      expect(
        activateNarrativeEvent(
          context: context,
          expectedRevision: 'sha256:old',
          eventId: eventIdA,
        ).status,
        NarrativeEventAuthoringStatus.staleRevision,
      );

      final staleCatalog = authoringCatalogForRegistry(registry);
      final staleContext = authoringContext(
        registry: registry,
        catalog: NarrativeEventProjectCatalog(
          manifestHash: 'manifest-old',
          mapHashes: staleCatalog.mapHashes,
          spatialSources: staleCatalog.spatialSources,
          outcomeSources: staleCatalog.outcomeSources,
          scenes: staleCatalog.scenes,
          facts: staleCatalog.facts,
          events: staleCatalog.events,
          diagnostics: staleCatalog.diagnostics,
        ),
      );
      expect(
        activateNarrativeEvent(
          context: staleContext,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        ).rejectionCode,
        'staleCatalog',
      );

      final enabledIndex = buildNarrativeEventSourceIndex([
        configuredRecord(id: eventIdB, enabled: true),
      ]);
      final staleIndexContext = configuredAuthoringContext(
        registry: registry,
        sourceIndex: enabledIndex,
      );
      expect(
        activateNarrativeEvent(
          context: staleIndexContext,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        ).rejectionCode,
        'staleCatalog',
      );
    });

    test('revalidates references and treats valid already enabled as no-op',
        () {
      final invalid = configuredRecord(sceneId: 'gone');
      final invalidRegistry = registryWithRecords([invalid]);
      final invalidResult = activateNarrativeEvent(
        context: configuredAuthoringContext(registry: invalidRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(invalidResult.rejectionCode, 'sceneMissing');

      final enabled = configuredRecord(enabled: true);
      final enabledResult = activateNarrativeEvent(
        context: configuredAuthoringContext(
          registry: registryWithRecords([enabled]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(enabledResult.status, NarrativeEventAuthoringStatus.noOp);
    });

    test('rejects an exact conflict even when activation is repeated', () {
      final enabled = configuredRecord(enabled: true);
      final conflict = configuredRecord(id: eventIdB, enabled: true);
      final registry = registryWithRecords([enabled, conflict]);
      final result = activateNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.rejectionCode, 'exactSourceConflict');
      expect(result.nextRegistry, isNull);
    });

    test('rejects non-canonical state during deactivation without throwing',
        () {
      final record = configuredRecord(
        enabled: true,
        priority: 0x20000000000001,
      );
      final result = deactivateNarrativeEvent(
        context: configuredAuthoringContext(
          registry: registryWithRecords([record]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.status, NarrativeEventAuthoringStatus.invalidRegistry);
      expect(result.nextRegistry, isNull);
    });

    test(
        'deactivates enabled, no-ops disabled, rejects draft and allows repair',
        () {
      final enabledInvalid = configuredRecord(enabled: true, sceneId: 'gone');
      final enabledRegistry = registryWithRecords([enabledInvalid]);
      final deactivated = deactivateNarrativeEvent(
        context: configuredAuthoringContext(registry: enabledRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(deactivated.status, NarrativeEventAuthoringStatus.applied);
      expect(deactivated.nextRecord!.enabledOrNull, isFalse);

      final disabled = configuredRecord();
      final noOp = deactivateNarrativeEvent(
        context: configuredAuthoringContext(
          registry: registryWithRecords([disabled]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(noOp.status, NarrativeEventAuthoringStatus.noOp);

      final draft = draftRecord();
      final rejected = deactivateNarrativeEvent(
        context: configuredAuthoringContext(
          registry: registryWithRecords([draft]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(rejected.rejectionCode, 'eventNotConfigured');
    });
  });
}
