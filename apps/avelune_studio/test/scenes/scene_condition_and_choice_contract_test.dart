import 'package:avelune_studio/features/scenes/application/scene_condition_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_dialogue_choice_policy_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('trainer condition keeps raw identity inverse expectation and excludes static encounters', () {
    const trainer = ProjectTrainerEntry(
      id: 'clair',
      name: 'Sandra',
      trainerClass: 'Championne',
    );
    final original = SceneConditionPayload(
      conditionSource: SceneConditionSource.trainerDefeated(trainerId: 'clair'),
    );
    final draft = _condition(
      ProjectManifest(
        name: 'Trainer',
        maps: [],
        tilesets: [],
        trainers: [
          trainer,
          trainer.copyWith(
            id: 'lugia',
            name: 'Lugia',
            tags: ['static-encounter'],
          ),
        ],
      ),
      original,
    );
    expect(draft.references.keys, ['clair']);
    draft.expected = false;
    expect(draft.current, same(original));
    final prepared = draft.prepared!;
    expect(prepared.sourceKind, SceneConditionSourceKind.trainerDefeated);
    expect(prepared.sourceId, 'clair');
    expect(prepared.trainerDefeatedExpected, isFalse);
    expect(prepared.factOperator, isNull);
    expect(original.conditionSource!.trainerDefeatedExpected, isTrue);
  });

  test(
    'missing and duplicated trainers cannot choose a replacement identity',
    () {
      const trainer = ProjectTrainerEntry(
        id: 'clair',
        name: 'Sandra',
        trainerClass: 'Championne',
      );
      final original = SceneConditionPayload(
        conditionSource: SceneConditionSource.trainerDefeated(
          trainerId: 'clair',
        ),
      );
      for (final trainers in <List<ProjectTrainerEntry>>[
        [],
        [trainer, trainer],
      ]) {
        final draft = _condition(
          ProjectManifest(
            name: 'Trainer',
            maps: [],
            tilesets: [],
            trainers: trainers,
          ),
          original,
        );
        expect(draft.referenceId, 'clair');
        expect(draft.prepared, isNull);
        expect(draft.current, same(original));
      }
    },
  );

  test('nested choice editing uses the exact scope default and linked cancellation branch', () {
    final original = _payload();
    final draft = _choice(payload: original);
    expect(draft.scopes, hasLength(2));
    draft.scopeIndex = 1;
    draft.readPolicy();
    expect(draft.scope.nodeName, 'Start');
    expect(draft.scope.choiceIndex, 1);
    expect(draft.defaultOutcome, 'back');
    expect(draft.choices, {'next': 'Continuer', 'back': 'Revenir'});
    draft.defaultOutcome = 'next';
    draft.cancellation = SceneDialogueChoiceCancellationKind.branch;
    expect(draft.targets, {'cancel': 'Retour au jeu'});
    draft.target = 'cancel';
    expect(
      draft.prepared,
      const SceneDialogueChoicePolicy(
        nodeName: 'Start',
        choiceIndex: 1,
        defaultOutcomeId: 'next',
        cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
      ),
    );
    expect(original.choicePolicies.single.defaultOutcomeId, 'back');
  });

  test('choice cancellation targets a visible choice and can be explicitly disabled', () {
    final draft = _choice();
    draft.cancellation = SceneDialogueChoiceCancellationKind.choice;
    draft.target = 'no';
    expect(
      draft.prepared!.cancellation,
      const SceneDialogueChoiceCancellation.choice('no'),
    );
    draft.cancellation = SceneDialogueChoiceCancellationKind.disabled;
    expect(draft.targets, isEmpty);
    expect(
      draft.prepared!.cancellation,
      const SceneDialogueChoiceCancellation.disabled(),
    );
  });

  test(
    'null duplicate and undeclared outcomes cannot provide policy choices',
    () {
      final draft = _choice(
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
      expect(draft.choices, isEmpty);
      draft.defaultOutcome = 'yes';
      expect(draft.prepared, isNull);
      draft.defaultOutcome = '';
      draft.cancellation = SceneDialogueChoiceCancellationKind.choice;
      draft.target = 'yes';
      expect(draft.targets, isEmpty);
      expect(draft.prepared, isNull);
    },
  );

  test('missing linked branches and absent dialogue choices cannot create a policy', () {
    final unlinked = _choice(linkedBranch: false);
    unlinked.cancellation = SceneDialogueChoiceCancellationKind.branch;
    unlinked.target = 'cancel';
    expect(unlinked.branches, isEmpty);
    expect(unlinked.prepared, isNull);
    final empty = _choice(
      document: RuntimeDialogueDocument(
        nodes: [
          RuntimeDialogueNode(
            title: 'Start',
            steps: [RuntimeDialogueLine('Bonjour')],
          ),
        ],
      ),
    );
    expect(empty.scopes, isEmpty);
    expect(empty.prepared, isNull);
  });

  test('a removed default requires explicit repair and preserves a valid cancellation choice', () {
    final original = _payload();
    final draft = _choice(
      payload: original,
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
    draft.scopeIndex = 1;
    draft.readPolicy();
    expect(draft.defaultOutcome, 'back');
    expect(draft.defaultValid, isFalse);
    expect(draft.prepared, isNull);
    draft.defaultOutcome = '';
    expect(draft.prepared!.defaultOutcomeId, isNull);
    expect(
      draft.prepared!.cancellation,
      const SceneDialogueChoiceCancellation.choice('next'),
    );
    expect(original.choicePolicies.single.defaultOutcomeId, 'back');
  });
}

SceneConditionDraft _condition(
  ProjectManifest project,
  SceneConditionPayload current,
) {
  final draft = SceneConditionDraft(
    project: project,
    current: current,
    changed: () {},
  );
  addTearDown(draft.dispose);
  return draft;
}

SceneDialogueChoicePolicyDraft _choice({
  SceneYarnDialoguePayload? payload,
  RuntimeDialogueDocument? document,
  bool linkedBranch = true,
}) {
  final value = payload ?? _payload();
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
          payload: value,
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
  return SceneDialogueChoicePolicyDraft(
    scene: scene,
    nodeId: 'dialogue-node',
    payload: value,
    document: document ?? _document(),
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
