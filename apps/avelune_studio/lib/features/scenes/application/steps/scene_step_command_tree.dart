part of 'scene_step_commands.dart';

typedef _Addition = ({SceneNode node, String anchor});

typedef _Location = ({
  String? blockNodeId,
  int branchIndex,
  int index,
  SceneStep step,
});

SceneStepEditResult _commit(
  SceneAsset scene,
  SceneStepList list,
  SceneStepSequence editedRoot, {
  required SceneStepIds ids,
  List<_Addition> added = const [],
  Set<String> removed = const {},
}) {
  final root = _normalise(editedRoot);
  final existingIds = {for (final node in scene.graph.nodes) node.id};
  final addedIds = [for (final addition in added) addition.node.id];
  if (addedIds.any(existingIds.contains) ||
      addedIds.toSet().length != addedIds.length) {
    return const SceneStepEditRefused(SceneStepEditRefusal.idCollision);
  }
  final referencedEnds = root.endNodeIds.toSet();
  final orphanEnds = [
    for (final id in list.root.endNodeIds.toSet())
      if (!referencedEnds.contains(id)) id,
  ];
  final keptEnds = scene.graph.nodes.where(
    (node) =>
        node.kind == SceneNodeKind.end &&
        !removed.contains(node.id) &&
        !orphanEnds.contains(node.id),
  );
  final allRemoved = {
    ...removed,
    ...(keptEnds.isEmpty ? orphanEnds.skip(1) : orphanEnds),
  };
  for (final node in scene.graph.nodes) {
    if (allRemoved.contains(node.id)) continue;
    final payload = node.payload;
    if (payload is ScenePresentationCinematicPayload &&
        payload.interactionCueBindings.any(
          (binding) => allRemoved.contains(binding.awaitableNodeId),
        )) {
      return const SceneStepEditRefused(
        SceneStepEditRefusal.referencedByPresentation,
      );
    }
    if (payload is SceneBranchByOutcomePayload &&
        allRemoved.contains(payload.sourceNodeId)) {
      return const SceneStepEditRefused(
        SceneStepEditRefusal.referencedByRouter,
      );
    }
  }
  final SceneGraph graph;
  final SceneAsset edited;
  try {
    graph = buildSceneStepGraph(
      original: scene.graph,
      root: root,
      startPortIds: list.startPortIds,
      addedNodes: [for (final addition in added) addition.node],
      removedNodeIds: allRemoved,
      newEdgeId: ids.edge,
    );
    final edgeIds = {for (final edge in graph.edges) edge.id};
    final layouts = [
      for (final layout in scene.layout.nodeLayouts)
        if (!allRemoved.contains(layout.nodeId)) layout,
    ];
    for (final addition in added) {
      layouts.add(_placeAfter(layouts, addition, graph.nodes.length));
    }
    edited = SceneAsset(
      id: scene.id,
      name: scene.name,
      executionProfile: scene.executionProfile,
      description: scene.description,
      storylineId: scene.storylineId,
      chapterId: scene.chapterId,
      tags: scene.tags,
      graph: graph,
      layout: SceneGraphLayout(
        nodeLayouts: layouts,
        edgeLayouts: [
          for (final layout in scene.layout.edgeLayouts)
            if (edgeIds.contains(layout.edgeId)) layout,
        ],
      ),
      declaredOutcomes: scene.declaredOutcomes,
      metadata: scene.metadata,
    );
  } on ValidationException {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  } on ArgumentError {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  }
  final projected = projectSceneSteps(edited.graph);
  if (projected is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notRepresentable);
  }
  return SceneStepEdited(
    scene: edited,
    steps: projected,
    createdNodeIds: addedIds,
    removedNodeIds: [
      for (final node in scene.graph.nodes)
        if (allRemoved.contains(node.id)) node.id,
    ],
  );
}

SceneNodeLayout _placeAfter(
  List<SceneNodeLayout> layouts,
  _Addition addition,
  int nodeCount,
) {
  SceneNodeLayout? source;
  for (final layout in layouts) {
    if (layout.nodeId == addition.anchor) source = layout;
  }
  if (source == null && layouts.isNotEmpty) {
    source = layouts.reduce((a, b) => b.x > a.x ? b : a);
  }
  if (source != null) {
    return SceneNodeLayout(
      nodeId: addition.node.id,
      x: source.x + 300,
      y: source.y,
    );
  }
  return SceneNodeLayout(
    nodeId: addition.node.id,
    x: 24 + nodeCount * 300,
    y: 80,
  );
}

