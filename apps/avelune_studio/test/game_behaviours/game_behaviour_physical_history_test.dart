import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_workspace/application/story_history_scope.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/map_builder_story_support.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'restoring map history does not turn redo into a new mutation',
    () async {
      final fixture = await openStory(records: [storyRecord(1)]);
      final story = fixture.story;
      fixture.tick.addListener(story.reconcile);
      final record = storyCurrent(fixture, storyEventId(1));
      expect(story.renameBehaviour(record, 'Règle R'), isTrue);
      expect(story.rename(storyElement(fixture), 'Porteur M'), isTrue);
      expect(story.rename(storyElement(fixture), 'Porteur M2'), isTrue);
      story.undo();
      story.undo();
      story.undo();
      expect(storyCurrent(fixture, record.id), record);
      story.redo();
      story.redo();
      expect(story.canRedo, isTrue);
      story.redo();
      expect(storyCurrent(fixture, record.id).name, 'Règle R');
      expect(story.entityOf(storyElement(fixture))!.name, 'Porteur M2');
      expect(story.canRedo, isFalse);
      story.undo();
      story.undo();
      story.undo();
      expect(storyCurrent(fixture, record.id), record);
      expect(story.entityOf(storyElement(fixture))!.name, 'Luth');
      expect(story.canUndo, isFalse);
    },
  );

  test('a refused physical undo keeps the narrative barrier intact', () async {
    final fixture = await openStory(records: [storyRecord(1)]);
    final story = fixture.story;
    final record = storyCurrent(fixture, storyEventId(1));
    expect(story.renameBehaviour(record, 'Règle R'), isTrue);
    expect(story.rename(storyElement(fixture), 'Porteur M'), isTrue);
    fixture.maps.active!.saving = true;
    story.undo();
    final scope = StoryHistoryScope({
      (kind: StoryDraftKind.event, id: record.id),
    });
    expect(story.canStepScope(scope, redo: false), isFalse);
    expect(story.entityOf(storyElement(fixture))!.name, 'Porteur M');
    fixture.maps.active!.saving = false;
    story.undo();
    expect(story.canStepScope(scope, redo: false), isTrue);
  });

  test(
    'a physical transaction on B cannot be skipped from Histoire on A',
    () async {
      final fixture = await openStory(records: [storyRecord(1)]);
      final story = fixture.story;
      fixture.maps.addListener(story.reconcile);
      final record = storyCurrent(fixture, storyEventId(1));
      expect(story.renameBehaviour(record, 'Règle A'), isTrue);
      await fixture.maps.activate(workspaceEntries.last);
      final b = fixture.maps.active!;
      b.commit(b.current.copyWith(name: 'Construction B'));
      fixture.maps.notify();
      await fixture.maps.activate(workspaceEntries.first);
      final scope = StoryHistoryScope({
        (kind: StoryDraftKind.event, id: record.id),
      });
      expect(story.canStepScope(scope, redo: false), isFalse);
      expect(storyCurrent(fixture, record.id).name, 'Règle A');
      await fixture.maps.activate(workspaceEntries.last);
      story.undo();
      await fixture.maps.activate(workspaceEntries.first);
      expect(story.canStepScope(scope, redo: false), isTrue);
    },
  );
}
