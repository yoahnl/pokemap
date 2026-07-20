import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('authors an explicit retryable policy from the End inspector',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? updatedNodeId;
    String? updatedOutcomeId;
    SceneOutcomePolicy? updatedPolicy;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 1600,
            child: SceneNodeReadOnlyInspector(
              scene: _summary(),
              selectedNodeId: 'node_end',
              onUpdateEndPayload: ({
                required nodeId,
                sceneOutcomeId,
                required outcomePolicy,
              }) async {
                updatedNodeId = nodeId;
                updatedOutcomeId = sceneOutcomeId;
                updatedPolicy = outcomePolicy;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final picker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('scene-end-outcome-policy-picker')),
    );
    expect(picker.value, 'unset');
    expect(find.text('À définir'), findsOneWidget);

    picker.onChanged('retryable');
    await tester.pump();

    expect(updatedNodeId, 'node_end');
    expect(updatedOutcomeId, 'defeat');
    expect(updatedPolicy, SceneOutcomePolicy.retryable);
  });
}

NarrativeSceneSummary _summary() {
  final outcomes = [SceneOutcome(id: 'defeat', label: 'Défaite')];
  final scene = SceneAsset(
    id: 'scene_retry_authoring',
    name: 'Retry authoring',
    declaredOutcomes: outcomes,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'defeat'),
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
  );
  return NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    nodeCount: scene.graph.nodes.length,
    edgeCount: scene.graph.edges.length,
    declaredOutcomeCount: outcomes.length,
    declaredOutcomes: outcomes.map((outcome) => outcome.label).toList(),
    tags: const [],
    graph: scene.graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
    outcomeDefinitions: outcomes,
  );
}
