import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_workspace/application/story_history_scope.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';

void main() {
  test(
    'rank changes from a different source stay outside the selected scope',
    () async {
      final selected = storyRecord(
        4,
        source: NarrativeEventSourceRef.mapEnter('a'),
      );
      final fixture = await openStory(
        records: [
          storyRecord(1),
          storyRecord(2, order: 1),
          storyRecord(3, order: 2),
          selected,
        ],
      );
      await fixture.story.prepare();
      fixture.story.behaviours.draft.load(
        StoryDraftKind.event,
        selected.id,
        selected,
      );
      final scope = StoryHistoryScope([
        (kind: StoryDraftKind.event, id: selected.id),
      ]);
      fixture.story.moveCase(
        fixture.story.casesOf(storyElement(fixture)).groups.single,
        1,
        0,
      );
      expect(fixture.story.canStepScope(scope, redo: false), isFalse);
    },
  );

  test('a batch of renames is not treated as a case reorder', () async {
    final fixture = await openStory(
      records: [storyRecord(1), storyRecord(2, order: 1)],
    );
    await fixture.story.prepare();
    final scope = StoryHistoryScope([
      (kind: StoryDraftKind.event, id: storyEventId(1)),
    ]);
    fixture.story.behaviours.draft.group(() {
      fixture.story.renameBehaviour(
        storyCurrent(fixture, storyEventId(1)),
        'Premier renommé',
      );
      fixture.story.renameBehaviour(
        storyCurrent(fixture, storyEventId(2)),
        'Autre renommé',
      );
    });
    expect(fixture.story.canStepScope(scope, redo: false), isFalse);
  });
  test(
    'scoped history admits an atomic reorder of cases from the selected source',
    () async {
      final fixture = await openStory(
        records: [
          storyRecord(1),
          storyRecord(2, order: 1),
          storyRecord(3, order: 2, enabled: false),
          storyRecord(4, order: 5),
        ],
      );
      await fixture.story.prepare();
      final scope = StoryHistoryScope([
        (kind: StoryDraftKind.event, id: storyEventId(1)),
      ]);
      final group = fixture.story.casesOf(storyElement(fixture)).groups.single;
      expect(fixture.story.moveCase(group, 1, 0), isTrue);
      expect(fixture.story.canStepScope(scope, redo: false), isTrue);
      fixture.story.undo();
      expect(fixture.story.canStepScope(scope, redo: true), isTrue);
      fixture.story.redo();
      expect(
        fixture.story
            .casesOf(storyElement(fixture))
            .groups
            .single
            .records
            .first
            .id,
        storyEventId(2),
      );
    },
  );

  test(
    'a different case rename remains outside the selected history scope',
    () async {
      final fixture = await openStory(
        records: [storyRecord(1), storyRecord(2, order: 1)],
      );
      await fixture.story.prepare();
      final scope = StoryHistoryScope([
        (kind: StoryDraftKind.event, id: storyEventId(1)),
      ]);
      expect(
        fixture.story.renameBehaviour(
          storyCurrent(fixture, storyEventId(2)),
          'Autre cas',
        ),
        isTrue,
      );
      expect(fixture.story.canStepScope(scope, redo: false), isFalse);
    },
  );
}
