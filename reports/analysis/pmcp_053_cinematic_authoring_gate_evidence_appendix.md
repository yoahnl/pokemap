# PMCP-053 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/domains/narrative/cinematic_actions.dart`

```dart
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
```
## `packages/map_authoring/lib/src/domains/narrative/narrative_parity_gate.dart`

```dart
import 'package:map_core/map_core.dart';

enum NarrativeParityStatus { supported, partial, unsupported }

final class NarrativeParityEntry {
  const NarrativeParityEntry({
    required this.domain,
    required this.featureId,
    required this.editorSurface,
    required this.apiActionOrRead,
    required this.runtimeAuthority,
    required this.status,
    this.limitations = const [],
  });

  final String domain;
  final String featureId;
  final String editorSurface;
  final String apiActionOrRead;
  final String runtimeAuthority;
  final NarrativeParityStatus status;
  final List<String> limitations;

  Map<String, Object?> toJson() => {
        'domain': domain,
        'featureId': featureId,
        'editorSurface': editorSurface,
        'apiActionOrRead': apiActionOrRead,
        'runtimeAuthority': runtimeAuthority,
        'status': status.name,
        'limitations': limitations,
      };
}

final class NarrativeParityReport {
  NarrativeParityReport({
    required Iterable<NarrativeParityEntry> entries,
    required this.projectCinematicCount,
  }) : entries = List.unmodifiable(entries);

  final List<NarrativeParityEntry> entries;
  final int projectCinematicCount;

  bool get hasUnsupportedFeatures =>
      entries.any((entry) => entry.status == NarrativeParityStatus.unsupported);

  Map<String, Object?> toJson() => {
        'projectCinematicCount': projectCinematicCount,
        'hasUnsupportedFeatures': hasUnsupportedFeatures,
        'entries': [for (final entry in entries) entry.toJson()],
      };
}

/// Explicit editor/API/runtime truth table. Entries marked partial expose their
/// limits instead of treating authorability as proof of runtime support.
final class NarrativeParityGate {
  const NarrativeParityGate();

  NarrativeParityReport inspect(ProjectManifest project) {
    final entries = <NarrativeParityEntry>[
      const NarrativeParityEntry(
        domain: 'dialogue',
        featureId: 'yarn_subset',
        editorSurface: 'Dialogue authoring',
        apiActionOrRead: 'dialogue.* / dialogue',
        runtimeAuthority: 'RuntimeDialogueDocument + YarnDialogueCompiler',
        status: NarrativeParityStatus.partial,
        limitations: ['Only the documented deterministic Yarn subset runs.'],
      ),
      const NarrativeParityEntry(
        domain: 'script',
        featureId: 'deterministic_commands',
        editorSurface: 'Script authoring and simulation',
        apiActionOrRead: 'script.* / script',
        runtimeAuthority: 'NarrativeCommandRuntimeExecutor',
        status: NarrativeParityStatus.partial,
        limitations: [
          'Simulation is side-effect free and host ports stay runtime-owned.'
        ],
      ),
      const NarrativeParityEntry(
        domain: 'scene',
        featureId: 'graph_execution',
        editorSurface: 'Scene graph authoring',
        apiActionOrRead: 'scene.* / scene',
        runtimeAuthority: 'buildSceneRuntimePlan',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'event_v2',
        featureId: 'dispatch',
        editorSurface: 'Event V2 lifecycle',
        apiActionOrRead: 'event_v2.* / eventV2',
        runtimeAuthority: 'NarrativeEventDispatchAuthority',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'fact',
        featureId: 'typed_resolution',
        editorSurface: 'Fact authoring',
        apiActionOrRead: 'fact.* / fact',
        runtimeAuthority: 'NarrativeFactRuntimeResolver',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'world_rule',
        featureId: 'effect_projection',
        editorSurface: 'World Rule authoring',
        apiActionOrRead: 'world_rule.* / worldRule',
        runtimeAuthority: 'projectWorldRuleEffects',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'storyline',
        featureId: 'progression_projection',
        editorSurface: 'Storyline graph authoring',
        apiActionOrRead: 'storyline.* / storyline',
        runtimeAuthority: 'StorylineRuntimeProjection',
        status: NarrativeParityStatus.partial,
        limitations: [
          'The projection is canonical; orchestration remains host-owned.'
        ],
      ),
      const NarrativeParityEntry(
        domain: 'scenario',
        featureId: 'legacy_execution',
        editorSurface: 'Scenario compatibility authoring',
        apiActionOrRead: 'scenario.* / scenario',
        runtimeAuthority: 'ScenarioRuntimeExecutor',
        status: NarrativeParityStatus.supported,
      ),
      for (final kind in CinematicTimelineStepKind.values)
        NarrativeParityEntry(
          domain: 'cinematic.timeline',
          featureId: kind.name,
          editorSurface: 'Cinematic timeline',
          apiActionOrRead: 'cinematic.* / cinematic',
          runtimeAuthority:
              'CinematicRuntimePlaybackController + FlameCinematicRuntimePlaybackSink',
          status: NarrativeParityStatus.supported,
          limitations: const [
            'Concrete actor, active-map, and media availability is checked by runtime preflight.',
          ],
        ),
    ];
    return NarrativeParityReport(
      entries: entries,
      projectCinematicCount: project.cinematics.length,
    );
  }
}
```

