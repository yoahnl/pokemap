import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-SCENES-V1-09 scene validation diagnostics', () {
    testWidgets('Narrative Studio exposes a real Scenes navigation entry',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.globalStory,
      );

      final sidebar = find.byKey(const ValueKey('narrative-studio-sidebar'));
      expect(sidebar, findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-studio-sidebar-scenes')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sidebar, matching: find.text('Scènes')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-studio-sidebar-scenes')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.scenes,
      );
      expect(
          find.byKey(const ValueKey('scenes-workspace-shell')), findsOneWidget);
    });

    testWidgets(
        'shows an honest empty state when ProjectManifest.scenes is empty',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
          find.byKey(const ValueKey('scenes-workspace-shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-panel')), findsOneWidget);
      expect(find.text('Arborescence des scènes'), findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-empty-state')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-summary-empty-state')),
          findsOneWidget);
      expect(find.text('Aucune scène créée'), findsOneWidget);
      expect(find.text('Liste vide'), findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-list-compact')), findsNothing);
    });

    testWidgets('does not render unsupported graph actions', (tester) async {
      final project = _projectWithScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(
          const ValueKey('scenes-open-graph-disabled-scene_test_intro'),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('scenes-open-graph-disabled')),
          findsNothing);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('creates a minimal scene draft from the Scenes workspace',
        (tester) async {
      final project = _emptyProject();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final createButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scenes-create-scene-action')).first,
      );
      expect(createButton.onPressed, isNotNull);

      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scenes-create-scene-dialog')),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scenes-create-scene-name-error')),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));

      await tester.enterText(
        find.byKey(const ValueKey('scenes-create-scene-name-field')),
        'New Draft Scene',
      );
      await tester.enterText(
        find.byKey(const ValueKey('scenes-create-scene-description-field')),
        'Created from the test flow.',
      );
      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
      await tester.pumpAndSettle();

      final updated = container.read(editorNotifierProvider).project!;
      expect(updated.scenes, hasLength(1));
      expect(updated.scenes.single.id, 'scene_new_draft_scene');
      expect(updated.scenes.single.name, 'New Draft Scene');
      expect(updated.scenes.single.description, 'Created from the test flow.');
      expect(updated.scenarios, equals(project.scenarios));
      expect(updated.storylines, equals(project.storylines));
      expect(
        find.byKey(const ValueKey('scenes-tree-item-scene_new_draft_scene')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scenes-selected-summary-scene_new_draft_scene'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_start')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_end')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_start')),
        findsOneWidget,
      );
      expect(find.text('Détails du nœud'), findsOneWidget);
      expect(find.text('node_start'), findsWidgets);
    });

    testWidgets('create scene draft handles id collisions', (tester) async {
      final project = ProjectManifest(
        name: 'Scenes shell test',
        maps: const [],
        tilesets: const [],
        scenes: [
          _sceneWithId('scene_new_draft_scene'),
        ],
      );
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('scenes-create-scene-name-field')),
        'New Draft Scene',
      );
      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
      await tester.pumpAndSettle();

      final updated = container.read(editorNotifierProvider).project!;
      expect(updated.scenes.map((scene) => scene.id), [
        'scene_new_draft_scene',
        'scene_new_draft_scene_2',
      ]);
      expect(
        find.byKey(const ValueKey('scenes-tree-item-scene_new_draft_scene_2')),
        findsOneWidget,
      );
    });

    testWidgets('adds a condition node draft from the Scenes palette',
        (tester) async {
      final project = _projectWithTwoScenes();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final originalScene = project.scenes.first;

      await tester.tap(find.byKey(const ValueKey('scenes-add-node-condition')));
      await tester.pumpAndSettle();

      final updatedProject = container.read(editorNotifierProvider).project!;
      final updatedScene = updatedProject.scenes.first;
      expect(updatedProject.scenes, hasLength(2));
      expect(updatedProject.scenes.last, project.scenes.last);
      expect(updatedScene.graph.edges, originalScene.graph.edges);
      expect(updatedScene.graph.nodes.map((node) => node.id),
          contains('node_condition'));
      expect(
        updatedScene.graph.nodes
            .firstWhere((node) => node.id == 'node_condition')
            .payload,
        isA<SceneConditionPayload>(),
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_condition')),
        findsOneWidget,
      );
      expect(find.text('node_condition'), findsWidgets);
      expect(find.text('Condition'), findsWidgets);
    });

    testWidgets('adds merge and end node drafts with no automatic edges',
        (tester) async {
      final project = _projectWithScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(find.byKey(const ValueKey('scenes-add-node-merge')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scenes-add-node-end')));
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.edges, project.scenes.single.graph.edges);
      expect(
          updatedScene.graph.nodes.map((node) => node.id),
          containsAll([
            'node_merge_2',
            'node_end_2',
          ]));
      expect(
        updatedScene.graph.nodes
            .firstWhere((node) => node.id == 'node_merge_2')
            .payload,
        isA<SceneMergePayload>(),
      );
      expect(
        updatedScene.graph.nodes
            .firstWhere((node) => node.id == 'node_end_2')
            .payload,
        isA<SceneEndPayload>(),
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_merge_2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_end_2')),
        findsOneWidget,
      );
      expect(find.text('node_end_2'), findsWidgets);
    });

    testWidgets('keeps unsupported node kinds disabled in the palette',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      for (final key in [
        'scenes-add-node-start-disabled',
        'scenes-add-node-yarn-disabled',
        'scenes-add-node-action-disabled',
        'scenes-add-node-battle-disabled',
        'scenes-add-node-cinematic-disabled',
        'scenes-add-node-branch-disabled',
      ]) {
        final button = tester.widget<PokeMapButton>(
          find.byKey(ValueKey(key)).first,
        );
        expect(button.onPressed, isNull, reason: key);
      }
      expect(find.text('Selbrume Demo'), findsNothing);
      expect(find.text('Annonce au port'), findsNothing);
    });

    testWidgets(
        'dialogue payload picker creates a Yarn node from real contracts',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithPayloadPickerContracts(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('scenes-add-node-yarn')),
      );
      await tester.tap(find.byKey(const ValueKey('scenes-add-node-yarn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-dialogue-picker-dialog')),
        findsOneWidget,
      );
      expect(find.text('Test Dialogue'), findsOneWidget);
      expect(find.text('test_dialogue'), findsWidgets);
      expect(find.text('dialogues/test_dialogue.yarn'), findsOneWidget);
      expect(
        find.text(
            'Dialogue outcomes are not exposed by a public contract yet.'),
        findsOneWidget,
      );
      expect(find.text('confident'), findsNothing);
      expect(find.text('hesitant'), findsNothing);
      expect(find.text('aggressive'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('scene-dialogue-picker-option-test_dialogue'),
        ),
      );
      await tester.pumpAndSettle();

      final scene =
          container.read(editorNotifierProvider).project!.scenes.single;
      final node = scene.graph.nodes.last;
      expect(node.kind, SceneNodeKind.yarnDialogue);
      expect(node.title, 'Test Dialogue');
      final payload = node.payload as SceneYarnDialoguePayload;
      expect(payload.dialogueId, 'test_dialogue');
      expect(payload.yarnNodeName, 'Start');
      expect(payload.expectedOutcomes, isEmpty);
      expect(
          find.byKey(ValueKey('scene-graph-node-${node.id}')), findsOneWidget);
      expect(find.text('dialogue_demo'), findsNothing);
      expect(find.text('selbrume_port'), findsNothing);
    });

    testWidgets(
        'battle payload picker creates trainer battle node from contracts',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithPayloadPickerContracts(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('scenes-add-node-battle')),
      );
      await tester.tap(find.byKey(const ValueKey('scenes-add-node-battle')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-battle-picker-dialog')),
        findsOneWidget,
      );
      expect(find.text('Trainer Test Trainer'), findsOneWidget);
      expect(find.text('test_trainer'), findsWidgets);
      expect(find.text('trainer'), findsWidgets);
      expect(find.text('victory / defeat'), findsOneWidget);
      expect(find.text('Trainer battle has no authored team yet.'),
          findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('scene-battle-picker-option-trainer_test_trainer'),
        ),
      );
      await tester.pumpAndSettle();

      final scene =
          container.read(editorNotifierProvider).project!.scenes.single;
      final node = scene.graph.nodes.last;
      expect(node.kind, SceneNodeKind.battle);
      expect(node.title, 'Trainer Test Trainer');
      final payload = node.payload as SceneBattlePayload;
      expect(payload.battleKind, 'trainer');
      expect(payload.trainerId, 'test_trainer');
      expect(payload.declaredOutcomes, ['victory', 'defeat']);
      expect(
          find.byKey(ValueKey('scene-graph-node-${node.id}')), findsOneWidget);
      expect(find.text('battle_demo'), findsNothing);
      expect(find.text('trainer_lysa'), findsNothing);
    });

    testWidgets('cinematic action and branch remain honestly disabled',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithPayloadPickerContracts(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final cinematicButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scenes-add-node-cinematic-disabled')).first,
      );
      final actionButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scenes-add-node-action-disabled')).first,
      );
      final branchButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scenes-add-node-branch-disabled')).first,
      );

      expect(cinematicButton.onPressed, isNull);
      expect(actionButton.onPressed, isNull);
      expect(branchButton.onPressed, isNull);
      expect(find.textContaining('bridge Scenario'), findsOneWidget);
      expect(find.textContaining('contrat futur'), findsOneWidget);
      expect(find.textContaining('mapping futur'), findsOneWidget);
      expect(find.text('CinematicAsset final'), findsNothing);
      expect(find.text('mael_intro'), findsNothing);
      expect(find.text('lysa_rival'), findsNothing);
    });

    testWidgets('edits a Yarn dialogue payload from real public contracts',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithEditablePayloadNodes(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_dialogue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Éditable'), findsWidgets);
      expect(find.text('Dialogue lié'), findsOneWidget);
      expect(find.text('dialogue_old'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-payload-edit-dialogue-action')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-payload-edit-dialogue-action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-dialogue-payload-edit-dialog')),
        findsOneWidget,
      );
      expect(find.text('Updated Dialogue'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('scene-dialogue-payload-edit-option-dialogue_updated'),
        ),
      );
      await tester.pumpAndSettle();

      final scene =
          container.read(editorNotifierProvider).project!.scenes.single;
      final node =
          scene.graph.nodes.firstWhere((node) => node.id == 'node_dialogue');
      final payload = node.payload as SceneYarnDialoguePayload;
      expect(payload.dialogueId, 'dialogue_updated');
      expect(payload.yarnNodeName, 'UpdatedStart');
      expect(payload.expectedOutcomes, ['accept']);
      expect(scene.graph.edges.map((edge) => edge.id), [
        'edge_dialogue_completed_end',
        'edge_battle_victory_end',
        'edge_battle_defeat_end_2',
      ]);
      expect(scene.layout.nodeLayouts.map((layout) => layout.nodeId), [
        'node_start',
        'node_dialogue',
        'node_battle',
        'node_end',
        'node_end_2',
      ]);
      expect(find.text('dialogue_updated'), findsOneWidget);
      expect(find.text('selbrume_port'), findsNothing);
    });

    testWidgets('edits a trainer battle payload from real public contracts',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithEditablePayloadNodes(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_battle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Éditable'), findsWidgets);
      expect(find.text('Combat lié'), findsOneWidget);
      expect(find.text('trainer_old'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-payload-edit-battle-action')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-payload-edit-battle-action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-battle-payload-edit-dialog')),
        findsOneWidget,
      );
      expect(find.text('Trainer Updated Trainer'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-battle-payload-edit-option-trainer_updated',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scene =
          container.read(editorNotifierProvider).project!.scenes.single;
      final node =
          scene.graph.nodes.firstWhere((node) => node.id == 'node_battle');
      final payload = node.payload as SceneBattlePayload;
      expect(payload.battleKind, 'trainer');
      expect(payload.trainerId, 'trainer_updated');
      expect(payload.declaredOutcomes, ['victory', 'defeat']);
      expect(scene.graph.edges.map((edge) => edge.id), [
        'edge_dialogue_completed_end',
        'edge_battle_victory_end',
        'edge_battle_defeat_end_2',
      ]);
      expect(scene.layout.nodeLayouts.map((layout) => layout.nodeId), [
        'node_start',
        'node_dialogue',
        'node_battle',
        'node_end',
        'node_end_2',
      ]);
      expect(find.text('trainer_updated'), findsWidgets);
      expect(find.text('trainer_lysa'), findsNothing);
    });

    testWidgets('connects start.completed to a target node explicitly',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-connect-port-completed')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-edge-connection-pending')),
        findsOneWidget,
      );
      expect(find.textContaining('node_start / completed'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.edges, hasLength(1));
      final edge = updatedScene.graph.edges.single;
      expect(edge.id, 'edge_node_start_completed_node_condition');
      expect(edge.fromNodeId, 'node_start');
      expect(edge.fromPortId, 'completed');
      expect(edge.toNodeId, 'node_condition');
      expect(edge.kind, SceneEdgeKind.defaultFlow);
      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-edge-edge_node_start_completed_node_condition',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_start')),
        findsOneWidget,
      );
      expect(
        find.text('edge_node_start_completed_node_condition'),
        findsOneWidget,
      );
      expect(project.scenes.single.graph.edges, isEmpty);
    });

    testWidgets('shows visual input and output ports for V0 nodes',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_start-completed'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-input-port-node_condition-in')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const ValueKey('scene-graph-output-port-node_condition-true')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_condition-false'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-input-port-node_merge-in')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_merge-completed'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-input-port-node_end-in')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_end-completed'),
        ),
        findsNothing,
      );
    });

    testWidgets('shows visual ports for Dialogue and Battle authoring nodes',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithDialogueBattlePortsScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(
          const ValueKey('scene-graph-input-port-node_dialogue-in'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_dialogue-completed'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-input-port-node_battle-in'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_battle-victory'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-output-port-node_battle-defeat'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'visual port drag shows preview, highlights target, and creates edge',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final output = find.byKey(
        const ValueKey('scene-graph-output-port-node_start-completed'),
      );
      final input = find.byKey(
        const ValueKey('scene-graph-input-port-node_condition-in'),
      );
      final conditionNode = find.byKey(
        const ValueKey('scene-graph-node-node_condition'),
      );
      final conditionTopLeftBeforeDrag = tester.getTopLeft(conditionNode);
      final outputHandleCenter =
          tester.getTopLeft(output) + const Offset(16, 16);
      final gesture = await tester.startGesture(outputHandleCenter);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(input));
      await tester.pump();
      expect(tester.getTopLeft(conditionNode), conditionTopLeftBeforeDrag);

      expect(
        find.byKey(const ValueKey('scene-graph-connection-preview-wire')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-input-port-hover-node_condition'),
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      final edges = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .edges;
      expect(edges, hasLength(1));
      expect(edges.single.id, 'edge_node_start_completed_node_condition');
      expect(edges.single.kind, SceneEdgeKind.defaultFlow);
      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-edge-edge_node_start_completed_node_condition',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('visual drag connects Dialogue.completed to a target node',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithDialogueBattlePortsScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final output = find.byKey(
        const ValueKey('scene-graph-output-port-node_dialogue-completed'),
      );
      final input = find.byKey(
        const ValueKey('scene-graph-input-port-node_end-in'),
      );
      final gesture = await tester.startGesture(
        tester.getTopLeft(output) + const Offset(16, 16),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(input));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('scene-graph-connection-preview-wire')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-input-port-hover-node_end')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      final edges = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .edges;
      expect(edges, hasLength(1));
      expect(edges.single.id, 'edge_node_dialogue_completed_node_end');
      expect(edges.single.fromPortId, 'completed');
      expect(edges.single.kind, SceneEdgeKind.defaultFlow);
    });

    testWidgets('visual drag connects Battle victory and defeat ports',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithDialogueBattlePortsScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final victoryOutput = find.byKey(
        const ValueKey('scene-graph-output-port-node_battle-victory'),
      );
      final victoryInput = find.byKey(
        const ValueKey('scene-graph-input-port-node_end-in'),
      );
      final victoryGesture = await tester.startGesture(
        tester.getTopLeft(victoryOutput) + const Offset(16, 16),
      );
      await tester.pump();
      await victoryGesture.moveTo(tester.getCenter(victoryInput));
      await tester.pump();
      await victoryGesture.up();
      await tester.pumpAndSettle();

      final defeatOutput = find.byKey(
        const ValueKey('scene-graph-output-port-node_battle-defeat'),
      );
      final defeatInput = find.byKey(
        const ValueKey('scene-graph-input-port-node_end_2-in'),
      );
      final defeatGesture = await tester.startGesture(
        tester.getTopLeft(defeatOutput) + const Offset(16, 16),
      );
      await tester.pump();
      await defeatGesture.moveTo(tester.getCenter(defeatInput));
      await tester.pump();
      await defeatGesture.up();
      await tester.pumpAndSettle();

      final edges = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .edges;
      expect(edges.map((edge) => (edge.fromPortId, edge.kind)), [
        ('victory', SceneEdgeKind.battleVictory),
        ('defeat', SceneEdgeKind.battleDefeat),
      ]);
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-edge_node_battle_victory_node_end'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-edge_node_battle_defeat_node_end_2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders color-coded edge paths from output ports',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(
          edges: [
            SceneEdge(
              id: 'edge_node_start_completed_node_condition',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_condition',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_node_condition_true_node_end',
              fromNodeId: 'node_condition',
              fromPortId: 'true',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'edge_node_condition_false_node_end_2',
              fromNodeId: 'node_condition',
              fromPortId: 'false',
              toNodeId: 'node_end_2',
              kind: SceneEdgeKind.conditionFalse,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-output-port-node_condition-true',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-output-port-node_condition-false',
          ),
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_15_wire_anchor_color_code.png',
        ),
      );
    });

    testWidgets('trackpad pan zoom is ignored during visual port drag',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final output = find.byKey(
        const ValueKey('scene-graph-output-port-node_start-completed'),
      );
      final conditionNode = find.byKey(
        const ValueKey('scene-graph-node-node_condition'),
      );
      final surface = find.byKey(const ValueKey('scene-graph-pan-surface'));
      final conditionTopLeftBeforeDrag = tester.getTopLeft(conditionNode);
      final outputHandleCenter =
          tester.getTopLeft(output) + const Offset(16, 16);
      final gesture = await tester.startGesture(outputHandleCenter);
      await tester.pump();

      final center = tester.getCenter(surface);
      tester.binding.handlePointerEvent(
        PointerPanZoomStartEvent(position: center),
      );
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(
          position: center,
          panDelta: const Offset(56, 24),
          scale: 1.25,
        ),
      );
      tester.binding.handlePointerEvent(
        PointerPanZoomEndEvent(position: center),
      );
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);
      expect(tester.getTopLeft(conditionNode), conditionTopLeftBeforeDrag);
      expect(
        find.byKey(const ValueKey('scene-graph-connection-preview-wire')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('visual port drop in empty canvas cancels without edge',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final output = find.byKey(
        const ValueKey('scene-graph-output-port-node_start-completed'),
      );
      final surface = find.byKey(const ValueKey('scene-graph-pan-surface'));
      final emptyPoint = tester.getBottomLeft(surface) + const Offset(32, -32);
      final outputHandleCenter =
          tester.getTopLeft(output) + const Offset(16, 16);
      final gesture = await tester.startGesture(outputHandleCenter);
      await tester.pump();
      await gesture.moveTo(emptyPoint);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('scene-graph-connection-preview-wire')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-connection-preview-wire')),
        findsNothing,
      );
      expect(container.read(editorNotifierProvider).project, project);
    });

    testWidgets('connects condition true and false ports with derived kinds',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scenes-connect-port-true')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scenes-connect-port-false')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_end_2')),
      );
      await tester.pumpAndSettle();

      final edges = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .edges;
      expect(edges, hasLength(2));
      expect(edges[0].fromPortId, 'true');
      expect(edges[0].kind, SceneEdgeKind.conditionTrue);
      expect(edges[1].fromPortId, 'false');
      expect(edges[1].kind, SceneEdgeKind.conditionFalse);
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-edge_node_condition_true_node_end'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-edge-edge_node_condition_false_node_end_2',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('edge_node_condition_true_node_end'), findsOneWidget);
      expect(find.text('edge_node_condition_false_node_end_2'), findsOneWidget);
    });

    testWidgets('disables used ports and offers no source output for end',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(
          edges: [
            SceneEdge(
              id: 'edge_node_start_completed_node_condition',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_condition',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final usedButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scenes-connect-port-completed')).first,
      );
      expect(usedButton.onPressed, isNull);
      expect(find.text('completed · connecté'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-edge-no-outputs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scenes-connect-port-completed')),
        findsNothing,
      );
    });

    testWidgets('connection mode is cancellable and local only',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-connect-port-completed')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scenes-edge-connection-pending')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-edge-connection-cancel')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-edge-connection-pending')),
        findsNothing,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('selects and deletes an edge without mutating nodes or layout',
        (tester) async {
      const edgeId = 'edge_node_start_completed_node_condition';
      final project = _projectWithEdgeAuthoringScene(
        edges: [
          SceneEdge(
            id: edgeId,
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final originalScene = project.scenes.single;
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-edge-hit-target-$edgeId')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-edge-selected-$edgeId')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-edge-read-only-inspector')),
        findsOneWidget,
      );
      expect(find.text('Lien sélectionné'), findsOneWidget);
      expect(find.text(edgeId), findsWidgets);
      expect(find.text('node_start'), findsWidgets);
      expect(find.text('completed'), findsWidgets);
      expect(find.textContaining('node_condition'), findsWidgets);
      expect(
        find.byKey(const ValueKey('scene-edge-delete-action')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('scene-edge-delete-action')));
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.edges, isEmpty);
      expect(updatedScene.graph.nodes, originalScene.graph.nodes);
      expect(updatedScene.layout, originalScene.layout);
      expect(
        find.byKey(const ValueKey('scene-graph-edge-$edgeId')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scene-edge-read-only-inspector')),
        findsNothing,
      );

      final output = find.byKey(
        const ValueKey('scene-graph-output-port-node_start-completed'),
      );
      final input = find.byKey(
        const ValueKey('scene-graph-input-port-node_condition-in'),
      );
      final gesture = await tester.startGesture(
        tester.getTopLeft(output) + const Offset(16, 16),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(input));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final recreatedEdges = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .edges;
      expect(recreatedEdges, hasLength(1));
      expect(recreatedEdges.single.id, edgeId);
    });

    testWidgets('deletes a selected V0 node and its connected edges',
        (tester) async {
      const incomingEdgeId = 'edge_node_start_completed_node_condition';
      const outgoingEdgeId = 'edge_node_condition_true_node_end';
      const keptEdgeId = 'edge_node_merge_completed_node_end_2';
      final project = _projectWithEdgeAuthoringScene(
        edges: [
          SceneEdge(
            id: incomingEdgeId,
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: outgoingEdgeId,
            fromNodeId: 'node_condition',
            fromPortId: 'true',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.conditionTrue,
          ),
          SceneEdge(
            id: keptEdgeId,
            fromNodeId: 'node_merge',
            fromPortId: 'completed',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final originalScene = project.scenes.single;
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-node-delete-action')),
        findsOneWidget,
      );
      expect(find.text('Supprimer le nœud'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-node-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scene-node-delete-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(
        updatedScene.graph.nodes.map((node) => node.id),
        isNot(contains('node_condition')),
      );
      expect(
        updatedScene.graph.edges.map((edge) => edge.id),
        [keptEdgeId],
      );
      expect(
        updatedScene.layout.nodeLayouts.map((layout) => layout.nodeId),
        isNot(contains('node_condition')),
      );
      expect(
        updatedScene.layout.nodeLayouts
            .where((layout) => layout.nodeId != 'node_condition')
            .toList(growable: false),
        originalScene.layout.nodeLayouts
            .where((layout) => layout.nodeId != 'node_condition')
            .toList(growable: false),
      );
      expect(
        originalScene.graph.nodes.map((node) => node.id),
        contains('node_condition'),
      );
      expect(originalScene.graph.edges, hasLength(3));
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-$incomingEdgeId'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-$outgoingEdgeId'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-$keptEdgeId'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_start')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-node-delete-action')),
        findsNothing,
      );
    });

    testWidgets('deletes a selected dialogue node and its connected edges',
        (tester) async {
      const incomingEdgeId = 'edge_start_dialogue';
      const outgoingEdgeId = 'edge_dialogue_end';
      final project = _projectWithDialogueBattlePortsScene(
        edges: [
          SceneEdge(
            id: incomingEdgeId,
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: outgoingEdgeId,
            fromNodeId: 'node_dialogue',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_battle_victory_end_2',
            fromNodeId: 'node_battle',
            fromPortId: 'victory',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.battleVictory,
          ),
        ],
      );
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_dialogue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone dangereuse'), findsOneWidget);
      expect(find.byKey(const ValueKey('scene-node-delete-action')),
          findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-node-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scene-node-delete-action')));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer ce nœud ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.nodes.map((node) => node.id),
          isNot(contains('node_dialogue')));
      expect(updatedScene.graph.edges.map((edge) => edge.id), [
        'edge_battle_victory_end_2',
      ]);
      expect(updatedScene.layout.nodeLayouts.map((layout) => layout.nodeId),
          isNot(contains('node_dialogue')));
      expect(find.byKey(const ValueKey('scene-graph-node-node_dialogue')),
          findsNothing);
      expect(find.byKey(const ValueKey('scene-graph-node-node_battle')),
          findsOneWidget);
    });

    testWidgets('deletes a selected battle node and its outcome edges',
        (tester) async {
      final project = _projectWithDialogueBattlePortsScene(
        edges: [
          SceneEdge(
            id: 'edge_start_battle',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_battle',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_battle_victory_end',
            fromNodeId: 'node_battle',
            fromPortId: 'victory',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.battleVictory,
          ),
          SceneEdge(
            id: 'edge_battle_defeat_end_2',
            fromNodeId: 'node_battle',
            fromPortId: 'defeat',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.battleDefeat,
          ),
          SceneEdge(
            id: 'edge_dialogue_completed_end',
            fromNodeId: 'node_dialogue',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_battle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone dangereuse'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-node-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scene-node-delete-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.nodes.map((node) => node.id),
          isNot(contains('node_battle')));
      expect(updatedScene.graph.edges.map((edge) => edge.id), [
        'edge_dialogue_completed_end',
      ]);
      expect(updatedScene.layout.nodeLayouts.map((layout) => layout.nodeId),
          isNot(contains('node_battle')));
      expect(find.byKey(const ValueKey('scene-graph-node-node_battle')),
          findsNothing);
      expect(find.byKey(const ValueKey('scene-graph-node-node_dialogue')),
          findsOneWidget);
    });

    testWidgets('last end node shows deletion as blocked', (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithSingleEndScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
      await tester.pumpAndSettle();

      expect(find.text('Zone dangereuse'), findsOneWidget);
      expect(find.text('Une scène doit garder au moins une fin.'),
          findsOneWidget);
      final deleteButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scene-node-delete-action')),
      );
      expect(deleteButton.onPressed, isNull);
    });

    testWidgets('authors a condition from an existing story step source',
        (tester) async {
      final project = _projectWithConditionAuthoringSources();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scene-condition-authoring-panel')),
        findsOneWidget,
      );
      expect(find.text('Configurer la condition'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-kind-storyStepCompletion',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-option-storyStepCompletion-step_intro_completed',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-value-completed')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-save-action')),
      );
      await tester.pumpAndSettle();

      final conditionNode = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .nodes
          .firstWhere((node) => node.id == 'node_condition');
      final payload = conditionNode.payload as SceneConditionPayload;
      final source = payload.conditionSource!;
      expect(source.sourceKind, SceneConditionSourceKind.storyStepCompletion);
      expect(source.sourceId, 'step_intro_completed');
      expect(source.operator, SceneConditionOperator.equals);
      expect(source.value, SceneConditionValues.completed);
      expect(source.label, 'Introduction terminée');
      expect(
        diagnoseScene(
                container.read(editorNotifierProvider).project!.scenes.single)
            .byCode(SceneDiagnosticCode.conditionSourceMissing),
        isEmpty,
      );
      expect(
          project.scenes.single.graph.nodes
              .firstWhere((node) => node.id == 'node_condition')
              .payload,
          equals(SceneConditionPayload()));
    });

    testWidgets('authors fact-like and consumed event conditions from pickers',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithConditionAuthoringSources(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-kind-factLikeStoryFlag',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-option-factLikeStoryFlag-story_flag.harbor_fog_seen',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-operator-isFalse')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-save-action')),
      );
      await tester.pumpAndSettle();

      var payload = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .nodes
          .firstWhere((node) => node.id == 'node_condition')
          .payload as SceneConditionPayload;
      expect(payload.conditionSource!.sourceKind,
          SceneConditionSourceKind.factLikeStoryFlag);
      expect(payload.conditionSource!.operator, SceneConditionOperator.isFalse);
      expect(payload.conditionSource!.sourceId, 'story_flag.harbor_fog_seen');

      await tester.tap(
        find.byKey(
          const ValueKey('scene-condition-source-kind-consumedEvent'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-option-consumedEvent-mapEnter:map_test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-operator-isTrue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-save-action')),
      );
      await tester.pumpAndSettle();

      payload = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .nodes
          .firstWhere((node) => node.id == 'node_condition')
          .payload as SceneConditionPayload;
      expect(payload.conditionSource!.sourceKind,
          SceneConditionSourceKind.consumedEvent);
      expect(payload.conditionSource!.sourceId, 'mapEnter:map_test');
      expect(find.text('Inventory item'), findsNothing);
      expect(find.text('Aucune donnée Selbrume'), findsNothing);
    });

    testWidgets('authors a condition from a Fact Registry source',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _projectWithConditionAuthoringSources(includeFacts: true),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fact Registry'), findsOneWidget);
      expect(find.text('Brume vue au port'), findsOneWidget);
      expect(find.text('Port · Etat narratif lisible.'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('scene-condition-source-kind-fact')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-option-fact-fact_harbor_fog_seen',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-operator-isTrue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-save-action')),
      );
      await tester.pumpAndSettle();

      final payload = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .nodes
          .firstWhere((node) => node.id == 'node_condition')
          .payload as SceneConditionPayload;
      expect(
          payload.conditionSource!.sourceKind, SceneConditionSourceKind.fact);
      expect(payload.conditionSource!.sourceId, 'fact_harbor_fog_seen');
      expect(payload.conditionSource!.label, 'Brume vue au port');
      expect(payload.conditionSource!.operator, SceneConditionOperator.isTrue);
      expect(payload.conditionRef, 'fact_harbor_fog_seen');
    });

    testWidgets('unsupported Action/Cinematic/Branch expose no active output',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithUnsupportedConnectionNodes(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester
          .tap(find.byKey(const ValueKey('scene-graph-node-node_action')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-edge-no-outputs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scenes-connect-port-completed')),
        findsNothing,
      );

      await tester
          .tap(find.byKey(const ValueKey('scene-graph-node-node_cinematic')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scenes-edge-no-outputs')),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey('scene-graph-node-node_branch')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scenes-edge-no-outputs')),
        findsOneWidget,
      );
    });

    testWidgets('shows zoom controls and resets the canvas zoom',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.byKey(const ValueKey('scene-graph-grid')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('scene-graph-zoom-out')), findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-zoom-in')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-graph-reset-view')),
        findsOneWidget,
      );
      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-in')));
      await tester.pumpAndSettle();
      expect(find.text('125%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-out')));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-in')));
      await tester.pumpAndSettle();
      expect(find.text('125%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scene-graph-reset-view')));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('keeps node content layout stable when zoom changes',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final conditionCard =
          find.byKey(const ValueKey('scene-graph-node-node_condition'));
      final canonicalCardSize = tester.getSize(conditionCard);

      await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-in')));
      await tester.pumpAndSettle();

      expect(find.text('125%'), findsOneWidget);
      expect(tester.getSize(conditionCard), canonicalCardSize);

      await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-out')));
      await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-out')));
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsOneWidget);
      expect(tester.getSize(conditionCard), canonicalCardSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pinches trackpad to zoom the canvas without mutating project',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );
      final before = container.read(editorNotifierProvider).project!;
      final surface = find.byKey(const ValueKey('scene-graph-pan-surface'));
      final center = tester.getCenter(surface);

      tester.binding.handlePointerEvent(
        PointerPanZoomStartEvent(position: center),
      );
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(position: center, scale: 1.25),
      );
      tester.binding.handlePointerEvent(
        PointerPanZoomEndEvent(position: center),
      );
      await tester.pump();

      expect(find.text('125%'), findsOneWidget);
      expect(container.read(editorNotifierProvider).project, before);

      tester.binding.handlePointerEvent(
        PointerPanZoomStartEvent(position: center),
      );
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(position: center, scale: 0.8),
      );
      tester.binding.handlePointerEvent(
        PointerPanZoomEndEvent(position: center),
      );
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);
      expect(container.read(editorNotifierProvider).project, before);
    });

    testWidgets('pans locally without mutating ProjectManifest',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );
      final before = container.read(editorNotifierProvider).project!;

      final surface = find.byKey(const ValueKey('scene-graph-pan-surface'));
      final origin = tester.getTopLeft(surface) + const Offset(8, 8);
      await tester.dragFrom(origin, const Offset(64, 28));
      await tester.pumpAndSettle();

      final after = container.read(editorNotifierProvider).project!;
      expect(after, before);
    });

    testWidgets('dragging a node updates only SceneGraphLayout',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene(
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );
      final originalScene = project.scenes.single;

      final dragTarget = find
          .byKey(const ValueKey('scene-graph-node-drag-target-node_condition'));
      await tester.dragFrom(
        tester.getTopLeft(dragTarget) + const Offset(18, 18),
        const Offset(80, 40),
      );
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      final conditionLayout = updatedScene.layout.nodeLayouts
          .firstWhere((layout) => layout.nodeId == 'node_condition');
      expect(conditionLayout.x, greaterThan(220));
      expect(conditionLayout.y, greaterThan(80));
      expect(updatedScene.graph.nodes, originalScene.graph.nodes);
      expect(updatedScene.graph.edges, originalScene.graph.edges);
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_condition')),
        findsOneWidget,
      );
      expect(find.text('node_condition'), findsWidgets);
    });

    testWidgets('edges follow moved nodes and V1-13 connection still works',
        (tester) async {
      final project = _projectWithEdgeAuthoringScene(
        edges: [
          SceneEdge(
            id: 'edge_node_start_completed_node_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );
      final edgeLabel = find.byKey(
        const ValueKey(
          'scene-graph-edge-edge_node_start_completed_node_condition',
        ),
      );

      final dragTarget = find
          .byKey(const ValueKey('scene-graph-node-drag-target-node_condition'));
      await tester.dragFrom(
        tester.getTopLeft(dragTarget) + const Offset(18, 18),
        const Offset(80, 40),
      );
      await tester.pumpAndSettle();

      final movedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      final movedLayout = movedScene.layout.nodeLayouts
          .firstWhere((layout) => layout.nodeId == 'node_condition');
      expect(movedLayout.x, greaterThan(220));
      expect(movedLayout.y, greaterThan(80));
      expect(edgeLabel, findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('scene-graph-node-node_merge')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('scenes-connect-port-completed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
      await tester.pumpAndSettle();

      final edges = container
          .read(editorNotifierProvider)
          .project!
          .scenes
          .single
          .graph
          .edges;
      expect(
        edges.map((edge) => edge.id),
        contains('edge_node_merge_completed_node_end'),
      );
      expect(
        find.byKey(
          const ValueKey('scene-graph-edge-edge_node_merge_completed_node_end'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows real SceneAsset data in the read-only tree and summary',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.byKey(const ValueKey('scenes-tree-panel')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_intro')),
        findsOneWidget,
      );
      expect(find.text('Test Scene Intro'), findsWidgets);
      expect(find.text('storyline_test'), findsWidgets);
      expect(find.text('chapter_test'), findsWidgets);
      expect(
        find.byKey(const ValueKey('scene-graph-read-only-view')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-graph-layout-source-real')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_start')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_yarn')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-edge-edge_start_yarn')),
          findsOneWidget);
      expect(find.text('completed'), findsWidgets);
      expect(
        find.byKey(const ValueKey('scene-node-read-only-inspector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_start')),
        findsOneWidget,
      );
    });

    testWidgets('uses scene-builder proportions with fixed inspector',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final treeSize =
          tester.getSize(find.byKey(const ValueKey('scenes-tree-column')));
      final graphSize =
          tester.getSize(find.byKey(const ValueKey('scenes-graph-column')));
      final inspectorSize =
          tester.getSize(find.byKey(const ValueKey('scenes-inspector-column')));

      expect(find.byKey(const ValueKey('scenes-legacy-header')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scenes-tree-panel')),
          matching: find.byKey(const ValueKey('scenes-create-scene-action')),
        ),
        findsOneWidget,
      );
      expect(treeSize.width, lessThan(270));
      expect(inspectorSize.width, closeTo(320, 0.1));
      expect(graphSize.width, greaterThan(treeSize.width * 2));
      expect(graphSize.width, greaterThan(inspectorSize.width * 1.7));
    });

    testWidgets('shows scene diagnostics warnings without mutating project',
        (tester) async {
      final project = _projectWithDiagnosticScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.text('Diagnostics'), findsWidgets);
      expect(find.text('1 warning'), findsWidgets);
      expect(find.textContaining('Un nœud n’a pas de position sauvegardée.'),
          findsOneWidget);
      expect(find.text('Corriger automatiquement'), findsNothing);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('shows scene diagnostics errors in tree and inspector',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithDiagnosticScene(missingEnd: true),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.text('1 erreur'), findsWidgets);
      expect(find.textContaining('La scène n’a pas de fin.'), findsOneWidget);
      expect(find.text('Aucune donnée Selbrume'), findsNothing);
    });

    testWidgets('selects real graph nodes and shows read-only inspector',
        (tester) async {
      final project = _projectWithScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(const ValueKey('scene-node-read-only-inspector')),
        findsOneWidget,
      );
      expect(find.text('Détails du nœud'), findsOneWidget);
      expect(find.text('node_start'), findsWidgets);
      expect(find.text('Début'), findsWidgets);
      expect(find.text('Lecture seule'), findsWidgets);

      await tester
          .tap(find.byKey(const ValueKey('scene-graph-node-node_yarn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_yarn')),
        findsOneWidget,
      );
      expect(find.text('node_yarn'), findsWidgets);
      expect(find.text('Dialogue Yarn'), findsWidgets);
      expect(find.text('dialogue_test_intro'), findsOneWidget);
      expect(find.text('yarn_node_test_intro'), findsOneWidget);
      expect(find.textContaining('accept'), findsWidgets);
      expect(find.textContaining('decline'), findsOneWidget);
      expect(find.text('speaker_test'), findsOneWidget);
      expect(find.text('edge_start_yarn'), findsOneWidget);
      expect(find.text('edge_yarn_battle'), findsOneWidget);
      expect(find.text('Sortants'), findsOneWidget);
      expect(find.text('Entrants'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Enregistrer'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
      expect(find.text('Dupliquer'), findsNothing);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('shows battle payload summary in read-only inspector',
        (tester) async {
      final project = _projectWithScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_battle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_battle')),
        findsOneWidget,
      );
      expect(find.text('node_battle'), findsWidgets);
      expect(find.text('Combat'), findsWidgets);
      expect(find.text('trainer'), findsOneWidget);
      expect(find.text('trainer_test'), findsOneWidget);
      expect(find.text('battle_template_test'), findsOneWidget);
      expect(find.text('npc_test'), findsOneWidget);
      expect(find.textContaining('victory'), findsWidgets);
      expect(find.textContaining('defeat'), findsWidgets);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('shows typed consequence action payload in inspector',
        (tester) async {
      final project = _projectWithTypedConsequenceActionScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_action')),
        findsOneWidget,
      );
      expect(find.text('Action'), findsWidgets);
      expect(find.text('Aucune action legacy.'), findsOneWidget);
      expect(find.text('setFact'), findsOneWidget);
      expect(find.text('fact_gate_open'), findsOneWidget);
      expect(find.text('true'), findsOneWidget);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('scene change recalculates local selected node',
        (tester) async {
      final project = _projectWithTwoScenes();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_battle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_battle')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_branch')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-selected-summary-scene_test_branch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_start')),
        findsOneWidget,
      );
      expect(find.text('node_start'), findsWidgets);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('uses a derived layout for scenes with incomplete layout',
        (tester) async {
      final project = _projectWithTwoScenes();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_branch')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-read-only-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-layout-source-derived')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-graph-node-node_start')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_end')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-edge-edge_start_end')),
          findsOneWidget);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('uses bounded derived layout for cyclic and disconnected graph',
        (tester) async {
      final project = _projectWithComplexFallbackScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(const ValueKey('scene-graph-read-only-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-layout-source-derived')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-graph-node-node_a')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_b')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_c')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_d')),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-graph-edge-edge_a_b')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-edge-edge_b_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-edge-edge_c_d')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-node-inspector')), findsNothing);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets(
        'local scene selection updates summary without mutating project',
        (tester) async {
      final project = _projectWithTwoScenes();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.text('Test Scene Intro'), findsWidgets);
      expect(find.text('Second Test Scene'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scenes-selected-summary-scene_test_intro')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_branch')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-selected-summary-scene_test_branch')),
        findsOneWidget,
      );
      expect(find.text('Second Test Scene'), findsWidgets);
      expect(find.byKey(const ValueKey('scene-graph-layout-source-derived')),
          findsOneWidget);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('Storylines workspace remains selectable', (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-studio-sidebar-storylines')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.globalStory,
      );
      expect(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the V1-08 scene draft visual flow valid',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('scenes-create-scene-name-field')),
        'New Draft Scene',
      );
      await tester
          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-tree-item-scene_new_draft_scene')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_start')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-node_end')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the V1-09 diagnostics visual flow valid',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithDiagnosticScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
          find.byKey(const ValueKey('scenes-workspace-shell')), findsOneWidget);
      expect(find.text('Diagnostics'), findsWidgets);
      expect(find.text('1 warning'), findsWidgets);
    });

    testWidgets('keeps the V1-12 node authoring visual flow valid',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(find.byKey(const ValueKey('scenes-add-node-condition')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-node-selected-node_condition')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scenes-add-node-palette')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-edge-authoring-toolbar')),
          findsOneWidget);
    });

    testWidgets('keeps the V1-13 edge authoring visual flow valid',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-connect-port-completed')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-edge-edge_node_start_completed_node_condition',
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-graph-grid')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('scene-graph-zoom-reset')), findsOneWidget);
    });

    testWidgets('keeps the V1-14 blueprint canvas visual flow valid',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(
          edges: [
            SceneEdge(
              id: 'edge_node_start_completed_node_condition',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_condition',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final dragTarget = find
          .byKey(const ValueKey('scene-graph-node-drag-target-node_condition'));
      await tester.dragFrom(
        tester.getTopLeft(dragTarget) + const Offset(18, 18),
        const Offset(88, 56),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('scene-graph-grid')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('scene-graph-zoom-reset')), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'scene-graph-edge-edge_node_start_completed_node_condition',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('writes V1-15 visual port connection UX screenshot',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(
          edges: [
            SceneEdge(
              id: 'edge_node_merge_completed_node_end',
              fromNodeId: 'node_merge',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final output = find.byKey(
        const ValueKey('scene-graph-output-port-node_start-completed'),
      );
      final input = find.byKey(
        const ValueKey('scene-graph-input-port-node_condition-in'),
      );
      final gesture = await tester.startGesture(
        tester.getTopLeft(output) + const Offset(16, 16),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(input));
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_15_visual_port_connection_ux_v0.png',
        ),
      );

      await gesture.up();
    });

    testWidgets('writes V1-15-bis edge selection deletion UX screenshot',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEdgeAuthoringScene(
          edges: [
            SceneEdge(
              id: 'edge_node_start_completed_node_condition',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_condition',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-graph-edge-hit-target-edge_node_start_completed_node_condition',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png',
        ),
      );
    });

    testWidgets('writes V1-25-bis dialogue battle ports screenshot',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithDialogueBattlePortsScene(
          edges: [
            SceneEdge(
              id: 'edge_node_dialogue_completed_node_end',
              fromNodeId: 'node_dialogue',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_node_battle_victory_node_end',
              fromNodeId: 'node_battle',
              fromPortId: 'victory',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.battleVictory,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_battle')),
      );
      await tester.pumpAndSettle();

      final defeatOutput = find.byKey(
        const ValueKey('scene-graph-output-port-node_battle-defeat'),
      );
      final defeatInput = find.byKey(
        const ValueKey('scene-graph-input-port-node_end_2-in'),
      );
      final gesture = await tester.startGesture(
        tester.getTopLeft(defeatOutput) + const Offset(16, 16),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(defeatInput));
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png',
        ),
      );

      await gesture.up();
    });

    testWidgets('writes V1-30 scene node payload editing screenshot',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithEditablePayloadNodes(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_dialogue')),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_30_scene_node_payload_editing_v0.png',
        ),
      );
    });

    testWidgets('writes V1-30-bis scene node deletion UX screenshot',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithDialogueBattlePortsScene(
          edges: [
            SceneEdge(
              id: 'edge_start_dialogue',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_dialogue_battle',
              fromNodeId: 'node_dialogue',
              fromPortId: 'completed',
              toNodeId: 'node_battle',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_battle_victory_end',
              fromNodeId: 'node_battle',
              fromPortId: 'victory',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.battleVictory,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_dialogue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone dangereuse'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-node-delete-action')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png',
        ),
      );
    });

    testWidgets('writes V1-17 condition authoring screenshot', (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithConditionAuthoringSources(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-kind-storyStepCompletion',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-option-storyStepCompletion-step_intro_completed',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-value-completed')),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_17_condition_authoring_v0.png',
        ),
      );
    });

    testWidgets('writes V1-18 Fact Registry screenshot', (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithConditionAuthoringSources(includeFacts: true),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-node_condition')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-condition-source-kind-fact')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'scene-condition-source-option-fact-fact_harbor_fog_seen',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_18_fact_registry_v0.png',
        ),
      );
    });
  });
}

