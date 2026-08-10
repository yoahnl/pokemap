import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class CinematicAuthoringInspection {
  CinematicAuthoringInspection({
    required this.cinematicId,
    required this.canPublish,
    required Iterable<Map<String, Object?>> preflightIssues,
    required Iterable<Map<String, Object?>> previewDiagnostics,
    required this.totalDurationMs,
    required this.executableDurationMs,
  })  : preflightIssues = List.unmodifiable(preflightIssues),
        previewDiagnostics = List.unmodifiable(previewDiagnostics);

  final String cinematicId;
  final bool canPublish;
  final List<Map<String, Object?>> preflightIssues;
  final List<Map<String, Object?>> previewDiagnostics;
  final int totalDurationMs;
  final int executableDurationMs;

  Map<String, Object?> toJson() => {
        'cinematicId': cinematicId,
        'canPublish': canPublish,
        'preflightIssues': preflightIssues,
        'previewDiagnostics': previewDiagnostics,
        'totalDurationMs': totalDurationMs,
        'executableDurationMs': executableDurationMs,
      };
}

/// Shared authoring projection over the same preflight and preview models used
/// by the runtime. It never claims that host-only actor or media availability
/// has been verified.
final class CinematicAuthoringInspector {
  const CinematicAuthoringInspector();

  CinematicAuthoringInspection inspect({
    required ProjectManifest project,
    required CinematicAsset cinematic,
  }) {
    final mapIds = project.maps.map((map) => map.id);
    final preflight = preflightCinematicPlayback(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
      availableMapIds: mapIds,
    );
    final preview = buildCinematicPreviewPlaybackPlan(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
      availableMapIds: mapIds,
    );
    final previewDiagnostics = [
      for (final diagnostic in preview.diagnostics)
        <String, Object?>{
          'code': diagnostic.code.name,
          'severity': diagnostic.severity.name,
          'message': diagnostic.message,
          'blocking': diagnostic.blocking,
          if (diagnostic.stepId != null) 'stepId': diagnostic.stepId,
          if (diagnostic.actorId != null) 'actorId': diagnostic.actorId,
          if (diagnostic.timeMs != null) 'timeMs': diagnostic.timeMs,
        },
    ];
    return CinematicAuthoringInspection(
      cinematicId: cinematic.id,
      canPublish: preflight.isReady &&
          previewDiagnostics
              .every((diagnostic) => diagnostic['blocking'] != true),
      preflightIssues: [
        for (final issue in preflight.issues)
          <String, Object?>{
            'kind': issue.kind.name,
            'message': issue.message,
            if (issue.stepId != null) 'stepId': issue.stepId,
            if (issue.referenceId != null) 'referenceId': issue.referenceId,
          },
      ],
      previewDiagnostics: previewDiagnostics,
      totalDurationMs: preview.totalDurationMs,
      executableDurationMs: preview.executableDurationMs,
    );
  }
}

