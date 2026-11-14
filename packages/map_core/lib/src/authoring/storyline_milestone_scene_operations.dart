part of 'storyline_milestone_operations.dart';

StorylineMilestoneMutation attachSceneToStorylineMilestone(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
}) {
  final step = _step(project, storylineId, chapterId, stepId);
  if (step == null) {
    return StorylineMilestoneMutation(
      _rejected(project, 'stepNotFound', 'The milestone does not exist.'),
    );
  }
  if (!project.scenes.any((scene) => scene.id == sceneId)) {
    return StorylineMilestoneMutation(
      _rejected(project, 'sceneNotFound', 'The SceneAsset does not exist.'),
    );
  }
  if (step.sceneLinkIds.contains(sceneId)) {
    return StorylineMilestoneMutation(
      updateStorylineStep(
        project,
        storylineId: storylineId,
        chapterId: chapterId,
        stepId: stepId,
        step: step,
      ),
    );
  }
  var next = project;
  final detached = _locate(
    project,
    (other) => other.id != stepId && other.sceneLinkIds.contains(sceneId),
  );
  for (final (location, other) in detached) {
    next = updateStorylineStep(
      next,
      storylineId: location.storylineId,
      chapterId: location.chapterId,
      stepId: location.stepId,
      step: other.copyWith(
        sceneLinkIds: [...other.sceneLinkIds]..remove(sceneId),
      ),
    ).after;
  }
  final attached = updateStorylineStep(
    next,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
    step: step.copyWith(sceneLinkIds: [...step.sceneLinkIds, sceneId]),
  );
  return StorylineMilestoneMutation(
    _rebased(project, attached),
    detachedFrom: [for (final (location, _) in detached) location],
  );
}

StorylineMutationResult detachSceneFromStorylineMilestone(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
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
    step: step.copyWith(sceneLinkIds: [...step.sceneLinkIds]..remove(sceneId)),
  );
}
