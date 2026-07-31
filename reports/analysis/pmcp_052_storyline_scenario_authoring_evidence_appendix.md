# PMCP-052 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `lib/src/domains/narrative/scenario_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';
import 'storyline_inspection.dart';

final class ScenarioSimulationTrace {
  ScenarioSimulationTrace({
    required this.scenarioId,
    required Iterable<String> visitedNodeIds,
    required Iterable<Map<String, Object?>> effectPreviews,
    required this.terminated,
    required this.truncated,
  })  : visitedNodeIds = List.unmodifiable(visitedNodeIds),
        effectPreviews = List.unmodifiable(effectPreviews);

  final String scenarioId;
  final List<String> visitedNodeIds;
  final List<Map<String, Object?>> effectPreviews;
  final bool terminated;
  final bool truncated;

  Map<String, Object?> toJson() => {
        'scenarioId': scenarioId,
        'visitedNodeIds': visitedNodeIds,
        'effectPreviews': effectPreviews,
        'terminated': terminated,
        'truncated': truncated,
        'sideEffectsApplied': false,
      };
}

final class ScenarioActions {
  const ScenarioActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      'scenario.upsert',
      'Create or update a validated legacy Scenario',
      resourceKinds: const ['project', 'scenario'],
    ),
    narrativeActionDescriptor(
      'scenario.delete',
      'Delete an unreferenced legacy Scenario',
      resourceKinds: const ['project', 'scenario'],
      risk: AuthoringRiskLevel.high,
    ),
    narrativeActionDescriptor(
      'scenario.migrate_global_story',
      'Import one legacy Global Story without deleting its Scenario',
      resourceKinds: const ['project', 'scenario', 'storyline'],
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    late final ProjectManifest projected;
    late final String scenarioId;
    switch (context.request.actionId) {
      case 'scenario.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'scenario'});
        final scenario = _decodeScenario(
          narrativeObjectParameter(parameters, 'scenario'),
        );
        scenarioId = scenario.id;
        projected = upsert(context.snapshot.manifest, scenario: scenario);
      case 'scenario.delete':
        rejectUnknownNarrativeParameters(parameters, const {'scenarioId'});
        scenarioId = narrativeStringParameter(parameters, 'scenarioId');
        projected = delete(
          context.snapshot.manifest,
          scenarioId: scenarioId,
        );
      case 'scenario.migrate_global_story':
        rejectUnknownNarrativeParameters(parameters, const {'scenarioId'});
        scenarioId = narrativeStringParameter(parameters, 'scenarioId');
        projected = migrateGlobalStory(
          context.snapshot.manifest,
          scenarioId: scenarioId,
        );
      default:
        throw NarrativeAuthoringException(
          'scenario.action_unsupported',
          'The requested Scenario action is unsupported.',
        );
    }
    final before = context.snapshot.manifest.scenarios
        .where((scenario) => scenario.id == scenarioId)
        .firstOrNull;
    final after = projected.scenarios
        .where((scenario) => scenario.id == scenarioId)
        .firstOrNull;
    return narrativeProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/scenarios/$scenarioId',
      before: before?.toJson(),
      after: after?.toJson(),
      preview: {
        'migration': migrationPreviewJson(projected),
        'storylines': const StorylineInspector().inspect(projected).toJson(),
      },
    );
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required ScenarioAsset scenario,
  }) {
    final exists = project.scenarios.any((item) => item.id == scenario.id);
    final projected = project.copyWith(
      scenarios: exists
          ? [
              for (final item in project.scenarios)
                if (item.id == scenario.id) scenario else item,
            ]
          : [...project.scenarios, scenario],
    );
    try {
      ProjectValidator.validate(projected);
    } on Object catch (error) {
      throw NarrativeAuthoringException(
        'scenario.validation_failed',
        'The Scenario would invalidate the project.',
        details: {'validationType': error.runtimeType.toString()},
      );
    }
    return projected;
  }

  ProjectManifest delete(
    ProjectManifest project, {
    required String scenarioId,
  }) {
    if (!project.scenarios.any((item) => item.id == scenarioId)) {
      throw NarrativeAuthoringException(
        'scenario.unknown',
        'The Scenario identity is unknown.',
      );
    }
    final index = buildNarrativeDependencyIndex(project: project);
    final usages = index.usagesFor(
      NarrativeDependencyKey.legacyScenario(scenarioId),
    );
    if (usages.isNotEmpty) {
      throw NarrativeAuthoringException(
        'scenario.references_blocking',
        'The Scenario is still referenced.',
        details: {
          'referencePaths': [for (final usage in usages) usage.path]
        },
      );
    }
    return project.copyWith(
      scenarios: [
        for (final item in project.scenarios)
          if (item.id != scenarioId) item,
      ],
    );
  }

  StorylineLegacyGlobalStoryImportPreview migrationPreview(
    ProjectManifest project,
  ) =>
      buildLegacyGlobalStoryImportPreview(project);

  Map<String, Object?> migrationPreviewJson(ProjectManifest project) {
    final preview = migrationPreview(project);
    return {
      'legacyRemainingCount': preview.legacyRemainingCount,
      'backupRequired': preview.backupRequired,
      'readerRemovalCondition': preview.readerRemovalCondition,
      'hasBlockingIssues': preview.hasBlockingIssues,
      'candidates': [
        for (final candidate in preview.candidates)
          {
            'sourceScenarioId': candidate.sourceScenarioId,
            'sourceScenarioName': candidate.sourceScenarioName,
            'draftStoryline': candidate.draftStoryline.toJson(),
            'issues': [
              for (final issue in candidate.issues)
                {
                  'severity': issue.severity.name,
                  'targetRef': issue.targetRef,
                  'ruleId': issue.ruleId,
                  'message': issue.message,
                },
            ],
          },
      ],
      'issues': [
        for (final issue in preview.issues)
          {
            'severity': issue.severity.name,
            'targetRef': issue.targetRef,
            'ruleId': issue.ruleId,
            'message': issue.message,
          },
      ],
    };
  }

  ProjectManifest migrateGlobalStory(
    ProjectManifest project, {
    required String scenarioId,
  }) {
    final result = applyLegacyGlobalStoryImport(
      project,
      sourceScenarioId: scenarioId,
    );
    if (result.disposition == StorylineLegacyImportDisposition.rejected ||
        result.importedStoryline == null) {
      throw NarrativeAuthoringException(
        result.code ?? 'scenario.migration_rejected',
        result.message ?? 'The Scenario migration was rejected.',
      );
    }
    return result.after;
  }

  ScenarioSimulationTrace simulate(
    ScenarioAsset scenario, {
    int maximumSteps = 256,
  }) {
    if (maximumSteps <= 0) {
      throw ArgumentError.value(maximumSteps, 'maximumSteps');
    }
    final nodes = {for (final node in scenario.nodes) node.id: node};
    final outgoing = <String, List<ScenarioEdge>>{};
    for (final edge in scenario.edges) {
      outgoing.putIfAbsent(edge.fromNodeId, () => []).add(edge);
    }
    for (final edges in outgoing.values) {
      edges.sort((left, right) {
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    }
    final visited = <String>[];
    final effects = <Map<String, Object?>>[];
    var currentId = scenario.entryNodeId;
    var terminated = false;
    var truncated = false;
    for (var step = 0; step < maximumSteps; step++) {
      final node = nodes[currentId];
      if (node == null) break;
      visited.add(node.id);
      if (node.payload.actionKind != null) {
        effects.add({
          'nodeId': node.id,
          'actionKind': node.payload.actionKind,
          'binding': node.binding.toJson(),
          'params': node.payload.params,
        });
      }
      if (node.type == ScenarioNodeType.end) {
        terminated = true;
        break;
      }
      final edges = outgoing[node.id] ?? const <ScenarioEdge>[];
      if (edges.isEmpty) break;
      currentId = edges.first.toNodeId;
      if (step == maximumSteps - 1) truncated = true;
    }
    return ScenarioSimulationTrace(
      scenarioId: scenario.id,
      visitedNodeIds: visited,
      effectPreviews: effects,
      terminated: terminated,
      truncated: truncated,
    );
  }
}

ScenarioAsset _decodeScenario(Map<String, dynamic> json) {
  try {
    return ScenarioAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scenario.invalid',
      'The Scenario payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}
```

## `lib/src/domains/narrative/storyline_actions.dart`

```dart
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
```

## `lib/src/domains/narrative/storyline_inspection.dart`

```dart
import 'package:map_core/map_core.dart';

enum StorylineInspectionSeverity { error, warning, info }

final class StorylineInspectionDiagnostic {
  const StorylineInspectionDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.storylineId,
    this.nodeId,
    this.edgeId,
  });

  final String code;
  final StorylineInspectionSeverity severity;
  final String message;
  final String storylineId;
  final String? nodeId;
  final String? edgeId;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'storylineId': storylineId,
        if (nodeId != null) 'nodeId': nodeId,
        if (edgeId != null) 'edgeId': edgeId,
      };
}

