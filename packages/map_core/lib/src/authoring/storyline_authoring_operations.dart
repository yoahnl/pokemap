import '../models/project_manifest.dart';
import '../models/storyline_asset.dart';
import '../read_models/narrative_dependency_index.dart';

/// Outcome of one pure Storyline lifecycle operation.
///
/// Rejected and no-op operations always keep [before] and [after] identical so
/// an editor cannot accidentally publish a partial projection.
enum StorylineMutationDisposition { applied, noChange, rejected }

/// Immutable before/after envelope returned by Storyline authoring commands.
final class StorylineMutationResult {
  StorylineMutationResult({
    required this.before,
    required this.after,
    required this.disposition,
    this.storyline,
    this.previousStoryline,
    this.chapter,
    this.previousChapter,
    this.step,
    this.previousStep,
    this.code,
    this.message,
    List<String> referencePaths = const <String>[],
  }) : referencePaths = List<String>.unmodifiable(referencePaths);

  final ProjectManifest before;
  final ProjectManifest after;
  final StorylineMutationDisposition disposition;
  final StorylineAsset? storyline;
  final StorylineAsset? previousStoryline;
  final StorylineChapter? chapter;
  final StorylineChapter? previousChapter;
  final StorylineStep? step;
  final StorylineStep? previousStep;
  final String? code;
  final String? message;
  final List<String> referencePaths;

  bool get isApplied => disposition == StorylineMutationDisposition.applied;
}

/// Adds an already validated Storyline asset without replacing an existing id.
StorylineMutationResult createStoryline(
  ProjectManifest project, {
  required StorylineAsset storyline,
}) {
  if (project.storylines.any((candidate) => candidate.id == storyline.id)) {
    return _storylineRejected(
      project,
      code: 'storylineIdAlreadyExists',
      message: 'A StorylineAsset already uses this id.',
    );
  }
  return _storylineApplied(
    project,
    project.copyWith(storylines: [...project.storylines, storyline]),
    storyline: storyline,
  );
}

/// Replaces one Storyline atomically while preserving its stable technical id.
StorylineMutationResult updateStoryline(
  ProjectManifest project, {
  required String storylineId,
  required StorylineAsset storyline,
}) {
  final id = storylineId.trim();
  final matches = project.storylines.where((asset) => asset.id == id).toList();
  if (matches.isEmpty) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to update does not exist.',
    );
  }
  if (matches.length > 1) {
    return _storylineRejected(
      project,
      code: 'storylineIdAmbiguous',
      message: 'The StorylineAsset id is ambiguous.',
    );
  }
  final previous = matches.single;
  if (storyline.id != id) {
    return _storylineRejected(
      project,
      code: 'storylineIdMismatch',
      message: 'A StorylineAsset update cannot change its stable id.',
    );
  }
  if (previous == storyline) {
    return StorylineMutationResult(
      before: project,
      after: project,
      disposition: StorylineMutationDisposition.noChange,
      storyline: previous,
      previousStoryline: previous,
      code: 'storylineUnchanged',
      message: 'The StorylineAsset already has these values.',
    );
  }
  return _storylineApplied(
    project,
    project.copyWith(
      storylines: [
        for (final asset in project.storylines)
          if (asset.id == id) storyline else asset,
      ],
    ),
    storyline: storyline,
    previousStoryline: previous,
  );
}

/// Deep-clones a Storyline and remaps every id owned by the copied asset.
StorylineMutationResult duplicateStoryline(
  ProjectManifest project, {
  required String storylineId,
  required String duplicateId,
  String? title,
}) {
  final source = _findStoryline(project, storylineId);
  if (source == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to duplicate does not exist.',
    );
  }
  final id = duplicateId.trim();
  if (id.isEmpty) {
    return _storylineRejected(
      project,
      code: 'blankStorylineId',
      message: 'The duplicated StorylineAsset requires an id.',
    );
  }
  if (project.storylines.any((candidate) => candidate.id == id)) {
    return _storylineRejected(
      project,
      code: 'storylineIdAlreadyExists',
      message: 'A StorylineAsset already uses the duplicate id.',
    );
  }
  try {
    final duplicate = _duplicateStorylineAsset(
      source,
      duplicateId: id,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : '${source.title} (copie)',
    );
    return createStoryline(project, storyline: duplicate);
  } on Object catch (error) {
    return _storylineRejected(
      project,
      code: 'invalidStorylineDuplicate',
      message: 'The StorylineAsset duplicate is invalid: $error',
    );
  }
}

/// Moves a Storyline to the archived lifecycle state without deleting content.
StorylineMutationResult archiveStoryline(
  ProjectManifest project, {
  required String storylineId,
}) {
  final source = _findStoryline(project, storylineId);
  if (source == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to archive does not exist.',
    );
  }
  return updateStoryline(
    project,
    storylineId: source.id,
    storyline: source.copyWith(status: StorylineStatus.archived),
  );
}

