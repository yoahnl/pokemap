import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

const String _testMapId = 'test_map';
const String _testMainStoryFact = 'test_main_story_fact';
const String _testOptionalQuestAvailableFact =
    'test_optional_quest_available_fact';
const String _testSideQuestStartedFact = 'test_side_quest_started_fact';
const String _testSideQuestCompletedFact = 'test_side_quest_completed_fact';
const String _testOptionalQuestGiverId = 'test_optional_quest_giver';
const String _testOptionalObjectiveEntityId = 'test_optional_objective_entity';
const String _testOptionalRewardEntityId = 'test_optional_reward_entity';
const String _testSideQuestStartSceneId = 'test_side_quest_start_scene';
const String _testSideQuestObjectiveSceneId = 'test_side_quest_objective_scene';
const String _testSideQuestCompleteSceneId = 'test_side_quest_complete_scene';
const String _testStepSideQuestStarted = 'test_step_side_quest_started';
const String _testStepSideQuestObjectiveDone =
    'test_step_side_quest_objective_done';
const String _testStepSideQuestCompleted = 'test_step_side_quest_completed';
const String _testItemReward = 'test_item_reward';
const String _testDialogueBeforeQuest = 'test_dialogue_before_quest';
const String _testDialogueAfterQuest = 'test_dialogue_after_quest';

// Scenario conditions currently read facts, while world rules can read steps.
// The V0 authoring pattern mirrors the optional objective step into a generic
// fact with the same id, avoiding any dedicated Quest Engine.
const String _testObjectiveDoneFact = _testStepSideQuestObjectiveDone;

