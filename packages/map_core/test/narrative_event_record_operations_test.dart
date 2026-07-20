import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('NSC-40 Event record lifecycle', () {
    test('duplicates a configured Event as a disabled draft with a new id', () {
      final original = configuredRecord(
        name: 'Rencontre au port',
        source: triggerSource,
        conditions: [NarrativeEventCondition.fact('fact_a', true)],
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 7,
        order: 3,
        enabled: true,
      );
      final registry = registryWithRecords([original]);

      final result = duplicateNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        idGenerator: deterministicGenerator(eventIdB),
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.mutation, NarrativeEventAuthoringMutation.duplicate);
      expect(result.eventId, eventIdB);
      final clone = result.nextRecord!.draftOrNull!;
      expect(clone.id, eventIdB);
      expect(clone.name, 'Rencontre au port — copie');
      expect(clone.source, triggerSource);
      expect(clone.conditions, original.definitionOrNull!.conditions);
      expect(clone.sceneId, 'scene_a');
      expect(clone.reusePolicy, NarrativeEventReusePolicy.reusable);
      expect(clone.priority, 7);
      expect(clone.order, 4);
      expect(result.nextRecord!.enabledOrNull, isNull);
      expect(result.nextRegistry!.records, [original, result.nextRecord]);
    });

    test('unpublishes without losing configured fields or legacy claims', () {
      final original = configuredRecord(
        name: 'Rencontre au port',
        source: outcomeSource,
        conditions: [NarrativeEventCondition.fact('fact_a', false)],
        sceneId: 'scene_a',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: -2,
        order: 9,
        enabled: true,
      );
      final claim = authoringClaim();
      final registry = registryWithRecords(
        [original],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );

      final result = unpublishNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.mutation, NarrativeEventAuthoringMutation.unpublish);
      final draft = result.nextRecord!.draftOrNull!;
      expect(draft.id, eventIdA);
      expect(draft.name, 'Rencontre au port');
      expect(draft.source, outcomeSource);
      expect(draft.conditions, original.definitionOrNull!.conditions);
      expect(draft.sceneId, 'scene_a');
      expect(draft.reusePolicy, NarrativeEventReusePolicy.oneShot);
      expect(draft.priority, -2);
      expect(draft.order, 9);
      expect(result.nextRegistry!.mode, EventSystemMode.dualRead);
      expect(result.nextRegistry!.legacyClaims, [claim]);
      expect(result.impactPreview!.structuralUnpublish, isTrue);
    });

    test('protects deletion with canonical dependency consumers', () {
      final original = configuredRecord();
      final registry = registryWithRecords([original]);
      final owner = const NarrativeDependencyKey.scene('scene_consumer');
      final target = const NarrativeDependencyKey.eventV2(eventIdA);
      final dependencyIndex = NarrativeDependencyIndex(
        usages: [
          NarrativeDependencyUsage(
            target: target,
            owner: owner,
            path: 'scenes.scene_consumer.graph.nodes.condition.eventId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
            navigationIntent: NarrativeDependencyNavigationIntent.fromKey(
              owner,
            ),
          ),
        ],
      );

      final result = deleteNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        dependencyIndex: dependencyIndex,
      );

      expect(result.status, NarrativeEventAuthoringStatus.rejected);
      expect(result.rejectionCode, 'eventReferenced');
      expect(result.deletionPreview, isNotNull);
      expect(result.deletionPreview!.consumers, hasLength(1));
      expect(result.deletionPreview!.consumers.single.owner, owner);
      expect(result.deletionPreview!.canDelete, isFalse);
      expect(result.nextRegistry, isNull);
    });

    test('deletes exactly one unreferenced Event and remains undoable', () {
      final first = draftRecord(id: eventIdA, order: 2);
      final second = configuredRecord(id: eventIdB, order: 4);
      final registry = registryWithRecords([first, second]);

      final result = deleteNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        dependencyIndex: NarrativeDependencyIndex(),
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.mutation, NarrativeEventAuthoringMutation.delete);
      expect(result.eventId, eventIdA);
      expect(result.previousRecord, first);
      expect(result.nextRecord, isNull);
      expect(result.nextRegistry!.records, [second]);
      expect(result.deletionPreview!.canDelete, isTrue);
      expect(result.undoable, isTrue);
    });

    test('rejects missing lifecycle targets before mutating', () {
      final context = authoringContext();

      final results = [
        duplicateNarrativeEvent(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          idGenerator: deterministicGenerator(eventIdB),
        ),
        unpublishNarrativeEvent(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        ),
        deleteNarrativeEvent(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          dependencyIndex: NarrativeDependencyIndex(),
        ),
      ];

      expect(results.map((result) => result.rejectionCode),
          everyElement('eventMissing'));
    });
  });
}