/// Deletes a Storyline only when no external narrative consumer references it.
///
/// Outgoing references owned by the Storyline do not block its own deletion.
StorylineMutationResult deleteStoryline(
  ProjectManifest project, {
  required String storylineId,
}) {
  final source = _findStoryline(project, storylineId);
  if (source == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to delete does not exist.',
    );
  }
  final target = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.storyline,
    source.id,
  );
  final externalUsages = buildNarrativeDependencyIndex(project: project)
      .usagesFor(target)
      .where((usage) => usage.owner != target)
      .toList(growable: false);
  if (externalUsages.isNotEmpty) {
    return _storylineRejected(
      project,
      code: 'storylineReferenced',
      message: 'The StorylineAsset is still used by narrative consumers.',
      referencePaths: [for (final usage in externalUsages) usage.path],
    );
  }
  return _storylineApplied(
    project,
    project.copyWith(
      storylines: [
        for (final asset in project.storylines)
          if (asset.id != source.id) asset,
      ],
    ),
    previousStoryline: source,
  );
}

/// Updates Chapter metadata without changing its stable id or ownership.
StorylineMutationResult updateStorylineChapter(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required StorylineChapter chapter,
}) {
  final storyline = _findStoryline(project, storylineId);
  final previous =
      storyline == null ? null : _findChapter(storyline, chapterId);
  if (storyline == null || previous == null) {
    return _storylineRejected(
      project,
      code: 'chapterNotFound',
      message: 'The StorylineChapter to update does not exist.',
    );
  }
  if (chapter.id != previous.id) {
    return _storylineRejected(
      project,
      code: 'chapterIdMismatch',
      message: 'A StorylineChapter update cannot change its stable id.',
    );
  }
  if (chapter == previous) {
    return _structureNoChange(
      project,
      storyline: storyline,
      chapter: previous,
      previousChapter: previous,
      code: 'chapterUnchanged',
    );
  }
  final updatedStoryline = storyline.copyWith(
    chapters: [
      for (final current in storyline.chapters)
        if (current.id == previous.id) chapter else current,
    ],
  );
  return _applyStructureProjection(
    project,
    storyline,
    updatedStoryline,
    chapter: chapter,
    previousChapter: previous,
  );
}

/// Deep-clones a Chapter, including its owned Steps and structured SceneLinks.
StorylineMutationResult duplicateStorylineChapter(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String duplicateChapterId,
  String? title,
}) {
  final storyline = _findStoryline(project, storylineId);
  final source = storyline == null ? null : _findChapter(storyline, chapterId);
  if (storyline == null || source == null) {
    return _storylineRejected(
      project,
      code: 'chapterNotFound',
      message: 'The StorylineChapter to duplicate does not exist.',
    );
  }
  final duplicateId = duplicateChapterId.trim();
  if (duplicateId.isEmpty) {
    return _storylineRejected(
      project,
      code: 'blankChapterId',
      message: 'The duplicated StorylineChapter requires an id.',
    );
  }
  if (storyline.chapters.any((chapter) => chapter.id == duplicateId)) {
    return _storylineRejected(
      project,
      code: 'chapterIdAlreadyExists',
      message: 'A StorylineChapter already uses the duplicate id.',
    );
  }

  final stepIds = <String, String>{
    for (final step in source.steps) step.id: '${duplicateId}__${step.id}',
  };
  final duplicate = source.copyWith(
    id: duplicateId,
    title: title?.trim().isNotEmpty == true
        ? title!.trim()
        : '${source.title} (copy)',
    order: _nextChapterOrder(storyline.chapters),
    steps: [
      for (final step in source.steps) step.copyWith(id: stepIds[step.id]),
    ],
  );
  var nextSceneLinkOrder = _nextSceneLinkOrder(storyline.sceneLinks);
  final duplicatedLinks = <StorylineSceneLink>[
    for (final link in storyline.sceneLinks)
      if (link.chapterId == source.id)
        _duplicateStructureSceneLink(
          link,
          duplicateOwnerId: duplicateId,
          chapterId: duplicateId,
          stepId: link.stepId == null ? null : stepIds[link.stepId!],
          order: nextSceneLinkOrder++,
          remappedStepIds: stepIds,
        ),
  ];
  final updatedStoryline = storyline.copyWith(
    chapters: [...storyline.chapters, duplicate],
    sceneLinks: [...storyline.sceneLinks, ...duplicatedLinks],
  );
  return _applyStructureProjection(
    project,
    storyline,
    updatedStoryline,
    chapter: duplicate,
  );
}

