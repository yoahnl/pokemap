import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

final class MapBuilderSceneFocusDraft implements SceneFocusDraft {
  const MapBuilderSceneFocusDraft(this._story, {required this.isEditable});

  final MapBuilderStoryBinding _story;
  final bool Function() isEditable;

  @override
  bool get editable => isEditable() && _story.ready && !_story.publishing;

  @override
  SceneAsset? touched(String sceneId) {
    final draft = _story.behaviours.draft;
    return draft.isTouched(StoryDraftKind.scene, sceneId)
        ? draft.entryOf(StoryDraftKind.scene, sceneId)!.current
        : null;
  }

  @override
  bool created(String sceneId) =>
      _story.behaviours.draft
          .entryOf(StoryDraftKind.scene, sceneId)
          ?.creation ??
      false;

  @override
  bool edit(SceneAsset next) => editable && _story.editScene(next.id, next);

  @override
  String? detach(String eventId, String name) =>
      editable ? _story.detachScene(eventId, name) : null;
}
