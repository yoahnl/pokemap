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
  });
}
