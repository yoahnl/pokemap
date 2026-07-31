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
