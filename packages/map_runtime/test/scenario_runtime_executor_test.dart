import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// Les scénarios de test sont construits étape par étape pour lisibilité.
// On désactive la préférence "const" pour garder les blocs homogènes.
// ignore_for_file: prefer_const_constructors

void main() {
  group('ScenarioRuntimeExecutor', () {
    const executor = ScenarioRuntimeExecutor();

    test('map enter source triggers dialogue node', () {
      final scenario = ScenarioAsset(
        id: 's_main',
        name: 'Main',
        entryNodeId: 'source_map',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_map',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: 'vova_east'),
          ),
          ScenarioNode(
            id: 'dialogue_intro',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'intro'),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_map',
            toNodeId: 'dialogue_intro',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'dialogue_intro',
            toNodeId: 'end',
          ),
        ],
      );

      final openedDialogues = <String>[];
      var state = const GameState(saveId: 'save');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'vova_east'),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.dialogue);
      expect(openedDialogues, <String>['intro']);
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('trigger enter source matches map + trigger id', () {
      final scenario = ScenarioAsset(
        id: 's_trigger',
        name: 'Trigger scenario',
        entryNodeId: 'source_trigger',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_trigger',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
            binding: ScenarioNodeBinding(
              mapId: 'vova_east',
              triggerId: 'trigger_intro_start',
            ),
          ),
          ScenarioNode(
            id: 'dialogue_intro',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'intro'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_trigger',
            toNodeId: 'dialogue_intro',
          ),
        ],
      );

      var dialogueOpened = false;
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: 'vova_east',
          triggerId: 'trigger_intro_start',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
            dialogueOpened = dialogueId == 'intro';
            return true;
          },
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(dialogueOpened, isTrue);
    });

    test('entity interaction source can run script action', () {
      final scenario = ScenarioAsset(
        id: 's_entity',
        name: 'Entity interaction',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_east',
              entityId: 'npc_professor',
            ),
          ),
          ScenarioNode(
            id: 'run_script',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
            binding: ScenarioNodeBinding(scriptId: 'professor_intro_script'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'run_script',
          ),
        ],
      );

      final startedScripts = <String>[];
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_east',
          entityId: 'npc_professor',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => false,
          runScript: (scriptId, {startNode, runtimeSourceId}) {
            startedScripts.add(scriptId);
            return true;
          },
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.script);
      expect(startedScripts, <String>['professor_intro_script']);
    });

    test('condition node routes to trueBranch and evaluates flag mutation', () {
      final scenario = ScenarioAsset(
        id: 's_condition',
        name: 'Condition flow',
        entryNodeId: 'source_map',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_map',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: 'vova_east'),
          ),
          ScenarioNode(
            id: 'set_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: 'story.got_starter'),
          ),
          ScenarioNode(
            id: 'condition',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName: 'story.got_starter',
                },
              ),
            ),
          ),
          ScenarioNode(
            id: 'dialogue_true',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'starter_true'),
          ),
          ScenarioNode(
            id: 'dialogue_false',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'starter_false'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_map',
            toNodeId: 'set_flag',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'set_flag',
            toNodeId: 'condition',
          ),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'condition',
            toNodeId: 'dialogue_true',
            kind: ScenarioEdgeKind.trueBranch,
          ),
          ScenarioEdge(
            id: 'e4',
            fromNodeId: 'condition',
            toNodeId: 'dialogue_false',
            kind: ScenarioEdgeKind.falseBranch,
          ),
        ],
      );

      final openedDialogues = <String>[];
      GameState state = const GameState(saveId: 'save');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'vova_east'),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(openedDialogues, <String>['starter_true']);
      expect(state.storyFlags.activeFlags, contains('story.got_starter'));
    });

    test('unsupported choice node blocks execution explicitly', () {
      final scenario = ScenarioAsset(
        id: 's_choice',
        name: 'Choice',
        entryNodeId: 'source_map',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_map',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: 'vova_east'),
          ),
          ScenarioNode(
            id: 'choice',
            type: ScenarioNodeType.choice,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_map',
            toNodeId: 'choice',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'vova_east'),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => false,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message.toLowerCase(), contains('choice'));
    });

    test('local outcome can route into global story sourceOutcome', () {
      final localScenario = ScenarioAsset(
        id: 'local_professor',
        name: 'Local professor hook',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_east',
              entityId: 'npc_professor',
            ),
          ),
          ScenarioNode(
            id: 'emit_outcome',
            type: ScenarioNodeType.action,
            payload:
                ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
            binding: ScenarioNodeBinding(
              outcomeId: 'professor_intro.completed',
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e_local_1',
            fromNodeId: 'source_entity',
            toNodeId: 'emit_outcome',
          ),
        ],
      );

      final globalScenario = ScenarioAsset(
        id: 'global_story',
        name: 'Global story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: const <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'source_outcome',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
            binding: ScenarioNodeBinding(
              outcomeId: 'professor_intro.completed',
            ),
          ),
          ScenarioNode(
            id: 'dialogue_global',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'global_intro_step'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e_global_1',
            fromNodeId: 'start',
            toNodeId: 'source_outcome',
          ),
          ScenarioEdge(
            id: 'e_global_2',
            fromNodeId: 'source_outcome',
            toNodeId: 'dialogue_global',
          ),
        ],
      );

      final openedDialogues = <String>[];
      GameState state = const GameState(saveId: 'save');
      final result = executor.dispatch(
        scenarios: <ScenarioAsset>[globalScenario, localScenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_east',
          entityId: 'npc_professor',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.dialogue);
      expect(result.emittedOutcomeId, 'professor_intro.completed');
      expect(openedDialogues, <String>['global_intro_step']);
      expect(
        state.storyFlags.activeFlags,
        contains(scenarioOutcomeFlagName('professor_intro.completed')),
      );
    });

    test('scenario activationCondition gates local source execution', () {
      final scenario = ScenarioAsset(
        id: 'local_gate',
        name: 'Local gated',
        scope: ScenarioScope.localEventFlow,
        activationCondition: const ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: <String, String>{
            ScriptConditionParams.flagName: 'story.chapter_1_started',
          },
        ),
        entryNodeId: 'source_map',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_map',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: 'vova_east'),
          ),
          ScenarioNode(
            id: 'dialogue_intro',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'intro'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_map',
            toNodeId: 'dialogue_intro',
          ),
        ],
      );

      final blockedResult = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'vova_east'),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );
      expect(
        blockedResult.status,
        ScenarioRuntimeExecutionStatus.noMatchingSource,
      );

      final allowedState = const GameState(saveId: 'save').copyWith(
        storyFlags: const StoryFlags(
          activeFlags: <String>{'story.chapter_1_started'},
        ),
      );
      var dialogueOpened = false;
      final allowedResult = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'vova_east'),
        context: ScenarioRuntimeExecutionContext(
          gameState: allowedState,
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
            dialogueOpened = true;
            return true;
          },
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );
      expect(
          allowedResult.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(dialogueOpened, isTrue);
    });

    test(
        'dispatchContinuation resumes after dialogue and executes moveCharacter',
        () {
      final scenario = ScenarioAsset(
        id: 's_cutscene_like',
        name: 'Cutscene-like chain',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_center',
              entityId: 'emma',
            ),
          ),
          ScenarioNode(
            id: 'dialogue_intro',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'intro'),
          ),
          ScenarioNode(
            id: 'move_emma',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionMoveCharacter,
              params: <String, String>{
                'targetKind': 'spawn',
                'targetId': 'spawn',
                'waitForCompletion': 'true',
              },
            ),
            binding: ScenarioNodeBinding(entityId: 'emma'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'dialogue_intro',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'dialogue_intro',
            toNodeId: 'move_emma',
          ),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'move_emma',
            toNodeId: 'end',
          ),
        ],
      );

      String? movedEntity;
      String? movedKind;
      String? movedTarget;
      final result = executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 's_cutscene_like',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'dialogue_intro',
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
          moveCharacter: ({
            required entityId,
            required targetKind,
            required targetId,
            required waitForCompletion,
            runtimeSourceId,
          }) {
            movedEntity = entityId;
            movedKind = targetKind;
            movedTarget = targetId;
            return true;
          },
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(movedEntity, 'emma');
      expect(movedKind, 'spawn');
      expect(movedTarget, 'spawn');
    });

    test('moveCharacter blocks when target data is missing', () {
      final scenario = ScenarioAsset(
        id: 's_move_invalid',
        name: 'Move invalid',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_center',
              entityId: 'emma',
            ),
          ),
          ScenarioNode(
            id: 'move_emma',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionMoveCharacter,
              params: <String, String>{
                'targetKind': 'spawn',
                'waitForCompletion': 'true',
              },
            ),
            binding: ScenarioNodeBinding(entityId: 'emma'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'move_emma',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_center',
          entityId: 'emma',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message, contains('moveCharacter invalide'));
    });

    test('followCharacter delegates to context and continues to end', () {
      final scenario = ScenarioAsset(
        id: 's_follow',
        name: 'Follow',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_center',
              entityId: 'emma',
            ),
          ),
          ScenarioNode(
            id: 'follow',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionFollowCharacter,
              params: <String, String>{'leaderId': 'emma'},
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'follow',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'follow',
            toNodeId: 'end',
          ),
        ],
      );

      String? followedLeader;
      final result = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_center',
          entityId: 'emma',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
          moveCharacter: ({
            required entityId,
            required targetKind,
            required targetId,
            required waitForCompletion,
            runtimeSourceId,
          }) =>
              true,
          followCharacter: ({
            required leaderEntityId,
          }) {
            followedLeader = leaderEntityId;
            return true;
          },
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(followedLeader, 'emma');
    });

    test('followCharacter blocks when leaderId is missing', () {
      final scenario = ScenarioAsset(
        id: 's_follow_invalid',
        name: 'Follow invalid',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_center',
              entityId: 'emma',
            ),
          ),
          ScenarioNode(
            id: 'follow',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionFollowCharacter,
              params: <String, String>{},
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'follow',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_center',
          entityId: 'emma',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message, contains('followCharacter invalide'));
    });

    test('transitionMap delegates to context and continues to end', () {
      final scenario = ScenarioAsset(
        id: 's_transition',
        name: 'Transition',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_center',
              entityId: 'emma',
            ),
          ),
          ScenarioNode(
            id: 'transition',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionTransitionMap,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'house_interior',
              warpId: 'entry_warp',
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'transition',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'transition',
            toNodeId: 'end',
          ),
        ],
      );

      String? transitionedMapId;
      String? transitionedWarpId;
      final result = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_center',
          entityId: 'emma',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
          transitionMap: ({
            required mapId,
            required warpId,
          }) {
            transitionedMapId = mapId;
            transitionedWarpId = warpId;
            return true;
          },
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(transitionedMapId, 'house_interior');
      expect(transitionedWarpId, 'entry_warp');
    });

    test('transitionMap blocks when mapId or warpId is missing', () {
      final scenario = ScenarioAsset(
        id: 's_transition_invalid',
        name: 'Transition invalid',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'vova_center',
              entityId: 'emma',
            ),
          ),
          ScenarioNode(
            id: 'transition',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionTransitionMap,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'house_interior',
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'transition',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: <ScenarioAsset>[scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'vova_center',
          entityId: 'emma',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: const GameState(saveId: 'save'),
          onGameStateUpdated: (_) {},
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message, contains('transitionMap invalide'));
    });
  });
}