final class StorylineInspectionReport {
  StorylineInspectionReport({
    required Iterable<StorylineInspectionDiagnostic> diagnostics,
    required Map<String, Map<String, Object?>> progression,
  })  : diagnostics = List.unmodifiable(diagnostics),
        progression = Map.unmodifiable(progression);

  final List<StorylineInspectionDiagnostic> diagnostics;
  final Map<String, Map<String, Object?>> progression;

  bool get canPublish => diagnostics.every(
        (item) => item.severity != StorylineInspectionSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'canPublish': canPublish,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
        'progression': progression,
      };
}

/// Read-only Storyline graph inspection backed by the canonical projection.
final class StorylineInspector {
  const StorylineInspector();

  StorylineInspectionReport inspect(ProjectManifest project) {
    final diagnostics = <StorylineInspectionDiagnostic>[];
    final progression = <String, Map<String, Object?>>{};
    for (final storyline in project.storylines) {
      final projection = buildStorylineProgressionProjection(
        project: project,
        storylineId: storyline.id,
      );
      for (final item in projection.diagnostics) {
        diagnostics.add(
          StorylineInspectionDiagnostic(
            code: item.code.name,
            severity: StorylineInspectionSeverity.error,
            message: item.message,
            storylineId: storyline.id,
            nodeId: item.nodeId,
            edgeId: item.edgeId,
          ),
        );
      }
      final unreachable = _unreachableStepIds(storyline, projection);
      for (final stepId in unreachable) {
        diagnostics.add(
          StorylineInspectionDiagnostic(
            code: 'unreachableStep',
            severity: StorylineInspectionSeverity.warning,
            message: 'The Step is not reachable from the first authored Step.',
            storylineId: storyline.id,
            nodeId: 'step:$stepId',
          ),
        );
      }
      progression[storyline.id] = {
        'status': storyline.status.name,
        'available': storyline.status == StorylineStatus.active,
        'chapterCount': storyline.chapters.length,
        'stepCount': storyline.chapters
            .fold<int>(0, (count, chapter) => count + chapter.steps.length),
        'edgeCount': projection.edges.length,
        'unreachableStepIds': unreachable,
        'completionPreview': {
          'hasCompletionConditions': storyline.chapters.any(
            (chapter) => chapter.steps.any(
              (step) => step.completionCondition != null,
            ),
          ),
          'requiresRuntimeState': true,
        },
      };
    }
    diagnostics.sort((left, right) {
      final story = left.storylineId.compareTo(right.storylineId);
      if (story != 0) return story;
      return left.code.compareTo(right.code);
    });
    return StorylineInspectionReport(
      diagnostics: diagnostics,
      progression: progression,
    );
  }
}

