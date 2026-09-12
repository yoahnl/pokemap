import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/scenario_runtime/scenario_runtime_executor.dart';
import 'package:map_runtime/src/application/scenario_runtime/scenario_runtime_models.dart';

void main() {
  const executor = ScenarioRuntimeExecutor();
  const state = GameState(saveId: 'save');
  final entityEvent = ScenarioRuntimeSourceEvent.entityInteract(
    mapId: 'station',
    entityId: 'clerk',
  );
  final worldSources = [
    (
      event: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'station'),
      actionKind: kScenarioSourceMapEnter,
    ),
    (
      event: ScenarioRuntimeSourceEvent.triggerEnter(
        mapId: 'station',
        triggerId: 'platform',
      ),
      actionKind: kScenarioSourceTriggerEnter,
    ),
    (event: entityEvent, actionKind: kScenarioSourceEntityInteract),
  ];

  group('ScenarioRuntimeExecutor.selectSource', () {
    for (final source in worldSources) {
      test('${source.event.type.name} prioritizes local scenarios', () {
        final global = _scenario(
          'global',
          scope: ScenarioScope.globalStory,
          actionKind: source.actionKind,
        );
        final local = _scenario('local', actionKind: source.actionKind);

        final selection = executor.selectSource(
          scenarios: [global, local],
          sourceEvent: source.event,
          gameState: state,
        );

        expect(selection?.scenario, same(local));
        expect(selection?.sourceNode, same(local.nodes.first));
      });
    }

    test('outcomes prioritize global scenarios', () {
      final local = _scenario('local', actionKind: kScenarioSourceOutcome);
      final global = _scenario(
        'global',
        scope: ScenarioScope.globalStory,
        actionKind: kScenarioSourceOutcome,
      );

      final selection = executor.selectSource(
        scenarios: [local, global],
        sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'ticket.collected',
        ),
        gameState: state,
      );

      expect(selection?.scenario, same(global));
    });

    test('uses the other scope only when the preferred scope is absent', () {
      final global = _scenario('global', scope: ScenarioScope.globalStory);
      final localOutcome = _scenario(
        'local_outcome',
        actionKind: kScenarioSourceOutcome,
      );

      expect(
        executor.selectSource(
          scenarios: [global],
          sourceEvent: entityEvent,
          gameState: state,
        )?.scenario,
        same(global),
      );
      expect(
        executor.selectSource(
          scenarios: [localOutcome],
          sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
            outcomeId: 'ticket.collected',
          ),
          gameState: state,
        )?.scenario,
        same(localOutcome),
      );
      expect(
        executor.selectSource(
          scenarios: [global, localOutcome],
          sourceEvent: entityEvent,
          gameState: state,
        ),
        isNull,
      );
      expect(
        executor.selectSource(
          scenarios: [localOutcome, global],
          sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
            outcomeId: 'ticket.collected',
          ),
          gameState: state,
        ),
        isNull,
      );
    });

    test('preserves manifest and source node order', () {
      final first = _scenario('first');
      final duplicateSource = first.nodes.first.copyWith(id: 'second_source');
      final firstWithSources = first.copyWith(
        nodes: [first.nodes.first, duplicateSource, first.nodes.last],
      );

      final selection = executor.selectSource(
        scenarios: [firstWithSources, _scenario('second')],
        sourceEvent: entityEvent,
        gameState: state,
      );

      expect(selection?.scenario, same(firstWithSources));
      expect(selection?.sourceNode, same(first.nodes.first));
    });

    test('ignores inactive scenarios before calling the skip predicate', () {
      final gated = _scenario('gated').copyWith(
        activationCondition: _activation,
      );
      final fallback = _scenario('fallback');
      final skippedCandidates = <String>[];
      final countingEvaluator = _CountingConditionEvaluator();
      final selectingExecutor = ScenarioRuntimeExecutor(
        conditionEvaluator: countingEvaluator,
      );

      final selection = selectingExecutor.selectSource(
        scenarios: [gated, fallback],
        sourceEvent: entityEvent,
        gameState: state,
        shouldSkipScenario: (id) {
          skippedCandidates.add(id);
          return false;
        },
      );

      expect(selection?.scenario, same(fallback));
      expect(skippedCandidates, ['fallback']);
      expect(countingEvaluator.evaluated, [_activation]);
      expect(
        selectingExecutor.selectSource(
          scenarios: [gated, fallback],
          sourceEvent: entityEvent,
          gameState: state.copyWith(
            storyFlags: const StoryFlags(activeFlags: {'ticket.available'}),
          ),
        )?.scenario,
        same(gated),
      );
    });

    test('skips matched scenarios using the trimmed id', () {
      final visited = <String>[];
      final fallback = _scenario('fallback');

      final selection = executor.selectSource(
        scenarios: [
          _scenario('unmatched', entityId: 'other'),
          _scenario(' consumed '),
          fallback,
        ],
        sourceEvent: entityEvent,
        gameState: state,
        shouldSkipScenario: (id) {
          visited.add(id);
          return id == 'consumed';
        },
      );

      expect(selection?.scenario, same(fallback));
      expect(visited, ['consumed', 'fallback']);
      expect(
        executor.selectSource(
          scenarios: [fallback],
          sourceEvent: entityEvent,
          gameState: state,
          shouldSkipScenario: (_) => true,
        ),
        isNull,
      );
    });

    test('does not call the skip predicate for an empty scenario id', () {
      final scenario = _scenario(' ');
      final selection = executor.selectSource(
        scenarios: [scenario],
        sourceEvent: entityEvent,
        gameState: state,
        shouldSkipScenario: (_) => throw StateError('Unexpected skip call'),
      );

      expect(selection?.scenario, same(scenario));
    });

    test('returns null when no source matches the event', () {
      for (final scenarios in <List<ScenarioAsset>>[
        [],
        [_scenario('wrong_entity', entityId: 'other')],
        [_scenario('wrong_map', mapId: 'elsewhere')],
        [_scenario('wrong_type', actionKind: kScenarioSourceMapEnter)],
        [_scenario('no_sources').copyWith(nodes: [], edges: [])],
      ]) {
        expect(
          executor.selectSource(
            scenarios: scenarios,
            sourceEvent: entityEvent,
            gameState: state,
          ),
          isNull,
        );
      }
    });

    test('selects a matching source without requiring an executable graph', () {
      final scenario = _scenario('unconnected').copyWith(edges: []);

      final selection = executor.selectSource(
        scenarios: [scenario],
        sourceEvent: entityEvent,
        gameState: state,
      );

      expect(selection?.scenario, same(scenario));
      expect(selection?.sourceNode, same(scenario.nodes.first));
    });

    test('repeated consultation neither traverses nor executes the graph', () {
      final evaluator = _CountingConditionEvaluator();
      final selectingExecutor = ScenarioRuntimeExecutor(
        conditionEvaluator: evaluator,
      );
      final scenario = _effectfulScenario();
      final callbacks = <String>[];
      final initialState = state.copyWith(
        storyFlags: const StoryFlags(activeFlags: {'ticket.available'}),
      );
      final stateBefore = initialState.toJson();
      final scenarioBefore = scenario.toJson();
      final context = ScenarioRuntimeExecutionContext(
        gameState: initialState,
        onGameStateUpdated: (_) => callbacks.add('state'),
        openDialogue: (id, {startNode, runtimeSourceId}) {
          callbacks.add('dialogue:$id');
          return true;
        },
        runScript: (id, {startNode, runtimeSourceId}) {
          callbacks.add('script:$id');
          return true;
        },
        showMessage: (message) => callbacks.add('message:$message'),
      );

      for (var index = 0; index < 3; index++) {
        final selection = selectingExecutor.selectSource(
          scenarios: [scenario],
          sourceEvent: entityEvent,
          gameState: context.gameState,
        );

        expect(selection?.scenario, same(scenario));
        expect(selection?.sourceNode, same(scenario.nodes.first));
        expect(context.gameState, same(initialState));
        expect(context.gameState.toJson(), stateBefore);
        expect(scenario.toJson(), scenarioBefore);
        expect(callbacks, isEmpty);
      }
      expect(evaluator.evaluated, [_activation, _activation, _activation]);

      final dispatched = selectingExecutor.dispatch(
        scenarios: [scenario],
        sourceEvent: entityEvent,
        context: context,
      );

      expect(dispatched.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(callbacks, ['state', 'dialogue:ticket_dialogue']);
      expect(
          context.gameState.storyFlags.activeFlags, contains('ticket.taken'));
      expect(evaluator.evaluated, [
        _activation,
        _activation,
        _activation,
        _activation,
        _graphCondition,
      ]);
    });

    test('dispatch executes the selected source with one activation check', () {
      final evaluator = _CountingConditionEvaluator();
      final selectingExecutor = ScenarioRuntimeExecutor(
        conditionEvaluator: evaluator,
      );
      final chosen = _scenario('chosen').copyWith(
        activationCondition: const ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: {ScriptConditionParams.flagName: 'already_used'},
        ),
      );
      final scenarios = [_scenario('consumed'), chosen, _scenario('later')];
      bool skip(String id) => id == 'consumed';
      final ScenarioRuntimeSourceSelection? selection =
          selectingExecutor.selectSource(
        scenarios: scenarios,
        sourceEvent: entityEvent,
        gameState: state,
        shouldSkipScenario: skip,
      );
      evaluator.evaluated.clear();
      final messages = <String>[];

      final result = selectingExecutor.dispatch(
        scenarios: scenarios,
        sourceEvent: entityEvent,
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (_) => fail('Unexpected state update'),
          openDialogue: (id, {startNode, runtimeSourceId}) => false,
          runScript: (id, {startNode, runtimeSourceId}) => false,
          showMessage: messages.add,
          shouldSkipScenario: skip,
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.scenarioId, selection?.scenario.id);
      expect(result.sourceNodeId, selection?.sourceNode.id);
      expect(messages, ['chosen']);
      expect(evaluator.evaluated, [chosen.activationCondition]);
    });
  });
}

