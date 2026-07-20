import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_graph_editor.dart';

void main() {
  testWidgets('duplicates the selected node through the graph editor', (
    tester,
  ) async {
    String? duplicatedNodeId;
    await _pumpEditor(
      tester,
      onDuplicateNode: (nodeId) async {
        duplicatedNodeId = nodeId;
        return 'node_condition_2';
      },
    );

    await tester.tap(find.byKey(const ValueKey('scene-graph-duplicate-node')));
    await tester.pump();

    expect(duplicatedNodeId, 'node_condition');
  });

  testWidgets('previews a path from explicit condition input', (tester) async {
    await _pumpEditor(tester);

    await tester.tap(find.byKey(const ValueKey('scene-graph-toggle-dry-run')));
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey('scene-graph-preview-input-node_condition-true'),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('scene-graph-run-dry-run')));
    await tester.pump();

    expect(
      find.textContaining('node_start → node_condition → node_end_true'),
      findsOneWidget,
    );
    expect(find.textContaining('outcome : yes'), findsOneWidget);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  SceneGraphNodeDuplicator? onDuplicateNode,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SceneGraphEditor(
          scene: _summary(),
          selectedNodeId: 'node_condition',
          onDuplicateNode: onDuplicateNode,
        ),
      ),
    ),
  );
  await tester.pump();
}

NarrativeSceneSummary _summary() {
  final graph = SceneGraph(
    startNodeId: 'node_start',
    nodes: [
      SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'node_condition',
        kind: SceneNodeKind.condition,
        title: 'Le port est ouvert',
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_port_open',
            operator: SceneConditionOperator.equals,
            value: 'true',
          ),
        ),
      ),
      SceneNode(
        id: 'node_end_true',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: 'yes'),
      ),
      SceneNode(
        id: 'node_end_false',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: 'no'),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'edge_start_condition',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'edge_true',
        fromNodeId: 'node_condition',
        fromPortId: 'true',
        toNodeId: 'node_end_true',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'edge_false',
        fromNodeId: 'node_condition',
        fromPortId: 'false',
        toNodeId: 'node_end_false',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  );
  final outcomes = [
    SceneOutcome(id: 'yes', label: 'Yes'),
    SceneOutcome(id: 'no', label: 'No'),
  ];
  final scene = SceneAsset(
    id: 'scene_graph_authoring',
    name: 'Graph authoring',
    graph: graph,
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_condition', x: 320, y: 80),
        SceneNodeLayout(nodeId: 'node_end_true', x: 620, y: 30),
        SceneNodeLayout(nodeId: 'node_end_false', x: 620, y: 160),
      ],
    ),
    declaredOutcomes: outcomes,
  );
  return NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    nodeCount: graph.nodes.length,
    edgeCount: graph.edges.length,
    declaredOutcomeCount: outcomes.length,
    declaredOutcomes: outcomes.map((outcome) => outcome.label).toList(),
    tags: const [],
    graph: graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
    outcomeDefinitions: outcomes,
  );
}