List<String> _unreachableStepIds(
  StorylineAsset storyline,
  StorylineProgressionProjection projection,
) {
  final chapters = storyline.chapters.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  final firstChapterWithSteps = chapters.where((item) => item.steps.isNotEmpty);
  if (firstChapterWithSteps.isEmpty) return const [];
  final firstSteps = firstChapterWithSteps.first.steps.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  final reachable = <String>{'step:${firstSteps.first.id}'};
  var changed = true;
  while (changed) {
    changed = false;
    for (final edge in projection.edges) {
      if (!reachable.contains(edge.fromNodeId) ||
          !edge.toNodeId.startsWith('step:')) {
        continue;
      }
      if (reachable.add(edge.toNodeId)) changed = true;
    }
  }
  final ids = <String>[
    for (final chapter in chapters)
      for (final step in chapter.steps)
        if (!reachable.contains('step:${step.id}')) step.id,
  ]..sort();
  return ids;
}
```

## `test/domains/narrative/storyline_scenario_authoring_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Storyline and Scenario authoring', () {
    test('chapter and step reorder preserves every stable identity', () {
      final project = _manifest(storylines: [_storyline()]);
      final chapters = project.storylines.single.chapters;
      final reorderedChapters = const StorylineActions().reorderChapters(
        project,
        storylineId: 'story_main',
        orderedChapterIds: const ['chapter_two', 'chapter_one'],
      );
      final reorderedSteps = const StorylineActions().reorderSteps(
        reorderedChapters,
        storylineId: 'story_main',
        chapterId: 'chapter_one',
        orderedStepIds: const ['step_two', 'step_one'],
      );

      expect(
        reorderedSteps.storylines.single.chapters.map((chapter) => chapter.id),
        ['chapter_two', 'chapter_one'],
      );
      expect(
        reorderedSteps.storylines.single.chapters
            .singleWhere((chapter) => chapter.id == 'chapter_one')
            .steps
            .map((step) => step.id),
        ['step_two', 'step_one'],
      );
      expect(
        reorderedSteps.storylines.single.chapters
            .expand((chapter) => chapter.steps)
            .map((step) => step.id)
            .toSet(),
        chapters
            .expand((chapter) => chapter.steps)
            .map((step) => step.id)
            .toSet(),
      );
    });

    test('canonical progression projection exposes relationship cycles', () {
      final main = StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main',
        relationships: [
          StorylineRelationship(
            id: 'main_requires_side',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story_main',
            targetStorylineId: 'story_side',
          ),
        ],
      );
      final side = StorylineAsset(
        id: 'story_side',
        type: StorylineType.sideQuest,
        title: 'Side',
        relationships: [
          StorylineRelationship(
            id: 'side_requires_main',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story_side',
            targetStorylineId: 'story_main',
          ),
        ],
      );

      final report = const StorylineInspector().inspect(
        _manifest(storylines: [main, side]),
      );

      expect(
        report.diagnostics.map((item) => item.code),
        contains('cycleDetected'),
      );
      expect(report.canPublish, isFalse);
    });

    test('legacy migration preview and apply preserve readable Scenario', () {
      final legacy = ScenarioAsset(
        id: 'legacy_main',
        name: 'Legacy main',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: const [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final project = _manifest(scenarios: [legacy]);
      final preview = const ScenarioActions().migrationPreview(project);
      final migrated = const ScenarioActions().migrateGlobalStory(
        project,
        scenarioId: legacy.id,
      );

      expect(preview.candidates.single.sourceScenarioId, legacy.id);
      expect(migrated.scenarios.single.toJson(), legacy.toJson());
      expect(migrated.storylines.single.legacySource!.sourceId, legacy.id);
      expect(migrated.storylines.single.legacySource!.metadata['imported'],
          'true');
    });

    test('dispatcher and resource registry expose Storyline and Scenario', () {
      final actionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        actionIds,
        containsAll({
          'storyline.upsert',
          'storyline.delete',
          'storyline.reorder_chapters',
          'storyline.reorder_steps',
          'scenario.upsert',
          'scenario.delete',
          'scenario.migrate_global_story',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        containsAll({'storyline', 'scenario'}),
      );
    });
  });
}

ProjectManifest _manifest({
  List<StorylineAsset> storylines = const [],
  List<ScenarioAsset> scenarios = const [],
}) =>
    ProjectManifest(
      name: 'Storyline fixture',
      maps: const [],
      tilesets: const [],
      storylines: storylines,
      scenarios: scenarios,
    );

StorylineAsset _storyline() => StorylineAsset(
      id: 'story_main',
      type: StorylineType.main,
      title: 'Main',
      chapters: [
        StorylineChapter(
          id: 'chapter_one',
          title: 'One',
          order: 0,
          steps: [
            StorylineStep(id: 'step_one', title: 'One', order: 0),
            StorylineStep(id: 'step_two', title: 'Two', order: 1),
          ],
        ),
        StorylineChapter(
          id: 'chapter_two',
          title: 'Two',
          order: 1,
        ),
      ],
    );
```
