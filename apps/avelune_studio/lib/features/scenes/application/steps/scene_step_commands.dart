import 'package:map_core/map_core_domain.dart';

import 'scene_step_list.dart';
import 'scene_step_projection.dart';
import 'scene_step_rebuild.dart';

part 'scene_step_command_tree.dart';

enum SceneStepEditRefusal {
  notAList,
  unknownSequence,
  indexOutOfRange,
  unknownStep,
  unsupportedNodeKind,
  invalidNode,
  unreachablePosition,
  intoItself,
  referencedByPresentation,
  referencedByRouter,
  idCollision,
  notRepresentable,
}

sealed class SceneStepEditResult {
  const SceneStepEditResult();
}

final class SceneStepEdited extends SceneStepEditResult {
  SceneStepEdited({
    required this.scene,
    required this.steps,
    List<String> createdNodeIds = const [],
    List<String> removedNodeIds = const [],
  }) : createdNodeIds = List.unmodifiable(createdNodeIds),
       removedNodeIds = List.unmodifiable(removedNodeIds);

  final SceneAsset scene;
  final SceneStepList steps;
  final List<String> createdNodeIds;
  final List<String> removedNodeIds;
}

final class SceneStepEditRefused extends SceneStepEditResult {
  const SceneStepEditRefused(this.reason);

  final SceneStepEditRefusal reason;
}

final class SceneStepIds {
  const SceneStepIds({required this.node, required this.edge});

  final String Function() node;
  final String Function() edge;
}

final class SceneStepSlot {
  const SceneStepSlot({
    this.blockNodeId,
    this.branchIndex = 0,
    required this.index,
  });

  final String? blockNodeId;
  final int branchIndex;
  final int index;
}

SceneStepEditResult insertSceneStep(
  SceneAsset scene, {
  required SceneStepSlot at,
  required SceneNodeKind kind,
  SceneNodePayload? payload,
  String? title,
  required SceneStepIds ids,
}) {
  final list = projectSceneSteps(scene.graph);
  if (list is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notAList);
  }
  if (const {
    SceneNodeKind.start,
    SceneNodeKind.end,
    SceneNodeKind.merge,
    SceneNodeKind.branchByOutcome,
  }.contains(kind)) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unsupportedNodeKind);
  }
  final sequence = _sequenceAt(list.root, at.blockNodeId, at.branchIndex);
  if (sequence == null) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unknownSequence);
  }
  final refusal = _slotRefusal(sequence, at.index);
  if (refusal != null) return SceneStepEditRefused(refusal);
  final SceneNode node;
  try {
    node = SceneNode(
      id: ids.node(),
      kind: kind,
      title: title,
      payload: payload,
    );
  } on ArgumentError {
    return const SceneStepEditRefused(SceneStepEditRefusal.invalidNode);
  } on ValidationException {
    return const SceneStepEditRefused(SceneStepEditRefusal.invalidNode);
  }
  final SceneStep step = kind == SceneNodeKind.condition
      ? _emptyCondition(node.id)
      : SceneLeafStep(nodeId: node.id);
  final root = _replaceSequence(
    list.root,
    at.blockNodeId,
    at.branchIndex,
    (current) =>
        current.copyWith(steps: [...current.steps]..insert(at.index, step)),
  );
  return _commit(
    scene,
    list,
    root,
    ids: ids,
    added: [(node: node, anchor: _anchorOf(list, sequence, at))],
  );
}

