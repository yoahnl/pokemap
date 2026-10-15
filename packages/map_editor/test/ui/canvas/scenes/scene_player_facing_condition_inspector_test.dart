import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';

void main() {
  testWidgets('facing condition has guided direction and negation controls', (
    tester,
  ) async {
    _prepareView(tester);
    final source = SceneConditionSource.playerFacing(
      direction: EntityFacing.north,
    );
    final updates = <SceneConditionSource>[];
    await tester.pumpWidget(_inspector(source, updates));
    await tester.pump();
    expect(find.text('Orientation du joueur'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('scene-condition-source-option-playerFacing-west'),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('scene-condition-operator-isFalse')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scene-condition-save-action')));
    await tester.pump();
    expect(updates, hasLength(1));
    expect(updates.single.playerFacingDirection, EntityFacing.west);
    expect(updates.single.operator, SceneConditionOperator.isFalse);
    expect(source.playerFacingDirection, EntityFacing.north);
    expect(tester.takeException(), isNull);
  });
}

void _prepareView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _inspector(
  SceneConditionSource source,
  List<SceneConditionSource> updates,
) {
  final scene = SceneAsset(
    id: 'scene-condition',
    name: 'Condition originale',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(conditionSource: source),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start-condition',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'condition',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
  final summary = NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    nodeCount: scene.graph.nodes.length,
    edgeCount: scene.graph.edges.length,
    declaredOutcomeCount: 0,
    declaredOutcomes: const [],
    tags: const [],
    graph: scene.graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
  );
  return MaterialApp(
    theme: PokeMapTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: 420,
        height: 2300,
        child: SceneNodeReadOnlyInspector(
          scene: summary,
          selectedNodeId: 'condition',
          conditionSourceOptions: [
            for (final direction in EntityFacing.values)
              SceneConditionSourcePickerOption(
                sourceKind: SceneConditionSourceKind.playerFacing,
                sourceId: direction.name,
                label: direction.name,
                debugTechnicalLabel: direction.name,
              ),
            SceneConditionSourcePickerOption(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: 'ready',
              label: 'Prêt',
              debugTechnicalLabel: 'ready',
            ),
          ],
          onUpdateConditionSource: ({required nodeId, required source}) async {
            updates.add(source);
            return true;
          },
        ),
      ),
    ),
  );
}
