import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SceneNode _node(String factId) => SceneNode(
    id: 'adjust',
    kind: SceneNodeKind.action,
    title: 'Original counter',
    payload: SceneActionPayload.consequence(SceneConsequence.adjustIntegerFact(
        factId: factId, delta: -2, minimum: -5, maximum: 8)));

ProjectManifest _project() => ProjectManifest(
      name: 'Typed counter',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
            id: 'counter',
            label: 'Counter',
            initialValue: NarrativeValue.integer(0)),
        NarrativeFactDefinition(id: 'flag', label: 'Flag')
      ],
      scenes: [
        SceneAsset(
            id: 'scene',
            name: 'Original',
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              _node('counter'),
              SceneNode(id: 'end', kind: SceneNodeKind.end)
            ], edges: [
              SceneEdge(
                  id: 'enter',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'adjust',
                  kind: SceneEdgeKind.defaultFlow),
              SceneEdge(
                  id: 'leave',
                  fromNodeId: 'adjust',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted),
            ]),
            layout: SceneGraphLayout(
                nodeLayouts: [SceneNodeLayout(nodeId: 'adjust', x: 41, y: 83)]))
      ],
    );

void main() {
  test(
      'scene mutation descriptors publish the exact integer adjustment contract',
      () {
    for (final id in ['scene.upsert', 'scene.graph.patch']) {
      final descriptor =
          SceneActions.descriptors.singleWhere((entry) => entry.id == id);
      final contract = descriptor.extensions['adjustIntegerFact'];
      expect(contract, isA<Map>());
      final fields = contract as Map;
      expect(fields['consequenceKind'], 'adjustIntegerFact');
      expect(fields['parameters'], ['factId', 'delta', 'minimum', 'maximum']);
      expect(fields['factReference'], 'knownUniqueIntegerFact');
      expect(fields['operation'], 'clamp(current + delta, minimum, maximum)');
      expect(fields['persistentField'], 'narrativeFactRuntimeState');
    }
  });

  test(
      'canonical graph authoring retains typed adjustment and untouched graph data',
      () {
    final original = _project();
    final edited = const SceneActions().patchGraph(original,
        maps: const [], sceneId: 'scene', upsertNodes: [_node('counter')]);
    final loaded = ProjectManifest.fromJson(edited.toJson());
    final scene = loaded.scenes.single;
    final payload = scene.graph.nodes
        .singleWhere((node) => node.id == 'adjust')
        .payload as SceneActionPayload;
    expect(payload.consequence,
        (_node('counter').payload as SceneActionPayload).consequence);
    expect(scene.layout, original.scenes.single.layout);
    expect(scene.graph.edges, original.scenes.single.graph.edges);
  });

  for (final target in ['flag', 'missing']) {
    test('canonical authoring refuses $target without mutating the project',
        () {
      final original = _project();
      final before = original.toJson();
      expect(
          () => const SceneActions().patchGraph(original,
              maps: const [], sceneId: 'scene', upsertNodes: [_node(target)]),
          throwsA(isA<NarrativeAuthoringException>()));
      expect(original.toJson(), before);
    });
  }
}
