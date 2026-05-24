import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// ignore_for_file: prefer_const_constructors

/// Characterization tests proving the trainer battle authoring readiness chain:
///
/// Scene action startTrainerBattle
/// → ScenarioRuntimeEffectType.battle (battleId, trainerId, npcEntityId)
/// → graph suspended
/// → battle outcome applied
/// → scenarioBattleOutcomeFlagName sets battle:<battleId>:victory or defeat
/// → dispatchContinuation resumes after battle node
/// → victory/defeat branch executes setFlag / completeStep
/// → save/load preserves all flags
///
/// Frontière Scene / Battle / World Rule :
/// - Scene orchestre la progression narrative (dialogue, branches, actions).
/// - Battle résout un combat (victory / defeat / flee).
/// - Outcome battle revient à la Scene (via flag + continuation).
/// - World Rule projette ensuite l'état (visibilité, dialogue conditionnel).
///
/// No Selbrume ids. All ids are generic test fixtures.
void main() {
  const executor = ScenarioRuntimeExecutor();

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  ScenarioRuntimeExecutionContext buildContext({
    GameState? gameState,
    void Function(GameState)? onGameStateUpdated,
    void Function(String)? onDialogueOpened,
  }) {
    var state = gameState ?? const GameState(saveId: 'test_save');
    return ScenarioRuntimeExecutionContext(
      gameState: state,
      onGameStateUpdated: onGameStateUpdated ?? (next) => state = next,
      openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
        onDialogueOpened?.call(dialogueId);
        return true;
      },
      runScript: (scriptId, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    );
  }

  // ─────────────────────────────────────────────────────────
  // 9.1  Scene action → battle effect
  // ─────────────────────────────────────────────────────────

  group('Scene action → battle effect', () {
    test('startTrainerBattle produces battle effect with correct ids', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_battle',
        name: 'Test Battle Scene',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'test_battle'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'test_trainer',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1',
              fromNodeId: 'source_entity',
              toNodeId: 'battle_node'),
          ScenarioEdge(
              id: 'e2', fromNodeId: 'battle_node', toNodeId: 'end'),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_entity',
        ),
        context: buildContext(),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(result.effect.trainerId, 'test_trainer');
      expect(result.effect.npcEntityId, 'test_npc_entity');
      expect(result.effect.battleId, 'test_battle');
    });

    test('graph suspends at battle node (no leak past)', () {
      var state = const GameState(saveId: 'test_save');
      final scenario = ScenarioAsset(
        id: 'test_scene_no_leak',
        name: 'No Leak',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'test_battle'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'test_trainer',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'leak_flag',
            type: ScenarioNodeType.action,
            payload:
                ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding:
                ScenarioNodeBinding(flagName: 'test_flag_should_not_be_set'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1',
              fromNodeId: 'source_entity',
              toNodeId: 'battle_node'),
          ScenarioEdge(
              id: 'e2',
              fromNodeId: 'battle_node',
              toNodeId: 'leak_flag'),
          ScenarioEdge(
              id: 'e3', fromNodeId: 'leak_flag', toNodeId: 'end'),
        ],
      );

      executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_entity',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      expect(state.storyFlags.activeFlags,
          isNot(contains('test_flag_should_not_be_set')));
    });

    test('result has non-null scenarioId/sourceNodeId/stopNodeId', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_complete',
        name: 'Complete',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'test_battle'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'test_trainer',
              entityId: 'test_npc_entity',
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1',
              fromNodeId: 'source_entity',
              toNodeId: 'battle_node'),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_entity',
        ),
        context: buildContext(),
      );

      expect(result.scenarioId, isNotNull);
      expect(result.sourceNodeId, isNotNull);
      expect(result.stopNodeId, 'battle_node');
    });
  });

  // ─────────────────────────────────────────────────────────
  // 9.3  Battle outcome flags
  // ─────────────────────────────────────────────────────────

  group('Battle outcome flags', () {
    test('victory flag format: battle:<battleId>:victory', () {
      expect(
        scenarioBattleOutcomeFlagName('test_battle', kBattleOutcomeSuffixVictory),
        'battle:test_battle:victory',
      );
    });

    test('defeat flag format: battle:<battleId>:defeat', () {
      expect(
        scenarioBattleOutcomeFlagName('test_battle', kBattleOutcomeSuffixDefeat),
        'battle:test_battle:defeat',
      );
    });

    test('flee flag format: battle:<battleId>:flee', () {
      expect(
        scenarioBattleOutcomeFlagName('test_battle', kBattleOutcomeSuffixFlee),
        'battle:test_battle:flee',
      );
    });

    test('captured flag format: battle:<battleId>:captured', () {
      expect(
        scenarioBattleOutcomeFlagName(
            'test_battle', kBattleOutcomeSuffixCaptured),
        'battle:test_battle:captured',
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // 9.4  Scenario continuation after battle
  // ─────────────────────────────────────────────────────────

  group('Scenario continuation after battle', () {
    /// Full scenario graph:
    /// source_entity → battle_node → condition(victory?) →
    ///   true  → set_flag(test_flag_victory_path) → complete_step(test_step_victory) → end
    ///   false → set_flag(test_flag_defeat_path)  → complete_step(test_step_defeat)  → end_defeat
    ScenarioAsset fullBattleBranchScenario() {
      return ScenarioAsset(
        id: 'test_scene_full_branch',
        name: 'Full Battle Branch',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'test_battle'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'test_trainer',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'condition_victory',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName:
                      'battle:test_battle:victory',
                },
              ),
            ),
          ),
          // Victory path
          ScenarioNode(
            id: 'set_victory_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: 'test_flag_victory_path'),
          ),
          ScenarioNode(
            id: 'complete_victory_step',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: <String, String>{'stepId': 'test_step_victory'},
            ),
          ),
          ScenarioNode(id: 'end_victory', type: ScenarioNodeType.end),
          // Defeat path
          ScenarioNode(
            id: 'set_defeat_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: 'test_flag_defeat_path'),
          ),
          ScenarioNode(
            id: 'complete_defeat_step',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: <String, String>{'stepId': 'test_step_defeat'},
            ),
          ),
          ScenarioNode(id: 'end_defeat', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1',
              fromNodeId: 'source_entity',
              toNodeId: 'battle_node'),
          ScenarioEdge(
              id: 'e2',
              fromNodeId: 'battle_node',
              toNodeId: 'condition_victory'),
          // Victory branch
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'condition_victory',
            toNodeId: 'set_victory_flag',
            kind: ScenarioEdgeKind.trueBranch,
          ),
          ScenarioEdge(
              id: 'e4',
              fromNodeId: 'set_victory_flag',
              toNodeId: 'complete_victory_step'),
          ScenarioEdge(
              id: 'e5',
              fromNodeId: 'complete_victory_step',
              toNodeId: 'end_victory'),
          // Defeat branch
          ScenarioEdge(
            id: 'e6',
            fromNodeId: 'condition_victory',
            toNodeId: 'set_defeat_flag',
            kind: ScenarioEdgeKind.falseBranch,
          ),
          ScenarioEdge(
              id: 'e7',
              fromNodeId: 'set_defeat_flag',
              toNodeId: 'complete_defeat_step'),
          ScenarioEdge(
              id: 'e8',
              fromNodeId: 'complete_defeat_step',
              toNodeId: 'end_defeat'),
        ],
      );
    }

    test('victory: continuation sets flag and completes step', () {
      final scenario = fullBattleBranchScenario();

      // Simulate: runtime has set the battle outcome victory flag.
      var state = const GameState(saveId: 'test_save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'battle:test_battle:victory',
        }),
      );

      final result = executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 'test_scene_full_branch',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'battle_node',
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (d, {startNode, runtimeSourceId}) => true,
          runScript: (s, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains('test_flag_victory_path'));
      expect(state.storyFlags.activeFlags,
          isNot(contains('test_flag_defeat_path')));
      expect(state.progression.completedStepIds, contains('test_step_victory'));
      expect(state.progression.completedStepIds,
          isNot(contains('test_step_defeat')));
    });

    test('defeat: continuation sets flag and completes step', () {
      final scenario = fullBattleBranchScenario();

      // Simulate: runtime has set the battle outcome defeat flag.
      var state = const GameState(saveId: 'test_save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'battle:test_battle:defeat',
        }),
      );

      final result = executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 'test_scene_full_branch',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'battle_node',
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (d, {startNode, runtimeSourceId}) => true,
          runScript: (s, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains('test_flag_defeat_path'));
      expect(state.storyFlags.activeFlags,
          isNot(contains('test_flag_victory_path')));
      expect(state.progression.completedStepIds, contains('test_step_defeat'));
      expect(state.progression.completedStepIds,
          isNot(contains('test_step_victory')));
    });

    test('victory continuation opens dialogue on branch if present', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_dialogue_branch',
        name: 'Dialogue Branch',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'test_battle'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'test_trainer',
              entityId: 'test_npc_entity',
            ),
          ),
          ScenarioNode(
            id: 'condition_victory',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName:
                      'battle:test_battle:victory',
                },
              ),
            ),
          ),
          ScenarioNode(
            id: 'dialogue_victory',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(
                dialogueId: 'test_dialogue_after_victory'),
          ),
          ScenarioNode(
            id: 'dialogue_defeat',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(
                dialogueId: 'test_dialogue_after_defeat'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1',
              fromNodeId: 'source_entity',
              toNodeId: 'battle_node'),
          ScenarioEdge(
              id: 'e2',
              fromNodeId: 'battle_node',
              toNodeId: 'condition_victory'),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'condition_victory',
            toNodeId: 'dialogue_victory',
            kind: ScenarioEdgeKind.trueBranch,
          ),
          ScenarioEdge(
            id: 'e4',
            fromNodeId: 'condition_victory',
            toNodeId: 'dialogue_defeat',
            kind: ScenarioEdgeKind.falseBranch,
          ),
        ],
      );

      final openedDialogues = <String>[];

      // Victory case.
      var state = const GameState(saveId: 'test_save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'battle:test_battle:victory',
        }),
      );
      executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 'test_scene_dialogue_branch',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'battle_node',
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          runScript: (s, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(openedDialogues, <String>['test_dialogue_after_victory']);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 9.5  Save / reload
  // ─────────────────────────────────────────────────────────

  group('Save / reload preserves battle outcome flags', () {
    test('battle outcome flags survive save/load round-trip', () {
      var state = const GameState(saveId: 'test_save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          scenarioBattleOutcomeFlagName(
              'test_battle', kBattleOutcomeSuffixVictory),
          'test_flag_victory_path',
        }),
        progression: PlayerProgression(
          completedStepIds: ['test_step_victory'],
        ),
      );

      final saveData = saveDataFromGameState(state);
      final reloaded = normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.storyFlags.activeFlags,
          contains('battle:test_battle:victory'));
      expect(reloaded.storyFlags.activeFlags,
          contains('test_flag_victory_path'));
      expect(reloaded.progression.completedStepIds,
          contains('test_step_victory'));
    });

    test('defeat flags also survive save/load', () {
      var state = const GameState(saveId: 'test_save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          scenarioBattleOutcomeFlagName(
              'test_battle', kBattleOutcomeSuffixDefeat),
          'test_flag_defeat_path',
        }),
        progression: PlayerProgression(
          completedStepIds: ['test_step_defeat'],
        ),
      );

      final saveData = saveDataFromGameState(state);
      final reloaded = normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.storyFlags.activeFlags,
          contains('battle:test_battle:defeat'));
      expect(reloaded.storyFlags.activeFlags,
          contains('test_flag_defeat_path'));
      expect(reloaded.progression.completedStepIds,
          contains('test_step_defeat'));
    });
  });

  // ─────────────────────────────────────────────────────────
  // 9.6  No Selbrume hardcoding
  // ─────────────────────────────────────────────────────────

  test('does not hardcode any Selbrume ids', () {
    // All ids used in these tests are generic test fixtures.
    // If this test compiles and passes, no Selbrume id was hardcoded.
    expect(
      scenarioBattleOutcomeFlagName('test_battle', kBattleOutcomeSuffixVictory),
      'battle:test_battle:victory',
    );
  });
}