## `packages/map_authoring/test/domains/narrative/cinematic_authoring_gate_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('cinematic authoring and narrative parity', () {
    test('all twelve timeline kinds have an explicit runtime consumer truth',
        () {
      final gate = const NarrativeParityGate().inspect(_manifest());
      final cinematicEntries = gate.entries
          .where((entry) => entry.domain == 'cinematic.timeline')
          .toList();

      expect(
          cinematicEntries, hasLength(CinematicTimelineStepKind.values.length));
      expect(
        cinematicEntries.map((entry) => entry.featureId).toSet(),
        CinematicTimelineStepKind.values.map((kind) => kind.name).toSet(),
      );
      expect(
        cinematicEntries.every((entry) => entry.runtimeAuthority.isNotEmpty),
        isTrue,
      );
    });

    test('missing dialogue is an explicit blocking preflight issue', () {
      final cinematic = CinematicAsset(
        id: 'cine_intro',
        title: 'Intro',
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              assetRef: 'missing_dialogue',
              durationMs: 500,
            ),
          ],
        ),
      );

      final report = const CinematicAuthoringInspector().inspect(
        project: _manifest(cinematics: [cinematic]),
        cinematic: cinematic,
      );

      expect(report.canPublish, isFalse);
      expect(
        report.preflightIssues.map((issue) => issue['kind']),
        contains('missingDialogue'),
      );
    });

    test('timeline move keeps selected identities and relative order', () {
      final cinematic = _cinematic();
      final project = _manifest(cinematics: [cinematic]);

      final moved = const CinematicActions().moveTimelineSteps(
        project,
        cinematicId: cinematic.id,
        stepIds: const {'wait', 'fade'},
        insertionIndex: 3,
      );

      expect(
        moved.cinematics.single.timeline.steps.map((step) => step.id),
        ['camera', 'wait', 'fade'],
      );
    });

    test('dispatcher and resource registry expose cinematic authoring', () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        ids,
        containsAll({
          'cinematic.upsert',
          'cinematic.delete',
          'cinematic.timeline_move',
          'cinematic.timeline_duplicate',
          'cinematic.timeline_paste',
          'cinematic.timeline_delete',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        contains('cinematic'),
      );
    });
  });
}

ProjectManifest _manifest({List<CinematicAsset> cinematics = const []}) =>
    ProjectManifest(
      name: 'Cinematic fixture',
      maps: const [],
      tilesets: const [],
      cinematics: cinematics,
    );

CinematicAsset _cinematic() => CinematicAsset(
      id: 'cine_timeline',
      title: 'Timeline',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'wait',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 100,
          ),
          CinematicTimelineStep(
            id: 'camera',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 100,
          ),
          CinematicTimelineStep(
            id: 'fade',
            kind: CinematicTimelineStepKind.fade,
            durationMs: 100,
          ),
        ],
      ),
    );
