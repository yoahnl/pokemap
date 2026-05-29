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
