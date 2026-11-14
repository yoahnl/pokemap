import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

final class MapBuilderStoryBehaviourSource implements GameBehaviourSource {
  const MapBuilderStoryBehaviourSource(this._story);

  final MapBuilderStoryBinding _story;

  ProjectManifest? get _project => _story.maps.project;

  @override
  NarrativeEventRegistry? get registry => switch (_project) {
    final project? => _story.behaviours.registry(project),
    null => null,
  };

  @override
  List<ProjectMapEntry> get maps => _project?.maps ?? const [];

  @override
  List<SceneAsset> get scenes => switch (_project) {
    final project? => _story.behaviours.project(project).scenes,
    null => const [],
  };

  @override
  Object? get revision => _project;

  @override
  bool touched(String id) =>
      _story.behaviours.draft.isTouched(StoryDraftKind.event, id);

  @override
  String? elementName(String mapId, MapStoryElementTarget target, String id) {
    if (_story.map?.id != mapId) return null;
    final name = _story.elements?.byKey('${target.name}:$id')?.name.trim();
    return name == null || name.isEmpty ? null : name;
  }
}