/// Deletes only an empty, unreferenced Chapter.
StorylineMutationResult deleteStorylineChapter(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
}) {
  final storyline = _findStoryline(project, storylineId);
  final source = storyline == null ? null : _findChapter(storyline, chapterId);
  if (storyline == null || source == null) {
    return _storylineRejected(
      project,
      code: 'chapterNotFound',
      message: 'The StorylineChapter to delete does not exist.',
    );
  }
  if (source.steps.isNotEmpty) {
    return _storylineRejected(
      project,
      code: 'chapterContainsSteps',
      message: 'Move or delete every Step before deleting this Chapter.',
      referencePaths: [
        for (final step in source.steps)
          'storylines[${storyline.id}].chapters[${source.id}].steps[${step.id}]',
      ],
    );
  }
  final usages = buildNarrativeDependencyIndex(project: project).usagesFor(
    NarrativeDependencyKey(
      NarrativeDependencyTargetKind.chapter,
      source.id,
    ),
  );
  if (usages.isNotEmpty) {
    return _storylineRejected(
      project,
      code: 'chapterReferenced',
      message: 'The StorylineChapter is still used by narrative consumers.',
      referencePaths: [for (final usage in usages) usage.path],
    );
  }
  final remaining = [
    for (final chapter in storyline.chapters)
      if (chapter.id != source.id) chapter,
  ];
  final updatedStoryline = storyline.copyWith(
    chapters: _normalizeChapterOrders(remaining),
  );
  return _applyStructureProjection(
    project,
    storyline,
    updatedStoryline,
    previousChapter: source,
  );
}

/// Reorders every Chapter from an exact, duplicate-free id projection.
StorylineMutationResult reorderStorylineChapters(
  ProjectManifest project, {
  required String storylineId,
  required List<String> orderedChapterIds,
}) {
  final storyline = _findStoryline(project, storylineId);
  if (storyline == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to reorder does not exist.',
    );
  }
  final ordered = _orderedChaptersByIds(storyline, orderedChapterIds);
  if (ordered == null) {
    return _storylineRejected(
      project,
      code: 'invalidChapterOrder',
      message: 'Chapter order must contain every Chapter id exactly once.',
    );
  }
  final normalized = _normalizeChapterOrders(ordered);
  final updatedStoryline = storyline.copyWith(chapters: normalized);
  if (updatedStoryline == storyline) {
    return _structureNoChange(
      project,
      storyline: storyline,
      code: 'chapterOrderUnchanged',
    );
  }
  return _applyStructureProjection(project, storyline, updatedStoryline);
}

/// Updates all authorable Step fields while preserving the stable Step id.
StorylineMutationResult updateStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required StorylineStep step,
}) {
  final target = _tryFindStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  if (target == null) {
    return _storylineRejected(
      project,
      code: 'stepNotFound',
      message: 'The StorylineStep to update does not exist.',
    );
  }
  if (step.id != target.step.id) {
    return _storylineRejected(
      project,
      code: 'stepIdMismatch',
      message: 'A StorylineStep update cannot change its stable id.',
    );
  }
  if (step == target.step) {
    return _structureNoChange(
      project,
      storyline: target.storyline,
      chapter: target.chapter,
      step: target.step,
      previousStep: target.step,
      code: 'stepUnchanged',
    );
  }
  final updatedChapter = target.chapter.copyWith(
    steps: [
      for (final current in target.chapter.steps)
        if (current.id == target.step.id) step else current,
    ],
  );
  final updatedStoryline = target.storyline.copyWith(
    chapters: [
      for (final chapter in target.storyline.chapters)
        if (chapter.id == target.chapter.id) updatedChapter else chapter,
    ],
  );
  return _applyStructureProjection(
    project,
    target.storyline,
    updatedStoryline,
    chapter: updatedChapter,
    step: step,
    previousStep: target.step,
  );
}

/// Clones a Step and its structured SceneLinks inside the same Chapter.
StorylineMutationResult duplicateStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String duplicateStepId,
  String? title,
}) {
  final target = _tryFindStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  if (target == null) {
    return _storylineRejected(
      project,
      code: 'stepNotFound',
      message: 'The StorylineStep to duplicate does not exist.',
    );
  }
  final duplicateId = duplicateStepId.trim();
  if (duplicateId.isEmpty) {
    return _storylineRejected(
      project,
      code: 'blankStepId',
      message: 'The duplicated StorylineStep requires an id.',
    );
  }
  if (_allStorylineSteps(target.storyline)
      .any((step) => step.id == duplicateId)) {
    return _storylineRejected(
      project,
      code: 'stepIdAlreadyExists',
      message: 'A StorylineStep already uses the duplicate id.',
    );
  }
  final duplicate = target.step.copyWith(
    id: duplicateId,
    title: title?.trim().isNotEmpty == true
        ? title!.trim()
        : '${target.step.title} (copy)',
    order: _nextStepOrder(target.chapter.steps),
  );
  final updatedChapter = target.chapter.copyWith(
    steps: [...target.chapter.steps, duplicate],
  );
  var nextSceneLinkOrder = _nextSceneLinkOrder(target.storyline.sceneLinks);
  final duplicateLinks = <StorylineSceneLink>[
    for (final link in target.storyline.sceneLinks)
      if (link.chapterId == target.chapter.id && link.stepId == target.step.id)
        _duplicateStructureSceneLink(
          link,
          duplicateOwnerId: duplicateId,
          chapterId: target.chapter.id,
          stepId: duplicateId,
          order: nextSceneLinkOrder++,
          remappedStepIds: {target.step.id: duplicateId},
        ),
  ];
  final updatedStoryline = target.storyline.copyWith(
    chapters: [
      for (final chapter in target.storyline.chapters)
        if (chapter.id == target.chapter.id) updatedChapter else chapter,
    ],
    sceneLinks: [...target.storyline.sceneLinks, ...duplicateLinks],
  );
  return _applyStructureProjection(
    project,
    target.storyline,
    updatedStoryline,
    chapter: updatedChapter,
    step: duplicate,
  );
}

