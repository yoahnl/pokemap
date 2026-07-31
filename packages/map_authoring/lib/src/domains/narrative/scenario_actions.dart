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
