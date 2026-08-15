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
      'scene.preSession.create',
      'Create a typed preSession Scene from a canonical template',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.interaction.insert',
      'Insert a structured preSession interaction before a Scene node',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.presentation.insert',
      'Insert a canonical Presentation Cinematic before a Scene node',
      resourceKinds: const ['project', 'scene', 'presentationCinematic'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.condition.insert',
      'Insert a draft-local preSession condition with a false terminal',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.end.configure',
      'Configure a typed preSession Scene end and declared outcome',
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
      case 'scene.preSession.create':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'name',
            'templateId',
            'setAsEntrypoint',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = createPreSessionScene(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          name: narrativeStringParameter(parameters, 'name'),
          templateId: narrativeStringParameter(parameters, 'templateId'),
          setAsEntrypoint: _optionalBoolParameter(
            parameters,
            'setAsEntrypoint',
            fallback: true,
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.interaction.insert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'nodeId', 'targetNodeId', 'title', 'interaction'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = insertPreSessionInteraction(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          targetNodeId: narrativeStringParameter(parameters, 'targetNodeId'),
          title: _optionalStringParameter(parameters, 'title'),
          interaction: _decodePreSessionInteraction(
            narrativeObjectParameter(parameters, 'interaction'),
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.presentation.insert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'targetNodeId',
            'title',
            'presentationCinematicId',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = insertPreSessionPresentation(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          targetNodeId: narrativeStringParameter(parameters, 'targetNodeId'),
          title: _optionalStringParameter(parameters, 'title'),
          presentationCinematicId: narrativeStringParameter(
            parameters,
            'presentationCinematicId',
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.condition.insert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'targetNodeId',
            'falseEndNodeId',
            'title',
            'draftField',
            'operator',
            'value',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = insertPreSessionCondition(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          targetNodeId: narrativeStringParameter(parameters, 'targetNodeId'),
          falseEndNodeId: narrativeStringParameter(
            parameters,
            'falseEndNodeId',
          ),
          title: _optionalStringParameter(parameters, 'title'),
          draftField: _enumParameter(
            parameters,
            'draftField',
            ScenePreSessionDraftField.values,
          ),
          operator: _enumParameter(
            parameters,
            'operator',
            SceneConditionOperator.values,
          ),
          value: _optionalStringParameter(parameters, 'value'),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.end.configure':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'outcomeId',
            'outcomeLabel',
            'outcomePolicy',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = configurePreSessionEnd(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          outcomeId: narrativeStringParameter(parameters, 'outcomeId'),
          outcomeLabel: narrativeStringParameter(parameters, 'outcomeLabel'),
          outcomePolicy: _enumParameter(
            parameters,
            'outcomePolicy',
            SceneOutcomePolicy.values,
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
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

  ProjectManifest createPreSessionScene(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String name,
    required String templateId,
    required bool setAsEntrypoint,
  }) {
    if (project.scenes.any((scene) => scene.id == sceneId)) {
      throw NarrativeAuthoringException(
        'scene.preSession.duplicate',
        'The preSession Scene identity already exists.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    final scene = _createPreSessionTemplate(
      project,
      sceneId: sceneId,
      name: name,
      templateId: templateId,
    );
    var projected = upsert(project, maps: maps, scene: scene);
    if (setAsEntrypoint) {
      projected = projected.copyWith(
        newGame: ProjectNewGameConfig.fromJson(<String, dynamic>{
          ...projected.newGame.toJson(),
          'preSessionSceneId': scene.id,
        }),
      );
    }
    return projected;
  }

  ProjectManifest insertPreSessionInteraction(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required ScenePreSessionInteractionSpec interaction,
    String? title,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    _validatePreSessionInteractionBinding(project, interaction);
    final updated = _insertLinearNode(
      scene,
      node: SceneNode(
        id: nodeId,
        kind: SceneNodeKind.action,
        title: title,
        payload: SceneActionPayload.preSessionInteraction(interaction),
      ),
      targetNodeId: targetNodeId,
      outgoingEdgeKind: SceneEdgeKind.actionCompleted,
    );
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest insertPreSessionPresentation(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required String presentationCinematicId,
    String? title,
  }) {
    if (!project.presentationCinematics
        .any((asset) => asset.id == presentationCinematicId)) {
      throw NarrativeAuthoringException(
        'scene.preSession.presentation.unknown',
        'The Presentation Cinematic identity is unknown.',
        details: <String, Object?>{
          'presentationCinematicId': presentationCinematicId,
        },
      );
    }
    final scene = _requirePreSessionScene(project, sceneId);
    final updated = _insertLinearNode(
      scene,
      node: SceneNode(
        id: nodeId,
        kind: SceneNodeKind.presentationCinematic,
        title: title,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: presentationCinematicId,
        ),
      ),
      targetNodeId: targetNodeId,
      outgoingEdgeKind: SceneEdgeKind.presentationCompleted,
    );
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest insertPreSessionCondition(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required String falseEndNodeId,
    required ScenePreSessionDraftField draftField,
    required SceneConditionOperator operator,
    String? value,
    String? title,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    _requireNewNodeIds(scene, <String>[nodeId, falseEndNodeId]);
    final target = _requireTargetNode(scene, targetNodeId);
    if (target.kind == SceneNodeKind.start) {
      throw NarrativeAuthoringException(
        'scene.preSession.target.invalid',
        'A node cannot be inserted before the Scene start.',
      );
    }
    final incoming = _singleIncomingEdge(scene, targetNodeId);
    final nodes = <SceneNode>[
      ...scene.graph.nodes,
      SceneNode(
        id: nodeId,
        kind: SceneNodeKind.condition,
        title: title,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.newGameDraft,
            sourceId: draftField.name,
            operator: operator,
            value: value,
            label: draftField.name,
          ),
        ),
      ),
      SceneNode(id: falseEndNodeId, kind: SceneNodeKind.end),
    ];
    final edges = <SceneEdge>[
      for (final edge in scene.graph.edges)
        if (edge.id == incoming.id) _copyEdge(edge, toNodeId: nodeId) else edge,
      SceneEdge(
        id: _edgeId(nodeId, 'true', targetNodeId),
        fromNodeId: nodeId,
        fromPortId: 'true',
        toNodeId: targetNodeId,
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: _edgeId(nodeId, 'false', falseEndNodeId),
        fromNodeId: nodeId,
        fromPortId: 'false',
        toNodeId: falseEndNodeId,
        kind: SceneEdgeKind.conditionFalse,
      ),
    ];
    final updated = _copyScene(
      scene,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: nodes,
        edges: edges,
      ),
    );
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest configurePreSessionEnd(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String outcomeId,
    required String outcomeLabel,
    required SceneOutcomePolicy outcomePolicy,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    final nodeIndex = scene.graph.nodes.indexWhere((node) => node.id == nodeId);
    if (nodeIndex < 0 ||
        scene.graph.nodes[nodeIndex].kind != SceneNodeKind.end) {
      throw NarrativeAuthoringException(
        'scene.preSession.end.required',
        'The selected preSession node is not an end node.',
        details: <String, Object?>{'nodeId': nodeId},
      );
    }
    final nodes = <SceneNode>[];
    final generatedOutcomes = <SceneOutcome>[];
    for (final node in scene.graph.nodes) {
      if (node.id == nodeId) {
        nodes.add(
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: SceneEndPayload(
              sceneOutcomeId: outcomeId,
              outcomePolicy: outcomePolicy,
            ),
          ),
        );
        continue;
      }
      final payload = node.payload;
      if (node.kind == SceneNodeKind.end &&
          payload is SceneEndPayload &&
          payload.sceneOutcomeId == null) {
        final generatedOutcomeId = 'outcome_${node.id}';
        nodes.add(
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: SceneEndPayload(
              sceneOutcomeId: generatedOutcomeId,
              outcomePolicy: SceneOutcomePolicy.retryable,
            ),
          ),
        );
        generatedOutcomes.add(
          SceneOutcome(
            id: generatedOutcomeId,
            label: node.title ?? node.id,
          ),
        );
        continue;
      }
      nodes.add(node);
    }
    final outcomes = <SceneOutcome>[
      for (final outcome in scene.declaredOutcomes)
        if (outcome.id != outcomeId &&
            !generatedOutcomes.any((generated) => generated.id == outcome.id))
          outcome,
      ...generatedOutcomes,
      SceneOutcome(id: outcomeId, label: outcomeLabel),
    ];
    final updated = _copyScene(
      scene,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: nodes,
        edges: scene.graph.edges,
      ),
      declaredOutcomes: outcomes,
    );
    return upsert(project, maps: maps, scene: updated);
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

void _validatePreSessionInteractionBinding(
  ProjectManifest project,
  ScenePreSessionInteractionSpec interaction,
) {
  final field = interaction.resultBinding?.field;
  if (field == null || field == ScenePreSessionDraftField.playerName) return;
  final allowedIds = switch (field) {
    ScenePreSessionDraftField.avatarCharacterId =>
      project.newGame.playerAvatarCharacterIds.toSet(),
    ScenePreSessionDraftField.starterOptionId =>
      project.newGame.starterOptions.map((option) => option.id).toSet(),
    ScenePreSessionDraftField.playerName => const <String>{},
  };
  final unknownIds = interaction.options
      .map((option) => option.id)
      .where((id) => !allowedIds.contains(id))
      .toList(growable: false);
  if (unknownIds.isNotEmpty) {
    throw NarrativeAuthoringException(
      'scene.preSession.binding.option_unknown',
      'A structured interaction option is not allowed by New Game config.',
      details: <String, Object?>{
        'draftField': field.name,
        'optionIds': unknownIds,
      },
    );
  }
}

AuthoringMutationDraft _preSessionProjectDraft(
  AuthoringPlanningContext context,
  ProjectManifest projected, {
  required String sceneId,
}) {
  final before = context.snapshot.manifest.scenes
      .where((scene) => scene.id == sceneId)
      .firstOrNull;
  final after =
      projected.scenes.where((scene) => scene.id == sceneId).firstOrNull;
  return narrativeProjectDraft(
    context.snapshot,
    projected,
    operation: context.request.actionId,
    path: '/scenes/$sceneId',
    before: before?.toJson(),
    after: after?.toJson(),
    preview: const ModernNarrativeInspector()
        .inspect(project: projected, maps: context.snapshot.maps)
        .toJson(),
  );
}

SceneAsset _createPreSessionTemplate(
  ProjectManifest project, {
  required String sceneId,
  required String name,
  required String templateId,
}) {
  if (templateId == 'minimal') {
    return SceneAsset(
      id: sceneId,
      name: name,
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
  }
  if (templateId != 'identitySetup') {
    throw NarrativeAuthoringException(
      'scene.preSession.template.unknown',
      'The preSession Scene template is unknown.',
      details: <String, Object?>{'templateId': templateId},
    );
  }

  final authoredNodes = <SceneNode>[
    SceneNode(
      id: 'playerName',
      kind: SceneNodeKind.action,
      title: 'Nom du joueur',
      payload: SceneActionPayload.preSessionInteraction(
        ScenePreSessionInteractionSpec.text(
          prompt: SceneInteractionPrompt(
            localizationKey: 'newGame.playerName.prompt',
            fallbackText: 'Quel est ton nom ?',
          ),
          constraints: SceneTextInputConstraints(
            minGraphemes: 1,
            maxGraphemes: 24,
          ),
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.playerName,
          ),
        ),
      ),
    ),
    if (project.newGame.playerAvatarCharacterIds.isNotEmpty)
      SceneNode(
        id: 'avatarCharacterId',
        kind: SceneNodeKind.action,
        title: 'Avatar',
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.selection(
            prompt: SceneInteractionPrompt(
              localizationKey: 'newGame.avatar.prompt',
              fallbackText: 'Choisis ton avatar',
            ),
            options: [
              for (final id in project.newGame.playerAvatarCharacterIds)
                SceneInteractionOption(
                  id: id,
                  label: SceneInteractionPrompt(
                    localizationKey: 'newGame.avatar.$id',
                    fallbackText: id,
                  ),
                ),
            ],
            constraints: SceneSelectionConstraints(),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.avatarCharacterId,
            ),
          ),
        ),
      ),
    if (project.newGame.starterOptions.isNotEmpty)
      SceneNode(
        id: 'starterOptionId',
        kind: SceneNodeKind.action,
        title: 'Starter',
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.selection(
            prompt: SceneInteractionPrompt(
              localizationKey: 'newGame.starter.prompt',
              fallbackText: 'Choisis ton starter',
            ),
            options: [
              for (final option in project.newGame.starterOptions)
                SceneInteractionOption(
                  id: option.id,
                  label: SceneInteractionPrompt(
                    localizationKey: 'newGame.starter.${option.id}',
                    fallbackText: option.label,
                  ),
                ),
            ],
            constraints: SceneSelectionConstraints(),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.starterOptionId,
            ),
          ),
        ),
      ),
  ];
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    ...authoredNodes,
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  final orderedIds = nodes.map((node) => node.id).toList(growable: false);
  return SceneAsset(
    id: sceneId,
    name: name,
    executionProfile: SceneExecutionProfile.preSession,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < orderedIds.length - 1; index += 1)
          SceneEdge(
            id: _edgeId(
              orderedIds[index],
              'completed',
              orderedIds[index + 1],
            ),
            fromNodeId: orderedIds[index],
            fromPortId: 'completed',
            toNodeId: orderedIds[index + 1],
            kind: index == 0
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}

SceneAsset _insertLinearNode(
  SceneAsset scene, {
  required SceneNode node,
  required String targetNodeId,
  required SceneEdgeKind outgoingEdgeKind,
}) {
  _requireNewNodeIds(scene, <String>[node.id]);
  final target = _requireTargetNode(scene, targetNodeId);
  if (target.kind == SceneNodeKind.start) {
    throw NarrativeAuthoringException(
      'scene.preSession.target.invalid',
      'A node cannot be inserted before the Scene start.',
    );
  }
  final incoming = _singleIncomingEdge(scene, targetNodeId);
  return _copyScene(
    scene,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: <SceneNode>[...scene.graph.nodes, node],
      edges: <SceneEdge>[
        for (final edge in scene.graph.edges)
          if (edge.id == incoming.id)
            _copyEdge(edge, toNodeId: node.id)
          else
            edge,
        SceneEdge(
          id: _edgeId(node.id, 'completed', targetNodeId),
          fromNodeId: node.id,
          fromPortId: 'completed',
          toNodeId: targetNodeId,
          kind: outgoingEdgeKind,
        ),
      ],
    ),
  );
}

SceneAsset _requirePreSessionScene(ProjectManifest project, String sceneId) {
  final scene =
      project.scenes.where((scene) => scene.id == sceneId).firstOrNull;
  if (scene == null) {
    throw NarrativeAuthoringException(
      'scene.unknown',
      'The Scene identity is unknown.',
      details: <String, Object?>{'sceneId': sceneId},
    );
  }
  if (scene.executionProfile != SceneExecutionProfile.preSession) {
    throw NarrativeAuthoringException(
      'scene.preSession.profile_required',
      'The requested Scene is not a preSession Scene.',
      details: <String, Object?>{'sceneId': sceneId},
    );
  }
  return scene;
}

void _requireNewNodeIds(SceneAsset scene, List<String> nodeIds) {
  final existing = scene.graph.nodes.map((node) => node.id).toSet();
  final requested = <String>{};
  for (final nodeId in nodeIds) {
    if (!requested.add(nodeId) || existing.contains(nodeId)) {
      throw NarrativeAuthoringException(
        'scene.preSession.node.duplicate',
        'The preSession node identity already exists.',
        details: <String, Object?>{'nodeId': nodeId},
      );
    }
  }
}

SceneNode _requireTargetNode(SceneAsset scene, String targetNodeId) {
  final target =
      scene.graph.nodes.where((node) => node.id == targetNodeId).firstOrNull;
  if (target == null) {
    throw NarrativeAuthoringException(
      'scene.preSession.target.unknown',
      'The insertion target node is unknown.',
      details: <String, Object?>{'targetNodeId': targetNodeId},
    );
  }
  return target;
}

SceneEdge _singleIncomingEdge(SceneAsset scene, String targetNodeId) {
  final incoming = scene.graph.edges
      .where((edge) => edge.toNodeId == targetNodeId)
      .toList(growable: false);
  if (incoming.length != 1) {
    throw NarrativeAuthoringException(
      'scene.preSession.target.incoming_ambiguous',
      'The insertion target must have exactly one incoming edge.',
      details: <String, Object?>{
        'targetNodeId': targetNodeId,
        'incomingEdgeCount': incoming.length,
      },
    );
  }
  return incoming.single;
}

SceneAsset _copyScene(
  SceneAsset scene, {
  required SceneGraph graph,
  List<SceneOutcome>? declaredOutcomes,
}) {
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: graph,
    layout: scene.layout,
    declaredOutcomes: declaredOutcomes ?? scene.declaredOutcomes,
    metadata: scene.metadata,
  );
}

SceneEdge _copyEdge(SceneEdge edge, {required String toNodeId}) {
  return SceneEdge(
    id: edge.id,
    fromNodeId: edge.fromNodeId,
    fromPortId: edge.fromPortId,
    toNodeId: toNodeId,
    kind: edge.kind,
    label: edge.label,
  );
}

String _edgeId(String fromNodeId, String fromPortId, String toNodeId) =>
    'edge_${fromNodeId}_${fromPortId}_$toNodeId';

ScenePreSessionInteractionSpec _decodePreSessionInteraction(
  Map<String, dynamic> json,
) {
  try {
    return ScenePreSessionInteractionSpec.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.preSession.interaction.invalid',
      'The structured preSession interaction cannot be decoded.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

bool _optionalBoolParameter(
  Map<String, Object?> parameters,
  String key, {
  required bool fallback,
}) {
  final value = parameters[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

String? _optionalStringParameter(
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

T _enumParameter<T extends Enum>(
  Map<String, Object?> parameters,
  String key,
  List<T> values,
) {
  final value = narrativeStringParameter(parameters, key);
  return values.where((candidate) => candidate.name == value).firstOrNull ??
      (throw ArgumentError.value(value, key, 'contains an unknown value'));
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