Future<ProviderContainer> _pumpNarrativeShell(
  WidgetTester tester, {
  required ProjectManifest project,
  required EditorWorkspaceMode workspaceMode,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project,
    workspaceMode: workspaceMode,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 1440,
            height: 900,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

ProjectManifest _emptyProject() {
  return const ProjectManifest(
    name: 'Scenes shell test',
    maps: [],
    tilesets: [],
  );
}

ProjectManifest _projectWithScene() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [_testIntroScene()],
  );
}

ProjectManifest _projectWithSingleEndScene() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      SceneAsset(
        id: 'scene_single_end',
        name: 'Single End Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
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
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 280, y: 80),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithTwoScenes() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      _testIntroScene(),
      _testBranchScene(),
    ],
  );
}

ProjectManifest _projectWithComplexFallbackScene() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [_testComplexFallbackScene()],
  );
}

ProjectManifest _projectWithEdgeAuthoringScene({
  List<SceneEdge> edges = const [],
}) {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      SceneAsset(
        id: 'scene_edge_authoring',
        name: 'Edge Authoring Test Scene',
        description: 'Fixture locale pour connecter des nodes.',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_condition',
              kind: SceneNodeKind.condition,
              title: 'Condition test',
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
                  sourceId: 'story_flag.edge_authoring_ready',
                  operator: SceneConditionOperator.isTrue,
                  label: 'Graph prêt pour les edges',
                  debugTechnicalLabel: 'story_flag.edge_authoring_ready',
                ),
              ),
            ),
            SceneNode(
              id: 'node_merge',
              kind: SceneNodeKind.merge,
              title: 'Merge test',
            ),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin A'),
            SceneNode(
              id: 'node_end_2',
              kind: SceneNodeKind.end,
              title: 'Fin B',
            ),
          ],
          edges: edges,
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_condition', x: 220, y: 80),
            SceneNodeLayout(nodeId: 'node_merge', x: 420, y: 210),
            SceneNodeLayout(nodeId: 'node_end', x: 420, y: 36),
            SceneNodeLayout(nodeId: 'node_end_2', x: 420, y: 154),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithDialogueBattlePortsScene({
  List<SceneEdge> edges = const [],
}) {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      SceneAsset(
        id: 'scene_dialogue_battle_ports',
        name: 'Dialogue Battle Ports Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_dialogue',
              kind: SceneNodeKind.yarnDialogue,
              title: 'Dialogue test',
              payload: SceneYarnDialoguePayload(
                dialogueId: 'dialogue_test',
                yarnNodeName: 'Start',
              ),
            ),
            SceneNode(
              id: 'node_battle',
              kind: SceneNodeKind.battle,
              title: 'Battle test',
              payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: 'trainer_test',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
            SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
          ],
          edges: edges,
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_dialogue', x: 260, y: 80),
            SceneNodeLayout(nodeId: 'node_battle', x: 260, y: 220),
            SceneNodeLayout(nodeId: 'node_end', x: 560, y: 80),
            SceneNodeLayout(nodeId: 'node_end_2', x: 560, y: 220),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithUnsupportedConnectionNodes() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      SceneAsset(
        id: 'scene_unsupported_connection_nodes',
        name: 'Unsupported Connection Nodes Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(actionKind: 'action_test'),
            ),
            SceneNode(
              id: 'node_cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'cinematic_test'),
            ),
            SceneNode(
              id: 'node_branch',
              kind: SceneNodeKind.branchByOutcome,
              payload: SceneBranchByOutcomePayload(sourceNodeId: 'node_action'),
            ),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_action', x: 260, y: 40),
            SceneNodeLayout(nodeId: 'node_cinematic', x: 260, y: 180),
            SceneNodeLayout(nodeId: 'node_branch', x: 496, y: 110),
            SceneNodeLayout(nodeId: 'node_end', x: 760, y: 110),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithTypedConsequenceActionScene() {
  return ProjectManifest(
    name: 'Scenes typed consequence action test',
    maps: const [],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_gate_open',
        label: 'Gate open',
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_typed_consequence_action',
        name: 'Typed Consequence Action Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_action',
              kind: SceneNodeKind.action,
              title: 'Action',
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(
                  factId: 'fact_gate_open',
                  value: true,
                ),
              ),
            ),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_action',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_action',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_action_end',
              fromNodeId: 'node_action',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_action', x: 260, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 520, y: 80),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithPayloadPickerContracts() {
  return ProjectManifest(
    name: 'Scenes payload picker test',
    maps: const [],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'test_dialogue',
        name: 'Test Dialogue',
        relativePath: 'dialogues/test_dialogue.yarn',
        defaultStartNode: 'Start',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'test_trainer',
        name: 'Test Trainer',
        trainerClass: 'Trainer',
      ),
    ],
    scenarios: const [
      ScenarioAsset(
        id: 'test_cinematic_bridge',
        name: 'Test Cinematic Bridge',
        entryNodeId: 'scenario_node_start',
        nodes: [
          ScenarioNode(
            id: 'scenario_node_start',
            type: ScenarioNodeType.start,
            title: 'Start',
          ),
        ],
        metadata: {
          'authoring.cutsceneSchema': 'test_bridge',
        },
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_payload_picker',
        name: 'Payload Picker Test Scene',
        description: 'Fixture locale pour choisir des payloads.',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
          ],
          edges: const [],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 420, y: 80),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithEditablePayloadNodes() {
  return ProjectManifest(
    name: 'Scenes payload editing test',
    maps: const [],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_old',
        name: 'Old Dialogue',
        relativePath: 'dialogues/dialogue_old.yarn',
        defaultStartNode: 'OldStart',
      ),
      ProjectDialogueEntry(
        id: 'dialogue_updated',
        name: 'Updated Dialogue',
        relativePath: 'dialogues/dialogue_updated.yarn',
        defaultStartNode: 'UpdatedStart',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_old',
        name: 'Old Trainer',
        trainerClass: 'Trainer',
      ),
      ProjectTrainerEntry(
        id: 'trainer_updated',
        name: 'Updated Trainer',
        trainerClass: 'Trainer',
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_payload_editing',
        name: 'Payload Editing Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_dialogue',
              kind: SceneNodeKind.yarnDialogue,
              title: 'Old Dialogue',
              payload: SceneYarnDialoguePayload(
                dialogueId: 'dialogue_old',
                yarnNodeName: 'OldStart',
                expectedOutcomes: const ['accept'],
              ),
            ),
            SceneNode(
              id: 'node_battle',
              kind: SceneNodeKind.battle,
              title: 'Old Battle',
              payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: 'trainer_old',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
            SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_dialogue_completed_end',
              fromNodeId: 'node_dialogue',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_battle_victory_end',
              fromNodeId: 'node_battle',
              fromPortId: 'victory',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.battleVictory,
            ),
            SceneEdge(
              id: 'edge_battle_defeat_end_2',
              fromNodeId: 'node_battle',
              fromPortId: 'defeat',
              toNodeId: 'node_end_2',
              kind: SceneEdgeKind.battleDefeat,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_dialogue', x: 260, y: 80),
            SceneNodeLayout(nodeId: 'node_battle', x: 260, y: 220),
            SceneNodeLayout(nodeId: 'node_end', x: 560, y: 80),
            SceneNodeLayout(nodeId: 'node_end_2', x: 560, y: 220),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithConditionAuthoringSources({
  bool includeFacts = false,
}) {
  return ProjectManifest(
    name: 'Scenes condition authoring test',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Carte de test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    facts: includeFacts
        ? [
            NarrativeFactDefinition(
              id: 'fact_harbor_fog_seen',
              label: 'Brume vue au port',
              description: 'Etat narratif lisible.',
              category: 'Port',
              defaultValue: false,
              tags: const ['brume'],
              legacyFlagName: 'story_flag.harbor_fog_seen',
            ),
          ]
        : const [],
    scenarios: const [
      ScenarioAsset(
        id: 'scenario_flag_sources',
        name: 'Sources de flags',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'scenario_node_start',
        activationCondition: ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: {
            ScriptConditionParams.flagName: 'story_flag.harbor_fog_seen',
          },
        ),
        nodes: [
          ScenarioNode(
            id: 'scenario_node_start',
            type: ScenarioNodeType.start,
            title: 'Start',
          ),
        ],
      ),
    ],
    storylines: [
      StorylineAsset(
        id: 'storyline_test',
        title: 'Storyline de test',
        type: StorylineType.main,
        chapters: [
          StorylineChapter(
            id: 'chapter_test',
            title: 'Chapitre de test',
            order: 0,
            steps: [
              StorylineStep(
                id: 'step_intro_completed',
                title: 'Introduction terminée',
                order: 0,
              ),
            ],
          ),
        ],
      ),
    ],
    scenes: [_conditionAuthoringScene()],
  );
}

SceneAsset _conditionAuthoringScene() {
  return SceneAsset(
    id: 'scene_condition_authoring',
    name: 'Condition Authoring Test Scene',
    description: 'Fixture locale pour configurer une condition.',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          title: 'Condition à configurer',
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
      ],
      edges: [
        SceneEdge(
          id: 'edge_node_start_completed_node_condition',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_condition',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_condition', x: 260, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 520, y: 80),
      ],
    ),
  );
}

