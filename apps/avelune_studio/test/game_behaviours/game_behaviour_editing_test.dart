import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_editing.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

import '../presentation/map_builder_story_support.dart';

void main() {
  test('an obsolete record cannot overwrite a newer behaviour edit', () async {
    final original = storyRecord(1);
    final fixture = await openStory(records: [original]);
    final story = fixture.story;
    expect(story.renameBehaviour(original, 'Premier nom'), isTrue);
    expect(story.renameBehaviour(original, 'Ancien formulaire'), isFalse);
    expect(storyCurrent(fixture, original.id).name, 'Premier nom');
    expect(story.error, isNotNull);
    story.undo();
    expect(storyCurrent(fixture, original.id).name, original.name);
    expect(story.canUndo, isFalse);
  });

  test('an edit keeps its activation and remains one undo step', () async {
    final original = storyRecord(1);
    final fixture = await openStory(records: [original]);
    expect(fixture.story.setScene(original, 'scene-plain'), isTrue);
    expect(storyCurrent(fixture, original.id).enabledOrNull, isTrue);
    expect(fixture.story.renameBehaviour(original, 'Renommé'), isTrue);
    fixture.story.undo();
    expect(storyCurrent(fixture, original.id), original);
    fixture.story.redo();
    expect(storyCurrent(fixture, original.id).name, 'Renommé');
    expect(fixture.ports.calls, isEmpty);
  });

  test(
    'a refused operation rolls back staged dependencies atomically',
    () async {
      final record = storyRecord(1);
      final fixture = await openStory(records: [record]);
      final behaviours = fixture.story.behaviours;
      final editing = GameBehaviourEditing(
        project: fixture.maps.project!,
        map: fixture.story.map!,
        behaviours: behaviours,
      );
      final fact = NarrativeFactDefinition(
        id: 'new-fact',
        label: 'Nouveau fait',
        initialValue: const NarrativeValue.boolean(false),
      );
      final before = behaviours.registry(fixture.maps.project!);
      final result = editing.apply(
        active: [record],
        stage: (draft) {
          draft.load(StoryDraftKind.fact, fact.id, null);
          draft.put(StoryDraftKind.fact, fact);
        },
        operations: [
          (c) => setNarrativeEventOrder(
            context: c,
            expectedRevision: 'obsolete',
            eventId: record.id,
            order: 10,
          ),
        ],
      );
      expect(result.applied, isFalse);
      expect(result.recorded, isFalse);
      expect(result.problem, isNotNull);
      expect(behaviours.registry(fixture.maps.project!), before);
      expect(behaviours.draft.currentOf(StoryDraftKind.fact, fact.id), isNull);
      expect(fixture.story.dirty, isFalse);
      expect(behaviours.canUndo, isFalse);
    },
  );

  test('an edit remains disabled if reactivation is refused', () async {
    final record = storyRecord(1);
    final fixture = await openStory(records: [record]);
    expect(fixture.story.setScene(record, null), isTrue);
    final edited = storyCurrent(fixture, record.id);
    expect(edited.sceneId, isNull);
    expect(edited.enabledOrNull, isNot(true));
    expect(fixture.story.error, startsWith(MapBuilderStoryBinding.deactivated));
    fixture.story.undo();
    expect(storyCurrent(fixture, record.id), record);
  });
}