const _activation = ScriptCondition(
  type: ScriptConditionType.flagIsSet,
  params: {ScriptConditionParams.flagName: 'ticket.available'},
);

const _graphCondition = ScriptCondition(
  type: ScriptConditionType.flagIsSet,
  params: {ScriptConditionParams.flagName: 'ticket.taken'},
);

ScenarioAsset _scenario(
  String id, {
  ScenarioScope scope = ScenarioScope.localEventFlow,
  String actionKind = kScenarioSourceEntityInteract,
  String mapId = 'station',
  String entityId = 'clerk',
}) {
  return ScenarioAsset(
    id: id,
    name: id,
    scope: scope,
    entryNodeId: 'source_$id',
    nodes: [
      ScenarioNode(
        id: 'source_$id',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: actionKind),
        binding: ScenarioNodeBinding(
          mapId: mapId,
          entityId: entityId,
          triggerId: 'platform',
          outcomeId: 'ticket.collected',
        ),
      ),
      ScenarioNode(
        id: 'message_$id',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionShowMessage,
          message: id,
        ),
      ),
    ],
    edges: [
      ScenarioEdge(
        id: 'edge_$id',
        fromNodeId: 'source_$id',
        toNodeId: 'message_$id',
      ),
    ],
  );
}

ScenarioAsset _effectfulScenario() {
  final scenario = _scenario('effectful');
  return scenario.copyWith(
    activationCondition: _activation,
    nodes: [
      scenario.nodes.first,
      const ScenarioNode(
        id: 'take_ticket',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: 'ticket.taken'),
      ),
      const ScenarioNode(
        id: 'condition',
        type: ScenarioNodeType.condition,
        payload: ScenarioNodePayload(condition: _graphCondition),
      ),
      const ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(dialogueId: 'ticket_dialogue'),
      ),
    ],
    edges: [
      ScenarioEdge(
        id: 'e1',
        fromNodeId: scenario.nodes.first.id,
        toNodeId: 'take_ticket',
      ),
      const ScenarioEdge(
        id: 'e2',
        fromNodeId: 'take_ticket',
        toNodeId: 'condition',
      ),
      const ScenarioEdge(
        id: 'e3',
        fromNodeId: 'condition',
        toNodeId: 'dialogue',
        kind: ScenarioEdgeKind.trueBranch,
      ),
    ],
  );
}

class _CountingConditionEvaluator extends ScriptConditionEvaluator {
  final evaluated = <ScriptCondition>[];

  @override
  bool evaluate(
    ScriptCondition condition,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    evaluated.add(condition);
    return super.evaluate(condition, state, context: context);
  }
}
