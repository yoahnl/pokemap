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
      String executionId = 'scenario_execution',
    }) {
      return ScenarioRuntimeExecutionContext(
        executionId: executionId,
        gameState: state,
        onGameStateUpdated: onUpdate,
        openDialogue: (_, {startNode, runtimeSourceId}) => false,
        runScript: (_, {startNode, runtimeSourceId}) => false,
        showMessage: (_) {},
      );
    }

    test('givePokemon action emits a grant effect without mutating state', () {
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
              params: {
                'speciesId': 'test_species',
                'formId': 'festival',
                'level': '7',
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
      expect(result.effect.type, ScenarioRuntimeEffectType.givePokemon);
      expect(result.effect.pokemon?.speciesId, 'test_species');
      expect(result.effect.pokemon?.formId, 'festival');
      expect(result.effect.pokemon?.level, 7);
      expect(result.effect.pokemon?.currentHp, 7);
      expect(
        result.effect.grantOperationId,
        'scenario:test_scenario:scenario_execution:give',
      );
      expect(state.party.members, isEmpty);
      expect(state.appliedPokemonGrantOperationIds, isEmpty);
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
              params: {
                'speciesId': 'default_species',
                'formId': 'base',
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

      expect(state.party.members, isEmpty);
      final pokemon = result.effect.pokemon!;
      expect(pokemon.speciesId, 'default_species');
      expect(pokemon.formId, 'base');
      expect(pokemon.level, 5); // default level
      expect(pokemon.natureId, 'hardy'); // default nature
      expect(pokemon.abilityId, 'unknown'); // default ability
      expect(pokemon.knownMoveIds, isEmpty); // default: no moves
      expect(pokemon.currentHp, 5); // default: equals level
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

    test('givePokemon blocks when formId is missing', () {
      final scenario = ScenarioAsset(
        id: 'test_no_form',
        name: 'No form',
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
              params: {'speciesId': 'test_species'},
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'source', toNodeId: 'give'),
          ScenarioEdge(id: 'e2', fromNodeId: 'give', toNodeId: 'end'),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_npc',
        ),
        context: makeContext(
          state: const GameState(saveId: 'test'),
          onUpdate: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message, contains('formId'));
    });

    test('givePokemon transports the duplicate-species policy', () {
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
                'formId': 'base',
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
      expect(result.effect.preventDuplicateSpecies, isTrue);
      expect(state.party.members, isEmpty);
    });

    test('givePokemon accepts knownMoveIds from payload', () {
      final scenario = ScenarioAsset(
        id: 'test_moves',
        name: 'With moves',
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
                'speciesId': 'test_species',
                'formId': 'base',
                'level': '10',
                'knownMoveIds': 'tackle,growl',
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

      expect(state.party.members, isEmpty);
      final pokemon = result.effect.pokemon!;
      expect(pokemon.knownMoveIds, ['tackle', 'growl']);
    });

    test('givePokemon trims knownMoveIds', () {
      final scenario = ScenarioAsset(
        id: 'test_trim_moves',
        name: 'Trim moves',
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
                'speciesId': 'test_species',
                'formId': 'base',
                'knownMoveIds': ' tackle , growl , ',
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

      final pokemon = result.effect.pokemon!;
      expect(state.party.members, isEmpty);
      expect(pokemon.knownMoveIds, ['tackle', 'growl']);
    });

    test('givePokemon accepts currentHp from payload', () {
      final scenario = ScenarioAsset(
        id: 'test_hp',
        name: 'With HP',
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
                'speciesId': 'test_species',
                'formId': 'base',
                'level': '10',
                'currentHp': '25',
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

      final pokemon = result.effect.pokemon!;
      expect(state.party.members, isEmpty);
      expect(pokemon.currentHp, 25);
      expect(pokemon.level, 10);
    });

    test('givePokemon defaults currentHp to level when absent', () {
      final scenario = ScenarioAsset(
        id: 'test_hp_default',
        name: 'HP defaults to level',
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
                'speciesId': 'test_species',
                'formId': 'base',
                'level': '15',
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

      final pokemon = result.effect.pokemon!;
      expect(state.party.members, isEmpty);
      expect(pokemon.level, 15);
      expect(pokemon.currentHp, 15); // fallback = level
    });

    test('givePokemon handles invalid currentHp safely', () {
      final scenario = ScenarioAsset(
        id: 'test_bad_hp',
        name: 'Bad HP',
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
                'speciesId': 'test_species',
                'formId': 'base',
                'level': '8',
                'currentHp': 'not_a_number',
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
      final pokemon = result.effect.pokemon!;
      expect(state.party.members, isEmpty);
      expect(pokemon.level, 8);
      expect(pokemon.currentHp, 8); // fallback = level when invalid
    });
  });
}
