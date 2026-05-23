import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

// ignore_for_file: prefer_const_constructors

void main() {
  group('ScenarioRuntimeExecutor - completeStep action', () {
    const executor = ScenarioRuntimeExecutor();

    ScenarioRuntimeExecutionContext makeContext({
      required GameState state,
      required void Function(GameState) onUpdate,
    }) {
      return ScenarioRuntimeExecutionContext(
        gameState: state,
        onGameStateUpdated: onUpdate,
        openDialogue: (_, {startNode, runtimeSourceId}) => false,
        runScript: (_, {startNode, runtimeSourceId}) => false,
        showMessage: (_) {},
      );
    }

    ScenarioAsset makeScenario({
      required Map<String, String> params,
    }) {
      return ScenarioAsset(
        id: 'test_scenario',
        name: 'Test',
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(
              mapId: 'test_map',
              entityId: 'test_entity',
            ),
          ),
          ScenarioNode(
            id: 'complete',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionCompleteStep,
              params: params,
            ),
          ),
          ScenarioNode(
            id: 'end',
            type: ScenarioNodeType.end,
          ),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
              id: 'e1', fromNodeId: 'source', toNodeId: 'complete'),
          ScenarioEdge(
              id: 'e2', fromNodeId: 'complete', toNodeId: 'end'),
        ],
      );
    }

    ScenarioRuntimeExecutionResult dispatch(
      ScenarioAsset scenario,
      ScenarioRuntimeExecutionContext context,
    ) {
      return executor.dispatch(
        scenarios: [scenario],
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'test_map',
          entityId: 'test_entity',
        ),
        context: context,
      );
    }

    test('completeStep action completes a step', () {
      final scenario = makeScenario(params: {'stepId': 'test_step_intro'});
      var state = const GameState(saveId: 'test');
      dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );

      expect(state.progression.completedStepIds, ['test_step_intro']);
    });

    test('completeStep action advances the graph', () {
      final scenario = makeScenario(params: {'stepId': 'test_step'});
      var state = const GameState(saveId: 'test');
      final result = dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );

      // Reaches the 'end' node after completing the step.
      expect(result.success, isTrue);
    });

    test('completeStep action calls onGameStateUpdated', () {
      final scenario = makeScenario(params: {'stepId': 'test_step'});
      var state = const GameState(saveId: 'test');
      GameState? updatedState;
      dispatch(
        scenario,
        makeContext(
          state: state,
          onUpdate: (next) {
            state = next;
            updatedState = next;
          },
        ),
      );

      expect(updatedState, isNotNull);
      expect(
        updatedState!.progression.completedStepIds,
        contains('test_step'),
      );
    });

    test('completeStep action blocks when stepId missing', () {
      final scenario = makeScenario(params: {});
      var state = const GameState(saveId: 'test');
      final result = dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(state.progression.completedStepIds, isEmpty);
    });

    test('completeStep action blocks when stepId is blank', () {
      final scenario = makeScenario(params: {'stepId': '   '});
      var state = const GameState(saveId: 'test');
      final result = dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(state.progression.completedStepIds, isEmpty);
    });

    test('completeStep action is idempotent when run twice', () {
      final scenario = makeScenario(params: {'stepId': 'test_step'});
      var state = const GameState(saveId: 'test');

      // First dispatch.
      dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );
      expect(state.progression.completedStepIds, hasLength(1));

      // Second dispatch: still 1 entry, no duplicate.
      dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );
      expect(state.progression.completedStepIds, hasLength(1));
      expect(state.progression.completedStepIds, ['test_step']);
    });

    test('completeStep feeds stepCompleted predicate', () {
      final scenario = makeScenario(params: {'stepId': 'test_step'});
      var state = const GameState(saveId: 'test');
      dispatch(
        scenario,
        makeContext(state: state, onUpdate: (next) => state = next),
      );

      // Verify the predicate evaluator reads the completed step.
      final evaluator = MapEntityRuntimePredicateEvaluator(
        gameState: state,
        chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
      );

      expect(
        evaluator.evaluatePredicate(
          MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 'test_step',
          ),
        ),
        isTrue,
      );

      expect(
        evaluator.evaluatePredicate(
          MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepNotCompleted,
            refId: 'test_step',
          ),
        ),
        isFalse,
      );
    });

    test('uncompleted step feeds stepNotCompleted predicate', () {
      var state = const GameState(saveId: 'test');

      final evaluator = MapEntityRuntimePredicateEvaluator(
        gameState: state,
        chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
      );

      expect(
        evaluator.evaluatePredicate(
          MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepNotCompleted,
            refId: 'test_step',
          ),
        ),
        isTrue,
      );

      expect(
        evaluator.evaluatePredicate(
          MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 'test_step',
          ),
        ),
        isFalse,
      );
    });
  });
}
