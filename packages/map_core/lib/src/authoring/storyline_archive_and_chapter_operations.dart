part of 'storyline_milestone_operations.dart';

StorylineMutationResult createStorylineChapter(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String title,
  int? index,
}) {
  final storyline = _storyline(project, storylineId);
  if (storyline == null) {
    return _rejected(
      project,
      'storylineNotFound',
      'The StorylineAsset to extend does not exist.',
    );
  }
  if (!_isIdentity(chapterId)) {
    return _rejected(
      project,
      'chapterIdInvalid',
      'A Chapter id must be a nonblank trimmed string.',
    );
  }
  if (title.trim().isEmpty) {
    return _rejected(
      project,
      'chapterTitleRequired',
      'A Chapter needs a title.',
    );
  }
  if (project.storylines.any(
    (asset) => asset.chapters.any((chapter) => chapter.id == chapterId),
  )) {
    return _rejected(
      project,
      'chapterIdAlreadyExists',
      'A StorylineChapter already uses this id.',
    );
  }
  final chapters = [...storyline.chapters];
  chapters.insert(
    (index ?? chapters.length).clamp(0, chapters.length),
    StorylineChapter(id: chapterId, title: title.trim(), order: 0),
  );
  return updateStoryline(
    project,
    storylineId: storyline.id,
    storyline: storyline.copyWith(
      chapters: [
        for (var position = 0; position < chapters.length; position++)
          chapters[position].copyWith(order: position),
      ],
    ),
  );
}

StorylineMutationResult renameStorylineChapter(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String title,
}) {
  final chapter = _chapter(_storyline(project, storylineId), chapterId);
  if (chapter == null) {
    return _rejected(
      project,
      'chapterNotFound',
      'The StorylineChapter does not exist.',
    );
  }
  if (title.trim().isEmpty) {
    return _rejected(
      project,
      'chapterTitleRequired',
      'A Chapter needs a title.',
    );
  }
  return updateStorylineChapter(
    project,
    storylineId: storylineId,
    chapterId: chapter.id,
    chapter: chapter.copyWith(title: title.trim()),
  );
}

StorylineMutationResult setStorylineChapterArchived(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required bool archived,
}) {
  final chapter = _chapter(_storyline(project, storylineId), chapterId);
  if (chapter == null) {
    return _rejected(
      project,
      'chapterNotFound',
      'The StorylineChapter does not exist.',
    );
  }
  return updateStorylineChapter(
    project,
    storylineId: storylineId,
    chapterId: chapter.id,
    chapter: chapter.copyWith(
      status: _archivedStatus(chapter.status, archived: archived),
    ),
  );
}

StorylineMutationResult setStorylineMilestoneArchived(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required bool archived,
}) {
  final step = _step(project, storylineId, chapterId, stepId);
  if (step == null) {
    return _rejected(project, 'stepNotFound', 'The milestone does not exist.');
  }
  return updateStorylineStep(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
    step: step.copyWith(
      status: _archivedStatus(step.status, archived: archived),
    ),
  );
}
