import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';
import 'story_trigger_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

void _expectOrder(WidgetTester tester, List<int> indexes) {
  for (var index = 1; index < indexes.length; index++) {
    expect(
      tester
          .getTopLeft(
            _key('map-story-case-${storyEventId(indexes[index - 1])}'),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(_key('map-story-case-${storyEventId(indexes[index])}'))
            .dy,
      ),
    );
  }
}

void main() {
  testWidgets('dragging a case rewrites only the records whose rank moved', (
    tester,
  ) async {
    final fixture = await openStory(
      records: [
        for (var index = 1; index <= 3; index++)
          storyRecord(index, order: index - 1),
      ],
    );
    await pumpStoryInspector(tester, fixture);
    fixture.story.openTab(MapStoryTab.behaviour);
    await tester.pump();
    _expectOrder(tester, [1, 2, 3]);
    final list = tester.widget<ReorderableListView>(
      find.descendant(
        of: _key('map-story-cases-entityInteract'),
        matching: find.byType(ReorderableListView),
      ),
    );
    expect(_key('map-story-case-drag-${storyEventId(3)}'), findsOneWidget);

    list.onReorderItem!(2, 0);
    await tester.pump();

    expect(
      [...fixture.story.behaviours.draft.touched(StoryDraftKind.event)]..sort(),
      [storyEventId(1), storyEventId(2)],
    );
    _expectOrder(tester, [3, 1, 2]);
    for (var index = 1; index <= 3; index++) {
      expect(
        storyCurrent(fixture, storyEventId(index)).enabledOrNull,
        isTrue,
        reason: fixture.story.error,
      );
    }

    fixture.story.undo();
    await tester.pump();
    _expectOrder(tester, [1, 2, 3]);
    expect(fixture.story.behaviours.draft.touchedRefs, isEmpty);
  });

  testWidgets('a case behind one that always plays is flagged', (tester) async {
    final fixture = await openStory(
      records: [
        storyRecord(1, reuse: NarrativeEventReusePolicy.reusable),
        storyRecord(2, order: 1),
      ],
    );
    await pumpStoryInspector(tester, fixture);
    fixture.story.openTab(MapStoryTab.behaviour);
    await tester.pump();
    expect(_key('map-story-case-shadow-${storyEventId(2)}'), findsOneWidget);
    expect(
      find.text('Ne peut jamais se jouer : « Cas 1 » passe toujours avant.'),
      findsOneWidget,
    );
    expect(_key('map-story-case-shadow-${storyEventId(1)}'), findsNothing);

    fixture.story.moveCase(
      fixture.story.casesOf(storyElement(fixture)).groups.single,
      1,
      0,
    );
    await tester.pump();
    expect(_key('map-story-case-shadow-${storyEventId(2)}'), findsNothing);
    expect(_key('map-story-case-shadow-${storyEventId(1)}'), findsNothing);
  });

  testWidgets('"Après" keeps a rearm after an outcome until it is replaced', (
    tester,
  ) async {
    final outcome = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene-plain',
      outcomeId: 'won',
    );
    final fixture = await openStory(
      records: [
        storyRecord(
          1,
          enabled: false,
          reset: NarrativeEventResetPolicy.onOutcomeReceived(outcome),
        ),
      ],
    );
    await pumpTrigger(tester, fixture);
    StudioSelect after() =>
        tester.widget<StudioSelect>(_key('map-story-after'));

    expect(after().value, 'onceUntilOutcome');
    expect(find.text('Une fois, puis après un résultat'), findsOneWidget);

    after().onChanged!('once');
    await tester.pump();
    final kept = storyCurrent(fixture, storyEventId(1));
    expect(
      kept.resetPolicy,
      NarrativeEventResetPolicy.onOutcomeReceived(outcome),
    );
    expect(fixture.story.behaviours.draft.touchedRefs, isEmpty);
    expect(find.textContaining('se réarme après un résultat'), findsOneWidget);
    expect(_key('map-story-after-replace'), findsOneWidget);

    await tester.tap(_key('map-story-after-replace'));
    await tester.pump();
    final replaced = storyCurrent(fixture, storyEventId(1));
    expect(replaced.resetPolicy, const NarrativeEventResetPolicy.never());
    expect(replaced.reusePolicy, NarrativeEventReusePolicy.oneShot);
    expect(_key('map-story-after-replace'), findsNothing);
  });

  testWidgets('"Quand" offers only the triggers the validation accepts', (
    tester,
  ) async {
    final fixture = await openStory(
      records: [storyRecord(1)],
      entities: [storyLuth.copyWith(blocksMovement: false)],
    );
    await pumpTrigger(tester, fixture);

    final options = tester
        .widget<StudioSelect>(_key('map-story-when'))
        .options
        .keys;
    expect(options, contains('entityInteract'));
    expect(options, isNot(contains('entityBump')));
    expect(
      fixture.story.triggerKinds(storyElement(fixture)),
      isNot(contains(NarrativeEventSourceKind.entityBump)),
    );
  });
}
