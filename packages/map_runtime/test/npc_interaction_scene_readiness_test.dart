import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// ignore_for_file: prefer_const_constructors

/// Characterization tests proving the full NPC → interaction → scene chain.
///
/// These tests demonstrate that a ScenarioAsset with an entityInteract source
/// can be triggered by a player interacting with an NPC entity, and that
/// the scenario can then execute multiple gameplay actions (setFlag,
/// completeStep, givePokemon) atomically.
///
/// No Selbrume ids are used. All ids are generic test fixtures.
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

  group('NPC interaction → scene authoring readiness', () {
    test('entityInteract triggers a scenario bound to a test NPC', () {
      // A minimal scenario bound to test_npc on test_map.
      // When the player interacts with test_npc, the scenario sets a flag.
      final scenario = ScenarioAsset(
        id: 'test_scene_npc_interaction',
        name: 'NPC Interaction Scene',
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
            id: 'action_set_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionSetFlag,
            ),
            binding: ScenarioNodeBinding(
              flagName: 'test_flag_npc_interacted',
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1', fromNodeId: 'source', toNodeId: 'action_set_flag'),
          ScenarioEdge(
              id: 'e2', fromNodeId: 'action_set_flag', toNodeId: 'end'),
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

      expect(result.success, isTrue);
      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_npc_interacted'),
      );
    });

    test(
        'entityInteract triggers multi-action scene: setFlag + completeStep',
        () {
      // A scenario that sets a flag AND completes a step from one interaction.
      final scenario = ScenarioAsset(
        id: 'test_scene_multi_action',
        name: 'Multi-Action NPC Scene',
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
              entityId: 'test_entity_mentor',
            ),
          ),
          ScenarioNode(
            id: 'set_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionSetFlag,
            ),
            binding: ScenarioNodeBinding(
              flagName: 'test_flag_mentor_met',
            ),
          ),
          ScenarioNode(
            id: 'complete_step',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: {'stepId': 'test_step_mentor_interaction'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1', fromNodeId: 'source', toNodeId: 'set_flag'),
          ScenarioEdge(
              id: 'e2', fromNodeId: 'set_flag', toNodeId: 'complete_step'),
          ScenarioEdge(
              id: 'e3', fromNodeId: 'complete_step', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_entity_mentor',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      expect(result.success, isTrue);
      expect(
        state.storyFlags.activeFlags,
        contains('test_flag_mentor_met'),
      );
      expect(
        state.progression.completedStepIds,
        contains('test_step_mentor_interaction'),
      );
    });

    test('no matching scenario returns noMatchingSource', () {
      // A scenario bound to a different NPC on a different map.
      final scenario = ScenarioAsset(
        id: 'test_scene_other',
        name: 'Other Scene',
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'other_map',
              entityId: 'other_npc',
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'end'),
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

      expect(
        result.status,
        ScenarioRuntimeExecutionStatus.noMatchingSource,
      );
    });

    test('entityInteract with empty scenario list returns noMatchingSource',
        () {
      var state = const GameState(saveId: 'test');
      final result = executor.dispatch(
        scenarios: [],
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
        result.status,
        ScenarioRuntimeExecutionStatus.noMatchingSource,
      );
    });

    test('NPC scene calls onGameStateUpdated for each action', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_update_callback',
        name: 'Callback Test',
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
            id: 'set_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionSetFlag,
            ),
            binding: ScenarioNodeBinding(
              flagName: 'test_callback_flag',
            ),
          ),
          ScenarioNode(
            id: 'complete_step',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: {'stepId': 'test_callback_step'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1', fromNodeId: 'source', toNodeId: 'set_flag'),
          ScenarioEdge(
              id: 'e2', fromNodeId: 'set_flag', toNodeId: 'complete_step'),
          ScenarioEdge(
              id: 'e3', fromNodeId: 'complete_step', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      var updateCount = 0;
      executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) {
            state = next;
            updateCount++;
          },
        ),
      );

      // setFlag + completeStep = 2 calls to onGameStateUpdated.
      expect(updateCount, 2);
      expect(
        state.storyFlags.activeFlags,
        contains('test_callback_flag'),
      );
      expect(
        state.progression.completedStepIds,
        contains('test_callback_step'),
      );
    });

    test('scenario with entityInteract preserves save/load round-trip', () {
      final scenario = ScenarioAsset(
        id: 'test_scene_save_load',
        name: 'Save Load Scene',
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
              entityId: 'test_npc_save',
            ),
          ),
          ScenarioNode(
            id: 'set_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionSetFlag,
            ),
            binding: ScenarioNodeBinding(
              flagName: 'test_flag_save',
            ),
          ),
          ScenarioNode(
            id: 'complete_step',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: {'stepId': 'test_step_save'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1', fromNodeId: 'source', toNodeId: 'set_flag'),
          ScenarioEdge(
              id: 'e2', fromNodeId: 'set_flag', toNodeId: 'complete_step'),
          ScenarioEdge(
              id: 'e3', fromNodeId: 'complete_step', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc_save',
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

      expect(
        reloaded.storyFlags.activeFlags,
        contains('test_flag_save'),
      );
      expect(
        reloaded.progression.completedStepIds,
        contains('test_step_save'),
      );
    });

    test('does not hardcode any Selbrume ids', () {
      // Mechanics-first: all ids are generic test fixtures.
      final scenario = ScenarioAsset(
        id: 'test_generic_npc_scene',
        name: 'Generic NPC Scene',
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'any_map_id',
              entityId: 'any_npc_id',
            ),
          ),
          ScenarioNode(
            id: 'action',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: {'stepId': 'any_generic_step'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'action'),
          ScenarioEdge(id: 'e2', fromNodeId: 'action', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'any_map_id',
          entityId: 'any_npc_id',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      expect(result.success, isTrue);
      expect(
        state.progression.completedStepIds,
        contains('any_generic_step'),
      );
    });
  });
}