final class CinematicActions {
  const CinematicActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      'cinematic.upsert',
      'Create or update a cinematic and its stage timeline',
      resourceKinds: const ['project', 'cinematic'],
    ),
    narrativeActionDescriptor(
      'cinematic.delete',
      'Delete an unreferenced cinematic',
      resourceKinds: const ['project', 'cinematic'],
      risk: AuthoringRiskLevel.high,
    ),
    for (final entry in const [
      (
        'cinematic.timeline_move',
        'Move timeline steps without changing identities'
      ),
      ('cinematic.timeline_duplicate', 'Duplicate selected timeline steps'),
      ('cinematic.timeline_paste', 'Paste a versioned timeline clipboard'),
      ('cinematic.timeline_delete', 'Delete selected timeline steps'),
    ])
      narrativeActionDescriptor(
        entry.$1,
        entry.$2,
        resourceKinds: const ['project', 'cinematic'],
        risk: entry.$1.endsWith('_delete')
            ? AuthoringRiskLevel.high
            : AuthoringRiskLevel.medium,
      ),
    narrativeActionDescriptor(
      'cinematic.character_animation.upsert',
      'Add or update one bounded Character Studio animation timeline step',
      resourceKinds: const ['project', 'cinematic'],
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    late final ProjectManifest projected;
    late final String cinematicId;
    switch (context.request.actionId) {
      case 'cinematic.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'cinematic'});
        final cinematic = _decodeCinematic(
          narrativeObjectParameter(parameters, 'cinematic'),
        );
        cinematicId = cinematic.id;
        projected = upsert(context.snapshot.manifest, cinematic: cinematic);
      case 'cinematic.delete':
        rejectUnknownNarrativeParameters(parameters, const {'cinematicId'});
        cinematicId = narrativeStringParameter(parameters, 'cinematicId');
        projected = delete(
          context.snapshot.manifest,
          cinematicId: cinematicId,
        );
      case 'cinematic.timeline_move':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'cinematicId', 'stepIds', 'insertionIndex'},
        );
        cinematicId = narrativeStringParameter(parameters, 'cinematicId');
        projected = moveTimelineSteps(
          context.snapshot.manifest,
          cinematicId: cinematicId,
          stepIds: _stringSet(parameters, 'stepIds'),
          insertionIndex: _integer(parameters, 'insertionIndex'),
        );
      case 'cinematic.timeline_duplicate':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'cinematicId', 'stepIds'},
        );
        cinematicId = narrativeStringParameter(parameters, 'cinematicId');
        projected = duplicateTimelineSteps(
          context.snapshot.manifest,
          cinematicId: cinematicId,
          stepIds: _stringSet(parameters, 'stepIds'),
        );
      case 'cinematic.timeline_paste':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'cinematicId', 'clipboard', 'insertionIndex'},
        );
        cinematicId = narrativeStringParameter(parameters, 'cinematicId');
        projected = pasteTimelineSteps(
          context.snapshot.manifest,
          cinematicId: cinematicId,
          clipboard: CinematicTimelineClipboard.fromJson(
            narrativeObjectParameter(parameters, 'clipboard'),
          ),
          insertionIndex: _integer(parameters, 'insertionIndex'),
        );
      case 'cinematic.timeline_delete':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'cinematicId', 'stepIds'},
        );
        cinematicId = narrativeStringParameter(parameters, 'cinematicId');
        projected = deleteTimelineSteps(
          context.snapshot.manifest,
          cinematicId: cinematicId,
          stepIds: _stringSet(parameters, 'stepIds'),
        );
      case 'cinematic.character_animation.upsert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'cinematicId',
            'stepId',
            'afterStepId',
            'label',
            'runtimeCommand',
          },
        );
        cinematicId = narrativeStringParameter(parameters, 'cinematicId');
        projected = upsertCharacterAnimationStep(
          context.snapshot.manifest,
          cinematicId: cinematicId,
          stepId: _optionalTrimmedString(parameters, 'stepId'),
          afterStepId: _optionalTrimmedString(parameters, 'afterStepId'),
          label: _optionalTrimmedString(parameters, 'label'),
          command: _decodeCharacterAnimationCommand(
            narrativeObjectParameter(parameters, 'runtimeCommand'),
          ),
        );
      default:
        throw NarrativeAuthoringException(
          'cinematic.action_unsupported',
          'The requested cinematic action is unsupported.',
        );
    }
    final before = _findCinematic(context.snapshot.manifest, cinematicId);
    final after = _findCinematic(projected, cinematicId);
    return narrativeProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/cinematics/$cinematicId',
      before: before?.toJson(),
      after: after?.toJson(),
      preview: after == null
          ? {'cinematicId': cinematicId, 'deleted': true}
          : const CinematicAuthoringInspector()
              .inspect(project: projected, cinematic: after)
              .toJson(),
    );
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required CinematicAsset cinematic,
  }) =>
      (project.cinematics.any((item) => item.id == cinematic.id)
              ? updateCinematicAsset(project, cinematic)
              : addCinematicAsset(project, cinematic))
          .updatedProject;

  ProjectManifest delete(
    ProjectManifest project, {
    required String cinematicId,
  }) =>
      removeCinematicAsset(project, cinematicId).updatedProject;

  CinematicTimelineClipboard copyTimelineSteps(
    ProjectManifest project, {
    required String cinematicId,
    required Set<String> stepIds,
  }) =>
      copyCinematicTimelineSteps(
        _requireCinematic(project, cinematicId),
        stepIds: stepIds,
      );

  ProjectManifest moveTimelineSteps(
    ProjectManifest project, {
    required String cinematicId,
    required Set<String> stepIds,
    required int insertionIndex,
  }) =>
      _replaceTimelineEdit(
        project,
        moveCinematicTimelineSteps(
          _requireCinematic(project, cinematicId),
          stepIds: stepIds,
          insertionIndex: insertionIndex,
        ),
      );

  ProjectManifest duplicateTimelineSteps(
    ProjectManifest project, {
    required String cinematicId,
    required Set<String> stepIds,
  }) =>
      _replaceTimelineEdit(
        project,
        duplicateCinematicTimelineSteps(
          _requireCinematic(project, cinematicId),
          stepIds: stepIds,
        ),
      );

  ProjectManifest pasteTimelineSteps(
    ProjectManifest project, {
    required String cinematicId,
    required CinematicTimelineClipboard clipboard,
    required int insertionIndex,
  }) =>
      _replaceTimelineEdit(
        project,
        pasteCinematicTimelineSteps(
          _requireCinematic(project, cinematicId),
          clipboard: clipboard,
          insertionIndex: insertionIndex,
        ),
      );

  ProjectManifest deleteTimelineSteps(
    ProjectManifest project, {
    required String cinematicId,
    required Set<String> stepIds,
  }) =>
      _replaceTimelineEdit(
        project,
        deleteCinematicTimelineSteps(
          _requireCinematic(project, cinematicId),
          stepIds: stepIds,
        ),
      );

  ProjectManifest upsertCharacterAnimationStep(
    ProjectManifest project, {
    required String cinematicId,
    required CharacterCustomAnimationRuntimeCommand command,
    String? stepId,
    String? afterStepId,
    String? label,
  }) {
    final cinematic = _requireCinematic(project, cinematicId);
    _validateCharacterAnimationCommand(
      project,
      command,
      actorIds: cinematic.requiredActors.map((actor) => actor.actorId).toSet(),
    );
    final steps = cinematic.timeline.steps.toList();
    final targetId = stepId ?? _nextCharacterAnimationStepId(cinematic);
    final existingIndex = steps.indexWhere((step) => step.id == targetId);
    if (existingIndex >= 0 &&
        steps[existingIndex].kind != CinematicTimelineStepKind.actorAnimation) {
      throw NarrativeAuthoringException(
        'cinematic.character_animation.step_kind_mismatch',
        'The selected timeline step is not a character animation.',
        details: <String, Object?>{'stepId': targetId},
      );
    }
    final step = buildCinematicCharacterCustomAnimationStep(
      id: targetId,
      command: command,
      label: label,
    );
    if (existingIndex >= 0) {
      steps[existingIndex] = step;
    } else if (afterStepId == null) {
      steps.add(step);
    } else {
      final insertionIndex = steps.indexWhere((item) => item.id == afterStepId);
      if (insertionIndex < 0) {
        throw NarrativeAuthoringException(
          'cinematic.character_animation.after_step_unknown',
          'The requested insertion anchor does not exist.',
          details: <String, Object?>{'afterStepId': afterStepId},
        );
      }
      steps.insert(insertionIndex + 1, step);
    }
    return updateCinematicAsset(
      project,
      cinematic.copyWith(timeline: CinematicTimeline(steps: steps)),
    ).updatedProject;
  }
}