void main() {
  group('Side Quest / Optional Storyline authoring readiness', () {
    const executor = ScenarioRuntimeExecutor();

    test('optional quest is unavailable before prerequisite fact', () {
      var state = createNewGameState(startMapId: _testMapId);

      final result = _dispatch(
        executor,
        scenario: _startQuestScenario(),
        entityId: _testOptionalQuestGiverId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.noMatchingSource);
      expect(
        state.storyFlags.activeFlags,
        isNot(contains(_testSideQuestStartedFact)),
      );
      expect(
        state.progression.completedStepIds,
        isNot(contains(_testStepSideQuestStarted)),
      );
    });

    test('optional quest becomes available after prerequisite fact', () {
      var state = _availableState();

      final result = _dispatch(
        executor,
        scenario: _startQuestScenario(),
        entityId: _testOptionalQuestGiverId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains(_testSideQuestStartedFact));
      expect(
        state.progression.completedStepIds,
        contains(_testStepSideQuestStarted),
      );
    });

    test('world rule hides optional quest giver before availability', () {
      final giver = _availableOnlyQuestGiver();
      final before = createNewGameState(startMapId: _testMapId);
      final after = _availableState();

      expect(_evaluator(before).isNpcPresentOnMap(giver), isFalse);
      expect(_evaluator(after).isNpcPresentOnMap(giver), isTrue);
    });

    test('starting optional quest sets started fact and step', () {
      var state = _availableState();

      _dispatch(
        executor,
        scenario: _startQuestScenario(),
        entityId: _testOptionalQuestGiverId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(state.storyFlags.activeFlags, contains(_testSideQuestStartedFact));
      expect(
        state.progression.completedStepIds,
        contains(_testStepSideQuestStarted),
      );
    });

    test('optional objective step can be completed independently', () {
      var state = _startedState();

      final result = _dispatch(
        executor,
        scenario: _objectiveScenario(),
        entityId: _testOptionalObjectiveEntityId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
        state.progression.completedStepIds,
        contains(_testStepSideQuestObjectiveDone),
      );
      expect(state.storyFlags.activeFlags, contains(_testObjectiveDoneFact));
      expect(
        state.storyFlags.activeFlags,
        isNot(contains(_testSideQuestCompletedFact)),
      );
    });

    test('optional quest final scene stays blocked before objective completion',
        () {
      var state = _startedState();
      final messages = <String>[];

      final result = _dispatch(
        executor,
        scenario: _completeQuestScenario(),
        entityId: _testOptionalRewardEntityId,
        state: state,
        messages: messages,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.message);
      expect(result.stopNodeId, 'test_final_blocked_message');
      expect(messages, [_testDialogueBeforeQuest]);
      expect(
        state.storyFlags.activeFlags,
        isNot(contains(_testSideQuestCompletedFact)),
      );
      expect(state.bag.entries, isEmpty);
    });

    test('optional quest final scene completes quest after objective step', () {
      var state = _objectiveDoneState();

      final result = _dispatch(
        executor,
        scenario: _completeQuestScenario(),
        entityId: _testOptionalRewardEntityId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
        state.storyFlags.activeFlags,
        contains(_testSideQuestCompletedFact),
      );
      expect(
        state.progression.completedStepIds,
        contains(_testStepSideQuestCompleted),
      );
    });

    test('optional quest can give simple item reward via giveItem', () {
      var state = _objectiveDoneState();

      _dispatch(
        executor,
        scenario: _completeQuestScenario(),
        entityId: _testOptionalRewardEntityId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(state.bag.entries.single.itemId, _testItemReward);
      expect(state.bag.entries.single.quantity, 1);
    });

    test('save/load preserves started objective completed and reward', () {
      final state = _runFullSideQuest(executor);

      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(saveDataFromGameState(state)),
      );

      expect(
        reloaded.storyFlags.activeFlags,
        contains(_testSideQuestStartedFact),
      );
      expect(reloaded.storyFlags.activeFlags, contains(_testObjectiveDoneFact));
      expect(
        reloaded.storyFlags.activeFlags,
        contains(_testSideQuestCompletedFact),
      );
      expect(
        reloaded.progression.completedStepIds,
        contains(_testStepSideQuestStarted),
      );
      expect(
        reloaded.progression.completedStepIds,
        contains(_testStepSideQuestObjectiveDone),
      );
      expect(
        reloaded.progression.completedStepIds,
        contains(_testStepSideQuestCompleted),
      );
      expect(reloaded.bag.entries.single.itemId, _testItemReward);
      expect(reloaded.bag.entries.single.quantity, 1);
    });

    test('world rule changes dialogue after optional quest completion', () {
      final npc = _questGiverDialogueNpc();
      final before = _availableState();
      final after = _completedState();

      expect(
        _evaluator(before).resolveNpcDialogue(npc.npc!)?.dialogueId,
        _testDialogueBeforeQuest,
      );
      expect(
        _evaluator(after).resolveNpcDialogue(npc.npc!)?.dialogueId,
        _testDialogueAfterQuest,
      );
    });

    test('world rule can hide optional objective after completion', () {
      final objective = _objectiveProxyNpc();
      final before = _startedState();
      final after = _completedState();

      expect(_evaluator(before).isNpcPresentOnMap(objective), isTrue);
      expect(_evaluator(after).isNpcPresentOnMap(objective), isFalse);
    });

    test('main story fact is not required or mutated by optional quest', () {
      final state = _runFullSideQuest(executor);

      expect(state.storyFlags.activeFlags, isNot(contains(_testMainStoryFact)));
      expect(
        state.storyFlags.activeFlags,
        contains(_testSideQuestCompletedFact),
      );
    });

    test('side quest replay is prevented by completion condition', () {
      var state = _runFullSideQuest(executor);

      final result = _dispatch(
        executor,
        scenario: _startQuestScenario(),
        entityId: _testOptionalQuestGiverId,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.noMatchingSource);
      expect(
        state.progression.completedStepIds
            .where((id) => id == _testStepSideQuestStarted),
        hasLength(1),
      );
      expect(state.bag.entries.single.quantity, 1);
    });

    test('fixtures use only generic test ids', () {
      final ids = <String>[
        _testMapId,
        _testMainStoryFact,
        _testOptionalQuestAvailableFact,
        _testSideQuestStartedFact,
        _testSideQuestCompletedFact,
        _testOptionalQuestGiverId,
        _testOptionalObjectiveEntityId,
        _testOptionalRewardEntityId,
        _testSideQuestStartSceneId,
        _testSideQuestObjectiveSceneId,
        _testSideQuestCompleteSceneId,
        _testStepSideQuestStarted,
        _testStepSideQuestObjectiveDone,
        _testStepSideQuestCompleted,
        _testItemReward,
        _testDialogueBeforeQuest,
        _testDialogueAfterQuest,
        for (final scenario in [
          _startQuestScenario(),
          _objectiveScenario(),
          _completeQuestScenario(),
        ]) ...[
          scenario.id,
          for (final node in scenario.nodes) node.id,
          for (final edge in scenario.edges) edge.id,
        ],
      ];

      expect(ids, everyElement(startsWith('test_')));
    });
  });
}

ScenarioRuntimeExecutionResult _dispatch(
  ScenarioRuntimeExecutor executor, {
  required ScenarioAsset scenario,
  required String entityId,
  required GameState state,
  required void Function(GameState) onUpdate,
  List<String>? messages,
}) {
  return executor.dispatch(
    scenarios: [scenario],
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _testMapId,
      entityId: entityId,
    ),
    context: _context(state: state, onUpdate: onUpdate, messages: messages),
  );
}

