import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('executeNarrativeEventScene', () {
    for (final giving in [true, false]) {
      test('inventory condition observes buffered ${giving ? 'give' : 'take'}',
          () async {
        final initial = GameState(
            saveId: 'inventory',
            bag: Bag(
                entries: giving
                    ? const []
                    : const [BagEntry(itemId: 'item_potion', quantity: 1)]));
        final scene = _inventoryScene(giving: giving);
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
              eventId: 'inventory_event',
              sceneId: scene.id,
              executionId: 'inventory_execution',
              gameState: initial),
          project: ProjectManifest(
              name: 'Inventory condition',
              maps: const [],
              tilesets: const [],
              scenes: [scene]),
          mapsById: const {},
          currentGameState: () => initial,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                    source: intent.conditionSource!, gameState: initial)
                ? 'true'
                : 'false',
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        );
        expect(result, isA<NarrativeSceneExecutionCompleted>());
        final completed = result as NarrativeSceneExecutionCompleted;
        expect(completed.qualifiedOutcomes.single.outcomeId,
            giving ? 'present' : 'absent');
        expect(
            const GameStateMutations()
                .itemQuantity(completed.updatedGameState, 'item_potion'),
            giving ? 1 : 0);
        expect(const GameStateMutations().itemQuantity(initial, 'item_potion'),
            giving ? 0 : 1);
      });
    }

    test('inventory condition rebases pending gifts on the latest host state',
        () async {
      const initial = GameState(saveId: 'inventory_host');
      var host = initial;
      final scene = _inventoryScene(giving: true, withDialogue: true);
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
            eventId: 'inventory_event',
            sceneId: scene.id,
            executionId: 'inventory_host_execution',
            gameState: initial),
        project: ProjectManifest(
            name: 'Inventory host',
            maps: const [],
            tilesets: const [],
            scenes: [
              scene
            ],
            dialogues: const [
              ProjectDialogueEntry(
                  id: 'inventory_dialogue',
                  name: 'Inventory',
                  relativePath: 'dialogues/inventory.yarn')
            ]),
        mapsById: const {},
        currentGameState: () => host,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                  source: intent.conditionSource!, gameState: host)
              ? 'true'
              : 'false',
          showDialogue: (_) {
            expect(const GameStateMutations().itemQuantity(host, 'item_potion'),
                0);
            host = const GameStateMutations().giveItem(host, 'item_potion', 2);
            host = host.copyWith(
                trainerProfile: host.trainerProfile.copyWith(money: 1234));
            return 'completed';
          },
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(completed.qualifiedOutcomes.single.outcomeId, 'present');
      expect(
          const GameStateMutations()
              .itemQuantity(completed.updatedGameState, 'item_potion'),
          3);
      expect(completed.updatedGameState.trainerProfile.money, 1234);
      expect(const GameStateMutations().itemQuantity(host, 'item_potion'), 2);
      expect(
          const GameStateMutations().itemQuantity(initial, 'item_potion'), 0);
    });

    test('inventory projection never commits a scene that later fails',
        () async {
      const initial = GameState(saveId: 'inventory_rollback');
      final scene = _inventoryScene(giving: true, rejectAfterCondition: true);
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
            eventId: 'inventory_event',
            sceneId: scene.id,
            executionId: 'inventory_rollback_execution',
            gameState: initial),
        project: ProjectManifest(
            name: 'Inventory rollback',
            maps: const [],
            tilesets: const [],
            scenes: [scene]),
        mapsById: const {},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                  source: intent.conditionSource!, gameState: initial)
              ? 'true'
              : 'false',
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(
          const GameStateMutations().itemQuantity(initial, 'item_potion'), 0);
    });

    test('unique wild battle consumes one-shot only after victory or capture',
        () async {
      const state = GameState(saveId: 'save_unique');
      final project = _project().copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'unique',
            name: 'Rencontre unique',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 12,
                maxLevel: 12,
              ),
            ],
          ),
        ],
        scenes: [_uniqueWildScene()],
      );
      for (final (outcome, consumed) in const [
        ('defeat', false),
        ('runaway', false),
        ('victory', true),
        ('captured', true),
      ]) {
        final result = await executeNarrativeEventScene(
          request: const NarrativeSceneExecutionRequest(
            eventId: 'unique_event',
            sceneId: 'unique_scene',
            executionId: 'unique_execution',
            gameState: state,
          ),
          project: project,
          mapsById: const {},
          currentGameState: () => state,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (intent) {
              expect(intent.battleKind, 'wild');
              expect(intent.battleTemplateId, 'unique');
              return outcome;
            },
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        );
        expect(result, isA<NarrativeSceneExecutionCompleted>(),
            reason: result is NarrativeSceneExecutionFailed
                ? '${result.failure}'
                : null);
        expect((result as NarrativeSceneExecutionCompleted).consumeOneShot,
            consumed);
        expect(
          result.updatedGameState.storyFlags.activeFlags,
          consumed
              ? contains('studio:unique_encounter:unique:consumed')
              : isNot(contains('studio:unique_encounter:unique:consumed')),
        );
      }
    });
    test('one consumed table cannot replay through another scene after reload',
        () async {
      const state = GameState(saveId: 'save_shared_unique');
      final project = _project().copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'unique',
            name: 'Rencontre unique',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 12,
                maxLevel: 12,
              ),
            ],
          ),
        ],
        scenes: [_uniqueWildScene(), _uniqueWildScene('another_scene')],
      );
      var battles = 0;
      SceneRuntimeHostCallbacks callbacks(String outcome) =>
          SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) {
              battles++;
              return outcome;
            },
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          );
      Future<NarrativeSceneExecutionResult> play(
        String sceneId,
        GameState gameState,
        String outcome,
      ) =>
          executeNarrativeEventScene(
            request: NarrativeSceneExecutionRequest(
              eventId: sceneId,
              sceneId: sceneId,
              executionId: 'run_$sceneId',
              gameState: gameState,
            ),
            project: project,
            mapsById: const {},
            currentGameState: () => gameState,
            callbacks: callbacks(outcome),
          );

      final defeat = await play('unique_scene', state, 'defeat');
      expect(defeat, isA<NarrativeSceneExecutionCompleted>());
      expect(battles, 1);
      final victory = await play('unique_scene', state, 'victory');
      expect(victory, isA<NarrativeSceneExecutionCompleted>());
      expect(battles, 2);
      final saved = (victory as NarrativeSceneExecutionCompleted)
          .updatedGameState
          .toJson();
      final reloaded = GameState.fromJson(saved);
      final replay = await play('another_scene', reloaded, 'victory');
      expect(replay, isA<NarrativeSceneExecutionCancelled>());
      expect(battles, 2);
    });
    test('a consumed table on an unvisited branch does not block the scene',
        () async {
      const initial = GameState(saveId: 'save_branch_unique');
      final state = const GameStateMutations().setFlag(
        initial,
        uniqueEncounterConsumedFlag('unique'),
      );
      final scene = SceneAsset(
        id: 'branch_scene',
        name: 'Combat avec branche',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'common',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'wild',
                battleTemplateId: 'common',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(
              id: 'unique',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'wild',
                battleTemplateId: 'unique',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_common',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'common',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'common_victory',
              fromNodeId: 'common',
              fromPortId: 'victory',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleVictory,
            ),
            SceneEdge(
              id: 'common_defeat',
              fromNodeId: 'common',
              fromPortId: 'defeat',
              toNodeId: 'unique',
              kind: SceneEdgeKind.battleDefeat,
            ),
            SceneEdge(
              id: 'unique_victory',
              fromNodeId: 'unique',
              fromPortId: 'victory',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleVictory,
            ),
            SceneEdge(
              id: 'unique_defeat',
              fromNodeId: 'unique',
              fromPortId: 'defeat',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleDefeat,
            ),
          ],
        ),
      );
      final project = _project().copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'common',
            name: 'Rencontre libre',
            encounterKind: EncounterKind.special,
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 5,
                maxLevel: 5,
              ),
            ],
          ),
          ProjectEncounterTable(
            id: 'unique',
            name: 'Rencontre unique',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'embercub',
                minLevel: 12,
                maxLevel: 12,
              ),
            ],
          ),
        ],
        scenes: [scene],
      );
      final battles = <String?>[];
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'branch_event',
          sceneId: 'branch_scene',
          executionId: 'branch_run',
          gameState: state,
        ),
        project: project,
        mapsById: const {},
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (intent) {
            battles.add(intent.battleTemplateId);
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      expect(battles, ['common']);
    });
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

    test('derives rail grant receipts from scene execution context', () async {
      const initial = GameState(saveId: 'save_rail_rewards');
      final project = _project().copyWith(
        scenes: <SceneAsset>[..._project().scenes, _railRewardScene()],
      );
      final callbacks = SceneRuntimeHostCallbacks(
        evaluateCondition: (_) => throw StateError('Unexpected condition.'),
        showDialogue: (_) => throw StateError('Unexpected dialogue.'),
        startBattle: (_) => throw StateError('Unexpected battle.'),
        playCinematic: (_) => throw StateError('Unexpected cinematic.'),
      );

      final first = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_rail_rewards',
          sceneId: 'scene_rail_rewards',
          executionId: 'execution_rail_rewards_1',
          gameState: initial,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => initial,
        callbacks: callbacks,
      ) as NarrativeSceneExecutionCompleted;
      final replay = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event_rail_rewards',
          sceneId: 'scene_rail_rewards',
          executionId: 'execution_rail_rewards_1',
          gameState: first.updatedGameState,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => first.updatedGameState,
        callbacks: callbacks,
      ) as NarrativeSceneExecutionCompleted;

      expect(
        first.updatedGameState.railJourneyProgress.semanticCurrencyBalances,
        <String, int>{'line_tokens': 3},
      );
      expect(first.updatedGameState.railJourneyProgress.earnedStampIds,
          <String>{'hanazuki_stamp'});
      expect(
        first.updatedGameState.railJourneyProgress.appliedProgressionOperations
            .keys,
        <String>{
          'scene:scene_rail_rewards:execution_rail_rewards_1:grant_currency',
          'scene:scene_rail_rewards:execution_rail_rewards_1:grant_stamp',
        },
      );
      expect(replay.updatedGameState, first.updatedGameState);
    });
  });
}