/// Deletes an unreferenced Step and keeps sibling order contiguous.
StorylineMutationResult deleteStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
}) {
  final target = _tryFindStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  if (target == null) {
    return _storylineRejected(
      project,
      code: 'stepNotFound',
      message: 'The StorylineStep to delete does not exist.',
    );
  }
  final usages = buildNarrativeDependencyIndex(project: project).usagesFor(
    NarrativeDependencyKey(
      NarrativeDependencyTargetKind.step,
      target.step.id,
    ),
  );
  if (usages.isNotEmpty) {
    return _storylineRejected(
      project,
      code: 'stepReferenced',
      message: 'The StorylineStep is still used by narrative consumers.',
      referencePaths: [for (final usage in usages) usage.path],
    );
  }
  final remaining = [
    for (final step in target.chapter.steps)
      if (step.id != target.step.id) step,
  ];
  final updatedChapter = target.chapter.copyWith(
    steps: _normalizeStepOrders(remaining),
  );
  final updatedStoryline = target.storyline.copyWith(
    chapters: [
      for (final chapter in target.storyline.chapters)
        if (chapter.id == target.chapter.id) updatedChapter else chapter,
    ],
  );
  return _applyStructureProjection(
    project,
    target.storyline,
    updatedStoryline,
    chapter: updatedChapter,
    previousStep: target.step,
  );
}

/// Reorders every Step in one Chapter from an exact id projection.
StorylineMutationResult reorderStorylineSteps(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required List<String> orderedStepIds,
}) {
  final storyline = _findStoryline(project, storylineId);
  final chapter = storyline == null ? null : _findChapter(storyline, chapterId);
  if (storyline == null || chapter == null) {
    return _storylineRejected(
      project,
      code: 'chapterNotFound',
      message: 'The StorylineChapter to reorder does not exist.',
    );
  }
  final ordered = _orderedStepsByIds(chapter, orderedStepIds);
  if (ordered == null) {
    return _storylineRejected(
      project,
      code: 'invalidStepOrder',
      message: 'Step order must contain every Step id exactly once.',
    );
  }
  final updatedChapter = chapter.copyWith(steps: _normalizeStepOrders(ordered));
  final updatedStoryline = storyline.copyWith(
    chapters: [
      for (final current in storyline.chapters)
        if (current.id == chapter.id) updatedChapter else current,
    ],
  );
  if (updatedStoryline == storyline) {
    return _structureNoChange(
      project,
      storyline: storyline,
      chapter: chapter,
      code: 'stepOrderUnchanged',
    );
  }
  return _applyStructureProjection(
    project,
    storyline,
    updatedStoryline,
    chapter: updatedChapter,
  );
}

/// Moves one Step between Chapters without changing its globally unique id.
StorylineMutationResult moveStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String sourceChapterId,
  required String targetChapterId,
  required String stepId,
  required int targetIndex,
}) {
  final target = _tryFindStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: sourceChapterId,
    stepId: stepId,
  );
  final targetChapter =
      target == null ? null : _findChapter(target.storyline, targetChapterId);
  if (target == null || targetChapter == null) {
    return _storylineRejected(
      project,
      code: 'stepMoveTargetNotFound',
      message: 'The Step source or target Chapter does not exist.',
    );
  }
  final sourceSteps = [...target.chapter.steps]..removeWhere(
      (step) => step.id == target.step.id,
    );
  final destinationSteps = target.chapter.id == targetChapter.id
      ? sourceSteps
      : [...targetChapter.steps];
  final insertionIndex = targetIndex.clamp(0, destinationSteps.length).toInt();
  destinationSteps.insert(insertionIndex, target.step);

  final updatedSource = target.chapter.copyWith(
    steps: _normalizeStepOrders(
      target.chapter.id == targetChapter.id ? destinationSteps : sourceSteps,
    ),
  );
  final updatedTarget = target.chapter.id == targetChapter.id
      ? updatedSource
      : targetChapter.copyWith(
          steps: _normalizeStepOrders(destinationSteps),
        );
  final updatedStoryline = target.storyline.copyWith(
    chapters: [
      for (final chapter in target.storyline.chapters)
        if (chapter.id == updatedSource.id)
          updatedSource
        else if (chapter.id == updatedTarget.id)
          updatedTarget
        else
          chapter,
    ],
    sceneLinks: [
      for (final link in target.storyline.sceneLinks)
        if (link.stepId == target.step.id)
          _copySceneLinkOwner(link, chapterId: targetChapter.id)
        else
          link,
    ],
  );
  return _applyStructureProjection(
    project,
    target.storyline,
    updatedStoryline,
    chapter: updatedTarget,
    step: updatedTarget.steps.firstWhere(
      (step) => step.id == target.step.id,
    ),
    previousChapter: target.chapter,
    previousStep: target.step,
  );
}

