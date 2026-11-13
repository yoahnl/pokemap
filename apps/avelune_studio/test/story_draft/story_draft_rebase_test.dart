import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_draft_fixtures.dart';

void main() {
  test('a saved edit stops being dirty and can still be undone', () {
    final store = SavedStore([fact('met')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Renamed'));
    draft.changes(store).forEach(store.publish);

    draft.rebase(store);

    expect(draft.dirty(store), isFalse);
    expect(draft.touchedRefs, isEmpty);
    expect(draft.baseOf(StoryDraftKind.fact, 'met'), fact('met', 'Renamed'));
    expect(draft.canUndo, isTrue);

    draft.undo();
    expect(draft.changes(store), [
      StoryDraftKind.fact.entry(
        'met',
        base: fact('met', 'Renamed'),
        current: fact('met'),
      ),
    ]);

    draft.redo();
    expect(draft.dirty(store), isFalse);
  });

  test('rebasing only some entries leaves the others pending', () {
    final store = SavedStore([fact('met'), scene('intro')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..load(StoryDraftKind.scene, 'intro', scene('intro'))
      ..put(StoryDraftKind.fact, fact('met', 'Renamed'))
      ..put(StoryDraftKind.scene, scene('intro', 'Renamed'));
    draft.changes(store).forEach(store.publish);

    draft.rebase(store, only: {(kind: StoryDraftKind.fact, id: 'met')});

    expect(draft.touchedRefs, [(kind: StoryDraftKind.scene, id: 'intro')]);
    expect(draft.dirty(store), isFalse);
  });

  test('a conflict survives a rebase', () {
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Mine'));
    final outside = SavedStore([fact('met', 'Elsewhere')]);

    draft.rebase(outside);

    expect(draft.conflicts(outside), [(kind: StoryDraftKind.fact, id: 'met')]);
    expect(draft.currentOf(StoryDraftKind.fact, 'met'), fact('met', 'Mine'));
  });

  test('an edit made while saving stays a clean change on the new base', () {
    final store = SavedStore([fact('met')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Sent'));
    final sent = draft.changes(store);
    draft.put(StoryDraftKind.fact, fact('met', 'Typed later'));
    sent.forEach(store.publish);

    draft.acknowledge(sent, store);

    expect(draft.conflicts(store), isEmpty);
    expect(draft.changes(store), [
      StoryDraftKind.fact.entry(
        'met',
        base: fact('met', 'Sent'),
        current: fact('met', 'Typed later'),
      ),
    ]);

    draft.undo();
    expect(draft.dirty(store), isFalse);
    draft.undo();
    expect(draft.changes(store).single.current, fact('met'));
  });

  test('an undo made while saving becomes a change back to the old value', () {
    final store = SavedStore([fact('met')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Sent'));
    final sent = draft.changes(store);
    draft.undo();
    sent.forEach(store.publish);

    draft.acknowledge(sent, store);

    expect(draft.conflicts(store), isEmpty);
    expect(draft.changes(store), [
      StoryDraftKind.fact.entry(
        'met',
        base: fact('met', 'Sent'),
        current: fact('met'),
      ),
    ]);
    draft.redo();
    expect(draft.dirty(store), isFalse);
  });

  test('a creation edited while saving becomes an update', () {
    final store = SavedStore();
    final draft = StoryDraft()
      ..load(StoryDraftKind.scene, 'line', null)
      ..put(StoryDraftKind.scene, scene('line'));
    final sent = draft.changes(store);
    draft.put(StoryDraftKind.scene, scene('line', 'Renamed'));
    sent.forEach(store.publish);

    draft.acknowledge(sent, store);

    final change = draft.changes(store).single;
    expect(change.creation, isFalse);
    expect(change.base, scene('line'));
    expect(change.current, scene('line', 'Renamed'));
  });

  test('a publication that did not land is not acknowledged', () {
    final store = SavedStore([fact('met')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.fact, 'met', fact('met'))
      ..put(StoryDraftKind.fact, fact('met', 'Sent'));
    final sent = draft.changes(store);

    draft.acknowledge(sent, store);

    expect(draft.changes(store), sent);
    expect(draft.baseOf(StoryDraftKind.fact, 'met'), fact('met'));
  });

  test('acknowledging a deletion forgets the entry until it is recreated', () {
    final store = SavedStore([dialogue('talk')]);
    final draft = StoryDraft()
      ..load(StoryDraftKind.dialogue, 'talk', dialogue('talk'))
      ..remove(StoryDraftKind.dialogue, 'talk');
    final sent = draft.changes(store);
    sent.forEach(store.publish);

    draft.acknowledge(sent, store);

    expect(draft.dirty(store), isFalse);
    expect(draft.baseOf(StoryDraftKind.dialogue, 'talk'), isNull);
    draft.undo();
    expect(draft.changes(store).single.creation, isTrue);
  });
}
