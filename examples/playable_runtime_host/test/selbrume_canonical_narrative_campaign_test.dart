import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Selbrume canonical campaign scenes execute through the current engine',
      () async {
    final fixture = _loadSelbrume();
    var state = const GameState(
      saveId: 'selbrume_canonical_campaign',
      currentMapId: 'map_bourg_selbrume',
    );
    final dialogueIds = <String>[];
    final cinematicIds = <String>[];
    final battleTrainerIds = <String>[];

    Future<NarrativeSceneExecutionCompleted> execute(
      String sceneId, {
      String battleOutcome = 'victory',
      String dialogueOutcome = 'completed',
    }) async {
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event_test_$sceneId',
          sceneId: sceneId,
          executionId: 'execution_test_$sceneId',
          gameState: state,
        ),
        project: fixture.project,
        mapsById: fixture.mapsById,
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          // Keep this campaign harness aligned with the production Scene hook:
          // canonical Fact branches (notably New Game party routing) must be
          // evaluated from the evolving GameState instead of being bypassed.
          evaluateCondition: (intent) =>
              _resolveConditionOutput(fixture.project, state, intent),
          showDialogue: (intent) {
            dialogueIds.add(intent.dialogueId!);
            return dialogueOutcome;
          },
          playCinematic: (intent) {
            cinematicIds.add(intent.cinematicId!);
            return 'completed';
          },
          startBattle: (intent) {
            battleTrainerIds.add(intent.trainerId!);
            return battleOutcome;
          },
        ),
      );
      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : sceneId,
      );
      final completed = result as NarrativeSceneExecutionCompleted;
      state = completed.updatedGameState;
      return completed;
    }

    await execute('scene_mael_intro');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_mael_mission_given', true),
    );
    expect(
      state.progression.completedStepIds,
      containsAll(<String>['step_intro_selbrume', 'step_receive_mission']),
    );

    await execute('scene_port_entry', dialogueOutcome: 'reassure');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_port_crowd_reassured', true),
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(containsPair('fact_port_crowd_panicked', true)),
    );
    expect(state.progression.completedStepIds, contains('step_go_to_port'));

    final rivalDefeat = await execute(
      'scene_lysa_port',
      battleOutcome: 'defeat',
      dialogueOutcome: 'hesitant',
    );
    expect(
      rivalDefeat.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.defeat',
        ),
      ),
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_lysa_tone_hesitant', true),
    );
    await execute('scene_rival_after_loss');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_rival_port_lost_once', true),
    );
    expect(
      state.progression.completedStepIds,
      contains('step_rival_battle'),
      reason: 'The defeat outcome must converge back into the main story.',
    );

    await execute('scene_soline_unlock_passage');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_passage_dames_unlocked', true),
    );

    final finalResult = await execute('scene_final_pokemon');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_mist_source_resolved', true),
    );
    expect(
      state.progression.completedStepIds,
      contains('step_final_confrontation'),
    );
    expect(
      finalResult.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_final_pokemon',
          outcomeId: 'lighthouse.pokemon.appeased',
        ),
      ),
    );
    final mistResult = await execute('scene_mist_disperses');
    expect(
      mistResult.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_mist_disperses',
          outcomeId: 'mist_resolved',
        ),
      ),
      reason: 'The final battle outcome must lead into the distinct '
          'mist-dispersal Scene.',
    );
    expect(
      battleTrainerIds,
      containsAll(<String>[
        'trainer_lysa_port',
        'trainer_boss_phare_pokemon',
      ]),
    );
    expect(
        dialogueIds,
        containsAll(<String>[
          'dialogue_mael_intro',
          'dialogue_port_alert',
          'dialogue_soline',
          'dialogue_lighthouse',
          'dialogue_lysa_port',
        ]));
    expect(
        cinematicIds,
        containsAll(<String>[
          'cinematic_port_reassure',
          'cinematic_passage_revealed',
          'cinematic_mist_disperses',
        ]));
    expect(cinematicIds, isNot(contains('cinematic_port_panic')));
  });

  test('the lighthouse boss defeat path does not resolve the mist', () async {
    final fixture = _loadSelbrume();
    var state = const GameState(
      saveId: 'selbrume_canonical_campaign_defeat',
      currentMapId: 'map_sommet_phare',
    );
    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: 'event_test_final_defeat',
        sceneId: 'scene_final_pokemon',
        executionId: 'execution_test_final_defeat',
        gameState: state,
      ),
      project: fixture.project,
      mapsById: fixture.mapsById,
      currentGameState: () => state,
      callbacks: SceneRuntimeHostCallbacks(
        evaluateCondition: (intent) =>
            _resolveConditionOutput(fixture.project, state, intent),
        showDialogue: (_) => 'completed',
        playCinematic: (_) => 'completed',
        startBattle: (_) => 'defeat',
      ),
    );
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(containsPair('fact_mist_source_resolved', true)),
    );
    expect(
      result.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_final_pokemon',
          outcomeId: 'lighthouse.pokemon.defeat',
        ),
      ),
    );
  });

  test('the Lysa victory route persists respect and rejoins the main story',
      () async {
    final fixture = _loadSelbrume();
    var state = const GameState(
      saveId: 'selbrume_canonical_rival_victory',
      currentMapId: 'map_port_brisants',
    );

    Future<NarrativeSceneExecutionCompleted> execute(
      String sceneId, {
      String battleOutcome = 'victory',
      String dialogueOutcome = 'completed',
    }) async {
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event_test_$sceneId',
          sceneId: sceneId,
          executionId: 'execution_test_$sceneId',
          gameState: state,
        ),
        project: fixture.project,
        mapsById: fixture.mapsById,
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) =>
              _resolveConditionOutput(fixture.project, state, intent),
          showDialogue: (_) => dialogueOutcome,
          playCinematic: (_) => 'completed',
          startBattle: (_) => battleOutcome,
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      state = completed.updatedGameState;
      return completed;
    }

    final battle = await execute(
      'scene_lysa_port',
      dialogueOutcome: 'confident',
    );
    expect(
      battle.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.victory',
        ),
      ),
    );
    await execute('scene_rival_after_win');

    for (final factId in const <String>[
      'fact_lysa_tone_confident',
      'fact_rival_port_defeated',
      'fact_lysa_respects_player',
      'fact_lysa_goes_ahead',
    ]) {
      expect(
        state.narrativeFactRuntimeState.overridesByFactId,
        containsPair(factId, true),
      );
    }
    expect(state.progression.completedStepIds, contains('step_rival_battle'));
  });

  test('the three optional quests persist choices, rewards and completion',
      () async {
    final fixture = _loadSelbrume();
    var state = const GameState(
      saveId: 'selbrume_canonical_side_quests',
      currentMapId: 'map_marais_salants',
    );

    Future<void> execute(
      String sceneId, {
      String dialogueOutcome = 'completed',
    }) async {
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event_test_$sceneId',
          sceneId: sceneId,
          executionId: 'execution_test_$sceneId',
          gameState: state,
        ),
        project: fixture.project,
        mapsById: fixture.mapsById,
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) =>
              _resolveConditionOutput(fixture.project, state, intent),
          showDialogue: (_) => dialogueOutcome,
          playCinematic: (_) => 'completed',
          startBattle: (_) => 'victory',
        ),
      );
      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : sceneId,
      );
      state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    }

    await execute('scene_mado_intro', dialogueOutcome: 'accept_help');
    await execute('scene_crystal_1');
    await execute('scene_crystal_2');
    await execute('scene_crystal_3');
    await execute('scene_mado_crystals_return');

    await execute('scene_goelise_fisher_intro');
    await execute('scene_goelise_nest_choice', dialogueOutcome: 'keep_item');
    await execute('scene_goelise_keep_reward');

    await execute('scene_yvon_intro', dialogueOutcome: 'accept_search_key');
    await execute('scene_cabin_key');
    await execute('scene_cabin_journal');

    final facts = state.narrativeFactRuntimeState.overridesByFactId;
    for (final factId in const <String>[
      'fact_crystals_quest_completed',
      'fact_goelise_object_kept',
      'fact_goelise_quest_completed',
      'fact_cabin_key_found',
      'fact_cabin_journal_read',
      'fact_cabin_quest_completed',
    ]) {
      expect(facts, containsPair(factId, true));
    }
    expect(_bagQuantity(state, 'super-potion'), 1);
    expect(_bagQuantity(state, 'pearl'), 1);
    expect(_bagQuantity(state, 'basement-key'), 1);
    expect(_bagQuantity(state, 'rare-candy'), 1);
    expect(
      state.progression.completedStepIds,
      containsAll(<String>[
        'step_crystals_completed',
        'step_goelise_completed',
        'step_cabin_completed',
      ]),
    );
    expect(
      facts,
      isNot(containsPair('fact_mist_source_resolved', true)),
      reason: 'Optional quests must not complete the main campaign.',
    );
  });
}