final class StorylineStepSceneLinkResult {
  const StorylineStepSceneLinkResult({
    required this.updatedProject,
    required this.updatedStoryline,
    required this.updatedStep,
  });

  final ProjectManifest updatedProject;
  final StorylineAsset updatedStoryline;
  final StorylineStep updatedStep;
}

StorylineStepSceneLinkResult linkSceneToStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
}) {
  final normalizedSceneId = _normalizeSceneId(sceneId);
  _requireKnownScene(project, normalizedSceneId);
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  if (target.step.sceneLinkIds.contains(normalizedSceneId)) {
    throw ArgumentError.value(
      sceneId,
      'sceneId',
      'StorylineStep already links this Scene.',
    );
  }
  return _replaceStepSceneLinks(
    project,
    target,
    [...target.step.sceneLinkIds, normalizedSceneId],
  );
}

StorylineStepSceneLinkResult unlinkSceneFromStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
}) {
  final normalizedSceneId = _normalizeSceneId(sceneId);
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  return _replaceStepSceneLinks(
    project,
    target,
    target.step.sceneLinkIds
        .where((current) => current != normalizedSceneId)
        .toList(growable: false),
  );
}

StorylineStepSceneLinkResult replaceStorylineStepSceneLinks(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required List<String> sceneIds,
}) {
  final normalizedSceneIds = _uniqueSceneIds(sceneIds);
  for (final sceneId in normalizedSceneIds) {
    _requireKnownScene(project, sceneId);
  }
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  return _replaceStepSceneLinks(project, target, normalizedSceneIds);
}

StorylineStepSceneLinkResult clearStorylineStepSceneLinks(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
}) {
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  return _replaceStepSceneLinks(project, target, const <String>[]);
}

StorylineStepSceneLinkResult _replaceStepSceneLinks(
  ProjectManifest project,
  _StorylineStepTarget target,
  List<String> sceneLinkIds,
) {
  final updatedStep = _copyStepWith(
    target.step,
    sceneLinkIds: sceneLinkIds,
  );
  final updatedChapter = _copyChapterWith(
    target.chapter,
    steps: target.chapter.steps
        .map((step) => step.id == target.step.id ? updatedStep : step)
        .toList(growable: false),
  );
  final updatedStoryline = _copyStorylineWith(
    target.storyline,
    chapters: target.storyline.chapters
        .map((chapter) =>
            chapter.id == target.chapter.id ? updatedChapter : chapter)
        .toList(growable: false),
  );
  final updatedProject = project.copyWith(
    storylines: project.storylines
        .map((storyline) =>
            storyline.id == target.storyline.id ? updatedStoryline : storyline)
        .toList(growable: false),
  );
  return StorylineStepSceneLinkResult(
    updatedProject: updatedProject,
    updatedStoryline: updatedStoryline,
    updatedStep: updatedStep,
  );
}

_StorylineStepTarget _findStorylineStepTarget(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
}) {
  final normalizedStorylineId = _requireNotBlank(storylineId, 'storylineId');
  final normalizedChapterId = _requireNotBlank(chapterId, 'chapterId');
  final normalizedStepId = _requireNotBlank(stepId, 'stepId');

  StorylineAsset? storyline;
  for (final candidate in project.storylines) {
    if (candidate.id == normalizedStorylineId) {
      storyline = candidate;
      break;
    }
  }
  if (storyline == null) {
    throw ArgumentError.value(
      storylineId,
      'storylineId',
      'Unknown StorylineAsset.',
    );
  }

  StorylineChapter? chapter;
  for (final candidate in storyline.chapters) {
    if (candidate.id == normalizedChapterId) {
      chapter = candidate;
      break;
    }
  }
  if (chapter == null) {
    throw ArgumentError.value(
      chapterId,
      'chapterId',
      'Unknown StorylineChapter.',
    );
  }

  StorylineStep? step;
  for (final candidate in chapter.steps) {
    if (candidate.id == normalizedStepId) {
      step = candidate;
      break;
    }
  }
  if (step == null) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Unknown StorylineStep.',
    );
  }

  return _StorylineStepTarget(
    storyline: storyline,
    chapter: chapter,
    step: step,
  );
}

String _normalizeSceneId(String sceneId) {
  final normalized = _requireNotBlank(sceneId, 'sceneId');
  return normalized;
}

List<String> _uniqueSceneIds(List<String> sceneIds) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final sceneId in sceneIds) {
    final value = _normalizeSceneId(sceneId);
    if (seen.add(value)) {
      normalized.add(value);
    }
  }
  return List<String>.unmodifiable(normalized);
}

