import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const String _testMapId = 'test_map';
const String _testBattleId = 'test_reward_battle';
const String _testTrainerId = 'test_reward_trainer';
const String _testNpcEntityId = 'test_reward_npc';
const String _testRewardItemId = 'test_item_reward';
const String _testRewardFact = 'test_reward_claimed_fact';
const String _testRewardStep = 'test_step_reward_claimed';
const String _testPlayerSpeciesId = 'test_player_species';

void main() {
  group('Reward bridge readiness', () {
    const executor = ScenarioRuntimeExecutor();

    test('trainer victory continuation can give item reward', () {
      var state = _initialState(money: 500);

      _startBattle(executor, state);
      final result = _continueAfterVictory(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.success, isTrue);
      expect(state.bag.entries.single.itemId, _testRewardItemId);
      expect(state.bag.entries.single.quantity, 2);
    });

    test('trainer victory continuation can complete reward fact and step', () {
      var state = _initialState();

      _startBattle(executor, state);
      final result = _continueAfterVictory(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.success, isTrue);
      expect(state.storyFlags.activeFlags, contains(_testRewardFact));
      expect(state.progression.completedStepIds, contains(_testRewardStep));
    });

    test('save load preserves post battle item reward fact and step', () {
      var state = _initialState(money: 500);

      _continueAfterVictory(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(saveDataFromGameState(state)),
      );

      expect(reloaded.bag.entries.single.itemId, _testRewardItemId);
      expect(reloaded.bag.entries.single.quantity, 2);
      expect(reloaded.storyFlags.activeFlags, contains(_testRewardFact));
      expect(reloaded.progression.completedStepIds, contains(_testRewardStep));
      expect(reloaded.trainerProfile.money, 500);
    });

    test('post battle item reward does not imply money xp or level up', () {
      var state = _initialState(money: 500, level: 7);

      _continueAfterVictory(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      final member = state.party.members.single;
      expect(state.trainerProfile.money, 500);
      expect(member.level, 7);
      expect(member.knownMoveIds, <String>['test_move']);
    });

    test('fixtures use only generic reward bridge ids', () {
      final fixtureIds = <String>{
        _testMapId,
        _testBattleId,
        _testTrainerId,
        _testNpcEntityId,
        _testRewardItemId,
        _testRewardFact,
        _testRewardStep,
        _testPlayerSpeciesId,
      };

      for (final id in fixtureIds) {
        expect(id, startsWith('test_'));
      }
    });
  });
}

GameState _initialState({int money = 0, int level = 5}) {
  return createNewGameState(
    startMapId: _testMapId,
    saveId: 'test_reward_save',
  ).copyWith(
    trainerProfile: TrainerProfile(name: 'Test Player', money: money),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: _testPlayerSpeciesId,
          natureId: 'test_nature',
          abilityId: 'test_ability',
          level: level,
          knownMoveIds: const <String>['test_move'],
          currentHp: 12,
        ),
      ],
    ),
  );
}

ScenarioRuntimeExecutionResult _startBattle(
  ScenarioRuntimeExecutor executor,
  GameState state,
) {
  return executor.dispatch(
    scenarios: [_rewardScenario()],
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _testMapId,
      entityId: _testNpcEntityId,
    ),
    context: _context(
      state,
      onUpdate: (_) {},
    ),
  );
}

ScenarioRuntimeExecutionResult _continueAfterVictory(
  ScenarioRuntimeExecutor executor, {
  required GameState state,
  required void Function(GameState next) onUpdate,
}) {
  final stateWithVictory = state.copyWith(
    storyFlags: StoryFlags(
      activeFlags: <String>{
        ...state.storyFlags.activeFlags,
        scenarioBattleOutcomeFlagName(
          _testBattleId,
          kBattleOutcomeSuffixVictory,
        ),
      },
    ),
  );

  return executor.dispatchContinuation(
    scenarios: [_rewardScenario()],
    scenarioId: 'test_reward_bridge_scene',
    sourceNodeId: 'test_source_reward_battle',
    context: _context(stateWithVictory, onUpdate: onUpdate),
    resumeAfterNodeId: 'test_start_reward_battle',
  );
}

ScenarioRuntimeExecutionContext _context(
  GameState state, {
  required void Function(GameState next) onUpdate,
}) {
  return ScenarioRuntimeExecutionContext(
    gameState: state,
    onGameStateUpdated: onUpdate,
    openDialogue: (_, {startNode, runtimeSourceId}) => false,
    runScript: (_, {startNode, runtimeSourceId}) => false,
    showMessage: (_) {},
  );
}

ScenarioAsset _rewardScenario() {
  final victoryFlag = scenarioBattleOutcomeFlagName(
    _testBattleId,
    kBattleOutcomeSuffixVictory,
  );

  return ScenarioAsset(
    id: 'test_reward_bridge_scene',
    name: 'Test Reward Bridge Scene',
    entryNodeId: 'test_start',
    nodes: <ScenarioNode>[
      const ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      const ScenarioNode(
        id: 'test_source_reward_battle',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(
          actionKind: kScenarioSourceEntityInteract,
        ),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testNpcEntityId,
        ),
      ),
      const ScenarioNode(
        id: 'test_start_reward_battle',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(
          trainerId: _testTrainerId,
          entityId: _testNpcEntityId,
        ),
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionStartTrainerBattle,
          params: <String, String>{'battleId': _testBattleId},
        ),
      ),
      ScenarioNode(
        id: 'test_condition_reward_victory',
        type: ScenarioNodeType.condition,
        payload: ScenarioNodePayload(
          condition: ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: <String, String>{
              ScriptConditionParams.flagName: victoryFlag,
            },
          ),
        ),
      ),
      const ScenarioNode(
        id: 'test_give_reward_item',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionGiveItem,
          params: <String, String>{
            'itemId': _testRewardItemId,
            'quantity': '2',
          },
        ),
      ),
      const ScenarioNode(
        id: 'test_set_reward_fact',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(flagName: _testRewardFact),
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      ),
      const ScenarioNode(
        id: 'test_complete_reward_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: <String, String>{
            'stepId': _testRewardStep,
          },
        ),
      ),
      const ScenarioNode(
        id: 'test_reward_end',
        type: ScenarioNodeType.end,
      ),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'test_edge_source_to_battle',
        fromNodeId: 'test_source_reward_battle',
        toNodeId: 'test_start_reward_battle',
      ),
      ScenarioEdge(
        id: 'test_edge_battle_to_condition',
        fromNodeId: 'test_start_reward_battle',
        toNodeId: 'test_condition_reward_victory',
      ),
      ScenarioEdge(
        id: 'test_edge_reward_victory_true',
        fromNodeId: 'test_condition_reward_victory',
        toNodeId: 'test_give_reward_item',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      ScenarioEdge(
        id: 'test_edge_reward_victory_false',
        fromNodeId: 'test_condition_reward_victory',
        toNodeId: 'test_reward_end',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      ScenarioEdge(
        id: 'test_edge_reward_item_to_fact',
        fromNodeId: 'test_give_reward_item',
        toNodeId: 'test_set_reward_fact',
      ),
      ScenarioEdge(
        id: 'test_edge_reward_fact_to_step',
        fromNodeId: 'test_set_reward_fact',
        toNodeId: 'test_complete_reward_step',
      ),
      ScenarioEdge(
        id: 'test_edge_reward_step_to_end',
        fromNodeId: 'test_complete_reward_step',
        toNodeId: 'test_reward_end',
      ),
    ],
  );
}
