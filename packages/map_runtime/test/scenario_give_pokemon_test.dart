import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// ignore_for_file: prefer_const_constructors

void main() {
  group('ScenarioRuntimeExecutor - givePokemon action', () {
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

    test('givePokemon action adds Pokemon to party', () {
      final scenario = ScenarioAsset(
        id: 'test_scenario',
        name: 'Test',
        entryNodeId: 'source',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_entity',
            ),
          ),
          ScenarioNode(
            id: 'give',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionGivePokemon,
              params: {'speciesId': 'test_species', 'level': '7'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'give'),
          ScenarioEdge(id: 'e2', fromNodeId: 'give', toNodeId: 'end'),
        ],
      );

      var state = const GameState(saveId: 'test');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_entity',
        ),
        context: makeContext(
          state: state,
          onUpdate: (next) => state = next,
        ),
      );

      expect(result.success, isTrue);
      expect(state.party.members, hasLength(1));
      expect(state.party.members.first.speciesId, 'test_species');
      expect(state.party.members.first.level, 7);
    });

    test('givePokemon uses defaults for optional params', () {
      final scenario = ScenarioAsset(
        id: 'test_defaults',
        name: 'Test defaults',
        entryNodeId: 'source',
        nodes: const <ScenarioNode>[
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
            id: 'give',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionGivePokemon,
              params: {'speciesId': 'default_species'},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'give'),
          ScenarioEdge(id: 'e2', fromNodeId: 'give', toNodeId: 'end'),
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

      expect(state.party.members, hasLength(1));
      final pokemon = state.party.members.first;
      expect(pokemon.speciesId, 'default_species');
      expect(pokemon.level, 5); // default level
      expect(pokemon.natureId, 'hardy'); // default nature
      expect(pokemon.abilityId, 'unknown'); // default ability
    });

    test('givePokemon blocks when speciesId is missing', () {
      final scenario = ScenarioAsset(
        id: 'test_no_species',
        name: 'No species',
        entryNodeId: 'source',
        nodes: const <ScenarioNode>[
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
            id: 'give',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionGivePokemon,
              params: {},
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'give'),
          ScenarioEdge(id: 'e2', fromNodeId: 'give', toNodeId: 'end'),
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
      expect(state.party.members, isEmpty);
    });

    test('givePokemon with preventDuplicate prevents double give', () {
      final scenario = ScenarioAsset(
        id: 'test_prevent_dup',
        name: 'Prevent duplicate',
        entryNodeId: 'source',
        nodes: const <ScenarioNode>[
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
            id: 'give',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionGivePokemon,
              params: {
                'speciesId': 'unique_species',
                'preventDuplicate': 'true',
              },
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'give'),
          ScenarioEdge(id: 'e2', fromNodeId: 'give', toNodeId: 'end'),
        ],
      );

      // First dispatch: adds the pokemon.
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
      expect(state.party.members, hasLength(1));

      // Second dispatch: duplicate prevention, still only 1.
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
      expect(state.party.members, hasLength(1));
    });
  });
}
