import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// ignore_for_file: prefer_const_constructors

/// Characterization tests proving the Yarn/Dialogue outcome → Scene branch chain.
///
/// The mechanism works as follows:
/// 1. emitOutcome('outcomeId') sets a flag `scenario.outcome.outcomeId`
///    in the GameState and attempts a global dispatch via outcomeReceived.
/// 2. A condition node reads flagIsSet('scenario.outcome.outcomeId').
/// 3. The condition node branches via trueBranch / falseBranch edges.
///
/// This is NOT a raw dialogue Yarn runtime test. It tests the Scene-level
/// mechanism that a Scene author can use after a dialogue produces an outcome.
/// The dialogue runtime itself (parse_yarn_dialogue, DialogueRuntimeController)
/// is responsible for surfacing outcomes from Yarn; this lot proves the Scene
/// can consume them via the outcome-as-flag convention.
///
/// Garde-fou faux positif: these tests use emitOutcome which IS the runtime
/// mechanism for Scene outcome emission. It is equivalent (case 2 in the prompt)
/// because the dialogue runtime emits outcomes using the same pipeline.
///
/// No Selbrume ids are used. All ids are generic test fixtures.
/// Event vs Scene boundary: this lot tests Scene branching only. Events are
/// flat reactions without branching; Scenes own the branching logic.
void main() {
  const executor = ScenarioRuntimeExecutor();

  ScenarioRuntimeExecutionContext makeContext({
    required GameState state,
    required void Function(GameState) onUpdate,
  }) {
    return ScenarioRuntimeExecutionContext(
      gameState: state,
      onGameStateUpdated: onUpdate,
      openDialogue: (_, {startNode, runtimeSourceId}) => false,
      runScript: (_, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    );
  }

  /// Builds a scenario that:
  /// 1. emitOutcome with the given outcomeId
  /// 2. After the outcome, continues linearly to end
  ///
  /// Used to simulate a dialogue producing an outcome.
  ScenarioAsset outcomeEmitterScenario({
    required String outcomeId,
  }) {
    return ScenarioAsset(
      id: 'test_scene_outcome_emitter',
      name: 'Outcome Emitter',
      entryNodeId: 'source',
      nodes: <ScenarioNode>[
        ScenarioNode(
          id: 'source',
          type: ScenarioNodeType.reference,
          payload: ScenarioNodePayload(
            actionKind: kScenarioSourceEntityInteract,
          ),
          binding: ScenarioNodeBinding(
            mapId: 'test_map',
            entityId: 'test_npc_emitter',
          ),
        ),
        ScenarioNode(
          id: 'emit',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionEmitOutcome,
          ),
          binding: ScenarioNodeBinding(
            outcomeId: outcomeId,
          ),
        ),
        ScenarioNode(
          id: 'end',
          type: ScenarioNodeType.end,
        ),
      ],
      edges: const <ScenarioEdge>[
        ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'emit'),
        ScenarioEdge(id: 'e2', fromNodeId: 'emit', toNodeId: 'end'),
      ],
    );
  }

  /// Builds a scenario that:
  /// 1. Starts from an NPC interaction
  /// 2. Checks a condition on a specific outcome flag
  /// 3. On true branch: setFlag test_flag_confident_path
  /// 4. On false branch: setFlag test_flag_tease_path
  /// 5. Both branches converge to end
  ScenarioAsset branchingScenario({
    required String checkedOutcomeId,
  }) {
    return ScenarioAsset(
      id: 'test_scene_branch_by_outcome',
      name: 'Branch By Outcome',
      entryNodeId: 'source',
      nodes: <ScenarioNode>[
        ScenarioNode(
          id: 'source',
          type: ScenarioNodeType.reference,
          payload: ScenarioNodePayload(
            actionKind: kScenarioSourceEntityInteract,
          ),
          binding: ScenarioNodeBinding(
            mapId: 'test_map',
            entityId: 'test_npc_branch',
          ),
        ),
        ScenarioNode(
          id: 'check_outcome',
          type: ScenarioNodeType.condition,
          payload: ScenarioNodePayload(
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {
                ScriptConditionParams.flagName:
                    scenarioOutcomeFlagName(checkedOutcomeId),
              },
            ),
          ),
        ),
        ScenarioNode(
          id: 'action_true',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionSetFlag,
          ),
          binding: ScenarioNodeBinding(
            flagName: 'test_flag_confident_path',
          ),
        ),
        ScenarioNode(
          id: 'action_false',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionSetFlag,
          ),
          binding: ScenarioNodeBinding(
            flagName: 'test_flag_tease_path',
          ),
        ),
        ScenarioNode(
          id: 'end',
          type: ScenarioNodeType.end,
        ),
      ],
      edges: const <ScenarioEdge>[
        ScenarioEdge(
            id: 'e1', fromNodeId: 'source', toNodeId: 'check_outcome'),
        ScenarioEdge(
          id: 'e2',
          fromNodeId: 'check_outcome',
          toNodeId: 'action_true',
          kind: ScenarioEdgeKind.trueBranch,
        ),
        ScenarioEdge(
          id: 'e3',
          fromNodeId: 'check_outcome',
          toNodeId: 'action_false',
          kind: ScenarioEdgeKind.falseBranch,
        ),
        ScenarioEdge(
            id: 'e4', fromNodeId: 'action_true', toNodeId: 'end'),
        ScenarioEdge(
            id: 'e5', fromNodeId: 'action_false', toNodeId: 'end'),
      ],
    );
  }

  group('Outcome → Scene branch readiness', () {
    test('emitOutcome sets the outcome flag in GameState', () {
      final scenario = outcomeEmitterScenario(outcomeId: 'test_confident');
      var state = const GameState(saveId: 'test');
      executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_emitter',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // emitOutcome stores outcome as a flag with prefix 'scenario.outcome.'
      expect(
        state.storyFlags.activeFlags,
        contains(scenarioOutcomeFlagName('test_confident')),
      );
      expect(
        state.storyFlags.activeFlags,
        contains('scenario.outcome.test_confident'),
      );
    });

    test('condition node branches to true when outcome flag is set', () {
      final branching = branchingScenario(checkedOutcomeId: 'test_confident');

      // Pre-set the outcome flag (simulates emitOutcome having run before).
      var state = const GameState(
        saveId: 'test',
        storyFlags: StoryFlags(activeFlags: {
          'scenario.outcome.test_confident',
        }),
      );

      executor.dispatch(
        scenarios: [branching],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_branch',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // True branch taken → confident path flag set.
      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_confident_path'),
      );
      // False branch NOT taken.
      expect(
        state.storyFlags.activeFlags,
        isNot(contains('test_flag_tease_path')),
      );
    });

    test('condition node branches to false when outcome flag is absent', () {
      final branching = branchingScenario(checkedOutcomeId: 'test_confident');

      // No outcome flag set → false branch.
      var state = const GameState(saveId: 'test');

      executor.dispatch(
        scenarios: [branching],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_branch',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // False branch taken → tease path flag set.
      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_tease_path'),
      );
      // True branch NOT taken.
      expect(
        state.storyFlags.activeFlags,
        isNot(contains('test_flag_confident_path')),
      );
    });

    test('full chain: emitOutcome then branch reads outcome flag', () {
      final emitter = outcomeEmitterScenario(outcomeId: 'test_confident');
      final branching = branchingScenario(checkedOutcomeId: 'test_confident');

      var state = const GameState(saveId: 'test');

      // Step 1: emit outcome (simulates dialogue producing outcome).
      executor.dispatch(
        scenarios: [emitter],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_emitter',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // Verify outcome flag was set.
      expect(
        state.storyFlags.activeFlags,
        contains('scenario.outcome.test_confident'),
      );

      // Step 2: branch scene reads the outcome flag.
      executor.dispatch(
        scenarios: [branching],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_branch',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // True branch taken because outcome flag was set.
      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_confident_path'),
      );
      expect(
        state.storyFlags.activeFlags,
        isNot(contains('test_flag_tease_path')),
      );
    });

    test('different outcome leads to different branch', () {
      // Emit 'hesitant' instead of 'confident'.
      final emitter = outcomeEmitterScenario(outcomeId: 'test_hesitant');
      final branching = branchingScenario(checkedOutcomeId: 'test_confident');

      var state = const GameState(saveId: 'test');

      // Emit hesitant outcome.
      executor.dispatch(
        scenarios: [emitter],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_emitter',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // Now branch checks for 'confident' which was NOT emitted.
      executor.dispatch(
        scenarios: [branching],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_branch',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // False branch taken because 'confident' was not emitted.
      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_tease_path'),
      );
      expect(
        state.storyFlags.activeFlags,
        isNot(contains('test_flag_confident_path')),
      );
      // But 'hesitant' outcome IS set.
      expect(
        state.storyFlags.activeFlags,
        contains('scenario.outcome.test_hesitant'),
      );
    });

    test('outcome flag survives save/load round-trip', () {
      final emitter = outcomeEmitterScenario(outcomeId: 'test_roundtrip');

      var state = const GameState(saveId: 'test');
      executor.dispatch(
        scenarios: [emitter],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_emitter',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      // Save and reload.
      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      // Outcome flag persists through save/load.
      expect(
        reloaded.storyFlags.activeFlags,
        contains('scenario.outcome.test_roundtrip'),
      );
    });

    test('emitOutcome with completeStep in same flow', () {
      // A scene that emits an outcome AND completes a step.
      final scenario = ScenarioAsset(
        id: 'test_scene_outcome_and_step',
        name: 'Outcome And Step',
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc',
            ),
          ),
          ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionEmitOutcome,
            ),
            binding: ScenarioNodeBinding(
              outcomeId: 'test_outcome_done',
            ),
          ),
          ScenarioNode(
            id: 'complete',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: {'stepId': 'test_step_outcome_done'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'emit'),
          ScenarioEdge(id: 'e2', fromNodeId: 'emit', toNodeId: 'complete'),
          ScenarioEdge(id: 'e3', fromNodeId: 'complete', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      expect(
        state.storyFlags.activeFlags,
        contains('scenario.outcome.test_outcome_done'),
      );
      expect(
        state.progression.completedStepIds,
        contains('test_step_outcome_done'),
      );
    });

    test('emitOutcome blocks when outcomeId is missing', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_no_outcome',
        name: 'No Outcome',
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_npc',
            ),
          ),
          ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionEmitOutcome,
            ),
            binding: const ScenarioNodeBinding(),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'emit'),
          ScenarioEdge(id: 'e2', fromNodeId: 'emit', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
    });

    test('does not hardcode any Selbrume ids', () {
      final emitter = outcomeEmitterScenario(outcomeId: 'any_generic_outcome');
      final branching =
          branchingScenario(checkedOutcomeId: 'any_generic_outcome');

      var state = const GameState(saveId: 'test');
      executor.dispatch(
        scenarios: [emitter],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_emitter',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      executor.dispatch(
        scenarios: [branching],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_branch',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_confident_path'),
      );
    });
  });
}
