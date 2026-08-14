import '../models/map_data.dart';
import '../models/enums.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../read_models/narrative_dependency_index.dart';

/// One structural Scene dependency on a public Dialogue outcome.
///
/// The path is deliberately machine-readable enough for a preview UI while
/// the stable ids remain the source of truth. Human labels are never used to
/// decide which Dialogue owns the outcome.
final class DialogueOutcomeSceneUsage {
  const DialogueOutcomeSceneUsage({
    required this.dialogueId,
    required this.outcomeId,
    required this.sceneId,
    required this.nodeId,
    required this.path,
  });

  final String dialogueId;
  final String outcomeId;
  final String sceneId;
  final String nodeId;
  final String path;
}

/// Collects every Scene payload or port that would be orphaned if an outcome
/// disappeared from [dialogueId]. Legacy `completed` flow is intentionally
/// excluded because it remains the backwards-compatible default port.
List<DialogueOutcomeSceneUsage> collectDialogueOutcomeSceneUsages(
  ProjectManifest project, {
  required String dialogueId,
  String? outcomeId,
}) {
  final normalizedDialogueId = dialogueId.trim();
  final normalizedOutcomeId = outcomeId?.trim();
  final usages = <DialogueOutcomeSceneUsage>[];

  bool accepts(String candidate) =>
      candidate != 'completed' &&
      (normalizedOutcomeId == null || candidate == normalizedOutcomeId);

  for (final scene in project.scenes) {
    final dialogueNodeIds = <String>{};
    for (var nodeIndex = 0;
        nodeIndex < scene.graph.nodes.length;
        nodeIndex += 1) {
      final node = scene.graph.nodes[nodeIndex];
      final payload = node.payload;
      if (payload is! SceneYarnDialoguePayload ||
          payload.dialogueId != normalizedDialogueId) {
        continue;
      }
      dialogueNodeIds.add(node.id);
      for (var outcomeIndex = 0;
          outcomeIndex < payload.expectedOutcomes.length;
          outcomeIndex += 1) {
        final candidate = payload.expectedOutcomes[outcomeIndex];
        if (!accepts(candidate)) continue;
        usages.add(
          DialogueOutcomeSceneUsage(
            dialogueId: normalizedDialogueId,
            outcomeId: candidate,
            sceneId: scene.id,
            nodeId: node.id,
            path: 'scenes[${scene.id}].graph.nodes[$nodeIndex].payload.'
                'expectedOutcomes[$outcomeIndex]',
          ),
        );
      }
    }

    final deferredBranchNodeIds = <String>{
      for (final node in scene.graph.nodes)
        if (node.payload case SceneBranchByOutcomePayload(:final sourceNodeId))
          if (dialogueNodeIds.contains(sourceNodeId)) node.id,
    };
    for (var edgeIndex = 0;
        edgeIndex < scene.graph.edges.length;
        edgeIndex += 1) {
      final edge = scene.graph.edges[edgeIndex];
      if (!dialogueNodeIds.contains(edge.fromNodeId) &&
          !deferredBranchNodeIds.contains(edge.fromNodeId)) {
        continue;
      }
      if (!accepts(edge.fromPortId)) continue;
      usages.add(
        DialogueOutcomeSceneUsage(
          dialogueId: normalizedDialogueId,
          outcomeId: edge.fromPortId,
          sceneId: scene.id,
          nodeId: edge.fromNodeId,
          path: 'scenes[${scene.id}].graph.edges[$edgeIndex].fromPortId',
        ),
      );
    }
  }

  usages.sort((a, b) {
    final sceneOrder = a.sceneId.compareTo(b.sceneId);
    if (sceneOrder != 0) return sceneOrder;
    final nodeOrder = a.nodeId.compareTo(b.nodeId);
    if (nodeOrder != 0) return nodeOrder;
    return a.path.compareTo(b.path);
  });
  return List<DialogueOutcomeSceneUsage>.unmodifiable(usages);
}

