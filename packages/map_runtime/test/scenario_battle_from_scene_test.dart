import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// Les scénarios de test sont construits étape par étape pour lisibilité.
// On désactive la préférence "const" pour garder les blocs homogènes.
// ignore_for_file: prefer_const_constructors

void main() {
  group('ScenarioRuntimeExecutor — startTrainerBattle', () {
    const executor = ScenarioRuntimeExecutor();

    /// Helper commun : construit un contexte d'exécution basique.
    ScenarioRuntimeExecutionContext buildContext({
      GameState? gameState,
      void Function(GameState)? onGameStateUpdated,
    }) {
      var state = gameState ?? const GameState(saveId: 'save');
      return ScenarioRuntimeExecutionContext(
        gameState: state,
        onGameStateUpdated: onGameStateUpdated ?? (next) => state = next,
        openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
        runScript: (scriptId, {startNode, runtimeSourceId}) => false,
        showMessage: (_) {},
      );
    }

    // -------------------------------------------------------------------
    // Cas nominal : nœud action startTrainerBattle retourne executedEffect
    // avec effet battle contenant trainerId, npcEntityId, battleId.
    // -------------------------------------------------------------------
    test('action startTrainerBattle returns executedEffect with battle data',
        () {
      final scenario = ScenarioAsset(
        id: 's_battle',
        name: 'Battle scenario',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{
                'battleId': 'battle_rival_port',
              },
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'battle_node',
            toNodeId: 'end',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'port_brisants',
          entityId: 'npc_lysa',
        ),
        context: buildContext(),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(result.effect.trainerId, 'trainer_lysa_port');
      expect(result.effect.npcEntityId, 'npc_lysa');
      expect(result.effect.battleId, 'battle_rival_port');
      expect(result.scenarioId, 's_battle');
      expect(result.stopNodeId, 'battle_node');
      // Le graphe doit être suspendu : pas de continuation automatique.
      expect(result.message, contains('suspendu'));
    });

    // -------------------------------------------------------------------
    // battleId fallback sur trainerId quand absent des params.
    // -------------------------------------------------------------------
    test('battleId defaults to trainerId when not in params', () {
      final scenario = ScenarioAsset(
        id: 's_battle_fallback',
        name: 'Battle fallback',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              // Pas de battleId dans params.
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              entityId: 'npc_lysa',
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'port_brisants',
          entityId: 'npc_lysa',
        ),
        context: buildContext(),
      );

      expect(result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(
        result.effect.battleId,
        'trainer_lysa_port',
        reason: 'battleId doit fallback sur trainerId',
      );
    });

    // -------------------------------------------------------------------
    // trainerId vide → blocked.
    // -------------------------------------------------------------------
    test('blocks when trainerId is empty', () {
      final scenario = ScenarioAsset(
        id: 's_battle_no_trainer',
        name: 'No trainer',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'battle_rival_port'},
            ),
            binding: ScenarioNodeBinding(
              // trainerId manquant !
              entityId: 'npc_lysa',
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'port_brisants',
          entityId: 'npc_lysa',
        ),
        context: buildContext(),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message, contains('trainerId'));
    });

    // -------------------------------------------------------------------
    // npcEntityId vide → blocked.
    // -------------------------------------------------------------------
    test('blocks when npcEntityId is empty', () {
      final scenario = ScenarioAsset(
        id: 's_battle_no_npc',
        name: 'No npc',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'battle_rival_port'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              // entityId manquant !
            ),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
        ],
      );

      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'port_brisants',
          entityId: 'npc_lysa',
        ),
        context: buildContext(),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(result.message, contains('npcEntityId'));
    });

    // -------------------------------------------------------------------
    // Continuation après combat : le graphe reprend après le node battle.
    // -------------------------------------------------------------------
    test('dispatchContinuation resumes after battle node and sets flag', () {
      final scenario = ScenarioAsset(
        id: 's_battle_continue',
        name: 'Battle continuation',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'battle_rival_port'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'set_victory_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: 'lysa_battle_done'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'battle_node',
            toNodeId: 'set_victory_flag',
          ),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'set_victory_flag',
            toNodeId: 'end',
          ),
        ],
      );

      // Simuler que le runtime a déjà posé le flag d'outcome battle.
      var state = const GameState(saveId: 'save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          scenarioBattleOutcomeFlagName(
            'battle_rival_port',
            kBattleOutcomeSuffixVictory,
          ),
        }),
      );

      final result = executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 's_battle_continue',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'battle_node',
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      // Le graphe doit atteindre la fin après avoir posé le flag setFlag.
      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains('lysa_battle_done'));
    });

    // -------------------------------------------------------------------
    // Continuation avec branchement condition victory / defeat.
    // -------------------------------------------------------------------
    test('continuation branches on victory/defeat flag after battle', () {
      final scenario = ScenarioAsset(
        id: 's_battle_branch',
        name: 'Battle branch',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'battle_rival_port'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'condition_victory',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName:
                      'battle:battle_rival_port:victory',
                },
              ),
            ),
          ),
          ScenarioNode(
            id: 'dialogue_victory',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'lysa_victory_speech'),
          ),
          ScenarioNode(
            id: 'dialogue_defeat',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'lysa_defeat_speech'),
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'battle_node',
            toNodeId: 'condition_victory',
          ),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'condition_victory',
            toNodeId: 'dialogue_victory',
            kind: ScenarioEdgeKind.trueBranch,
          ),
          ScenarioEdge(
            id: 'e4',
            fromNodeId: 'condition_victory',
            toNodeId: 'dialogue_defeat',
            kind: ScenarioEdgeKind.falseBranch,
          ),
        ],
      );

      final openedDialogues = <String>[];

      // Cas victoire.
      var state = const GameState(saveId: 'save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'battle:battle_rival_port:victory',
        }),
      );
      final victoryResult = executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 's_battle_branch',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'battle_node',
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

      expect(victoryResult.status,
          ScenarioRuntimeExecutionStatus.executedEffect);
      expect(openedDialogues, <String>['lysa_victory_speech']);

      // Cas défaite.
      openedDialogues.clear();
      state = const GameState(saveId: 'save').copyWith(
        storyFlags: StoryFlags(activeFlags: <String>{
          'battle:battle_rival_port:defeat',
        }),
      );
      final defeatResult = executor.dispatchContinuation(
        scenarios: <ScenarioAsset>[scenario],
        scenarioId: 's_battle_branch',
        sourceNodeId: 'source_entity',
        resumeAfterNodeId: 'battle_node',
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

      expect(
          defeatResult.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(openedDialogues, <String>['lysa_defeat_speech']);
    });
  });

  group('scenarioBattleOutcomeFlagName', () {
    test('produces deterministic battle:id:outcome format', () {
      expect(
        scenarioBattleOutcomeFlagName(
            'battle_rival_port', kBattleOutcomeSuffixVictory),
        'battle:battle_rival_port:victory',
      );
      expect(
        scenarioBattleOutcomeFlagName(
            'battle_rival_port', kBattleOutcomeSuffixDefeat),
        'battle:battle_rival_port:defeat',
      );
      expect(
        scenarioBattleOutcomeFlagName(
            'battle_rival_port', kBattleOutcomeSuffixFlee),
        'battle:battle_rival_port:flee',
      );
      expect(
        scenarioBattleOutcomeFlagName(
            'battle_rival_port', kBattleOutcomeSuffixCaptured),
        'battle:battle_rival_port:captured',
      );
    });

    test('trims whitespace from battleId and outcomeSuffix', () {
      expect(
        scenarioBattleOutcomeFlagName('  rival  ', '  victory  '),
        'battle:rival:victory',
      );
    });

    test('does not produce generic flags like battle_victory', () {
      final flag = scenarioBattleOutcomeFlagName(
          'battle_rival_port', kBattleOutcomeSuffixVictory);
      expect(flag, isNot('battle_victory'));
      expect(flag, isNot('battle_defeat'));
      expect(flag, contains('battle_rival_port'));
    });

    test('asserts on empty battleId (debug mode)', () {
      expect(
        () => scenarioBattleOutcomeFlagName('', kBattleOutcomeSuffixVictory),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => scenarioBattleOutcomeFlagName('   ', kBattleOutcomeSuffixVictory),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts on empty outcomeSuffix (debug mode)', () {
      expect(
        () => scenarioBattleOutcomeFlagName('battle_rival_port', ''),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => scenarioBattleOutcomeFlagName('battle_rival_port', '   '),
        throwsA(isA<AssertionError>()),
      );
    });

    test('all four outcome suffixes are unique and non-empty', () {
      final suffixes = <String>{
        kBattleOutcomeSuffixVictory,
        kBattleOutcomeSuffixDefeat,
        kBattleOutcomeSuffixFlee,
        kBattleOutcomeSuffixCaptured,
      };
      // Les 4 suffixes sont distincts.
      expect(suffixes.length, 4);
      for (final s in suffixes) {
        expect(s.trim(), isNotEmpty);
      }
    });

    test('flag prefix is battle: (colon-separated, not underscore)', () {
      expect(kBattleOutcomeFlagPrefix, 'battle:');
      final flag = scenarioBattleOutcomeFlagName('test_id', 'victory');
      // Ne doit jamais commencer par 'battle_' (format générique).
      expect(flag.startsWith('battle_'), isFalse);
      // Doit commencer par 'battle:' (format qualifié).
      expect(flag.startsWith('battle:'), isTrue);
    });
  });

  group('ScenarioRuntimeExecutor — startTrainerBattle result completeness', () {
    const executor = ScenarioRuntimeExecutor();

    test('battle effect result has non-null scenarioId/sourceNodeId/stopNodeId',
        () {
      final scenario = ScenarioAsset(
        id: 's_complete',
        name: 'Complete',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'battle_rival_port'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'battle_node',
            toNodeId: 'end',
          ),
        ],
      );

      var state = const GameState(saveId: 'save');
      final result = executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'port_brisants',
          entityId: 'npc_lysa',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      // [SEL-B2-bis] Le runtimeSourceId de _handleScenarioBattleEffect
      // exige que ces trois champs soient non-null. Vérifions-le.
      expect(result.scenarioId, isNotNull);
      expect(result.sourceNodeId, isNotNull);
      expect(result.stopNodeId, isNotNull);

      // Le stopNodeId est le node battle, pas un node au-delà.
      expect(result.stopNodeId, 'battle_node');
    });

    test('graph does not advance past battle node (no graph leak)', () {
      // Le flag 'should_not_be_set' est posé par un node setFlag
      // après le battle node. Si le graphe avance au-delà du battle,
      // ce flag serait posé dans le gameState. Il ne doit PAS l'être.
      var state = const GameState(saveId: 'save');
      final scenario = ScenarioAsset(
        id: 's_no_leak',
        name: 'No leak',
        entryNodeId: 'source_entity',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source_entity',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
            binding: ScenarioNodeBinding(
              mapId: 'port_brisants',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'battle_node',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionStartTrainerBattle,
              params: <String, String>{'battleId': 'b1'},
            ),
            binding: ScenarioNodeBinding(
              trainerId: 'trainer_lysa_port',
              entityId: 'npc_lysa',
            ),
          ),
          ScenarioNode(
            id: 'set_leak_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: 'should_not_be_set'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source_entity',
            toNodeId: 'battle_node',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'battle_node',
            toNodeId: 'set_leak_flag',
          ),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'set_leak_flag',
            toNodeId: 'end',
          ),
        ],
      );

      executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'port_brisants',
          entityId: 'npc_lysa',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => true,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      // Le flag ne doit pas être posé : le graphe s'arrête au battle node.
      expect(state.storyFlags.activeFlags,
          isNot(contains('should_not_be_set')));
    });
  });
}