void _requireKnownScene(ProjectManifest project, String sceneId) {
  if (!project.scenes.any((scene) => scene.id == sceneId)) {
    throw ArgumentError.value(sceneId, 'sceneId', 'Unknown SceneAsset.');
  }
}

String _requireNotBlank(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'Value must not be blank.');
  }
  return trimmed;
}

StorylineAsset _copyStorylineWith(
  StorylineAsset storyline, {
  List<StorylineChapter>? chapters,
}) {
  return StorylineAsset(
    id: storyline.id,
    schemaVersion: storyline.schemaVersion,
    type: storyline.type,
    status: storyline.status,
    title: storyline.title,
    description: storyline.description,
    sortOrder: storyline.sortOrder,
    locale: storyline.locale,
    chapters: chapters ?? storyline.chapters,
    sceneLinks: storyline.sceneLinks,
    relationships: storyline.relationships,
    legacySource: storyline.legacySource,
    authorNotes: storyline.authorNotes,
    metadata: storyline.metadata,
  );
}

StorylineChapter _copyChapterWith(
  StorylineChapter chapter, {
  List<StorylineStep>? steps,
}) {
  return StorylineChapter(
    id: chapter.id,
    title: chapter.title,
    description: chapter.description,
    order: chapter.order,
    steps: steps ?? chapter.steps,
    directSceneLinkIds: chapter.directSceneLinkIds,
    status: chapter.status,
    authorNotes: chapter.authorNotes,
    metadata: chapter.metadata,
  );
}

StorylineStep _copyStepWith(
  StorylineStep step, {
  List<String>? sceneLinkIds,
}) {
  return StorylineStep(
    id: step.id,
    title: step.title,
    description: step.description,
    order: step.order,
    entryCondition: step.entryCondition,
    completionCondition: step.completionCondition,
    sceneLinkIds: sceneLinkIds ?? step.sceneLinkIds,
    expectedOutcomeIds: step.expectedOutcomeIds,
    status: step.status,
    authorNotes: step.authorNotes,
    metadata: step.metadata,
  );
}

final class _StorylineStepTarget {
  const _StorylineStepTarget({
    required this.storyline,
    required this.chapter,
    required this.step,
  });

  final StorylineAsset storyline;
  final StorylineChapter chapter;
  final StorylineStep step;
}

StorylineChapter? _findChapter(
  StorylineAsset storyline,
  String chapterId,
) {
  final id = chapterId.trim();
  for (final chapter in storyline.chapters) {
    if (chapter.id == id) return chapter;
  }
  return null;
}

_StorylineStepTarget? _tryFindStorylineStepTarget(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
}) {
  final storyline = _findStoryline(project, storylineId);
  if (storyline == null) return null;
  final chapter = _findChapter(storyline, chapterId);
  if (chapter == null) return null;
  final id = stepId.trim();
  for (final step in chapter.steps) {
    if (step.id == id) {
      return _StorylineStepTarget(
        storyline: storyline,
        chapter: chapter,
        step: step,
      );
    }
  }
  return null;
}

Iterable<StorylineStep> _allStorylineSteps(StorylineAsset storyline) sync* {
  for (final chapter in storyline.chapters) {
    yield* chapter.steps;
  }
}

int _nextChapterOrder(List<StorylineChapter> chapters) {
  var next = 0;
  for (final chapter in chapters) {
    if (chapter.order >= next) next = chapter.order + 1;
  }
  return next;
}

int _nextStepOrder(List<StorylineStep> steps) {
  var next = 0;
  for (final step in steps) {
    if (step.order >= next) next = step.order + 1;
  }
  return next;
}

int _nextSceneLinkOrder(List<StorylineSceneLink> links) {
  var next = 0;
  for (final link in links) {
    if (link.order >= next) next = link.order + 1;
  }
  return next;
}

List<StorylineChapter> _normalizeChapterOrders(
  List<StorylineChapter> chapters,
) {
  return List<StorylineChapter>.unmodifiable([
    for (var index = 0; index < chapters.length; index++)
      chapters[index].copyWith(order: index),
  ]);
}

List<StorylineStep> _normalizeStepOrders(List<StorylineStep> steps) {
  return List<StorylineStep>.unmodifiable([
    for (var index = 0; index < steps.length; index++)
      steps[index].copyWith(order: index),
  ]);
}

List<StorylineChapter>? _orderedChaptersByIds(
  StorylineAsset storyline,
  List<String> ids,
) {
  if (ids.length != storyline.chapters.length) return null;
  final byId = {for (final chapter in storyline.chapters) chapter.id: chapter};
  final seen = <String>{};
  final ordered = <StorylineChapter>[];
  for (final rawId in ids) {
    final id = rawId.trim();
    final chapter = byId[id];
    if (chapter == null || !seen.add(id)) return null;
    ordered.add(chapter);
  }
  return ordered;
}

