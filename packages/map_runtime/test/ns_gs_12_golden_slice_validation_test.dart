import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

// ignore_for_file: prefer_const_constructors

/// NS-GS-12 — Editor-authored Golden Slice Validation
///
/// This test suite proves that the generic bricks added in NS-GS-05 through
/// NS-GS-11 can be composed into a single coherent Golden Slice flow:
///
///   new game → NPC interaction → scene → GivePokemon → completeStep
///   → save/load → world rule unlocks rival → outcome branch
///   → trainer battle → victory/defeat continuation → save/load
///
/// Level of proof: Level 2 — Application layer.
///   ScenarioRuntimeExecutor + MapEntityRuntimePredicateEvaluator
///   + GameStateMutations + save/load round-trip.
///
/// NOT Level 3 (Flame) or Level 4 (disk project). The test does NOT:
///   - instantiate PlayableMapGame,
///   - load a project.json from disk,
///   - render any Flame widget.
///
/// Frontier maintained:
///   Event = external trigger (entityInteract).
///   Scene = narrative orchestration (scenario graph).
///   Battle = gameplay resolution (victory/defeat via flag).
///   World Rule = passive projection (predicate evaluator).
///
/// All ids are generic test_*. No Selbrume ids.
/// This is a technical validation fixture, not final content.
void main() {
  const executor = ScenarioRuntimeExecutor();

  // ═══════════════════════════════════════════════════════════════════════════
  // Golden Slice Scenario Graphs (generic, non-Selbrume)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Scene 1: mentor NPC gives a pokemon and completes the starter step.
  ///
  /// Graph: source(entityInteract test_mentor_npc on test_start_map)
  ///   → givePokemon(test_starter_species, level 5)
  ///   → setFlag(test_given_starter_fact)
  ///   → completeStep(test_step_starter_received)
  ///   → setFlag(test_mission_started_fact)
  ///   → completeStep(test_step_mission_started)
  ///   → end
  ScenarioAsset mentorGivesPokemonScene() {
    return ScenarioAsset(
      id: 'test_scene_mentor_gives_pokemon',
      name: 'Mentor Gives Pokemon (Golden Slice)',
      entryNodeId: 'source_mentor',
      nodes: const <ScenarioNode>[
        ScenarioNode(
          id: 'source_mentor',
          type: ScenarioNodeType.reference,
          payload:
              ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
          binding: ScenarioNodeBinding(
            mapId: 'test_start_map',
            entityId: 'test_mentor_npc',
          ),
        ),
        ScenarioNode(
          id: 'give_pokemon',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionGivePokemon,
            params: <String, String>{
              'speciesId': 'test_starter_species',
              'level': '5',
              'knownMoveIds': 'tackle,growl',
            },
          ),
        ),
        ScenarioNode(
          id: 'set_starter_fact',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
          binding: ScenarioNodeBinding(flagName: 'test_given_starter_fact'),
        ),
        ScenarioNode(
          id: 'complete_starter_step',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionCompleteStep,
            params: <String, String>{'stepId': 'test_step_starter_received'},
          ),
        ),
        ScenarioNode(
          id: 'set_mission_fact',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
          binding: ScenarioNodeBinding(flagName: 'test_mission_started_fact'),
        ),
        ScenarioNode(
          id: 'complete_mission_step',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionCompleteStep,
            params: <String, String>{'stepId': 'test_step_mission_started'},
          ),
        ),
        ScenarioNode(id: 'end', type: ScenarioNodeType.end),
      ],
      edges: const <ScenarioEdge>[
        ScenarioEdge(
            id: 'e1', fromNodeId: 'source_mentor', toNodeId: 'give_pokemon'),
        ScenarioEdge(
            id: 'e2',
            fromNodeId: 'give_pokemon',
            toNodeId: 'set_starter_fact'),
        ScenarioEdge(
            id: 'e3',
            fromNodeId: 'set_starter_fact',
            toNodeId: 'complete_starter_step'),
        ScenarioEdge(
            id: 'e4',
            fromNodeId: 'complete_starter_step',
            toNodeId: 'set_mission_fact'),
        ScenarioEdge(
            id: 'e5',
            fromNodeId: 'set_mission_fact',
            toNodeId: 'complete_mission_step'),
        ScenarioEdge(
            id: 'e6',
            fromNodeId: 'complete_mission_step',
            toNodeId: 'end'),
      ],
    );
  }

  /// Scene 2: rival NPC dialogue that branches based on outcome.
  ///
  /// This proves the outcome→branch pathway. The dialogue opens and the
  /// scene emits outcome flags. Then a condition routes to the trainer
  /// battle scene.
  ///
  /// Graph: source(entityInteract test_rival_npc on test_port_map)
  ///   → dialogue(test_scene_rival_dialogue)
  ///   → emitOutcome(test_dialogue_outcome_confident)
  ///   → end_dialogue
  ScenarioAsset rivalDialogueScene() {
    return ScenarioAsset(
      id: 'test_scene_rival_dialogue',
      name: 'Rival Dialogue (Golden Slice)',
      entryNodeId: 'source_rival',
      nodes: const <ScenarioNode>[
        ScenarioNode(
          id: 'source_rival',
          type: ScenarioNodeType.reference,
          payload:
              ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
          binding: ScenarioNodeBinding(
            mapId: 'test_port_map',
            entityId: 'test_rival_npc',
          ),
        ),
        ScenarioNode(
          id: 'open_dialogue',
          type: ScenarioNodeType.dialogue,
          binding: ScenarioNodeBinding(
            dialogueId: 'test_scene_rival_dialogue',
          ),
        ),
        ScenarioNode(
          id: 'emit_outcome',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionEmitOutcome,
          ),
          binding: ScenarioNodeBinding(
            outcomeId: 'test_dialogue_outcome_confident',
          ),
        ),
        ScenarioNode(id: 'end_dialogue', type: ScenarioNodeType.end),
      ],
      edges: const <ScenarioEdge>[
        ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_rival',
            toNodeId: 'open_dialogue'),
        ScenarioEdge(
            id: 'e2',
            fromNodeId: 'open_dialogue',
            toNodeId: 'emit_outcome'),
        ScenarioEdge(
            id: 'e3',
            fromNodeId: 'emit_outcome',
            toNodeId: 'end_dialogue'),
      ],
    );
  }

  /// Scene 3: rival battle with victory/defeat branches.
  ///
  /// This is the critical Golden Slice battle scene:
  ///   source(outcome received) → condition(confident outcome?)
  ///   → true: startTrainerBattle → condition(victory?)
  ///       → true: setFlag(victory) + completeStep(rival_battle_done) → end
  ///       → false: setFlag(defeat) + completeStep(rival_battle_done) → end
  ///   → false: end_skip (no battle if not confident)
  ScenarioAsset rivalBattleScene() {
    return ScenarioAsset(
      id: 'test_scene_rival_battle',
      name: 'Rival Battle (Golden Slice)',
      entryNodeId: 'source_outcome',
      nodes: const <ScenarioNode>[
        ScenarioNode(
          id: 'source_outcome',
          type: ScenarioNodeType.reference,
          payload:
              ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
          binding: ScenarioNodeBinding(
            outcomeId: 'test_dialogue_outcome_confident',
          ),
        ),
        // Condition: did the dialogue emit the confident outcome?
        ScenarioNode(
          id: 'condition_confident',
          type: ScenarioNodeType.condition,
          payload: ScenarioNodePayload(
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: <String, String>{
                ScriptConditionParams.flagName:
                    'scenario.outcome.test_dialogue_outcome_confident',
              },
            ),
          ),
        ),
        // Battle node
        ScenarioNode(
          id: 'battle_node',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionStartTrainerBattle,
            params: <String, String>{'battleId': 'test_battle'},
          ),
          binding: ScenarioNodeBinding(
            trainerId: 'test_trainer',
            entityId: 'test_rival_npc',
          ),
        ),
        // Condition: victory?
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
          id: 'set_victory_fact',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
          binding:
              ScenarioNodeBinding(flagName: 'test_battle_victory_fact'),
        ),
        ScenarioNode(
          id: 'complete_battle_step_victory',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionCompleteStep,
            params: <String, String>{
              'stepId': 'test_step_rival_battle_done',
            },
          ),
        ),
        ScenarioNode(id: 'end_victory', type: ScenarioNodeType.end),
        // Defeat path
        ScenarioNode(
          id: 'set_defeat_fact',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
          binding:
              ScenarioNodeBinding(flagName: 'test_battle_defeat_fact'),
        ),
        ScenarioNode(
          id: 'complete_battle_step_defeat',
          type: ScenarioNodeType.action,
          payload: ScenarioNodePayload(
            actionKind: kScenarioActionCompleteStep,
            params: <String, String>{
              'stepId': 'test_step_rival_battle_done',
            },
          ),
        ),
        ScenarioNode(id: 'end_defeat', type: ScenarioNodeType.end),
        // Skip path (not confident)
        ScenarioNode(id: 'end_skip', type: ScenarioNodeType.end),
      ],
      edges: const <ScenarioEdge>[
        ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_outcome',
            toNodeId: 'condition_confident'),
        ScenarioEdge(
          id: 'e2',
          fromNodeId: 'condition_confident',
          toNodeId: 'battle_node',
          kind: ScenarioEdgeKind.trueBranch,
        ),
        ScenarioEdge(
          id: 'e3',
          fromNodeId: 'condition_confident',
          toNodeId: 'end_skip',
          kind: ScenarioEdgeKind.falseBranch,
        ),
        ScenarioEdge(
            id: 'e4',
            fromNodeId: 'battle_node',
            toNodeId: 'condition_victory'),
        // Victory
        ScenarioEdge(
          id: 'e5',
          fromNodeId: 'condition_victory',
          toNodeId: 'set_victory_fact',
          kind: ScenarioEdgeKind.trueBranch,
        ),
        ScenarioEdge(
            id: 'e6',
            fromNodeId: 'set_victory_fact',
            toNodeId: 'complete_battle_step_victory'),
        ScenarioEdge(
            id: 'e7',
            fromNodeId: 'complete_battle_step_victory',
            toNodeId: 'end_victory'),
        // Defeat
        ScenarioEdge(
          id: 'e8',
          fromNodeId: 'condition_victory',
          toNodeId: 'set_defeat_fact',
          kind: ScenarioEdgeKind.falseBranch,
        ),
        ScenarioEdge(
            id: 'e9',
            fromNodeId: 'set_defeat_fact',
            toNodeId: 'complete_battle_step_defeat'),
        ScenarioEdge(
            id: 'e10',
            fromNodeId: 'complete_battle_step_defeat',
            toNodeId: 'end_defeat'),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // World Rule entities (generic test NPCs with visibility predicates)
  // ─────────────────────────────────────────────────────────────────────────

  /// Rival NPC: visible only when both starter received AND mission started.
  ///
  /// This tests the World Rule: rival is hidden until facts are set,
  /// then becomes present and interactable on test_port_map.
  MapEntity rivalEntity() {
    return MapEntity(
      id: 'test_rival_npc',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 10, y: 10),
      npc: MapEntityNpcData(
        displayName: 'Test Rival',
        dialogue:
            const DialogueRef(dialogueId: 'test_rival_default_dialogue'),
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'test_mission_started_fact',
          ),
        ),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.stepCompleted,
              refId: 'test_step_rival_battle_done',
            ),
            dialogue:
                DialogueRef(dialogueId: 'test_rival_post_battle_dialogue'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  MapEntityRuntimePredicateEvaluator evaluator(GameState state) {
    return MapEntityRuntimePredicateEvaluator(
      gameState: state,
      chapterIndex: GlobalStoryChapterStepIndex(
        chapterIdToStepIds: const {},
      ),
    );
  }

  ScenarioRuntimeExecutionContext buildContext({
    required GameState gameState,
    required void Function(GameState) onGameStateUpdated,
    void Function(String)? onDialogueOpened,
  }) {
    return ScenarioRuntimeExecutionContext(
      gameState: gameState,
      onGameStateUpdated: onGameStateUpdated,
      openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
        onDialogueOpened?.call(dialogueId);
        return true;
      },
      runScript: (scriptId, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 1: New game starts with empty party and expected start map
  // ═══════════════════════════════════════════════════════════════════════════

  group('1. New game + empty party', () {
    test('createNewGameState starts with empty party on test_start_map', () {
      final state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
        playerName: 'test_player',
      );

      expect(state.party.members, isEmpty);
      expect(state.currentMapId, 'test_start_map');
      expect(state.saveId, 'test_save');
      expect(state.trainerProfile.name, 'test_player');
      expect(state.storyFlags.activeFlags, isEmpty);
      expect(state.progression.completedStepIds, isEmpty);
      // Bag starts empty (no items in progression).
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 2: Mentor scene gives pokemon and completes starter step
  // ═══════════════════════════════════════════════════════════════════════════

  group('2. Mentor scene → GivePokemon + completeStep', () {
    test('interacting with mentor NPC gives pokemon and sets facts/steps', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );

      final result = executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      // Scene completed successfully.
      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);

      // Pokemon given.
      expect(state.party.members, hasLength(1));
      expect(state.party.members.first.speciesId, 'test_starter_species');
      expect(state.party.members.first.level, 5);

      // Facts set.
      expect(
          state.storyFlags.activeFlags, contains('test_given_starter_fact'));
      expect(
          state.storyFlags.activeFlags, contains('test_mission_started_fact'));

      // Steps completed.
      expect(state.progression.completedStepIds,
          contains('test_step_starter_received'));
      expect(state.progression.completedStepIds,
          contains('test_step_mission_started'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 3: Save/load preserves given pokemon and starter progression
  // ═══════════════════════════════════════════════════════════════════════════

  group('3. Save/load preserves pokemon + progression', () {
    test('save/load round-trip preserves party, facts, and steps', () {
      // Build state after mentor scene.
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      // Save and reload.
      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      // Pokemon preserved.
      expect(reloaded.party.members, hasLength(1));
      expect(reloaded.party.members.first.speciesId, 'test_starter_species');
      expect(reloaded.party.members.first.level, 5);

      // Facts preserved.
      expect(reloaded.storyFlags.activeFlags,
          contains('test_given_starter_fact'));
      expect(reloaded.storyFlags.activeFlags,
          contains('test_mission_started_fact'));

      // Steps preserved.
      expect(reloaded.progression.completedStepIds,
          contains('test_step_starter_received'));
      expect(reloaded.progression.completedStepIds,
          contains('test_step_mission_started'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 4: World rule unlocks rival NPC after starter + mission facts
  // ═══════════════════════════════════════════════════════════════════════════

  group('4. World Rule unlocks rival NPC', () {
    test('rival is hidden before mentor scene', () {
      final state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );

      final ev = evaluator(state);
      expect(ev.isNpcPresentOnMap(rivalEntity()), isFalse);
    });

    test('rival is visible after starter + mission facts', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      final ev = evaluator(state);
      expect(ev.isNpcPresentOnMap(rivalEntity()), isTrue);
    });

    test('rival visibility survives save/load', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      final ev = evaluator(reloaded);
      expect(ev.isNpcPresentOnMap(rivalEntity()), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 5: Dialogue outcome branches scene toward trainer battle
  // ═══════════════════════════════════════════════════════════════════════════

  group('5. Outcome → Branch', () {
    test('rival dialogue emits outcome and sets outcome flag', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      // First: mentor scene runs.
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      // Then: rival dialogue runs (opens dialogue and emits outcome).
      final openedDialogues = <String>[];
      final dialogueResult = executor.dispatch(
        scenarios: [rivalDialogueScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_port_map',
          entityId: 'test_rival_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          onDialogueOpened: openedDialogues.add,
        ),
      );

      // Dialogue was opened.
      expect(dialogueResult.status,
          ScenarioRuntimeExecutionStatus.executedEffect);
      expect(openedDialogues, contains('test_scene_rival_dialogue'));

      // After dialogue closes, continuation runs emitOutcome.
      final continuationResult = executor.dispatchContinuation(
        scenarios: [rivalDialogueScene()],
        scenarioId: 'test_scene_rival_dialogue',
        sourceNodeId: 'source_rival',
        resumeAfterNodeId: 'open_dialogue',
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      expect(
          continuationResult.status, ScenarioRuntimeExecutionStatus.reachedEnd);

      // Outcome flag was set.
      expect(state.storyFlags.activeFlags,
          contains('scenario.outcome.test_dialogue_outcome_confident'));
    });

    test('outcome flag triggers battle scene via sourceOutcome', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      // Setup: mentor scene + outcome flag already set.
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );
      // Set outcome flag as if dialogue completed.
      state = state.copyWith(
        storyFlags: state.storyFlags.copyWith(
          activeFlags: <String>{
            ...state.storyFlags.activeFlags,
            'scenario.outcome.test_dialogue_outcome_confident',
          },
        ),
      );

      // Battle scene triggered by outcome.
      final battleResult = executor.dispatch(
        scenarios: [rivalBattleScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'test_dialogue_outcome_confident',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      // Battle effect emitted (graph suspended at battle node).
      expect(
          battleResult.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(battleResult.effect.type, ScenarioRuntimeEffectType.battle);
      expect(battleResult.effect.battleId, 'test_battle');
      expect(battleResult.effect.trainerId, 'test_trainer');
      expect(battleResult.effect.npcEntityId, 'test_rival_npc');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 6: Battle effect has correct battleId, trainerId, npcEntityId
  // ═══════════════════════════════════════════════════════════════════════════

  group('6. Trainer Battle → Battle Effect', () {
    test('battle effect contains battleId trainerId npcEntityId', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      state = state.copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'scenario.outcome.test_dialogue_outcome_confident',
        }),
      );

      final result = executor.dispatch(
        scenarios: [rivalBattleScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'test_dialogue_outcome_confident',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      expect(result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(result.effect.battleId, 'test_battle');
      expect(result.effect.trainerId, 'test_trainer');
      expect(result.effect.npcEntityId, 'test_rival_npc');
      expect(result.scenarioId, 'test_scene_rival_battle');
      expect(result.stopNodeId, 'battle_node');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 7: Victory outcome continues scenario and completes victory path
  // ═══════════════════════════════════════════════════════════════════════════

  group('7. Victory continuation', () {
    test('victory flag → victory path → fact + step completed', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      state = state.copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'scenario.outcome.test_dialogue_outcome_confident',
          'battle:test_battle:victory',
        }),
      );

      final result = executor.dispatchContinuation(
        scenarios: [rivalBattleScene()],
        scenarioId: 'test_scene_rival_battle',
        sourceNodeId: 'source_outcome',
        resumeAfterNodeId: 'battle_node',
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
          state.storyFlags.activeFlags, contains('test_battle_victory_fact'));
      expect(state.storyFlags.activeFlags,
          isNot(contains('test_battle_defeat_fact')));
      expect(state.progression.completedStepIds,
          contains('test_step_rival_battle_done'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 8: Defeat outcome continues scenario and completes defeat path
  // ═══════════════════════════════════════════════════════════════════════════

  group('8. Defeat continuation', () {
    test('defeat flag → defeat path → fact + step completed', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      state = state.copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'scenario.outcome.test_dialogue_outcome_confident',
          'battle:test_battle:defeat',
        }),
      );

      final result = executor.dispatchContinuation(
        scenarios: [rivalBattleScene()],
        scenarioId: 'test_scene_rival_battle',
        sourceNodeId: 'source_outcome',
        resumeAfterNodeId: 'battle_node',
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
          state.storyFlags.activeFlags, contains('test_battle_defeat_fact'));
      expect(state.storyFlags.activeFlags,
          isNot(contains('test_battle_victory_fact')));
      expect(state.progression.completedStepIds,
          contains('test_step_rival_battle_done'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 9: Save/load preserves final battle facts and completed steps
  // ═══════════════════════════════════════════════════════════════════════════

  group('9. Save/load preserves final state', () {
    test('full golden slice state survives save/load (victory path)', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      // 1. Mentor gives pokemon.
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );
      // 2. Set outcome flag.
      state = state.copyWith(
        storyFlags: state.storyFlags.copyWith(
          activeFlags: <String>{
            ...state.storyFlags.activeFlags,
            'scenario.outcome.test_dialogue_outcome_confident',
            'battle:test_battle:victory',
          },
        ),
      );
      // 3. Victory continuation.
      executor.dispatchContinuation(
        scenarios: [rivalBattleScene()],
        scenarioId: 'test_scene_rival_battle',
        sourceNodeId: 'source_outcome',
        resumeAfterNodeId: 'battle_node',
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      // Save and reload.
      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      // Pokemon preserved.
      expect(reloaded.party.members, hasLength(1));
      expect(reloaded.party.members.first.speciesId, 'test_starter_species');

      // All facts preserved.
      expect(reloaded.storyFlags.activeFlags,
          contains('test_given_starter_fact'));
      expect(reloaded.storyFlags.activeFlags,
          contains('test_mission_started_fact'));
      expect(reloaded.storyFlags.activeFlags,
          contains('test_battle_victory_fact'));
      expect(reloaded.storyFlags.activeFlags,
          contains('battle:test_battle:victory'));
      expect(reloaded.storyFlags.activeFlags,
          contains('scenario.outcome.test_dialogue_outcome_confident'));

      // All steps preserved.
      expect(reloaded.progression.completedStepIds,
          contains('test_step_starter_received'));
      expect(reloaded.progression.completedStepIds,
          contains('test_step_mission_started'));
      expect(reloaded.progression.completedStepIds,
          contains('test_step_rival_battle_done'));
    });

    test('world rule still resolves correctly after full save/load', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        saveId: 'test_save',
      );
      // Full flow: mentor → battle victory.
      executor.dispatch(
        scenarios: [mentorGivesPokemonScene()],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_start_map',
          entityId: 'test_mentor_npc',
        ),
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );
      state = state.copyWith(
        storyFlags: state.storyFlags.copyWith(
          activeFlags: <String>{
            ...state.storyFlags.activeFlags,
            'scenario.outcome.test_dialogue_outcome_confident',
            'battle:test_battle:victory',
          },
        ),
      );
      executor.dispatchContinuation(
        scenarios: [rivalBattleScene()],
        scenarioId: 'test_scene_rival_battle',
        sourceNodeId: 'source_outcome',
        resumeAfterNodeId: 'battle_node',
        context: buildContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
        ),
      );

      // Save/load.
      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      // Rival still visible (mission fact survives).
      expect(evaluator(reloaded).isNpcPresentOnMap(rivalEntity()), isTrue);

      // Rival dialogue resolves to post-battle (step completed survives).
      final resolvedDialogue =
          evaluator(reloaded).resolveNpcDialogue(rivalEntity().npc!);
      expect(resolvedDialogue?.dialogueId,
          'test_rival_post_battle_dialogue');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test 10: No Selbrume ids used anywhere in this test file
  // ═══════════════════════════════════════════════════════════════════════════

  group('10. No Selbrume ids guard', () {
    test('all fixture ids use test_* prefix', () {
      // Compile-time guard: if this test exists and passes, the Golden Slice
      // validation uses only generic ids.
      final scene = mentorGivesPokemonScene();
      expect(scene.id, startsWith('test_'));
      expect(scene.nodes.first.binding.entityId, startsWith('test_'));

      final battleScene = rivalBattleScene();
      expect(battleScene.id, startsWith('test_'));

      // No forbidden Selbrume ids.
      const forbiddenIds = [
        'mael', 'Maël', 'lysa', 'Lysa', 'soline', 'Soline',
        'selbrume', 'Selbrume', 'Bourg de Selbrume',
        'map_bourg_selbrume', 'map_port_brisants',
        'npc_mael', 'npc_lysa', 'npc_soline',
        'trainer_lysa_port', 'battle_rival_port',
        'scene_mael_intro', 'scene_rival_meet',
        'Sproutle', 'Sparkitten',
      ];
      final allIds = <String>[
        scene.id,
        ...scene.nodes.map((n) => n.id),
        ...scene.nodes.map((n) => n.binding.entityId ?? ''),
        ...scene.nodes.map((n) => n.binding.mapId ?? ''),
        ...scene.nodes.map((n) => n.binding.flagName ?? ''),
        battleScene.id,
        ...battleScene.nodes.map((n) => n.id),
        ...battleScene.nodes.map((n) => n.binding.entityId ?? ''),
        ...battleScene.nodes.map((n) => n.binding.trainerId ?? ''),
      ];
      for (final forbidden in forbiddenIds) {
        expect(allIds, isNot(contains(forbidden)),
            reason: 'Forbidden Selbrume id found: $forbidden');
      }
    });
  });
}
