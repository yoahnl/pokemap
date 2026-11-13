import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_history.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_draft_fixtures.dart';

void main() {
  StoryDraft giveALine() {
    final draft = StoryDraft()
      ..load(StoryDraftKind.event, eventId(1), null)
      ..load(StoryDraftKind.scene, 'line', null)
      ..load(StoryDraftKind.dialogue, 'line', null);
    draft.group(() {
      draft
        ..put(StoryDraftKind.dialogue, dialogue('line'))
        ..put(StoryDraftKind.scene, scene('line'))
        ..put(StoryDraftKind.event, event(1));
    });
    return draft;
  }

  test('one step across three kinds is undone and redone as a whole', () {
    final draft = giveALine();
    expect(draft.touchedRefs, hasLength(3));

    draft.undo();

    expect(draft.touchedRefs, isEmpty);
    expect(draft.currentOf(StoryDraftKind.event, eventId(1)), isNull);
    expect(draft.currentOf(StoryDraftKind.scene, 'line'), isNull);
    expect(draft.currentOf(StoryDraftKind.dialogue, 'line'), isNull);
    expect(draft.canUndo, isFalse);
    expect(draft.canRedo, isTrue);

    draft.redo();

    expect(draft.currentOf(StoryDraftKind.event, eventId(1)), event(1));
    expect(draft.currentOf(StoryDraftKind.scene, 'line'), scene('line'));
    expect(draft.currentOf(StoryDraftKind.dialogue, 'line'), dialogue('line'));
    expect(draft.canRedo, isFalse);
  });

  test('several edits of one entry inside a step undo to where it started', () {
    final draft = StoryDraft()..load(StoryDraftKind.fact, 'met', fact('met'));
    draft.group(() {
      draft
        ..put(StoryDraftKind.fact, fact('met', 'First'))
        ..put(StoryDraftKind.fact, fact('met', 'Second'));
      expect(
        draft.currentOf(StoryDraftKind.fact, 'met'),
        fact('met', 'Second'),
      );
    });

    draft.undo();

    expect(draft.currentOf(StoryDraftKind.fact, 'met'), fact('met'));
    expect(draft.canUndo, isFalse);
  });

  test('a step that fails leaves no trace', () {
    final draft = giveALine();

    expect(
      () => draft.group(() {
        draft.put(StoryDraftKind.scene, scene('line', 'Renamed'));
        draft.put(StoryDraftKind.fact, fact('never-loaded'));
      }),
      throwsStateError,
    );

    expect(draft.currentOf(StoryDraftKind.scene, 'line'), scene('line'));
    draft.undo();
    expect(draft.touchedRefs, isEmpty);
    expect(draft.canUndo, isFalse);
  });

  test('a step that changes nothing is not recorded and keeps the redo', () {
    final draft = giveALine()..undo();

    draft.group(() {});
    draft.load(StoryDraftKind.fact, 'met', fact('met'));
    draft.put(StoryDraftKind.fact, fact('met'));
    draft.group(() {
      draft
        ..put(StoryDraftKind.fact, fact('met', 'Renamed'))
        ..put(StoryDraftKind.fact, fact('met'));
    });

    expect(draft.canUndo, isFalse);
    expect(draft.canRedo, isTrue);
  });

  test('a new edit clears the redo', () {
    final draft = giveALine()..undo();
    expect(draft.canRedo, isTrue);

    draft.put(StoryDraftKind.scene, scene('line', 'Another'));

    expect(draft.canRedo, isFalse);
    draft.redo();
    expect(
      draft.currentOf(StoryDraftKind.scene, 'line'),
      scene('line', 'Another'),
    );
    expect(draft.currentOf(StoryDraftKind.event, eventId(1)), isNull);
  });

  test('the history keeps the last eighty steps', () {
    final draft = StoryDraft()..load(StoryDraftKind.fact, 'met', fact('met'));
    for (var index = 1; index <= StoryDraftHistory.capacity + 5; index++) {
      draft.put(StoryDraftKind.fact, fact('met', 'Label $index'));
    }

    var undone = 0;
    while (draft.canUndo) {
      draft.undo();
      undone++;
    }

    expect(StoryDraftHistory.capacity, 80);
    expect(undone, 80);
    expect(draft.currentOf(StoryDraftKind.fact, 'met'), fact('met', 'Label 5'));
  });

  test('undo and redo with nothing to play change nothing', () {
    final draft = StoryDraft()
      ..undo()
      ..redo();

    expect(draft.touchedRefs, isEmpty);
    expect(draft.canUndo, isFalse);
    expect(draft.canRedo, isFalse);
  });

  test('the history cannot move while a step is being written', () {
    final draft = giveALine();

    expect(() => draft.group(draft.undo), throwsStateError);
    expect(draft.touchedRefs, hasLength(3));
  });

  test('a nested step joins the step that contains it', () {
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..load(StoryDraftKind.story, 'main', story('main'));
    draft.group(() {
      draft.put(StoryDraftKind.fact, fact('met', 'Renamed'));
      draft.group(() => draft.remove(StoryDraftKind.story, 'main'));
    });

    draft.undo();

    expect(draft.touchedRefs, isEmpty);
    expect(draft.canUndo, isFalse);
  });
}
