import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';

const _data = SceneDialogueChoicePolicyEditorData(
  scopes: [
    SceneDialogueChoiceScopeOption(
      nodeName: 'Start',
      choiceIndex: 0,
      labels: ['Oui', 'Non'],
      choices: [
        SceneDialogueChoiceOption(outcomeId: 'yes', label: 'Oui'),
        SceneDialogueChoiceOption(outcomeId: 'no', label: 'Non'),
      ],
      branches: [],
    ),
  ],
  policies: [],
);

void main() {
  testWidgets(
    'inspector loads the selected dialogue choice and shows a rejected edit faithfully',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? loadedNode;
      SceneDialogueChoicePolicy? attempted;
      final scene = SceneAsset(
        id: 'scene',
        name: 'Scène',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'choice',
                expectedOutcomes: const ['yes', 'no'],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'entry',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final summary = NarrativeSceneSummary(
        id: scene.id,
        name: scene.name,
        nodeCount: 3,
        edgeCount: 1,
        declaredOutcomeCount: 0,
        declaredOutcomes: const [],
        tags: const [],
        graph: scene.graph,
        layout: scene.layout,
        diagnostics: diagnoseScene(scene),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 390,
                child: SceneNodeReadOnlyInspector(
                  scene: summary,
                  selectedNodeId: 'dialogue',
                  linkedAssetContracts: LinkedAssetContractsSnapshot(
                    dialogues: [
                      DialoguePublicContract(
                        id: 'choice',
                        label: 'Choix',
                        sourceRef: 'dialogues/choice.yarn',
                        defaultStartNode: 'Start',
                        availableStartNodes: const ['Start'],
                        declaredOutcomes: const [],
                        diagnostics: const [],
                        status: LinkedAssetContractStatus.available,
                      ),
                    ],
                    battles: const [],
                    cinematics: const [],
                    outcomeProducers: const [],
                    actionContractsAvailable: true,
                    branchByOutcomeAvailable: true,
                    diagnostics: const [],
                  ),
                  onLoadDialogueChoicePolicies: ({required nodeId}) async {
                    loadedNode = nodeId;
                    return _data;
                  },
                  onUpdateDialogueChoicePolicy:
                      ({required nodeId, required policy}) async {
                        attempted = policy;
                        return false;
                      },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-dialogue-choice-policy-edit')),
      );
      await tester.pumpAndSettle();
      expect(loadedNode, 'dialogue');
      await tester.tap(
        find.byKey(const ValueKey('scene-choice-policy-confirm')),
      );
      await tester.pumpAndSettle();
      expect(attempted, const SceneDialogueChoicePolicy(nodeName: 'Start'));
      expect(
        find.text(
          'Le comportement des choix n’a pas été appliqué. Vérifiez les sorties de la scène et le dialogue.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Comportement des choix appliqué au brouillon.'),
        findsNothing,
      );
    },
  );
}
