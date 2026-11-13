import 'package:map_core/map_core_domain.dart';

enum SceneStepBlockKind { condition, outcomes, failure }

enum SceneStepBranchRole { whenTrue, whenFalse, main, failure, outcome }

enum SceneStepGraphReason {
  portFanOut,
  endWithOutgoingEdge,
  multipleEntry,
  unreachableNodes,
  sharedStep,
  ambiguousJoin,
  unclaimedEdges,
}

sealed class SceneStepTail {
  const SceneStepTail();
}

final class SceneStepTailContinue extends SceneStepTail {
  const SceneStepTailContinue();

  @override
  bool operator ==(Object other) => other is SceneStepTailContinue;

  @override
  int get hashCode => 1;
}

final class SceneStepTailEnd extends SceneStepTail {
  const SceneStepTailEnd(this.endNodeId);

  final String endNodeId;

  @override
  bool operator ==(Object other) =>
      other is SceneStepTailEnd && other.endNodeId == endNodeId;

  @override
  int get hashCode => endNodeId.hashCode;
}

final class SceneStepTailOpen extends SceneStepTail {
  const SceneStepTailOpen();

  @override
  bool operator ==(Object other) => other is SceneStepTailOpen;

  @override
  int get hashCode => 2;
}

final class SceneStepSequence {
  SceneStepSequence({
    List<SceneStep> steps = const [],
    this.tail = const SceneStepTailContinue(),
  }) : steps = List.unmodifiable(steps);

  final List<SceneStep> steps;
  final SceneStepTail tail;

  bool get flowsOn =>
      tail is SceneStepTailContinue && (steps.isEmpty || steps.last.flowsOn);

  Iterable<SceneStep> get allSteps sync* {
    for (final step in steps) {
      yield step;
      if (step is SceneBlockStep) {
        for (final branch in step.branches) {
          yield* branch.sequence.allSteps;
        }
      }
    }
  }

  Iterable<String> get endNodeIds sync* {
    if (tail case SceneStepTailEnd(:final endNodeId)) yield endNodeId;
    for (final step in steps) {
      if (step is SceneBlockStep) {
        for (final branch in step.branches) {
          yield* branch.sequence.endNodeIds;
        }
      }
    }
  }

  SceneStepSequence copyWith({List<SceneStep>? steps, SceneStepTail? tail}) =>
      SceneStepSequence(steps: steps ?? this.steps, tail: tail ?? this.tail);

  @override
  bool operator ==(Object other) =>
      other is SceneStepSequence &&
      other.tail == tail &&
      _same(other.steps, steps);

  @override
  int get hashCode => Object.hash(tail, Object.hashAll(steps));
}

sealed class SceneStep {
  const SceneStep({required this.nodeId, this.routerNodeId});

  final String nodeId;
  final String? routerNodeId;

  String get exitNodeId => routerNodeId ?? nodeId;

  bool get flowsOn;

  Iterable<String> get ownNodeIds;
}

final class SceneLeafStep extends SceneStep {
  SceneLeafStep({
    required super.nodeId,
    super.routerNodeId,
    List<String> portIds = const [],
  }) : portIds = List.unmodifiable(portIds);

  final List<String> portIds;

  @override
  bool get flowsOn => true;

  @override
  Iterable<String> get ownNodeIds => [nodeId, ?routerNodeId];

  @override
  bool operator ==(Object other) =>
      other is SceneLeafStep &&
      other.nodeId == nodeId &&
      other.routerNodeId == routerNodeId &&
      _same(other.portIds, portIds);

  @override
  int get hashCode =>
      Object.hash(nodeId, routerNodeId, Object.hashAll(portIds));
}

final class SceneBlockStep extends SceneStep {
  SceneBlockStep({
    required super.nodeId,
    super.routerNodeId,
    required this.kind,
    required List<SceneStepBranch> branches,
    this.mergeNodeId,
    List<String> mergePortIds = const [],
  }) : branches = List.unmodifiable(branches),
       mergePortIds = List.unmodifiable(mergePortIds);

  final SceneStepBlockKind kind;
  final List<SceneStepBranch> branches;
  final String? mergeNodeId;
  final List<String> mergePortIds;

  @override
  bool get flowsOn => branches.any((branch) => branch.sequence.flowsOn);

  @override
  Iterable<String> get ownNodeIds => [nodeId, ?routerNodeId, ?mergeNodeId];

  SceneBlockStep withBranches(List<SceneStepBranch> branches) => SceneBlockStep(
    nodeId: nodeId,
    routerNodeId: routerNodeId,
    kind: kind,
    branches: branches,
    mergeNodeId: mergeNodeId,
    mergePortIds: mergePortIds,
  );

  @override
  bool operator ==(Object other) =>
      other is SceneBlockStep &&
      other.nodeId == nodeId &&
      other.routerNodeId == routerNodeId &&
      other.kind == kind &&
      other.mergeNodeId == mergeNodeId &&
      _same(other.mergePortIds, mergePortIds) &&
      _same(other.branches, branches);

  @override
  int get hashCode => Object.hash(
    nodeId,
    routerNodeId,
    kind,
    mergeNodeId,
    Object.hashAll(mergePortIds),
    Object.hashAll(branches),
  );
}

final class SceneStepBranch {
  SceneStepBranch({
    required List<String> portIds,
    required this.role,
    required this.sequence,
  }) : portIds = List.unmodifiable(portIds);

  final List<String> portIds;
  final SceneStepBranchRole role;
  final SceneStepSequence sequence;

  SceneStepBranch withSequence(SceneStepSequence sequence) =>
      SceneStepBranch(portIds: portIds, role: role, sequence: sequence);

  @override
  bool operator ==(Object other) =>
      other is SceneStepBranch &&
      other.role == role &&
      other.sequence == sequence &&
      _same(other.portIds, portIds);

  @override
  int get hashCode => Object.hash(role, sequence, Object.hashAll(portIds));
}

sealed class SceneStepProjection {
  const SceneStepProjection(this.graph);

  final SceneGraph graph;

  int get nodeCount => graph.nodes.length;

  int get edgeCount => graph.edges.length;

  SceneNode? node(String nodeId) {
    for (final node in graph.nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }
}

final class SceneStepList extends SceneStepProjection {
  SceneStepList(
    super.graph, {
    required this.root,
    List<String> startPortIds = const [],
    List<String> unusedEndNodeIds = const [],
  }) : startPortIds = List.unmodifiable(startPortIds),
       unusedEndNodeIds = List.unmodifiable(unusedEndNodeIds);

  final SceneStepSequence root;
  final List<String> startPortIds;
  final List<String> unusedEndNodeIds;

  Iterable<SceneStep> get allSteps => root.allSteps;

  SceneStep? step(String nodeId) {
    for (final step in allSteps) {
      if (step.nodeId == nodeId) return step;
    }
    return null;
  }
}

final class SceneStepTrueGraph extends SceneStepProjection {
  SceneStepTrueGraph(
    super.graph, {
    required this.reason,
    List<String> nodeIds = const [],
  }) : nodeIds = List.unmodifiable(nodeIds);

  final SceneStepGraphReason reason;
  final List<String> nodeIds;
}

final class SceneStepLoop extends SceneStepProjection {
  SceneStepLoop(super.graph, {required List<String> cycleNodeIds})
    : cycleNodeIds = List.unmodifiable(cycleNodeIds);

  final List<String> cycleNodeIds;
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
