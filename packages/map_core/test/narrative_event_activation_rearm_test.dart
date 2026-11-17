import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  test('activation accepts a valid outcome and rejects a stale revision first', () {
    final json = configuredRecord().toJson();
    (json['definition'] as Map<String, Object?>)['resetPolicy'] =
        NarrativeEventResetPolicy.onOutcomeReceived(outcomeRef).toJson();
    final record = NarrativeEventRecord.fromJson(json);
    final registry = registryWithRecords([record]);
    final context = configuredAuthoringContext(registry: registry);
    final accepted = activateNarrativeEvent(context: context,
      expectedRevision: authoringRevision, eventId: eventIdA);
    expect(accepted.status, NarrativeEventAuthoringStatus.applied);
    expect(accepted.nextRecord!.definitionOrNull!.resetPolicy, record.definitionOrNull!.resetPolicy);
    final stale = activateNarrativeEvent(context: context,
      expectedRevision: 'obsolete', eventId: eventIdA);
    expect(stale.status, NarrativeEventAuthoringStatus.staleRevision);
    expect(registry.records.single, record);
  });
  test(
    'activation rejects an unavailable rearm outcome and preserves the record',
    () {
      final json = configuredRecord().toJson();
      (json['definition'] as Map<String, Object?>)['resetPolicy'] =
          NarrativeEventResetPolicy.onOutcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_a',
              outcomeId: 'missing',
            ),
          ).toJson();
      final record = NarrativeEventRecord.fromJson(json);
      final registry = registryWithRecords([record]);
      final result = activateNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(result.rejectionCode, 'resetOutcomeMissing');
      expect(result.status, NarrativeEventAuthoringStatus.rejected);
      expect(result.nextRecord, record);
      expect(registry.records.single, record);
    },
  );
}