```

## `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_preview_adapter.dart`

```dart
import 'package:map_core/map_core.dart';

final class CinematicRuntimePreview {
  CinematicRuntimePreview({
    required this.cinematicId,
    required this.canStart,
    required Iterable<Map<String, Object?>> preflightIssues,
    required Iterable<String> timelineKinds,
    required this.totalDurationMs,
    required this.executableDurationMs,
    required Iterable<String> hostLimitations,
  })  : preflightIssues = List.unmodifiable(preflightIssues),
        timelineKinds = List.unmodifiable(timelineKinds),
        hostLimitations = List.unmodifiable(hostLimitations);

  final String cinematicId;
  final bool canStart;
  final List<Map<String, Object?>> preflightIssues;
  final List<String> timelineKinds;
  final int totalDurationMs;
  final int executableDurationMs;
  final List<String> hostLimitations;

  Map<String, Object?> toJson() => {
        'cinematicId': cinematicId,
        'canStart': canStart,
        'preflightIssues': preflightIssues,
        'timelineKinds': timelineKinds,
        'totalDurationMs': totalDurationMs,
        'executableDurationMs': executableDurationMs,
        'hostLimitations': hostLimitations,
      };
}

/// Read-only runtime projection for API/editor previews. Structural checks are
/// shared with live playback; mounted actor handles and decoded media remain
/// host-owned and are deliberately reported as limitations.
final class CinematicRuntimePreviewAdapter {
  const CinematicRuntimePreviewAdapter();

  CinematicRuntimePreview inspect({
    required ProjectManifest project,
    required CinematicAsset cinematic,
    String? activeMapId,
  }) {
    final mapIds = project.maps.map((map) => map.id);
    final preflight = preflightCinematicPlayback(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
      availableMapIds: mapIds,
      activeMapId: activeMapId,
      mode: CinematicPlaybackPreflightMode.runtime,
    );
    final plan = buildCinematicPreviewPlaybackPlan(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
      availableMapIds: mapIds,
    );
    return CinematicRuntimePreview(
      cinematicId: cinematic.id,
      canStart: preflight.isReady &&
          plan.diagnostics.every((diagnostic) => !diagnostic.blocking),
      preflightIssues: [
        for (final issue in preflight.issues)
          <String, Object?>{
            'kind': issue.kind.name,
            'message': issue.message,
            if (issue.stepId != null) 'stepId': issue.stepId,
            if (issue.referenceId != null) 'referenceId': issue.referenceId,
          },
      ],
      timelineKinds: [
        for (final step in cinematic.timeline.steps) step.kind.name,
      ],
      totalDurationMs: plan.totalDurationMs,
      executableDurationMs: plan.executableDurationMs,
      hostLimitations: const [
        'Mounted Flame actor handles are verified only by the playback sink.',
        'Media decoding and device audio availability are host responsibilities.',
        'Preview inspection does not execute commands or mutate runtime state.',
      ],
    );
  }
}
```

## `packages/map_runtime/test/cinematic_runtime_preview_adapter_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime preview blocks references unavailable to the runtime', () {
    final cinematic = CinematicAsset(
      id: 'intro',
      title: 'Intro',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'line',
            kind: CinematicTimelineStepKind.dialogueLine,
            assetRef: 'missing_dialogue',
            durationMs: 250,
          ),
        ],
      ),
    );
    final project = ProjectManifest(
      name: 'Runtime preview',
      maps: const [],
      tilesets: const [],
      cinematics: [cinematic],
    );

    final preview = const CinematicRuntimePreviewAdapter().inspect(
      project: project,
      cinematic: cinematic,
    );

    expect(preview.canStart, isFalse);
    expect(
      preview.preflightIssues.map((issue) => issue['kind']),
      contains('missingDialogue'),
    );
    expect(preview.timelineKinds, ['dialogueLine']);
    expect(preview.hostLimitations, isNotEmpty);
  });
}
```
