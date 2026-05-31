import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';

final class SceneDraftCreationResult {
  const SceneDraftCreationResult({
    required this.updatedProject,
    required this.createdScene,
  });

  final ProjectManifest updatedProject;
  final SceneAsset createdScene;
}

final class SceneNodeDraftCreationResult {
  const SceneNodeDraftCreationResult({
    required this.updatedScene,
    required this.createdNode,
  });

  final SceneAsset updatedScene;
  final SceneNode createdNode;
}

final class SceneEdgeDraftCreationResult {
  const SceneEdgeDraftCreationResult({
    required this.updatedScene,
    required this.createdEdge,
  });

  final SceneAsset updatedScene;
  final SceneEdge createdEdge;
}

final class SceneEdgeDraftRemovalResult {
  const SceneEdgeDraftRemovalResult({
    required this.updatedScene,
    required this.removedEdge,
  });

  final SceneAsset updatedScene;
  final SceneEdge removedEdge;
}

final class SceneNodeDraftRemovalResult {
  const SceneNodeDraftRemovalResult({
    required this.updatedScene,
    required this.removedNode,
    required this.removedEdges,
  });

  final SceneAsset updatedScene;
  final SceneNode removedNode;
  final List<SceneEdge> removedEdges;
}

final class SceneNodeLayoutUpdateResult {
  const SceneNodeLayoutUpdateResult({
    required this.updatedScene,
    required this.updatedLayout,
  });

  final SceneAsset updatedScene;
  final SceneNodeLayout updatedLayout;
}

final class SceneConditionSourceUpdateResult {
  const SceneConditionSourceUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneConditionPayload updatedPayload;
}

final class SceneYarnDialoguePayloadUpdateResult {
  const SceneYarnDialoguePayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneYarnDialoguePayload updatedPayload;
}

final class SceneBattlePayloadUpdateResult {
  const SceneBattlePayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneBattlePayload updatedPayload;
}