List<StorylineStep>? _orderedStepsByIds(
  StorylineChapter chapter,
  List<String> ids,
) {
  if (ids.length != chapter.steps.length) return null;
  final byId = {for (final step in chapter.steps) step.id: step};
  final seen = <String>{};
  final ordered = <StorylineStep>[];
  for (final rawId in ids) {
    final id = rawId.trim();
    final step = byId[id];
    if (step == null || !seen.add(id)) return null;
    ordered.add(step);
  }
  return ordered;
}

StorylineSceneLink _copySceneLinkOwner(
  StorylineSceneLink link, {
  required String chapterId,
}) {
  return StorylineSceneLink(
    id: link.id,
    chapterId: chapterId,
    stepId: link.stepId,
    label: link.label,
    state: link.state,
    role: link.role,
    sceneRef: link.sceneRef,
    order: link.order,
    expectedOutcomeIds: link.expectedOutcomeIds,
    outcomeLinks: link.outcomeLinks,
    authorNotes: link.authorNotes,
    metadata: link.metadata,
  );
}

StorylineSceneLink _duplicateStructureSceneLink(
  StorylineSceneLink link, {
  required String duplicateOwnerId,
  required String chapterId,
  required String? stepId,
  required int order,
  required Map<String, String> remappedStepIds,
}) {
  return StorylineSceneLink(
    id: '${duplicateOwnerId}__${link.id}',
    chapterId: chapterId,
    stepId: stepId,
    label: link.label,
    state: link.state,
    role: link.role,
    sceneRef: link.sceneRef,
    order: order,
    expectedOutcomeIds: link.expectedOutcomeIds,
    outcomeLinks: [
      for (final outcome in link.outcomeLinks)
        StorylineSceneOutcomeLink(
          id: '${duplicateOwnerId}__${outcome.id}',
          outcomeId: outcome.outcomeId,
          label: outcome.label,
          effects: [
            for (final effect in outcome.effects)
              if ((effect.type == StorylineEffectType.activateStep ||
                      effect.type == StorylineEffectType.completeStep) &&
                  remappedStepIds.containsKey(effect.targetId))
                StorylineEffect(
                  type: effect.type,
                  targetId: remappedStepIds[effect.targetId]!,
                  value: effect.value,
                )
              else
                effect,
          ],
          notes: outcome.notes,
          metadata: outcome.metadata,
        ),
    ],
    authorNotes: link.authorNotes,
    metadata: link.metadata,
  );
}

StorylineMutationResult _applyStructureProjection(
  ProjectManifest project,
  StorylineAsset previousStoryline,
  StorylineAsset storyline, {
  StorylineChapter? chapter,
  StorylineChapter? previousChapter,
  StorylineStep? step,
  StorylineStep? previousStep,
}) {
  final after = project.copyWith(
    storylines: [
      for (final current in project.storylines)
        if (current.id == previousStoryline.id) storyline else current,
    ],
  );
  return _storylineApplied(
    project,
    after,
    storyline: storyline,
    previousStoryline: previousStoryline,
    chapter: chapter,
    previousChapter: previousChapter,
    step: step,
    previousStep: previousStep,
  );
}

StorylineMutationResult _structureNoChange(
  ProjectManifest project, {
  required StorylineAsset storyline,
  StorylineChapter? chapter,
  StorylineChapter? previousChapter,
  StorylineStep? step,
  StorylineStep? previousStep,
  required String code,
}) {
  return StorylineMutationResult(
    before: project,
    after: project,
    disposition: StorylineMutationDisposition.noChange,
    storyline: storyline,
    previousStoryline: storyline,
    chapter: chapter,
    previousChapter: previousChapter,
    step: step,
    previousStep: previousStep,
    code: code,
    message: 'The Storyline structure already has these values.',
  );
}

StorylineAsset? _findStoryline(ProjectManifest project, String storylineId) {
  final id = storylineId.trim();
  StorylineAsset? match;
  for (final candidate in project.storylines) {
    if (candidate.id != id) continue;
    if (match != null) return null;
    match = candidate;
  }
  return match;
}

StorylineMutationResult _storylineApplied(
  ProjectManifest before,
  ProjectManifest after, {
  StorylineAsset? storyline,
  StorylineAsset? previousStoryline,
  StorylineChapter? chapter,
  StorylineChapter? previousChapter,
  StorylineStep? step,
  StorylineStep? previousStep,
}) {
  return StorylineMutationResult(
    before: before,
    after: after,
    disposition: StorylineMutationDisposition.applied,
    storyline: storyline,
    previousStoryline: previousStoryline,
    chapter: chapter,
    previousChapter: previousChapter,
    step: step,
    previousStep: previousStep,
  );
}

StorylineMutationResult _storylineRejected(
  ProjectManifest project, {
  required String code,
  required String message,
  List<String> referencePaths = const <String>[],
}) {
  return StorylineMutationResult(
    before: project,
    after: project,
    disposition: StorylineMutationDisposition.rejected,
    code: code,
    message: message,
    referencePaths: referencePaths,
  );
}

