import 'package:avelune_studio/presentation/features/scenes/scene_dialogue_choice_policy_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'edits the exact nested choice using labels and linked branches',
    (tester) async {
      final updates = <SceneDialogueChoicePolicy>[];
      await _pump(tester, onApply: updates.add);
      expect(
        _select(tester, 'scene-choice-scope').options.values,
        contains('Start · Choix 2 : Continuer / Revenir'),
      );
      await _change(tester, 'scene-choice-scope', '1');
      expect(_select(tester, 'scene-choice-default').value, 'back');
      expect(
        _select(tester, 'scene-choice-default').options['next'],
        'Continuer',
      );
      await _change(tester, 'scene-choice-default', 'next');
      await _change(tester, 'scene-choice-cancellation', 'branch');
      expect(_select(tester, 'scene-choice-target').options, {
        'cancel': 'Retour au jeu',
      });
      await _apply(tester);
      expect(updates, [
        const SceneDialogueChoicePolicy(
          nodeName: 'Start',
          choiceIndex: 1,
          defaultOutcomeId: 'next',
          cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
        ),
      ]);
      expect(_payload().choicePolicies.single.defaultOutcomeId, 'back');
    },
  );

  testWidgets(
    'supports visible choice cancellation and disables it explicitly',
    (tester) async {
      final updates = <SceneDialogueChoicePolicy>[];
      await _pump(tester, onApply: updates.add);
      await _change(tester, 'scene-choice-cancellation', 'choice');
      await _change(tester, 'scene-choice-target', 'no');
      await _apply(tester);
      expect(
        updates.last.cancellation,
        const SceneDialogueChoiceCancellation.choice('no'),
      );
      await _change(tester, 'scene-choice-cancellation', 'disabled');
      expect(find.byKey(const ValueKey('scene-choice-target')), findsNothing);
      await _apply(tester);
      expect(
        updates.last.cancellation,
        const SceneDialogueChoiceCancellation.disabled(),
      );
    },
  );

  testWidgets('does not offer null duplicated or undeclared outcomes', (
    tester,
  ) async {
    await _pump(
      tester,
      document: RuntimeDialogueDocument(
        nodes: [
          RuntimeDialogueNode(
            title: 'Start',
            steps: [
              RuntimeDialogueChoiceBlock([
                RuntimeDialogueChoice(text: 'Sans sortie', steps: []),
                RuntimeDialogueChoice(
                  text: 'Doublon A',
                  outcomeId: 'yes',
                  steps: [],
                ),
                RuntimeDialogueChoice(
                  text: 'Doublon B',
                  outcomeId: 'yes',
                  steps: [],
                ),
                RuntimeDialogueChoice(
                  text: 'Non déclarée',
                  outcomeId: 'unknown',
                  steps: [],
                ),
              ]),
            ],
          ),
        ],
      ),
    );
    expect(_select(tester, 'scene-choice-default').options.values, [
      'Première option',
    ]);
    expect(
      _select(tester, 'scene-choice-cancellation').options,
      isNot(contains('choice')),
    );
  });

  testWidgets(
    'explains absent choices and absent linked cancellation branches',
    (tester) async {
      await _pump(tester, linkedBranch: false);
      expect(
        _select(tester, 'scene-choice-cancellation').options,
        isNot(contains('branch')),
      );
      expect(
        find.textContaining('Aucune branche d’annulation reliée'),
        findsOneWidget,
      );
      await _pump(
        tester,
        document: RuntimeDialogueDocument(
          nodes: [
            RuntimeDialogueNode(
              title: 'Start',
              steps: [RuntimeDialogueLine('Bonjour')],
            ),
          ],
        ),
      );
      expect(
        find.textContaining('Aucun choix dans ce dialogue'),
        findsOneWidget,
      );
      expect(find.byType(StudioSelect), findsNothing);
      expect(find.byType(StudioButton), findsNothing);
    },
  );

  testWidgets(
    'requires an explicit repair when an existing choice disappears',
    (tester) async {
      final updates = <SceneDialogueChoicePolicy>[];
      await _pump(
        tester,
        onApply: updates.add,
        document: RuntimeDialogueDocument(
          nodes: [
            RuntimeDialogueNode(
              title: 'Start',
              steps: [
                RuntimeDialogueChoiceBlock([
                  RuntimeDialogueChoice(
                    text: 'Oui',
                    outcomeId: 'yes',
                    steps: [
                      RuntimeDialogueChoiceBlock([
                        RuntimeDialogueChoice(
                          text: 'Continuer',
                          outcomeId: 'next',
                          steps: [],
                        ),
                      ]),
                    ],
                  ),
                ]),
              ],
            ),
          ],
        ),
      );
      await _change(tester, 'scene-choice-scope', '1');
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('scene-choice-apply')),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('option qui n’existe plus'), findsOneWidget);
      await _change(tester, 'scene-choice-default', '');
      await _apply(tester);
      expect(updates.single.defaultOutcomeId, isNull);
      expect(
        updates.single.cancellation,
        const SceneDialogueChoiceCancellation.choice('next'),
      );
    },
  );
}

SceneYarnDialoguePayload _payload() => SceneYarnDialoguePayload(
  dialogueId: 'dialogue',
  expectedOutcomes: const ['yes', 'no', 'next', 'back', 'cancel'],
  choicePolicies: const [
    SceneDialogueChoicePolicy(
      nodeName: 'Start',
      choiceIndex: 1,
      defaultOutcomeId: 'back',
      cancellation: SceneDialogueChoiceCancellation.choice('next'),
    ),
  ],
);

RuntimeDialogueDocument _document() => RuntimeDialogueDocument(
  nodes: [
    RuntimeDialogueNode(
      title: 'Start',
      steps: [
        RuntimeDialogueChoiceBlock([
          RuntimeDialogueChoice(
            text: 'Oui',
            outcomeId: 'yes',
            steps: [
              RuntimeDialogueChoiceBlock([
                RuntimeDialogueChoice(
                  text: 'Continuer',
                  outcomeId: 'next',
                  steps: [],
                ),
                RuntimeDialogueChoice(
                  text: 'Revenir',
                  outcomeId: 'back',
                  steps: [],
                ),
              ]),
            ],
          ),
          RuntimeDialogueChoice(text: 'Non', outcomeId: 'no', steps: []),
        ]),
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<SceneDialogueChoicePolicy>? onApply,
  RuntimeDialogueDocument? document,
  bool linkedBranch = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final payload = _payload();
  final scene = SceneAsset(
    id: 'scene',
    name: 'Scène',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue-node',
          kind: SceneNodeKind.yarnDialogue,
          payload: payload,
        ),
        SceneNode(
          id: 'return',
          title: 'Retour au jeu',
          kind: SceneNodeKind.end,
        ),
      ],
      edges: [
        if (linkedBranch)
          SceneEdge(
            id: 'cancel-edge',
            fromNodeId: 'dialogue-node',
            fromPortId: 'cancel',
            toNodeId: 'return',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
      ],
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: SceneDialogueChoicePolicyForm(
              scene: scene,
              nodeId: 'dialogue-node',
              payload: payload,
              document: document ?? _document(),
              onApply: onApply ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

StudioSelect _select(WidgetTester tester, String key) =>
    tester.widget<StudioSelect>(find.byKey(ValueKey(key)));

Future<void> _change(WidgetTester tester, String key, String value) async {
  _select(tester, key).onChanged!(value);
  await tester.pump();
}

Future<void> _apply(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('scene-choice-apply'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}
