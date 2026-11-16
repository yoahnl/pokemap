import 'package:map_core/map_core_domain.dart';

import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/scene_document.dart';
import 'scene_catalog_controller.dart';
import 'scene_focus_controller.dart';

SceneFocusController sceneCatalogFocus(
  SceneCatalogController catalog,
  SceneDocument document,
) => SceneFocusController(
  port: catalog.port,
  draft: _CatalogFocusDraft(catalog.draft),
  source: catalog.source,
  sceneId: document.scene.id,
  changed: catalog.changed,
)..document.value = document;

final class _CatalogFocusDraft implements SceneFocusDraft {
  const _CatalogFocusDraft(this.draft);
  final StoryDraft draft;

  @override
  bool get editable => false;
  @override
  bool get preparing => false;
  @override
  SceneAsset? touched(String sceneId) =>
      draft.entryOf(StoryDraftKind.scene, sceneId)?.current;
  @override
  SceneAsset? current(String sceneId) =>
      draft.entryOf(StoryDraftKind.scene, sceneId)?.current;
  @override
  bool created(String sceneId) =>
      draft.entryOf(StoryDraftKind.scene, sceneId)?.creation ?? false;
  @override
  bool edit(SceneAsset next) => false;
  @override
  String? detach(String eventId, String name) => null;
}
