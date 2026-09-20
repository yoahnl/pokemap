import 'package:map_core/map_core_domain.dart';
import '../../../features/stories/application/story_workspace_controller.dart';

class StoryDocumentCommands {
  const StoryDocumentCommands(this.controller);
  final StoryWorkspaceController controller;

  void metadata(
    String storyId,
    String? chapterId,
    String? stepId,
    String field,
    String value,
  ) {
    final story = controller.stories.where((s) => s.id == storyId).firstOrNull;
    if (story == null || (field == 'title' && value.trim().isEmpty)) return;
    final text = value.trim().isEmpty ? null : value;
    final status = StorylineStatus.values
        .where((s) => s.name == value)
        .firstOrNull;
    final chapter = story.chapters.where((c) => c.id == chapterId).firstOrNull;
    final step = chapter?.steps.where((s) => s.id == stepId).firstOrNull;
    if ((chapterId != null && chapter == null) ||
        (stepId != null && step == null)) {
      return;
    }
    if (step != null) {
      final next = switch (field) {
        'title' => step.copyWith(title: value.trim()),
        'description' => step.copyWith(description: text),
        'notes' => step.copyWith(authorNotes: text),
        'status' => step.copyWith(status: status),
        _ => step,
      };
      controller.apply(
        updateStorylineStep(
          controller.project,
          storylineId: storyId,
          chapterId: chapter!.id,
          stepId: step.id,
          step: next,
        ),
      );
    } else if (chapter != null) {
      final next = switch (field) {
        'title' => chapter.copyWith(title: value.trim()),
        'description' => chapter.copyWith(description: text),
        'notes' => chapter.copyWith(authorNotes: text),
        'status' => chapter.copyWith(status: status),
        _ => chapter,
      };
      controller.apply(
        updateStorylineChapter(
          controller.project,
          storylineId: storyId,
          chapterId: chapter.id,
          chapter: next,
        ),
      );
    } else {
      final next = switch (field) {
        'title' => story.copyWith(title: value.trim()),
        'description' => story.copyWith(description: text),
        'notes' => story.copyWith(authorNotes: text),
        'status' => story.copyWith(status: status ?? story.status),
        'type' => story.copyWith(
          type: StorylineType.values.firstWhere((v) => v.name == value),
        ),
        _ => story,
      };
      controller.apply(
        updateStoryline(
          controller.project,
          storylineId: storyId,
          storyline: next,
        ),
      );
    }
  }

  void addChapter(String storyId, String name) {
    final story = controller.stories.firstWhere((s) => s.id == storyId);
    final order =
        story.chapters.fold(-1, (n, c) => c.order > n ? c.order : n) + 1;
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(
          chapters: [
            ...story.chapters,
            StorylineChapter(
              id: controller.narrative.identity('chapitre'),
              title: name,
              order: order,
            ),
          ],
        ),
      ),
    );
  }

  void addStep(String storyId, String chapterId, String name) {
    final chapter = controller.stories
        .firstWhere((s) => s.id == storyId)
        .chapters
        .firstWhere((c) => c.id == chapterId);
    final order =
        chapter.steps.fold(-1, (n, s) => s.order > n ? s.order : n) + 1;
    controller.apply(
      updateStorylineChapter(
        controller.project,
        storylineId: storyId,
        chapterId: chapterId,
        chapter: chapter.copyWith(
          steps: [
            ...chapter.steps,
            StorylineStep(
              id: controller.narrative.identity('etape'),
              title: name,
              order: order,
            ),
          ],
        ),
      ),
    );
  }

  void remove(String storyId, String? chapterId, String? stepId) {
    final project = controller.project;
    controller.apply(
      stepId != null
          ? deleteStorylineStep(
              project,
              storylineId: storyId,
              chapterId: chapterId!,
              stepId: stepId,
            )
          : chapterId != null
          ? deleteStorylineChapter(
              project,
              storylineId: storyId,
              chapterId: chapterId,
            )
          : deleteStoryline(project, storylineId: storyId),
    );
  }

  void duplicate(String storyId, String? chapterId, String? stepId) {
    final project = controller.project;
    controller.apply(
      stepId != null
          ? duplicateStorylineStep(
              project,
              storylineId: storyId,
              chapterId: chapterId!,
              stepId: stepId,
              duplicateStepId: controller.narrative.identity('etape'),
            )
          : chapterId != null
          ? duplicateStorylineChapter(
              project,
              storylineId: storyId,
              chapterId: chapterId,
              duplicateChapterId: controller.narrative.identity('chapitre'),
            )
          : duplicateStoryline(
              project,
              storylineId: storyId,
              duplicateId: controller.narrative.identity('histoire'),
            ),
    );
  }
}