ScenarioRuntimeExecutionContext _context({
  required GameState state,
  required void Function(GameState) onUpdate,
  List<String>? messages,
}) {
  return ScenarioRuntimeExecutionContext(
    gameState: state,
    onGameStateUpdated: onUpdate,
    openDialogue: (_, {startNode, runtimeSourceId}) => false,
    runScript: (_, {startNode, runtimeSourceId}) => false,
    showMessage: (message) => messages?.add(message),
  );
}

GameState _availableState() {
  return createNewGameState(startMapId: _testMapId).copyWith(
    storyFlags: const StoryFlags(
      activeFlags: {_testOptionalQuestAvailableFact},
    ),
  );
}

GameState _startedState() {
  return _availableState().copyWith(
    storyFlags: const StoryFlags(
      activeFlags: {
        _testOptionalQuestAvailableFact,
        _testSideQuestStartedFact,
      },
    ),
    progression: const PlayerProgression(
      completedStepIds: [_testStepSideQuestStarted],
    ),
  );
}

GameState _objectiveDoneState() {
  return _startedState().copyWith(
    storyFlags: const StoryFlags(
      activeFlags: {
        _testOptionalQuestAvailableFact,
        _testSideQuestStartedFact,
        _testObjectiveDoneFact,
      },
    ),
    progression: const PlayerProgression(
      completedStepIds: [
        _testStepSideQuestStarted,
        _testStepSideQuestObjectiveDone,
      ],
    ),
  );
}

GameState _completedState() {
  return _objectiveDoneState().copyWith(
    storyFlags: const StoryFlags(
      activeFlags: {
        _testOptionalQuestAvailableFact,
        _testSideQuestStartedFact,
        _testObjectiveDoneFact,
        _testSideQuestCompletedFact,
      },
    ),
    progression: const PlayerProgression(
      completedStepIds: [
        _testStepSideQuestStarted,
        _testStepSideQuestObjectiveDone,
        _testStepSideQuestCompleted,
      ],
    ),
  );
}

GameState _runFullSideQuest(ScenarioRuntimeExecutor executor) {
  var state = _availableState();
  _dispatch(
    executor,
    scenario: _startQuestScenario(),
    entityId: _testOptionalQuestGiverId,
    state: state,
    onUpdate: (next) => state = next,
  );
  _dispatch(
    executor,
    scenario: _objectiveScenario(),
    entityId: _testOptionalObjectiveEntityId,
    state: state,
    onUpdate: (next) => state = next,
  );
  _dispatch(
    executor,
    scenario: _completeQuestScenario(),
    entityId: _testOptionalRewardEntityId,
    state: state,
    onUpdate: (next) => state = next,
  );
  return state;
}

ScenarioAsset _startQuestScenario() {
  return const ScenarioAsset(
    id: _testSideQuestStartSceneId,
    name: 'Test Side Quest Start Scene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'test_start',
    activationCondition: ScriptCondition(
      type: ScriptConditionType.allOf,
      children: [
        ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: {
            ScriptConditionParams.flagName: _testOptionalQuestAvailableFact,
          },
        ),
        ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: {ScriptConditionParams.flagName: _testSideQuestCompletedFact},
        ),
      ],
    ),
    nodes: [
      ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      ScenarioNode(
        id: 'test_source_optional_quest_giver',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testOptionalQuestGiverId,
        ),
      ),
      ScenarioNode(
        id: 'test_set_side_quest_started',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testSideQuestStartedFact),
      ),
      ScenarioNode(
        id: 'test_complete_side_quest_started_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: {'stepId': _testStepSideQuestStarted},
        ),
      ),
      ScenarioNode(id: 'test_start_scene_end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(
        id: 'test_edge_start_source_to_set_fact',
        fromNodeId: 'test_source_optional_quest_giver',
        toNodeId: 'test_set_side_quest_started',
      ),
      ScenarioEdge(
        id: 'test_edge_start_fact_to_step',
        fromNodeId: 'test_set_side_quest_started',
        toNodeId: 'test_complete_side_quest_started_step',
      ),
      ScenarioEdge(
        id: 'test_edge_start_step_to_end',
        fromNodeId: 'test_complete_side_quest_started_step',
        toNodeId: 'test_start_scene_end',
      ),
    ],
  );
}

