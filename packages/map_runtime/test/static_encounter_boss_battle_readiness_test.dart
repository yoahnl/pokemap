import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

const String _testMapId = 'test_map';
const String _testStaticEncounterEntityId = 'test_static_encounter_entity';
const String _testStaticBossNpcId = 'test_static_boss_npc';
const String _testStaticBattleId = 'test_static_battle';
const String _testStaticTrainerId = 'test_static_trainer';
const String _testStaticEncounterSceneId = 'test_static_encounter_scene';
const String _testStaticVictoryFact = 'test_static_victory_fact';
const String _testStaticDefeatFact = 'test_static_defeat_fact';
const String _testStaticFleeFact = 'test_static_flee_fact';
const String _testStaticCapturedFact = 'test_static_captured_fact';
const String _testStaticDoneStep = 'test_step_static_encounter_done';
const String _testDialogueBeforeStatic = 'test_dialogue_before_static';
const String _testDialogueAfterStatic = 'test_dialogue_after_static';

void main() {
  group('Static Encounter / Boss Battle authoring readiness', () {
    const executor = ScenarioRuntimeExecutor();

    test('static boss proxy is available before resolution', () {
      final before = createNewGameState(startMapId: _testMapId);
      final after = _withFlag(before, _testStaticVictoryFact);
      final proxy = _staticBossProxy();

      expect(_evaluator(before).isNpcPresentOnMap(proxy), isTrue);
      expect(_evaluator(after).isNpcPresentOnMap(proxy), isFalse);
    });

    test('entity interaction launches trainer-like boss battle effect', () {
      var state = createNewGameState(startMapId: _testMapId);

      final result = _dispatchStaticBoss(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(result.stopNodeId, 'test_start_static_battle');
    });

    test('battle effect carries generic battle trainer and npc ids', () {
      var state = createNewGameState(startMapId: _testMapId);

      final result = _dispatchStaticBoss(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.effect.battleId, _testStaticBattleId);
      expect(result.effect.trainerId, _testStaticTrainerId);
      expect(result.effect.npcEntityId, _testStaticBossNpcId);
      expect(result.scenarioId, _testStaticEncounterSceneId);
      expect(result.sourceNodeId, 'test_source_static_interact');
    });

    test('battle node suspends graph before post-battle facts', () {
      var state = createNewGameState(startMapId: _testMapId);

      _dispatchStaticBoss(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(state.storyFlags.activeFlags,
          isNot(contains(_testStaticVictoryFact)));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_testStaticDefeatFact)));
      expect(state.progression.completedStepIds, isEmpty);
    });

    test('victory outcome completes static encounter path', () {
      var state = _withOutcome(
        createNewGameState(startMapId: _testMapId),
        kBattleOutcomeSuffixVictory,
      );

      final result = _continueAfterBattle(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains(_testStaticVictoryFact));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_testStaticDefeatFact)));
      expect(state.progression.completedStepIds, contains(_testStaticDoneStep));
    });

    test('defeat outcome completes defeat branch without resolution step', () {
      var state = _withOutcome(
        createNewGameState(startMapId: _testMapId),
        kBattleOutcomeSuffixDefeat,
      );

      final result = _continueAfterBattle(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains(_testStaticDefeatFact));
      expect(state.storyFlags.activeFlags,
          isNot(contains(_testStaticVictoryFact)));
      expect(state.progression.completedStepIds, isEmpty);
    });

    test('flee outcome can branch when supplied by battle outcome convention',
        () {
      var state = _withOutcome(
        createNewGameState(startMapId: _testMapId),
        kBattleOutcomeSuffixFlee,
      );

      final result = _continueAfterBattle(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains(_testStaticFleeFact));
      expect(state.progression.completedStepIds, isEmpty);
    });

    test('captured outcome can complete one-shot path when supplied', () {
      var state = _withOutcome(
        createNewGameState(startMapId: _testMapId),
        kBattleOutcomeSuffixCaptured,
      );

      final result = _continueAfterBattle(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains(_testStaticCapturedFact));
      expect(state.progression.completedStepIds, contains(_testStaticDoneStep));
    });

    test('one-shot condition prevents replay after victory or capture', () {
      final victoryState = _withFlag(
        createNewGameState(startMapId: _testMapId),
        _testStaticVictoryFact,
      );
      final capturedState = _withFlag(
        createNewGameState(startMapId: _testMapId),
        _testStaticCapturedFact,
      );

      final victoryReplay = _dispatchStaticBoss(
        executor,
        state: victoryState,
        onUpdate: (_) {},
      );
      final capturedReplay = _dispatchStaticBoss(
        executor,
        state: capturedState,
        onUpdate: (_) {},
      );

      expect(victoryReplay.status,
          ScenarioRuntimeExecutionStatus.noMatchingSource);
      expect(capturedReplay.status,
          ScenarioRuntimeExecutionStatus.noMatchingSource);
    });

    test('save load preserves static encounter victory resolution', () {
      var state = _withOutcome(
        createNewGameState(startMapId: _testMapId),
        kBattleOutcomeSuffixVictory,
      );

      _continueAfterBattle(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(saveDataFromGameState(state)),
      );

      expect(
        reloaded.storyFlags.activeFlags,
        contains(_outcomeFlag(kBattleOutcomeSuffixVictory)),
      );
      expect(reloaded.storyFlags.activeFlags, contains(_testStaticVictoryFact));
      expect(
        reloaded.progression.completedStepIds,
        contains(_testStaticDoneStep),
      );
    });

    test('world rule hides encounter proxy after post-battle fact', () {
      final proxy = _staticBossProxy();
      final before = createNewGameState(startMapId: _testMapId);
      final after = _withFlag(before, _testStaticVictoryFact);

      expect(_evaluator(before).isNpcPresentOnMap(proxy), isTrue);
      expect(_evaluator(after).isNpcPresentOnMap(proxy), isFalse);
    });

    test('world rule changes post-battle dialogue after victory', () {
      final npc = _staticBossDialogueProxy();
      final before = createNewGameState(startMapId: _testMapId);
      final after = _withFlag(before, _testStaticVictoryFact);

      expect(
        _evaluator(before).resolveNpcDialogue(npc.npc!)?.dialogueId,
        _testDialogueBeforeStatic,
      );
      expect(
        _evaluator(after).resolveNpcDialogue(npc.npc!)?.dialogueId,
        _testDialogueAfterStatic,
      );
    });

    test('fixtures use only generic test ids', () {
      final scenario = _staticBossScenario();
      final ids = <String>[
        _testMapId,
        _testStaticEncounterEntityId,
        _testStaticBossNpcId,
        _testStaticBattleId,
        _testStaticTrainerId,
        _testStaticEncounterSceneId,
        _testStaticVictoryFact,
        _testStaticDefeatFact,
        _testStaticFleeFact,
        _testStaticCapturedFact,
        _testStaticDoneStep,
        _testDialogueBeforeStatic,
        _testDialogueAfterStatic,
        scenario.id,
        for (final node in scenario.nodes) node.id,
        for (final edge in scenario.edges) edge.id,
      ];

      expect(ids, everyElement(startsWith('test_')));
    });
  });
}