int _bagQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

({ProjectManifest project, Map<String, MapData> mapsById}) _loadSelbrume() {
  final root = _findRepositoryRoot();
  final projectRoot = Directory(p.join(root.path, 'selbrume'));
  final project = ProjectManifest.fromJson(
    _readJson(File(p.join(projectRoot.path, 'project.json'))),
  );
  return (
    project: project,
    mapsById: <String, MapData>{
      for (final entry in project.maps)
        entry.id: MapData.fromJson(
          _readJson(File(p.join(projectRoot.path, entry.relativePath))),
        ),
    },
  );
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

String _resolveConditionOutput(
  ProjectManifest project,
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('Scene condition intent is missing a condition source.');
  }

  if (source.sourceKind == SceneConditionSourceKind.fact) {
    final matched = evaluateCanonicalNarrativeFactSceneCondition(
      source: source,
      gameState: state,
      resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    return matched ? 'true' : 'false';
  }

  final value = switch (source.sourceKind) {
    SceneConditionSourceKind.factLikeStoryFlag =>
      state.storyFlags.activeFlags.contains(source.sourceId) ||
          state.progression.storyFlags.contains(source.sourceId),
    SceneConditionSourceKind.storyStepCompletion =>
      state.progression.completedStepIds.contains(source.sourceId),
    SceneConditionSourceKind.consumedEvent =>
      state.consumedEventIds.contains(source.sourceId),
    _ => throw UnsupportedError(
        'Condition source ${source.sourceKind.name} is outside this campaign.',
      ),
  };

  final matched = switch (source.operator) {
    SceneConditionOperator.isTrue => value,
    SceneConditionOperator.isFalse => !value,
    SceneConditionOperator.equals => switch (source.value) {
        'true' || SceneConditionValues.completed => value,
        'false' || SceneConditionValues.notCompleted => !value,
        _ => throw UnsupportedError(
            'Condition value ${source.value} is outside this campaign.',
          ),
      },
  };
  return matched ? 'true' : 'false';
}
