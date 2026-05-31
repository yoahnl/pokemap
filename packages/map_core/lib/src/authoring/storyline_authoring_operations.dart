import '../models/project_manifest.dart';
import '../models/storyline_asset.dart';

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