SceneAsset _inventoryScene(
        {required bool giving,
        bool withDialogue = false,
        bool rejectAfterCondition = false}) =>
    SceneAsset.fromJson({
      'id': 'inventory_scene',
      'name': 'Buffered inventory condition',
      'declaredOutcomes': [
        {'id': 'present', 'label': 'Present'},
        {'id': 'absent', 'label': 'Absent'},
      ],
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {
            'id': 'change',
            'kind': 'action',
            'payload': {
              'kind': 'action',
              'parameters': {},
              'consequence': {
                'kind': giving ? 'giveItem' : 'takeItem',
                'itemId': 'item_potion',
                'quantity': 1
              }
            }
          },
          if (withDialogue)
            {
              'id': 'dialogue',
              'kind': 'yarnDialogue',
              'payload': {
                'kind': 'yarnDialogue',
                'dialogueId': 'inventory_dialogue',
                'yarnNodeName': 'Start'
              }
            },
          if (rejectAfterCondition)
            {
              'id': 'reject',
              'kind': 'action',
              'payload': {
                'kind': 'action',
                'parameters': {},
                'consequence': {
                  'kind': 'takeItem',
                  'itemId': 'item_potion',
                  'quantity': 2
                }
              }
            },
          {
            'id': 'condition',
            'kind': 'condition',
            'payload': {
              'kind': 'condition',
              'conditionSource': {
                'sourceKind': 'inventoryItem',
                'sourceId': 'item_potion',
                'operator': 'isTrue',
                'value': withDialogue ? '3' : '1',
              }
            }
          },
          for (final outcome in ['present', 'absent'])
            {
              'id': outcome,
              'kind': 'end',
              'payload': {'kind': 'end', 'sceneOutcomeId': outcome}
            },
        ],
        'edges': [
          {
            'id': 'start-change',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'change',
            'kind': 'default'
          },
          {
            'id': 'change-condition',
            'fromNodeId': 'change',
            'fromPortId': 'completed',
            'toNodeId': withDialogue ? 'dialogue' : 'condition',
            'kind': 'default'
          },
          {
            'id': 'condition-true',
            'fromNodeId': 'condition',
            'fromPortId': 'true',
            'toNodeId': rejectAfterCondition ? 'reject' : 'present',
            'kind': 'conditionTrue'
          },
          if (withDialogue)
            {
              'id': 'dialogue-condition',
              'fromNodeId': 'dialogue',
              'fromPortId': 'completed',
              'toNodeId': 'condition',
              'kind': 'default'
            },
          if (rejectAfterCondition)
            {
              'id': 'reject-present',
              'fromNodeId': 'reject',
              'fromPortId': 'completed',
              'toNodeId': 'present',
              'kind': 'default'
            },
          {
            'id': 'condition-false',
            'fromNodeId': 'condition',
            'fromPortId': 'false',
            'toNodeId': 'absent',
            'kind': 'conditionFalse'
          },
        ],
      },
    });

