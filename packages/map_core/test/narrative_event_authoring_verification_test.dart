import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('NS-EVENT-V2 Phase E authoring result verification', () {
    test('accepts a result replayed from its source-first context', () {
      final context = authoringContext();
      final result = createNarrativeEventDraft(
        context: context,
        expectedRevision: authoringRevision,
        name: 'Verified draft',
        initialSource: mapSource,
        idGenerator: NarrativeEventIdGenerator(
          rawUuidFactory: () => eventIdA.substring(4),
        ),
      );

      expect(
        verifyNarrativeEventAuthoringResult(context: context, result: result),
        isNull,
      );
    });

    test('rejects a forged activation that changes validated references', () {
      final previousRecord = configuredRecord(id: eventIdA);
      final definition = previousRecord.definitionOrNull!;
      final previous = registryWithRecords([previousRecord]);
      final forgedRecord = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: definition.id,
          name: definition.name,
          source: NarrativeEventSourceRef.mapEnter('missing_map'),
          conditions: definition.conditions,
          sceneId: 'missing_scene',
          reusePolicy: definition.reusePolicy,
          priority: definition.priority,
          order: definition.order,
        ),
        enabled: true,
      );
      final forged = NarrativeEventAuthoringResult.applied(
        mutation: NarrativeEventAuthoringMutation.activate,
        previousRegistry: previous,
        nextRegistry: registryWithRecords([forgedRecord]),
        previousRecord: previousRecord,
        nextRecord: forgedRecord,
        expectedRevision: authoringRevision,
      );
      final context = configuredAuthoringContext(registry: previous);

      final issue = verifyNarrativeEventAuthoringResult(
        context: context,
        result: forged,
      );

      expect(issue?.code, 'unverifiedAuthoringResult');
    });

    test('rejects untruthful multi-record metadata', () {
      final context = authoringContext();
      final first = draftRecord(id: eventIdA, name: 'First');
      final second = draftRecord(id: eventIdB, name: 'Second');
      final forged = NarrativeEventAuthoringResult.applied(
        mutation: NarrativeEventAuthoringMutation.createDraft,
        previousRegistry: null,
        nextRegistry: registryWithRecords([first, second]),
        previousRecord: null,
        nextRecord: first,
        expectedRevision: authoringRevision,
      );

      final issue = verifyNarrativeEventAuthoringResult(
        context: context,
        result: forged,
      );

      expect(issue?.code, 'unverifiedAuthoringResult');
    });
  });
}
