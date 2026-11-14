import 'package:avelune_studio/features/scenes/application/steps/scene_step_list.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scene_step_fixtures.dart';
import 'scene_step_projection_fixtures.dart';

void main() {
  test('a linear scene becomes a flat list ending on its end node', () {
    final list = listOf(
      graphOf(
        [startNode(), factNode('a'), dialogueNode('b'), endNode('end')],
        [link('start', 'a'), link('a', 'b'), link('b', 'end')],
      ),
    );
    expect(ids(list.root), ['a', 'b']);
    expect(list.root.tail, const SceneStepTailEnd('end'));
    expect((list.root.steps.first as SceneLeafStep).portIds, ['completed']);
    expect(list.startPortIds, ['completed']);
  });

  test('a shared ending is projected once after the if / else block', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          conditionNode('if'),
          factNode('a'),
          factNode('b'),
          dialogueNode('after'),
          endNode('end'),
        ],
        [
          link('start', 'if'),
          link('if', 'a', port: 'true'),
          link('if', 'b', port: 'false'),
          link('a', 'after'),
          link('b', 'after'),
          link('after', 'end'),
        ],
      ),
    );
    expect(ids(list.root), ['if', 'after']);
    final block = blockAt(list.root, 0);
    expect(block.kind, SceneStepBlockKind.condition);
    expect(block.branches.map((branch) => branch.role), [
      SceneStepBranchRole.whenTrue,
      SceneStepBranchRole.whenFalse,
    ]);
    expect(ids(block.branches[0].sequence), ['a']);
    expect(ids(block.branches[1].sequence), ['b']);
    expect(block.branches[0].sequence.tail, const SceneStepTailContinue());
    expect(block.flowsOn, isTrue);
  });

  test('nested conditions keep their own continuation', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          conditionNode('outer'),
          conditionNode('inner'),
          factNode('a'),
          factNode('innerAfter'),
          factNode('outerAfter'),
          endNode('end'),
        ],
        [
          link('start', 'outer'),
          link('outer', 'inner', port: 'true'),
          link('outer', 'outerAfter', port: 'false'),
          link('inner', 'a', port: 'true'),
          link('inner', 'innerAfter', port: 'false'),
          link('a', 'innerAfter'),
          link('innerAfter', 'outerAfter'),
          link('outerAfter', 'end'),
        ],
      ),
    );
    expect(ids(list.root), ['outer', 'outerAfter']);
    final outer = blockAt(list.root, 0);
    expect(ids(outer.branches[0].sequence), ['inner', 'innerAfter']);
    expect(outer.branches[1].sequence.steps, isEmpty);
    final inner = blockAt(outer.branches[0].sequence, 0);
    expect(ids(inner.branches[0].sequence), ['a']);
    expect(inner.branches[1].sequence.steps, isEmpty);
  });

  test('an early exit to another end keeps the shared continuation', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          conditionNode('outer'),
          factNode('a'),
          conditionNode('guard'),
          endNode('early'),
          factNode('after'),
          endNode('end'),
        ],
        [
          link('start', 'outer'),
          link('outer', 'a', port: 'true'),
          link('outer', 'guard', port: 'false'),
          link('guard', 'early', port: 'true'),
          link('guard', 'after', port: 'false'),
          link('a', 'after'),
          link('after', 'end'),
        ],
      ),
    );
    expect(ids(list.root), ['outer', 'after']);
    final guard = blockAt(blockAt(list.root, 0).branches[1].sequence, 0);
    expect(guard.branches[0].sequence.tail, const SceneStepTailEnd('early'));
    expect(guard.branches[1].sequence.tail, const SceneStepTailContinue());
  });

  test('branches that all end on their own end nodes close the list', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          conditionNode('if'),
          factNode('a'),
          factNode('b'),
          endNode('endA'),
          endNode('endB'),
        ],
        [
          link('start', 'if'),
          link('if', 'a', port: 'true'),
          link('if', 'b', port: 'false'),
          link('a', 'endA'),
          link('b', 'endB'),
        ],
      ),
    );
    final block = blockAt(list.root, 0);
    expect(block.flowsOn, isFalse);
    expect(list.root.tail, const SceneStepTailOpen());
    expect(block.branches[0].sequence.tail, const SceneStepTailEnd('endA'));
    expect(block.branches[1].sequence.tail, const SceneStepTailEnd('endB'));
  });

  test('a merge node joining the branches is absorbed by its block', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          conditionNode('if'),
          factNode('a'),
          factNode('b'),
          mergeNode('join'),
          factNode('after'),
          endNode('end'),
        ],
        [
          link('start', 'if'),
          link('if', 'a', port: 'true'),
          link('if', 'b', port: 'false'),
          link('a', 'join'),
          link('b', 'join'),
          link('join', 'after'),
          link('after', 'end'),
        ],
      ),
    );
    expect(ids(list.root), ['if', 'after']);
    expect(blockAt(list.root, 0).mergeNodeId, 'join');
  });

  test('a mechanical failure becomes an on-failure list beside the flow', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          giveNode('give'),
          dialogueNode('full'),
          factNode('next'),
          endNode('end'),
        ],
        [
          link('start', 'give'),
          link('give', 'next', port: 'received'),
          link('give', 'full', port: 'bagFull'),
          link('full', 'end'),
          link('next', 'end'),
        ],
      ),
    );
    expect(ids(list.root), ['give', 'next']);
    final block = blockAt(list.root, 0);
    expect(block.kind, SceneStepBlockKind.failure);
    expect(block.branches.map((branch) => branch.role), [
      SceneStepBranchRole.main,
      SceneStepBranchRole.failure,
    ]);
    expect(block.branches[0].sequence.steps, isEmpty);
    expect(ids(block.branches[1].sequence), ['full']);
    expect(block.branches[1].sequence.tail, const SceneStepTailEnd('end'));
  });

  test('a failure branch rejoining the enclosing flow is not inlined', () {
    final list = listOf(
      graphOf(
        [
          startNode(),
          conditionNode('if'),
          giveNode('give'),
          factNode('thanks'),
          factNode('after'),
          endNode('end'),
          endNode('end2'),
        ],
        [
          link('start', 'if'),
          link('if', 'give', port: 'true'),
          link('if', 'after', port: 'false'),
          link('give', 'thanks', port: 'received'),
          link('give', 'after', port: 'bagFull'),
          link('thanks', 'end2'),
          link('after', 'end'),
        ],
      ),
    );
    expect(ids(list.root), ['if', 'after']);
    final give = blockAt(blockAt(list.root, 0).branches[0].sequence, 0);
    expect(ids(give.branches[0].sequence), ['thanks']);
    expect(give.branches[1].sequence.tail, const SceneStepTailContinue());
  });

  test('failure ports leading to the same step stay a single step', () {
    final list = listOf(
      graphOf(
        [startNode(), giveNode('give'), endNode('end')],
        [
          link('start', 'give'),
          link('give', 'end', port: 'received'),
          link('give', 'end', port: 'bagFull'),
        ],
      ),
    );
    final step = list.root.steps.single as SceneLeafStep;
    expect(step.portIds, ['received', 'bagFull']);
  });
}
