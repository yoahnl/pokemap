import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/storyline_trame_fixture.dart';

void main() {
  group('scenes', () {
    test('attaching moves a scene owned by another milestone', () {
      final result = attachSceneToStorylineMilestone(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        sceneId: 'scene_shared',
      );

      expect(result.result.isApplied, isTrue);
      expect(result.detachedFrom.map((location) => location.toJson()), [
        {'storylineId': 'side', 'chapterId': 'side_act', 'stepId': 'side_step'},
      ]);
      final after = result.result.after;
      expect(after.storylines.first.chapters.single.steps.single.sceneLinkIds, [
        'scene_rival',
        'scene_shared',
      ]);
      expect(
        after.storylines.last.chapters.single.steps.single.sceneLinkIds,
        isEmpty,
      );
    });

    test('attaching twice changes nothing and unknown scenes are rejected', () {
      final project = storylineTrameProject();
      final again = attachSceneToStorylineMilestone(
        project,
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        sceneId: 'scene_rival',
      );
      final unknown = attachSceneToStorylineMilestone(
        project,
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        sceneId: 'scene_missing',
      );

      expect(again.result.disposition, StorylineMutationDisposition.noChange);
      expect(again.detachedFrom, isEmpty);
      expect(unknown.result.code, 'sceneNotFound');
      expect(unknown.result.after, same(project));
    });

    test('detaching removes the scene and ignores an absent one', () {
      final detached = detachSceneFromStorylineMilestone(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        sceneId: 'scene_rival',
      );
      final absent = detachSceneFromStorylineMilestone(
        detached.after,
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        sceneId: 'scene_rival',
      );

      expect(
        detached
            .after
            .storylines
            .first
            .chapters
            .single
            .steps
            .single
            .sceneLinkIds,
        isEmpty,
      );
      expect(absent.disposition, StorylineMutationDisposition.noChange);
    });
  });
}
