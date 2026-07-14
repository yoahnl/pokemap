import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('E3 publication', () {
    test('publishes a complete draft as configured disabled', () {
      final claim = authoringClaim();
      final draft = draftRecord(
        name: 'Ready',
        source: entitySource,
        conditions: [NarrativeEventCondition.fact('fact_a', true)],
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: -2,
        order: 8,
      );
      final registry = registryWithRecords(
        [draft],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final result = publishNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord!.definitionOrNull, isNotNull);
      expect(result.nextRecord!.enabledOrNull, isFalse);
      expect(result.nextRecord!.definitionOrNull!.id, eventIdA);
      expect(result.nextRecord!.definitionOrNull!.conditions,
          draft.draftOrNull!.conditions);
      expect(result.nextRegistry!.mode, EventSystemMode.dualRead);
      expect(result.nextRegistry!.legacyClaims, [claim]);
      expect(registry.records.single, draft);
    });

    test('rejects incomplete source Scene and behavior independently', () {
      NarrativeEventAuthoringResult apply(NarrativeEventRecord record) {
        final registry = registryWithRecords([record]);
        return publishNarrativeEvent(
          context: configuredAuthoringContext(registry: registry),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        );
      }

      expect(
        apply(draftRecord(
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
        )).rejectionCode,
        'sourceRequired',
      );
      expect(
        apply(draftRecord(
          source: entitySource,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
        )).rejectionCode,
        'sceneRequired',
      );
      expect(
        apply(draftRecord(
          source: entitySource,
          sceneId: 'scene_a',
        )).rejectionCode,
        'reusePolicyRequired',
      );
    });

    test('rejects invalid source Scene Fact and Event dependency', () {
      NarrativeEventAuthoringResult apply({
        required NarrativeEventRecord record,
        List<NarrativeEventProjectSceneEntry>? scenes,
        List<NarrativeEventProjectFactEntry>? facts,
        List<NarrativeEventRecord> others = const [],
        Set<String> invalidEventIds = const {},
      }) {
        final registry = registryWithRecords([record, ...others]);
        return publishNarrativeEvent(
          context: configuredAuthoringContext(
            registry: registry,
            scenes: scenes,
            facts: facts,
            invalidEventIds: invalidEventIds,
          ),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        );
      }

      final complete = draftRecord(
        source: entitySource,
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
      );
      expect(
        apply(
          record: draftRecord(
            source: NarrativeEventSourceRef.entityInteract('map_a', 'gone'),
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
          ),
        ).rejectionCode,
        'sourceMissing',
      );
      expect(apply(record: complete, scenes: const []).rejectionCode,
          'sceneMissing');
      expect(
        apply(
          record: draftRecord(
            source: entitySource,
            conditions: [NarrativeEventCondition.fact('gone', true)],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
          ),
        ).rejectionCode,
        'factMissing',
      );
      expect(
        apply(
          record: draftRecord(
            source: entitySource,
            conditions: [
              NarrativeEventCondition.narrativeEventConsumed(eventIdB, true),
            ],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
          ),
          others: [configuredRecord(id: eventIdB)],
          invalidEventIds: const {eventIdB},
        ).rejectionCode,
        'eventReferenceUnavailable',
      );
    });

    test('rejects a projected dependency cycle and blocking catalog errors',
        () {
      final draft = draftRecord(
        source: entitySource,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdB, true),
        ],
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
      );
      final eventB = configuredRecord(
        id: eventIdB,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdA, true),
        ],
      );
      final registry = registryWithRecords([draft, eventB]);
      final cycle = publishNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(cycle.rejectionCode, 'eventDependencyCycle');

      final diagnostic = NarrativeEventProjectDiagnostic(
        code: 'duplicateSceneId',
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Projet ambigu.',
        path: 'scenes.other',
      );
      final blocked = publishNarrativeEvent(
        context: configuredAuthoringContext(
          registry: registryWithRecords([
            draftRecord(
              source: entitySource,
              sceneId: 'scene_a',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
            )
          ]),
          diagnostics: [diagnostic],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(blocked.rejectionCode, 'catalogBlocked');
    });

    test('never combines publication with activation or filesystem effects',
        () {
      final registry = registryWithRecords([
        draftRecord(
          source: entitySource,
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.reusable,
        ),
      ]);
      final result = publishNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.nextRecord!.enabledOrNull, isFalse);
      expect(result.mutation, NarrativeEventAuthoringMutation.publish);
      expect(result.undoable, isTrue);
      expect(result.nextRecord!.toJson().keys,
          unorderedEquals(['state', 'definition', 'enabled']));
    });
  });
}
