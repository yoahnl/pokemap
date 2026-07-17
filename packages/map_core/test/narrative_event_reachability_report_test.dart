import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

const _eventE = 'evt_019abcde-0000-7000-8000-000000000005';
const _eventF = 'evt_019abcde-0000-7000-8000-000000000006';

void main() {
  group('I2 Event V2 reachability report', () {
    test('keeps structural order, exact conflicts, claims and unknown runtime',
        () {
      final conflictSource = NarrativeEventSourceRef.mapEnter('map_a');
      final disabledSource = NarrativeEventSourceRef.mapEnter('map_disabled');
      final conditionSource =
          NarrativeEventSourceRef.outcomeReceived(outcomeRef);
      final records = <NarrativeEventRecord>[
        configuredRecord(
          id: eventIdC,
          source: conflictSource,
          priority: 20,
          order: 99,
          enabled: true,
        ),
        configuredRecord(
          id: eventIdB,
          source: conflictSource,
          priority: 10,
          order: 2,
          enabled: true,
        ),
        configuredRecord(
          id: eventIdA,
          source: conflictSource,
          priority: 10,
          order: 2,
          enabled: true,
        ),
        configuredRecord(
          id: eventIdD,
          source: disabledSource,
          priority: 99,
          enabled: false,
        ),
        configuredRecord(
          id: _eventF,
          source: conditionSource,
          conditions: [NarrativeEventCondition.fact('fact_a', true)],
          enabled: true,
        ),
      ];
      final claim = authoringClaim(
        source: conflictSource,
        targetEventIds: [eventIdA],
      );
      final registry = registryWithRecords(
        records,
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );

      final report = buildNarrativeEventReachabilityReport(
        registry: registry,
        catalog: _catalog(registry),
      );
      final conflict = report.sources.singleWhere(
        (source) => source.source == conflictSource,
      );
      expect(conflict.orderedEventIds, [eventIdC, eventIdA, eventIdB]);
      expect(conflict.hasOrderingConflict, isTrue);
      expect(conflict.claimedTargetEventIds, [eventIdA]);
      expect(conflict.status, NarrativeEventReachabilityStatus.runtimeUnknown);

      final disabled = report.sources.singleWhere(
        (source) => source.source == disabledSource,
      );
      expect(disabled.disabledEventIds, [eventIdD]);
      expect(disabled.status, NarrativeEventReachabilityStatus.unreachable);
      expect(disabled.reasons, contains('disabled'));

      final condition = report.sources.singleWhere(
        (source) => source.source == conditionSource,
      );
      expect(condition.status, NarrativeEventReachabilityStatus.runtimeUnknown);
      final unknown = report.diagnostics.where(
        (diagnostic) => diagnostic.code == 'runtimeUnknown',
      );
      expect(unknown, isNotEmpty);
      expect(
        unknown.every(
          (diagnostic) =>
              diagnostic.severity == NarrativeEventValidationSeverity.warning,
        ),
        isTrue,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'runtimeUnknown' &&
              diagnostic.severity == NarrativeEventValidationSeverity.error,
        ),
        isEmpty,
      );
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(['sourceOrderingConflict', 'sourceClaimedByV2']),
      );
      expect(
        report.diagnostics
            .where((diagnostic) => diagnostic.code == 'sourceOrderingConflict')
            .map((diagnostic) => diagnostic.eventId),
        containsAll([eventIdA, eventIdB]),
      );
      expect(
        report.diagnostics
            .where((diagnostic) => diagnostic.code == 'runtimeUnknown')
            .first
            .destination
            .kind,
        NarrativeEventValidationDestinationKind.mapSource,
      );

      final permutedRegistry = registryWithRecords(
        records.reversed.toList(),
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final permuted = buildNarrativeEventReachabilityReport(
        registry: permutedRegistry,
        catalog: _catalog(permutedRegistry),
      );
      expect(permuted.toDebugJson(), report.toDebugJson());
    });

    test(
        'reuses dispatch authority for consumed and missing runtime references',
        () {
      final consumedSource = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'npc_a',
      );
      final missingReferenceSource =
          NarrativeEventSourceRef.triggerEnter('map_a', 'zone_a');
      final records = <NarrativeEventRecord>[
        configuredRecord(
          id: eventIdC,
          source: consumedSource,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          enabled: true,
        ),
        configuredRecord(
          id: _eventE,
          source: missingReferenceSource,
          sceneId: 'scene_missing',
          enabled: true,
        ),
      ];
      final registry = registryWithRecords(
        records,
        mode: EventSystemMode.v2Only,
      );
      final report = buildNarrativeEventReachabilityReport(
        registry: registry,
        catalog: _catalog(registry),
        runtime: NarrativeEventReachabilityRuntimeSnapshot.complete(
          gameState: GameState(
            saveId: 'reachability',
            narrativeEventProgress: NarrativeEventProgress(
              consumedNarrativeEventIds: [eventIdC],
            ),
          ),
          factResolver: NarrativeFactRuntimeResolver.fromFacts(
            [factEntry().fact],
          ),
        ),
      );

      final consumed = report.sources.singleWhere(
        (source) => source.source == consumedSource,
      );
      expect(consumed.status, NarrativeEventReachabilityStatus.unreachable);
      expect(consumed.reasons, contains('eventConsumed'));

      final missing = report.sources.singleWhere(
        (source) => source.source == missingReferenceSource,
      );
      expect(missing.status, NarrativeEventReachabilityStatus.unreachable);
      expect(missing.reasons, contains('runtimeReferenceUnavailable'));
    });
  });
}

NarrativeEventProjectCatalog _catalog(NarrativeEventRegistry registry) {
  return authoringCatalog(
    spatialOptions: [
      spatialOption(NarrativeEventSourceRef.mapEnter('map_a')),
      spatialOption(NarrativeEventSourceRef.mapEnter('map_disabled')),
      spatialOption(entitySource),
      spatialOption(triggerSource),
    ],
    scenes: [sceneEntry()],
    facts: [factEntry()],
    events: [
      for (final record in registry.records)
        NarrativeEventProjectEventEntry(
          record: record,
          proposed: false,
          inDependencyCycle: false,
          contextuallyValid: true,
        ),
    ],
  );
}
