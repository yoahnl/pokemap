import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_party_condition_editor.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';

void main() {
  testWidgets(
    'party inspector exposes four typed predicates with guided references',
    (tester) async {
      _prepareView(tester);
      final updates = <SceneConditionSource>[];
      await tester.pumpWidget(
        _inspector(SceneConditionSource.partyCanReceivePokemon(), updates),
      );
      await tester.pump();
      expect(find.text('Équipe Pokémon'), findsOneWidget);
      void select(String key, String value) => tester
          .widget<PokeMapDropdownField<String>>(find.byKey(ValueKey(key)))
          .onChanged(value);
      Future<void> apply() async {
        final button = find.byKey(const ValueKey('scene-party-apply'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      select('scene-party-expected', 'false');
      await tester.pump();
      await apply();
      expect(
        updates.last.partyConditionKind,
        ScenePartyConditionKind.canReceivePokemon,
      );
      expect(updates.last.partyExpected, isFalse);
      for (final kind in [
        ScenePartyConditionKind.knowsMove,
        ScenePartyConditionKind.hasUsableMove,
      ]) {
        select('scene-party-kind', kind.name);
        await tester.pumpAndSettle();
        select('scene-party-move', 'tackle');
        await tester.pump();
        await apply();
        expect(updates.last.partyConditionKind, kind);
        expect(updates.last.partyMoveId, 'tackle');
      }
      select('scene-party-kind', 'canUseFieldAbility');
      await tester.pump();
      select('scene-party-ability', 'rock_smash');
      await tester.pump();
      await apply();
      expect(updates.last.partyFieldAbility, FieldAbility.rockSmash);
      expect(updates.last.value, 'rock_smash');
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unavailable catalogue preserves the saved reference and disables apply',
    (tester) async {
      var applied = false;
      final source = SceneConditionSource.partyKnowsMove(moveId: 'missing');
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: ScenePartyConditionEditor(
                current: source,
                loadMoves: () async => throw StateError('Unreadable'),
                onApply: (_) async {
                  applied = true;
                  return true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('indisponible ou ambigu'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-party-apply')),
            )
            .onPressed,
        isNull,
      );
      expect(applied, isFalse);
      expect(source.partyMoveId, 'missing');
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: ScenePartyConditionEditor(
                current: source,
                loadMoves: () async => {'tackle': 'Charge'},
                onApply: (_) async => true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('La capacité enregistrée est indisponible'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-party-apply')),
            )
            .onPressed,
        isNull,
      );
      expect(source.partyMoveId, 'missing');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('3D field ability notice preserves the authored false branch', (
    tester,
  ) async {
    SceneConditionSource? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: ScenePartyConditionEditor(
              dimension: ProjectDimension.threeD,
              current: SceneConditionSource.partyCanUseFieldAbility(
                ability: FieldAbility.surf,
                expected: false,
              ),
              onApply: (source) async {
                saved = source;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Player 2D'), findsOneWidget);
    expect(find.textContaining('PP0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-party-apply')));
    await tester.pumpAndSettle();
    expect(saved!.partyExpected, isFalse);
    expect(saved!.partyFieldAbility, FieldAbility.surf);
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
          loadPartyMoves: () async => {'tackle': 'Charge'},
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
