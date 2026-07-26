import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene runtime dry-run preview', () {
    test('waits for explicit input then previews the selected dialogue path',
        () {
      final plan = _dialoguePlan();

      final waiting = previewSceneRuntimePath(
        plan,
        input: const SceneDryRunInputState(),
      );
      expect(waiting.status, SceneDryRunPreviewStatus.awaitingInput);
      expect(waiting.awaitingNodeId, 'node_dialogue');
      expect(waiting.acceptedOutputPortIds, ['completed', 'accept', 'leave']);
      expect(waiting.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
      ]);

      final completed = previewSceneRuntimePath(
        plan,
        input: SceneDryRunInputState(
          outputPortByNodeId: {'node_dialogue': 'leave'},
        ),
      );
      expect(completed.status, SceneDryRunPreviewStatus.completed);
      expect(completed.sceneOutcomeId, 'left');
      expect(completed.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
        'node_leave',
      ]);
    });

    test('rejects an explicit output not declared by the node', () {
      final result = previewSceneRuntimePath(
        _dialoguePlan(),
        input: SceneDryRunInputState(
          outputPortByNodeId: {'node_dialogue': 'unknown'},
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.failed);
      expect(result.message, contains('unknown'));
    });

    test('routes a recorded dialogue outcome through merge and branch', () {
      final plan = SceneRuntimePlan(
        sceneId: 'scene_branch_preview',
        startNodeId: 'start',
        nodes: [
          SceneRuntimePlanNode(
            id: 'start',
            kind: SceneNodeKind.start,
            intent: SceneRuntimePlanIntent.start(),
          ),
          SceneRuntimePlanNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            intent: SceneRuntimePlanIntent.showDialogue(
              dialogueId: 'dialogue_test',
              expectedOutcomes: const ['accept', 'refuse'],
            ),
          ),
          SceneRuntimePlanNode(
            id: 'merge',
            kind: SceneNodeKind.merge,
            intent: SceneRuntimePlanIntent.merge(),
          ),
          SceneRuntimePlanNode(
            id: 'branch',
            kind: SceneNodeKind.branchByOutcome,
            intent: SceneRuntimePlanIntent.branchByOutcome(
              sourceNodeId: 'dialogue',
              fallbackPolicy: SceneBranchOutcomeFallbackPolicy.exact,
              sourceOutcomes: const ['completed', 'accept', 'refuse'],
            ),
          ),
          SceneRuntimePlanNode(
            id: 'end_accept',
            kind: SceneNodeKind.end,
            intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'accepted'),
          ),
        ],
        edges: const [
          SceneRuntimePlanEdge(
            id: 'start_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneRuntimePlanEdge(
            id: 'dialogue_accept_merge',
            fromNodeId: 'dialogue',
            fromPortId: 'accept',
            toNodeId: 'merge',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
          SceneRuntimePlanEdge(
            id: 'merge_branch',
            fromNodeId: 'merge',
            fromPortId: 'completed',
            toNodeId: 'branch',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneRuntimePlanEdge(
            id: 'branch_accept_end',
            fromNodeId: 'branch',
            fromPortId: 'accept',
            toNodeId: 'end_accept',
            kind: SceneEdgeKind.branchOutcome,
          ),
        ],
        declaredOutcomes: [
          SceneOutcome(id: 'accepted', label: 'Accepted'),
        ],
      );

      final result = previewSceneRuntimePath(
        plan,
        input: SceneDryRunInputState(
          outputPortByNodeId: {'dialogue': 'accept'},
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.completed);
      expect(result.sceneOutcomeId, 'accepted');
      expect(result.trace.map((entry) => entry.nodeId),
          ['start', 'dialogue', 'merge', 'branch', 'end_accept']);
      expect(result.context.branchProvenance.single.sourceOutcome, 'accept');
    });

    test('summarizes every canonical consequence in authored order', () {
      final consequences = <SceneConsequence>[
        SceneConsequence.setFact(factId: 'fact_gate', value: true),
        SceneConsequence.markEventConsumed(
          mapId: 'map_port',
          eventId: 'event_chest',
        ),
        SceneConsequence.completeStoryStep(stepId: 'step_departure'),
        SceneConsequence.giveItem(itemId: 'potion', quantity: 3),
        SceneConsequence.takeItem(itemId: 'potion', quantity: 1),
        SceneConsequence.giveMoney(amount: 250),
        SceneConsequence.givePokemon(
          speciesId: 'sproutle',
          level: 5,
          currentHp: 20,
        ),
        SceneConsequence.giveConfiguredStarter(
          starterOptionId: 'starter_sproutle',
        ),
        SceneConsequence.healParty(),
        SceneConsequence.awardBadge(badgeId: 'badge_tide'),
        SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
        SceneConsequence.setNpcPresence(
          mapId: 'map_port',
          entityId: 'npc_sailor',
          present: false,
        ),
        SceneConsequence.finishGame(
          endingId: 'ending_selbrume',
          outcome: SceneGameCompletionOutcome.victory,
          result: SceneFinishGameResult(
            title: SceneLocalizedText(fallback: 'Selbrume est sauvée'),
            summary: SceneLocalizedText(fallback: 'La brume se retire.'),
          ),
          postGamePolicy: ScenePostGamePolicy.returnToHub,
        ),
      ];

      final result = previewSceneRuntimePath(
        _consequencePlan(consequences),
        input: SceneDryRunInputState(
          consequenceState: SceneDryRunConsequenceState(
            itemQuantityById: {'potion': 2},
            money: 100,
          ),
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.completed);
      expect(
        result.consequenceChanges.map((change) => change.consequence.kind),
        SceneConsequenceKind.values,
      );
      expect(result.consequenceState.factValueById['fact_gate'], isTrue);
      expect(
        result.consequenceState.consumedEventKeys,
        contains('map_port:event_chest'),
      );
      expect(
        result.consequenceState.completedStoryStepIds,
        contains('step_departure'),
      );
      expect(result.consequenceState.itemQuantityById['potion'], 4);
      expect(result.consequenceState.money, 350);
      expect(result.consequenceState.partyMemberCount, 2);
      expect(result.consequenceState.partyHealed, isTrue);
      expect(result.consequenceState.badgeIds, contains('badge_tide'));
      expect(
        result.consequenceState.unlockedFieldAbilities,
        contains(FieldAbility.surf),
      );
      expect(
        result.consequenceState.npcPresenceByRef['map_port::npc_sailor'],
        isFalse,
      );
      expect(result.consequenceChanges[3].beforeSummary, contains('2'));
      expect(result.consequenceChanges[3].afterSummary, contains('5'));
    });

    test('keeps prior action summaries but does not mutate a failing action',
        () {
      final result = previewSceneRuntimePath(
        _consequencePlan([
          SceneConsequence.giveItem(itemId: 'potion', quantity: 2),
          SceneConsequence.takeItem(itemId: 'potion', quantity: 5),
        ]),
        input: SceneDryRunInputState(
          consequenceState: SceneDryRunConsequenceState(
            itemQuantityById: const {'potion': 1},
          ),
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.failed);
      expect(result.message, contains('potion'));
      expect(result.consequenceChanges, hasLength(1));
      expect(result.consequenceState.itemQuantityById['potion'], 3);
    });
  });
}

SceneRuntimePlan _consequencePlan(List<SceneConsequence> consequences) {
  final nodes = <SceneRuntimePlanNode>[
    SceneRuntimePlanNode(
      id: 'start',
      kind: SceneNodeKind.start,
      intent: SceneRuntimePlanIntent.start(),
    ),
    for (var index = 0; index < consequences.length; index++)
      SceneRuntimePlanNode(
        id: 'action_$index',
        kind: SceneNodeKind.action,
        intent: SceneRuntimePlanIntent.applyConsequence(
          consequence: consequences[index],
        ),
      ),
    SceneRuntimePlanNode(
      id: 'end',
      kind: SceneNodeKind.end,
      intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'completed'),
    ),
  ];
  return SceneRuntimePlan(
    sceneId: 'scene_consequences',
    startNodeId: 'start',
    nodes: nodes,
    edges: <SceneRuntimePlanEdge>[
      for (var index = 0; index <= consequences.length; index++)
        SceneRuntimePlanEdge(
          id: 'edge_$index',
          fromNodeId: index == 0 ? 'start' : 'action_${index - 1}',
          fromPortId: 'completed',
          toNodeId: index == consequences.length ? 'end' : 'action_$index',
          kind: index == 0
              ? SceneEdgeKind.defaultFlow
              : SceneEdgeKind.actionCompleted,
        ),
    ],
    declaredOutcomes: [SceneOutcome(id: 'completed', label: 'Completed')],
  );
}