/// Returns a project candidate where all Scene references to one public
/// Dialogue outcome have been rewritten. The Dialogue declaration itself is
/// intentionally left to the caller so a dependency preview can show both
/// halves before committing them atomically.
ProjectManifest replaceDialogueOutcomeSceneReferences(
  ProjectManifest project, {
  required String dialogueId,
  required String fromOutcomeId,
  required String toOutcomeId,
}) {
  final normalizedDialogueId = dialogueId.trim();
  final from = fromOutcomeId.trim();
  final to = toOutcomeId.trim();
  if (normalizedDialogueId.isEmpty || from.isEmpty || to.isEmpty) {
    throw ArgumentError('Dialogue and outcome ids must not be blank.');
  }
  if (from == 'completed' || to == 'completed') {
    throw ArgumentError('The legacy completed port cannot be replaced.');
  }
  if (from == to) return project;

  final updatedScenes = <SceneAsset>[];
  for (final scene in project.scenes) {
    final dialogueNodeIds = <String>{};
    final updatedNodes = <SceneNode>[];
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneYarnDialoguePayload &&
          payload.dialogueId == normalizedDialogueId) {
        dialogueNodeIds.add(node.id);
        final expectedOutcomes = <String>[];
        for (final outcome in payload.expectedOutcomes) {
          final replacement = outcome == from ? to : outcome;
          if (!expectedOutcomes.contains(replacement)) {
            expectedOutcomes.add(replacement);
          }
        }
        updatedNodes.add(
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: SceneYarnDialoguePayload(
              dialogueId: payload.dialogueId,
              yarnNodeName: payload.yarnNodeName,
              expectedOutcomes: expectedOutcomes,
              speakerHints: payload.speakerHints,
            ),
          ),
        );
      } else {
        updatedNodes.add(node);
      }
    }
    final deferredBranchNodeIds = <String>{
      for (final node in updatedNodes)
        if (node.payload case SceneBranchByOutcomePayload(:final sourceNodeId))
          if (dialogueNodeIds.contains(sourceNodeId)) node.id,
    };
    final updatedEdges = [
      for (final edge in scene.graph.edges)
        if ((dialogueNodeIds.contains(edge.fromNodeId) ||
                deferredBranchNodeIds.contains(edge.fromNodeId)) &&
            edge.fromPortId == from)
          SceneEdge(
            id: edge.id,
            fromNodeId: edge.fromNodeId,
            fromPortId: to,
            toNodeId: edge.toNodeId,
            kind: edge.kind,
            label: edge.label,
          )
        else
          edge,
    ];
    updatedScenes.add(
      SceneAsset(
        id: scene.id,
        name: scene.name,
        executionProfile: scene.executionProfile,
        description: scene.description,
        storylineId: scene.storylineId,
        chapterId: scene.chapterId,
        tags: scene.tags,
        graph: SceneGraph(
          startNodeId: scene.graph.startNodeId,
          nodes: updatedNodes,
          edges: updatedEdges,
        ),
        layout: scene.layout,
        declaredOutcomes: scene.declaredOutcomes,
        metadata: scene.metadata,
      ),
    );
  }
  return project.copyWith(scenes: updatedScenes);
}

/// Collecte les identifiants de dialogue référencés directement par les
/// données de [map]. Les identifiants vides sont ignorés et les doublons
/// éliminés.
///
/// Sans [dependencyIndex], conserve le scan historique borné aux dialogues
/// principaux des PNJ et des panneaux.
///
/// Avec [dependencyIndex], l'index est la source de vérité et doit avoir été
/// construit avec la version courante de [map]. Sont alors inclus les
/// dialogues principaux, de défaite et conditionnels des PNJ, les panneaux et
/// les effets de dialogue des éléments placés. Aucun fallback ni fusion avec
/// le scan historique n'est effectué.
///
/// Les références appartenant à un autre asset, même s'il cible cette carte,
/// ne sont pas incluses.
Set<String> collectDialogueIdsReferencedOnMap(
  MapData map, {
  NarrativeDependencyIndex? dependencyIndex,
}) {
  if (dependencyIndex != null) {
    return <String>{
      for (final usage in dependencyIndex.usages)
        if (usage.target.kind == NarrativeDependencyTargetKind.dialogue &&
            usage.owner.physicalMapId == map.id)
          usage.target.id,
    };
  }
  final ids = <String>{};
  for (final e in map.entities) {
    switch (e.kind) {
      case MapEntityKind.npc:
        final id = e.npc?.dialogue?.dialogueId.trim();
        if (id != null && id.isNotEmpty) ids.add(id);
        break;
      case MapEntityKind.sign:
        final id = e.sign?.dialogue?.dialogueId.trim();
        if (id != null && id.isNotEmpty) ids.add(id);
        break;
      default:
        break;
    }
  }
  return ids;
}

/// Fusionne les références de plusieurs cartes.
Set<String> collectDialogueIdsReferencedOnMaps(
  Iterable<MapData> maps, {
  NarrativeDependencyIndex? dependencyIndex,
}) {
  final all = <String>{};
  for (final m in maps) {
    all.addAll(
      collectDialogueIdsReferencedOnMap(
        m,
        dependencyIndex: dependencyIndex,
      ),
    );
  }
  return all;
}
