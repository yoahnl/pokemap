import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_port.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/story_draft_entry.dart';
import '../domain/story_draft_saved.dart';
import 'story_draft.dart';
import 'story_publication_plan.dart';

typedef StoryPublicationLanding = Future<StoryDraftSaved> Function(
  Future<ResourceMutationReceipt> Function() write,
);

final class StoryPublicationUnsupported implements Exception {
  StoryPublicationUnsupported(Iterable<StoryDraftKind<Object>> kinds)
    : kinds = Set.unmodifiable(kinds);

  final Set<StoryDraftKind<Object>> kinds;

  @override
  String toString() =>
      'StoryPublicationUnsupported(${kinds.map((kind) => kind.name).join(', ')})';
}

final class StoryPublicationFailed implements Exception {
  const StoryPublicationFailed(this.progress, this.cause);

  final StoryPublicationProgress progress;
  final Object cause;

  @override
  String toString() => '$cause';
}

final class StoryPublicationGateway {
  const StoryPublicationGateway({required this._draft, required this._events});

  static const published = {StoryDraftKind.event};

  final StoryDraft _draft;
  final EventPort _events;

  Future<StoryPublicationProgress> publish(
    List<StoryPublicationStep> plan, {
    required StoryPublicationLanding land,
  }) async {
    final unsupported = {
      for (final step in plan)
        if (!published.contains(step.kind)) step.kind,
    };
    if (unsupported.isNotEmpty) throw StoryPublicationUnsupported(unsupported);
    final batch = switch (_events) {
      final EventBatchPort batch => batch,
      _ => null,
    };
    final steps = [
      for (final step in plan)
        if (step.deletion || batch != null)
          step
        else
          for (final entry in step.entries)
            StoryPublicationStep(
              kind: step.kind,
              deletion: false,
              entries: [entry],
            ),
    ];
    var succeeded = 0;
    try {
      for (final step in steps) {
        final saved = await land(() => _write(step, batch));
        _draft.acknowledge(step.entries, saved);
        succeeded++;
      }
    } on Object catch (cause, stackTrace) {
      Error.throwWithStackTrace(
        StoryPublicationFailed(
          storyPublicationProgress(steps, succeeded: succeeded),
          cause,
        ),
        stackTrace,
      );
    }
    return storyPublicationProgress(steps, succeeded: succeeded);
  }

  Future<ResourceMutationReceipt> _write(
    StoryPublicationStep step,
    EventBatchPort? batch,
  ) {
    final changes = [
      for (final entry in step.entries)
        (
          id: entry.id,
          base: entry.base as NarrativeEventRecord?,
          current: entry.current as NarrativeEventRecord?,
        ),
    ];
    if (batch != null && !step.deletion) return batch.publishEvents(changes);
    final change = changes.single;
    return _events.publishEvent(
      id: change.id,
      base: change.base,
      current: change.current,
    );
  }
}
