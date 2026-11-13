import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_draft_fixtures.dart';

void main() {
  final samples = <(Object, Object, Object)>[
    (event(1), event(1, 'Mine'), event(1, 'Elsewhere')),
    (scene('scene'), scene('scene', 'Mine'), scene('scene', 'Elsewhere')),
    (dialogue('talk'), dialogue('talk', 'Mine'), dialogue('talk', 'Elsewhere')),
    (fact('met'), fact('met', 'Mine'), fact('met', 'Elsewhere')),
    (story('main'), story('main', 'Mine'), story('main', 'Elsewhere')),
    (rule('gate'), rule('gate', 'Mine'), rule('gate', 'Elsewhere')),
  ];

  for (final (saved, edited, elsewhere) in samples) {
    final kind = StoryDraftKind.of(saved);
    final id = kind.idOf(saved);

    group(kind.name, () {
      test('an edit is a change against the value it was loaded from', () {
        final store = SavedStore([saved]);
        final draft = StoryDraft()..load(kind, id, saved);
        expect(draft.dirty(store), isFalse);
        expect(draft.touched(kind), isEmpty);

        draft.put(kind, edited);

        expect(draft.currentOf(kind, id), edited);
        expect(draft.baseOf(kind, id), saved);
        expect(draft.touched(kind), [id]);
        expect(draft.dirty(store), isTrue);
        expect(draft.dirty(store, kind: kind), isTrue);
        expect(draft.changes(store), [
          kind.entry(id, base: saved, current: edited),
        ]);
        expect(draft.conflicts(store), isEmpty);
        for (final other in StoryDraftKind.values) {
          if (other == kind) continue;
          expect(draft.dirty(store, kind: other), isFalse);
          expect(draft.changes(store, kind: other), isEmpty);
        }
      });

      test('a creation has no base and a deletion has no current', () {
        final store = SavedStore();
        final draft = StoryDraft()
          ..load(kind, id, null)
          ..put(kind, saved);
        expect(draft.changes(store).single.creation, isTrue);
        expect(draft.changes(store).single.base, isNull);

        store.save(saved);
        final deleting = StoryDraft()
          ..load(kind, id, saved)
          ..remove(kind, id);
        final deletion = deleting.changes(store).single;
        expect(deletion.deletion, isTrue);
        expect(deletion.base, saved);
        expect(deleting.currentOf(kind, id), isNull);
        expect(deleting.isLoaded(kind, id), isTrue);
      });

      test('a saved value that moved away from the base is a conflict', () {
        final draft = StoryDraft()
          ..load(kind, id, saved)
          ..put(kind, edited);
        final moved = SavedStore([elsewhere]);

        expect(draft.changes(moved), isEmpty);
        expect(draft.conflicts(moved), [(kind: kind, id: id)]);
        expect(draft.dirty(moved), isTrue);
        expect(draft.currentOf(kind, id), edited);

        final gone = SavedStore();
        expect(draft.changes(gone), isEmpty);
        expect(draft.conflicts(gone, kind: kind), [(kind: kind, id: id)]);
      });

      test('an entry that was never loaded cannot be edited', () {
        final draft = StoryDraft();

        expect(() => draft.put(kind, edited), throwsStateError);
        expect(() => draft.remove(kind, id), throwsStateError);
        expect(draft.isLoaded(kind, id), isFalse);
        expect(draft.touched(kind), isEmpty);
        expect(draft.canUndo, isFalse);
      });

      test('putting the base back leaves nothing to save', () {
        final store = SavedStore([saved]);
        final draft = StoryDraft()
          ..load(kind, id, saved)
          ..put(kind, edited)
          ..put(kind, saved);

        expect(draft.touched(kind), isEmpty);
        expect(draft.dirty(store), isFalse);
        expect(draft.entryOf(kind, id), isNull);
      });
    });
  }

  test('a value of another kind is refused', () {
    final draft = StoryDraft()..load(StoryDraftKind.scene, 'scene', null);

    expect(
      () => (StoryDraftKind.scene as StoryDraftKind<Object>).idOf(fact('met')),
      throwsArgumentError,
    );
    expect(
      () => draft.load(StoryDraftKind.scene, 'other', scene('scene')),
      throwsArgumentError,
    );
  });

  test('an untouched entry keeps following what is saved', () {
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Mine'))
      ..undo();
    final outside = SavedStore([fact('met', 'Elsewhere')]);

    expect(draft.dirty(outside), isFalse);
    expect(draft.conflicts(outside), isEmpty);
    expect(
      draft.effective(StoryDraftKind.fact, 'met', outside),
      fact('met', 'Elsewhere'),
    );
    expect(
      draft.load(StoryDraftKind.fact, 'met', fact('met', 'Elsewhere')),
      isTrue,
    );
    draft.put(StoryDraftKind.fact, fact('met', 'Mine again'));
    expect(draft.changes(outside).single.base, fact('met', 'Elsewhere'));
  });

  test('loading again never replaces the base of a pending edit', () {
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Mine'));

    expect(
      draft.load(StoryDraftKind.fact, 'met', fact('met', 'Elsewhere')),
      isFalse,
    );
    expect(draft.baseOf(StoryDraftKind.fact, 'met'), fact('met'));
    expect(draft.conflicts(SavedStore([fact('met', 'Elsewhere')])), [
      (kind: StoryDraftKind.fact, id: 'met'),
    ]);
  });

  test('checking the draft only reads the entries it touched', () {
    final store = SavedStore([
      for (var index = 0; index < 500; index++) fact('fact-$index'),
    ]);
    final draft = StoryDraft();
    for (var index = 0; index < 500; index++) {
      draft.load(StoryDraftKind.fact, 'fact-$index', fact('fact-$index'));
    }
    draft
      ..put(StoryDraftKind.fact, fact('fact-7', 'Mine'))
      ..put(StoryDraftKind.fact, fact('fact-9', 'Mine'));
    store.reads = 0;

    draft.changes(store);

    expect(store.reads, 2);
  });
}
