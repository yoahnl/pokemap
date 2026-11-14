import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_draft_entry.dart';
import 'storyline_ids.dart';
import 'storyline_trame_controller.dart';

extension StorylineTrameEdits on StorylineTrameController {
  Future<bool> _edit(
    StorylineMilestoneMutation Function(ProjectManifest project) operation,
  ) async {
    if (!staging.editable || !await prepare() || !staging.editable) {
      return false;
    }
    return apply(operation(working()));
  }

  Set<String> _ids(bool steps) => {
    for (final story in working().storylines)
      for (final chapter in story.chapters)
        if (steps) ...chapter.steps.map((step) => step.id) else chapter.id,
  };

  Future<bool> createChapter(String storylineId, String title) async {
    await prepare();
    final id = storylineItemId('chapter', title, _ids(false));
    return _edit(
      (p) => StorylineMilestoneMutation(
        createStorylineChapter(
          p,
          storylineId: storylineId,
          chapterId: id,
          title: title,
        ),
      ),
    );
  }

  Future<bool> renameChapter(
    String storylineId,
    String chapterId,
    String title,
  ) => _edit(
    (p) => StorylineMilestoneMutation(
      renameStorylineChapter(
        p,
        storylineId: storylineId,
        chapterId: chapterId,
        title: title,
      ),
    ),
  );

  Future<bool> archiveChapter(
    String storylineId,
    String chapterId, {
    required bool archived,
  }) => _edit(
    (p) => StorylineMilestoneMutation(
      setStorylineChapterArchived(
        p,
        storylineId: storylineId,
        chapterId: chapterId,
        archived: archived,
      ),
    ),
  );

  Future<bool> moveChapter(String storylineId, String chapterId, int delta) =>
      _edit((p) {
        final story = p.storylines.firstWhere((s) => s.id == storylineId);
        final ids = [
          for (final chapter in [
            ...story.chapters,
          ]..sort((a, b) => a.order.compareTo(b.order)))
            chapter.id,
        ];
        final from = ids.indexOf(chapterId);
        final to = (from + delta).clamp(0, ids.length - 1);
        ids
          ..removeAt(from)
          ..insert(to, chapterId);
        return StorylineMilestoneMutation(
          reorderStorylineChapters(
            p,
            storylineId: storylineId,
            orderedChapterIds: ids,
          ),
        );
      });

  Future<bool> createMilestone(
    String storylineId,
    String chapterId,
    String title,
  ) async {
    await prepare();
    final id = storylineItemId('milestone', title, _ids(true));
    return _edit(
      (p) => createStorylineMilestone(
        p,
        storylineId: storylineId,
        chapterId: chapterId,
        stepId: id,
        title: title,
      ),
    );
  }

  Future<bool> renameMilestone(
    String storylineId,
    String chapterId,
    String stepId,
    String title, {
    String? completionFactId,
  }) async {
    if (completionFactId != null &&
        !staging.draft.isTouched(StoryDraftKind.fact, completionFactId)) {
      await loadDefinition(completionFactId);
    }
    return _edit(
      (p) => renameStorylineMilestone(
        p,
        storylineId: storylineId,
        chapterId: chapterId,
        stepId: stepId,
        title: title,
      ),
    );
  }

  Future<bool> moveMilestone(
    String storylineId,
    String chapterId,
    String stepId, {
    required String targetChapterId,
    required int targetIndex,
  }) => _edit(
    (p) => StorylineMilestoneMutation(
      moveStorylineStep(
        p,
        storylineId: storylineId,
        sourceChapterId: chapterId,
        targetChapterId: targetChapterId,
        stepId: stepId,
        targetIndex: targetIndex,
      ),
    ),
  );

  Future<bool> archiveMilestone(
    String storylineId,
    String chapterId,
    String stepId, {
    required bool archived,
  }) => _edit(
    (p) => StorylineMilestoneMutation(
      setStorylineMilestoneArchived(
        p,
        storylineId: storylineId,
        chapterId: chapterId,
        stepId: stepId,
        archived: archived,
      ),
    ),
  );

  Future<bool> attachScene(
    String storylineId,
    String chapterId,
    String stepId,
    String sceneId,
  ) => _edit(
    (p) => attachSceneToStorylineMilestone(
      p,
      storylineId: storylineId,
      chapterId: chapterId,
      stepId: stepId,
      sceneId: sceneId,
    ),
  );

  Future<bool> detachScene(
    String storylineId,
    String chapterId,
    String stepId,
    String sceneId,
  ) => _edit(
    (p) => StorylineMilestoneMutation(
      detachSceneFromStorylineMilestone(
        p,
        storylineId: storylineId,
        chapterId: chapterId,
        stepId: stepId,
        sceneId: sceneId,
      ),
    ),
  );

  Future<bool> renameStoryline(String storylineId, String title) => _edit((p) {
    final story = p.storylines.firstWhere((s) => s.id == storylineId);
    return StorylineMilestoneMutation(
      updateStoryline(
        p,
        storylineId: storylineId,
        storyline: story.copyWith(title: title.trim()),
      ),
    );
  });

  Future<bool> startStoryline(
    StorylineType type,
    String title,
    String chapterTitle,
  ) async {
    await prepare();
    final project = working();
    final id = storylineItemId(type.name, title, {
      for (final story in project.storylines) story.id,
    });
    final chapter = storylineItemId('chapter', chapterTitle, _ids(false));
    return _edit(
      (p) => StorylineMilestoneMutation(
        createStoryline(
          p,
          storyline: StorylineAsset(
            id: id,
            type: type,
            status: StorylineStatus.active,
            title: title.trim(),
            chapters: [
              StorylineChapter(id: chapter, title: chapterTitle, order: 0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loadProposal() => proposal.load(port.proposal, changed);

  Future<bool> keepProposal(String title) async {
    final proposed = proposal.value?.storyline;
    if (proposed == null) return false;
    final kept = await _edit(
      (p) => StorylineMilestoneMutation(
        createStoryline(
          p,
          storyline: title.trim().isEmpty
              ? proposed
              : proposed.copyWith(title: title.trim()),
        ),
      ),
    );
    if (kept) discardProposal();
    return kept;
  }

  void discardProposal() {
    proposal
      ..value = null
      ..problem = null;
    changed();
  }

  bool discardStoryline(String id) {
    final entry = staging.draft.entryOf(StoryDraftKind.story, id);
    if (!staging.editable || entry == null || !entry.creation) return false;
    staging.stage((draft) => draft.remove(StoryDraftKind.story, id));
    return true;
  }
}
