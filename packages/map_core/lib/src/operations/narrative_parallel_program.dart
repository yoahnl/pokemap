import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';

List<String> validateNarrativeParallelProgram(
  SceneAsset scene, {
  String? ownerMapId,
}) {
  final issues = <String>[];
  if (scene.executionProfile != SceneExecutionProfile.world ||
      scene.declaredOutcomes.isNotEmpty) {
    issues.add('Parallel programs require a world Scene without outcomes.');
  }
  final graph = scene.graph;
  if (graph.nodes.length > 64 || graph.edges.length > 128) {
    issues.add('Parallel programs permit at most 64 nodes and 128 edges.');
    return List.unmodifiable(issues);
  }
  for (final node in graph.nodes) {
    final payload = node.payload;
    switch (payload) {
      case SceneStartPayload():
      case SceneMergePayload():
        break;
      case SceneEndPayload():
        if (payload.sceneOutcomeId != null || payload.outcomePolicy != null) {
          issues.add('Parallel terminal ${node.id} cannot publish an outcome.');
        }
      case SceneConditionPayload():
        if (ownerMapId != null &&
            payload.conditionSource?.sourceKind ==
                SceneConditionSourceKind.mapEventInstanceBoolean &&
            payload.conditionSource?.mapId != ownerMapId) {
          issues.add(
            'Parallel instance conditions must stay on their owner map.',
          );
        }
        if (payload.conditionSource == null ||
            !const {
              SceneConditionSourceKind.fact,
              SceneConditionSourceKind.integerComparison,
              SceneConditionSourceKind.mapEventInstanceBoolean,
              SceneConditionSourceKind.inventoryItem,
            }.contains(payload.conditionSource!.sourceKind)) {
          issues.add(
            'Parallel condition ${node.id} must read supported canonical state.',
          );
        }
      case SceneActionPayload():
        final effect = payload.consequence;
        if (ownerMapId != null &&
            effect is SceneSetMapEventInstanceBooleanConsequence &&
            effect.mapId != ownerMapId) {
          issues.add('Parallel instance writes must stay on their owner map.');
        }
        if (payload.interactiveCommand != null ||
            payload.preSessionInteraction != null ||
            payload.actionKind != null ||
            payload.parameters.isNotEmpty ||
            payload.consequence == null ||
            !const {
              SceneConsequenceKind.setFact,
              SceneConsequenceKind.adjustIntegerFact,
              SceneConsequenceKind.setMapEventInstanceBoolean,
            }.contains(payload.consequence!.kind)) {
          issues.add(
            'Parallel action ${node.id} must only update facts or map instance booleans.',
          );
        }
      default:
        issues.add(
          'Parallel node ${node.id} cannot perform ${node.kind.name}.',
        );
    }
  }
  final outgoing = <String, List<String>>{};
  for (final edge in graph.edges) {
    outgoing.putIfAbsent(edge.fromNodeId, () => []).add(edge.toNodeId);
  }
  final visiting = <String>{};
  final visited = <String>{};
  bool visit(String id) {
    if (visiting.contains(id)) return false;
    if (!visited.add(id)) return true;
    visiting.add(id);
    for (final next in outgoing[id] ?? const <String>[]) {
      if (!visit(next)) return false;
    }
    visiting.remove(id);
    return true;
  }

  for (final node in graph.nodes) {
    if (!visit(node.id)) {
      issues.add('Parallel programs must be acyclic.');
      break;
    }
    if (node.kind != SceneNodeKind.end &&
        (outgoing[node.id]?.isEmpty ?? true)) {
      issues.add('Parallel path at ${node.id} must terminate explicitly.');
    }
    if (node.kind == SceneNodeKind.end &&
        (outgoing[node.id]?.isNotEmpty ?? false)) {
      issues.add('Parallel terminal ${node.id} cannot continue.');
    }
  }
  return List.unmodifiable(issues);
}
