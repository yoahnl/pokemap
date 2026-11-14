import 'package:avelune_studio/features/scenes/application/scene_changed_facts.dart';
import 'package:avelune_studio/features/scenes/application/scene_path_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

SceneEdge _edge(String from, String port, String to) => SceneEdge(
  id: '$from-$port',
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: switch (port) {
    'true' => SceneEdgeKind.conditionTrue,
    'false' => SceneEdgeKind.conditionFalse,
    _ => SceneEdgeKind.defaultFlow,
  },
);

SceneNode _condition(String id) => SceneNode(
  id: id,
  kind: SceneNodeKind.condition,
  payload: SceneConditionPayload(
    conditionSource: SceneConditionSource(
      sourceKind: SceneConditionSourceKind.fact,
      sourceId: 'met',
      operator: SceneConditionOperator.isTrue,
      label: 'Rencontre',
    ),
  ),
);

void main() {
  final graph = SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      _condition('check'),
      SceneNode(
        id: 'count',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.adjustIntegerFact(
            factId: 'coins',
            delta: 1,
            minimum: 0,
            maximum: 99,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      _edge('start', 'completed', 'check'),
      _edge('check', 'false', 'end'),
      _edge('check', 'true', 'count'),
      _edge('count', 'completed', 'check'),
    ],
  );

  test('a path stops on each exit choice, in port order', () {
    final first = previewScenePath(graph, const {});
    expect(first.nodeIds, ['start', 'check']);
    expect(first.choiceNodeId, 'check');
    expect(first.exits.map((exit) => exit.portId), ['true', 'false']);
    expect(first.ended, isFalse);

    final unknown = previewScenePath(graph, const {'check': 'maybe'});
    expect(unknown.choiceNodeId, 'check');

    final ended = previewScenePath(graph, const {'check': 'false'});
    expect(ended.nodeIds, ['start', 'check', 'end']);
    expect(ended.ended, isTrue);
  });

  test('a path that comes back to a walked step stops as a loop', () {
    final looped = previewScenePath(graph, const {'check': 'true'});

    expect(looped.nodeIds, ['start', 'check', 'count']);
    expect((looped.looped, looped.ended), (true, false));
  });

  test('the changed states come from the scene consequences', () {
    expect(sceneChangedFactIds(graph), ['coins']);
  });
}
