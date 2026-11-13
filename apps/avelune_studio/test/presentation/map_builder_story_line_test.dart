import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';

void main() {
  List<String> touched(StoryFixture fixture, StoryDraftKind<Object> kind) => [
    ...fixture.story.behaviours.draft.touched(kind),
  ];

  test(
    'a first line creates dialogue, scene and link in one undo step',
    () async {
      final fixture = await openStory();
      final story = fixture.story;
      final luth = storyElement(fixture);
      expect(story.addBehaviour(luth), isTrue, reason: story.error);
      final created = story.behaviours
          .registry(fixture.maps.project!)!
          .records
          .single;
      expect(story.lineOf(created).state, MapStoryLineState.empty);
      final steps = story.behaviours.draft.recorded;

      expect(
        story.writeLine(luth, created, 'Bonjour !\nBelle journée.'),
        isTrue,
        reason: story.error,
      );

      final linked = storyCurrent(fixture, created.id);
      final sceneId = linked.sceneId!;
      expect(sceneId, startsWith('scene_evt_'));
      final dialogueId = behaviourLineDialogueId(story.sceneOf(sceneId)!)!;
      expect(dialogueId, startsWith('dialogue_evt_'));
      expect(dialogueId.substring(9), sceneId.substring(6));
      expect(story.behaviours.draft.recorded, steps + 1);
      expect(story.lineOf(linked).state, MapStoryLineState.line);
      expect(story.lineOf(linked).text, 'Bonjour !\nBelle journée.');
      expect(touched(fixture, StoryDraftKind.scene), [sceneId]);
      expect(touched(fixture, StoryDraftKind.dialogue), [dialogueId]);

      story.undo();
      expect(storyCurrent(fixture, created.id).sceneId, isNull);
      expect(touched(fixture, StoryDraftKind.scene), isEmpty);
      expect(touched(fixture, StoryDraftKind.dialogue), isEmpty);
      expect(
        story.lineOf(storyCurrent(fixture, created.id)).state,
        MapStoryLineState.empty,
      );

      story.redo();
      expect(storyCurrent(fixture, created.id).sceneId, sceneId);
      expect(story.sceneOf(sceneId), isNotNull);

      expect(await story.save(), isTrue, reason: story.error);
      expect(fixture.ports.calls, [
        'dialogue $dialogueId',
        'scene $sceneId',
        'event ${created.id}',
      ]);
      expect(story.dirty, isFalse);
    },
  );

  test('editing a line keeps its ids and writes only the dialogue', () async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'scene_talk')],
      scenes: [storyLineScene('scene_talk', 'dialogue_talk')],
      dialogues: [
        storyLineDialogue('dialogue_talk', ['Salut']),
      ],
    );
    final story = fixture.story;
    final record = storyCurrent(fixture, storyEventId(1));
    expect(story.lineOf(record).state, MapStoryLineState.loading);
    await pumpEventQueue();
    expect(fixture.tick.value, greaterThan(0));
    expect(story.lineOf(record).text, 'Salut');

    expect(story.writeLine(storyElement(fixture), record, 'Salut toi'), isTrue);

    expect(touched(fixture, StoryDraftKind.dialogue), ['dialogue_talk']);
    expect(touched(fixture, StoryDraftKind.scene), isEmpty);
    expect(touched(fixture, StoryDraftKind.event), isEmpty);
    expect(story.lineOf(record).text, 'Salut toi');
    expect(await story.save(), isTrue, reason: story.error);
    expect(fixture.ports.calls, ['dialogue dialogue_talk']);
    expect(
      fixture.ports.sources['dialogue_talk']?.source,
      contains('Salut toi'),
    );
    expect(story.dirty, isFalse);
  });

  test('a shared dialogue warns and is detached before being edited', () async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'scene_talk')],
      scenes: [
        storyLineScene('scene_talk', 'dialogue_talk'),
        storyLineScene('scene_other', 'dialogue_talk'),
      ],
      dialogues: [
        storyLineDialogue('dialogue_talk', ['Salut']),
      ],
    );
    final story = fixture.story;
    final record = storyCurrent(fixture, storyEventId(1));
    story.lineOf(record);
    await pumpEventQueue();
    final shared = story.lineOf(record);
    expect(shared.state, MapStoryLineState.shared);
    expect(shared.sharedWith, ['Réplique scene_other']);
    expect(story.writeLine(storyElement(fixture), record, 'Autre'), isFalse);
    expect(story.behaviours.draft.touchedRefs, isEmpty);

    expect(story.detachLine(record), isTrue, reason: story.error);

    final detached = story.lineOf(record);
    expect(detached.state, MapStoryLineState.line);
    final copy = detached.line!.dialogueId;
    expect(copy, isNot('dialogue_talk'));
    expect(behaviourLineDialogueId(story.sceneOf('scene_talk')!), copy);
    expect(
      behaviourLineDialogueId(story.sceneOf('scene_other')!),
      'dialogue_talk',
    );
    expect(
      story.writeLine(storyElement(fixture), record, 'Rien que moi'),
      isTrue,
    );

    story.undo();
    story.undo();
    expect(story.lineOf(record).state, MapStoryLineState.shared);
    story.redo();
    story.redo();
    expect(await story.save(), isTrue, reason: story.error);
    expect(fixture.ports.calls, ['dialogue $copy', 'scene scene_talk']);
    expect(fixture.ports.sources[copy]?.source, contains('Rien que moi'));
    expect(fixture.ports.sources['dialogue_talk']?.source, contains('Salut'));
  });

  test(
    'sceneOf reads the draft first and editScene is one undo step',
    () async {
      final fixture = await openStory(scenes: [storyPlainScene('scene-x')]);
      final story = fixture.story;
      final saved = story.sceneOf('scene-x')!;
      final next = SceneAsset.fromJson({...saved.toJson(), 'name': 'Renommée'});
      final steps = story.behaviours.draft.recorded;

      expect(story.editScene('scene-y', next), isFalse);
      expect(story.editScene('scene-x', next), isTrue, reason: story.error);

      expect(story.sceneOf('scene-x'), next);
      expect(story.behaviours.draft.recorded, steps + 1);
      expect(story.canUndo, isTrue);
      expect(story.dirty, isTrue);
      expect(story.sceneOf('missing'), isNull);

      story.undo();
      expect(story.sceneOf('scene-x'), saved);
      expect(story.dirty, isFalse);
      story.redo();
      expect(story.sceneOf('scene-x'), next);
      expect(await story.save(), isTrue, reason: story.error);
      expect(fixture.ports.calls, ['scene scene-x']);
    },
  );

  test('a kind without its port is refused with a localized message', () async {
    final fixture = await openStory(scenes: [storyPlainScene('scene-x')]);
    final story = fixture.story;
    final next = SceneAsset.fromJson({
      ...story.sceneOf('scene-x')!.toJson(),
      'name': 'Renommée',
    });
    expect(story.editScene('scene-x', next), isTrue);

    expect(await story.publish(storyEvents(story, fixture.ports)), isFalse);

    expect(fixture.ports.calls, isEmpty);
    expect(story.dirty, isTrue);
    expect(
      mapBuilderStoryError(
        story.error!,
        lookupAppLocalizations(const Locale('fr')),
      ),
      'Rien n’a été enregistré : ce projet ne sait pas encore enregistrer les '
      'scènes ici.',
    );
  });
}
