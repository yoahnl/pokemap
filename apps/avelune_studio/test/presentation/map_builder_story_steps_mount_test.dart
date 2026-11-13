import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_story_steps_edit_test.dart' show openMenu, rootIds;
import 'map_builder_story_steps_list_test.dart' show linearScene;
import 'map_builder_story_support.dart';

void main() {
  testWidgets(
    'a scene with several steps is edited from the inspector and undone',
    (tester) async {
      final scene = linearScene();
      final fixture = await openStory(
        records: [storyRecord(1, sceneId: scene.id)],
        scenes: [scene],
      );
      await pumpStoryInspector(tester, fixture);
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('map-story-steps-${scene.id}')), findsOne);
      expect(find.byKey(const ValueKey('map-story-then')), findsOne);

      await openMenu(
        tester,
        find.byKey(const ValueKey('story-step-actions-fact')),
        'story-step-remove-fact',
      );

      final edited = fixture.story.sceneOf(scene.id)!;
      expect(rootIds(edited), ['talk']);
      expect(
        [...fixture.story.behaviours.draft.touched(StoryDraftKind.scene)],
        [scene.id],
      );
      expect(fixture.story.dirty, isTrue);

      fixture.story.undo();
      await tester.pumpAndSettle();

      expect(rootIds(fixture.story.sceneOf(scene.id)!), ['fact', 'talk']);
      expect(fixture.story.dirty, isFalse);
      expect(find.byKey(const ValueKey('story-step-actions-fact')), findsOne);
    },
  );
}
