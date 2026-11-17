part of 'game_memory_controller.dart';

extension GameMemoryOwnerNames on GameMemoryController {
  String? ownerName(NarrativeOwner owner) {
    final value = switch (owner.kind) {
      NarrativeOwnerKind.event => staging.draft.currentOf(
        StoryDraftKind.event,
        owner.id,
      ),
      NarrativeOwnerKind.scene => staging.draft.currentOf(
        StoryDraftKind.scene,
        owner.id,
      ),
      NarrativeOwnerKind.worldRule => staging.draft.currentOf(
        StoryDraftKind.worldRule,
        owner.id,
      ),
      NarrativeOwnerKind.storyline => staging.draft.currentOf(
        StoryDraftKind.story,
        owner.id,
      ),
      NarrativeOwnerKind.dialogue => staging.draft.currentOf(
        StoryDraftKind.dialogue,
        owner.id,
      ),
      _ => null,
    };
    final name = switch (value) {
      NarrativeEventRecord() => value.name,
      SceneAsset() => value.name,
      WorldRuleDefinition() => value.label,
      StorylineAsset() => value.title,
      StoryDialogueSource() => value.entry.name,
      _ => names.name(owner.kind.titles, owner.id),
    };
    return name?.trim().isEmpty == true ? null : name;
  }

  Future<List<GameMemoryUsageTarget>> storyUsageTargets(
    NarrativeOwner owner,
    String factId,
  ) async {
    StorylineAsset? story;
    if (staging.draft.isLoaded(StoryDraftKind.story, owner.id)) {
      story = staging.draft.currentOf(StoryDraftKind.story, owner.id);
    } else if (port case final NarrativeUsageDocumentPort documents) {
      final generation = _generation;
      try {
        story = await _usageStories.putIfAbsent(
          owner.id,
          () => documents.usageStoryline(owner.id),
        );
      } on Object {
        _usageStories.remove(owner.id);
        rethrow;
      }
      if (generation != _generation) return const [];
    }
    return story == null
        ? const []
        : gameMemoryStoryTargets(story, factId, owner.role);
  }
}
