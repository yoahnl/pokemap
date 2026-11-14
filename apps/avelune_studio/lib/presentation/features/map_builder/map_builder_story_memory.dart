import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_staging.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

final class MapBuilderStoryMemory implements GameMemoryStaging {
  MapBuilderStoryMemory(this._story, {required this._editable});

  final MapBuilderStoryBinding _story;
  final bool Function() _editable;

  @override
  StoryDraft get draft => _story.behaviours.draft;

  @override
  bool get editable => _editable() && !_story.publishing;

  @override
  Object? get revision => _story.maps.project;

  @override
  void rememberFact(NarrativeFactDefinition fact) =>
      _story.behaviours.records.rememberFact(fact);

  @override
  void rememberRule(WorldRuleDefinition rule) =>
      _story.behaviours.records.rememberRule(rule);

  @override
  void stage(void Function(StoryDraft draft) body) {
    final before = draft.recorded;
    draft.group(() => body(draft));
    if (draft.recorded != before) _story.recordBehaviourStep();
    _story.changed();
  }
}
