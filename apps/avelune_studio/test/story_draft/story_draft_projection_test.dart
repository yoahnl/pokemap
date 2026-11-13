import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_manifest_reader.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_draft_fixtures.dart';

void main() {
  final saved = manifest(
    events: [event(1), event(2)],
    scenes: [scene('intro'), scene('outro')],
    dialogues: [dialogue('talk')],
    facts: [fact('met'), fact('won')],
    stories: [story('main')],
    rules: [rule('gate')],
  );

  StoryDraft loaded() => StoryDraft()
    ..load(StoryDraftKind.event, eventId(1), event(1))
    ..load(StoryDraftKind.event, eventId(2), event(2))
    ..load(StoryDraftKind.event, eventId(3), null)
    ..load(StoryDraftKind.scene, 'intro', scene('intro'))
    ..load(StoryDraftKind.scene, 'outro', scene('outro'))
    ..load(StoryDraftKind.scene, 'line', null)
    ..load(StoryDraftKind.dialogue, 'talk', dialogue('talk'))
    ..load(StoryDraftKind.dialogue, 'line', null)
    ..load(StoryDraftKind.fact, 'met', fact('met'))
    ..load(StoryDraftKind.fact, 'won', fact('won'))
    ..load(StoryDraftKind.story, 'main', story('main'))
    ..load(StoryDraftKind.story, 'side', null)
    ..load(StoryDraftKind.worldRule, 'gate', rule('gate'))
    ..load(StoryDraftKind.worldRule, 'door', null);

  test('a draft without edits projects the saved manifest itself', () {
    final draft = loaded();

    expect(draft.project(saved), same(saved));
    expect(draft.eventRegistry(saved.eventRegistry), same(saved.eventRegistry));
  });

  test('the projection shows updates, creations and deletions per kind', () {
    final draft = loaded()
      ..put(StoryDraftKind.event, event(1, 'Renamed'))
      ..remove(StoryDraftKind.event, eventId(2))
      ..put(StoryDraftKind.event, event(3))
      ..put(StoryDraftKind.scene, scene('intro', 'Renamed'))
      ..remove(StoryDraftKind.scene, 'outro')
      ..put(StoryDraftKind.scene, scene('line'))
      ..put(StoryDraftKind.dialogue, dialogue('line'))
      ..remove(StoryDraftKind.dialogue, 'talk')
      ..put(StoryDraftKind.fact, fact('met', 'Renamed'))
      ..remove(StoryDraftKind.fact, 'won')
      ..put(StoryDraftKind.story, story('side'))
      ..remove(StoryDraftKind.story, 'main')
      ..put(StoryDraftKind.worldRule, rule('gate', 'Renamed'))
      ..put(StoryDraftKind.worldRule, rule('door'));

    final projected = draft.project(saved);

    expect(projected.eventRegistry!.records, [event(1, 'Renamed'), event(3)]);
    expect(projected.eventRegistry!.mode, saved.eventRegistry!.mode);
    expect(projected.scenes, [scene('intro', 'Renamed'), scene('line')]);
    expect(projected.dialogues, [dialogue('line').entry]);
    expect(projected.facts, [fact('met', 'Renamed')]);
    expect(projected.storylines, [story('side')]);
    expect(projected.worldRules, [rule('gate', 'Renamed'), rule('door')]);
    expect(projected.name, saved.name);
    expect(saved.scenes, [scene('intro'), scene('outro')]);
  });

  test('the projection is the same instance until the draft changes', () {
    final draft = loaded()
      ..put(StoryDraftKind.scene, scene('intro', 'Renamed'));

    final first = draft.project(saved);
    expect(draft.project(saved), same(first));

    draft.put(StoryDraftKind.fact, fact('met', 'Renamed'));
    final second = draft.project(saved);
    expect(second, isNot(same(first)));
    expect(draft.project(saved), same(second));

    final reloaded = saved.copyWith();
    expect(draft.project(reloaded), isNot(same(second)));
    expect(draft.project(reloaded).scenes.first, scene('intro', 'Renamed'));
  });

  test('the registry is rebuilt only when an event edit changes', () {
    final draft = loaded()..put(StoryDraftKind.event, event(1, 'Renamed'));
    final first = draft.eventRegistry(saved.eventRegistry);

    draft.put(StoryDraftKind.scene, scene('intro', 'Renamed'));
    expect(draft.eventRegistry(saved.eventRegistry), same(first));
    expect(draft.project(saved.copyWith()).eventRegistry, same(first));

    draft.put(StoryDraftKind.event, event(1, 'Again'));
    expect(draft.eventRegistry(saved.eventRegistry), isNot(same(first)));
  });

  test('a first event needs a registry shell when none is saved', () {
    final empty = manifest();
    final draft = StoryDraft()
      ..load(StoryDraftKind.event, eventId(1), null)
      ..put(StoryDraftKind.event, event(1));

    expect(draft.eventRegistry(null), isNull);

    draft.eventRegistryShell = registry(const []);
    expect(draft.project(empty).eventRegistry!.records, [event(1)]);
    draft.put(StoryDraftKind.event, event(1, 'Renamed'));

    expect(draft.project(empty).eventRegistry!.records, [event(1, 'Renamed')]);
    expect(draft.project(empty).eventRegistry!.mode, EventSystemMode.v2Only);
  });

  test('a partial manifest is never read as the whole project', () {
    final partial = manifest(events: [event(1)], scenes: [scene('intro')]);
    final far = scene('far');
    final gone = scene('gone');
    final beyond = SavedStore([far, gone, scene('idle')]);
    final reader = StoryDraftManifestReader().of(partial, beyond: beyond);
    final draft = StoryDraft()
      ..load(StoryDraftKind.scene, 'far', far)
      ..load(StoryDraftKind.scene, 'gone', gone)
      ..load(StoryDraftKind.scene, 'idle', scene('idle'))
      ..put(StoryDraftKind.scene, scene('far', 'Renamed'))
      ..remove(StoryDraftKind.scene, 'gone');

    final changes = draft.changes(reader);
    expect(changes, [
      StoryDraftKind.scene.entry(
        'far',
        base: far,
        current: scene('far', 'Renamed'),
      ),
      StoryDraftKind.scene.entry('gone', base: gone),
    ]);
    expect(changes.any((change) => change.creation), isFalse);
    expect(draft.conflicts(reader), isEmpty);
    expect(draft.project(partial).scenes, [
      scene('intro'),
      scene('far', 'Renamed'),
    ]);
    expect(draft.project(partial).eventRegistry, same(partial.eventRegistry));
  });

  test(
    'the manifest reader answers each kind and follows the manifest it reads',
    () {
      final index = StoryDraftManifestReader();
      final beyond = SavedStore([dialogue('talk'), scene('far')]);
      final reader = index.of(saved, beyond: beyond);

      expect(reader.read(StoryDraftKind.event, eventId(2)), event(2));
      expect(reader.read(StoryDraftKind.scene, 'outro'), scene('outro'));
      expect(reader.read(StoryDraftKind.scene, 'far'), scene('far'));
      expect(reader.read(StoryDraftKind.fact, 'won'), fact('won'));
      expect(reader.read(StoryDraftKind.story, 'main'), story('main'));
      expect(reader.read(StoryDraftKind.worldRule, 'gate'), rule('gate'));
      expect(reader.read(StoryDraftKind.dialogue, 'talk'), dialogue('talk'));
      expect(reader.read(StoryDraftKind.scene, 'missing'), isNull);
      expect(index.of(saved).read(StoryDraftKind.dialogue, 'talk'), isNull);
      expect(index.of(saved).read(StoryDraftKind.scene, 'far'), isNull);

      final sameRegistry = saved.copyWith(scenes: [scene('intro')]);
      final again = index.of(sameRegistry);
      expect(again.read(StoryDraftKind.event, eventId(1)), event(1));
      expect(again.read(StoryDraftKind.scene, 'outro'), isNull);
    },
  );

  test('the effective value is the edit, else what is saved', () {
    final store = SavedStore([dialogue('talk'), dialogue('other')]);
    final draft = loaded()
      ..put(StoryDraftKind.dialogue, dialogue('talk', 'Bonsoir'))
      ..put(StoryDraftKind.dialogue, dialogue('line'));

    expect(
      draft.effective(StoryDraftKind.dialogue, 'talk', store)!.source,
      'Bonsoir',
    );
    expect(
      draft.effective(StoryDraftKind.dialogue, 'line', store),
      dialogue('line'),
    );
    expect(
      draft.effective(StoryDraftKind.dialogue, 'other', store),
      dialogue('other'),
    );

    draft.remove(StoryDraftKind.dialogue, 'talk');
    expect(draft.effective(StoryDraftKind.dialogue, 'talk', store), isNull);
  });
}
