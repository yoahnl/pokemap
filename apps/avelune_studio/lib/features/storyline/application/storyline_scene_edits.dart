import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_draft_entry.dart';
import 'storyline_trame_controller.dart';

extension StorylineSceneEdits on StorylineTrameController {
  Future<bool> attachSceneReviewed(
    String storylineId,
    String chapterId,
    String stepId,
    String sceneId, {
    required Future<bool> Function(List<StorylineStepLocation> origins)
    confirmMove,
  }) async {
    if (!staging.editable || !await prepare() || !staging.editable) {
      return false;
    }
    final draft = staging.draft;
    final storyVersion = draft.versionOf(StoryDraftKind.story);
    final sceneVersion = draft.versionOf(StoryDraftKind.scene);
    final revision = source().revision;
    final stories = saved.value;
    bool current() =>
        staging.editable &&
        draft.versionOf(StoryDraftKind.story) == storyVersion &&
        draft.versionOf(StoryDraftKind.scene) == sceneVersion &&
        identical(saved.value, stories) &&
        identical(source().revision, revision);
    final sceneEntry = draft.entryOf(StoryDraftKind.scene, sceneId);
    var scene =
        sceneEntry?.current ??
        source().scenes.where((scene) => scene.id == sceneId).firstOrNull;
    if (sceneEntry != null && sceneEntry.current == null) {
      return _linkRefused('sceneNotFound');
    }
    if (scene == null) {
      try {
        scene = (await index.sceneDocument(sceneId)).scene;
      } on Object {
        return _linkRefused('sceneUnavailable');
      }
    }
    if (!current()) return _linkRefused('stale');
    final project = working();
    final mutation = attachSceneToStorylineMilestone(
      project.copyWith(
        scenes: [
          for (final item in project.scenes)
            if (item.id != sceneId) item,
          scene,
        ],
      ),
      storylineId: storylineId,
      chapterId: chapterId,
      stepId: stepId,
      sceneId: sceneId,
    );
    if (mutation.detachedFrom.isNotEmpty &&
        !await confirmMove(mutation.detachedFrom)) {
      return false;
    }
    if (!current()) return _linkRefused('stale');
    return apply(mutation);
  }

  bool _linkRefused(String code) {
    refusal = code;
    changed();
    return false;
  }
}
