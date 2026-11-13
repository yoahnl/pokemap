import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:map_core/map_core_domain.dart';

SceneNode startNode([String id = 'start']) =>
    SceneNode(id: id, kind: SceneNodeKind.start);

SceneNode endNode(String id) => SceneNode(id: id, kind: SceneNodeKind.end);

SceneNode waitNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.interactive(
    SceneInteractiveCommand.wait(durationMs: 10),
  ),
);

SceneNode pcNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.interactive(SceneInteractiveCommand.openPc()),
);

SceneNode giveNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.interactive(
    SceneInteractiveCommand.giveItem(itemId: 'potion', quantity: 1),
  ),
);

SceneNode soundNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.interactive(
    SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'sfx', volume: 1),
  ),
);

SceneNode factNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.consequence(
    SceneConsequence.setFact(factId: 'met', value: true),
  ),
);

SceneConditionPayload weekdayCondition() => SceneConditionPayload(
  conditionLabel: 'Monday',
  conditionSource: SceneConditionSource.civilWeekday(
    weekday: CivilWeekday.monday,
    expectedValue: true,
  ),
);

SceneNode conditionNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.condition,
  payload: weekdayCondition(),
);

SceneNode dialogueNode(String id, [List<String> outcomes = const []]) =>
    SceneNode(
      id: id,
      kind: SceneNodeKind.yarnDialogue,
      payload: SceneYarnDialoguePayload(
        dialogueId: 'talk',
        expectedOutcomes: outcomes,
      ),
    );

SceneNode battleNode(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.battle,
  payload: SceneBattlePayload(battleKind: 'trainer', trainerId: 'rival'),
);

SceneNode mergeNode(String id) => SceneNode(id: id, kind: SceneNodeKind.merge);

SceneNode routerNode(String id, String sourceNodeId) => SceneNode(
  id: id,
  kind: SceneNodeKind.branchByOutcome,
  payload: SceneBranchByOutcomePayload(sourceNodeId: sourceNodeId),
);

SceneEdge link(String from, String to, {String port = 'completed'}) =>
    SceneEdge(
      id: '$from.$port',
      fromNodeId: from,
      fromPortId: port,
      toNodeId: to,
      kind: switch (port) {
        'true' => SceneEdgeKind.conditionTrue,
        'false' => SceneEdgeKind.conditionFalse,
        'completed' => SceneEdgeKind.defaultFlow,
        _ => SceneEdgeKind.actionCompleted,
      },
    );

SceneGraph graphOf(List<SceneNode> nodes, List<SceneEdge> edges) =>
    SceneGraph(startNodeId: 'start', nodes: nodes, edges: edges);

SceneAsset sceneOf(List<SceneNode> nodes, List<SceneEdge> edges) => SceneAsset(
  id: 'scene',
  name: 'Scene',
  graph: graphOf(nodes, edges),
  layout: SceneGraphLayout(
    nodeLayouts: [
      for (final (index, node) in nodes.indexed)
        SceneNodeLayout(nodeId: node.id, x: index * 100.0, y: index * 10.0),
    ],
    edgeLayouts: [
      for (final edge in edges)
        SceneEdgeLayout(
          edgeId: edge.id,
          controlPoints: [SceneLayoutPoint(x: 1, y: 2)],
        ),
    ],
  ),
);

SceneStepIds countingIds() {
  var nodes = 0;
  var edges = 0;
  return SceneStepIds(
    node: () => 'new_node_${++nodes}',
    edge: () => 'new_edge_${++edges}',
  );
}