String _anchorOf(
  SceneStepList list,
  SceneStepSequence sequence,
  SceneStepSlot slot,
) {
  if (slot.index > 0) return sequence.steps[slot.index - 1].nodeId;
  return slot.blockNodeId ?? list.graph.startNodeId;
}

SceneStepEditRefusal? _slotRefusal(SceneStepSequence sequence, int index) {
  if (index < 0 || index > sequence.steps.length) {
    return SceneStepEditRefusal.indexOutOfRange;
  }
  if (index > 0 && !sequence.steps[index - 1].flowsOn) {
    return SceneStepEditRefusal.unreachablePosition;
  }
  return null;
}

SceneBlockStep _emptyCondition(String nodeId) => SceneBlockStep(
  nodeId: nodeId,
  kind: SceneStepBlockKind.condition,
  branches: [
    SceneStepBranch(
      portIds: const ['true'],
      role: SceneStepBranchRole.whenTrue,
      sequence: SceneStepSequence(),
    ),
    SceneStepBranch(
      portIds: const ['false'],
      role: SceneStepBranchRole.whenFalse,
      sequence: SceneStepSequence(),
    ),
  ],
);

SceneStepSequence _without(SceneStepSequence sequence, int index) {
  final step = sequence.steps[index];
  final steps = [...sequence.steps]..removeAt(index);
  var tail = sequence.tail;
  if (index == sequence.steps.length - 1 &&
      !step.flowsOn &&
      tail is SceneStepTailOpen) {
    final end = SceneStepSequence(steps: [step]).endNodeIds.firstOrNull;
    if (end != null) tail = SceneStepTailEnd(end);
  }
  return SceneStepSequence(steps: steps, tail: tail);
}

SceneStepSequence _normalise(SceneStepSequence sequence) {
  final steps = [
    for (final step in sequence.steps)
      if (step is SceneBlockStep)
        step.withBranches([
          for (final branch in step.branches)
            branch.withSequence(_normalise(branch.sequence)),
        ])
      else
        step,
  ];
  final closed = steps.isNotEmpty && !steps.last.flowsOn;
  return SceneStepSequence(
    steps: steps,
    tail: closed ? const SceneStepTailOpen() : sequence.tail,
  );
}

Iterable<SceneStep> _subtree(SceneStep step) sync* {
  yield step;
  if (step is SceneBlockStep) {
    for (final branch in step.branches) {
      yield* branch.sequence.allSteps;
    }
  }
}

SceneStepSequence? _sequenceAt(
  SceneStepSequence root,
  String? blockNodeId,
  int branchIndex,
) {
  if (blockNodeId == null) return root;
  for (final step in root.allSteps) {
    if (step is SceneBlockStep && step.nodeId == blockNodeId) {
      if (branchIndex < 0 || branchIndex >= step.branches.length) return null;
      return step.branches[branchIndex].sequence;
    }
  }
  return null;
}

SceneStepSequence _replaceSequence(
  SceneStepSequence sequence,
  String? blockNodeId,
  int branchIndex,
  SceneStepSequence Function(SceneStepSequence) change,
) {
  if (blockNodeId == null) return change(sequence);
  return sequence.copyWith(
    steps: [
      for (final step in sequence.steps)
        if (step is SceneBlockStep)
          step.withBranches([
            for (final (index, branch) in step.branches.indexed)
              branch.withSequence(
                step.nodeId == blockNodeId && index == branchIndex
                    ? change(branch.sequence)
                    : _replaceSequence(
                        branch.sequence,
                        blockNodeId,
                        branchIndex,
                        change,
                      ),
              ),
          ])
        else
          step,
    ],
  );
}

_Location? _locate(
  SceneStepSequence sequence,
  String nodeId,
  String? blockNodeId,
  int branchIndex,
) {
  for (final (index, step) in sequence.steps.indexed) {
    if (step.nodeId == nodeId) {
      return (
        blockNodeId: blockNodeId,
        branchIndex: branchIndex,
        index: index,
        step: step,
      );
    }
    if (step is SceneBlockStep) {
      for (final (branch, child) in step.branches.indexed) {
        final found = _locate(child.sequence, nodeId, step.nodeId, branch);
        if (found != null) return found;
      }
    }
  }
  return null;
}
