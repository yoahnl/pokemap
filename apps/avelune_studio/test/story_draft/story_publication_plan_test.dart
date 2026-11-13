import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_plan.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_draft_fixtures.dart';

void main() {
  int rank(List<StoryDraftKind<Object>> order, StoryDraftKind<Object> kind) =>
      order.indexOf(kind);

  test('what is referenced is written before what references it', () {
    final order = storyPublicationOrder(deletion: false);

    expect(order.toSet(), StoryDraftKind.values.toSet());
    expect(order, hasLength(StoryDraftKind.values.length));
    for (final (dependent, dependency) in const [
      (StoryDraftKind.dialogue, StoryDraftKind.fact),
      (StoryDraftKind.scene, StoryDraftKind.dialogue),
      (StoryDraftKind.scene, StoryDraftKind.fact),
      (StoryDraftKind.story, StoryDraftKind.scene),
      (StoryDraftKind.event, StoryDraftKind.scene),
      (StoryDraftKind.event, StoryDraftKind.story),
      (StoryDraftKind.worldRule, StoryDraftKind.event),
    ]) {
      expect(
        rank(order, dependency),
        lessThan(rank(order, dependent)),
        reason: '${dependency.name} before ${dependent.name}',
      );
    }
  });

  test('what references is deleted before what it references', () {
    final order = storyPublicationOrder(deletion: true);

    expect(order, storyPublicationOrder(deletion: false).reversed);
    expect(
      rank(order, StoryDraftKind.event),
      lessThan(rank(order, StoryDraftKind.scene)),
    );
    expect(
      rank(order, StoryDraftKind.scene),
      lessThan(rank(order, StoryDraftKind.dialogue)),
    );
    expect(
      rank(order, StoryDraftKind.worldRule),
      lessThan(rank(order, StoryDraftKind.event)),
    );
  });

  test('a mixed plan writes first, then deletes in the reverse order', () {
    final changes = <StoryDraftEntry<Object>>[
      StoryDraftKind.worldRule.entry('door', current: rule('door')),
      StoryDraftKind.event.entry(eventId(1), base: event(1)),
      StoryDraftKind.event.entry(eventId(2), current: event(2)),
      StoryDraftKind.scene.entry('old', base: scene('old')),
      StoryDraftKind.scene.entry('line', current: scene('line')),
      StoryDraftKind.dialogue.entry('old', base: dialogue('old')),
      StoryDraftKind.dialogue.entry('line', current: dialogue('line')),
      StoryDraftKind.story.entry(
        'main',
        base: story('main'),
        current: story('main', 'Renamed'),
      ),
      StoryDraftKind.fact.entry('met', current: fact('met')),
      StoryDraftKind.fact.entry('won', base: fact('won')),
      StoryDraftKind.worldRule.entry('gate', base: rule('gate')),
    ];

    final plan = planStoryPublication(changes);

    expect(
      [
        for (final step in plan)
          '${step.deletion ? 'delete' : 'write'} ${step.kind.name} '
              '${[for (final entry in step.entries) entry.id].join(',')}',
      ],
      [
        'write fact met',
        'write dialogue line',
        'write scene line',
        'write story main',
        'write event ${eventId(2)}',
        'write worldRule door',
        'delete worldRule gate',
        'delete event ${eventId(1)}',
        'delete scene old',
        'delete dialogue old',
        'delete fact won',
      ],
    );
    expect([
      for (final step in plan) ...step.entries,
    ], unorderedEquals(changes));
  });

  test('an entry that changes nothing is not planned', () {
    expect(
      planStoryPublication([
        StoryDraftKind.fact.entry(
          'met',
          base: fact('met'),
          current: fact('met'),
        ),
        StoryDraftKind.fact.entry('none'),
      ]),
      isEmpty,
    );
  });

  test('written events are batched and every other step holds one entry', () {
    final count = EventBatchPort.maxRecords * 2 + 3;
    final plan = planStoryPublication([
      for (var index = 1; index <= count; index++)
        StoryDraftKind.event.entry(eventId(index), current: event(index)),
      StoryDraftKind.event.entry(eventId(900), base: event(900)),
      StoryDraftKind.event.entry(eventId(901), base: event(901)),
      StoryDraftKind.scene.entry('one', current: scene('one')),
      StoryDraftKind.scene.entry('two', current: scene('two')),
    ]);

    expect(EventBatchPort.maxRecords, 128);
    expect(
      [
        for (final step in plan)
          (step.kind, step.deletion, step.entries.length),
      ],
      [
        (StoryDraftKind.scene, false, 1),
        (StoryDraftKind.scene, false, 1),
        (StoryDraftKind.event, false, 128),
        (StoryDraftKind.event, false, 128),
        (StoryDraftKind.event, false, 3),
        (StoryDraftKind.event, true, 1),
        (StoryDraftKind.event, true, 1),
      ],
    );
    expect(plan[2].entries.first.id, eventId(1));
    expect(plan[3].entries.first.id, eventId(129));
    expect(plan[4].entries.last.id, eventId(count));
  });

  test('a failed step splits the plan into saved and remaining', () {
    final plan = planStoryPublication([
      StoryDraftKind.dialogue.entry('line', current: dialogue('line')),
      StoryDraftKind.scene.entry('line', current: scene('line')),
      StoryDraftKind.event.entry(eventId(1), current: event(1)),
    ]);

    final progress = storyPublicationProgress(plan, succeeded: 1);

    expect(progress.saved, [plan[0].entries.single]);
    expect(progress.failed, plan[1]);
    expect(progress.remaining, [
      plan[1].entries.single,
      plan[2].entries.single,
    ]);
    expect(progress.complete, isFalse);

    final done = storyPublicationProgress(plan, succeeded: plan.length);
    expect(done.complete, isTrue);
    expect(done.failed, isNull);
    expect(done.remaining, isEmpty);
    expect(done.saved, hasLength(3));

    expect(storyPublicationProgress(plan, succeeded: 0).saved, isEmpty);
    expect(
      () => storyPublicationProgress(plan, succeeded: plan.length + 1),
      throwsRangeError,
    );
    expect(
      () => storyPublicationProgress(plan, succeeded: -1),
      throwsRangeError,
    );
  });

  test('after a partial failure the draft keeps exactly what remains', () {
    final store = SavedStore([scene('old'), dialogue('old')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.dialogue, 'line', null)
      ..load(StoryDraftKind.scene, 'line', null)
      ..load(StoryDraftKind.event, eventId(1), null)
      ..load(StoryDraftKind.scene, 'old', scene('old'))
      ..load(StoryDraftKind.dialogue, 'old', dialogue('old'));
    draft.group(() {
      draft
        ..put(StoryDraftKind.event, event(1))
        ..put(StoryDraftKind.scene, scene('line'))
        ..put(StoryDraftKind.dialogue, dialogue('line'))
        ..remove(StoryDraftKind.scene, 'old')
        ..remove(StoryDraftKind.dialogue, 'old');
    });
    final plan = planStoryPublication(draft.changes(store));
    expect(plan, hasLength(5));

    final progress = storyPublicationProgress(plan, succeeded: 2);
    progress.saved.forEach(store.publish);
    draft.acknowledge(progress.saved, store);

    expect(draft.changes(store), unorderedEquals(progress.remaining));
    expect(draft.conflicts(store), isEmpty);
    expect(draft.dirty(store), isTrue);
    expect(planStoryPublication(draft.changes(store)), plan.sublist(2));

    draft.undo();
    expect(
      [
        for (final change in draft.changes(store))
          (change.ref, change.deletion),
      ],
      unorderedEquals([
        ((kind: StoryDraftKind.dialogue, id: 'line'), true),
        ((kind: StoryDraftKind.scene, id: 'line'), true),
      ]),
    );
  });
}
