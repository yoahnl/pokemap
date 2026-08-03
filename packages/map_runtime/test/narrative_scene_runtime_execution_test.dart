import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('executeNarrativeEventScene', () {
    test('rebases buffered consequences onto host battle write-back', () async {
      const requestGameState = GameState(
        saveId: 'save_scene_runtime',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 12,
            ),
          ],
        ),
      );
      var runtimeGameState = requestGameState;
      var battleCalls = 0;
      final hostedBattleOutcomes = <NarrativeOutcomeRef>[];

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        hostedBattleOutcomes: hostedBattleOutcomes,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (intent) {
            battleCalls++;
            expect(intent.trainerId, 'trainer_scene_runtime');
            runtimeGameState = runtimeGameState.copyWith(
              party: PlayerParty(
                members: <PlayerPokemon>[
                  runtimeGameState.party.members.single.copyWith(currentHp: 3),
                ],
              ),
              metadata: const <String, String>{
                'battleWriteBack': 'committed',
              },
            );
            hostedBattleOutcomes.add(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'trainer:trainer_scene_runtime',
                outcomeId: 'victory',
              ),
            );
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : null,
      );
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(battleCalls, 1);
      expect(completed.updatedGameState.party.members.single.currentHp, 3);
      expect(
        completed.updatedGameState.metadata['battleWriteBack'],
        'committed',
      );
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_scene_runtime_completed'),
      );
      expect(
        completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
        containsPair('fact_scene_runtime_completed', true),
      );
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.battle,
            producerId: 'trainer:trainer_scene_runtime',
            outcomeId: 'victory',
          ),
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_battle_then_fact',
            outcomeId: 'scene.completed',
          ),
        ],
      );
    });

    test('fails closed on an initial GameState conflict before host callbacks',
        () async {
      const requestGameState = GameState(saveId: 'save_scene_runtime');
      final runtimeGameState = requestGameState.copyWith(
        metadata: const <String, String>{'newerRuntimeState': 'true'},
      );
      var hostCallbackCalls = 0;
      String unexpectedCallback(SceneRuntimePlanIntent _) {
        hostCallbackCalls++;
        return 'victory';
      }

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: unexpectedCallback,
          showDialogue: unexpectedCallback,
          startBattle: unexpectedCallback,
          playCinematic: unexpectedCallback,
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      final failed = result as NarrativeSceneExecutionFailed;
      expect(failed.failure, isA<StateError>());
      expect(failed.failure.toString(), contains('initial GameState conflict'));
      expect(hostCallbackCalls, 0);
    });

    test('stops on the first rejected Action node before later callbacks',
        () async {
      const state = GameState(saveId: 'save_rejected_action');
      var battleCalls = 0;
      final project = _project().copyWith(
        scenes: [..._project().scenes, _rejectedActionScene()],
      );

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_rejected_action',
          sceneId: 'scene_rejected_action',
          executionId: 'execution_rejected_action',
          gameState: state,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (_) {
            battleCalls++;
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(
        (result as NarrativeSceneExecutionFailed).failure.toString(),
        contains('potion'),
      );
      expect(battleCalls, 0);
      expect(state.trainerProfile.money, 0);
      expect(state.bag.entries, isEmpty);
    });

    test('returns Finish Game only with its committed terminal state',
        () async {
      const state = GameState(saveId: 'save_finish_scene');
      final project = _project().copyWith(
        scenes: [..._project().scenes, _finishScene()],
      );

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_finish',
          sceneId: 'scene_finish',
          executionId: 'execution_finish',
          gameState: state,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (_) => throw StateError('Unexpected battle.'),
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(completed.gameCompletion?.endingId, 'ending.selbrume');
      expect(
        completed
            .updatedGameState.metadata[sceneGameCompletionEndingMetadataKey],
        'ending.selbrume',
      );
    });
  });
}

SceneAsset _finishScene() {
  return SceneAsset(
    id: 'scene_finish',
    name: 'Finish',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'finish',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.finishGame(
              endingId: 'ending.selbrume',
              outcome: SceneGameCompletionOutcome.victory,
              result: SceneFinishGameResult(
                title: SceneLocalizedText(fallback: 'Victoire'),
                summary: SceneLocalizedText(
                  fallback: 'Selbrume est sauvée.',
                ),
              ),
              postGamePolicy: ScenePostGamePolicy.returnToTitle,
            ),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_finish',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'finish',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'finish_end',
          fromNodeId: 'finish',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _rejectedActionScene() {
  return SceneAsset(
    id: 'scene_rejected_action',
    name: 'Rejected Action',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'money',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.giveMoney(amount: 100),
          ),
        ),
        SceneNode(
          id: 'take_missing',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.takeItem(itemId: 'potion', quantity: 1),
          ),
        ),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_money',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'money',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'money_take',
          fromNodeId: 'money',
          fromPortId: 'completed',
          toNodeId: 'take_missing',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'take_battle',
          fromNodeId: 'take_missing',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_end',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Narrative Scene Runtime Execution Test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: 'trainer_scene_runtime',
        name: 'Runtime Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_scene_runtime_completed',
        label: 'Runtime scene completed',
      ),
    ],
    scenes: <SceneAsset>[_battleThenFactScene()],
  );
}

SceneAsset _battleThenFactScene() {
  return SceneAsset(
    id: 'scene_battle_then_fact',
    name: 'Battle then Fact',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: 'scene.completed', label: 'Scene completed'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_scene_runtime_completed',
              value: true,
            ),
          ),
        ),
        SceneNode(
          id: 'victory_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
        SceneNode(
          id: 'defeat_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory_to_fact',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'fact_to_victory_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_defeat_to_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