SceneAsset _railRewardScene() {
  return SceneAsset(
    id: 'scene_rail_rewards',
    name: 'Rail rewards',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'grant_currency',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.grantRailCurrency(
              semanticCurrencyId: 'line_tokens',
              amount: 3,
            ),
          ),
        ),
        SceneNode(
          id: 'grant_stamp',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.grantRailStamp(stampId: 'hanazuki_stamp'),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_currency',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'grant_currency',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'currency_stamp',
          fromNodeId: 'grant_currency',
          fromPortId: 'completed',
          toNodeId: 'grant_stamp',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'stamp_end',
          fromNodeId: 'grant_stamp',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
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

SceneAsset _uniqueWildScene([String id = 'unique_scene']) => SceneAsset(
      id: id,
      name: 'Rencontre unique',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'battle',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'wild',
              battleTemplateId: 'unique',
              declaredOutcomes: const [
                'victory',
                'captured',
                'defeat',
                'runaway',
              ],
            ),
          ),
          for (final outcome in const [
            'victory',
            'captured',
            'defeat',
            'runaway',
          ])
            SceneNode(id: 'end_$outcome', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_battle',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'battle',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final outcome in const [
            'victory',
            'captured',
            'defeat',
            'runaway',
          ])
            SceneEdge(
              id: 'battle_$outcome',
              fromNodeId: 'battle',
              fromPortId: outcome,
              toNodeId: 'end_$outcome',
              kind: switch (outcome) {
                'victory' => SceneEdgeKind.battleVictory,
                'defeat' => SceneEdgeKind.battleDefeat,
                _ => SceneEdgeKind.branchOutcome,
              },
            ),
        ],
      ),
    );

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
