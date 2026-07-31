import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';
import 'storyline_inspection.dart';

final class StorylineActions {
  const StorylineActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      'storyline.upsert',
      'Create or update a Storyline aggregate',
      resourceKinds: const ['project', 'storyline'],
    ),
    narrativeActionDescriptor(
      'storyline.delete',
      'Delete an unreferenced Storyline',
      resourceKinds: const ['project', 'storyline'],
      risk: AuthoringRiskLevel.high,
    ),
    narrativeActionDescriptor(
      'storyline.reorder_chapters',
      'Reorder Chapters without changing identities',
      resourceKinds: const ['project', 'storyline'],
    ),
    narrativeActionDescriptor(
      'storyline.reorder_steps',
      'Reorder Steps without changing identities',
      resourceKinds: const ['project', 'storyline'],
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    late final ProjectManifest projected;
    late final String storylineId;
    switch (context.request.actionId) {
      case 'storyline.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'storyline'});
        final storyline = _decodeStoryline(
          narrativeObjectParameter(parameters, 'storyline'),
        );
        storylineId = storyline.id;
        projected = upsert(context.snapshot.manifest, storyline: storyline);
      case 'storyline.delete':
        rejectUnknownNarrativeParameters(parameters, const {'storylineId'});
        storylineId = narrativeStringParameter(parameters, 'storylineId');
        projected = delete(
          context.snapshot.manifest,
          storylineId: storylineId,
        );
      case 'storyline.reorder_chapters':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'storylineId', 'orderedChapterIds'},
        );
        storylineId = narrativeStringParameter(parameters, 'storylineId');
        projected = reorderChapters(
          context.snapshot.manifest,
          storylineId: storylineId,
          orderedChapterIds: _stringList(parameters, 'orderedChapterIds'),
        );
      case 'storyline.reorder_steps':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'storylineId', 'chapterId', 'orderedStepIds'},
        );
        storylineId = narrativeStringParameter(parameters, 'storylineId');
        projected = reorderSteps(
          context.snapshot.manifest,
          storylineId: storylineId,
          chapterId: narrativeStringParameter(parameters, 'chapterId'),
          orderedStepIds: _stringList(parameters, 'orderedStepIds'),
        );
      default:
        throw NarrativeAuthoringException(
          'storyline.action_unsupported',
          'The requested Storyline action is unsupported.',
        );
    }
    final before = context.snapshot.manifest.storylines
        .where((storyline) => storyline.id == storylineId)
        .firstOrNull;
    final after = projected.storylines
        .where((storyline) => storyline.id == storylineId)
        .firstOrNull;
    return narrativeProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/storylines/$storylineId',
      before: before?.toJson(),
      after: after?.toJson(),
      preview: const StorylineInspector().inspect(projected).toJson(),
    );
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required StorylineAsset storyline,
  }) {
    final existing = project.storylines.any((item) => item.id == storyline.id);
    return _requireApplied(
      existing
          ? updateStoryline(
              project,
              storylineId: storyline.id,
              storyline: storyline,
            )
          : createStoryline(project, storyline: storyline),
      allowNoChange: true,
    );
  }

  ProjectManifest delete(
    ProjectManifest project, {
    required String storylineId,
  }) =>
      _requireApplied(
        deleteStoryline(project, storylineId: storylineId),
      );

  ProjectManifest reorderChapters(
    ProjectManifest project, {
    required String storylineId,
    required List<String> orderedChapterIds,
  }) =>
      _requireApplied(
        reorderStorylineChapters(
          project,
          storylineId: storylineId,
          orderedChapterIds: orderedChapterIds,
        ),
        allowNoChange: true,
      );

  ProjectManifest reorderSteps(
    ProjectManifest project, {
    required String storylineId,
    required String chapterId,
    required List<String> orderedStepIds,
  }) =>
      _requireApplied(
        reorderStorylineSteps(
          project,
          storylineId: storylineId,
          chapterId: chapterId,
          orderedStepIds: orderedStepIds,
        ),
        allowNoChange: true,
      );
}

ProjectManifest _requireApplied(
  StorylineMutationResult result, {
  bool allowNoChange = false,
}) {
  if (result.isApplied ||
      allowNoChange &&
          result.disposition == StorylineMutationDisposition.noChange) {
    return result.after;
  }
  throw NarrativeAuthoringException(
    result.code ?? 'storyline.rejected',
    result.message ?? 'The canonical Storyline operation was rejected.',
    details: {'referencePaths': result.referencePaths},
  );
}

StorylineAsset _decodeStoryline(Map<String, dynamic> json) {
  try {
    return StorylineAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'storyline.invalid',
      'The Storyline payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

List<String> _stringList(Map<String, Object?> parameters, String key) {
  final raw = parameters[key];
  if (raw is! List || raw.any((item) => item is! String)) {
    throw ArgumentError.value(raw, key, 'must be a string list');
  }
  return List<String>.from(raw);
}
