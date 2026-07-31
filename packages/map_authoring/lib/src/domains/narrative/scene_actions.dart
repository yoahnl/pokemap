import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'modern_narrative_inspection.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class SceneActions {
  const SceneActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      'scene.upsert',
      'Create or replace a complete Scene graph',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.delete',
      'Delete an unreferenced Scene or replace its references',
      resourceKinds: const ['project', 'scene'],
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    switch (context.request.actionId) {
      case 'scene.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'scene'});
        final scene =
            _decodeScene(narrativeObjectParameter(parameters, 'scene'));
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == scene.id)
            .firstOrNull;
        final projected = upsert(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          scene: scene,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/${scene.id}',
          before: before?.toJson(),
          after: scene.toJson(),
          preview: const ModernNarrativeInspector()
              .inspect(project: projected, maps: context.snapshot.maps)
              .toJson(),
        );
      case 'scene.delete':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'replacementSceneId'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final replacement = parameters['replacementSceneId'];
        if (replacement != null && replacement is! String) {
          throw ArgumentError.value(
            replacement,
            'replacementSceneId',
            'must be a string',
          );
        }
        final projected = delete(
          context.snapshot.manifest,
          sceneId: sceneId,
          replacementSceneId: replacement as String?,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId',
          before: before?.toJson(),
          preview: const ModernNarrativeInspector()
              .inspect(project: projected, maps: context.snapshot.maps)
              .toJson(),
        );
      default:
        throw NarrativeAuthoringException(
          'scene.action_unsupported',
          'The requested Scene action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required List<MapData> maps,
    required SceneAsset scene,
  }) {
    final exists = project.scenes.any((candidate) => candidate.id == scene.id);
    final projected = project.copyWith(
      scenes: exists
          ? [
              for (final candidate in project.scenes)
                if (candidate.id == scene.id) scene else candidate,
            ]
          : [...project.scenes, scene],
    );
    final diagnostics = diagnoseSceneAgainstProject(
      scene,
      projected,
      mapsById: {for (final map in maps) map.id: map},
    );
    final runtimePlan = buildSceneRuntimePlan(scene);
    if (diagnostics.hasErrors || !runtimePlan.canBuild) {
      throw NarrativeAuthoringException(
        'scene.publication_blocked',
        'The Scene is not safe for the canonical runtime.',
        details: {
          'diagnostics': [
            for (final item in diagnostics.diagnostics)
              {
                'code': item.code.name,
                'severity': item.severity.name,
                'message': item.message,
                if (item.nodeId != null) 'nodeId': item.nodeId,
                if (item.edgeId != null) 'edgeId': item.edgeId,
              },
          ],
          'runtimePlanBuildable': runtimePlan.canBuild,
        },
      );
    }
    return projected;
  }

  ProjectManifest delete(
    ProjectManifest project, {
    required String sceneId,
    String? replacementSceneId,
  }) {
    final result = deleteSceneFromProject(
      project,
      sceneId: sceneId,
      replacementSceneId: replacementSceneId,
      dependencyIndex: buildNarrativeDependencyIndex(project: project),
    );
    if (!result.isApplied) {
      throw NarrativeAuthoringException(
        result.code ?? 'scene.delete_rejected',
        result.message ?? 'The canonical Scene deletion was rejected.',
        details: {'referencePaths': result.referencePaths},
      );
    }
    return result.after;
  }
}

SceneAsset _decodeScene(Map<String, dynamic> json) {
  try {
    return SceneAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.invalid',
      'The Scene payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}
