import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_catalog_binding.dart';

import '../presentation/map_builder_story_support.dart';
import 'game_behaviour_edit_support.dart';

void main() {
  test('a missing condition fact refuses an incomplete context', () async {
    final record = storyRecord(
      1,
      source: NarrativeEventSourceRef.entityInteract('b', 'luth'),
      expression: NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('absent', true),
      ),
    );
    final fixture = await openStory(records: [record]);
    final catalog = openCatalogue(fixture, BehaviourMapLoader());
    expect(await catalog.open(record.id), isFalse);
    expect(catalog.error, contains('fait'));
    expect(catalog.editor, isNull);
    expect(fixture.story.dirty, isFalse);
  });

  test(
    'a failed preparation never makes an incomplete context editable',
    () async {
      final record = recordOnB();
      final fixture = await openStory(records: [record]);
      final story = MapBuilderStoryBinding(
        maps: fixture.maps,
        changed: () {},
        view: () => null,
        loadMedia: (_) async => throw StateError('Catalogue indisponible'),
      );
      final loader = BehaviourMapLoader();
      final catalog = MapBuilderStoryCatalogBinding(
        story: story,
        maps: loader,
        changed: () {},
      );
      addTearDown(catalog.dispose);
      expect(await catalog.open(record.id), isFalse);
      expect(catalog.editor, isNull);
      expect(loader.reads, isEmpty);
      expect(story.dirty, isFalse);
      expect(story.ready, isFalse);
    },
  );

  test(
    'failed dialogue reads preserve the behaviour and support retry',
    () async {
      final record = storyRecord(
        1,
        source: NarrativeEventSourceRef.entityInteract('b', 'luth'),
        sceneId: 'line',
      );
      final dialogue = storyLineDialogue('text', ['Original']);
      final fixture = await openStory(
        records: [record],
        scenes: [storyLineScene('line', 'text')],
        dialogues: [dialogue],
      );
      fixture.ports.sources.clear();
      final catalog = openCatalogue(fixture, BehaviourMapLoader());
      expect(await catalog.open(record.id), isFalse);
      expect(catalog.editor, isNull);
      expect(fixture.story.behaviours.draft.recorded, 0);
      expect(storyCurrent(fixture, record.id), record);
      fixture.ports.sources['text'] = dialogue;
      expect(await catalog.open(record.id), isTrue);
      expect(catalog.editor!.lineOf(record).text, 'Original');
    },
  );

  test(
    'a changed record during a dialogue read refuses the old context',
    () async {
      final record = storyRecord(
        1,
        source: NarrativeEventSourceRef.entityInteract('b', 'luth'),
        sceneId: 'line',
      );
      final fixture = await openStory(
        records: [record],
        scenes: [storyLineScene('line', 'text')],
        dialogues: [
          storyLineDialogue('text', ['Original']),
        ],
      );
      final gate = fixture.ports.reading = Completer<void>();
      final catalog = openCatalogue(fixture, BehaviourMapLoader());
      final pending = catalog.open(record.id);
      await Future<void>.delayed(Duration.zero);
      expect(fixture.story.setScene(record, 'scene-plain'), isTrue);
      gate.complete();
      expect(await pending, isFalse);
      expect(catalog.editor, isNull);
      expect(
        fixture.story.behaviours.draft.touched(StoryDraftKind.dialogue),
        isEmpty,
      );
      expect(storyCurrent(fixture, record.id), isNot(record));
    },
  );
}
