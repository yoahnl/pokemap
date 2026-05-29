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