SceneStepEditResult wrapSceneStepsInCondition(
  SceneAsset scene, {
  required SceneStepSlot from,
  required int count,
  required SceneConditionPayload condition,
  String? title,
  required SceneStepIds ids,
}) {
  final list = projectSceneSteps(scene.graph);
  if (list is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notAList);
  }
  final sequence = _sequenceAt(list.root, from.blockNodeId, from.branchIndex);
  if (sequence == null) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unknownSequence);
  }
  if (count < 0 || from.index + count > sequence.steps.length) {
    return const SceneStepEditRefused(SceneStepEditRefusal.indexOutOfRange);
  }
  final refusal = _slotRefusal(sequence, from.index);
  if (refusal != null) return SceneStepEditRefused(refusal);
  final SceneNode node;
  try {
    node = SceneNode(
      id: ids.node(),
      kind: SceneNodeKind.condition,
      title: title,
      payload: condition,
    );
  } on ArgumentError {
    return const SceneStepEditRefused(SceneStepEditRefusal.invalidNode);
  } on ValidationException {
    return const SceneStepEditRefused(SceneStepEditRefusal.invalidNode);
  }
  final root = _replaceSequence(list.root, from.blockNodeId, from.branchIndex, (
    current,
  ) {
    final wrapped = current.steps.sublist(from.index, from.index + count);
    final block = SceneBlockStep(
      nodeId: node.id,
      kind: SceneStepBlockKind.condition,
      branches: [
        SceneStepBranch(
          portIds: const ['true'],
          role: SceneStepBranchRole.whenTrue,
          sequence: SceneStepSequence(steps: wrapped),
        ),
        SceneStepBranch(
          portIds: const ['false'],
          role: SceneStepBranchRole.whenFalse,
          sequence: SceneStepSequence(),
        ),
      ],
    );
    return current.copyWith(
      steps: [...current.steps]
        ..replaceRange(from.index, from.index + count, [block]),
    );
  });
  return _commit(
    scene,
    list,
    root,
    ids: ids,
    added: [(node: node, anchor: _anchorOf(list, sequence, from))],
  );
}

SceneStepEditResult removeSceneStep(
  SceneAsset scene, {
  required String nodeId,
  required SceneStepIds ids,
}) {
  final list = projectSceneSteps(scene.graph);
  if (list is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notAList);
  }
  final location = _locate(list.root, nodeId, null, 0);
  if (location == null) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unknownStep);
  }
  final removed = {
    for (final step in _subtree(location.step)) ...step.ownNodeIds,
  };
  final root = _replaceSequence(
    list.root,
    location.blockNodeId,
    location.branchIndex,
    (current) => _without(current, location.index),
  );
  return _commit(scene, list, root, ids: ids, removed: removed);
}

SceneStepEditResult moveSceneStep(
  SceneAsset scene, {
  required String nodeId,
  required SceneStepSlot to,
  required SceneStepIds ids,
}) {
  final list = projectSceneSteps(scene.graph);
  if (list is! SceneStepList) {
    return const SceneStepEditRefused(SceneStepEditRefusal.notAList);
  }
  final location = _locate(list.root, nodeId, null, 0);
  if (location == null) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unknownStep);
  }
  final target = _sequenceAt(list.root, to.blockNodeId, to.branchIndex);
  if (target == null) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unknownSequence);
  }
  if (to.blockNodeId != null &&
      _subtree(location.step).any((step) => step.nodeId == to.blockNodeId)) {
    return const SceneStepEditRefused(SceneStepEditRefusal.intoItself);
  }
  if (to.index < 0 || to.index > target.steps.length) {
    return const SceneStepEditRefused(SceneStepEditRefusal.indexOutOfRange);
  }
  final sameSequence =
      to.blockNodeId == location.blockNodeId &&
      to.branchIndex == location.branchIndex;
  final index = sameSequence && location.index < to.index
      ? to.index - 1
      : to.index;
  final detached = _replaceSequence(
    list.root,
    location.blockNodeId,
    location.branchIndex,
    (current) => _without(current, location.index),
  );
  final landing = _sequenceAt(detached, to.blockNodeId, to.branchIndex)!;
  final refusal = _slotRefusal(landing, index);
  if (refusal != null) return SceneStepEditRefused(refusal);
  if (!location.step.flowsOn && index < landing.steps.length) {
    return const SceneStepEditRefused(SceneStepEditRefusal.unreachablePosition);
  }
  final root = _replaceSequence(
    detached,
    to.blockNodeId,
    to.branchIndex,
    (current) => current.copyWith(
      steps: [...current.steps]..insert(index, location.step),
    ),
  );
  return _commit(scene, list, root, ids: ids);
}