ScenarioRuntimeExecutionResult _dispatchStaticBoss(
  ScenarioRuntimeExecutor executor, {
  required GameState state,
  required void Function(GameState) onUpdate,
  List<String>? messages,
}) {
  return executor.dispatch(
    scenarios: [_staticBossScenario()],
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _testMapId,
      entityId: _testStaticEncounterEntityId,
    ),
    context: _context(state: state, onUpdate: onUpdate, messages: messages),
  );
}

ScenarioRuntimeExecutionResult _continueAfterBattle(
  ScenarioRuntimeExecutor executor, {
  required GameState state,
  required void Function(GameState) onUpdate,
  List<String>? messages,
}) {
  return executor.dispatchContinuation(
    scenarios: [_staticBossScenario()],
    scenarioId: _testStaticEncounterSceneId,
    sourceNodeId: 'test_source_static_interact',
    resumeAfterNodeId: 'test_start_static_battle',
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

GameState _withFlag(GameState state, String flagName) {
  return state.copyWith(
    storyFlags: StoryFlags(
      activeFlags: <String>{...state.storyFlags.activeFlags, flagName},
    ),
  );
}

GameState _withOutcome(GameState state, String outcomeSuffix) {
  return _withFlag(state, _outcomeFlag(outcomeSuffix));
}

String _outcomeFlag(String outcomeSuffix) {
  return scenarioBattleOutcomeFlagName(_testStaticBattleId, outcomeSuffix);
}

ScenarioAsset _staticBossScenario() {
  return ScenarioAsset(
    id: _testStaticEncounterSceneId,
    name: 'Test Static Encounter Scene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'test_start',
    activationCondition: const ScriptCondition(
      type: ScriptConditionType.allOf,
      children: [
        ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: {ScriptConditionParams.flagName: _testStaticVictoryFact},
        ),
        ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: {ScriptConditionParams.flagName: _testStaticCapturedFact},
        ),
      ],
    ),
    nodes: [
      const ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      const ScenarioNode(
        id: 'test_source_static_interact',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testStaticEncounterEntityId,
        ),
      ),
      const ScenarioNode(
        id: 'test_start_static_battle',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionStartTrainerBattle,
          params: {'battleId': _testStaticBattleId},
        ),
        binding: ScenarioNodeBinding(
          trainerId: _testStaticTrainerId,
          entityId: _testStaticBossNpcId,
        ),
      ),
      _flagConditionNode(
        nodeId: 'test_condition_static_victory',
        flagName: _outcomeFlag(kBattleOutcomeSuffixVictory),
      ),
      const ScenarioNode(
        id: 'test_set_static_victory_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testStaticVictoryFact),
      ),
      _flagConditionNode(
        nodeId: 'test_condition_static_defeat',
        flagName: _outcomeFlag(kBattleOutcomeSuffixDefeat),
      ),
      const ScenarioNode(
        id: 'test_set_static_defeat_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testStaticDefeatFact),
      ),
      _flagConditionNode(
        nodeId: 'test_condition_static_flee',
        flagName: _outcomeFlag(kBattleOutcomeSuffixFlee),
      ),
      const ScenarioNode(
        id: 'test_set_static_flee_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testStaticFleeFact),
      ),
      _flagConditionNode(
        nodeId: 'test_condition_static_captured',
        flagName: _outcomeFlag(kBattleOutcomeSuffixCaptured),
      ),
      const ScenarioNode(
        id: 'test_set_static_captured_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testStaticCapturedFact),
      ),
      const ScenarioNode(
        id: 'test_complete_static_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: {'stepId': _testStaticDoneStep},
        ),
      ),
      const ScenarioNode(
        id: 'test_static_unresolved_message',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionShowMessage,
          message: _testDialogueBeforeStatic,
        ),
      ),
      const ScenarioNode(
          id: 'test_end_static_done', type: ScenarioNodeType.end),
      const ScenarioNode(
          id: 'test_end_static_defeat', type: ScenarioNodeType.end),
      const ScenarioNode(
          id: 'test_end_static_flee', type: ScenarioNodeType.end),
    ],
    edges: [
      _edge(
        'test_edge_static_source_battle',
        'test_source_static_interact',
        'test_start_static_battle',
      ),
      _edge(
        'test_edge_static_battle_victory_condition',
        'test_start_static_battle',
        'test_condition_static_victory',
      ),
      _edge(
        'test_edge_static_victory_true',
        'test_condition_static_victory',
        'test_set_static_victory_fact',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      _edge(
        'test_edge_static_victory_false',
        'test_condition_static_victory',
        'test_condition_static_defeat',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      _edge(
        'test_edge_static_victory_step',
        'test_set_static_victory_fact',
        'test_complete_static_step',
      ),
      _edge(
        'test_edge_static_defeat_true',
        'test_condition_static_defeat',
        'test_set_static_defeat_fact',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      _edge(
        'test_edge_static_defeat_false',
        'test_condition_static_defeat',
        'test_condition_static_flee',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      _edge(
        'test_edge_static_defeat_end',
        'test_set_static_defeat_fact',
        'test_end_static_defeat',
      ),
      _edge(
        'test_edge_static_flee_true',
        'test_condition_static_flee',
        'test_set_static_flee_fact',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      _edge(
        'test_edge_static_flee_false',
        'test_condition_static_flee',
        'test_condition_static_captured',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      _edge(
        'test_edge_static_flee_end',
        'test_set_static_flee_fact',
        'test_end_static_flee',
      ),
      _edge(
        'test_edge_static_captured_true',
        'test_condition_static_captured',
        'test_set_static_captured_fact',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      _edge(
        'test_edge_static_captured_false',
        'test_condition_static_captured',
        'test_static_unresolved_message',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      _edge(
        'test_edge_static_captured_step',
        'test_set_static_captured_fact',
        'test_complete_static_step',
      ),
      _edge(
        'test_edge_static_step_end',
        'test_complete_static_step',
        'test_end_static_done',
      ),
    ],
  );
}

ScenarioNode _flagConditionNode({
  required String nodeId,
  required String flagName,
}) {
  return ScenarioNode(
    id: nodeId,
    type: ScenarioNodeType.condition,
    payload: ScenarioNodePayload(
      condition: ScriptCondition(
        type: ScriptConditionType.flagIsSet,
        params: {ScriptConditionParams.flagName: flagName},
      ),
    ),
  );
}

ScenarioEdge _edge(
  String id,
  String from,
  String to, {
  ScenarioEdgeKind kind = ScenarioEdgeKind.next,
}) {
  return ScenarioEdge(id: id, fromNodeId: from, toNodeId: to, kind: kind);
}

MapEntity _staticBossProxy() {
  return const MapEntity(
    id: _testStaticEncounterEntityId,
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Static Boss',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: _testStaticVictoryFact,
        ),
      ),
    ),
  );
}

MapEntity _staticBossDialogueProxy() {
  return const MapEntity(
    id: _testStaticBossNpcId,
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Static Boss Dialogue',
      dialogue: DialogueRef(dialogueId: _testDialogueBeforeStatic),
      conditionalDialogues: [
        MapEntityConditionalDialogue(
          when: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: _testStaticVictoryFact,
          ),
          dialogue: DialogueRef(dialogueId: _testDialogueAfterStatic),
        ),
      ],
    ),
  );
}

MapEntityRuntimePredicateEvaluator _evaluator(GameState state) {
  return MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
  );
}
