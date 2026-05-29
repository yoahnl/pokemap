import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneAsset construction', () {
    test('accepts a minimal scene with start and end nodes', () {
      final scene = _minimalScene();

      expect(scene.id, 'scene_intro');
      expect(scene.name, 'Intro scene');
      expect(scene.graph.startNodeId, 'node_start');
      expect(scene.graph.nodes, hasLength(2));
      expect(scene.graph.edges, hasLength(1));
      expect(scene.layout.nodeLayouts, hasLength(2));
      expect(scene.declaredOutcomes, isEmpty);
      expect(scene.metadata, isEmpty);
    });

    test('keeps graph logic and editor layout separated', () {
      final scene = _minimalScene();

      expect(scene.graph.toJson(), isNot(contains('nodeLayouts')));
      expect(scene.layout.toJson()['nodeLayouts'], isA<List<dynamic>>());
      expect(scene.layout.nodeLayouts.first.nodeId, 'node_start');
    });

    test('exposes V0 node and edge taxonomy', () {
      expect(SceneNodeKind.start, isA<SceneNodeKind>());
      expect(SceneNodeKind.end, isA<SceneNodeKind>());
      expect(SceneNodeKind.yarnDialogue, isA<SceneNodeKind>());
      expect(SceneNodeKind.condition, isA<SceneNodeKind>());
      expect(SceneNodeKind.action, isA<SceneNodeKind>());
      expect(SceneNodeKind.battle, isA<SceneNodeKind>());
      expect(SceneNodeKind.cinematic, isA<SceneNodeKind>());
      expect(SceneNodeKind.branchByOutcome, isA<SceneNodeKind>());
      expect(SceneNodeKind.merge, isA<SceneNodeKind>());

      expect(SceneEdgeKind.defaultFlow, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.conditionTrue, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.conditionFalse, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.dialogueOutcome, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.battleVictory, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.battleDefeat, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.cinematicCompleted, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.actionCompleted, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.branchOutcome, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.error, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.blocked, isA<SceneEdgeKind>());
    });
  });

  group('SceneAsset validation', () {
    test('rejects blank core identifiers and names', () {
      expect(() => SceneAsset(id: '', name: 'Scene', graph: _graph()), _throws);
      expect(
          () => SceneAsset(id: 'scene', name: ' ', graph: _graph()), _throws);
      expect(
        () => SceneGraph(startNodeId: '', nodes: _nodes()),
        _throws,
      );
      expect(
        () => SceneNode(id: '', kind: SceneNodeKind.start),
        _throws,
      );
      expect(
        () => SceneEdge(
          id: '',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
        _throws,
      );
      expect(
        () => SceneOutcome(id: '', label: 'Completed'),
        _throws,
      );
      expect(
        () => SceneOutcome(id: 'completed', label: ''),
        _throws,
      );
    });

    test('rejects duplicate graph, layout and outcome ids', () {
      expect(
        () => SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_start', kind: SceneNodeKind.end),
          ],
        ),
        _throws,
      );
      expect(
        () => SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: _graph(),
          layout: SceneGraphLayout(
            nodeLayouts: [
              SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
              SceneNodeLayout(nodeId: 'node_start', x: 32, y: 0),
            ],
          ),
        ),
        _throws,
      );
      expect(
        () => SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: _graph(),
          declaredOutcomes: [
            SceneOutcome(id: 'done', label: 'Done'),
            SceneOutcome(id: 'done', label: 'Done again'),
          ],
        ),
        _throws,
      );
    });

    test('rejects missing start node and broken edge references', () {
      expect(
        () => SceneGraph(
          startNodeId: 'missing',
          nodes: _nodes(),
        ),
        _throws,
      );
      expect(
        () => SceneGraph(
          startNodeId: 'node_start',
          nodes: _nodes(),
          edges: [
            SceneEdge(
              id: 'edge_missing_target',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'missing',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        _throws,
      );
      expect(
        () => SceneEdge(
          id: 'edge',
          fromNodeId: 'node_start',
          fromPortId: '',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
        _throws,
      );
    });

    test('rejects payloads attached to incompatible node kinds', () {
      expect(
        () => SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.condition,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_intro'),
        ),
        _throws,
      );
    });
  });

  group('SceneAsset authoring guarantees', () {
    test('keeps ids stable when user-facing names are renamed', () {
      final before = _minimalScene();
      final after = SceneAsset(
        id: before.id,
        name: 'Renamed scene',
        description: before.description,
        graph: before.graph,
        layout: before.layout,
      );

      expect(after.id, before.id);
      expect(after.name, 'Renamed scene');
    });

    test('keeps metadata non-critical and string-only', () {
      final scene = SceneAsset(
        id: 'scene',
        name: 'Scene',
        graph: _graph(),
        metadata: const {
          'seed': 'manual_fixture',
          'notes': 'non critical',
        },
      );

      expect(scene.metadata['seed'], 'manual_fixture');
      expect(scene.toJson()['metadata'], isA<Map<String, String>>());
    });
  });
}

final Matcher _throws = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

SceneAsset _minimalScene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    description: 'A minimal orchestration scene.',
    graph: _graph(),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 0),
      ],
    ),
  );
}

SceneGraph _graph() {
  return SceneGraph(
    startNodeId: 'node_start',
    nodes: _nodes(),
    edges: [
      SceneEdge(
        id: 'edge_start_end',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  );
}

List<SceneNode> _nodes() {
  return [
    SceneNode(id: 'node_start', kind: SceneNodeKind.start),
    SceneNode(id: 'node_end', kind: SceneNodeKind.end),
  ];
}