ProjectManifest _projectWithDiagnosticScene({bool missingEnd = false}) {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      SceneAsset(
        id: 'scene_diagnostic_test',
        name: 'Diagnostic Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            if (!missingEnd) SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
          edges: [
            if (!missingEnd)
              SceneEdge(
                id: 'edge_start_end',
                fromNodeId: 'node_start',
                fromPortId: 'completed',
                toNodeId: 'node_end',
                kind: SceneEdgeKind.defaultFlow,
              ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
          ],
        ),
      ),
    ],
  );
}

SceneAsset _testIntroScene() {
  return SceneAsset(
    id: 'scene_test_intro',
    name: 'Test Scene Intro',
    description: 'Fixture locale de test.',
    storylineId: 'storyline_test',
    chapterId: 'chapter_test',
    tags: const ['test', 'intro'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_yarn',
          kind: SceneNodeKind.yarnDialogue,
          title: 'Dialogue test',
          description: 'Dialogue Yarn réel de test.',
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_test_intro',
            yarnNodeName: 'yarn_node_test_intro',
            expectedOutcomes: const ['accept', 'decline'],
            speakerHints: const ['speaker_test'],
          ),
        ),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          title: 'Battle test',
          description: 'Combat réel de test.',
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test',
            battleTemplateId: 'battle_template_test',
            npcEntityId: 'npc_test',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'node_merge',
          kind: SceneNodeKind.merge,
          title: 'Merge test',
          description: 'Node réel de test.',
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'End test'),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_yarn',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_yarn',
          kind: SceneEdgeKind.defaultFlow,
          label: 'completed',
        ),
        SceneEdge(
          id: 'edge_yarn_battle',
          fromNodeId: 'node_yarn',
          fromPortId: 'completed',
          toNodeId: 'node_battle',
          kind: SceneEdgeKind.defaultFlow,
          label: 'completed',
        ),
        SceneEdge(
          id: 'edge_battle_merge',
          fromNodeId: 'node_battle',
          fromPortId: 'victory',
          toNodeId: 'node_merge',
          kind: SceneEdgeKind.battleVictory,
          label: 'victory',
        ),
        SceneEdge(
          id: 'edge_merge_end',
          fromNodeId: 'node_merge',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
          label: 'done',
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_yarn', x: 230, y: 80),
        SceneNodeLayout(nodeId: 'node_battle', x: 436, y: 80),
        SceneNodeLayout(nodeId: 'node_merge', x: 642, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 848, y: 80),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(id: 'intro_done', label: 'Intro done'),
      SceneOutcome(id: 'branch_done', label: 'Branch done'),
    ],
  );
}