final class SceneActionNodeDraftCreationResult {
  const SceneActionNodeDraftCreationResult({
    required this.updatedScene,
    required this.createdNode,
    required this.createdPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode createdNode;
  final SceneActionPayload createdPayload;
}

final class SceneActionConsequencePayloadUpdateResult {
  const SceneActionConsequencePayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneActionPayload updatedPayload;
}

final class SceneAuthorableOutputPort {
  const SceneAuthorableOutputPort({
    required this.id,
    required this.label,
    required this.edgeKind,
  });

  final String id;
  final String label;
  final SceneEdgeKind edgeKind;
}

SceneDraftCreationResult createSceneDraftInProject(
  ProjectManifest project, {
  required String name,
  String? description,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Scene name is required.');
  }

  final scene = _createSceneDraft(
    id: _uniqueSceneId(trimmedName, project.scenes.map((scene) => scene.id)),
    name: trimmedName,
    description: _trimOptional(description),
  );
  return SceneDraftCreationResult(
    updatedProject: project.copyWith(
      scenes: [...project.scenes, scene],
    ),
    createdScene: scene,
  );
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForNode(
  SceneNode node,
) {
  return authorableSceneOutputPortsForKind(node.kind);
}

bool isSceneNodeDraftRemovable(SceneNode node) {
  return isSceneNodeDraftKindRemovable(node.kind);
}

bool isSceneNodeDraftKindRemovable(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => false,
    SceneNodeKind.end ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome ||
    SceneNodeKind.merge =>
      true,
  };
}

String? sceneNodeDraftRemovalBlocker(SceneGraph graph, SceneNode node) {
  if (node.kind == SceneNodeKind.start || graph.startNodeId == node.id) {
    return 'Le nœud de départ ne peut pas être supprimé.';
  }
  if (node.kind == SceneNodeKind.end) {
    final endCount =
        graph.nodes.where((candidate) => candidate.kind == SceneNodeKind.end);
    if (endCount.length <= 1) {
      return 'Une scène doit garder au moins une fin.';
    }
  }
  return null;
}

bool canRemoveSceneNodeDraft(SceneGraph graph, SceneNode node) {
  return sceneNodeDraftRemovalBlocker(graph, node) == null;
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForKind(
  SceneNodeKind kind,
) {
  return switch (kind) {
    SceneNodeKind.start => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.condition => const [
        SceneAuthorableOutputPort(
          id: 'true',
          label: 'true',
          edgeKind: SceneEdgeKind.conditionTrue,
        ),
        SceneAuthorableOutputPort(
          id: 'false',
          label: 'false',
          edgeKind: SceneEdgeKind.conditionFalse,
        ),
      ],
    SceneNodeKind.merge => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.yarnDialogue => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.battle => const [
        SceneAuthorableOutputPort(
          id: 'victory',
          label: 'victory',
          edgeKind: SceneEdgeKind.battleVictory,
        ),
        SceneAuthorableOutputPort(
          id: 'defeat',
          label: 'defeat',
          edgeKind: SceneEdgeKind.battleDefeat,
        ),
      ],
    SceneNodeKind.action => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.end ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome =>
      const <SceneAuthorableOutputPort>[],
  };
}

SceneConditionSourceUpdateResult updateSceneConditionSource(
  SceneAsset scene, {
  required String nodeId,
  required SceneConditionSource source,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.condition) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Condition Authoring V0 can only update condition nodes.',
    );
  }
  _validateConditionSourceForV0(source);

  final updatedPayload = SceneConditionPayload(
    conditionLabel: _trimOptional(source.label),
    conditionRef: source.sourceId,
    conditionSource: source,
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedNodes = [
    for (final candidate in scene.graph.nodes)
      if (candidate.id == nodeId) updatedNode else candidate,
  ];
  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: updatedNodes,
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneConditionSourceUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneYarnDialoguePayloadUpdateResult updateSceneYarnDialoguePayload(
  SceneAsset scene, {
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.yarnDialogue ||
      node.payload is! SceneYarnDialoguePayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene payload editing V0 can only update Yarn dialogue nodes.',
    );
  }
  final normalizedDialogueId = _trimRequired(
    dialogueId,
    'dialogueId',
    'Dialogue id is required by Scene payload editing V0.',
  );
  final currentPayload = node.payload as SceneYarnDialoguePayload;
  final updatedPayload = SceneYarnDialoguePayload(
    dialogueId: normalizedDialogueId,
    yarnNodeName: _trimOptional(yarnNodeName),
    expectedOutcomes: currentPayload.expectedOutcomes,
    speakerHints: currentPayload.speakerHints,
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneYarnDialoguePayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneBattlePayloadUpdateResult updateSceneBattlePayload(
  SceneAsset scene, {
  required String nodeId,
  required String trainerId,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.battle ||
      node.payload is! SceneBattlePayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene payload editing V0 can only update trainer battle nodes.',
    );
  }
  final normalizedTrainerId = _trimRequired(
    trainerId,
    'trainerId',
    'Trainer id is required by Scene payload editing V0.',
  );
  final currentPayload = node.payload as SceneBattlePayload;
  final updatedPayload = SceneBattlePayload(
    battleKind: 'trainer',
    trainerId: normalizedTrainerId,
    battleTemplateId: currentPayload.battleTemplateId,
    npcEntityId: currentPayload.npcEntityId,
    declaredOutcomes: const ['victory', 'defeat'],
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneBattlePayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneActionNodeDraftCreationResult addSceneConsequenceActionNodeDraft(
  SceneAsset scene, {
  required SceneConsequence consequence,
  String? title,
  String? afterNodeId,
}) {
  _validateSceneConsequenceForAuthoring(consequence);

  final nodeId = _uniqueNodeId(
    'node_action',
    scene.graph.nodes.map((node) => node.id),
  );
  final createdPayload = SceneActionPayload.consequence(consequence);
  final createdNode = SceneNode(
    id: nodeId,
    kind: SceneNodeKind.action,
    title: _trimOptional(title) ?? _defaultConsequenceActionTitle(consequence),
    payload: createdPayload,
  );
  final createdLayout = _layoutForNewNode(
    scene,
    nodeId: nodeId,
    afterNodeId: afterNodeId,
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
      nodes: [...scene.graph.nodes, createdNode],
      edges: scene.graph.edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneActionNodeDraftCreationResult(
    updatedScene: updatedScene,
    createdNode: createdNode,
    createdPayload: createdPayload,
  );
}

SceneActionConsequencePayloadUpdateResult updateSceneActionConsequencePayload(
  SceneAsset scene, {
  required String nodeId,
  required SceneConsequence consequence,
}) {
  final trimmedNodeId = _trimRequired(
    nodeId,
    'nodeId',
    'Scene consequence editing requires an action node id.',
  );
  final node = _findNodeOrThrow(scene, trimmedNodeId, 'nodeId');
  if (node.kind != SceneNodeKind.action) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene consequence editing V0 can only update action nodes.',
    );
  }
  _validateSceneConsequenceForAuthoring(consequence);

  final currentPayload = node.payload;
  final updatedPayload = currentPayload is SceneActionPayload
      ? SceneActionPayload.consequence(
          consequence,
          actionKind: currentPayload.actionKind,
          parameters: currentPayload.parameters,
        )
      : SceneActionPayload.consequence(consequence);
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneActionConsequencePayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneNodeLayoutUpdateResult updateSceneNodeLayout(
  SceneAsset scene, {
  required String nodeId,
  required double x,
  required double y,
}) {
  _findNodeOrThrow(scene, nodeId, 'nodeId');

  final updatedLayout = SceneNodeLayout(nodeId: nodeId, x: x, y: y);
  var replaced = false;
  final nodeLayouts = <SceneNodeLayout>[];
  for (final layout in scene.layout.nodeLayouts) {
    if (layout.nodeId == nodeId) {
      nodeLayouts.add(updatedLayout);
      replaced = true;
    } else {
      nodeLayouts.add(layout);
    }
  }
  if (!replaced) {
    nodeLayouts.add(updatedLayout);
  }

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: scene.graph,
    layout: SceneGraphLayout(
      nodeLayouts: nodeLayouts,
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeLayoutUpdateResult(
    updatedScene: updatedScene,
    updatedLayout: updatedLayout,
  );
}

SceneNodeDraftCreationResult addSceneNodeDraft(
  SceneAsset scene, {
  required SceneNodeKind kind,
  String? title,
  String? afterNodeId,
}) {
  if (!_isSupportedDraftNodeKind(kind)) {
    throw ArgumentError.value(
      kind,
      'kind',
      'Scene node kind ${kind.name} is not supported by Node Authoring V0.',
    );
  }

  final nodeId = _uniqueNodeId(
    _nodeIdBaseForKind(kind),
    scene.graph.nodes.map((node) => node.id),
  );
  final createdNode = SceneNode(
    id: nodeId,
    kind: kind,
    title: _trimOptional(title) ?? _defaultTitleForKind(kind),
    payload: SceneNodePayload.emptyForKind(kind),
  );
  final createdLayout = _layoutForNewNode(
    scene,
    nodeId: nodeId,
    afterNodeId: afterNodeId,
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
      nodes: [...scene.graph.nodes, createdNode],
      edges: scene.graph.edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeDraftCreationResult(
    updatedScene: updatedScene,
    createdNode: createdNode,
  );
}

SceneNodeDraftCreationResult addSceneLinkedAssetNodeDraft(
  SceneAsset scene, {
  required SceneNodePayload payload,
  String? title,
  String? afterNodeId,
}) {
  if (!_isSupportedLinkedAssetPayloadKind(payload.kind)) {
    throw ArgumentError.value(
      payload.kind,
      'payload.kind',
      'Scene node kind ${payload.kind.name} is not supported by Payload '
          'Pickers V0.',
    );
  }

  final nodeId = _uniqueNodeId(
    _linkedAssetNodeIdBaseForKind(payload.kind),
    scene.graph.nodes.map((node) => node.id),
  );
  final createdNode = SceneNode(
    id: nodeId,
    kind: payload.kind,
    title:
        _trimOptional(title) ?? _defaultLinkedAssetTitleForKind(payload.kind),
    payload: payload,
  );
  final createdLayout = _layoutForNewNode(
    scene,
    nodeId: nodeId,
    afterNodeId: afterNodeId,
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
      nodes: [...scene.graph.nodes, createdNode],
      edges: scene.graph.edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeDraftCreationResult(
    updatedScene: updatedScene,
    createdNode: createdNode,
  );
}

SceneEdgeDraftCreationResult addSceneEdgeDraft(
  SceneAsset scene, {
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
  String? label,
}) {
  final fromNode = _findNodeOrThrow(scene, fromNodeId, 'fromNodeId');
  _findNodeOrThrow(scene, toNodeId, 'toNodeId');

  if (fromNodeId == toNodeId) {
    throw ArgumentError.value(
      toNodeId,
      'toNodeId',
      'Self-loop edges are not supported by Edge Authoring V0.',
    );
  }

  final port = _authorableOutputPortOrThrow(fromNode, fromPortId);
  for (final edge in scene.graph.edges) {
    if (edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId) {
      throw ArgumentError.value(
        fromPortId,
        'fromPortId',
        'Edge Authoring V0 allows only one outgoing edge per source port.',
      );
    }
  }

  final createdEdge = SceneEdge(
    id: _uniqueEdgeId(
      _edgeIdBase(
        fromNodeId: fromNodeId,
        fromPortId: fromPortId,
        toNodeId: toNodeId,
      ),
      scene.graph.edges.map((edge) => edge.id),
    ),
    fromNodeId: fromNodeId,
    fromPortId: fromPortId,
    toNodeId: toNodeId,
    kind: port.edgeKind,
    label: _trimOptional(label) ?? port.label,
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
      nodes: scene.graph.nodes,
      edges: [...scene.graph.edges, createdEdge],
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneEdgeDraftCreationResult(
    updatedScene: updatedScene,
    createdEdge: createdEdge,
  );
}

SceneEdgeDraftRemovalResult removeSceneEdgeDraft(
  SceneAsset scene,
  String edgeId,
) {
  SceneEdge? removedEdge;
  final remainingEdges = <SceneEdge>[];
  for (final edge in scene.graph.edges) {
    if (edge.id == edgeId) {
      removedEdge = edge;
    } else {
      remainingEdges.add(edge);
    }
  }
  final edge = removedEdge;
  if (edge == null) {
    throw ArgumentError.value(
      edgeId,
      'edgeId',
      'Scene edge draft references an unknown edge.',
    );
  }

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: scene.graph.nodes,
      edges: remainingEdges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: scene.layout.nodeLayouts,
      edgeLayouts: [
        for (final layout in scene.layout.edgeLayouts)
          if (layout.edgeId != edgeId) layout,
      ],
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneEdgeDraftRemovalResult(
    updatedScene: updatedScene,
    removedEdge: edge,
  );
}

SceneNodeDraftRemovalResult removeSceneNodeDraft(
  SceneAsset scene,
  String nodeId,
) {
  final trimmedNodeId = _trimRequired(
    nodeId,
    'nodeId',
    'Scene node deletion requires a node id.',
  );
  final removedNode = _findNodeOrThrow(scene, trimmedNodeId, 'nodeId');
  final removalBlocker = sceneNodeDraftRemovalBlocker(
    scene.graph,
    removedNode,
  );
  if (removalBlocker != null || !isSceneNodeDraftRemovable(removedNode)) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      removalBlocker ??
          'Scene node kind ${removedNode.kind.name} cannot be removed by Node Authoring V0.',
    );
  }

  final removedEdges = <SceneEdge>[];
  final remainingEdges = <SceneEdge>[];
  for (final edge in scene.graph.edges) {
    if (edge.fromNodeId == trimmedNodeId || edge.toNodeId == trimmedNodeId) {
      removedEdges.add(edge);
    } else {
      remainingEdges.add(edge);
    }
  }
  final removedEdgeIds = removedEdges.map((edge) => edge.id).toSet();

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          if (node.id != trimmedNodeId) node,
      ],
      edges: remainingEdges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        for (final layout in scene.layout.nodeLayouts)
          if (layout.nodeId != trimmedNodeId) layout,
      ],
      edgeLayouts: [
        for (final layout in scene.layout.edgeLayouts)
          if (!removedEdgeIds.contains(layout.edgeId)) layout,
      ],
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeDraftRemovalResult(
    updatedScene: updatedScene,
    removedNode: removedNode,
    removedEdges: List<SceneEdge>.unmodifiable(removedEdges),
  );
}

void _validateConditionSourceForV0(SceneConditionSource source) {
  switch (source.sourceKind) {
    case SceneConditionSourceKind.fact:
    case SceneConditionSourceKind.factLikeStoryFlag:
    case SceneConditionSourceKind.consumedEvent:
      if (source.operator != SceneConditionOperator.isTrue &&
          source.operator != SceneConditionOperator.isFalse) {
        throw ArgumentError.value(
          source.operator,
          'source.operator',
          '${source.sourceKind.name} supports only isTrue/isFalse in '
              'Condition Authoring V0.',
        );
      }
      if (_trimOptional(source.value) != null) {
        throw ArgumentError.value(
          source.value,
          'source.value',
          '${source.sourceKind.name} must not carry a comparison value in '
              'Condition Authoring V0.',
        );
      }
      return;
    case SceneConditionSourceKind.storyStepCompletion:
      if (source.operator != SceneConditionOperator.equals) {
        throw ArgumentError.value(
          source.operator,
          'source.operator',
          'storyStepCompletion supports only equals in Condition Authoring V0.',
        );
      }
      final value = source.value;
      if (value != SceneConditionValues.completed &&
          value != SceneConditionValues.notCompleted) {
        throw ArgumentError.value(
          source.value,
          'source.value',
          'storyStepCompletion value must be completed or notCompleted.',
        );
      }
      return;
    case SceneConditionSourceKind.storyStepActive:
    case SceneConditionSourceKind.inventoryItem:
    case SceneConditionSourceKind.partyState:
    case SceneConditionSourceKind.trainerDefeated:
    case SceneConditionSourceKind.dialogueOutcome:
    case SceneConditionSourceKind.battleOutcome:
    case SceneConditionSourceKind.scriptVariable:
    case SceneConditionSourceKind.worldState:
      throw ArgumentError.value(
        source.sourceKind,
        'source.sourceKind',
        'Condition source kind ${source.sourceKind.name} is not supported by '
            'Condition Authoring V0.',
      );
  }
}

void _validateSceneConsequenceForAuthoring(SceneConsequence consequence) {
  switch (consequence) {
    case SceneSetFactConsequence():
      _trimRequired(
        consequence.factId,
        'consequence.factId',
        'setFact consequence requires a fact id.',
      );
    case SceneMarkEventConsumedConsequence():
      _trimRequired(
        consequence.mapId,
        'consequence.mapId',
        'markEventConsumed consequence requires a map id.',
      );
      _trimRequired(
        consequence.eventId,
        'consequence.eventId',
        'markEventConsumed consequence requires an event id.',
      );
    case _:
      throw ArgumentError.value(
        consequence,
        'consequence',
        'Unsupported Scene consequence kind for authoring V0.',
      );
  }
}

SceneAsset _createSceneDraft({
  required String id,
  required String name,
  String? description,
}) {
  return SceneAsset(
    id: id,
    name: name,
    description: description,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(
          id: 'node_start',
          kind: SceneNodeKind.start,
          title: 'Début',
        ),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          title: 'Fin',
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
      ],
    ),
  );
}

SceneNode _findNodeOrThrow(
  SceneAsset scene,
  String nodeId,
  String argumentName,
) {
  for (final node in scene.graph.nodes) {
    if (node.id == nodeId) {
      return node;
    }
  }
  throw ArgumentError.value(
    nodeId,
    argumentName,
    'Scene edge draft references an unknown node.',
  );
}

SceneAuthorableOutputPort _authorableOutputPortOrThrow(
  SceneNode node,
  String fromPortId,
) {
  final ports = authorableSceneOutputPortsForNode(node);
  for (final port in ports) {
    if (port.id == fromPortId) {
      return port;
    }
  }
  throw ArgumentError.value(
    fromPortId,
    'fromPortId',
    'Port $fromPortId is not supported for ${node.kind.name} '
        'by Edge Authoring V0.',
  );
}

String _uniqueSceneId(String name, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  final base = 'scene_${_slugify(name)}';
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _uniqueNodeId(String base, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _uniqueEdgeId(String base, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

SceneAsset _sceneWithUpdatedNode(SceneAsset scene, SceneNode updatedNode) {
  final updatedNodes = [
    for (final candidate in scene.graph.nodes)
      if (candidate.id == updatedNode.id) updatedNode else candidate,
  ];
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: updatedNodes,
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );
}

String _edgeIdBase({
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
}) {
  return 'edge_${_sanitizeEdgeIdPart(fromNodeId)}_'
      '${_sanitizeEdgeIdPart(fromPortId)}_'
      '${_sanitizeEdgeIdPart(toNodeId)}';
}

String _sanitizeEdgeIdPart(String value) {
  final slug = _slugify(value);
  return slug.isEmpty ? 'id' : slug;
}

bool _isSupportedDraftNodeKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.condition || SceneNodeKind.merge || SceneNodeKind.end => true,
    SceneNodeKind.start ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome =>
      false,
  };
}

bool _isSupportedLinkedAssetPayloadKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic =>
      true,
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.branchByOutcome ||
    SceneNodeKind.merge =>
      false,
  };
}

String _nodeIdBaseForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.condition => 'node_condition',
    SceneNodeKind.merge => 'node_merge',
    SceneNodeKind.end => 'node_end',
    SceneNodeKind.start ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome =>
      throw ArgumentError.value(kind, 'kind', 'Unsupported draft node kind.'),
  };
}

String _linkedAssetNodeIdBaseForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.yarnDialogue => 'node_yarn_dialogue',
    SceneNodeKind.battle => 'node_battle',
    SceneNodeKind.cinematic => 'node_cinematic',
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.branchByOutcome ||
    SceneNodeKind.merge =>
      throw ArgumentError.value(
        kind,
        'kind',
        'Unsupported linked asset node kind.',
      ),
  };
}

String _defaultTitleForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.condition => 'Condition',
    SceneNodeKind.merge => 'Merge',
    SceneNodeKind.end => 'Fin',
    SceneNodeKind.start ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome =>
      throw ArgumentError.value(kind, 'kind', 'Unsupported draft node kind.'),
  };
}

String _defaultLinkedAssetTitleForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.yarnDialogue => 'Dialogue',
    SceneNodeKind.battle => 'Combat',
    SceneNodeKind.cinematic => 'Cinématique',
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.branchByOutcome ||
    SceneNodeKind.merge =>
      throw ArgumentError.value(
        kind,
        'kind',
        'Unsupported linked asset node kind.',
      ),
  };
}

String _defaultConsequenceActionTitle(SceneConsequence consequence) {
  return switch (consequence) {
    SceneSetFactConsequence() => 'Définir un Fact',
    SceneMarkEventConsumedConsequence() => 'Marquer event consommé',
    _ => 'Conséquence',
  };
}

