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
    narrativeActionDescriptor(
      'scene.character_animation.set',
      'Set one bounded Character Studio animation on a Scene action node',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.pause_menu_visibility.set',
      'Set one persistent pause menu entry visibility on a Scene action node',
      resourceKinds: const ['project', 'scene'],
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
      case 'scene.character_animation.set':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'nodeId', 'runtimeCommand'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final projected = setCharacterAnimationCommand(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: nodeId,
          command: _decodeCharacterAnimationCommand(
            narrativeObjectParameter(parameters, 'runtimeCommand'),
          ),
        );
        final after = projected.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId/graph/nodes/$nodeId/interactiveCommand',
          before: before?.toJson(),
          after: after?.toJson(),
          preview: const ModernNarrativeInspector()
              .inspect(project: projected, maps: context.snapshot.maps)
              .toJson(),
        );
      case 'scene.pause_menu_visibility.set':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'nodeId', 'actionId', 'visible'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final beforeScene = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final beforePayload = beforeScene?.graph.nodes
            .where((node) => node.id == nodeId)
            .firstOrNull
            ?.payload
            .toJson();
        final projected = setPauseMenuEntryVisibility(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: nodeId,
          actionId: _decodePauseActionId(
            narrativeStringParameter(parameters, 'actionId'),
          ),
          visible: _booleanParameter(parameters, 'visible'),
        );
        final afterScene = projected.scenes
            .where((candidate) => candidate.id == sceneId)
            .first;
        final afterPayload = afterScene.graph.nodes
            .where((node) => node.id == nodeId)
            .first
            .payload
            .toJson();
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId/graph/nodes/$nodeId/consequence',
          before: beforePayload,
          after: afterPayload,
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

  ProjectManifest setCharacterAnimationCommand(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required CharacterCustomAnimationRuntimeCommand command,
  }) {
    _validateSceneCharacterAnimationCommand(project, command);
    final scene = project.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) {
      throw NarrativeAuthoringException(
        'scene.unknown',
        'The Scene identity is unknown.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    final nodeIndex = scene.graph.nodes.indexWhere((node) => node.id == nodeId);
    if (nodeIndex < 0 ||
        scene.graph.nodes[nodeIndex].kind != SceneNodeKind.action) {
      throw NarrativeAuthoringException(
        'scene.character_animation.action_node_required',
        'Character animations require an existing Scene action node.',
        details: <String, Object?>{'nodeId': nodeId},
      );
    }
    final beforeNode = scene.graph.nodes[nodeIndex];
    final nodes = scene.graph.nodes.toList();
    nodes[nodeIndex] = SceneNode(
      id: beforeNode.id,
      kind: beforeNode.kind,
      title: beforeNode.title,
      description: beforeNode.description,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.playCharacterAnimation(
          runtimeCommand: command,
        ),
      ),
    );
    final updatedScene = SceneAsset(
      id: scene.id,
      name: scene.name,
      description: scene.description,
      storylineId: scene.storylineId,
      chapterId: scene.chapterId,
      tags: scene.tags,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: nodes,
        edges: scene.graph.edges,
      ),
      layout: scene.layout,
      declaredOutcomes: scene.declaredOutcomes,
      metadata: scene.metadata,
    );
    return upsert(project, maps: maps, scene: updatedScene);
  }

  ProjectManifest setPauseMenuEntryVisibility(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required ProjectPauseActionId actionId,
    required bool visible,
  }) {
    final scene = project.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) {
      throw NarrativeAuthoringException(
        'scene.unknown',
        'The Scene identity is unknown.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    final updated = updateSceneActionConsequencePayload(
      scene,
      nodeId: nodeId,
      consequence: SceneConsequence.setPauseMenuEntryVisibility(
        actionId: actionId,
        visible: visible,
      ),
    );
    return upsert(project, maps: maps, scene: updated.updatedScene);
  }
}

ProjectPauseActionId _decodePauseActionId(String value) {
  try {
    return ProjectPauseActionId.values.byName(value);
  } on ArgumentError {
    throw ArgumentError.value(value, 'actionId', 'is not a pause menu entry');
  }
}

bool _booleanParameter(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
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

CharacterCustomAnimationRuntimeCommand _decodeCharacterAnimationCommand(
  Map<String, dynamic> json,
) {
  try {
    return CharacterCustomAnimationRuntimeCommand.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.character_animation.command_invalid',
      'The Character Studio animation command cannot be decoded.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

void _validateSceneCharacterAnimationCommand(
  ProjectManifest project,
  CharacterCustomAnimationRuntimeCommand command,
) {
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
      'scene.character_animation.definition_unknown',
      'The selected custom animation definition does not exist.',
      details: <String, Object?>{'definitionId': command.definitionId},
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.single &&
      command.direction != null) {
    throw NarrativeAuthoringException(
      'scene.character_animation.direction_unexpected',
      'A single custom animation does not accept a direction.',
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.directional &&
      command.direction == null) {
    throw NarrativeAuthoringException(
      'scene.character_animation.direction_required',
      'A directional custom animation requires a direction.',
    );
  }
}