SceneRuntimePlan _dialoguePlan() {
  return SceneRuntimePlan(
    sceneId: 'scene_preview',
    startNodeId: 'node_start',
    nodes: [
      SceneRuntimePlanNode(
        id: 'node_start',
        kind: SceneNodeKind.start,
        intent: SceneRuntimePlanIntent.start(),
      ),
      SceneRuntimePlanNode(
        id: 'node_dialogue',
        kind: SceneNodeKind.yarnDialogue,
        intent: SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test',
          expectedOutcomes: const ['accept', 'leave'],
        ),
      ),
      SceneRuntimePlanNode(
        id: 'node_accept',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'accepted'),
      ),
      SceneRuntimePlanNode(
        id: 'node_leave',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'left'),
      ),
    ],
    edges: const [
      SceneRuntimePlanEdge(
        id: 'edge_start_dialogue',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_accept',
        fromNodeId: 'node_dialogue',
        fromPortId: 'accept',
        toNodeId: 'node_accept',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_leave',
        fromNodeId: 'node_dialogue',
        fromPortId: 'leave',
        toNodeId: 'node_leave',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
    ],
    declaredOutcomes: [
      SceneOutcome(id: 'accepted', label: 'Accepted'),
      SceneOutcome(id: 'left', label: 'Left'),
    ],
  );
}