ScenarioAsset _objectiveScenario() {
  return const ScenarioAsset(
    id: _testSideQuestObjectiveSceneId,
    name: 'Test Side Quest Objective Scene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'test_start',
    activationCondition: ScriptCondition(
      type: ScriptConditionType.allOf,
      children: [
        ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: {ScriptConditionParams.flagName: _testSideQuestStartedFact},
        ),
        ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: {ScriptConditionParams.flagName: _testSideQuestCompletedFact},
        ),
      ],
    ),
    nodes: [
      ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      ScenarioNode(
        id: 'test_source_optional_objective',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testOptionalObjectiveEntityId,
        ),
      ),
      ScenarioNode(
        id: 'test_complete_objective_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: {'stepId': _testStepSideQuestObjectiveDone},
        ),
      ),
      ScenarioNode(
        id: 'test_set_objective_done_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testObjectiveDoneFact),
      ),
      ScenarioNode(id: 'test_objective_scene_end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(
        id: 'test_edge_objective_source_to_step',
        fromNodeId: 'test_source_optional_objective',
        toNodeId: 'test_complete_objective_step',
      ),
      ScenarioEdge(
        id: 'test_edge_objective_step_to_fact',
        fromNodeId: 'test_complete_objective_step',
        toNodeId: 'test_set_objective_done_fact',
      ),
      ScenarioEdge(
        id: 'test_edge_objective_fact_to_end',
        fromNodeId: 'test_set_objective_done_fact',
        toNodeId: 'test_objective_scene_end',
      ),
    ],
  );
}

ScenarioAsset _completeQuestScenario() {
  return const ScenarioAsset(
    id: _testSideQuestCompleteSceneId,
    name: 'Test Side Quest Complete Scene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'test_start',
    activationCondition: ScriptCondition(
      type: ScriptConditionType.flagIsSet,
      params: {ScriptConditionParams.flagName: _testSideQuestStartedFact},
    ),
    nodes: [
      ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      ScenarioNode(
        id: 'test_source_optional_reward',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testOptionalRewardEntityId,
        ),
      ),
      ScenarioNode(
        id: 'test_objective_done_condition',
        type: ScenarioNodeType.condition,
        payload: ScenarioNodePayload(
          condition: ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: _testObjectiveDoneFact},
          ),
        ),
      ),
      ScenarioNode(
        id: 'test_give_optional_reward_item',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionGiveItem,
          params: {'itemId': _testItemReward, 'quantity': '1'},
        ),
      ),
      ScenarioNode(
        id: 'test_set_side_quest_completed',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testSideQuestCompletedFact),
      ),
      ScenarioNode(
        id: 'test_complete_side_quest_completed_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: {'stepId': _testStepSideQuestCompleted},
        ),
      ),
      ScenarioNode(
        id: 'test_final_blocked_message',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionShowMessage,
          message: _testDialogueBeforeQuest,
        ),
      ),
      ScenarioNode(id: 'test_complete_scene_end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(
        id: 'test_edge_complete_source_to_condition',
        fromNodeId: 'test_source_optional_reward',
        toNodeId: 'test_objective_done_condition',
      ),
      ScenarioEdge(
        id: 'test_edge_complete_condition_to_reward',
        fromNodeId: 'test_objective_done_condition',
        toNodeId: 'test_give_optional_reward_item',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      ScenarioEdge(
        id: 'test_edge_complete_condition_to_blocked',
        fromNodeId: 'test_objective_done_condition',
        toNodeId: 'test_final_blocked_message',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      ScenarioEdge(
        id: 'test_edge_complete_reward_to_fact',
        fromNodeId: 'test_give_optional_reward_item',
        toNodeId: 'test_set_side_quest_completed',
      ),
      ScenarioEdge(
        id: 'test_edge_complete_fact_to_step',
        fromNodeId: 'test_set_side_quest_completed',
        toNodeId: 'test_complete_side_quest_completed_step',
      ),
      ScenarioEdge(
        id: 'test_edge_complete_step_to_end',
        fromNodeId: 'test_complete_side_quest_completed_step',
        toNodeId: 'test_complete_scene_end',
      ),
    ],
  );
}

MapEntity _availableOnlyQuestGiver() {
  return const MapEntity(
    id: _testOptionalQuestGiverId,
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Optional Quest Giver',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.visibleWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: _testOptionalQuestAvailableFact,
        ),
      ),
    ),
  );
}

MapEntity _questGiverDialogueNpc() {
  return const MapEntity(
    id: _testOptionalQuestGiverId,
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Optional Quest Giver',
      dialogue: DialogueRef(dialogueId: _testDialogueBeforeQuest),
      conditionalDialogues: [
        MapEntityConditionalDialogue(
          when: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: _testSideQuestCompletedFact,
          ),
          dialogue: DialogueRef(dialogueId: _testDialogueAfterQuest),
        ),
      ],
    ),
  );
}

MapEntity _objectiveProxyNpc() {
  return const MapEntity(
    id: _testOptionalObjectiveEntityId,
    kind: MapEntityKind.npc,
    pos: GridPos(x: 2, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Optional Objective',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: _testSideQuestCompletedFact,
        ),
      ),
    ),
  );
}

MapEntityRuntimePredicateEvaluator _evaluator(GameState state) {
  return MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
  );
}
