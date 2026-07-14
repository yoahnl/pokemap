import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('NarrativeEventIdGenerator retries collisions and caps attempts', () {
    const firstId = 'evt_019abcde-0000-7000-8000-000000000001';
    const secondId = 'evt_019abcde-0000-7000-8000-000000000002';
    final existing = NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: firstId,
        name: 'Existing',
        conditions: const [],
        priority: 0,
        order: 0,
      ),
    );
    var attempt = 0;
    final generator = NarrativeEventIdGenerator(
      rawUuidFactory: () => (attempt++ == 0 ? firstId : secondId).substring(4),
    );

    expect(generator.generate(existingRecords: [existing]), secondId);

    final exhausted = NarrativeEventIdGenerator(
      rawUuidFactory: () => firstId.substring(4),
    );
    expect(
      () => exhausted.generate(existingRecords: [existing]),
      throwsStateError,
    );
  });
}
