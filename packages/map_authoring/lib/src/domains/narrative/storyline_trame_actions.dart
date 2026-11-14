import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class StorylineTrameActions {
  const StorylineTrameActions();

  static const factWritingActions = {
    'storyline.milestone.create',
    'storyline.milestone.rename',
  };

  static const sceneReadingActions = {'storyline.milestone.attach_scene'};

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final (id, summary) in const [
      ('storyline.chapter.create', 'Create a Chapter at a position'),
      ('storyline.chapter.rename', 'Rename a Chapter'),
      ('storyline.chapter.set_archived', 'Archive or restore a Chapter'),
      (
        'storyline.milestone.create',
        'Create a milestone Step with its own completion Fact'
      ),
      (
        'storyline.milestone.rename',
        'Rename a milestone and its untouched completion Fact label'
      ),
      (
        'storyline.milestone.move',
        'Move a milestone to a Chapter position without changing its id'
      ),
      ('storyline.milestone.set_archived', 'Archive or restore a milestone'),
      (
        'storyline.milestone.attach_scene',
        'Attach a whole Scene to a milestone, moving it from any other'
      ),
      ('storyline.milestone.detach_scene', 'Detach a Scene from a milestone'),
    ])
      narrativeActionDescriptor(id, summary,
          resourceKinds: const ['project', 'storyline']),
  ]);

  static final Set<String> ids = {
    for (final descriptor in descriptors) descriptor.id
  };

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final action = context.request.actionId;
    final p = context.request.parameters;
    final project = context.snapshot.manifest;
    final storylineId = narrativeStringParameter(p, 'storylineId');
    String text(String key) => narrativeStringParameter(p, key);
    StorylineMilestoneMutation wrapped(StorylineMutationResult result) =>
        StorylineMilestoneMutation(result);
    final keys = switch (action) {
      'storyline.chapter.create' => {'chapterId', 'title', 'index'},
      'storyline.chapter.rename' => {'chapterId', 'title'},
      'storyline.chapter.set_archived' => {'chapterId', 'archived'},
      'storyline.milestone.create' => {'chapterId', 'stepId', 'title', 'index'},
      'storyline.milestone.rename' => {'chapterId', 'stepId', 'title'},
      'storyline.milestone.move' => {
          'chapterId',
          'stepId',
          'targetChapterId',
          'targetIndex'
        },
      'storyline.milestone.set_archived' => {'chapterId', 'stepId', 'archived'},
      'storyline.milestone.attach_scene' ||
      'storyline.milestone.detach_scene' =>
        {'chapterId', 'stepId', 'sceneId'},
      _ => throw NarrativeAuthoringException('storyline.action_unsupported',
          'The requested Storyline action is unsupported.'),
    };
    rejectUnknownNarrativeParameters(p, {'storylineId', ...keys});
    final mutation = switch (action) {
      'storyline.chapter.create' => wrapped(createStorylineChapter(project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          title: text('title'),
          index: _index(p, 'index'))),
      'storyline.chapter.rename' => wrapped(renameStorylineChapter(project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          title: text('title'))),
      'storyline.chapter.set_archived' => wrapped(setStorylineChapterArchived(
          project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          archived: _flag(p, 'archived'))),
      'storyline.milestone.create' => createStorylineMilestone(project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          stepId: text('stepId'),
          title: text('title'),
          index: _index(p, 'index')),
      'storyline.milestone.rename' => renameStorylineMilestone(project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          stepId: text('stepId'),
          title: text('title')),
      'storyline.milestone.move' => wrapped(moveStorylineStep(project,
          storylineId: storylineId,
          sourceChapterId: text('chapterId'),
          targetChapterId: text('targetChapterId'),
          stepId: text('stepId'),
          targetIndex: _index(p, 'targetIndex', required: true)!)),
      'storyline.milestone.set_archived' => wrapped(
          setStorylineMilestoneArchived(project,
              storylineId: storylineId,
              chapterId: text('chapterId'),
              stepId: text('stepId'),
              archived: _flag(p, 'archived'))),
      'storyline.milestone.attach_scene' => attachSceneToStorylineMilestone(
          project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          stepId: text('stepId'),
          sceneId: text('sceneId')),
      _ => wrapped(detachSceneFromStorylineMilestone(project,
          storylineId: storylineId,
          chapterId: text('chapterId'),
          stepId: text('stepId'),
          sceneId: text('sceneId'))),
    };
    final result = mutation.result;
    if (result.disposition == StorylineMutationDisposition.rejected) {
      throw NarrativeAuthoringException(
        result.code ?? 'storyline.rejected',
        result.message ?? 'The canonical Storyline operation was rejected.',
        details: {'referencePaths': result.referencePaths},
      );
    }
    return _draft(context, mutation, storylineId);
  }

  AuthoringMutationDraft _draft(AuthoringPlanningContext context,
      StorylineMilestoneMutation mutation, String storylineId) {
    final before = context.snapshot.manifest;
    final after = mutation.result.after;
    final detached = [
      for (final location in mutation.detachedFrom) location.toJson()
    ];
    final preview = {
      'storylineId': storylineId,
      'disposition': mutation.result.disposition.name,
      if (mutation.result.chapter case final chapter?) 'chapterId': chapter.id,
      if (mutation.result.step case final step?) 'stepId': step.id,
      if (mutation.fact case final fact?) 'factId': fact.id,
      if (detached.isNotEmpty) 'detachedFrom': detached,
    };
    final base = narrativeProjectDraft(context.snapshot, after,
        operation: context.request.actionId,
        path: '/storylines/$storylineId',
        preview: preview);
    final resource = base.changeSet.diff.entries.first.resource;
    final entries = [
      for (final (field, previous, next) in [
        (
          'storylines',
          {for (final item in before.storylines) item.id: item.toJson()},
          {for (final item in after.storylines) item.id: item.toJson()}
        ),
        (
          'facts',
          {for (final item in before.facts) item.id: item.toJson()},
          {for (final item in after.facts) item.id: item.toJson()}
        ),
      ])
        for (final entry in next.entries)
          if (!_sameJson(previous[entry.key], entry.value))
            AuthoringDiffEntry(
              operation: previous.containsKey(entry.key)
                  ? AuthoringDiffOperation.replace
                  : AuthoringDiffOperation.add,
              resource: resource,
              path: '/$field/${entry.key}',
              before: previous[entry.key],
              after: entry.value,
              extensions: field == 'storylines' &&
                      entry.key == storylineId &&
                      detached.isNotEmpty
                  ? {'detachedFrom': detached}
                  : const {},
            ),
    ];
    if (entries.isEmpty) return base;
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
          changes: base.changeSet.changes, diff: AuthoringDiff(entries)),
      projectedProject: base.projectedProject,
      preview: base.preview,
    );
  }
}

bool _sameJson(Object? left, Object? right) => left == null
    ? right == null
    : canonicalAuthoringJson(left) == canonicalAuthoringJson(right);

int? _index(Map<String, Object?> parameters, String key,
    {bool required = false}) {
  final value = parameters[key];
  if (value == null && !required) return null;
  if (value is! int || value < 0) {
    throw ArgumentError.value(value, key, 'must be a non-negative integer');
  }
  return value;
}

bool _flag(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}
