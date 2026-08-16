import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Storyline authoring', () {
    test('chapter and step reorder preserves every stable identity', () {
      final project = _manifest(storylines: [_storyline()]);
      final chapters = project.storylines.single.chapters;
      final reorderedChapters = const StorylineActions().reorderChapters(
        project,
        storylineId: 'story_main',
        orderedChapterIds: const ['chapter_two', 'chapter_one'],
      );
      final reorderedSteps = const StorylineActions().reorderSteps(
        reorderedChapters,
        storylineId: 'story_main',
        chapterId: 'chapter_one',
        orderedStepIds: const ['step_two', 'step_one'],
      );

      expect(
        reorderedSteps.storylines.single.chapters.map((chapter) => chapter.id),
        ['chapter_two', 'chapter_one'],
      );
      expect(
        reorderedSteps.storylines.single.chapters
            .singleWhere((chapter) => chapter.id == 'chapter_one')
            .steps
            .map((step) => step.id),
        ['step_two', 'step_one'],
      );
      expect(
        reorderedSteps.storylines.single.chapters
            .expand((chapter) => chapter.steps)
            .map((step) => step.id)
            .toSet(),
        chapters
            .expand((chapter) => chapter.steps)
            .map((step) => step.id)
            .toSet(),
      );
    });

    test('canonical progression projection exposes relationship cycles', () {
      final main = StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main',
        relationships: [
          StorylineRelationship(
            id: 'main_requires_side',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story_main',
            targetStorylineId: 'story_side',
          ),
        ],
      );
      final side = StorylineAsset(
        id: 'story_side',
        type: StorylineType.sideQuest,
        title: 'Side',
        relationships: [
          StorylineRelationship(
            id: 'side_requires_main',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story_side',
            targetStorylineId: 'story_main',
          ),
        ],
      );

      final report = const StorylineInspector().inspect(
        _manifest(storylines: [main, side]),
      );

      expect(
        report.diagnostics.map((item) => item.code),
        contains('cycleDetected'),
      );
      expect(report.canPublish, isFalse);
    });

    test('dispatcher and resource registry expose Storyline only', () {
      final actionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        actionIds,
        containsAll({
          'storyline.upsert',
          'storyline.delete',
          'storyline.reorder_chapters',
          'storyline.reorder_steps',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        contains('storyline'),
      );
      expect(
        actionIds.where((actionId) => actionId.startsWith('scenario.')),
        isEmpty,
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal().find('scenario'),
        isNull,
      );
    });
  });
}

ProjectManifest _manifest({
  List<StorylineAsset> storylines = const [],
}) =>
    ProjectManifest(
      name: 'Storyline fixture',
      maps: const [],
      tilesets: const [],
      storylines: storylines,
    );

StorylineAsset _storyline() => StorylineAsset(
      id: 'story_main',
      type: StorylineType.main,
      title: 'Main',
      chapters: [
        StorylineChapter(
          id: 'chapter_one',
          title: 'One',
          order: 0,
          steps: [
            StorylineStep(id: 'step_one', title: 'One', order: 0),
            StorylineStep(id: 'step_two', title: 'Two', order: 1),
          ],
        ),
        StorylineChapter(
          id: 'chapter_two',
          title: 'Two',
          order: 1,
        ),
      ],
    );