SceneNodeLayout _layoutForNewNode(
  SceneAsset scene, {
  required String nodeId,
  String? afterNodeId,
}) {
  final layouts = scene.layout.nodeLayouts;
  SceneNodeLayout? source;
  if (afterNodeId != null) {
    for (final layout in layouts) {
      if (layout.nodeId == afterNodeId) {
        source = layout;
        break;
      }
    }
  }

  source ??= _rightMostLayout(layouts);
  if (source != null) {
    return SceneNodeLayout(
      nodeId: nodeId,
      x: source.x + 300,
      y: source.y,
    );
  }

  return SceneNodeLayout(
    nodeId: nodeId,
    x: 24 + scene.graph.nodes.length * 300,
    y: 80,
  );
}

SceneNodeLayout? _rightMostLayout(List<SceneNodeLayout> layouts) {
  if (layouts.isEmpty) {
    return null;
  }
  var rightMost = layouts.first;
  for (final layout in layouts.skip(1)) {
    if (layout.x > rightMost.x) {
      rightMost = layout;
    }
  }
  return rightMost;
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  var wroteSeparator = false;

  for (final codeUnit in lower.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }

  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

String _trimRequired(
  String value,
  String argumentName,
  String message,
) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, argumentName, message);
  }
  return trimmed;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