ProjectManifest _replaceTimelineEdit(
  ProjectManifest project,
  CinematicTimelineEditResult edit,
) =>
    updateCinematicAsset(project, edit.cinematic).updatedProject;

CinematicAsset _requireCinematic(ProjectManifest project, String id) =>
    _findCinematic(project, id) ??
    (throw NarrativeAuthoringException(
      'cinematic.unknown',
      'The cinematic identity is unknown.',
      details: {'cinematicId': id},
    ));

CinematicAsset? _findCinematic(ProjectManifest project, String id) {
  for (final cinematic in project.cinematics) {
    if (cinematic.id == id) return cinematic;
  }
  return null;
}

CinematicAsset _decodeCinematic(Map<String, dynamic> json) {
  try {
    return CinematicAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'cinematic.invalid',
      'The cinematic payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

Set<String> _stringSet(Map<String, Object?> parameters, String key) {
  final raw = parameters[key];
  if (raw is! List || raw.isEmpty || raw.any((item) => item is! String)) {
    throw ArgumentError.value(raw, key, 'must be a non-empty string list');
  }
  return Set<String>.from(raw);
}

int _integer(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! int) {
    throw ArgumentError.value(value, key, 'must be an integer');
  }
  return value;
}

String? _optionalTrimmedString(
  Map<String, Object?> parameters,
  String key,
) {
  final value = parameters[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be a nonblank trimmed string');
  }
  return value;
}

CharacterCustomAnimationRuntimeCommand _decodeCharacterAnimationCommand(
  Map<String, dynamic> json,
) {
  try {
    return CharacterCustomAnimationRuntimeCommand.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'character_animation.command_invalid',
      'The Character Studio animation command cannot be decoded.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

void _validateCharacterAnimationCommand(
  ProjectManifest project,
  CharacterCustomAnimationRuntimeCommand command, {
  Set<String>? actorIds,
}) {
  if (actorIds != null && !actorIds.contains(command.actorId)) {
    throw NarrativeAuthoringException(
      'character_animation.actor_unknown',
      'The selected actor is not available in this narrative asset.',
      details: <String, Object?>{'actorId': command.actorId},
    );
  }
  CharacterCustomAnimationDefinition? definition;
  for (final candidate
      in project.characterStudioCatalog.customAnimationDefinitions) {
    if (candidate.id == command.definitionId) {
      definition = candidate;
      break;
    }
  }
  if (definition == null) {
    throw NarrativeAuthoringException(
      'character_animation.definition_unknown',
      'The selected custom animation definition does not exist.',
      details: <String, Object?>{'definitionId': command.definitionId},
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.single &&
      command.direction != null) {
    throw NarrativeAuthoringException(
      'character_animation.direction_unexpected',
      'A single custom animation does not accept a direction.',
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.directional &&
      command.direction == null) {
    throw NarrativeAuthoringException(
      'character_animation.direction_required',
      'A directional custom animation requires a direction.',
    );
  }
}

String _nextCharacterAnimationStepId(CinematicAsset cinematic) {
  final used = cinematic.timeline.steps.map((step) => step.id).toSet();
  var suffix = 1;
  while (used.contains('step_character_animation_$suffix')) {
    suffix += 1;
  }
  return 'step_character_animation_$suffix';
}
