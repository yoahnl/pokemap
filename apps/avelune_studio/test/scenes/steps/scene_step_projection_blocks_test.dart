import 'package:avelune_studio/features/scenes/application/steps/scene_step_list.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_step_fixtures.dart';
import 'scene_step_projection_fixtures.dart';

void main() {
  test('a branch-by-outcome router is absorbed by its source step', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          soundNode('sound'),
          routerNode('result', 'sound'),
          factNode('a'),
          dialogueNode('muted'),
          endNode('end'),
        ],
        [
          link('start', 'sound'),
          link('sound', 'result'),
          link('sound', 'result', port: 'blocked'),
          link('result', 'a'),
          link('result', 'muted', port: 'blocked'),
          link('a', 'end'),
          link('muted', 'a'),
        ],
      ),
    );
    expect(ids(list.root), ['sound', 'a']);
    final block = blockAt(list.root, 0);
    expect(block.routerNodeId, 'result');
    expect(block.kind, SceneStepBlockKind.failure);
    expect(ids(block.branches[1].sequence), ['muted']);
  });

  test('dialogue outcomes and battle outcomes become per-outcome blocks', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          dialogueNode('ask', ['yes', 'no']),
          battleNode('fight'),
          factNode('won'),
          factNode('lost'),
          dialogueNode('bye'),
          endNode('end'),
        ],
        [
          link('start', 'ask'),
          link('ask', 'fight', port: 'yes'),
          link('ask', 'bye', port: 'no'),
          link('fight', 'won', port: 'victory'),
          link('fight', 'lost', port: 'defeat'),
          link('won', 'bye'),
          link('lost', 'bye'),
          link('bye', 'end'),
        ],
      ),
    );
    final ask = blockAt(list.root, 0);
    expect(ask.kind, SceneStepBlockKind.outcomes);
    expect(ask.branches.map((branch) => branch.portIds), [
      ['yes'],
      ['no'],
    ]);
    final fight = blockAt(ask.branches[0].sequence, 0);
    expect(fight.kind, SceneStepBlockKind.outcomes);
    expect(fight.branches.first.role, SceneStepBranchRole.main);
    expect(ids(list.root), ['ask', 'bye']);
  });

  test('an unconnected port keeps an open branch', () {
    final list = listOf(
      graphOf(
        [startNode(), conditionNode('if'), factNode('a'), endNode('end')],
        [link('start', 'if'), link('if', 'a', port: 'true'), link('a', 'end')],
      ),
    );
    final block = blockAt(list.root, 0);
    expect(block.branches[1].sequence.tail, const SceneStepTailOpen());
  });

  test('an unused end node without links does not prevent the list', () {
    final list = listOf(
      graphOf(
        [startNode(), factNode('a'), endNode('end'), endNode('spare')],
        [link('start', 'a'), link('a', 'end')],
      ),
    );
    expect(list.unusedEndNodeIds, ['spare']);
  });

  test('a cycle is reported as a loop with its nodes', () {
    final projection = projectSceneSteps(
      graphOf(
        [startNode(), pcNode('a'), factNode('b'), endNode('end')],
        [
          link('start', 'a'),
          link('a', 'b'),
          link('b', 'a'),
          link('a', 'end', port: 'cancelled'),
        ],
      ),
    );
    expect(projection, isA<SceneStepLoop>());
    expect((projection as SceneStepLoop).cycleNodeIds, ['a', 'b']);
    expect(projection.nodeCount, 4);
  });

  test(
    'two steps converging on two different continuations is a true graph',
    () {
      final projection = projectSceneSteps(
        graphOf(
          [
            startNode(),
            conditionNode('asked'),
            dialogueNode('first', ['yes', 'no']),
            dialogueNode('again', ['yes', 'no']),
            factNode('accept'),
            factNode('refuse'),
            endNode('end'),
          ],
          [
            link('start', 'asked'),
            link('asked', 'first', port: 'false'),
            link('asked', 'again', port: 'true'),
            link('first', 'accept', port: 'yes'),
            link('first', 'refuse', port: 'no'),
            link('again', 'accept', port: 'yes'),
            link('again', 'refuse', port: 'no'),
            link('accept', 'end'),
            link('refuse', 'end'),
          ],
        ),
      );
      expect(projection, isA<SceneStepTrueGraph>());
      final trueGraph = projection as SceneStepTrueGraph;
      expect(trueGraph.reason, SceneStepGraphReason.ambiguousJoin);
      expect(trueGraph.nodeIds.toSet(), {'accept', 'refuse'});
      expect(trueGraph.nodeCount, 7);
    },
  );

  test('a step reached from two nested blocks with other joins is shared', () {
    final projection = projectSceneSteps(
      graphOf(
        [
          startNode(),
          conditionNode('daily'),
          pcNode('shake'),
          dialogueNode('claim', ['x', 'y', 'z']),
          factNode('already'),
          factNode('blocked'),
          endNode('end'),
        ],
        [
          link('start', 'daily'),
          link('daily', 'shake', port: 'true'),
          link('daily', 'already', port: 'false'),
          link('shake', 'claim'),
          link('shake', 'blocked', port: 'cancelled'),
          link('claim', 'end', port: 'x'),
          link('claim', 'already', port: 'y'),
          link('claim', 'blocked', port: 'z'),
          link('already', 'end'),
          link('blocked', 'end'),
        ],
      ),
    );
    expect(projection, isA<SceneStepTrueGraph>());
    expect(
      (projection as SceneStepTrueGraph).reason,
      SceneStepGraphReason.sharedStep,
    );
  });

  test('shapes outside nested lists fall back to a true graph', () {
    SceneStepGraphReason reasonOf(SceneGraph graph) =>
        (projectSceneSteps(graph) as SceneStepTrueGraph).reason;

    expect(
      reasonOf(
        graphOf(
          [startNode(), startNode('other'), factNode('a'), endNode('end')],
          [link('start', 'a'), link('other', 'a'), link('a', 'end')],
        ),
      ),
      SceneStepGraphReason.multipleEntry,
    );
    expect(
      reasonOf(
        graphOf(
          [startNode(), factNode('a'), factNode('lost'), endNode('end')],
          [link('start', 'a'), link('a', 'end'), link('lost', 'end')],
        ),
      ),
      SceneStepGraphReason.unreachableNodes,
    );
    expect(
      reasonOf(
        graphOf(
          [startNode(), factNode('a'), endNode('end'), endNode('other')],
          [
            link('start', 'a'),
            link('a', 'end'),
            SceneEdge(
              id: 'twin',
              fromNodeId: 'a',
              fromPortId: 'completed',
              toNodeId: 'other',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      ),
      SceneStepGraphReason.portFanOut,
    );
  });

  test('nodes without a modelled command stay visible as steps', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          SceneNode(
            id: 'show',
            kind: SceneNodeKind.presentationCinematic,
            payload: ScenePresentationCinematicPayload(
              presentationCinematicId: 'intro',
            ),
          ),
          SceneNode(
            id: 'legacy',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(actionKind: 'custom'),
          ),
          endNode('end'),
        ],
        [link('start', 'show'), link('show', 'legacy'), link('legacy', 'end')],
      ),
    );
    expect(ids(list.root), ['show', 'legacy']);
  });
}
