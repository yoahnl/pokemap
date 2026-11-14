part of 'map_builder_story_binding.dart';

extension MapStoryPublication on MapBuilderStoryBinding {
  Future<bool> publish(StoryPublicationGateway? gateway) async {
    final project = maps.project;
    if (project == null || !dirty) return true;
    if (gateway == null) {
      error = 'publish-unavailable';
      changed();
      return false;
    }
    publishing = true;
    changed();
    try {
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
      error = cause is EventFailure ? cause.message : '$cause';
      return false;
    } finally {
      publishing = false;
      changed();
    }
  }
}