StorylineAsset _duplicateStorylineAsset(
  StorylineAsset source, {
  required String duplicateId,
  required String title,
}) {
  // Chapter and step ids are asset-owned. Keeping them unchanged would create
  // ambiguous authoring targets as soon as the duplicate is inserted.
  final chapterIds = <String, String>{
    for (final chapter in source.chapters)
      chapter.id: '${duplicateId}__${chapter.id}',
  };
  final stepIds = <String, String>{
    for (final chapter in source.chapters)
      for (final step in chapter.steps) step.id: '${duplicateId}__${step.id}',
  };

  StorylineAnchor remapAnchor(StorylineAnchor anchor) {
    final targetId = switch (anchor.kind) {
      StorylineAnchorKind.storyline when anchor.targetId == source.id =>
        duplicateId,
      StorylineAnchorKind.chapter =>
        chapterIds[anchor.targetId] ?? anchor.targetId,
      StorylineAnchorKind.step => stepIds[anchor.targetId] ?? anchor.targetId,
      _ => anchor.targetId,
    };
    return StorylineAnchor(kind: anchor.kind, targetId: targetId);
  }

  StorylineEffect remapEffect(StorylineEffect effect) {
    final targetId = switch (effect.type) {
      StorylineEffectType.activateStep ||
      StorylineEffectType.completeStep =>
        stepIds[effect.targetId] ?? effect.targetId,
      StorylineEffectType.unlockStoryline when effect.targetId == source.id =>
        duplicateId,
      _ => effect.targetId,
    };
    return StorylineEffect(
      type: effect.type,
      targetId: targetId,
      value: effect.value,
    );
  }

  return StorylineAsset(
    id: duplicateId,
    schemaVersion: source.schemaVersion,
    type: source.type,
    status: StorylineStatus.draft,
    title: title,
    description: source.description,
    sortOrder: source.sortOrder,
    locale: source.locale,
    chapters: [
      for (final chapter in source.chapters)
        StorylineChapter(
          id: chapterIds[chapter.id]!,
          title: chapter.title,
          description: chapter.description,
          order: chapter.order,
          steps: [
            for (final step in chapter.steps)
              StorylineStep(
                id: stepIds[step.id]!,
                title: step.title,
                description: step.description,
                order: step.order,
                entryCondition: step.entryCondition,
                completionCondition: step.completionCondition,
                sceneLinkIds: step.sceneLinkIds,
                expectedOutcomeIds: step.expectedOutcomeIds,
                status: step.status,
                authorNotes: step.authorNotes,
                metadata: step.metadata,
              ),
          ],
          directSceneLinkIds: chapter.directSceneLinkIds,
          status: chapter.status,
          authorNotes: chapter.authorNotes,
          metadata: chapter.metadata,
        ),
    ],
    sceneLinks: [
      for (final link in source.sceneLinks)
        StorylineSceneLink(
          id: '${duplicateId}__${link.id}',
          chapterId: chapterIds[link.chapterId]!,
          stepId: link.stepId == null ? null : stepIds[link.stepId!],
          label: link.label,
          state: link.state,
          role: link.role,
          sceneRef: link.sceneRef,
          order: link.order,
          expectedOutcomeIds: link.expectedOutcomeIds,
          outcomeLinks: [
            for (final outcome in link.outcomeLinks)
              StorylineSceneOutcomeLink(
                id: '${duplicateId}__${outcome.id}',
                outcomeId: outcome.outcomeId,
                label: outcome.label,
                effects: [
                  for (final effect in outcome.effects) remapEffect(effect)
                ],
                notes: outcome.notes,
                metadata: outcome.metadata,
              ),
          ],
          authorNotes: link.authorNotes,
          metadata: link.metadata,
        ),
    ],
    relationships: [
      for (final relationship in source.relationships)
        StorylineRelationship(
          id: '${duplicateId}__${relationship.id}',
          kind: relationship.kind,
          sourceStorylineId: duplicateId,
          targetStorylineId: relationship.targetStorylineId,
          anchor: relationship.anchor == null
              ? null
              : remapAnchor(relationship.anchor!),
          availability: relationship.availability == null
              ? null
              : SideQuestAvailability(
                  startAnchor:
                      remapAnchor(relationship.availability!.startAnchor),
                  endAnchor: relationship.availability!.endAnchor == null
                      ? null
                      : remapAnchor(relationship.availability!.endAnchor!),
                  availabilityCondition:
                      relationship.availability!.availabilityCondition,
                  expiresCondition: relationship.availability!.expiresCondition,
                  requiredOutcomeIds:
                      relationship.availability!.requiredOutcomeIds,
                ),
          condition: relationship.condition,
          notes: relationship.notes,
          metadata: relationship.metadata,
        ),
    ],
    authorNotes: source.authorNotes,
    metadata: <String, String>{
      for (final entry in source.metadata.entries)
        if (entry.key != 'legacyImportPreview' && entry.key != 'legacyImported')
          entry.key: entry.value,
      'duplicatedFrom': source.id,
    },
  );
}
