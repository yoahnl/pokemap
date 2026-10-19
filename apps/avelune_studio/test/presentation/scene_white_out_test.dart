import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    testWidgets('Studio whiteOut guide is available only in $dimension', (
      tester,
    ) async {
      SceneNodePayload? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionForm(
                project: _project(dimension),
                current: null,
                onApply: (value) => submitted = value,
              ),
            ),
          ),
        ),
      );
      final pickerFinder = find.byWidgetPredicate(
        (widget) => widget is StudioSelect && widget.label == 'Commande',
      );
      final picker = tester.widget<StudioSelect>(pickerFinder);
      expect(
        picker.options.containsKey('whiteOut'),
        dimension == ProjectDimension.twoD,
      );
      if (dimension == ProjectDimension.twoD) {
        picker.onChanged!('whiteOut');
        await tester.pump();
        expect(
          find.textContaining('Une seule récupération par Scene'),
          findsOneWidget,
        );
        final apply = find.byWidgetPredicate(
          (widget) =>
              widget is StudioButton && widget.label == 'Ajouter l’action',
        );
        tester.widget<StudioButton>(apply).onPressed!();
        expect(
          (submitted! as SceneActionPayload).interactiveCommand!.toJson(),
          {'kind': 'whiteOut'},
        );
      }
    });

    testWidgets('Studio battle recovery picker preserves graph in $dimension', (
      tester,
    ) async {
      final scene = _battleScene();
      final session = SceneEditSession(scene, base: scene);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 450,
              height: 600,
              child: SceneInspector(
                session: session,
                project: _project(dimension),
                nodeId: 'battle',
                edgeId: null,
                changed: () {},
                onDocument: (_) {},
                onDelete: () {},
                onDuplicate: () {},
              ),
            ),
          ),
        ),
      );
      final picker = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('scene-battle-defeat-recovery-picker')),
      );
      expect(picker.value, 'continueScene');
      expect(picker.onChanged == null, dimension != ProjectDimension.twoD);
      picker.onChanged?.call('returnToRecoveryPoint');
      expect(
        (session.current.graph.nodes
                    .singleWhere((node) => node.id == 'battle')
                    .payload
                as SceneBattlePayload)
            .defeatRecovery,
        dimension == ProjectDimension.twoD
            ? SceneBattleDefeatRecovery.returnToRecoveryPoint
            : SceneBattleDefeatRecovery.continueScene,
      );
      expect(session.current.graph.edges, scene.graph.edges);
      expect(session.current.layout, scene.layout);
      expect(session.current.metadata, scene.metadata);
    });
  }
}

ProjectManifest _project(ProjectDimension dimension) => ProjectManifest(
  name: 'Recovery',
  maps: const [],
  tilesets: const [],
  settings: ProjectSettings(dimension: dimension),
  scenes: [_battleScene()],
  trainers: const [
    ProjectTrainerEntry(
      id: 'rival',
      name: 'Rival',
      trainerClass: 'Rival',
      team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)],
    ),
  ],
);

SceneAsset _battleScene() => SceneAsset(
  id: 'scene',
  name: 'Rival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'battle',
        kind: SceneNodeKind.battle,
        payload: SceneBattlePayload(battleKind: 'trainer', trainerId: 'rival'),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'battle',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'win',
        fromNodeId: 'battle',
        fromPortId: 'victory',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleVictory,
      ),
      SceneEdge(
        id: 'lose',
        fromNodeId: 'battle',
        fromPortId: 'defeat',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  ),
);
