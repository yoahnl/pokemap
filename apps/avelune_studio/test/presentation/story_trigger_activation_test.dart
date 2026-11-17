import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';

void main() {
  test('an incomplete trigger stays in the shared draft when activation is refused', () async {
    final fixture = await openStory();
    final story = fixture.story;
    await story.prepare();
    expect(story.addBehaviour(storyElement(fixture)), isTrue);
    final draft = story.behaviours
        .registry(fixture.maps.project!)!
        .records
        .single;
    expect(draft.enabledOrNull, isNot(true));
    expect(draft.sceneId, isNull);
    final before = draft.toJson();
    expect(story.setActive(draft, true), isFalse);
    expect(
      story.behaviours.registry(fixture.maps.project!)!.records.single.toJson(),
      before,
    );
    expect(story.dirty, isTrue);
    expect(fixture.ports.calls, isEmpty);
    expect(fixture.maps.project!.eventRegistry!.records, isEmpty);
  });

  test(
    'missing scene and missing rearm outcome refuse activation without loss',
    () async {
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene-plain',
        outcomeId: 'missing',
      );
      for (final record in [
        storyRecord(1, sceneId: 'missing', enabled: false),
        storyRecord(
          1,
          reset: NarrativeEventResetPolicy.onOutcomeReceived(outcome),
          enabled: false,
        ),
      ]) {
        final fixture = await openStory(records: [record]);
        await fixture.story.prepare();
        expect(fixture.story.setActive(record, true), isFalse);
        expect(storyCurrent(fixture, record.id), record);
        expect(fixture.story.dirty, isFalse);
        expect(fixture.ports.calls, isEmpty);
      }
    },
  );
}
