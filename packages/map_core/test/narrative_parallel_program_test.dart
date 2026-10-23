import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SceneAsset program({
  bool cycle = false,
  bool outcome = false,
  SceneConsequence? effect,
}) => SceneAsset(
  id: 'scene',
  name: 'Parallel',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (effect != null)
        SceneNode(
          id: 'action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(effect),
        ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: outcome ? 'done' : null),
      ),
    ],
    edges: [
      SceneEdge(
        kind: SceneEdgeKind.defaultFlow,
        id: 'a',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: effect != null ? 'action' : 'end',
      ),
      if (effect != null)
        SceneEdge(
          kind: SceneEdgeKind.actionCompleted,
          id: 'b',
          fromNodeId: 'action',
          fromPortId: 'completed',
          toNodeId: 'end',
        ),
      if (cycle)
        SceneEdge(
          kind: SceneEdgeKind.defaultFlow,
          id: 'c',
          fromNodeId: 'end',
          fromPortId: 'completed',
          toNodeId: 'start',
        ),
    ],
  ),
);

void main() {
  test('accepts finite state-only programs', () {
    expect(
      validateNarrativeParallelProgram(
        program(effect: SceneConsequence.setFact(factId: 'flag', value: true)),
      ),
      isEmpty,
    );
  });
  test('rejects cycles, outcome publication and nonstate effects', () {
    expect(validateNarrativeParallelProgram(program(cycle: true)), isNotEmpty);
    expect(
      validateNarrativeParallelProgram(program(outcome: true)),
      isNotEmpty,
    );
    expect(
      validateNarrativeParallelProgram(
        program(
          effect: SceneConsequence.adjustMoney(
            operation: SceneMoneyOperation.add,
            amount: SceneIntegerOperand.literal(1),
            minimum: 0,
            maximum: 100,
          ),
        ),
      ),
      isNotEmpty,
    );
  });
}
