import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_step_fixtures.dart';
import 'scene_step_commands_fixtures.dart';

void main() {
  test('inserting a step reuses the incoming link and appends new ids', () {
    final before = linearScene();
    final result = edited(
      insertSceneStep(
        before,
        at: const SceneStepSlot(index: 1),
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.wait(durationMs: 5),
        ),
        ids: countingIds(),
      ),
    );
    expect(result.createdNodeIds, ['new_node_1']);
    expect(rootIds(result), ['a', 'new_node_1', 'b', 'c']);
    final scene = result.scene;
    expect(edgeFrom(scene, 'a', 'completed').id, 'a.completed');
    expect(edgeFrom(scene, 'a', 'completed').toNodeId, 'new_node_1');
    expect(edgeFrom(scene, 'new_node_1', 'completed').id, 'new_edge_1');
    expect(edgeFrom(scene, 'new_node_1', 'completed').toNodeId, 'b');
    expect(
      scene.graph.nodes.take(5).toList(),
      before.graph.nodes,
      reason: 'existing nodes keep their order and content',
    );
    expect(scene.graph.nodes.last.id, 'new_node_1');
    final anchor = layoutOf(before, 'a');
    expect(layoutOf(scene, 'new_node_1').x, anchor.x + 300);
    expect(layoutOf(scene, 'new_node_1').y, anchor.y);
    for (final layout in before.layout.nodeLayouts) {
      expect(layoutOf(scene, layout.nodeId), layout);
    }
    expect(scene.layout.edgeLayouts, before.layout.edgeLayouts);
  });

  test('inserting at the end of a nested branch links it to the join', () {
    final result = edited(
      insertSceneStep(
        branchingScene(),
        at: const SceneStepSlot(blockNodeId: 'if', index: 1),
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.openPc(),
        ),
        ids: countingIds(),
      ),
    );
    final branch = (result.steps.root.steps.first as SceneBlockStep)
        .branches
        .first
        .sequence;
    expect([for (final step in branch.steps) step.nodeId], ['a', 'new_node_1']);
    expect(edgeFrom(result.scene, 'a', 'completed').toNodeId, 'new_node_1');
    expect(edgeFrom(result.scene, 'new_node_1', 'completed').toNodeId, 'after');
    expect(edgeFrom(result.scene, 'new_node_1', 'cancelled').toNodeId, 'after');
  });

  test('inserting a condition creates an empty if / else block', () {
    final result = edited(
      insertSceneStep(
        linearScene(),
        at: const SceneStepSlot(index: 3),
        kind: SceneNodeKind.condition,
        payload: weekdayCondition(),
        ids: countingIds(),
      ),
    );
    final block = result.steps.root.steps.last as SceneBlockStep;
    expect(block.nodeId, 'new_node_1');
    expect(block.branches.map((branch) => branch.sequence.steps), [
      isEmpty,
      isEmpty,
    ]);
    expect(edgeFrom(result.scene, 'new_node_1', 'true').toNodeId, 'end');
    expect(edgeFrom(result.scene, 'new_node_1', 'false').toNodeId, 'end');
  });

  test('removing a step links its predecessor to its successor', () {
    final before = linearScene();
    final result = edited(
      removeSceneStep(before, nodeId: 'b', ids: countingIds()),
    );
    expect(rootIds(result), ['a', 'c']);
    expect(result.removedNodeIds, ['b']);
    expect(edgeFrom(result.scene, 'a', 'completed').id, 'a.completed');
    expect(edgeFrom(result.scene, 'a', 'completed').toNodeId, 'c');
    expect(
      result.scene.layout.nodeLayouts.map((layout) => layout.nodeId),
      isNot(contains('b')),
    );
    expect(
      result.scene.layout.edgeLayouts.map((layout) => layout.edgeId),
      isNot(contains('b.completed')),
    );
  });

  test('removing a block removes its content and its orphan end only', () {
    final result = edited(
      removeSceneStep(branchingScene(), nodeId: 'if', ids: countingIds()),
    );
    expect(rootIds(result), ['after']);
    expect(result.removedNodeIds, ['if', 'a', 'early', 'guard']);
    expect(edgeFrom(result.scene, 'start', 'completed').toNodeId, 'after');
  });

  test('moving a step within its list and across lists keeps every id', () {
    final within = edited(
      moveSceneStep(
        linearScene(),
        nodeId: 'a',
        to: const SceneStepSlot(index: 3),
        ids: countingIds(),
      ),
    );
    expect(rootIds(within), ['b', 'c', 'a']);
    expect(within.createdNodeIds, isEmpty);
    expect(
      within.scene.graph.nodes.map((node) => node.id),
      linearScene().graph.nodes.map((node) => node.id),
    );

    final across = edited(
      moveSceneStep(
        branchingScene(),
        nodeId: 'after',
        to: const SceneStepSlot(blockNodeId: 'if', index: 0),
        ids: countingIds(),
      ),
    );
    final block = across.steps.root.steps.single as SceneBlockStep;
    expect(
      [for (final step in block.branches.first.sequence.steps) step.nodeId],
      ['after', 'a'],
    );
    expect(block.branches.first.sequence.tail, const SceneStepTailEnd('end'));
    expect(edgeFrom(across.scene, 'after', 'completed').toNodeId, 'a');
    expect(edgeFrom(across.scene, 'a', 'completed').toNodeId, 'end');
    expect(edgeFrom(across.scene, 'guard', 'false').toNodeId, 'end');
    expect(edgeFrom(across.scene, 'if', 'true').toNodeId, 'after');
  });

  test('wrapping steps in a condition nests them under « si »', () {
    final result = edited(
      wrapSceneStepsInCondition(
        linearScene(),
        from: const SceneStepSlot(index: 1),
        count: 2,
        condition: weekdayCondition(),
        ids: countingIds(),
      ),
    );
    expect(rootIds(result), ['a', 'new_node_1']);
    final block = result.steps.root.steps.last as SceneBlockStep;
    expect(
      [for (final step in block.branches.first.sequence.steps) step.nodeId],
      ['b', 'c'],
    );
    expect(block.branches.last.sequence.steps, isEmpty);
    expect(edgeFrom(result.scene, 'new_node_1', 'false').toNodeId, 'end');
    expect(edgeFrom(result.scene, 'c', 'completed').toNodeId, 'end');
  });

  test('commands are refused on loops and true graphs', () {
    final loop = sceneOf(
      [startNode(), pcNode('a'), waitNode('b'), endNode('end')],
      [
        link('start', 'a'),
        link('a', 'b'),
        link('b', 'a'),
        link('a', 'end', port: 'cancelled'),
      ],
    );
    expect(
      refused(removeSceneStep(loop, nodeId: 'b', ids: countingIds())),
      SceneStepEditRefusal.notAList,
    );
    expect(
      refused(
        insertSceneStep(
          loop,
          at: const SceneStepSlot(index: 0),
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.openPc(),
          ),
          ids: countingIds(),
        ),
      ),
      SceneStepEditRefusal.notAList,
    );
  });

  test('impossible positions and identities are refused', () {
    final closed = sceneOf(
      [startNode(), conditionNode('if'), endNode('endA'), endNode('endB')],
      [
        link('start', 'if'),
        link('if', 'endA', port: 'true'),
        link('if', 'endB', port: 'false'),
      ],
    );
    expect(
      refused(
        insertSceneStep(
          closed,
          at: const SceneStepSlot(index: 1),
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.openPc(),
          ),
          ids: countingIds(),
        ),
      ),
      SceneStepEditRefusal.unreachablePosition,
    );
    expect(
      refused(
        moveSceneStep(
          branchingScene(),
          nodeId: 'if',
          to: const SceneStepSlot(blockNodeId: 'guard', index: 0),
          ids: countingIds(),
        ),
      ),
      SceneStepEditRefusal.intoItself,
    );
    expect(
      refused(
        insertSceneStep(
          linearScene(),
          at: const SceneStepSlot(index: 0),
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.openPc(),
          ),
          ids: SceneStepIds(node: () => 'b', edge: () => 'x'),
        ),
      ),
      SceneStepEditRefusal.idCollision,
    );
    expect(
      refused(
        removeSceneStep(linearScene(), nodeId: 'end', ids: countingIds()),
      ),
      SceneStepEditRefusal.unknownStep,
    );
    expect(
      refused(
        insertSceneStep(
          linearScene(),
          at: const SceneStepSlot(index: 9),
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.openPc(),
          ),
          ids: countingIds(),
        ),
      ),
      SceneStepEditRefusal.indexOutOfRange,
    );
  });
}
