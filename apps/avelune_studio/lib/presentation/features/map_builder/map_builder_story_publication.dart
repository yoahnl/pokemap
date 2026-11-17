part of 'map_builder_story_binding.dart';

extension MapStoryPublication on MapBuilderStoryBinding {
  Future<bool> publish(StoryPublicationGateway? gateway) async {
    final published = await _publish(gateway);
    saveError = published ? null : error;
    changed();
    return published;
  }

  Future<bool> _publish(StoryPublicationGateway? gateway) async {
    if (maps.project == null || !dirty) return true;
    if (gateway == null) {
      error = 'publish-unavailable';
      changed();
      return false;
    }
    publishing = true;
    changed();
    try {
      await maps.savesSettled;
      final project = maps.project;
      if (project == null) {
        error = 'publish-unavailable';
        return false;
      }
      final progress = await gateway.publish(
        planStoryPublication(
          behaviours.draft.changes(behaviours.saved(project)),
        ),
        land: (write) async {
          final before = maps.project!;
          final receipt = await write();
          maps.acceptResources(
            maps.project == receipt.before ? receipt.before : before,
            receipt.manifest,
          );
          return behaviours.saved(receipt.manifest);
        },
      );
      behaviours.rememberPublished(progress.saved);
      final saved = maps.project!;
      behaviours.settle(saved);
      final conflicts = behaviours.conflicts(saved);
      if (conflicts.isNotEmpty) {
        final records = saved.eventRegistry?.records ?? const [];
        error = _conflictMessage([
          for (final id in conflicts)
            (behaviours.draftOf(id) ??
                        records.where((record) => record.id == id).firstOrNull)
                    ?.name ??
                id,
        ]);
        return false;
      }
      error = null;
      return true;
    } on StoryPublicationUnsupported catch (failure) {
      error =
          '${MapBuilderStoryBinding.unsupported}${[for (final kind in failure.kinds) kind.name].join(',')}';
      return false;
    } on Object catch (failure) {
      if (failure is StoryPublicationFailed) {
        behaviours.rememberPublished(failure.progress.saved);
      }
      final cause = failure is StoryPublicationFailed ? failure.cause : failure;
      error = storyPublicationReason(cause) ?? _refusal(failure);
      return false;
    } finally {
      publishing = false;
      changed();
    }
  }

  String _refusal(Object failure) {
    final step = failure is StoryPublicationFailed
        ? failure.progress.failed
        : null;
    final entry = step?.entries.firstOrNull;
    if (entry == null) return MapBuilderStoryBinding.publishRefused;
    final value =
        behaviours.draft.currentOf(entry.kind, entry.id) ??
        entry.current ??
        entry.base;
    final name = switch (value) {
      NarrativeFactDefinition(:final label) => label,
      StorylineAsset(:final title) => title,
      SceneAsset(:final name) => name,
      NarrativeEventRecord(:final name) => name,
      WorldRuleDefinition(:final label) => label,
      _ => entry.id,
    };
    return '${MapBuilderStoryBinding.publishRefused}${entry.kind.name}:$name';
  }
}