SceneAsset _sceneWithId(String id) {
  return SceneAsset(
    id: id,
    name: 'Existing scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
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
}

SceneAsset _testComplexFallbackScene() {
  return SceneAsset(
    id: 'scene_test_complex_fallback',
    name: 'Complex Fallback Test Scene',
    description: 'Fixture locale de test cyclique et déconnectée.',
    graph: SceneGraph(
      startNodeId: 'node_a',
      nodes: [
        SceneNode(id: 'node_a', kind: SceneNodeKind.start, title: 'Node A'),
        SceneNode(id: 'node_b', kind: SceneNodeKind.condition, title: 'Node B'),
        SceneNode(id: 'node_c', kind: SceneNodeKind.merge, title: 'Node C'),
        SceneNode(id: 'node_d', kind: SceneNodeKind.end, title: 'Node D'),
      ],
      edges: [
        SceneEdge(
          id: 'edge_a_b',
          fromNodeId: 'node_a',
          fromPortId: 'completed',
          toNodeId: 'node_b',
          kind: SceneEdgeKind.defaultFlow,
          label: 'a to b',
        ),
        SceneEdge(
          id: 'edge_b_a',
          fromNodeId: 'node_b',
          fromPortId: 'true',
          toNodeId: 'node_a',
          kind: SceneEdgeKind.conditionTrue,
          label: 'b to a',
        ),
        SceneEdge(
          id: 'edge_c_d',
          fromNodeId: 'node_c',
          fromPortId: 'completed',
          toNodeId: 'node_d',
          kind: SceneEdgeKind.actionCompleted,
          label: 'c to d',
        ),
      ],
    ),
  );
}

SceneAsset _testBranchScene() {
  return SceneAsset(
    id: 'scene_test_branch',
    name: 'Second Test Scene',
    description: 'Deuxième fixture locale.',
    tags: const ['test'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
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
    declaredOutcomes: [
      SceneOutcome(id: 'second_done', label: 'Second done'),
    ],
  );
}
