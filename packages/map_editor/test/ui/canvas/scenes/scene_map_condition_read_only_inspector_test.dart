import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final instanceBoolean in [false, true]) {
    for (final expected in [false, true]) {
      testWidgets(
        '${instanceBoolean ? 'instance boolean' : 'entity anchor'} $expected remains read only and unchanged',
        (tester) async {
          _prepareView(tester);
          final source = instanceBoolean
              ? SceneConditionSource.mapEventInstanceBoolean(
                  mapId: 'map-original',
                  eventId: 'door-owner',
                  key: 'A',
                  expected: expected,
                )
              : SceneConditionSource.playerAtEntityAnchor(
                  mapId: 'map-original',
                  entityId: 'door-owner',
                  expected: expected,
                );
          final before = jsonEncode(source.toJson());
          final updates = <SceneConditionSource>[];
          await tester.pumpWidget(_inspector(source, updates));
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.text(source.sourceKind.name), findsOneWidget);
          expect(find.text(source.sourceId), findsOneWidget);
          expect(find.text(source.operator.name), findsOneWidget);
          final save = find.byKey(
            const ValueKey('scene-condition-save-action'),
          );
          expect(tester.widget<PokeMapButton>(save).onPressed, isNull);
          await tester.tap(save);
          await tester.pump();
          expect(updates, isEmpty);
          expect(jsonEncode(source.toJson()), before);
          expect(source.mapId, 'map-original');
          expect(source.key, instanceBoolean ? 'A' : isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(_inspector(source, updates));
          await tester.pump();
          expect(find.text(source.sourceKind.name), findsOneWidget);
          expect(tester.widget<PokeMapButton>(save).onPressed, isNull);
          expect(updates, isEmpty);
          expect(jsonEncode(source.toJson()), before);
        },
      );
    }
  }

  testWidgets('a supported fact condition can still be saved', (tester) async {
    _prepareView(tester);
    final source = SceneConditionSource.factValue(
      factId: 'ready',
      operator: NarrativeFactOperator.equals,
      expectedValue: const NarrativeValue.boolean(true),
    );
    final updates = <SceneConditionSource>[];
    await tester.pumpWidget(_inspector(source, updates));
    await tester.pump();
    final save = find.byKey(const ValueKey('scene-condition-save-action'));
    expect(tester.widget<PokeMapButton>(save).onPressed, isNotNull);
    await tester.tap(save);
    await tester.pump();
    expect(updates, hasLength(1));
    expect(updates.single.sourceKind, SceneConditionSourceKind.fact);
    expect(updates.single.sourceId, 'ready');
    expect(
      updates.single.resolvedExpectedFactValue,
      const NarrativeValue.boolean(true),
    );
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
          conditionSourceOptions: const [
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
