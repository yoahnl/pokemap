import '../models/project_manifest.dart';
import '../models/scene_asset.dart';

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
    SceneNodeKind.end ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
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
  final removedNode = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (!isSceneNodeDraftRemovable(removedNode) ||
      scene.graph.startNodeId == nodeId) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene node kind ${removedNode.kind.name} cannot be removed by Node Authoring V0.',
    );
  }

  final removedEdges = <SceneEdge>[];
  final remainingEdges = <SceneEdge>[];
  for (final edge in scene.graph.edges) {
    if (edge.fromNodeId == nodeId || edge.toNodeId == nodeId) {
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
          if (node.id != nodeId) node,
      ],
      edges: remainingEdges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        for (final layout in scene.layout.nodeLayouts)
          if (layout.nodeId != nodeId) layout,
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

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
