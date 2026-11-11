import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

Map<String, dynamic> _target({String mapId = 'map', String? entityId}) => {
  'kind': entityId == null ? 'player' : 'entity',
  'mapId': mapId,
  'entityId': ?entityId,
};

Map<String, dynamic> _route({
  Map<String, dynamic>? target,
  List<Map<String, dynamic>>? steps,
}) => {
  'kind': 'actorRoute',
  'target': target ?? _target(entityId: 'door'),
  'steps':
      steps ??
      [
        {'kind': 'face', 'direction': 'south'},
        {'kind': 'move', 'direction': 'south', 'durationMs': 200},
        {'kind': 'wait', 'durationMs': 0},
        {'kind': 'through', 'enabled': true},
        {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': 0.8},
      ],
  'skippable': false,
};

Map<String, dynamic> _visibility({Map<String, dynamic>? target}) => {
  'kind': 'actorVisibility',
  'target': target ?? _target(entityId: 'door'),
  'visible': false,
};

SceneAsset _scene(Map<String, dynamic> wire) => SceneAsset(
  id: 'scene',
  name: 'Scene',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'actor',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.fromJson(wire),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'actor',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: port,
          fromNodeId: 'actor',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

void main() {

  test(
    'actor world actions compile with the guided publication gate open',
    () {
      for (final wire in [_route(), _visibility()]) {
        final scene = _scene(wire);
        final node = scene.graph.nodes[1];
        expect(
          sceneExecutionCapabilityForNode(SceneExecutionProfile.world, node),
          SceneExecutionCapabilityIds.worldAction,
        );
        final plan = buildSceneRuntimePlan(scene);
        expect(plan.canBuild, isTrue);
        expect(
          plan.plan!.nodes[1].intent.kind,
          SceneRuntimePlanIntentKind.executeInteractiveCommand,
        );
        expect(
          NarrativeCommandCatalog.canonical()
              .byId(wire['kind'] as String)!
              .isPublishable,
          isTrue,
        );
      }
    },
  );

}
