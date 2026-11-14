import 'package:map_core/map_core_domain.dart';

import '../../dialogues/domain/dialogue_port.dart';
import '../../events/domain/event_port.dart';
import '../../resources/domain/resource_port.dart';
import '../../scenes/domain/scene_port.dart';
import '../../stories/domain/story_port.dart';
import '../../world/domain/world_port.dart';
import '../domain/story_dialogue_source.dart';
import '../domain/story_draft_entry.dart';
import '../domain/story_draft_saved.dart';
import 'story_draft.dart';
import 'story_publication_plan.dart';
import 'story_saved_dialogues.dart';

typedef StoryPublicationLanding = Future<StoryDraftSaved> Function(
  Future<ResourceMutationReceipt> Function() write,
);

typedef StoryPublicationGatewayFactory = StoryPublicationGateway Function(
  StoryDraft draft,
  StorySavedDialogues dialogues,
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
  StoryPublicationGateway({
    required this._draft,
    this._events,
    this._scenes,
    this._dialogues,
    this._facts,
    this._savedDialogues,
    this._stories,
  });

  final StoryDraft _draft;
  final EventPort? _events;
  final ScenePort? _scenes;
  final DialoguePort? _dialogues;
  final WorldPort? _facts;
  final StorySavedDialogues? _savedDialogues;
  final StoryPort? _stories;

  bool supports(StoryDraftKind<Object> kind, {required bool deletion}) =>
      switch (kind) {
        StoryDraftKind.event => _events != null,
        StoryDraftKind.scene => _scenes != null && !deletion,
        StoryDraftKind.dialogue => _dialogues != null,
        StoryDraftKind.fact || StoryDraftKind.worldRule => _facts != null,
        StoryDraftKind.story => _stories != null,
      };

  Future<StoryPublicationProgress> publish(
    List<StoryPublicationStep> plan, {
    required StoryPublicationLanding land,
  }) async {
    final unsupported = {
      for (final step in plan)
        if (!supports(step.kind, deletion: step.deletion)) step.kind,
    };
    if (unsupported.isNotEmpty) throw StoryPublicationUnsupported(unsupported);
    final batch = switch (_events) {
      final EventBatchPort batch => batch,
      _ => null,
    };
    final steps = [
      for (final step in plan)
        if (step.entries.length == 1 ||
            (step.kind == StoryDraftKind.event &&
                !step.deletion &&
                batch != null))
          step
        else
          for (final entry in step.entries)
            StoryPublicationStep(
              kind: step.kind,
              deletion: step.deletion,
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
  ) => switch (step.kind) {
    StoryDraftKind.event => _writeEvents(step, batch),
    StoryDraftKind.scene => _writeScene(
      step.entries.single as StoryDraftEntry<SceneAsset>,
    ),
    StoryDraftKind.dialogue => _writeDialogue(
      step.entries.single as StoryDraftEntry<StoryDialogueSource>,
    ),
    StoryDraftKind.fact => _writeFact(
      step.entries.single as StoryDraftEntry<NarrativeFactDefinition>,
    ),
    StoryDraftKind.worldRule => _writeRule(
      step.entries.single as StoryDraftEntry<WorldRuleDefinition>,
    ),
    StoryDraftKind.story => _writeStory(
      step.entries.single as StoryDraftEntry<StorylineAsset>,
    ),
  };

  Future<ResourceMutationReceipt> _writeEvents(
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
    return _events!.publishEvent(
      id: change.id,
      base: change.base,
      current: change.current,
    );
  }

  Future<ResourceMutationReceipt> _writeScene(
    StoryDraftEntry<SceneAsset> entry,
  ) async => (await _scenes!.publishScene(
    base: entry.base,
    current: entry.current!,
  )).catalog;

  Future<ResourceMutationReceipt> _writeDialogue(
    StoryDraftEntry<StoryDialogueSource> entry,
  ) async {
    final base = entry.base;
    final current = entry.current;
    final revision = base?.revision;
    if (base != null && revision == null) {
      throw StateError('The saved dialogue ${entry.id} has no revision.');
    }
    final receipt = await _dialogues!.publish(
      id: entry.id,
      base: base == null
          ? null
          : DialogueSourceSnapshot(
              entry: base.entry,
              source: base.source,
              revision: revision!,
            ),
      entry: current?.entry,
      source: current?.source,
    );
    switch (receipt.snapshot) {
      case final snapshot?:
        _savedDialogues?.remember(
          StoryDialogueSource(
            entry: snapshot.entry,
            source: snapshot.source,
            revision: snapshot.revision,
          ),
        );
      case null:
        _savedDialogues?.forget(entry.id);
    }
    return receipt.resources;
  }

  Future<ResourceMutationReceipt> _writeFact(
    StoryDraftEntry<NarrativeFactDefinition> entry,
  ) => switch (entry.current) {
    final current? => _facts!.publishFact(base: entry.base, current: current),
    null => _facts!.deleteFact(entry.base!),
  };

  Future<ResourceMutationReceipt> _writeRule(
    StoryDraftEntry<WorldRuleDefinition> entry,
  ) => switch (entry.current) {
    final current? => _facts!.publishRule(base: entry.base, current: current),
    null => _facts!.deleteRule(entry.base!),
  };

  Future<ResourceMutationReceipt> _writeStory(
    StoryDraftEntry<StorylineAsset> entry,
  ) => _stories!.publishStory(
    id: entry.id,
    base: entry.base,
    current: entry.current,
  );
}
