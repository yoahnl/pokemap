import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_parallel_execution.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_writer.dart';

SceneAsset counter({bool failSecond = false}) => SceneAsset(
  id: 'counter',
  name: 'Counter',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'count',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.adjustIntegerFact(
            factId: 'count',
            delta: 1,
            minimum: 0,
            maximum: 20,
          ),
        ),
      ),
      if (failSecond)
        SceneNode(
          id: 'fail',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'missing', value: true),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'a',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'count',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'b',
        fromNodeId: 'count',
        fromPortId: 'completed',
        toNodeId: failSecond ? 'fail' : 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
      if (failSecond)
        SceneEdge(
          id: 'c',
          fromNodeId: 'fail',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

void main() {
  test('parallel inventory conditions require the authoritative item catalog', () {
    final scene = SceneAsset(id: 'inventory', name: 'Inventory', graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'condition', kind: SceneNodeKind.condition, payload: SceneConditionPayload(conditionSource: SceneConditionSource(
        sourceKind: SceneConditionSourceKind.inventoryItem, sourceId: 'missing-item', operator: SceneConditionOperator.isTrue))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(id: 'a', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'condition', kind: SceneEdgeKind.defaultFlow),
      SceneEdge(id: 'b', fromNodeId: 'condition', fromPortId: 'true', toNodeId: 'end', kind: SceneEdgeKind.conditionTrue),
      SceneEdge(id: 'c', fromNodeId: 'condition', fromPortId: 'false', toNodeId: 'end', kind: SceneEdgeKind.conditionFalse),
    ]));
    final writer = SceneConsequenceRuntimeWriter(project: const ProjectManifest(name: 'Parallel', maps: [], tilesets: []));
    expect(() => executeNarrativeParallelProgram(scene: scene, gameState: const GameState(saveId: 'save'), writer: writer), throwsStateError);
  });
  test(
    'finite cycle commits current fact values and has no execution cursor',
    () {
      final project = ProjectManifest(
        name: 'Parallel',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'count',
            label: 'Count',
            initialValue: NarrativeValue.integer(0),
          ),
        ],
      );
      final writer = SceneConsequenceRuntimeWriter(project: project);
      final initial = const GameState(saveId: 'save');
      final first = executeNarrativeParallelProgram(
        scene: counter(),
        gameState: initial,
        writer: writer,
      );
      final second = executeNarrativeParallelProgram(
        scene: counter(),
        gameState: first,
        writer: writer,
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
      final value = resolver.resolve(
        factId: 'count',
        runtimeState: second.narrativeFactRuntimeState,
        storyFlags: second.storyFlags,
      ) as NarrativeFactRuntimeResolved;
      expect(value.narrativeValue.intValue, 2);
      expect(second.narrativeEventProgress, initial.narrativeEventProgress);
    },
  );
  test('invalid second write never publishes first buffered write', () {
    final writer = SceneConsequenceRuntimeWriter(
      project: ProjectManifest(
        name: 'Parallel',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'count',
            label: 'Count',
            initialValue: NarrativeValue.integer(0),
          ),
        ],
      ),
    );
    final initial = const GameState(saveId: 'save');
    expect(
      () => executeNarrativeParallelProgram(
        scene: counter(failSecond: true),
        gameState: initial,
        writer: writer,
      ),
      throwsStateError,
    );
    expect(
      initial.narrativeFactRuntimeState,
      const GameState(saveId: 'save').narrativeFactRuntimeState,
    );
  });
}
